# Handoff: Authentication Agent Consolidation

## Who this is for

This document is a briefing for an agent tasked with planning and executing the consolidation of all credential management into `authentication_agent`. Read every section before touching any code. The architecture decision at the end overrides anything you think you know about how authentication_agent currently works.

---

## What was built this session (already done, do not redo)

### google-oauth-setup (`~/ai/infra/google-oauth-setup/`)

A one-shot Google OAuth CLI. Fully working. Committed and pushed to `arc-web/google-oauth-setup`.

**Files:**
- `storage.py` - credential read/write. OpenBao via SSH to zeroclaw. 1Password via `op` CLI. Three-tier lookup chain.
- `auth_flow.py` - runs `InstalledAppFlow.run_local_server()`, returns token dict WITHOUT writing to disk (important: the disk write was removed this session)
- `services.py` - registry of 10 Google services with scopes, OpenBao paths, token filenames, smoke test logic
- `google_oauth.py` - Typer CLI: `setup`, `status`, `refresh`, `smoke-test`, `migrate`
- `requirements.txt` - google-auth-oauthlib, google-api-python-client, typer, rich, requests

**What was fixed this session:**
- `write_openbao()` - old version used inline shell quoting (`f"{k}='{v}'"`) which breaks on special chars. Fixed to pipe a Python script via stdin to `python3` on zeroclaw. No quoting issues.
- `auth_flow.py` - removed disk write from inside the function. Caller now decides persistence.
- `google_oauth.py setup()` - now writes OpenBao first, then 1Password, then local cache last with `chmod 600`
- `google_oauth.py migrate()` - completely rewritten. Old version was file-to-file copy (never touched OpenBao). New version: reads `~/.gmail-mcp/`, writes to OpenBao, verifies, writes 1P, writes local cache, then asks to delete source.
- `storage.py get_service_credentials()` - new function returning full token dict (refresh_token + client_id + client_secret + account). If found in 1P but missing from OpenBao: prompts interactively or auto-syncs in agent context.
- `read_openbao()` - now catches `TimeoutExpired`, returns None on SSH failure (offline mode).
- `get_client_credentials()` - unchanged API but now uses cleaner 1P search helpers.

### arc-scripts auth.py (`~/ai/infra/arc-scripts/gmail-mgmt/auth.py`)

Consumer-side credential loader for Gmail agents. Fully rewritten this session. Committed and pushed to `arc-web/arc-scripts`.

**What it does now:**
1. Try OpenBao: `secret/gmail/me-advertisingreportcard-com`
2. If missing: try 1Password (searches ARC vault for "gmail" + "oauth" + "advertisingreportcard" in title)
3. If found in 1P but not OpenBao: auto-syncs to OpenBao without prompt (agent context = non-interactive)
4. If still missing: try local cache `~/.google-oauth/me-advertisingreportcard-com/gmail.json`
5. If all fail: raise FileNotFoundError with setup instructions
6. Build `google.oauth2.credentials.Credentials` with `scopes=None` (critical: passing scopes on refresh causes `invalid_scope` from Google - scopes are baked into the refresh token)
7. If token expired: call `creds.refresh(Request())`, push rotated refresh_token back to OpenBao, update local cache with `chmod 600`

**Hardcoded values in auth.py** (known limitation - address in consolidation):
- Account: `me@advertisingreportcard.com`
- Slug: `me-advertisingreportcard-com`
- Service: `gmail` only
- OpenBao path: `secret/gmail/me-advertisingreportcard-com`

### OpenBao live state (verified)

Host: zeroclaw. Runs in Docker at `http://127.0.0.1:8200`. KV v2 mount at `secret/`.

Auth: Root token only for writes. Fetched at runtime from 1Password:
```
op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token --reveal
```

All AppRoles are read-only. Only root token can `kv put`.

**Verified paths for `me@advertisingreportcard.com` (slug: `me-advertisingreportcard-com`):**
```
secret/google-oauth-client/me-advertisingreportcard-com  → {client_id, client_secret, gcp_project}
secret/gmail/me-advertisingreportcard-com                → {refresh_token, client_id, client_secret, account}
secret/google-drive/me-advertisingreportcard-com         → same fields
secret/google-tag-manager/me-advertisingreportcard-com   → same fields
secret/google-analytics/me-advertisingreportcard-com     → same fields
secret/google-ads/me-advertisingreportcard-com           → same fields
secret/search-console/me-advertisingreportcard-com       → same fields
secret/gmb/me-advertisingreportcard-com                  → same fields
secret/youtube/me-advertisingreportcard-com              → same fields
secret/calendar/me-advertisingreportcard-com             → same fields
secret/people/me-advertisingreportcard-com               → same fields
```

