# Plan: Proper OpenBao + 1Password Credential Flow

## Context

The credential system exists but is wired incorrectly. OpenBao is KV v2 running in Docker on zeroclaw at `http://127.0.0.1:8200`. Auth method is root token fetched from 1Password item `hl23px33remaz2xecl5ecvvaem` field `root_token`. All AppRoles are read-only - only root token can write. The current code has two structural problems: (1) it calls OpenBao correctly in some places but not others, and (2) there is no "found in 1P but not OpenBao - want to push?" recovery flow. This plan fixes both.

---

## How OpenBao Actually Works (Ground Truth)

- **Mount**: `secret/` is KV v2 Docker container on zeroclaw port 8200
- **Auth**: Root token only for writes. `op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token --reveal`
- **Read**: `bao kv get -format=json secret/{path}` returns `{data: {data: {fields...}, metadata: {...}}}`
- **Write**: `bao kv put secret/{path} key=value key=value` - ALL via SSH to zeroclaw
- **Shell quoting bug**: Current `write_openbao` uses inline f-string quoting. Refresh tokens contain `+`, `/`, `=` chars. Single-quote wrapping `f"{k}='{v}'"` breaks if value contains `'`. Must use temp-script-on-zeroclaw pattern instead.
- **KV response extraction**: `data.get("data", {}).get("data", {})` is correct for KV v2

## How 1Password Fits

- **Field names in 1P items**: `client_id` (plain), `client_secret` (password), `refresh_token` (password), `account` (plain), `notesPlain` (metadata)
- **Item title pattern**: `Google {Service} OAuth - {account_localpart}` in ARC vault
- **Current gap**: `get_client_credentials` reads `client_id` + `client_secret` from 1P but NOT `refresh_token` or `account` - those are written but never read back
- **Full recovery possible**: 1P has all 4 fields. If OpenBao is empty, full credentials can be reconstructed from 1P alone.

---

## Lookup Chain (Canonical)

```
Need credentials for a service/account?
  1. OpenBao: bao kv get secret/{service}/{slug}
     → if fields present with refresh_token + client_id + client_secret → use them
  
  2. OpenBao missing or incomplete:
     → search 1Password ARC vault for "Google {service} OAuth - {account_localpart}"
     → if found: read client_id, client_secret, refresh_token, account
     → prompt: "Found in 1Password but not OpenBao. Push to OpenBao now? [y/N]"
       → yes: write_openbao(path, all 4 fields) - then return credentials
       → no: return credentials from 1P only (local session only, no persistence)
  
  3. Neither found:
     → return None (caller prompts user to run setup)
```

---

## Write Order (Canonical)

```
New OAuth flow completed:
  1. Hold token dict in memory (never write to disk first)
  2. write_openbao() → OpenBao
  3. write_1password() → 1P backup
  4. write_local_cache() → ~/.google-oauth/{slug}/{service}.json + chmod 600
```

---

## Files to Change

### 1. `storage.py` - Core fixes

**Fix A: Shell quoting bug in `write_openbao` (line 27)**
Current: `kv_args = " ".join(f"{k}='{v}'" for k, v in fields.items())`  
Breaks when value contains `'`. Fix: write a temp Python script to zeroclaw, execute it, delete it.

```python
def write_openbao(bao_path: str, fields: dict) -> bool:
    root_token = _root_token()
    # Write temp script to zeroclaw to avoid shell quoting issues with token values
    import tempfile, os
    script_lines = [
        "import subprocess, json",
        f"env = {{'VAULT_TOKEN': {repr(root_token)}, 'VAULT_ADDR': 'http://127.0.0.1:8200'}}",
        f"fields = {repr(fields)}",
        "args = ['/usr/local/bin/bao', 'kv', 'put', {repr(bao_path)}]",
        "args += [f'{k}={v}' for k, v in fields.items()]",
        "r = subprocess.run(args, env={**__import__('os').environ, **env}, capture_output=True)",
        "exit(r.returncode)",
    ]
    script = "\n".join(script_lines)
    # scp temp script, execute, delete
    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(script)
        local_path = f.name
    try:
        subprocess.run(["scp", "-q", local_path, "zeroclaw:/tmp/_bao_write.py"],
                       capture_output=True, timeout=10)
        result = subprocess.run(["ssh", ZEROCLAW_HOST, "python3 /tmp/_bao_write.py && rm /tmp/_bao_write.py"],
                                capture_output=True, text=True, timeout=30)
        return result.returncode == 0
    finally:
        os.unlink(local_path)
```

**Fix B: Expand `get_client_credentials` to return full token dict + recovery prompt**

New signature: `get_service_credentials(service_key, account, account_slug) -> dict | None`

Returns all 4 fields: `{client_id, client_secret, refresh_token, account}` or `None`.

Flow:
1. OpenBao path from `SERVICES[service_key]['openbao_path']/{slug}`
2. Also check `secret/google-oauth-client/{slug}` for client creds if service path missing
3. 1P fallback: search by `Google {service_display} OAuth - {account_localpart}`
4. If 1P has it but OpenBao doesn't: prompt user → optionally push to OpenBao
5. Return full dict or None

Keep old `get_client_credentials(account, slug)` for backward compat - call new function with `service_key=None` to get client creds only.

**Fix C: `read_openbao` - add SSH reachability check**

Wrap in try/except for subprocess.TimeoutExpired. Return `None` on timeout (offline mode). Log reason clearly.

---

### 2. `auth_flow.py` - Stop writing to disk

