# OpenBao Canonical Enforcement - Epic

Last updated: 2026-05-16

## Context

Caught a live drift: `~/.claude/skills/plane-pm/SKILL.md` and `reference_plane_api.md` instruct fetching the Plane API key from 1P (`op item get x7qhfdaos76fcymuztjjscmrpa --vault Zeroclaw`) even though the same key already lives in OpenBao at `secret/shared/plane-api-key`. That's not an isolated bug. An Explore sweep of skills, memory, settings, and agent code shows the same pattern across ~10 surfaces.

Root cause: `credentials_architecture.md` lines 219-235 publish a "local CLI access patterns" table that sanctions 1P as the primary lookup for most service tokens. The table contradicts the file's own headline rule ("OpenBao is the single source of truth for all agent credentials") and every downstream skill faithfully copied the 1P pattern.

Intended outcome: OpenBao is the only documented runtime path. 1P is emergency-only break-glass for the AppRole/root creds that bootstrap Bao. Drift between the two stores is an alert, not a workflow. Every skill, settings file, and agent code path is patched to match. Memory is consolidated so the rule is unambiguous.

---

## Drift inventory (Phase-1 findings)

### Credentials already in OpenBao but still fetched via 1P in code/docs

| Credential | OpenBao path | Drift sites |
|---|---|---|
| Plane API key | `secret/shared/plane-api-key` | `skills/plane-pm/SKILL.md` lines 13-19, 82-91; `memory/reference_plane_api.md` line 23; `memory/credentials_architecture.md` line 228 |
| GitHub PAT (arc-web) | `secret/hermes/github-pat` | `memory/credentials_architecture.md` line 222 |
| Discord bot tokens (6x) | `secret/shared/discord-<slug>` | Multiple memory files (postmortem refs); `agents/comms/discord_agent/bot.env` (stale env file) |
| Supabase PAT/keys | `secret/tool-infra/supabase-*` | `agents/development/client_director/check_schema.sh:6`; `memory/credentials_architecture.md` line 227; `settings.local.json` allowlist |
| Fathom API key | `secret/data/fathom/*` | `agents/comms/fathom_agent/src/op.ts:14`; `agents/comms/fathom_agent/CLAUDE.md` (op run --env-file); `settings.local.json` allowlist |
| OpenRouter key | `secret/tool-infra/openrouter-key` | (already Bao-first, leave) |

### Credentials NOT yet in OpenBao - net-new mirror work

| Credential | Current 1P location | Target Bao path |
|---|---|---|
| Cloudflare Global API Key | 1P ARC "Cloudflare Global API Key - ARC" | `secret/tool-infra/cloudflare-api-key` |
| Cloudflare account email | 1P ARC same item, field email | `secret/tool-infra/cloudflare-account-email` |
| Resend API key | 1P ARC "Resend API Key" | `secret/tool-infra/resend-api-key` |
| Google Ads OAuth set (5 fields) | 1P ARC scattered | `secret/tool-infra/google-ads-*` (paths already reserved in arch doc line 64) |

### Intentional 1P (keep)

- OpenBao root token (1P ARC `hl23px33remaz2xecl5ecvvaem` field `root_token`) - bootstrap only, used by Claude Code for writes
- AppRole `role_id`/`secret_id` backups (1P ARC `OpenBao AppRole - <name>`) - disaster recovery
- macOS LaunchAgent `OP_SERVICE_ACCOUNT_TOKEN` injection - needed for the above two

Everything else fetched via `op` is drift.

---

## Execution plan

### Phase A - Mirror missing creds into Bao

Files to read/touch:
- `memory/openbao_admin_write_pattern.md` - the root-token write pattern
- `memory/agent_credential_map.md` - confirm path conventions (field=`value`)

Actions:
1. Fetch CF/Resend/Google Ads secrets from 1P ARC.
2. Write each to Bao using root token + field `value` (matches `fetch()` helper convention).
3. Add `host-scripts` policy line for any new `tool-infra/` subpath if missing.
4. Verify read via `ssh zeroclaw 'source /opt/openbao-wrapper/lib.sh && export BAO_AUTH_FILE=/etc/openbao/host-scripts.env && bao_auth && bao_get tool-infra/cloudflare-api-key value'`.

### Phase B - Heal memory (canonical doc)

Single file is the source of contradiction. Rewrite is surgical:

