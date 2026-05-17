# Plan: Consolidate into authentication_agent - PR Series

## Context

Three separate credential systems exist with no connection to each other:
- `authentication_agent` - best architecture (AES-256-GCM, FastAPI, platform pattern) but no Google OAuth, no OpenBao, no 1Password
- `authentication_boss` - audit/test CLI for API keys, missing `store.py`, plaintext SQLite, no secret manager integration
- `google-oauth-setup` - production-ready Google OAuth with OpenBao + 1P chain, but standalone infra tool with no relation to the agent

The goal: `authentication_agent` becomes the single credential gateway. Everything else folds into it. Other projects (arc-scripts, agents) call authentication_agent's REST API to get credentials instead of duplicating lookup logic.

**End state:** One agent. Three tool categories inside it: (1) Google OAuth acquisition + storage, (2) API key management, (3) credential gateway REST API. Arc-scripts auth.py becomes a thin HTTP client.

---

## Architecture After Consolidation

```
authentication_agent (FastAPI, port 8401)
  │
  ├── backends/
  │   ├── openbao.py       ← from storage.py (write via pipe-to-python, read via SSH)
  │   ├── onepassword.py   ← from storage.py (_find_1p_item, write_1password)
  │   └── sqlite.py        ← existing core/database.py (AES-256-GCM encrypted)
  │
  ├── core/platforms/
  │   ├── google_oauth.py  ← new GoogleOAuthManager (BasePlatformManager subclass)
  │   └── google_services.py ← from services.py (10 service registry + smoke tests)
  │
  ├── tools/
  │   ├── oauth_flow.py    ← from auth_flow.py (InstalledAppFlow wrapper)
  │   └── policy_manager.py ← from authentication_boss/policy_manager/
  │
  ├── cli/
  │   ├── auth_cli.py      ← existing (store, get, test, list, export, delete)
  │   ├── google_commands.py ← from google_oauth.py (setup, refresh, smoke-test, migrate)
  │   └── api_key_commands.py ← from authentication_boss (add, list, delete, test, report)
  │
  └── web/
      ├── server.py        ← existing (JWT auth, credential CRUD endpoints)
      └── google_routes.py ← new (GET /credentials/google/{service}, POST /setup)

arc-scripts/gmail-mgmt/auth.py → thin HTTP client (~20 lines) calling GET /credentials/google/gmail
```

---

## PR 1: Add Credential Backends (OpenBao + 1Password)

**Repo:** `arc-web/authentication-agent`  
**Branch:** `feat/credential-backends`

**New files:**
- `backends/__init__.py`
- `backends/openbao.py` - port `write_openbao()`, `read_openbao()`, `_root_token()` from `google-oauth-setup/storage.py`. Keep the pipe-to-python approach for writes. Add `TimeoutExpired` catch on reads.
- `backends/onepassword.py` - port `_find_1p_item()`, `_find_1p_any_google_item()`, `write_1password()`, `_read_1p_items()`, `_read_1p_item_fields()` from `google-oauth-setup/storage.py`

**Constants to centralize** (currently duplicated across storage.py and auth.py):
```python
ZEROCLAW_HOST = "zeroclaw"
VAULT_ADDR = "http://127.0.0.1:8200"
OPENBAO_ROOT_TOKEN_ITEM_ID = "hl23px33remaz2xecl5ecvvaem"
ONEPASSWORD_VAULT = "ARC"
```

**Key design:** Backends are pure functions, no classes. `openbao.read(path) -> dict | None`, `openbao.write(path, fields) -> bool`. No coupling to Google-specific logic.

**Tests to add:** `tests/backends/test_openbao.py`, `tests/backends/test_onepassword.py` - mock SSH subprocess calls.

---

## PR 2: Add Google OAuth Platform + Services Registry

**Branch:** `feat/google-oauth-platform`  
**Depends on:** PR 1

**New files:**
- `core/platforms/google_oauth.py` - `GoogleOAuthManager(BasePlatformManager)`:
  - `validate_credential()` - checks refresh_token is non-empty, client_id matches GCP format
  - `test_connection()` - delegates to service-specific smoke test
  - `get_required_credentials()` - returns `[REFRESH_TOKEN, client_id, client_secret]`
  - `get_service_credentials(service_key, account, account_slug)` - OpenBao → 1P → None (port from `storage.get_service_credentials()`)
  - `write_all_tiers(service_key, account_slug, account, token_dict)` - writes OpenBao → 1P → local cache (in that order)

- `core/platforms/google_services.py` - port `SERVICES` dict and `smoke_test()` from `google-oauth-setup/services.py`. All 10 services with scopes, api_ids, openbao_path, token_file.

