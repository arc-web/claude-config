# OpenBao Canonical Enforcement - Unified Plan

Last updated: 2026-05-16

## Context

Two independent Claude Code sessions hit the same bug within hours:
- This session: wrangler deploy → hunted 1P for CF token → got wrong credential type → wasted 4 turns
- Other session (shown in paste): plane-pm skill instructs `op item get` for Plane API key even though it lives in OpenBao

Root cause is the same in both cases: `credentials_architecture.md` lines 219-235 publish a "local CLI access patterns" table that lists 1P as the primary lookup for service tokens. Skills faithfully copy that pattern. The architecture file's own headline rule ("OpenBao is single source of truth") is contradicted by its own table.

A comprehensive plan already exists at `~/.claude/plans/openbao_canonical_enforcement_epic.md` (created by the other session, approved). This session's `fix-credential-discovery-order.md` is a subset of that epic's Phase B. **This plan supersedes both.**

Existing Plane tasks to check/update:
- AGENT-174 [Needs Approval] - "Fix cron skill docs to reflect OpenBao credential model" - overlaps Phase C
- No existing epic task for this full scope - create one

---

## What this session executes (Phase B - immediate, no VPS access needed)

Memory and docs only. No code changes, no Bao writes, no VPS ops.

### B1 - Rewrite `feedback_credential_discovery_order.md`

Split discovery order by credential type:

**Service tokens** (API keys, bearer tokens, webhook URLs, bot tokens, worker secrets):
1. Env vars + local cache
2. OpenBao - `ssh zeroclaw "VAULT_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root> bao kv get secret/<path>"` (local), or AppRole proxy `127.0.0.1:8100` (in-container)
3. VPS filesystem: `/etc/openbao/<role>.env` or `/etc/openbao/<role>/{role_id,secret_id}`
4. Ask user - ONLY after 2-3 confirmed empty

**DO NOT check 1P for service tokens.** If found in 1P but not Bao: mirror to Bao, then fetch from Bao. Never bake a new `op item get` into a skill for a service token.

**Account logins** (web UI logins: Hostinger hPanel, GitHub web UI, Stripe, Skool, GHL dashboards):
1. Env vars + local cache
2. OpenBao (check first)
3. 1Password - ARC and Zeroclaw vaults
4. Ask user

**Intentional 1P bootstrap (never move these):**
- OpenBao root token: 1P ARC `hl23px33remaz2xecl5ecvvaem` field `root_token`
- AppRole backups: 1P ARC items prefixed `OpenBao AppRole - <name>`
- macOS LaunchAgent `OP_SERVICE_ACCOUNT_TOKEN` injection

File: `~/.claude/projects/-Users-home/memory/feedback_credential_discovery_order.md`

### B2 - Delete the drift-seed table in `credentials_architecture.md`

Lines 219-235: "Local credential access patterns (2026-04-29)" table - this is the root cause. The table lists `op item get` patterns for Plane, Supabase, CF, Resend, GitHub. Delete the table and replace with a single rule block:

> **Runtime credential rule (all environments):** Fetch service tokens from OpenBao. Never write `op item get` or `op read` for a service token in a skill or code file. If the token is missing from OpenBao, mirror it using credsync (Phase F), then fetch from OpenBao.

Stamp `Last updated: 2026-05-16`.

File: `~/.claude/projects/-Users-home/memory/credentials_architecture.md`

### B3 - Add `feedback_no_1p_for_service_tokens.md` (new file)

One-screen rule. Content:
- Rule: `op item get` / `op read` for service tokens is banned in skills and code
- Alert trigger: finding `op item get` in a skill that's not fetching the 3 intentional bootstrap items
- Why: caught twice in the same day causing wasted turns and wrong credential types
- How to apply: before writing any credential fetch, check if it's a service token. If yes, go to OpenBao.

### B4 - Update `preflight_infrastructure_checklist.md`

Add one checklist item: "About to write `op read` or `op item get`? Is it a service token? If yes, STOP - that's drift. Mirror to Bao first."

### B5 - Update `MEMORY.md` index

Update descriptions for B1, B2, add entry for B3.

---

## What gets Plane tasks (Phases A + C-G - future execution)

Create one parent epic + child tasks in AGENT project (`0e399778-93d9-4a95-ba2f-755990dd69bc`):

**Parent:** "OpenBao Canonical Enforcement - Epic" [In Progress]

**Children:**
- AGENT-NEW-A: Mirror missing creds to OpenBao (CF Global Key, Resend, Google Ads) - VPS write ops
- AGENT-NEW-C: Patch skills - plane-pm, credentials, supabase, fathom - bao-first fetch patterns
- AGENT-NEW-D: Patch code - fathom_agent/src/op.ts, client_director/check_schema.sh, delete discord_agent/bot.env
- AGENT-NEW-E: settings.local.json - replace `op read` allowlist entries with bao-fetch wrapper entries
- AGENT-NEW-F: credsync repurpose - add `mirror-to-bao` + `detect` subcommands, daily Discord cron
- AGENT-174 update: mark as child of the parent epic, confirm overlap with Phase C

Phase B (this session) = mark Done on parent once B1-B5 complete.

---

## Verification

After Phase B:
```bash
grep -r "op read\|op item get" ~/.claude/projects/-Users-home/memory/ | grep -v "root_token\|AppRole\|hl23px33"
# Should return zero results - no service token fetches remain
```

Check the two drift files no longer contradict:
- `credentials_architecture.md`: no 1P table for service tokens
- `feedback_credential_discovery_order.md`: OpenBao is step 1 for service tokens, 1P doesn't appear

---

## Files touched this session (Phase B only)

1. `~/.claude/projects/-Users-home/memory/feedback_credential_discovery_order.md` - rewrite
2. `~/.claude/projects/-Users-home/memory/credentials_architecture.md` - delete table at ~lines 219-235, add rule block
3. `~/.claude/projects/-Users-home/memory/feedback_no_1p_for_service_tokens.md` - NEW
4. `~/.claude/projects/-Users-home/memory/preflight_infrastructure_checklist.md` - add checklist item
5. `~/.claude/projects/-Users-home/memory/MEMORY.md` - update index
6. Plane: create parent epic + A/C/D/E/F child tasks, update AGENT-174
