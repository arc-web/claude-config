# Plan: Credential System Audit + Fix

## Context

Every Google service OAuth token for `me@advertisingreportcard.com` is stored in plaintext on local disk (`~/.gmail-mcp/`, `~/.google-oauth/`). The memory files say OpenBao is canonical. The code doesn't touch OpenBao for reads. These contradict each other. This plan catalogs every failure and fixes the chain.

---

## Failure Registry (10 items, all critical)

### F1 - auth.py reads filesystem only, never OpenBao

**File:** `/Users/home/ai/infra/arc-scripts/gmail-mgmt/auth.py`  
**Lines:** 25-31 (path construction), 34-49 (file load), 73-81 (refresh writes back to disk)  
**Violation:** `get_gmail_credentials()` reads `~/.gmail-mcp/gcp-oauth.keys.json` and `~/.gmail-mcp/credentials.json.advertisingreportcard`. No OpenBao lookup. Raises `FileNotFoundError` with no fallback.  
**Impact:** Every agent using Gmail bypasses OpenBao entirely.

### F2 - All Gmail agents use the broken auth path

**Files:**
- `/Users/home/ai/agents/comms/comms_agent/comms_apps/gmail_thread_app/gmail_thread_agent/gmail_thread_agent.py` (line 17)
- `/Users/home/ai/agents/development/client_director/scripts/gmail_location_extractor.py` (line 22)
- `/Users/home/ai/agents/development/client_director/scripts/extract_locations_from_gmail.py` (line 20)

**Violation:** All `from auth import get_gmail_credentials` - inherits F1's broken chain.

### F3 - google_oauth.py writes plaintext client.json

**File:** `/Users/home/ai/infra/google-oauth-setup/google_oauth.py`  
**Lines:** 79-93 (`write_client_file()`)  
**Violation:** Writes `client_id` + `client_secret` to `~/.google-oauth/{account}/client.json` in plaintext. Used as the local "credential file" for all OAuth flows.

### F4 - google_oauth.py writes tokens to disk before OpenBao

**File:** `/Users/home/ai/infra/google-oauth-setup/google_oauth.py`  
**Lines:** 136 (`run_oauth_flow()` → writes disk), then 139 (`write_service_token()` → writes OpenBao)  
**Violation:** Plaintext write happens first. If process crashes between lines 136-139, token lives on disk only, never reaches OpenBao.

### F5 - migrate() copies file-to-file, not file-to-OpenBao

**File:** `/Users/home/ai/infra/google-oauth-setup/google_oauth.py`  
**Lines:** 233-267  
**Violation:** Copies `~/.gmail-mcp/credentials.json.*` → `~/.google-oauth/*/service.json`. Token never goes to OpenBao. Migration is cosmetic.

### F6 - 22 plaintext credential files on disk right now

**Locations:**
- `~/.gmail-mcp/` - 11 files (gcp-oauth.keys.json + 10 token files)
- `~/.google-oauth/me-advertisingreportcard-com/` - 11 files (client.json + 10 token files)

**Violation:** All contain live refresh tokens and client secrets. No encryption. No TTL. No restricted permissions.

### F7 - auth_flow.py writes refresh token to disk as primary action

**File:** `/Users/home/ai/infra/google-oauth-setup/auth_flow.py`  
**Line:** 24 (`token_output_path.write_text(...)`)  
**Violation:** The OAuth flow writes to disk first. OpenBao is called externally after the fact.

### F8 - Hardcoded token paths in other agent scripts

**Files:**
- `automated_contacts_location_sync.py` lines 40-44: hardcoded `~/.gmail-mcp/token.json` paths
- `check_setup.py` lines 16-19: same

**Violation:** These bypass `auth.py` entirely and read fixed local paths.

### F9 - auth.py refresh writes new access token back to plaintext disk

**File:** `/Users/home/ai/infra/arc-scripts/gmail-mgmt/auth.py`  
**Lines:** 69-81  
**Violation:** On token refresh, new access token written to `~/.gmail-mcp/credentials.json.advertisingreportcard`. Token stays on disk indefinitely with no cleanup.

### F10 - Memory files describe aspirational state, not actual code

**Files:**
- `gmail_access.md` - claims OpenBao is authoritative, auth.py doesn't touch it
- `credentials_architecture.md` - states OpenBao is canonical, no agent reads from it
- `agent_credential_map.md` - maps per-agent OpenBao paths that no agent reads

---

## Canonical credential chain (per credentials_architecture.md)

```
Agent needs token
  → OpenBao (ssh zeroclaw, secret/{service}/{account_slug})
  → 1Password (backup, admin recovery only)
  → Local cache file (~/.google-oauth/...) as short-TTL fallback only
  → NEVER: hardcoded paths, plaintext primary storage, filesystem-first reads
```

---

## Fix Plan

### Fix 1: Rewrite auth.py - OpenBao first, local cache fallback

**File:** `/Users/home/ai/infra/arc-scripts/gmail-mgmt/auth.py`

