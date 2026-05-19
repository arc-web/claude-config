---
name: Credentials architecture - consolidated
description: Single source for credential rules. OpenBao canonical for runtime/services; 1Password is human custody, backup, bootstrap, recovery, manual handoff, and new-credential capture. .env files are not runtime credential stores. Includes VPS agent flow, AppRole + proxy, local fetch patterns, biometric 1Password handling, and safe patterns.
type: project
originSessionId: 543d8aad-b206-4ecd-88b5-ed0a28587e95
---
# Credentials Architecture (consolidated 2026-04-27, updated 2026-05-18)

## QUICK REFERENCE - read first

- **OpenBao root token (for writes/policies):** 1P ARC vault, item `hl23px33remaz2xecl5ecvvaem` ("OpenBao Unseal Material - ARC"), field `root_token`. Also has `unseal_key`, `bao_addr`, `bao_addr_container`.
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

### 1Password is not a runtime source for VPS or agents

OpenBao is the only runtime credential store for anything VPS-related, including:
- Agent runtime secrets (API keys, tokens)
- VPS provider account credentials (Hostinger hPanel login, etc.)
- SSH keys for VPS access
- Any third-party service the VPS or agents touch

1Password remains valid for human custody, backup, OpenBao bootstrap material,
emergency recovery, migration, manual handoff, and newly created credential
capture. If a VPS or agent runtime credential exists only in 1Password, that is
a drift signal. Report the missing OpenBao path, then promote or mirror the
credential into OpenBao before an agent, scheduler, CI job, MCP server, deploy,
or service consumes it.

The `op` CLI, `OP_SERVICE_ACCOUNT_TOKEN`, `OP_SESSION`, `setup-op.sh`, and any
`op read` / `op run` calls must be removed from all agent containers and
long-running runtime environments. 1Password reads are allowed only for human
login, bootstrap, recovery, migration, newly created credential capture, or an
explicitly approved emergency/manual handoff.

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

1. OpenBao via the direct Cloudflare AppRole path or `ssh zeroclaw` plus
   `/opt/openbao-wrapper/lib.sh`.
2. A local cache file under `~/.cache/<tool>/token` with TTL only when the cache
   was populated from OpenBao and never stores an unredacted long-lived secret
   outside the approved cache boundary.
3. Explicit env var override only for local, one-off human debugging. Do not
   wire env vars as the scheduler, MCP, CI, deploy, or service credential
   source.

**Never:** put `op read 'op://...'` as primary or fallback in a local CLI.

**Why:** OpenBao is the runtime source of truth. 1Password is human custody,
backup, bootstrap, recovery, migration, and manual handoff. Treating 1P as
"easy fallback" creates drift between stores and reintroduces the failure mode
the OpenBao migration killed.

**How to apply:** When planning any tool needing a service token, first question is "what's the OpenBao path?" Check known paths (`shared/plane-api-key`, `tool-infra/supabase-*`, etc.). Only ask user for token if path genuinely unknown and not yet in OpenBao.

**Reference impl:** `~/ai/agents/web/plane_agent/plane` `get_token()` function - shows env -> cache -> ssh pattern.

**On VPS itself:** services use the in-container OpenBao Agent proxy at `http://127.0.0.1:8100`. SSH-fetch is only for local-machine tools running outside the VPS.

### OpenBao retrieval commands

**`bao` binary is NOT installed on the local Mac.** Do NOT run `bao kv get` locally.

**Two valid patterns for local agents (Claude Code):**

**Option A - Direct (preferred): AppRole via vault.aibrainbuilders.com**
- Cloudflare Tunnel exposes OpenBao at `https://vault.aibrainbuilders.com`
- Local Claude Code has AppRole `claude-code-local` - bootstrap material is
  held in 1P ARC item "OpenBao AppRole - claude-code-local". This 1Password read
  is for OpenBao authentication, not for the Plane, Supabase, Discord, or other
  service token itself.
