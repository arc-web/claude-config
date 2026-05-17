---
name: Credential discovery - service tokens via OpenBao, account logins via OpenBao then 1P
description: Hard rule split by credential type. Service tokens (API keys, tokens, webhooks): env→OpenBao→VPS filesystem→ask. Account logins: env→OpenBao→1P→ask. Never check 1P for service tokens - that is drift.
type: feedback
originSessionId: 5e4c15fa-4ed9-4e70-b9de-f4f25e3e31ae
---
# Credential discovery order

**Rule:** Never ask user for a credential before exhausting the documented lookup order. Discovery order splits by credential type - service tokens and account logins have different paths.

**Why:** Caught twice in the same day (2026-05-16): one session hunted 1P for a Cloudflare API token (service token), got the wrong credential type, wasted 4 turns. Another session fetched the Plane API key from 1P even though it lives in OpenBao. Root cause: the old order listed 1P before OpenBao for all types, contradicting the architecture rule that OpenBao is canonical for service tokens.

---

## Service tokens (API keys, bearer tokens, webhook URLs, bot tokens, worker secrets, PATs)

Walk this order - stop at first hit:

1. **Env vars + local cache** - `env | grep -iE <service>`, `~/.cache/<tool>/`
2. **OpenBao via SSH** - `ssh zeroclaw "VAULT_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root> bao kv get -format=json secret/<path>"` - check `secret/shared/`, `secret/tool-infra/`, `secret/hosting/`, `secret/hermes/`, `secret/zeroclaw-*/`
3. **VPS filesystem** - `ssh zeroclaw 'cat /etc/openbao/<role>.env'` or `/etc/openbao/<role>/{role_id,secret_id}`
4. **Ask user** - ONLY after 2-3 confirmed empty

**DO NOT check 1P for service tokens.** If a service token is found in 1P but not in OpenBao: that is drift. Mirror it to OpenBao first using the write pattern (`bao kv put secret/<path> value=<token>`), then fetch from OpenBao. Never bake a new `op item get` or `op read` into a skill or code path for a service token.

Known OpenBao paths for common service tokens:
- Plane API key: `secret/shared/plane-api-key`
- Cloudflare API key + email: `secret/hosting/cloudflare-api` (JSON blob with `credential`, `email`, `account_id`)
- Discord bot tokens: `secret/shared/discord-<slug>`
- GitHub PAT (arc-web): `secret/hermes/github-pat`
- OpenRouter key: `secret/tool-infra/openrouter-key`
- GHL agency PIT: `secret/shared/ghl-agency-pit`

---

## Account logins (web UI logins: Hostinger hPanel, GitHub web UI, Stripe dashboard, Skool admin, GHL dashboards, etc.)

Walk this order - stop at first hit:

1. **Env vars + local cache**
2. **OpenBao** (check first - some account creds are already mirrored)
3. **1Password** - ARC and Zeroclaw vaults via `op item list --vault <V> --format=json | grep -i <service>`
4. **Ask user**

---

## Intentional 1P bootstrap items (never move these to OpenBao, never fetch via OpenBao)

These three are designed to bootstrap OpenBao itself - they MUST stay in 1P:

- **OpenBao root token**: 1P ARC `hl23px33remaz2xecl5ecvvaem` field `root_token` - used for writes and by Claude Code locally
- **AppRole backups**: 1P ARC items prefixed `OpenBao AppRole - <name>` - disaster recovery only
- **macOS LaunchAgent `OP_SERVICE_ACCOUNT_TOKEN`**: injected via LaunchAgent for local `op` CLI auth

---

## Emergency fallback protocol (service tokens only)

OpenBao is the only credential source of truth. 1P is the only fallback. Nothing else is permitted.

If OpenBao returns an error for a service token:
1. Print the exact error
2. Retry once (transient network)
3. If still failing: print `⚠ EMERGENCY FALLBACK: OpenBao unreachable - [exact error]. Using 1P. THIS NEEDS FIXING.`
4. Then and only then: use 1P
5. After current task: diagnose and fix OpenBao

Silent 1P fallback = a bug. No emergency declaration = a bug.

**Never copy the credential value to another system.** If GitHub Actions / CI / an external service needs a credential: design a webhook receiver on zeroclaw (zeroclaw fetches from OpenBao and calls out), or an SSH deploy key that lets the runner fetch at runtime. Credential values stay in OpenBao and never travel.

## Trigger

Any task that says "add credential", "wire up access", "connect to vault", "write secret", "give X access to Y", "needs a token". Run mem-search FIRST, then walk the appropriate discovery order above.

Finding `op item get` or `op read` in a skill for a service token = alert. See `feedback_no_1p_for_service_tokens.md`.