**IMPORTANT slug migration that already happened:** Tokens were originally seeded at slug `advertisingreportcard` (just username). Code generates `me-advertisingreportcard-com` (full slug). This session migrated all 10 service tokens from old slug to new slug. Both slugs exist in OpenBao. The `advertisingreportcard` paths are stale leftovers - they can be deleted.

### 1Password structure (ARC vault)

Item naming: `Google {Service Display} OAuth - {account_localpart}`

Fields per item:
- `client_id` (text)
- `client_secret` (password type)
- `refresh_token` (password type)
- `account` (text - full email)
- `notesPlain` - metadata: GCP project, auth date, OpenBao path, authorized account

---

## What exists and has NOT been changed (read these before touching them)

### authentication_agent (`~/ai/agents/development/authentication_agent/`)

Repo: `arc-web/authentication-agent`

**Architecture:**
- `core/crypto.py` - AES-256-GCM encryption with PBKDF2-HMAC-SHA256 key derivation (100k iterations). Master key from `CREDENTIAL_MASTER_KEY` env var.
- `core/database.py` - SQLite at `~/.auth_agent/credentials.db`. Tables: `credentials`, `sessions`, `audit_log`.
- `core/models.py` - Pydantic models. `Platform` enum (supabase, gcp, aws, azure, generic). `CredentialType` enum (api_key, secret_key, access_token, refresh_token, password, connection_string, certificate, private_key, public_key, custom). `Environment` enum (development, staging, production).
- `core/platforms.py` - `BasePlatformManager` ABC with `validate_credential()`, `test_connection()`, `get_required_credentials()`. Implementations: `SupabaseManager` (full), `GCPManager` (format validation only, no actual API call).
- `core/errors.py` - custom exception hierarchy
- `web/server.py` - FastAPI. JWT auth (30-min tokens, master key validates). Endpoints: `POST /auth/token`, `DELETE /auth/token`, `POST /credentials`, `GET /credentials/{service}/{key_name}`, `GET /credentials/{service}`, `GET /credentials`, `DELETE /credentials/{service}/{key_name}`, `PUT /credentials/{service}/{key_name}`.
- `cli/auth_cli.py` - Click CLI: `store`, `get`, `test`, `list`, `export`, `delete`.
- Dependencies: fastapi, uvicorn, pydantic, cryptography, pyjwt, requests, python-multipart, python-jose, passlib, pydantic-settings, streamlit, rich, pytest.

**Current gaps:**
- No OpenBao integration
- No 1Password integration
- No Google OAuth (no google-auth-oauthlib dependency)
- GCP support = service account JSON only, not OAuth tokens
- AWS/Azure: enumerated but empty implementations
- No token expiry enforcement or auto-refresh
- SQLite is the only credential store

### authentication_boss (`~/ai/agents/development/authentication_boss/`)

Repo: `arc-web/authentication-boss`

**What it has:**
- `scripts/manage_api_keys.py` - Click CLI for API key CRUD: `add`, `list`, `delete`, `get`, `report`, `export-env`, `full-report`. Stores in `~/.cli.db` SQLite. **Plaintext - no encryption.**
- `scripts/test_api_keys.py` - Integration tests for stored keys. Hardcoded tests for OpenAI, Stripe, Airtable, Slack. Others logged as MANUAL. Records results in `invocations` table.
- `policy_manager/manage_specs.py` - Fetches OpenAPI specs, classifies endpoints by risk level (read_only, transactional, high_risk, unclassified). Stores in `tools.db`.
- `policy_manager/classification/stripe.yaml` - 55 Stripe operations classified.
- `policy_manager/classification/template.yaml` - blank template.
- `lib/store.py` - **DOES NOT EXIST. File is missing. Referenced in scripts but absent.**