- Audit log shows `claude-code-local` fingerprint (NOT zeroclaw's identity)
- Pattern (Python, no SSH):
  ```python
  import urllib.request, json, subprocess
  item = json.loads(subprocess.check_output(
      ['op','item','get','OpenBao AppRole - claude-code-local','--vault','ARC','--format','json','--reveal'],
      text=True))
  fields = {f['label']: f.get('value','') for f in item['fields']}
  auth = json.loads(urllib.request.urlopen(urllib.request.Request(
      'https://vault.aibrainbuilders.com/v1/auth/approle/login',
      data=json.dumps({'role_id': fields['role_id'], 'secret_id': fields['secret_id']}).encode(),
      headers={'Content-Type': 'application/json', 'User-Agent': 'vault-client/1.0'},
      method='POST')).read())
  token = auth['auth']['client_token']
  value = json.loads(urllib.request.urlopen(urllib.request.Request(
      'https://vault.aibrainbuilders.com/v1/secret/data/<path>',
      headers={'X-Vault-Token': token, 'User-Agent': 'vault-client/1.0'})).read())['data']['data']['value']
  ```

**Option B - SSH admin path (writes/policy changes only):** SSH to zeroclaw with
root token from 1P ARC
  ```
  ROOT=$(op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token --reveal)
  ssh zeroclaw "VAULT_ADDR='http://127.0.0.1:8200' BAO_TOKEN='$ROOT' /usr/local/bin/bao kv put secret/<path> value=<val>"
  ```
  Use Option B only for writes/policy changes. Reads go via Option A or the
  host wrapper with the least-privileged AppRole that covers the path.

- If vault.aibrainbuilders.com is unreachable for a runtime service token:
  fail loud with the exact error and intended OpenBao path. Use 1Password only
  when the user explicitly approves an emergency or manual handoff, and report
  that the credential must be repaired or mirrored back into OpenBao.

---

## 2) 1Password - custody, bootstrap, and human role

### Two-tier lookup model

| Credential type | Where to look |
|-----------------|---------------|
| Service API tokens (Plane, Supabase, OpenRouter, Discord bot tokens, Anthropic, OAuth refresh tokens, webhooks, deploy tokens, etc.) | **OpenBao for runtime.** If missing, capture the new credential in 1Password first for human custody, then manually promote or mirror it into OpenBao before runtime use. |
| Provider account logins (Hostinger hPanel, GitHub web UI, Skool admin, Stripe dashboard, etc.) | 1Password is valid for human login and browser-assisted human workflows. OpenBao may hold mirrored copies when automation needs them. |
| One-off secrets the user just mentioned | Store in 1Password first for custody. Promote or mirror to OpenBao before any agent, automation, scheduler, MCP, CI, deploy, or service consumes it. |

**Why the split:** Service tokens are runtime infrastructure, so one runtime
source avoids drift. Account logins are mostly used by humans plus browser
automation and can remain in 1Password unless they become runtime inputs.

Do not ask "where is this credential?" until the documented lookup path has
been exhausted. For runtime tokens, 1Password is not the normal second runtime
store. It is custody, migration, recovery, or explicit manual handoff.

### Browser automation prep - mandatory checklist

Before generating any prompt that drives a browser automation tool (arc-browser, browser-use, Playwright, etc.), resolve every required credential up front:

1. Try OpenBao first.
   - On VPS: AppRole via `/opt/openbao-wrapper/lib.sh` then `bao_get <path> <field>`
   - From local machine: `ssh zeroclaw 'source /opt/openbao-wrapper/lib.sh && export BAO_AUTH_FILE=/etc/openbao/host-scripts.env && bao_auth >/dev/null && bao_get <path> <field>'`
2. For account logins only, use 1Password after OpenBao misses.
   - Find item: `op item list --vault ARC | grep -i <service>`
   - Read fields: `op item get <id> --vault ARC --fields label=username,label=password --reveal`
3. For service/runtime tokens, do not use 1Password as silent fallback. Report
   the exact OpenBao miss or failure and the intended path.
4. Bake the **exact retrieval command** into the agent prompt. Do not make the downstream agent rediscover the lookup. It should run one command and get the credential.
5. Note in the agent prompt which store the credential came from. If a runtime
   token came from 1Password under explicit emergency/manual handoff, flag the
   OpenBao repair as mandatory follow-up.

**Why this matters:** Without it, every browser-automation task stalls at credential lookup, user gets pinged for something we could have figured out, we lose a turn. With it, prep step is automatic and agent prompt is always self-sufficient.

### 1Password biometric workflow for local human operations (Mac)

When a concealed `op read` or `op item get --reveal` call is allowed for human
login, bootstrap, recovery, migration, new-credential capture, or explicit
manual handoff, 1Password biometric approval is the human confirmation.

Do not ask the user to reply "approved" after launching the command. Run `op`,
let the user approve with fingerprint or in 1Password.app, then poll or retry
briefly. If the first attempt times out or returns a prompt/authorization
error, open 1Password and retry the same operation. Stop only after repeated
retries prove the app is locked, desktop integration is disabled, or the item
or field is missing.

`OP_SERVICE_ACCOUNT_TOKEN` and `OP_SESSION` must not be inherited by
schedulers, MCP servers, CI, deploy jobs, agent containers, or runtime services.
For scheduler checks, verify they are absent:
```bash
launchctl getenv OP_SERVICE_ACCOUNT_TOKEN
launchctl getenv OP_SESSION
```

### credsync tool

Path: ~/ai/workspaces/aimacpro/7_tools/credentials/credsync.py
Purpose: syncs credentials between 1P vaults (Zeroclaw vault = canonical VPS secrets, ARC vault = local-only + cached copies tagged cached-from-zeroclaw)
Defaults: dry-run, conflict detection, no value print without --reveal

---

## 3) Rules - safe patterns

### No .env / .env.example - hard rule

Never use `.env` or `.env.example` files for any system. All credentials, API keys, URLs containing secrets, and config-with-secrets must be sourced from:

- **1Password** - human custody, human login, bootstrap, recovery, migration,
  manual handoff, and new-credential capture
- **OpenBao** - runtime credentials for services, agents, schedulers, MCP
  servers, CI, deploys, and automation

When auditing or scaffolding a repo, if `.env` / `.env.example` exists, treat as tech debt. Update project README/setup docs to repeat this rule so it doesn't creep back in.

**Why:** Credentials stay in vaults (1Password + OpenBao via arcbao sidecar). `.env` files leak into git, get committed, drift between machines, dodge rotation. User explicitly said "never use a .env file" and asked that documentation enforce this.

**How to apply:**
- Refuse to create `.env` or `.env.example` files
- When repo references `.env`, propose replacement: 1Password only for human
  login or local-only custody, and OpenBao client or wrapper reads for service
  credentials
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
- On 403/404/empty from OpenBao for an account login, use 1Password as the
  human login source. For service tokens, do not auto-fall to 1P. Fix or
  populate OpenBao instead, unless the user explicitly approves emergency or
  manual handoff.

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

If a token is missing from OpenBao: create or capture it in 1Password first for
human custody, mirror it using `bao kv put secret/<path> value=<token>` (root
token pattern), then fetch from OpenBao. Never use 1P as the runtime path.

Bash permission entries must use literal path references, NEVER hardcoded tokens:
- CORRECT: `Bash(ssh zeroclaw "VAULT_ADDR=... BAO_TOKEN=... bao kv get secret/...":*)`
- WRONG: `Bash(GITHUB_TOKEN="github_pat_11BC..." gh api:*)`
- WRONG: `Bash(op read "op://ARC/...":*)` for service tokens

See `feedback_no_1p_for_service_tokens.md` for the alert trigger and mirror pattern. See `feedback_credential_discovery_order.md` for the full discovery order by credential type.
