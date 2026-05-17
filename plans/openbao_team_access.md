# OpenBao Team Access - Per-Member Identity + Local Agent Credential Flow

## Context

Right now Claude Code (Mike) accesses OpenBao by SSH-ing into zeroclaw and running commands remotely. There is no per-member identity - everything runs under the root token or a shared AppRole. No fingerprinting.

Goal: every team member (Mike, Patrick, future members) authenticates to OpenBao with their own identity from their local machine. Every credential read is attributed to them in the audit log. Local agents (Claude Code, Codex) use OpenBao as the primary credential source with 1P as declared-emergency-only fallback. No SSH required. No key copying.

---

## What we're building (plain English)

Three pieces:

1. **OpenBao on the internet (via Cloudflare Tunnel)** - cloudflared is already running on zeroclaw. We add one route: `vault.arc-web.com → localhost:8200`. Team members' local machines can now reach OpenBao directly.

2. **Per-member identity (userpass auth)** - each team member gets a username + password in OpenBao. When they fetch a secret, the audit log records their name. `mike` fetched this key at this time. `patrick` fetched that token. Revoke one person = their reads stop. Nothing else affected.

3. **Standard agent instructions** - a CLAUDE.md snippet every team member's machine includes. Claude Code and Codex get the same rule: try OpenBao first with your userpass, cache the token locally, use 1P only if OpenBao is confirmed down and declare it loudly.

---

## Current state

- OpenBao: `127.0.0.1:8200` on zeroclaw, localhost only
- Auth methods: AppRole + Token only (no userpass yet)
- Audit log: already enabled at `/openbao/audit/audit.log`
- cloudflared: running on zeroclaw (config in Cloudflare dashboard)
- `bao` binary: NOT on local Macs
- Team members: Mike (local Mac), tronstar/Patrick (VPS access)

---

## Components

### 1. Cloudflare Tunnel route for OpenBao

Add ingress rule to existing cloudflared tunnel:
```
hostname: vault.arc-web.com
service: http://localhost:8200
```

Done via Cloudflare dashboard: Zero Trust → Networks → Tunnels → existing tunnel → Public Hostnames → Add.

**Security:** Cloudflare proxies all traffic (TLS). Optionally add Cloudflare Access policy requiring Google/GitHub login before hitting OpenBao - this adds a second auth layer on top of OpenBao's own auth. Recommended.

---

### 2. `bao` binary on local Macs

```bash
brew install openbao
```

Or download binary from https://github.com/openbao/openbao/releases.

Set in `~/.zshrc` / `~/.zprofile`:
```bash
export VAULT_ADDR=https://vault.arc-web.com
```

---

### 3. Enable userpass auth in OpenBao

```bash
ROOT=$(op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token --reveal)
ssh zeroclaw "VAULT_TOKEN='$ROOT' VAULT_ADDR='http://127.0.0.1:8200' /usr/local/bin/bao auth enable userpass"
```

Create policy `team-read` (read-only on shared paths):
```hcl
path "secret/data/shared/*"     { capabilities = ["read"] }
path "secret/data/tool-infra/*" { capabilities = ["read"] }
path "secret/data/projects/*"   { capabilities = ["read"] }
path "secret/data/hosting/*"    { capabilities = ["read"] }
path "secret/data/google-*/*"   { capabilities = ["read"] }
path "secret/data/search-console/*" { capabilities = ["read"] }
```

Create per-member users:
```bash
# Mike (admin - broader access)
bao write auth/userpass/users/mike password="<strong>" policies="team-read,host-scripts" token_ttl=8h token_max_ttl=24h

# Patrick
bao write auth/userpass/users/patrick password="<strong>" policies="team-read" token_ttl=8h token_max_ttl=24h

# Future members: same pattern, assign policy based on role
```

Passwords stored in 1P ARC vault as `OpenBao User - mike`, `OpenBao User - patrick`.

---

### 4. Local credential file per member

Each team member's machine gets `~/.vault-credentials` (not in git, not committed anywhere):
```bash
VAULT_ADDR=https://vault.arc-web.com
VAULT_USERNAME=mike
```

Password NOT stored in this file. Retrieved from 1P at login time:
```bash
# In ~/.zshrc or a login script
export VAULT_ADDR=https://vault.arc-web.com
export VAULT_USERNAME=mike
# bao login is run manually or via a helper script; token cached at ~/.vault-token
```