1. `memory/credentials_architecture.md`:
   - Delete the "Local credential access patterns (2026-04-29)" table at lines 214-235. That table is the drift seed.
   - Replace section 2 "1Password - local-only role" with a tighter version:
     - Tier 1: OpenBao for **every** service/runtime credential (no exceptions, no per-credential carve-outs).
     - Tier 2: 1P emergency-only - bootstrap creds (Bao root token, AppRole role_id/secret_id), account logins still being migrated, and offline break-glass if Bao is unreachable.
     - Drift rule: if a service token is found in 1P but not in Bao, that's an alert. Mirror it into Bao before using it. Never bake a 1P fetch into a new skill/code path.
   - Add a "Canonical retrieval commands" block - one block per environment (local Mac via SSH-fetch, VPS via proxy, VPS host-scripts via wrapper).
   - Stamp `Last updated: 2026-05-16`.

2. `memory/preflight_infrastructure_checklist.md`:
   - Add "If you're about to write `op read` or `op item get` for a runtime service token - STOP. That's drift. Mirror to Bao and fetch from there."

3. `memory/feedback_credential_discovery_order.md`:
   - Reorder so OpenBao is step 1, 1P drops to step 3 (after env/cache), and add explicit "treat any 1P hit on a service token as a TODO to mirror to Bao."

4. New file `memory/feedback_no_1p_for_service_tokens.md` (feedback-type) - one-screen rule with the why and the alert trigger.

5. Update `MEMORY.md` index entries for the changed files.

### Phase C - Patch skills

| Skill | Change |
|---|---|
| `skills/plane-pm/SKILL.md` | Replace `op item get` example with the `ssh zeroclaw ... bao_get shared/plane-api-key value` pattern. Move 1P snippet under "Emergency fallback if Bao unreachable". |
| `skills/credentials/SKILL.md` | Add a top-of-file invariant: "OpenBao first, always. 1P only for the 3 intentional cases listed in credentials_architecture.md." |
| `skills/supabase/SKILL.md` (if it references `op read`) | Convert to bao-first. |
| `skills/fathom/SKILL.md` (if it references `op run`) | Convert to bao-first. |

Skills are git-tracked - any edit auto-commits via the always-on rule in CLAUDE.md.

### Phase D - Patch code call-sites

| File | Change |
|---|---|
| `agents/comms/fathom_agent/src/op.ts` | Replace `op read` with HTTP call to Bao agent proxy at `127.0.0.1:8100` (in-container) or SSH fetch (local). |
| `agents/comms/fathom_agent/CLAUDE.md` | Drop `op run --env-file=.env.1p` invocation; add bao-fetch alternative. |
| `agents/development/client_director/check_schema.sh` | Replace line 6 `op read` with `bao_get tool-infra/supabase-anon-key value`. |
| `agents/comms/discord_agent/bot.env` | Confirmed stale - delete the file (tokens are now in Bao at `secret/shared/discord-<slug>`). |

### Phase E - Settings + permission allowlist

`~/.claude/settings.local.json` Bash allowlist currently sanctions `op read` for Supabase, Cloudflare, Resend, Fathom. Rewrite entries to reference the bao-fetch wrapper instead:

- `Bash(ssh zeroclaw source /opt/openbao-wrapper/lib.sh*)` - generic bao-fetch
- Keep `Bash(op item get hl23px33remaz2xecl5ecvvaem*)` - root token bootstrap only
- Keep `Bash(op item get *--vault ARC*OpenBao AppRole*)` - AppRole break-glass only

### Phase F - credsync repurpose + drift detector

Two-part: detect drift AND fix it with one tool.

**F1. Repurpose `credsync`** at `~/ai/workspaces/aimacpro/7_tools/credentials/credsync.py`:
- Current behavior: syncs between 1P vaults (Zeroclaw ↔ ARC).
- New behavior: adds a `mirror-to-bao` subcommand that pulls a 1P item, translates field name (1P `credential` → Bao `value`), writes to `secret/<path>` via Bao root token.
- Map file: `~/ai/workspaces/aimacpro/7_tools/credentials/mirror_map.yaml` declares known 1P-item-id → Bao-path pairs (Plane, CF, Resend, Google Ads etc.).
- Keep dry-run default + `--reveal` gate.
- Per directory law, the tool may stay in aimacpro/7_tools/credentials/ since it's already there; if extracted, target is `~/ai/tools/credsync/`.

