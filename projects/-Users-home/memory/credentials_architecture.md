---
name: Credentials architecture - consolidated
description: Single source for credential rules. OpenBao canonical for runtime/services; 1Password local-only for account logins + dev workstation; .env files banned. Includes VPS agent flow, AppRole + proxy, local SSH-fetch, LaunchAgent op-token injection, and safe patterns.
type: project
originSessionId: 543d8aad-b206-4ecd-88b5-ed0a28587e95
---
# Credentials Architecture (consolidated 2026-04-27, updated 2026-05-18)

## QUICK REFERENCE - read first

- **OpenBao root token (for writes/policies):** 1P ARC vault, item `hl23px33remaz2xecl5ecvvaem` ("OpenBao Unseal Material — ARC"), field `root_token`. Also has `unseal_key`, `bao_addr`, `bao_addr_container`.
- **AppRole backups:** 1P ARC items prefixed `OpenBao AppRole - <name>` (hermes, zeroclaw-alpha, zeroclaw-bravo, host-scripts, paperclip, fathom, approval-webhook).
- **Per-container AppRole on zeroclaw:** `/etc/openbao/<container>/{role_id,secret_id,agent.hcl}` for hermes, zeroclaw-alpha, zeroclaw-bravo.
- **Per-host AppRole env files on zeroclaw:** `/etc/openbao/<role>.env` (host-scripts, fathom, paperclip, approval-webhook, cron-scripts).
- **Wrapper for reads:** `/opt/openbao-wrapper/lib.sh` exports `bao_auth` + `bao_get`. No `bao_put` - use `bao kv put` directly with root token.
- **Field convention:** secrets stored with field name `value` to match the `fetch()` helper in `/entrypoint-openbao.sh`. Use `value`, not `token` or `credential`.
- **Discovery order if a credential is missing:** see `feedback_credential_discovery_order.md`. Never ask user without exhausting it.
- **Write pattern (full):** see `openbao_admin_write_pattern.md`.

---

## 1) OpenBao - canonical source

Status: Migration complete as of 2026-04-23.

**OpenBao is the single source of truth for all agent credentials.**

### VPS agent flow / AppRole / proxy

- OpenBao Agent runs as a sidecar inside each container (Hermes, ZeroClaw Alpha, ZeroClaw Bravo).
- Agent authenticates via AppRole (`role_id` + `secret_id` files mounted from `/etc/openbao/{agent}/`).
- Proxy runs on `http://127.0.0.1:8100` inside each container - no auth header needed.
- All startup secrets fetched through the proxy at boot.
- All mid-session secret fetches go through the same proxy.
- `BAO_PROXY_ADDR=http://127.0.0.1:8100` is exported for agent use.

### 1Password has NO role for VPS or agents

OpenBao is the only credential store for anything VPS-related, including:
- Agent runtime secrets (API keys, tokens)
- VPS provider account credentials (Hostinger hPanel login, etc.)
- SSH keys for VPS access
- Any third-party service the VPS or agents touch

Existing 1P entries for VPS-related credentials (e.g. "Hostinger" items in ARC vault) are STALE and should be ignored. Do not pull from 1P for any VPS work - go to OpenBao.

The `op` CLI, `OP_SERVICE_ACCOUNT_TOKEN`, `setup-op.sh`, and any `op read` / `op run` calls must be removed from all agent containers. NOT done yet for Hermes.

### Open migration items (Hermes)

- Remove `setup-op.sh` call from Hermes entrypoint
- Remove `OP_SERVICE_ACCOUNT_TOKEN` from `hermes-compose-live.yml`
- Audit and replace any `op`-based skills in Hermes with OpenBao proxy equivalents
- Verify no `op` CLI calls remain in any agent entrypoint or skill

### Per-agent secret paths

- `hermes/discord-bot-token`, `hermes/openrouter-key`
- `zeroclaw-alpha/discord-bot-token`, `zeroclaw-alpha/openrouter-key`
- `zeroclaw-bravo/discord-bot-token`, `zeroclaw-bravo/openrouter-key`
- `shared/plane-api-key`
- `tool-infra/supabase-url`, `tool-infra/supabase-service-key`, `tool-infra/supabase-anon-key`, `tool-infra/supabase-project-id`
- `tool-infra/browser-use-api-key`
- `tool-infra/google-ads-client-id`, `tool-infra/google-ads-client-secret`, `tool-infra/google-ads-refresh-token`, `tool-infra/google-ads-developer-token`, `tool-infra/google-ads-login-customer-id`

### Local CLIs hitting VPS services - token source order