**Critical gaps:**
- `store.py` missing - the abstraction layer doesn't exist
- API keys stored plaintext
- No OpenBao, no 1Password, no secret manager integration
- Only 4 services have real API tests (OpenAI, Stripe, Airtable, Slack)
- No environment isolation (dev/staging/prod mixed)

---

## The Architecture Decision (non-negotiable)

**OpenBao is the only credential store. 1Password is emergency fallback only. No SQLite.**

This means:
- `authentication_agent`'s entire `core/database.py` and `core/crypto.py` layer is **irrelevant for credential storage** and gets removed or made optional
- `authentication_boss`'s `~/.cli.db` is **wrong** and gets migrated to OpenBao then deleted
- All credentials - Google OAuth tokens, API keys, everything - live at OpenBao paths
- The local file cache (`~/.google-oauth/`) stays for performance but is NOT a store - it's a cache with TTL

What IS worth keeping from authentication_agent:
- FastAPI server structure
- `BasePlatformManager` ABC pattern (extensible, clean)
- `CredentialType` enum concept
- Audit log concept (repurposed to log OpenBao reads/writes)
- CLI framework

What gets thrown away from authentication_agent:
- `core/database.py` - SQLite credential storage
- `core/crypto.py` - AES-256-GCM (OpenBao handles encryption)
- `core/models.py` `credentials` table schema
- All `~/.auth_agent/credentials.db` references

---

## Target Architecture

```
authentication_agent (arc-web/authentication-agent)
  │
  ├── backends/                     ← NEW: replaces core/database.py
  │   ├── openbao.py               ← from storage.py: write_openbao(), read_openbao(), _root_token()
  │   └── onepassword.py           ← from storage.py: _find_1p_item(), write_1password() etc.
  │
  ├── core/
  │   ├── platforms/
  │   │   ├── base.py              ← existing BasePlatformManager ABC (keep)
  │   │   ├── supabase.py          ← existing SupabaseManager (keep)
  │   │   ├── gcp.py               ← existing GCPManager (keep, partial)
  │   │   ├── google_oauth.py      ← NEW: GoogleOAuthManager (10 services, 3-tier lookup)
  │   │   └── google_services.py   ← from services.py (service registry + smoke tests)
  │   ├── models.py                ← keep enums, REMOVE db schema models
  │   ├── errors.py                ← keep as-is
  │   └── utils.py                 ← NEW: account_slug(), shared constants (ZEROCLAW_HOST etc.)
  │
  ├── tools/
  │   ├── oauth_flow.py            ← from auth_flow.py (InstalledAppFlow wrapper, no disk write)
  │   └── policy_manager.py        ← from authentication_boss/policy_manager/
  │
  ├── cli/
  │   ├── auth_cli.py              ← keep structure, repoint storage calls to backends/
  │   ├── google_commands.py       ← from google_oauth.py (setup, status, refresh, smoke-test, migrate)
  │   └── api_key_commands.py      ← from authentication_boss/scripts/ (now writes to OpenBao)
  │
  └── web/
      ├── server.py                ← keep JWT auth structure, repoint to backends/
      └── google_routes.py         ← NEW: GET /credentials/google/{service}, POST /google/setup

arc-scripts/gmail-mgmt/auth.py     ← becomes thin HTTP client OR stays as-is (decision below)
```

### OpenBao path convention (standardize this)

```
Google OAuth:
  secret/google-oauth-client/{account-slug}      → {client_id, client_secret, gcp_project}
  secret/{google-service}/{account-slug}          → {refresh_token, client_id, client_secret, account}

API keys (from authentication_boss, needs migration):
  secret/api-keys/{service}/{org-slug}            → {api_key, notes, account}

Other platform credentials:
  secret/platforms/{platform}/{environment}/{service}  → {credential fields}
```

---

## What the other agent needs to plan and execute

### Phase 1: Strip SQLite from authentication_agent

1. Remove `core/database.py` (SQLite) and `core/crypto.py` (AES layer) from active use
2. Create `backends/openbao.py` - port exactly from `google-oauth-setup/storage.py`:
   - `_root_token() -> str`
   - `read_openbao(bao_path: str) -> dict | None` (with TimeoutExpired catch)
   - `write_openbao(bao_path: str, fields: dict) -> bool` (pipe-to-python approach, NOT inline shell quoting)
