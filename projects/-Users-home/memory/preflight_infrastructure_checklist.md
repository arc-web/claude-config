---
name: Pre-flight checklist - any infrastructure / credential task
description: Before proposing or executing any infra/credential change, walk this list. Prevents the 50-call overengineering pattern from the 2026-04-28 Hermes session. Read agent_credential_map.md + openbao_admin_write_pattern.md first. Never propose .env or new AppRoles.
type: feedback
originSessionId: 11d73955-4195-456c-b3f4-7f63a576b646
---
# Before any infrastructure task

Triggered by tasks containing: "add credential", "wire up access", "give X access", "write secret", "rotate token", "new agent", "new policy", any phrasing involving OpenBao/1P/AppRole.

## Mandatory steps before proposing anything

1. **mem-search** for the exact task (e.g. "hermes github access", "zeroclaw new key"). Prior solutions usually exist.
2. **Read** `agent_credential_map.md` + `openbao_admin_write_pattern.md` + `credentials_architecture.md` QUICK REFERENCE block.
3. **Audit existing infra** - read the target entrypoint (e.g. `/docker/<agent>/entrypoint-openbao.sh`) before assuming a new mechanism is needed. If `fetch()` exists, the change is one line.
4. **Confirm policy already covers path** - check `secret/data/<scope>/*` matches an existing policy before drafting a new one.

## Banned defaults

- Never propose `.env` or `.env.example`.
- Never default to 1Password for runtime service tokens (1P is for account logins + AppRole break-glass backups only).
- Never create a new AppRole for a write task - all AppRoles are read-only by design; use root token.
- Never present a 4-option decision matrix for a routine credential write.
- Never invent secret field names - use `value` (matches existing fetch helpers).
- Never SSH-walk filesystem for tokens before checking 1P + memory.
- Never ask user for a credential before exhausting the discovery order (see feedback_credential_discovery_order.md). For service tokens: env → OpenBao → VPS filesystem → ask. 1P is NOT in the service token path.
- About to write `op read` or `op item get` for a runtime service token? STOP. That is drift. Mirror to OpenBao first, fetch from there. See `feedback_no_1p_for_service_tokens.md`.

## Execution discipline

- Batch SSH: 5-10 inspection commands joined with `;` in one ssh invocation, not 10 separate calls.
- ctx_read same path twice in a session = stop, info is already in context.
- One plan, executed - "do it, don't instruct".

## Why

2026-04-28 Hermes GitHub task: ~60 tool calls for a 5-call job. Root causes: did not read existing `entrypoint-openbao.sh`, designed new AppRole when AppRoles are read-only, asked user for root token that was in 1P ARC the whole time, presented 4 plans instead of executing 1.