For any local CLI/tool talking to a VPS-hosted service (Plane, Supabase, Discord, OpenRouter, etc.):

1. Env var override (`PLANE_API_KEY=...`)
2. Local cache file under `~/.cache/<tool>/token` with TTL
3. `ssh zeroclaw 'bash /root/bao-env.sh printenv <VAR>'` - the canonical fetch

**Never:** put `op read 'op://...'` as primary or fallback in a local CLI.

**Why:** OpenBao is single source of truth. 1Password is human/disaster-recovery backup of the AppRole creds themselves, not a live secret store for runtime. Treating 1P as "easy fallback" creates drift between stores and reintroduces the failure mode the OpenBao migration killed.

**How to apply:** When planning any tool needing a service token, first question is "what's the OpenBao path?" Check known paths (`shared/plane-api-key`, `tool-infra/supabase-*`, etc.). Only ask user for token if path genuinely unknown and not yet in OpenBao.

**Reference impl:** `~/ai/agents/web/plane_agent/plane` `get_token()` function - shows env -> cache -> ssh pattern.

**On VPS itself:** services use the in-container OpenBao Agent proxy at `http://127.0.0.1:8100`. SSH-fetch is only for local-machine tools running outside the VPS.

### OpenBao retrieval commands

**`bao` binary is NOT installed on the local Mac.** Do NOT run `bao kv get` locally.

**Two valid patterns for local agents (Claude Code):**

