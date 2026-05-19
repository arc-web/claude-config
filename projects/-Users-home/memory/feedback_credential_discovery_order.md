---
name: Credential discovery - OpenBao runtime, 1Password custody and human login
description: Hard rule split by credential type. Service tokens (API keys, tokens, webhooks): OpenBao runtime first, with 1Password only for custody, bootstrap, recovery, migration, or explicit manual handoff. Account logins: 1Password is valid for human login. Never normalize 1P as a silent runtime fallback.
type: feedback
originSessionId: 5e4c15fa-4ed9-4e70-b9de-f4f25e3e31ae
---
# Credential discovery order

**Rule:** Never ask user for a credential before exhausting the documented
lookup order. Discovery order splits by credential type. Service tokens and
account logins have different paths.

**Why:** Caught twice in the same day (2026-05-16): one session hunted 1P for a Cloudflare API token (service token), got the wrong credential type, wasted 4 turns. Another session fetched the Plane API key from 1P even though it lives in OpenBao. Root cause: the old order listed 1P before OpenBao for all types, contradicting the architecture rule that OpenBao is canonical for service tokens.

---

## Service tokens (API keys, bearer tokens, webhook URLs, bot tokens, worker secrets, PATs)

Walk this order and stop at the first valid runtime path:

1. **OpenBao direct or via SSH** - use the Cloudflare AppRole path, or
   `ssh zeroclaw` with `/opt/openbao-wrapper/lib.sh` and the AppRole file whose
   policy covers the path. Check `secret/shared/`, `secret/tool-infra/`,
   `secret/hosting/`, `secret/hermes/`, and `secret/zeroclaw-*/`.
2. **OpenBao AppRole material on the VPS** - inspect only the relevant
   `/etc/openbao/<role>.env` or `/etc/openbao/<role>/{role_id,secret_id}` path
   needed to authenticate to OpenBao.
3. **Explicit local override/cache** - only if it was created for a one-off
   human debugging session or was populated from OpenBao with a TTL. Do not
   wire env or cache as the scheduler, MCP, CI, deploy, or service credential
   source.
4. **Ask user for the smallest missing thing** - only after OpenBao path and
   AppRole access are confirmed missing or broken.

**Do not check 1P as a normal runtime fallback for service tokens.** If a
service token is found in 1P but not in OpenBao, that is drift or new-credential
custody. Mirror it to OpenBao first using the write pattern
(`bao kv put secret/<path> value=<token>`), then fetch from OpenBao. Never bake
a new `op item get` or `op read` into a skill or code path for a service token.

Known OpenBao paths for common service tokens:
- Plane API key: `secret/shared/plane-api-key`
- Cloudflare API key + email: `secret/hosting/cloudflare-api` (JSON blob with `credential`, `email`, `account_id`)
- Discord bot tokens: `secret/shared/discord-<slug>`
- GitHub PAT (arc-web): `secret/hermes/github-pat`
- OpenRouter key: `secret/tool-infra/openrouter-key`
- GHL agency PIT: `secret/shared/ghl-agency-pit`

---

## Account logins (web UI logins: Hostinger hPanel, GitHub web UI, Stripe dashboard, Skool admin, GHL dashboards, etc.)

Walk this order and stop at the first valid login path:

1. **1Password** - ARC and Zeroclaw vaults via `op item list --vault <V> --format=json | grep -i <service>`
2. **OpenBao** - check if automation needs the login mirrored for a runtime
   workflow
3. **Explicit local override/cache** - human debugging only
4. **Ask user**

---

## Intentional 1P bootstrap and recovery items

These items are designed for human custody, OpenBao bootstrap, or recovery:

- **OpenBao root token**: 1P ARC `hl23px33remaz2xecl5ecvvaem` field `root_token` - used for writes and policy recovery
- **AppRole backups**: 1P ARC items prefixed `OpenBao AppRole - <name>` - disaster recovery only
- **New credentials**: capture in 1Password first for human custody, then mirror
  to OpenBao before runtime use
- **Human login items**: valid in 1Password unless they become runtime inputs

`OP_SERVICE_ACCOUNT_TOKEN` and `OP_SESSION` are not runtime credentials. They
must not be inherited by schedulers, MCP servers, CI, deploy jobs, agent
containers, or services.

---

## Emergency or manual handoff protocol for service tokens

If OpenBao returns an error for a service token:
1. Print the exact error
2. Retry once (transient network)
3. If still failing, report the intended OpenBao path and the exact failure
4. Use 1Password only if the user explicitly approved emergency recovery or
   manual handoff for this operation
5. After current task: diagnose and fix OpenBao, or mirror the custody copy into
   OpenBao

Silent 1P fallback is a bug. No emergency or manual handoff declaration is a
bug.

**Never copy the credential value to another system.** If GitHub Actions / CI / an external service needs a credential: design a webhook receiver on zeroclaw (zeroclaw fetches from OpenBao and calls out), or an SSH deploy key that lets the runner fetch at runtime. Credential values stay in OpenBao and never travel.

## Trigger

Any task that says "add credential", "wire up access", "connect to vault", "write secret", "give X access to Y", "needs a token". Run mem-search FIRST, then walk the appropriate discovery order above.

Finding `op item get` or `op read` in a skill for a service token = alert. See `feedback_no_1p_for_service_tokens.md`.