3. Create `backends/onepassword.py` - port from `storage.py`:
   - `_root_token()` already in openbao.py, share it
   - `_read_1p_items() -> list[dict]`
   - `_read_1p_item_fields(item_id: str) -> dict`
   - `_find_1p_item(service_display: str, account: str) -> dict | None`
   - `_find_1p_any_google_item(account: str) -> dict | None`
   - `write_1password(...)` - create/update ARC vault items
4. Create `core/utils.py` with:
   ```python
   ZEROCLAW_HOST = "zeroclaw"
   VAULT_ADDR = "http://127.0.0.1:8200"
   OPENBAO_ROOT_TOKEN_ITEM_ID = "hl23px33remaz2xecl5ecvvaem"
   ONEPASSWORD_VAULT = "ARC"
   
   def account_slug(account: str) -> str:
       return account.replace("@", "-").replace(".", "-")
   ```
5. Update existing `cli/auth_cli.py` to call `backends/openbao.py` instead of `core/database.py`
6. Update existing `web/server.py` to call `backends/openbao.py` instead of `core/database.py`
7. Keep `core/database.py` only for `audit_log` table if you want to keep local audit history - or remove entirely

### Phase 2: Add Google OAuth platform

1. Create `core/platforms/google_services.py` - exact copy of `google-oauth-setup/services.py`
2. Create `core/platforms/google_oauth.py` - `GoogleOAuthManager(BasePlatformManager)`:
   - `validate_credential(token_dict)` - check refresh_token non-empty, client_id format
   - `test_connection(service_key, account, account_slug)` - delegates to `smoke_test()` from google_services.py
   - `get_required_credentials()` - returns list of required field names
   - `get_service_credentials(service_key, account, account_slug, interactive=True) -> dict | None` - OpenBao → 1P with optional push-back prompt
   - `write_all_tiers(service_key, slug, account, token_dict)` - OpenBao first, 1P second, local cache last chmod 600
3. Create `tools/oauth_flow.py` - exact copy of `google-oauth-setup/auth_flow.py`
4. Extend `core/models.py` Platform enum with Google services
5. Extend `core/models.py` CredentialType enum: add `OAUTH_REFRESH_TOKEN`, `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`

### Phase 3: Add Google CLI commands

1. Create `cli/google_commands.py` - port from `google-oauth-setup/google_oauth.py`:
   - `google setup --account EMAIL [--services S,S|--all] [--gcp-project ID]`
   - `google status --account EMAIL`
   - `google refresh --account EMAIL --service SVC`
   - `google smoke-test --account EMAIL [--service SVC]`
   - `google migrate --account EMAIL` (reads `~/.gmail-mcp/`, writes OpenBao + 1P + local cache, verifies, asks to delete)
2. Wire into main CLI entry point

### Phase 4: Add Google REST API routes

1. Create `web/google_routes.py`:
   ```
   GET  /credentials/google/{service}?account=EMAIL
        → lookup via GoogleOAuthManager.get_service_credentials()
        → auto-refresh if access token expired
        → return {access_token, refresh_token, client_id, client_secret, valid_until}
        → 404 if not found
   
   POST /credentials/google/setup
        → body: {account, service, gcp_project}
        → triggers InstalledAppFlow browser OAuth
        → writes all tiers
        → returns {status, services_authed}
   
   GET  /credentials/google/status?account=EMAIL
        → all 10 services with {authed: bool, has_token: bool, expires: ISO|null}
   ```
2. Mount in `web/server.py` with `app.include_router(google_router)`
3. Same JWT auth as existing endpoints

### Phase 5: Absorb authentication_boss

1. Create `cli/api_key_commands.py` - port from authentication_boss, but write to OpenBao:
   - `apikey add SERVICE KEY [--notes] [--org-slug]` → `write_openbao(f"secret/api-keys/{service}/{org_slug}", {api_key, notes})`
   - `apikey list [--service]` → `read_openbao` for each known path
   - `apikey get SERVICE [--org-slug]` → `read_openbao`
   - `apikey delete SERVICE [--org-slug]` → `ssh zeroclaw bao kv delete`
   - `apikey test [SERVICE]` → port test logic from `test_api_keys.py` (OpenAI, Stripe, Airtable, Slack tests)
   - `apikey report` → list all with test status
