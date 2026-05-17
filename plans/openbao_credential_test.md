# OpenBao Full Credential Test Plan

## Context

We've built the following in the last two sessions:
- `vault.aibrainbuilders.com` → Cloudflare Tunnel → `openbao` container on zeroclaw
- `claude-code-local` AppRole (reads from local Mac directly, own fingerprint)
- `github-actions` AppRole (5-min TTL, plane-read policy only)
- `mike` + `patrick` userpass accounts (team-read policy)
- `plane-sync.yml` GitHub Actions workflow (fetches Plane key from OpenBao via AppRole at runtime)

This plan verifies every identity, every policy boundary, and the live GitHub Actions → Plane sync.

---

## Test 1: Health + Connectivity

```python
# vault.aibrainbuilders.com reachable and unsealed
import urllib.request, json
d = json.loads(urllib.request.urlopen('https://vault.aibrainbuilders.com/v1/sys/health').read())
assert not d['sealed'], "SEALED"
assert d['initialized'], "NOT INIT"
print(f"OK: OpenBao {d['version']} healthy")
```

---

## Test 2: claude-code-local AppRole

**Auth + multi-path reads + scope enforcement:**

```python
import urllib.request, json, subprocess

item = json.loads(subprocess.check_output(
    ['op','item','get','OpenBao AppRole - claude-code-local','--vault','ARC','--format','json','--reveal'],
    text=True))
fields = {f['label']: f.get('value','') for f in item['fields']}

def vault_auth(role_id, secret_id):
    r = urllib.request.urlopen(urllib.request.Request(
        'https://vault.aibrainbuilders.com/v1/auth/approle/login',
        data=json.dumps({'role_id': role_id, 'secret_id': secret_id}).encode(),
        headers={'Content-Type': 'application/json', 'User-Agent': 'vault-client/1.0'},
        method='POST'))
    return json.loads(r.read())['auth']['client_token']

def vault_read(token, path):
    r = urllib.request.urlopen(urllib.request.Request(
        f'https://vault.aibrainbuilders.com/v1/{path}',
        headers={'X-Vault-Token': token, 'User-Agent': 'vault-client/1.0'}))
    return json.loads(r.read())['data']['data']

token = vault_auth(fields['role_id'], fields['secret_id'])
print(f"AUTH OK: {token[:12]}...")

# Paths that MUST succeed (claude-code-read policy)
paths = [
    'secret/data/shared/plane-api-key',
    'secret/data/shared/github-actions-approle',
    'secret/data/hosting/cloudflare-api',
    'secret/data/tool-infra/supabase-url',
]
for p in paths:
    try:
        val = vault_read(token, p)
        print(f"READ OK: {p}")
    except Exception as e:
        print(f"READ FAIL: {p} - {e}")

# Path that MUST be denied (outside policy)
try:
    vault_read(token, 'secret/data/human-only/test')
    print("SCOPE FAIL: read human-only - should have been denied")
except urllib.error.HTTPError as e:
    print(f"SCOPE OK: human-only denied ({e.code})")
```

---

## Test 3: github-actions AppRole

**Auth + plane-key read + scope enforcement (narrower than claude-code-local):**

```python
# Fetch github-actions approle creds from OpenBao
ROOT = subprocess.check_output(
    ['op','item','get','hl23px33remaz2xecl5ecvvaem','--vault','ARC','--reveal','--fields','root_token'],
    text=True).strip()
creds_raw = subprocess.check_output(['ssh','zeroclaw',
    f"VAULT_ADDR='http://127.0.0.1:8200' BAO_TOKEN='{ROOT}' /usr/local/bin/bao kv get -format=json secret/shared/github-actions-approle"],
    text=True)
creds = json.loads(creds_raw)['data']['data']

token = vault_auth(creds['role_id'], creds['secret_id'])
print(f"github-actions AUTH OK: {token[:12]}...")

# MUST succeed
val = vault_read(token, 'secret/data/shared/plane-api-key')
assert len(val['value']) == 64
print("READ OK: plane-api-key (64 chars)")

# MUST be denied (outside plane-read scope)
for p in ['secret/data/shared/github-actions-approle', 'secret/data/hosting/cloudflare-api']:
    try:
        vault_read(token, p)
        print(f"SCOPE FAIL: {p} should be denied")
    except urllib.error.HTTPError as e:
        print(f"SCOPE OK: {p} denied ({e.code})")
```

