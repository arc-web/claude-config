---
name: Gmail Access - CLI Only
description: How Gmail is accessed across all agents and scripts - CLI and API only, no MCP
type: reference
originSessionId: 0dfa7498-1600-4451-8939-f6ff2dcc407f
---
Gmail access uses the CLI and Gmail API directly. The `@gongrzhe/server-gmail-autoauth-mcp` third-party server is purged. The native claude.ai Gmail integration may exist (check `claude mcp list`); if it does, the CLI/API approach below is still preferred for agent scripts.

**Auth status:** Working as of 2026-05-09. Token at `~/.gmail-mcp/credentials.json.advertisingreportcard`. OAuth client in 1P item `ystolmder36ygfnnk3q4xsbgb4` (Gmail MCP - advertisingreportcard). Refresh token + client creds in OpenBao at `secret/gmail/advertisingreportcard`. GCP project 510919487798, Gmail API enabled.

**Canonical CLI tool:** `/Users/home/ai/infra/arc-scripts/gmail-mgmt/gmail_mgmt.py`
- Typer CLI with subcommands: `labels`, `filters`, `rules`, `bulk`, `daemon`, `backup`, `profile`, `messages`
- `messages` subcommands: `messages-search`, `messages-thread`, `messages-draft`, `messages-send`
- Auth module: `auth.py` in same dir via `get_gmail_credentials()`

**Pattern for agents calling Gmail API directly:**
```python
import sys
sys.path.insert(0, "/Users/home/ai/infra/arc-scripts/gmail-mgmt")
from auth import get_gmail_credentials
from googleapiclient.discovery import build

creds = get_gmail_credentials()
service = build("gmail", "v1", credentials=creds)
# service.users().messages().list(userId="me", q="...").execute()
# service.users().threads().get(userId="me", id=thread_id, format="full").execute()
# service.users().drafts().create(userId="me", body={...}).execute()
```

**Account:** `me@advertisingreportcard.com`

**Agents using Gmail API:**
- `gmail_thread_agent.py` - thread fetch, analysis, draft creation
- `extract_locations_from_gmail.py` - contact location enrichment from email signatures
- `gmail_location_extractor.py` - same, alternate version

**Sending rules (always enforce):**
- NEVER send without explicit user confirmation
- Test emails ONLY to `me@advertisingreportcard.com` unless explicitly told otherwise
- Always draft first, never auto-send
- HTML body only (`text/html`), never markdown

**What NOT to do:**
- Do not suggest `@gongrzhe/server-gmail-autoauth-mcp` - purged 2026-05-09
- Do not use any third-party gmail MCP npm server - removed
- claude.ai native Gmail MCP may be connected (check `claude mcp list`) - fine to check but CLI/API is primary for scripting
- Do not reference `mcp_gmail_*` tool calls in agent code - removed
