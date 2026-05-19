# Plane Project Prefix Rename Sweep

## Context

todovibes workspace renamed 6 project identifiers between the original Plane setup (~2026-04 era) and today (2026-05-20). Memory files, plan files, skills, and live Plane comments still reference the old prefixes. Old issue refs like `AGENT-342` still resolve by UUID, but the display label now reads `INTERNALOPS-342` in Plane's UI. Result: stale text everywhere that misleads agents and humans about which project an issue lives in. Sweep fixes this in one batch.

**Identifier map:**

| Old | New | Verified live |
|---|---|---|
| AGENT | INTERNALOPS | ✓ |
| AGNTS | AGENTS | ✓ (no old refs found) |
| INFRA | INFRASTRUCT | ✓ |
| COMM | COMMUNITIES | ✓ |
| ADS | GOOGLEADS | ✓ |
| LAND | WEBDESIGN | ✓ (no old refs found) |
| DEVOPS | DEVOPS | unchanged |

## Scope inventory (occurrences per file)

**Total: ~410 occurrences across 35 files.** Some are historical/narrative (can stay), most need updating.

### Memory files (6 files, 10 refs)
| File | Refs | Notes |
|---|---|---|
| `rules_tool_transparency.md` | 5 | Active examples - update |
| `reference_plane_api.md` | 1 | API reference example - update |
| `MEMORY.md` | 1 | Index entry - update |
| `feedback_plane_task_always.md` | 1 | Rule text - update |
| `feedback_end_of_turn_structure.md` | 1 | Rule text - update |
| `failure_arc_browser_2026-05-19.md` | 1 | "COMM-35" cycle ref - update to COMMUNITIES-35 |

### Plan files (23 files, ~395 refs)

High-volume plans:
| File | Refs | Status decision |
|---|---|---|
| `google_ads_agent_sonnet_swarm_execution.md` | 119 | Active swarm program - update |
| `google_ads_agent_production_readiness_program.md` | 75 | 58 cancelled but plan still active - update |
| `stackpack_plane_cleanup_v2.md` | 58 | Active StackPack work - update |
| `stackpack_plane_cleanup_and_resolution.md` | 48 | Active - update |
| `openbao_blind_spot_task_tree.md` | 25 | Today's plan with AGENT/INFRA/COMM refs in tree + AGENT-225 historical - update active, leave AGENT-225 quoted as-is |
| `plane_task_sync_auth_consolidation.md` | 12 | Active - update |
| `cycle_automation_pm_analysis.md` | 10 | Today's plan - update |

Lower-volume (1-7 refs each, 11 files): `plane_github_bridge.md`, `session-knowledge-consolidation.md`, `plane_workspace_gap_analysis.md`, `openbao_credential_test.md`, `tool_transparency_standard.md`, `bpm_marine_p2_p3b_build.md`, `openbao-enforcement-unified.md`, `google_ads_marine_next_steps.md`, `plane_system_centralize.md`, `openbao_team_access.md`, `ghl_full_access_auth_architecture.md`. All update.

Single-ref (4 files): `skill_updates_plane_github.md`, `projectmanagement_category_and_plane_pm_agent.md`, `openbao_canonical_enforcement_epic.md`, `copy_engine_industry_guides.md`, `agentic_browser_intelligence_v3.md`. Update each.

### Skill files (3 files, 11 refs)
| File | Refs | Notes |
|---|---|---|
| `plane-pm/SKILL.md` | 6 | Doc examples - update |
| `github-pr-flow/SKILL.md` | 4 | Doc examples - update |
| `swarm-program/SKILL.md` | 1 | Doc example - update |

### Live Plane comments (2 today)
| Comment | Posted on | Issue |
|---|---|---|
| Master epic cycle URLs comment | INTERNALOPS-342 (was AGENT-342) | Refers to "INFRA-184", "AGENT-357" in body |
| AGENT-225 reference comment | INTERNALOPS-225 (still resolves) | Refers to "AGENT-342" in body |

These were posted before the rename was noticed. Edit-in-place via Plane API to swap labels.

### Discord message (1 today)
Channel `🤖-ai`, msg ID `1506372806890225864` (Johan brief, "Direction for finalizing OpenBao"). Mentions `INFRA-184`, `AGENT-357`, `INFRA-182`, `DEVOPS-14` (DEVOPS-14 stays correct). Edit via Discord API or post follow-up correction.