**Option A - Direct (preferred): AppRole via vault.todovibes.com**
- Cloudflare Tunnel exposes OpenBao at `https://vault.todovibes.com`
- Local Claude Code has AppRole `claude-code-local` - bootstrapped from 1P ARC item "OpenBao AppRole - claude-code-local"
- Audit log shows `claude-code-local` fingerprint (NOT zeroclaw's identity)
- Pattern (Python, no SSH):
  ```python
  import urllib.request, json, subprocess
  item = json.loads(subprocess.check_output(
      ['op','item','get','OpenBao AppRole - claude-code-local','--vault','ARC','--format','json','--reveal'],
      text=True))
  fields = {f['label']: f.get('value','') for f in item['fields']}
  auth = json.loads(urllib.request.urlopen(urllib.request.Request(
      'https://vault.todovibes.com/v1/auth/approle/login',
      data=json.dumps({'role_id': fields['role_id'], 'secret_id': fields['secret_id']}).encode(),
      headers={'Content-Type': 'application/json', 'User-Agent': 'vault-client/1.0'},
      method='POST')).read())
  token = auth['auth']['client_token']
  value = json.loads(urllib.request.urlopen(urllib.request.Request(
      'https://vault.todovibes.com/v1/secret/data/<path>',
      headers={'X-Vault-Token': token, 'User-Agent': 'vault-client/1.0'})).read())['data']['data']['value']
  ```

**Option B - SSH fallback (writes/admin only):** SSH to zeroclaw with root token from 1P ARC
  ```
  ROOT=$(op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token --reveal)
  ssh zeroclaw "VAULT_ADDR='http://127.0.0.1:8200' BAO_TOKEN='$ROOT' /usr/local/bin/bao kv put secret/<path> value=<val>"
  ```
  Use Option B only for writes/policy changes. Reads go via Option A.

- If vault.todovibes.com unreachable: declare "⚠ EMERGENCY FALLBACK: OpenBao unreachable - [exact error]. Using 1P. This is broken and needs fixing." Then and only then use 1P.

---

## 2) 1Password - local-only role

### Two-tier lookup model

| Credential type | Where to look |
|-----------------|---------------|
| Service API tokens (Plane, Supabase, OpenRouter, Discord bot tokens, Anthropic, etc.) | **OpenBao only.** Never fall back to 1P. If missing, add to OpenBao, do not pull from 1P. |
| Provider account logins (Hostinger hPanel, GitHub web UI, Skool admin, Stripe dashboard, etc.) | OpenBao first. If missing, **automatically** fall back to 1P CLI. Note in output which store it came from so we know what to migrate. |
| One-off secrets the user just mentioned | Ask user where to put it. Default answer is OpenBao. |

**Why the split:** Service tokens are runtime infrastructure - one place avoids drift. Account logins are mostly used by humans + browser automation; migration of those into OpenBao is incomplete, so the 1P fallback is a bridge until that work finishes.

We do NOT ask "where is this credential?" - we just go look. If OpenBao misses on an account login, automatically check 1P before bothering the user.

### Browser automation prep - mandatory checklist

Before generating any prompt that drives a browser automation tool (arc-browser, browser-use, Playwright, etc.), resolve every required credential up front:

1. Try OpenBao first.
   - On VPS: AppRole via `/opt/openbao-wrapper/lib.sh` then `bao_get <path> <field>`
   - From local machine: `ssh zeroclaw 'source /opt/openbao-wrapper/lib.sh && export BAO_AUTH_FILE=/etc/openbao/host-scripts.env && bao_auth >/dev/null && bao_get <path> <field>'`
2. On 403 / 404 / empty value, try 1Password CLI.
   - Find item: `op item list --vault ARC | grep -i <service>`
   - Read fields: `op item get <id> --vault ARC --fields label=username,label=password --reveal`
3. If both miss, then ask the user.
4. Bake the **exact retrieval command** into the agent prompt. Do not make the downstream agent rediscover the lookup. It should run one command and get the credential.
5. Note in the agent prompt which store the credential came from. If from 1P, flag as migration TODO.

**Why this matters:** Without it, every browser-automation task stalls at credential lookup, user gets pinged for something we could have figured out, we lose a turn. With it, prep step is automatic and agent prompt is always self-sufficient.

### LaunchAgent - op token injection for GUI apps (Mac)

GUI apps on macOS (Claude Code Desktop, etc.) do NOT inherit shell env from `.zprofile` or `.zshrc`. So `OP_SERVICE_ACCOUNT_TOKEN` set there never reaches Claude Code or any of its hook subprocesses, and `op` falls back to Apple Events IPC with 1Password.app -> macOS TCC popup "op would like to access data from other apps" -> popup repeats every hook call because TCC grants are bound to calling process context.

**Solution in place (2026-04-25):**

- LaunchAgent: `~/Library/LaunchAgents/com.local.op-env.plist` (Label: `com.local.op-env`, RunAtLoad=true)
- Script: `~/Library/Scripts/op-env-inject.sh`

What the script does on every user login:
1. Reads service account token from macOS Keychain (`security find-generic-password -s op-service-account`)
2. Injects via `launchctl setenv OP_SERVICE_ACCOUNT_TOKEN "$tok"` so all subsequently launched GUI apps inherit it
3. Refreshes TCC AppleEvents grant for current `op` binary path (handles `op` updates that change Caskroom version path)

TCC grant target: `com.todesktop.230313mzl4w4u92` (1Password 8 desktop bundle ID, built with ToDesktop framework).
TCC table: `$HOME/Library/Application Support/com.apple.TCC/TCC.db` - writable when terminal has Full Disk Access.
TCC values for INSERT OR REPLACE: service=`kTCCServiceAppleEvents`, client=resolved op path, client_type=1 (binary), auth_value=2 (allowed), auth_reason=3 (user set), indirect_object_identifier=1Password bundle ID, indirect_object_identifier_type=0 (bundle).

**Verify it's working:**
```bash
launchctl getenv OP_SERVICE_ACCOUNT_TOKEN | head -c 20   # should print "ops_..."
launchctl list | grep com.local.op-env                    # should show PID + 0 exit
sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
  "SELECT client, auth_value FROM access WHERE service='kTCCServiceAppleEvents' AND client LIKE '%op%';"
```

**Why this matters:**
- Without LaunchAgent: every hook subprocess that touches `op` (directly or via `lean-ctx`, composure, or any MCP server fetching secrets) triggers a TCC popup - GUI apps don't inherit shell env; `op` without `OP_SERVICE_ACCOUNT_TOKEN` falls back to Apple Events to 1Password.app; TCC for Apple Events is per-caller-context so CLI tools triggered from different parent processes get fresh prompts.
- With LaunchAgent: `op` always finds token in env, never tries Apple Events, never triggers TCC. Belt-and-suspenders: TCC grant exists too, so even if token vanishes, no popup.

**Caveat - reboot required after install:** `launchctl setenv` only affects processes spawned AFTER the call. Already-running GUI apps (Claude Code Desktop) need to be quit and relaunched to pick up the new env var.

**Files:**
- `~/Library/LaunchAgents/com.local.op-env.plist`
- `~/Library/Scripts/op-env-inject.sh`
- `/tmp/op-env-inject.log` (stderr if anything goes wrong)

### credsync tool

Path: ~/ai/workspaces/aimacpro/7_tools/credentials/credsync.py
Purpose: syncs credentials between 1P vaults (Zeroclaw vault = canonical VPS secrets, ARC vault = local-only + cached copies tagged cached-from-zeroclaw)
Defaults: dry-run, conflict detection, no value print without --reveal

---

## 3) Rules - safe patterns

### No .env / .env.example - hard rule

Never use `.env` or `.env.example` files for any system. All credentials, API keys, URLs containing secrets, and config-with-secrets must be sourced from:

- **1Password** - quick local needs (developer workstation, one-off scripts)
- **OpenBao** - everything else (services, agents, VPS deployments, CI)

When auditing or scaffolding a repo, if `.env` / `.env.example` exists, treat as tech debt. Update project README/setup docs to repeat this rule so it doesn't creep back in.

**Why:** Credentials stay in vaults (1Password + OpenBao via arcbao sidecar). `.env` files leak into git, get committed, drift between machines, dodge rotation. User explicitly said "never use a .env file" and asked that documentation enforce this.

**How to apply:**
- Refuse to create `.env` or `.env.example` files
- When repo references `.env`, propose replacement: `op read "op://<vault>/<item>/<field>"` for 1P, or arcbao/OpenBao client for service credentials
- Add line to repo README/setup docs stating the rule
- Existing `.env.example` files in repos: flag for removal as part of any work touching that area

### No tokens in curl args / safe patterns

- Never put service tokens directly into command-line arguments visible to `ps`. Pipe via env or file:
  - `BAO_TOKEN=$(...) curl -H "X-Vault-Token: $BAO_TOKEN" ...`  (env, not inline literal)
  - For OpenBao on VPS, prefer the localhost proxy at `http://127.0.0.1:8100` - no auth header needed.
- Never log full tokens. If logging, mask to first 4 + last 4 only.
- Never commit `role_id` / `secret_id` files. They live at `/etc/openbao/{agent}/` only.
- Never use Anthropic API keys for 3rd-party LLM calls (cross-ref: `feedback_no_anthropic_oauth_misuse` if present).
- For local CLIs: env var > cache file (with TTL) > `ssh zeroclaw` fetch. Never `op read` as primary/fallback for VPS service tokens.
- Browser automation: resolve every credential BEFORE the prompt, bake exact retrieval command in.
- On 403/404/empty from OpenBao for an account login, auto-fall to 1P. For service tokens, do NOT auto-fall - fix OpenBao instead.

## Reference cross-links

- Service token rules: this file (was `feedback_local_cli_credentials_openbao.md` / `memory_credentials_openbao_local.md`)
- OpenBao architecture: this file (was `memory_credentials_openbao_architecture.md` / `project_credentials_coordination.md`)
- 1P token injection on Mac: this file (was `reference_op_token_launchd.md`)

---
## HARD RULE: Never copy credential values to external systems (2026-05-17)

**Never fetch a credential value and store it somewhere else.** GitHub Secrets, .env files, config files, CI variables, shell scripts - all count as "external."

If a system like GitHub Actions needs a credential:
- **Option A (SSH):** GitHub Actions has one SSH deploy key. It SSHes to zeroclaw and runs `bao kv get` locally. Value used in-memory in the same job step. Never stored.
- **Option B (webhook):** zeroclaw runs a webhook listener. GitHub Actions POSTs a signed event. zeroclaw calls the third-party API using its local OpenBao creds. Zero secrets leave zeroclaw.

**Never:** `gh secret set KEY --repo X <<< $(bao kv get ...)` - this copies the value.
**Never:** `echo "$KEY" | gh secret set ...` - same violation.

If the only option appears to be storing a key externally: stop and design Option A or B instead. If truly unavoidable, get explicit user approval and document why.

## Runtime credential rule (2026-05-16 - supersedes local access patterns table)

**Fetch service tokens from OpenBao. Do not write `op item get` or `op read` for a service token in a skill or code file.**

Service tokens = API keys, bearer tokens, webhook URLs, bot tokens, worker secrets, PATs, OAuth tokens.

If a token is missing from OpenBao: mirror it using `bao kv put secret/<path> value=<token>` (root token pattern), then fetch from OpenBao. Never use 1P as the runtime path.

Bash permission entries must use literal path references, NEVER hardcoded tokens:
- CORRECT: `Bash(ssh zeroclaw "VAULT_ADDR=... BAO_TOKEN=... bao kv get secret/...":*)`
- WRONG: `Bash(GITHUB_TOKEN="github_pat_11BC..." gh api:*)`
- WRONG: `Bash(op read "op://ARC/...":*)` for service tokens

See `feedback_no_1p_for_service_tokens.md` for the alert trigger and mirror pattern. See `feedback_credential_discovery_order.md` for the full discovery order by credential type.