Login flow:
```bash
bao login -method=userpass username=mike
# prompts for password (fetched from 1P if desired)
# token written to ~/.vault-token automatically by bao CLI
# TTL: 8h - re-login once per workday
```

After login, `bao kv get` works with no further auth:
```bash
bao kv get -field=value secret/projects/plane-api-token
```

---

### 5. Agent instructions - standard CLAUDE.md snippet

Added to each team member's `~/.claude/CLAUDE.md` (or a shared include):

```markdown
## Credential access

Primary: OpenBao at https://vault.arc-web.com
```bash
# One-time per session login (token cached at ~/.vault-token, 8h TTL)
bao login -method=userpass username=$VAULT_USERNAME

# Fetch any secret
bao kv get -field=value secret/<path>
```

Emergency fallback (only if bao login fails with network error):
Declare: `⚠ EMERGENCY FALLBACK: OpenBao unreachable - [exact error]. Using 1P.`
Then: `op item get <id> --vault <vault> --fields credential --reveal`
```

---

### 6. Codex instructions

Codex has no persistent memory. The OpenBao pattern goes in the task prompt handed to it:

```
Credential access: bao kv get -field=value secret/<path> (VAULT_ADDR=https://vault.arc-web.com, already logged in).
1P is emergency fallback only. Declare emergency if using it.
```

This goes into the Codex prompt template in `~/.claude/skills/` or wherever Codex prompts originate.

---

### 7. GitHub Actions AppRole (replaces GitHub Secrets)

For GitHub Actions (the Plane sync workflow), create a dedicated AppRole instead of using a static secret:

```bash
# Create github-actions AppRole with read-only policy on needed paths
bao write auth/approle/role/github-actions \
  token_policies="team-read" \
  token_ttl=5m \
  token_max_ttl=10m \
  secret_id_ttl=0  # static secret_id (stored in Cloudflare Tunnel access or GitHub OIDC)
```

GitHub Actions workflow:
1. Authenticate with role_id + secret_id → get 5-min token
2. Fetch `secret/projects/plane-api-token` → use in same step
3. Token expires after 5 min automatically

role_id stored as GitHub Secret (not an API key - it's a non-sensitive identifier). secret_id also GitHub Secret. Neither is the actual credential - just auth material. This is the established AppRole pattern.

---

## Fingerprinting in audit log

Every read shows up as:
```json
{
  "auth": {
    "display_name": "userpass-mike",
    "policies": ["team-read"],
    "accessor": "abc123"
  },
  "request": {
    "path": "secret/data/projects/plane-api-token"
  }
}
```

Query who read what:
```bash
ssh zeroclaw "grep 'plane-api-token' /openbao/audit/audit.log | jq '.auth.display_name'"
```

---

## Execution order

1. Cloudflare dashboard: add `vault.arc-web.com` route to existing tunnel (Mike, ~5 min)
2. `bao auth enable userpass` + create `team-read` policy + create users (Claude Code executes)
3. `brew install openbao` on local Macs (each member)
4. Test: `bao login -method=userpass username=mike` from local → `bao kv get -field=value secret/projects/plane-api-token`
5. Each member adds VAULT_ADDR + VAULT_USERNAME to `~/.zshrc`
6. Update `~/.claude/CLAUDE.md` (Mike's) with standard credential snippet
7. Create `github-actions` AppRole for GitHub Actions workflow
8. Remove SSH workaround from agent instructions (it's no longer needed for reads)

---

## Verification

- `bao login -method=userpass username=mike` → succeeds from local Mac (no SSH)
- `bao kv get -field=value secret/projects/plane-api-token` → returns key (no SSH)
- `ssh zeroclaw "grep userpass-mike /openbao/audit/audit.log | tail -3"` → shows Mike's reads
- `ssh zeroclaw "grep userpass-patrick /openbao/audit/audit.log | tail -3"` → shows Patrick's reads separately
- GitHub Actions plane-sync workflow → authenticates via AppRole, fetches Plane key, no static API key in GitHub

---

## Plane task

Create AGENT task: "OpenBao team access: Cloudflare Tunnel + userpass per member + bao on local Macs"
- State: Todo
- Priority: High
- Estimate: 45 min human time (tunnel config + policy + user creation + local installs)