### What stays as-is (historical / narrative)
- Quoted task refs from cancelled work being explained as "superseded by..." in `openbao_blind_spot_task_tree.md` and AGENT-225 reconciliation doc - keep original labels in QUOTES, add `[now INTERNALOPS-225]` parenthetical only.
- Old project UUID `0e399778-93d9-4a95-ba2f-755990dd69bc` references - unchanged, still valid, no edit needed.
- DEVOPS-* refs - unchanged.

## Task tree

### Phase 1 - Live Plane comments (highest blast radius, do first)

**P1-1.** Fetch the master epic cycle comment posted on INTERNALOPS-342 today. Find UUID of comment via API `GET /workspaces/todovibes/projects/<INTERNALOPS-UUID>/issues/1d053404-a1ce-4aca-a018-b81a6117dfc7/comments/`. Identify the comment that lists 3 cycle URLs + INFRA/AGENT refs.

**P1-2.** Edit comment via `PATCH /comments/<uuid>/`. Rewrite body: `AGENT-342` -> `INTERNALOPS-342`, `INFRA-184` -> `INFRASTRUCT-184`, `AGENT-357` -> `INTERNALOPS-357`, `INFRA-182` -> `INFRASTRUCT-182`. Cycle URLs unchanged (UUID-based).

**P1-3.** Same on INTERNALOPS-225 (was AGENT-225) cancellation-link comment. Rewrite `AGENT-342` -> `INTERNALOPS-342`. Same PATCH endpoint.

### Phase 2 - Discord follow-up

**P2-1.** Edit Discord message `1506372806890225864` in `🤖-ai` via Discord API `PATCH /channels/<id>/messages/<id>`. Swap `INFRA-184` -> `INFRASTRUCT-184`, `AGENT-357` -> `INTERNALOPS-357`, `INFRA-182` -> `INFRASTRUCT-182`, `AGENT-342` -> `INTERNALOPS-342`. DEVOPS-14 keep. Cycle URLs unchanged.

**P2-2.** Optional: post a one-liner reply confirming the rename happened mid-session so Johan understands the change.

### Phase 3 - Memory files (10 refs, low blast)

**P3-1.** Edit `rules_tool_transparency.md` - 5 refs. Run `sed` swap pattern across all 6 prefixes.
**P3-2.** Edit `reference_plane_api.md` - 1 ref + add a "Project identifier rename history" note section.
**P3-3.** Edit `MEMORY.md` - 1 ref. Index entry.
**P3-4.** Edit `feedback_plane_task_always.md` - 1 ref. Rule text "AGENT project (ID: 0e399778-...)" -> "INTERNALOPS project (ID: 0e399778-...)". UUID stays.
**P3-5.** Edit `feedback_end_of_turn_structure.md` - 1 ref.
**P3-6.** Edit `failure_arc_browser_2026-05-19.md` - 1 ref `COMM-35` -> `COMMUNITIES-35`.

### Phase 4 - Skills (11 refs)

**P4-1.** Edit `plane-pm/SKILL.md` - 6 refs. Documentation examples.
**P4-2.** Edit `github-pr-flow/SKILL.md` - 4 refs.
**P4-3.** Edit `swarm-program/SKILL.md` - 1 ref.

### Phase 5 - High-volume plan files (sed-batchable)

Use `sed -i '' -E 's/\b(AGENT|INFRA|COMM|ADS)-([0-9]+)/<MAP>-\2/g'` with explicit per-prefix substitutions, executed per file. NOT a single regex because each old prefix maps to a different new prefix.

**P5-1.** `google_ads_agent_sonnet_swarm_execution.md` (119 refs) - swap AGENT→INTERNALOPS, ADS→GOOGLEADS.
**P5-2.** `google_ads_agent_production_readiness_program.md` (75 refs) - swap AGENT→INTERNALOPS, ADS→GOOGLEADS.
**P5-3.** `stackpack_plane_cleanup_v2.md` (58 refs) - swap COMM→COMMUNITIES.
**P5-4.** `stackpack_plane_cleanup_and_resolution.md` (48 refs) - swap COMM→COMMUNITIES.
**P5-5.** `openbao_blind_spot_task_tree.md` (25 refs) - swap AGENT→INTERNALOPS, INFRA→INFRASTRUCT, COMM→COMMUNITIES. PRESERVE quoted historical AGENT-225/226/227/229/230/303 with parenthetical addition.
**P5-6.** `plane_task_sync_auth_consolidation.md` (12 refs).
**P5-7.** `cycle_automation_pm_analysis.md` (10 refs).

### Phase 6 - Low-volume plan files (11 files, 1-7 refs each)

