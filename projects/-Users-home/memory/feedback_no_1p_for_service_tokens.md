---
name: No 1Password for service tokens - OpenBao only
description: op item get / op read for service tokens (API keys, bearer tokens, webhooks, bot tokens) is banned in skills and code. OpenBao is the only runtime path. Finding 1P fetch in a skill = alert, mirror to OpenBao before proceeding.
type: feedback
originSessionId: 9ae3ac9b-afd9-492d-a109-07c3b8188200
---
# No 1Password for service tokens

**Rule:** `op item get` and `op read` for service tokens is banned in skills and runtime code. OpenBao is the only documented fetch path.

**Why:** Caught twice 2026-05-16 in independent sessions. The pattern costs turns (wrong vault, wrong field, wrong credential type), and it silently bypasses the canonical store. Skills downstream of 1P drift the moment a key rotates in OpenBao but not in 1P.

**Service tokens = API keys, bearer tokens, webhook URLs, bot tokens, worker secrets, PATs, OAuth tokens.** Account logins (web UI passwords) are different - see `feedback_credential_discovery_order.md`.

## Alert trigger

Finding any of these in a skill, CLAUDE.md, or code file (outside the 3 intentional bootstrap items):

```
op item get ...
op read "op://...
op run --env-file=...
```

That is drift. Before using it: mirror the credential to OpenBao, update the skill/code to fetch from OpenBao, then proceed.

## The 3 intentional bootstrap exceptions (1P only, do not move)

1. `op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token` - OpenBao root token bootstrap
2. `op item get "OpenBao AppRole - <name>" --vault ARC` - AppRole disaster recovery
3. macOS LaunchAgent `OP_SERVICE_ACCOUNT_TOKEN` injection for local `op` CLI auth

Everything else = drift.

## How to apply

Before writing any credential fetch in a skill or code:
1. Is it a service token? → OpenBao only. Use `ssh zeroclaw "VAULT_ADDR=... BAO_TOKEN=<root> bao kv get secret/<path>"` locally, or AppRole proxy `127.0.0.1:8100` in-container.
2. Is it an account login? → OpenBao first, then 1P fallback.
3. Is it one of the 3 bootstrap items? → 1P only, no OpenBao.
4. Credential missing from OpenBao? → Mirror it via `bao kv put secret/<path> value=<token>`, then fetch from OpenBao. Never use 1P as the runtime path.

## Mirror pattern (when you find drift)

```bash
ROOT=$(op item get hl23px33remaz2xecl5ecvvaem --vault ARC --reveal --fields root_token)
TOKEN=$(op item get <item-id> --vault <vault> --reveal --fields credential)
ssh zeroclaw "VAULT_ADDR=http://127.0.0.1:8200 BAO_TOKEN=$ROOT bao kv put secret/<path> value=$TOKEN"
```

Then update the skill/code to fetch from `secret/<path>` and remove the `op item get`.