New flow in `get_gmail_credentials()`:
1. Try OpenBao: `ssh zeroclaw bao kv get -format=json secret/gmail/me-advertisingreportcard-com`
2. Extract `refresh_token`, `client_id`, `client_secret`
3. Build `Credentials` object, refresh if expired
4. Cache refreshed token to `~/.google-oauth/me-advertisingreportcard-com/gmail.json` (TTL: 50min, same as Google's access token lifetime)
5. On refresh, write updated access token back to OpenBao (not just local disk)
6. Local file fallback only when OpenBao SSH unreachable (offline mode)

**Remove:** all hardcoded references to `~/.gmail-mcp/`

### Fix 2: Update google_oauth.py - OpenBao write BEFORE local cache

**File:** `/Users/home/ai/infra/google-oauth-setup/google_oauth.py`

In `setup()` command:
1. `run_oauth_flow()` → get token dict in memory (do NOT write to disk yet)
2. `write_service_token()` → write to OpenBao first
3. `write_1password()` → write to 1P backup
4. Write local cache file LAST (as cache, not primary)
5. `chmod 600` on all local token files

In `write_client_file()`:
- Still writes to `~/.google-oauth/{account}/client.json` (acceptable as cache)
- Add `chmod 600` immediately after write

### Fix 3: Fix auth_flow.py - return token dict, don't write to disk

**File:** `/Users/home/ai/infra/google-oauth-setup/auth_flow.py`

Change `run_oauth_flow()` to return the token dict without writing to disk. Caller (google_oauth.py) writes to disk after OpenBao/1P writes succeed.

### Fix 4: Fix migrate() to read from OpenBao and verify

**File:** `/Users/home/ai/infra/google-oauth-setup/google_oauth.py`

`migrate()` should:
1. Read tokens from `~/.gmail-mcp/` (existing plaintext)
2. Write each to OpenBao (the actual migration target)
3. Verify OpenBao has the correct values
4. Only THEN delete the plaintext files
5. Update memory

### Fix 5: Delete ~/.gmail-mcp/ after confirming OpenBao has all tokens

After Fix 4 is verified:
- `rm -rf ~/.gmail-mcp/` (all 11 files)
- `~/.google-oauth/` stays as local cache location
- `chmod 600 ~/.google-oauth/me-advertisingreportcard-com/*.json` on all files

### Fix 6: Fix hardcoded paths in agent scripts

**Files:**
- `automated_contacts_location_sync.py` - replace hardcoded path list with `get_gmail_credentials()` call
- `check_setup.py` - same

### Fix 7: Update memory to reflect actual implementation

**Files to update after fixes implemented:**
- `gmail_access.md` - update auth chain to show OpenBao → local cache → error (not file-first)
- `credentials_architecture.md` - add gmail/google services to the credential map
- `agent_credential_map.md` - add actual OpenBao paths confirmed working

---

## Verification

After all fixes:
```bash
# 1. Delete local files, verify OpenBao is the only source
rm ~/.gmail-mcp/credentials.json.advertisingreportcard
python3 -c "from auth import get_gmail_credentials; c = get_gmail_credentials(); print('auth ok')"
# Should succeed by reading from OpenBao

# 2. Verify all 10 services can auth from OpenBao only
cd ~/ai/infra/google-oauth-setup
python3 google_oauth.py smoke-test --account me@advertisingreportcard.com

# 3. Verify agents work
cd ~/ai/agents/comms/comms_agent
python3 -c "from comms_apps.gmail_thread_app.gmail_thread_agent.gmail_thread_agent import GmailThreadAgent; print('agent ok')"
```

---

## File touch list

| File | Change |
|------|--------|
| `arc-scripts/gmail-mgmt/auth.py` | Rewrite: OpenBao first, cache fallback |
| `google-oauth-setup/auth_flow.py` | Return dict, don't write to disk |
| `google-oauth-setup/google_oauth.py` | OpenBao first, local cache last, fix migrate() |
| `agents/.../gmail_location_extractor.py` | Remove hardcoded paths |
| `agents/.../extract_locations_from_gmail.py` | Remove hardcoded paths |
| `agents/.../automated_contacts_location_sync.py` | Remove hardcoded paths |
| `agents/.../check_setup.py` | Remove hardcoded paths |
| `~/.gmail-mcp/` | Delete after OpenBao verified |
| `memory/gmail_access.md` | Update auth chain description |
| `memory/agent_credential_map.md` | Add Google service paths |

---

## Execution order

1. Fix auth_flow.py (smallest, no deps)
2. Fix google_oauth.py (depends on auth_flow fix)
3. Rewrite auth.py (depends on OpenBao paths being populated - they already are)
4. Test auth.py with local file deleted
5. Fix agent hardcoded paths
6. Run migrate() to formally re-migrate from ~/.gmail-mcp → OpenBao
7. Delete ~/.gmail-mcp/ after verification
8. Update memory files
9. Commit all changes