Single sed pass per file:
`plane_github_bridge.md`, `session-knowledge-consolidation.md`, `plane_workspace_gap_analysis.md`, `openbao_credential_test.md`, `tool_transparency_standard.md`, `bpm_marine_p2_p3b_build.md`, `openbao-enforcement-unified.md`, `google_ads_marine_next_steps.md`, `plane_system_centralize.md`, `openbao_team_access.md`, `ghl_full_access_auth_architecture.md`, `skill_updates_plane_github.md`, `projectmanagement_category_and_plane_pm_agent.md`, `openbao_canonical_enforcement_epic.md`, `copy_engine_industry_guides.md`, `agentic_browser_intelligence_v3.md`.

### Phase 7 - Commit + push

**P7-1.** Skill edits auto-commit per memory rule: `cd ~/ai/tools/ai/claude-skills && git add . && git commit && git push`.
**P7-2.** Memory + plan + audit_directive are in `~/.claude/` (not a tracked repo for the user). No commit needed for those.

### Phase 8 - Verification

**P8-1.** Re-run sweep grep: `grep -rcE "\b(AGENT|AGNTS|INFRA|COMM|ADS|LAND)-[0-9]+" ~/.claude/ 2>/dev/null | grep -v ":0$"` returns 0 results except the explicitly-preserved historical quotes.
**P8-2.** Fetch the two Plane comments via API and confirm new labels in body_html.
**P8-3.** Fetch Discord message via API; confirm edited content.
**P8-4.** Update INTERNALOPS-376 lifecycle issue with closing comment listing files touched.

## Edge cases + handling

- **`AGENT_` env var lookups** (e.g., `AGENT_PROJECT_UUID` in code) - regex anchored on `-[0-9]+` so won't false-positive. Confirmed.
- **`AGENT` in narrative without `-XX`** ("AGENT project") - bare project names are still ambiguous. Leave them; only sweep `<PREFIX>-<NUMBER>` patterns.
- **Cancelled / historical refs** - keep original label in quotes, add `[now <NEW>-XX]` only where context is unclear. Don't rewrite the history.
- **AGENT-225 reconciliation doc** at `/Users/home/plane_cleanup/20260517_openbao_task_reconciliation_review.md` - external to ~/.claude/. Out of scope for this sweep unless explicitly requested.
- **PR descriptions, GitHub gists, external Plane workspace tasks not in todovibes** - out of scope.

## Critical files

- Source of truth for new identifiers: `PLANE_WORKSPACE=todovibes /Users/home/.local/bin/plane projects` (live)
- Memory + plans + skills under `/Users/home/.claude/`
- Plane API: `https://arc.todovibes.com/api/v1/workspaces/todovibes/projects/<pid>/issues/<iid>/comments/<cid>/` (PATCH)
- Discord API: `https://discord.com/api/v10/channels/<cid>/messages/<mid>` (PATCH) via `discord_api.py`
- Plane CLI: `~/ai/agents/projectmanagement/plane_agent/plane` (read-only for this sweep; write via direct API)

## Verification (end-to-end)

1. `grep -rcE "\b(AGENT|AGNTS|INFRA|COMM|ADS|LAND)-[0-9]+" ~/.claude/ 2>/dev/null | grep -v ":0$" | wc -l` - should equal only the preserved-historical lines count documented in P5-5.
2. Re-fetch INTERNALOPS-342 comments via API, confirm body uses new labels.
3. Re-fetch INTERNALOPS-225 comments, confirm.
4. Re-fetch Discord message `1506372806890225864`, confirm new labels.
5. INTERNALOPS-376 has closing comment with sweep summary.

## Decisions confirmed

- **Historical refs: annotate only.** Cancelled task refs (AGENT-225/226/227/229/230/303 etc.) stay in their original quoted form; add `[now INTERNALOPS-225]` parenthetical inline where context is unclear. Preserves the rename breadcrumb.
- **Discord: edit in place only, silent.** No follow-up notification. Johan reads corrected text next time he opens the channel.
- **Lifecycle issues: flat.** No epic for memory/hygiene audits. INTERNALOPS-376 stays orphan; future audits same.

## Done / Open / Recommend

Done: Inventory complete (35 files, ~410 refs). Map verified live. Tier 1/2/3 phasing drafted. Edge cases identified. Verification commands ready.

Open: 3 open questions above. INTERNALOPS-376 needs closing comment after sweep.

Recommend: Answer the 3 open questions, then build Phase 1 (live Plane comments) first since those are public + agent-facing. Memory + plans can be batched after. Total effort if all-auto: 15-25 min execute + verify.