---

## Test 4: userpass mike + patrick

```python
def userpass_auth(username, password):
    r = urllib.request.urlopen(urllib.request.Request(
        f'https://vault.aibrainbuilders.com/v1/auth/userpass/login/{username}',
        data=json.dumps({'password': password}).encode(),
        headers={'Content-Type': 'application/json', 'User-Agent': 'vault-client/1.0'},
        method='POST'))
    d = json.loads(r.read())
    return d['auth']['client_token'], d['auth']['policies']

for user in ['mike', 'patrick']:
    # Get password from 1P
    pw = subprocess.check_output(
        ['op','item','get',f'OpenBao userpass - {user}','--vault','ARC','--fields','password','--reveal'],
        text=True).strip()
    token, policies = userpass_auth(user, pw)
    print(f"{user} AUTH OK: policies={policies}")

    # MUST succeed (team-read)
    vault_read(token, 'secret/data/shared/plane-api-key')
    print(f"{user} READ OK: shared/plane-api-key")

    # MUST be denied (outside team-read scope)
    try:
        vault_read(token, 'secret/data/hermes/github-pat')
        print(f"SCOPE FAIL: {user} read hermes/ - should be denied")
    except urllib.error.HTTPError as e:
        print(f"SCOPE OK: {user} denied hermes/ ({e.code})")
```

---

## Test 5: Audit Log Fingerprinting

After running Tests 2-4, verify all identities appear distinctly:

```bash
ssh zeroclaw "grep -o '\"display_name\":\"[^\"]*\"' /openbao/audit/audit.log | sort | uniq -c | sort -rn | head -20"
```

Expected output includes:
- `"display_name":"approle-claude-code-local"` (or similar - AppRole accessor name)
- `"display_name":"approle-github-actions"`
- `"display_name":"userpass-mike"`
- `"display_name":"userpass-patrick"`

---

## Test 6: plane-sync Live GitHub Actions Test

**Open a test PR on arc-web/reportcard-agent with a Linked Task block:**

1. Create test branch on reportcard-agent
2. Open PR with body containing:
   ```
   ## Linked Task
   [AGENT-322 - OpenBao team access + Plane-GitHub bridge rebuild](https://arc.todovibes.com/todovibes/issues/AGENT-322)
   ```
3. Check GitHub Actions tab → `plane-sync` workflow runs → exits 0
4. Check AGENT-322 in Plane → state = In Progress, comment with PR link
5. Close PR without merging → AGENT-322 → state = Todo
6. Re-open and merge → AGENT-322 → state = Done

*Note: AGENT-322 is already Done. Use a different open task or create a throwaway AGENT task for the merge test.*

---

## Execution Order

1. Test 1 (health) - verify tunnel alive
2. Test 2 (claude-code-local) - primary local identity
3. Test 3 (github-actions) - narrow scope AppRole
4. Test 4 (mike + patrick) - human userpass
5. Test 5 (audit log) - confirm fingerprints distinct
6. Test 6 (plane-sync) - live PR end-to-end

All tests 1-5 run as a single Python script with `dangerouslyDisableSandbox: true`.
Test 6 requires `gh pr create` + watching Actions tab.

---

## Files involved (read-only for this test)

- `~/.claude/skills/plane-pm/SKILL.md` - credential fetch pattern
- `~/ai/infra/review-workflows/.github/workflows/plane-sync.yml` - workflow being tested
- `/openbao/audit/audit.log` on zeroclaw - audit verification