**File:** `/Users/home/ai/infra/google-oauth-setup/auth_flow.py`  
**Line 24:** Currently writes token to `token_output_path` before returning.

Change `run_oauth_flow(client_json_path, scopes, token_output_path=None)`:
- Remove disk write from inside the function
- Return token dict always
- `token_output_path` parameter removed or made unused (caller writes if needed)

---

### 3. `google_oauth.py` - Fix write order + migrate()

**`setup()` command:**
- `run_oauth_flow()` → returns token dict (no disk write)
- `write_service_token()` → OpenBao
- `write_1password()` → 1P  
- THEN: write local cache `~/.google-oauth/{slug}/{service}.json` + `chmod 600`

**`write_client_file()` (line 79-93):**
- Still write to `~/.google-oauth/{slug}/client.json`
- Add `os.chmod(client_path, 0o600)` immediately after write

**`migrate()` - full rewrite:**
Old: reads `~/.gmail-mcp/` tokens → copies to `~/.google-oauth/` (file-to-file, never touches OpenBao)

New flow:
1. Read each token file from `~/.gmail-mcp/`
2. Parse JSON, extract `refresh_token`
3. Get `client_id` + `client_secret` from OpenBao or 1P (they're already there from original setup)
4. Call `write_service_token()` → writes all fields to OpenBao
5. Call `write_1password()` → updates 1P with refresh_token
6. Verify: `read_openbao()` confirms the path has the value
7. After all 10 verified: ask user "Delete ~/.gmail-mcp/? [y/N]"
8. Only on explicit yes: `shutil.rmtree(~/.gmail-mcp/)`

---

### 4. `auth.py` - OpenBao-first rewrite

**File:** `/Users/home/ai/infra/arc-scripts/gmail-mgmt/auth.py`  
**`get_gmail_credentials()`** - full rewrite:

```python
def get_gmail_credentials():
    slug = "me-advertisingreportcard-com"
    account = "me@advertisingreportcard.com"
    
    # 1. Try OpenBao
    fields = read_openbao(f"secret/gmail/{slug}")
    
    # 2. If OpenBao unreachable or empty, try 1P
    if not fields or not fields.get("refresh_token"):
        fields = _get_from_1password(account)
        if fields:
            answer = input("Credentials found in 1Password but not OpenBao. Push to OpenBao? [y/N]: ")
            if answer.lower() == 'y':
                write_openbao(f"secret/gmail/{slug}", fields)
    
    if not fields or not fields.get("refresh_token"):
        raise FileNotFoundError("No credentials found in OpenBao or 1Password")
    
    creds = google.oauth2.credentials.Credentials(
        token=None,
        refresh_token=fields["refresh_token"],
        client_id=fields["client_id"],
        client_secret=fields["client_secret"],
        token_uri="https://oauth2.googleapis.com/token",
    )
    
    if not creds.valid:
        creds.refresh(google.auth.transport.requests.Request())
        # Write refreshed token back to OpenBao (access token is ephemeral, refresh_token may rotate)
        if creds.refresh_token and creds.refresh_token != fields["refresh_token"]:
            write_openbao(f"secret/gmail/{slug}", {**fields, "refresh_token": creds.refresh_token})
    
    return creds
```

Remove all `~/.gmail-mcp/` references. Add `from storage import read_openbao, write_openbao`.

---

## Execution Order

1. Fix `write_openbao` quoting bug in `storage.py` (no deps, prevents data corruption)
2. Expand `get_client_credentials` → `get_service_credentials` with 1P→OpenBao recovery prompt
3. Fix `auth_flow.py` - return dict, no disk write
4. Fix `google_oauth.py` setup() write order + migrate() rewrite
5. Rewrite `auth.py` - OpenBao first
6. Run `migrate()` against `~/.gmail-mcp/` - verify each service in OpenBao
7. Delete `~/.gmail-mcp/` only after step 6 confirms all 10 verified
8. chmod 600 all `~/.google-oauth/me-advertisingreportcard-com/*.json`
9. Commit all files

---

## Verification

```bash
# After rewrite: delete local gmail token, confirm OpenBao is the only source
rm ~/.google-oauth/me-advertisingreportcard-com/gmail.json
cd ~/ai/infra/arc-scripts/gmail-mgmt
python3 -c "from auth import get_gmail_credentials; c = get_gmail_credentials(); print('ok:', c.valid)"

# Smoke test all 10 services from OpenBao
cd ~/ai/infra/google-oauth-setup
python3 google_oauth.py smoke-test --account me@advertisingreportcard.com

# Confirm 1P fallback + recovery prompt works
# (manually remove one OpenBao secret, run get_service_credentials, verify prompt fires)

# Verify no plaintext tokens left after migrate + delete
ls ~/.gmail-mcp/ 2>&1  # should be "No such file"
ls -la ~/.google-oauth/me-advertisingreportcard-com/
stat -f "%A" ~/.google-oauth/me-advertisingreportcard-com/*.json  # should all be 600
```

---

## Files Touched

| File | Change |
|------|--------|
| `google-oauth-setup/storage.py` | Fix quoting bug, expand credential lookup, add 1P→OpenBao recovery |
| `google-oauth-setup/auth_flow.py` | Return dict, remove disk write |
| `google-oauth-setup/google_oauth.py` | Write order fix, migrate() rewrite |
| `arc-scripts/gmail-mgmt/auth.py` | OpenBao-first rewrite |
| `~/.gmail-mcp/` | Delete after verified |
| `~/.google-oauth/me-advertisingreportcard-com/*.json` | chmod 600 |