**F2. Drift detector** as new mode `credsync detect`:
1. Lists items in 1P ARC + Zeroclaw vaults matching the mirror_map service set.
2. Lists Bao secrets under `secret/{shared,tool-infra,hermes,zeroclaw-*,fathom,paperclip}/`.
3. Reports drift = 1P-only OR Bao value diverges from 1P (hash compare without leaking value).
4. Output: pretty stdout for human runs, JSON for cron.

**F3. Daily Discord pipe:**
- Schedule: daily cron on zeroclaw via `/etc/cron.d/openbao-drift` at 09:00 ET.
- On any drift: post immediate Charlie-bot message to a dedicated channel (`#bao-drift` - create if missing).
- Always: one daily digest at 09:00 summarizing current drift state (even if zero - "all clean" heartbeat so silence isn't ambiguous).
- Channel post path: existing `discord_agent` CLI at `~/ai/agents/comms/discord_agent/` (per memory `reference_discord.md`).

### Phase G - Plane epic

Open one Plane epic in AGENT project (`0e399778-93d9-4a95-ba2f-755990dd69bc`) titled "OpenBao Canonical Enforcement" with child tasks per phase A-F. Use the handoff-prompt template (per AGENT-206 / -207 work) so any agent can resume mid-phase cold.

---

## Critical files to modify (paths)

Memory:
- `~/.claude/projects/-Users-home/memory/credentials_architecture.md`
- `~/.claude/projects/-Users-home/memory/preflight_infrastructure_checklist.md`
- `~/.claude/projects/-Users-home/memory/feedback_credential_discovery_order.md`
- `~/.claude/projects/-Users-home/memory/MEMORY.md`
- NEW: `~/.claude/projects/-Users-home/memory/feedback_no_1p_for_service_tokens.md`

Skills:
- `~/.claude/skills/plane-pm/SKILL.md`
- `~/.claude/skills/credentials/SKILL.md`
- `~/.claude/skills/supabase/SKILL.md` (if affected)
- `~/.claude/skills/fathom/SKILL.md` (if affected)

Code:
- `~/ai/agents/comms/fathom_agent/src/op.ts`
- `~/ai/agents/comms/fathom_agent/CLAUDE.md`
- `~/ai/agents/development/client_director/check_schema.sh`
- `~/ai/agents/comms/discord_agent/bot.env` (delete)

Settings:
- `~/.claude/settings.local.json`

Tool repurpose:
- `~/ai/workspaces/aimacpro/7_tools/credentials/credsync.py` (extend with `mirror-to-bao` + `detect` subcommands)
- NEW: `~/ai/workspaces/aimacpro/7_tools/credentials/mirror_map.yaml` (1P-item → Bao-path declarations)

Discord:
- Create `#bao-drift` channel in ARC guild via `discord_agent` CLI if not present.

VPS:
- Bao writes for CF/Resend/Google Ads under `secret/tool-infra/`
- `/etc/cron.d/openbao-drift` (drift detector schedule)

---

## Verification

End-to-end checks after rollout:

1. `grep -r "op read\|op item get" ~/.claude/skills/ ~/.claude/projects/-Users-home/memory/` returns only the 3 intentional bootstrap/AppRole cases.
2. Plane skill executes cleanly: `ssh zeroclaw 'source /opt/openbao-wrapper/lib.sh && export BAO_AUTH_FILE=/etc/openbao/host-scripts.env && bao_auth && bao_get shared/plane-api-key value'` returns the key.
3. Same for new mirrors: `bao_get tool-infra/cloudflare-api-key value`, `bao_get tool-infra/resend-api-key value`, `bao_get tool-infra/google-ads-refresh-token value`.
4. Fathom agent fetches via Bao proxy (in-container) - check container log shows proxy hit not `op` invocation.
5. `credsync detect --json` dry-run - manually trigger, confirm Discord alert posts to `#bao-drift` when a known 1P-only service is detected and "all clean" heartbeat posts when mirrored.
6. `credsync mirror-to-bao <1p-item-id>` round-trip - mirror, then `bao_get` returns same value, then `credsync detect` reports zero drift.
7. Plane epic exists with 6 child tasks (one per phase A-F), each with full handoff prompt + `— [Agent: ... | YYYY-MM-DD]` attribution trailer per `feedback_plane_task_fields.md`.
