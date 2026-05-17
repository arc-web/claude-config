# Plan: google-oauth-setup - One-Shot Google OAuth CLI

## Context

During session 2026-05-09 we manually set up OAuth for 10 Google services for `me@advertisingreportcard.com`:
- Created GCP Desktop app OAuth client
- Enabled each API via GCP Console
- Ran InstalledAppFlow for each service (10 separate scripts)
- Stored all tokens in OpenBao + 1Password

The 10 setup scripts are identical except for scopes and token filename. All of this should be one idempotent CLI that works for any Google account, any set of services, any future account.

## Goal

Single Python CLI: `google_oauth.py setup --account me@foo.com --services gmail,drive,ads`

Covers: GCP client setup → API enable (browser links) → OAuth flows → OpenBao → 1Password → smoke test.

---

## Repo

**GitHub:** `arc-web/google-oauth-setup`  
**Local:** `~/ai/infra/google-oauth-setup/`  
**Category:** `infra` - it's a tooling/credential management repo

---

## File Structure

```
~/ai/infra/google-oauth-setup/
  google_oauth.py       # Typer CLI - entry point
  services.py           # service registry: scopes, API IDs, smoke tests
  storage.py            # OpenBao + 1Password read/write
  auth_flow.py          # InstalledAppFlow wrapper (replaces all 10 setup_*.py)
  requirements.txt
  .env.1p               # op:// refs for client_id/secret
  .gitignore
  README.md
```

---

## Service Registry (services.py)

Each service is one dict entry:

```python
SERVICES = {
    "gmail": {
        "display": "Gmail",
        "api_ids": ["gmail.googleapis.com"],
        "scopes": [
            "https://www.googleapis.com/auth/gmail.modify",
            "https://www.googleapis.com/auth/gmail.settings.basic",
            "https://www.googleapis.com/auth/gmail.send",
            "https://www.googleapis.com/auth/gmail.compose",
        ],
        "token_suffix": "gmail",          # ~/.google-oauth/{account}/gmail.json
        "openbao_path": "secret/gmail",   # + /{account_slug}
        "smoke_test": "gmail_test",       # fn name in services.py
    },
    "drive":          { ... },
    "gtm":            { ... },
    "analytics":      { ... },
    "google-ads":     { ... },
    "search-console": { ... },
    "gmb":            { ... },
    "youtube":        { ... },
    "calendar":       { ... },
    "people":         { ... },
}
```

---

## CLI Commands (google_oauth.py)

### `setup`
```
google_oauth.py setup \
  --account me@foo.com \
  --services gmail,drive,ads      # or --all
  --gcp-project 510919487798      # optional, for API enable links
```

Flow:
1. Load client_id + client_secret: OpenBao `secret/google-oauth-client/{account_slug}` → 1P search `Google * OAuth - {account}` → prompt user to paste
2. Write `~/.google-oauth/client.json` for this account
3. Print API enable URLs for all requested services, open in browser
4. Wait: user types `done` when all APIs enabled
5. Run auth flow for each service sequentially (browser opens, user signs in)
6. Store token to `~/.google-oauth/{account_slug}/{service}.json`
7. Push to OpenBao: `secret/{service}/{account_slug}`
8. Create/update 1Password item: `Google {Service} OAuth - {account}`
9. Run smoke test for each service
10. Print summary table: service | token file | OpenBao | 1P | smoke test

### `status`
```
google_oauth.py status --account me@foo.com
```
Shows which services are authed, token expiry, OpenBao path.

### `refresh`
```
google_oauth.py refresh --account me@foo.com --service gmail
```
Re-runs InstalledAppFlow for one service. Updates OpenBao + 1P.

### `smoke-test`
```
google_oauth.py smoke-test --account me@foo.com [--service gmail]
```
Verifies each token works by making a lightweight API call.

---

## Token Storage Layout

Local (machine-local, not committed):
```
~/.google-oauth/
  {account_slug}/           # e.g. me-advertisingreportcard-com/
    client.json             # client_id + secret (from GCP Desktop app)
    gmail.json
    drive.json
    gtm.json
    analytics.json
    google-ads.json
    search-console.json
    gmb.json
    youtube.json
    calendar.json
    people.json
```

