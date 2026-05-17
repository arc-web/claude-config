# Gmail CLI - messages subapp + agent subprocess wiring

## Context

Gmail access is being standardized on the `gmail_mgmt` CLI (`/Users/home/ai/infra/arc-scripts/gmail-mgmt/`).
The existing CLI covers labels/filters/rules/bulk/daemon/backup but has no read/search/draft/send commands.
Agents currently call Gmail API directly (temp fallback). Goal: add `messages` subapp to CLI, wire agents
to call CLI via subprocess, keep direct API as fallback until CLI is verified 100%, then purge the fallback.

---

## Phase 1: Add `messages.py` module

**New file:** `/Users/home/ai/infra/arc-scripts/gmail-mgmt/messages.py`

Class `MessageManager(service)` with methods:

```python
def search(query: str, max_results: int = 10) -> list[dict]
    # service.users().messages().list(userId='me', q=query, maxResults=max_results)
    # For each result: messages().get(userId='me', id=msg_id, format='full')
    # Returns: [{'id', 'thread_id', 'subject', 'from', 'to', 'date', 'snippet', 'body'}, ...]

def get_thread(thread_id: str) -> list[dict]
    # service.users().threads().get(userId='me', id=thread_id, format='full')
    # Returns: same shape as search() per message, chronological

def draft(to: str, subject: str, body: str, thread_id: str = None) -> dict
    # MIMEText → base64 → drafts().create()
    # Returns: {'draft_id': '...'}

def send(to: str, subject: str, body: str) -> dict
    # MIMEText → base64 → messages().send()
    # Returns: {'message_id': '...'}
```

**Shared body parser** (reuse exact pattern from `gmail_thread_agent.py`):
```python
def _decode_body(payload: dict) -> str:
    # base64 urlsafe decode, handles multipart
```

**Output:** always JSON (this subapp is for programmatic/agent use). Use `json.dumps()`, not Rich tables.

---

## Phase 2: Register `messages` subapp in `gmail_mgmt.py`

```python
from messages import MessageManager

messages_app = typer.Typer(help="Read, search, draft, and send messages")
app.add_typer(messages_app, name="messages")

@messages_app.command()
def messages_search(query: str, max: int = typer.Option(10, "--max")):
    """Search messages. Outputs JSON."""

@messages_app.command()
def messages_thread(thread_id: str = typer.Option(..., "--thread-id")):
    """Fetch full thread as JSON."""

@messages_app.command()
def messages_draft(
    to: str = typer.Option(...),
    subject: str = typer.Option(...),
    body: str = typer.Option(...),
    thread_id: str = typer.Option(None, "--thread-id"),
):
    """Create Gmail draft. Outputs JSON with draft_id."""

@messages_app.command()
def messages_send(
    to: str = typer.Option(...),
    subject: str = typer.Option(...),
    body: str = typer.Option(...),
):
    """Send email. Outputs JSON with message_id. NEVER call without explicit user confirmation."""
```

---

## Phase 3: Add subprocess helper to agents

**New shared helper** (inline in each agent file - no shared lib):

```python
GMAIL_CLI = "/Users/home/ai/infra/arc-scripts/gmail-mgmt/gmail_mgmt.py"

def _gmail_cli(*args) -> dict | list | None:
    """Call gmail_mgmt CLI, return parsed JSON. Returns None on failure (triggers fallback)."""
    try:
        result = subprocess.run(
            ["python3", GMAIL_CLI, *args],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout)
    except Exception:
        pass
    return None
```

---

## Phase 4: Wire agents to CLI with direct API fallback

### `gmail_thread_agent.py`

`get_thread(thread_id)`:
```python
# Try CLI first
data = _gmail_cli("messages", "thread", "--thread-id", thread_id)
if data is not None:
    return [Email(**msg) for msg in data]
# TEMP FALLBACK: direct API
...existing API code...
```

`draft_response(response_text, thread_id, subject, to_addresses)`:
```python
data = _gmail_cli("messages", "draft",
    "--to", ", ".join(to_addresses),
    "--subject", subject,
    "--body", response_text,
    "--thread-id", thread_id,
)
if data is not None:
    return data.get("draft_id", "")
# TEMP FALLBACK: direct API
...existing API code...
```

### `extract_locations_from_gmail.py` + `gmail_location_extractor.py`

`search_emails_for_contact(email)`:
```python
data = _gmail_cli("messages", "search", f"from:{email} OR to:{email}", "--max", "10")
if data is not None:
    return data
# TEMP FALLBACK: direct API
...existing API code...
```

---

## Files touched

| File | Change |
|------|--------|
| `/Users/home/ai/infra/arc-scripts/gmail-mgmt/messages.py` | **NEW** - MessageManager class |
| `/Users/home/ai/infra/arc-scripts/gmail-mgmt/gmail_mgmt.py` | Add messages_app + 4 commands |
| `gmail_thread_agent.py` (comms + aimacpro workspace) | _gmail_cli helper + CLI-first in get_thread, draft_response |
| `extract_locations_from_gmail.py` (client_director + workspace) | _gmail_cli helper + CLI-first in search |
| `gmail_location_extractor.py` (client_director + workspace) | same |

---

## Verification

```bash
# CLI smoke tests
cd /Users/home/ai/infra/arc-scripts/gmail-mgmt

python3 gmail_mgmt.py messages search "from:me@advertisingreportcard.com" --max 3
# expect: JSON array of messages

python3 gmail_mgmt.py messages draft \
  --to "me@advertisingreportcard.com" \
  --subject "CLI test draft" \
  --body "test body"
# expect: {"draft_id": "..."}
# verify: draft appears in Gmail Drafts folder

python3 gmail_mgmt.py messages thread --thread-id <any-real-thread-id>
# expect: JSON array of emails
```

---

## Purge condition (future task)

Once CLI commands pass verification above with zero failures over real data:
- Remove `import base64`, `from googleapiclient.discovery import build`, `from auth import get_gmail_credentials` from all agent files
- Remove all `# TEMP FALLBACK` blocks
- Remove `_get_service()` from `GmailThreadAgent`
- Update `gmail_access.md` memory to remove fallback note