- `tools/oauth_flow.py` - port `run_oauth_flow()` from `google-oauth-setup/auth_flow.py`. Returns token dict without writing to disk.

**Extend existing files:**
- `core/models.py` - add to `Platform` enum: `GOOGLE_GMAIL`, `GOOGLE_DRIVE`, `GOOGLE_GTM`, `GOOGLE_ANALYTICS`, `GOOGLE_ADS`, `GOOGLE_SEARCH_CONSOLE`, `GOOGLE_GMB`, `GOOGLE_YOUTUBE`, `GOOGLE_CALENDAR`, `GOOGLE_PEOPLE`
- `core/models.py` - add to `CredentialType` enum: `OAUTH_REFRESH_TOKEN`, `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`
- `core/platforms.py` - register `GoogleOAuthManager` in the platform factory

**`account_slug()` utility** (moved to `core/utils.py`):
```python
def account_slug(account: str) -> str:
    return account.replace("@", "-").replace(".", "-")
```

---

## PR 3: Google OAuth CLI Commands

**Branch:** `feat/google-cli-commands`  
**Depends on:** PR 2

**New file:** `cli/google_commands.py`

Port these commands from `google-oauth-setup/google_oauth.py`:
- `google setup --account EMAIL [--services S,S] [--all] [--gcp-project ID]`
- `google status --account EMAIL`
- `google refresh --account EMAIL --service SVC`
- `google smoke-test --account EMAIL [--service SVC]`
- `google migrate --account EMAIL`

Wire into main CLI entry point alongside existing `auth_cli.py` commands.

**Key changes vs original:**
- Uses `GoogleOAuthManager` from PR 2 instead of inline storage calls
- Uses backends from PR 1 directly
- `account_slug()` from `core/utils.py`
- Local cache still written last with `chmod 600`

---

## PR 4: Absorb authentication_boss

**Branch:** `feat/absorb-auth-boss`  
**Depends on:** PR 1 (for encrypted storage)

**New files:**
- `cli/api_key_commands.py` - port from `authentication_boss/scripts/manage_api_keys.py`:
  - `apikey add SERVICE KEY [--notes] [--org-name] [--org-slug]`
  - `apikey list [--service] [--json]`
  - `apikey delete SERVICE KEY`
  - `apikey get SERVICE`
  - `apikey test [--open-links] [--history]` - port from `test_api_keys.py`
  - `apikey report` / `apikey full-report`
  - Fix: store keys in **existing encrypted SQLite** (`~/.auth_agent/credentials.db`) instead of plaintext `~/.cli.db`

- `tools/policy_manager.py` - port from `authentication_boss/policy_manager/manage_specs.py`:
  - `policy init`
  - `policy update --tool TOOL --spec-url URL [--classification-file YAML]`
  - `policy report [--tool TOOL]`

- `tools/policy_classifications/` - copy Stripe YAML + template from authentication_boss

**Deprecate authentication_boss:** Update its README: "Superseded by authentication_agent. Do not use for new integrations."

---

## PR 5: Credential Gateway REST API (Google routes)

**Branch:** `feat/google-api-routes`  
**Depends on:** PR 2

**New file:** `web/google_routes.py`

New FastAPI router mounted at `/credentials/google/`:

```
GET  /credentials/google/{service}?account=EMAIL
     → returns {access_token, refresh_token, client_id, valid_until}
     → triggers token refresh if expired
     → OpenBao → 1P → local cache lookup chain
     → 404 if not found, 401 if JWT missing

POST /credentials/google/setup
     → triggers OAuth browser flow for service
     → body: {account, service, gcp_project}
     → returns {status: "ok", services_authed: [...]}

GET  /credentials/google/status?account=EMAIL
     → returns all 10 services with {authed: bool, expires: ISO}
```

Wire into `web/server.py` with `app.include_router(google_router, prefix="/credentials/google")`.

**JWT requirement:** Same JWT auth as existing endpoints (X-Master-Key to get token, Bearer token on subsequent requests).

---

## PR 6: Update arc-scripts auth.py to use API

**Repo:** `arc-web/arc-scripts`  
**Branch:** `feat/auth-via-agent-api`  
**Depends on:** PR 5 deployed/running

**Replace** `gmail-mgmt/auth.py` (currently 160 lines with duplicated OpenBao/1P logic) with:

```python
"""Gmail credential loader - delegates to authentication_agent REST API."""
import os, requests
from google.oauth2.credentials import Credentials

AUTH_AGENT_URL = os.getenv("AUTH_AGENT_URL", "http://localhost:8401")
AUTH_AGENT_TOKEN = os.getenv("AUTH_AGENT_TOKEN", "")  # JWT

def get_gmail_credentials() -> Credentials:
    r = requests.get(
        f"{AUTH_AGENT_URL}/credentials/google/gmail",
        params={"account": "me@advertisingreportcard.com"},
        headers={"Authorization": f"Bearer {AUTH_AGENT_TOKEN}"},
        timeout=10,
    )
    r.raise_for_status()
    data = r.json()
    return Credentials(
        token=data["access_token"],
        refresh_token=data["refresh_token"],
        token_uri="https://oauth2.googleapis.com/token",
        client_id=data["client_id"],
        client_secret=data["client_secret"],
    )
```

**Fallback:** If `AUTH_AGENT_URL` is unreachable, fall back to direct OpenBao lookup (same chain as current auth.py but as a second attempt). This prevents single point of failure.

---

## PR Execution Order

| PR | Branch | Depends | Size | Risk |
|----|--------|---------|------|------|
| PR 1 | `feat/credential-backends` | none | Medium | Low |
| PR 2 | `feat/google-oauth-platform` | PR 1 | Large | Medium |
| PR 3 | `feat/google-cli-commands` | PR 2 | Medium | Low |
| PR 4 | `feat/absorb-auth-boss` | PR 1 | Medium | Low |
| PR 5 | `feat/google-api-routes` | PR 2 | Medium | Medium |
| PR 6 | `feat/auth-via-agent-api` | PR 5 live | Small | Low |

PRs 3 and 4 can be developed in parallel. PR 5 can be developed in parallel with PR 3/4.

---

## What Gets Deprecated

| Repo | Status after consolidation |
|------|---------------------------|
| `arc-web/google-oauth-setup` | Keep repo, add README banner: "Absorbed into authentication_agent. Use auth agent CLI for new setups." Stop active development. |
| `arc-web/authentication-boss` | Keep repo, README: "Superseded by authentication_agent apikey commands." |
| `arc-scripts/gmail-mgmt/auth.py` | Replaced by thin HTTP client (PR 6) |

---

## Files to Create/Modify

**authentication_agent:**

| File | Action | Source |
|------|--------|--------|
| `backends/__init__.py` | Create | - |
| `backends/openbao.py` | Create | `google-oauth-setup/storage.py` |
| `backends/onepassword.py` | Create | `google-oauth-setup/storage.py` |
| `core/platforms/google_oauth.py` | Create | `storage.py` + `google_oauth.py` |
| `core/platforms/google_services.py` | Create | `google-oauth-setup/services.py` |
| `core/utils.py` | Create | `account_slug()` + shared constants |
| `core/models.py` | Modify | Add Google platforms + OAuth credential types |
| `core/platforms.py` | Modify | Register GoogleOAuthManager |
| `tools/oauth_flow.py` | Create | `google-oauth-setup/auth_flow.py` |
| `tools/policy_manager.py` | Create | `authentication_boss/policy_manager/manage_specs.py` |
| `tools/policy_classifications/` | Create | From authentication_boss |
| `cli/google_commands.py` | Create | `google-oauth-setup/google_oauth.py` |
| `cli/api_key_commands.py` | Create | `authentication_boss/scripts/` |
| `web/google_routes.py` | Create | New |
| `web/server.py` | Modify | Mount google_routes |
| `requirements.txt` | Modify | Add google-auth-oauthlib, google-api-python-client, typer, rich |

**arc-scripts:**

| File | Action |
|------|--------|
| `gmail-mgmt/auth.py` | Replace with HTTP client (PR 6) |

---

## Verification

After PR 1-3:
```bash
cd ~/ai/agents/development/authentication_agent
python3 -m cli.google_commands setup --account me@advertisingreportcard.com --services gmail
python3 -m cli.google_commands smoke-test --account me@advertisingreportcard.com
```

After PR 5:
```bash
# Start the agent
python3 -m web.server

# Test the new endpoint
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8401/credentials/google/gmail?account=me@advertisingreportcard.com"
```

After PR 6:
```bash
# With auth agent running
cd ~/ai/infra/arc-scripts/gmail-mgmt
python3 -c "from auth import get_gmail_credentials; c = get_gmail_credentials(); print('ok', c.valid)"

# Without auth agent (fallback path)
AUTH_AGENT_URL=http://localhost:9999 python3 -c "from auth import get_gmail_credentials; c = get_gmail_credentials(); print('fallback ok', c.valid)"
```