Migrate current tokens from `~/.gmail-mcp/credentials.json.*` → `~/.google-oauth/me-advertisingreportcard-com/*.json` as part of first run.

OpenBao (canonical, always read by agents):
```
secret/google-oauth-client/{account_slug}    # shared client_id + secret for the account
  client_id
  client_secret
  gcp_project

secret/{service}/{account_slug}              # per-service tokens (already populated)
  refresh_token
  client_id
  client_secret
  account
```

Client credential discovery order (in storage.py):
1. OpenBao `secret/google-oauth-client/{account_slug}`
2. 1Password: search for any `Google * OAuth - {account}` item, extract client_id/secret
3. Prompt user to paste client JSON from GCP Console

1Password (backup, ARC vault):
```
"Google {Service} OAuth - {account}"
  client_id
  client_secret[password]
  refresh_token[password]
  account
  notesPlain: GCP project {id}. Auth {date}. OpenBao: secret/{service}/{account_slug}. Authorized via {account}.
```

---

## auth_flow.py

Replaces all 10 `setup_*.py` scripts. Single function:

```python
def run_oauth_flow(client_json_path, scopes, token_output_path, account_hint=""):
    """Run InstalledAppFlow, write token JSON, return Credentials."""
```

Uses `OAUTHLIB_RELAX_TOKEN_SCOPE=1` to handle Google's scope remapping (needed for People API).

---

## storage.py

```python
def write_openbao(service, account_slug, fields: dict): ...
def read_openbao(service, account_slug) -> dict: ...
def write_1password(service, account, client_id, client_secret, refresh_token, gcp_project): ...
```

Uses SSH to zeroclaw for OpenBao writes (same pattern as current session).  
Uses `op item create/edit` for 1Password.

---

## Migration: existing tokens

During first `setup` run for `me@advertisingreportcard.com`, add a `--migrate` flag that:
- Reads all 10 tokens from `~/.gmail-mcp/credentials.json.*`
- Writes to new `~/.google-oauth/me-advertisingreportcard-com/` layout
- Does NOT re-auth (tokens are still valid)
- Just updates OpenBao + 1P paths to point at new location

---

## Smoke Tests (in services.py)

| Service | Test call |
|---------|-----------|
| Gmail | `messages().list(userId="me", maxResults=1)` |
| Drive | `files().list(pageSize=1)` |
| GTM | `accounts().list()` |
| Analytics | `management().accounts().list()` |
| Google Ads | validate refresh token via token refresh only |
| Search Console | `sites().list()` |
| GMB | validate refresh token only (API v4 requires extra setup) |
| YouTube | `channels().list(part="snippet", mine=True)` |
| Calendar | `calendarList().list()` |
| People | `people().get(resourceName="people/me", personFields="names")` |

---

## README.md structure

- Prerequisites (Python 3.11+, op CLI, SSH access to zeroclaw)
- GCP setup: create project, create Desktop app OAuth client, note client_id + secret
- Usage: `setup`, `status`, `refresh`, `smoke-test`
- Adding a new service (edit services.py)
- How tokens are stored (local → OpenBao → 1P)
- Re-auth when tokens expire

---

## Files to create (new repo)

- `google_oauth.py` - ~200 lines
- `services.py` - ~150 lines
- `auth_flow.py` - ~60 lines
- `storage.py` - ~100 lines
- `requirements.txt` - google-auth-oauthlib, google-api-python-client, typer, rich, requests
- `.env.1p` - op:// refs
- `.gitignore`
- `README.md`

## Files to delete after migration

- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_drive_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_gtm_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_ga_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_google_ads_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_search_console_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_gmb_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_youtube_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_calendar_oauth.py`
- `/Users/home/ai/infra/arc-scripts/gmail-mgmt/setup_people_oauth.py`

## Verification

1. `python3 google_oauth.py setup --account test@example.com --all --gcp-project <id>` - full flow with a test account
2. `python3 google_oauth.py status --account me@advertisingreportcard.com` - shows all 10 services green
3. `python3 google_oauth.py smoke-test --account me@advertisingreportcard.com` - all pass
4. `python3 google_oauth.py refresh --account me@advertisingreportcard.com --service gmail` - re-auths just Gmail
