# Fix: Credential Discovery Order Contradiction

## Context

`feedback_credential_discovery_order.md` lists 1Password as step 2 and OpenBao as step 3 for ALL credential types. `credentials_architecture.md` says "OpenBao is the single source of truth for all agent credentials" and "1Password has NO role for VPS or agents." These directly contradict each other. This caused the agent to hunt 1P for a Cloudflare API token (a service token) instead of going straight to OpenBao — wasting turns and using the wrong lookup pattern.

The architecture file already has the correct split rule (service tokens → OpenBao only; account logins → OpenBao first, 1P fallback). The discovery order file just doesn't reflect it.

## What's wrong

`feedback_credential_discovery_order.md`:
- Step 2 is "1Password — both ARC and Zeroclaw vaults. Includes: API keys, account logins" (too broad)
- Step 3 is OpenBao (too late for service tokens)
- No distinction between service tokens and account logins

`credentials_architecture.md` (correct, no change needed):
- Service API tokens → OpenBao only, never fall back to 1P
- Account logins → OpenBao first, then 1P fallback

## Fix

**One file to rewrite:** `~/.claude/projects/-Users-home/memory/feedback_credential_discovery_order.md`

Rewrite the discovery order section to match the architecture file's split rule:

```
## Service tokens (API keys, bearer tokens, webhook URLs, bot tokens, worker secrets)

1. Env vars + local cache
2. OpenBao (ssh zeroclaw → bao kv get secret/...) — ONLY source, no fallback to 1P
3. VPS filesystem: /etc/openbao/<role>.env or /etc/openbao/<role>/{role_id,secret_id}
4. Ask user — only if OpenBao + VPS filesystem both empty

DO NOT check 1P for service tokens. If it's missing from OpenBao, add it to OpenBao, don't pull from 1P.

## Account logins (web UI logins: Hostinger hPanel, GitHub web UI, Stripe dashboard, Skool admin, etc.)

1. Env vars + local cache
2. OpenBao (check first)
3. 1Password — ARC and Zeroclaw vaults
4. Ask user
```

Also update the `description` field in the frontmatter to reflect the split rule.

## Files to touch

- `~/.claude/projects/-Users-home/memory/feedback_credential_discovery_order.md` — rewrite discovery order section
- `~/.claude/projects/-Users-home/memory/MEMORY.md` — update the one-line description for this entry to mention the service/login split

## Verification

After edit: re-read both files and confirm:
- Discovery order for service tokens goes env → OpenBao → VPS filesystem → ask (no 1P)
- Discovery order for account logins goes env → OpenBao → 1P → ask
- No remaining reference to "API keys" under the 1P step
- Both files agree on the canonical source for service tokens