2. Create `tools/policy_manager.py` - port from `authentication_boss/policy_manager/manage_specs.py`
3. Copy `policy_manager/classification/` YAML files
4. Migrate existing `~/.cli.db` API keys to OpenBao paths (one-time migration script)

### Phase 6: Update arc-scripts auth.py

Two options - pick one:

**Option A (preferred):** Replace with HTTP client calling authentication_agent REST API:
```python
GET http://localhost:8401/credentials/google/gmail?account=me@advertisingreportcard.com
Authorization: Bearer {JWT}
```
Requires authentication_agent running as a daemon (LaunchAgent). Add fallback: if HTTP fails, fall back to direct OpenBao lookup (current auth.py logic).

**Option B (simpler):** Leave auth.py as-is. It already works (tested this session). Generalize the hardcoded account/service to accept parameters so other agents can import it. This avoids the daemon dependency.

Recommendation: **Option B for now, Option A when LaunchAgent is set up.**

### Phase 7: Archive deprecated repos

After Phase 3 is working and smoke tests pass:
```bash
gh repo archive arc-web/google-oauth-setup
gh repo archive arc-web/authentication-boss
```

Delete stale OpenBao paths:
```bash
# Old slug paths (advertisingreportcard instead of me-advertisingreportcard-com)
ssh zeroclaw 'VAULT_TOKEN=... bao kv delete secret/gmail/advertisingreportcard'
# ... repeat for all 10 services
```

---

## Hard constraints the other agent must not violate

1. **`write_openbao()` must use pipe-to-python approach** - NOT inline shell quoting. The old `f"{k}='{v}'"` approach breaks on special characters. The correct pattern is piping a Python script via stdin to `python3` on zeroclaw. See `google-oauth-setup/storage.py:write_openbao()` for the exact implementation.

2. **Never pass scopes to `Credentials()` when refreshing from a stored refresh_token** - Google rejects with `invalid_scope`. Only pass scopes if they are stored in the credential fields themselves. Pass `scopes=None` otherwise.

3. **Write order is always: OpenBao first, 1Password second, local cache last** - Never write disk before OpenBao. If OpenBao write fails, do not proceed to 1P or cache.

4. **`auth_flow.py` must not write to disk** - `run_oauth_flow()` returns a token dict. The caller writes to disk. This was fixed this session; do not revert it.

5. **account_slug() = `account.replace("@", "-").replace(".", "-")`** - This exact transformation. The OpenBao paths currently in production use this format. Do not change it.

6. **Root token fetched at runtime from 1Password** - never hardcoded, never cached to disk. Item ID: `hl23px33remaz2xecl5ecvvaem`, field: `root_token`, vault: `ARC`.

7. **No SQLite for credentials** - authentication_agent's SQLite is being removed from the credential path. Do not store any credential in SQLite.

---

## Verification checklist (run after each phase)

```bash
# Phase 1 - backends work
cd ~/ai/agents/development/authentication_agent
python3 -c "from backends.openbao import read_openbao; print(read_openbao('secret/gmail/me-advertisingreportcard-com').keys())"
# Expected: dict_keys(['account', 'client_id', 'client_secret', 'refresh_token'])

# Phase 2 - Google platform works
python3 -c "
from core.platforms.google_oauth import GoogleOAuthManager
m = GoogleOAuthManager()
creds = m.get_service_credentials('gmail', 'me@advertisingreportcard.com', 'me-advertisingreportcard-com', interactive=False)
print('ok:', list(creds.keys()))
"

# Phase 3 - CLI works
python3 -m cli.google_commands smoke-test --account me@advertisingreportcard.com
# Expected: all 10 services ok

# Phase 4 - REST API works
python3 -m web.server &
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8401/credentials/google/gmail?account=me@advertisingreportcard.com" | python3 -m json.tool

# Phase 5 - API keys in OpenBao
python3 -m cli.api_key_commands add openai "$OPENAI_KEY" --notes "main key"
python3 -m cli.api_key_commands get openai
# Verify it's in OpenBao: ssh zeroclaw 'VAULT_TOKEN=... bao kv get secret/api-keys/openai/default'

# Phase 6 - auth.py still works
python3 -c "
import sys; sys.path.insert(0, '/Users/home/ai/infra/arc-scripts/gmail-mgmt')
from auth import get_gmail_credentials
c = get_gmail_credentials()
print('auth ok:', c.valid)
"
```
