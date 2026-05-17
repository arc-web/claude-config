# Plan: Sync Plane documentation across all 4 sources with cross-references

## Context

Plane documentation currently lives in 4 places. Each was written at a different time and they have drifted:

- **A.** Skill: `~/.claude/skills/plane-pm/SKILL.md` (updated 2026-05-16; most complete; missing Clients workspace UUIDs)
- **B.** Memory: `~/.claude/projects/-Users-home/memory/reference_plane_api.md` (verified 2026-05-11; has wrong LAND UUID duplicate; missing Clients UUIDs; no cross-refs)
- **C.** Memory: `~/.claude/projects/-Users-home/memory/project_plane_workspaces.md` (has Clients workspace structure but no UUIDs; no cross-refs)
- **D.** Plane Pages (in-app wiki at arc.todovibes.com; no doc page exists yet)

User wants all 4 updated to a consistent state and each to point at the other three so any one entry point gets the reader to the full picture.

Today (2026-05-16) confirmed live:
- Clients workspace projects (verified via ssh zeroclaw curl):
  - TMPL `b7c7c9d8-2be5-44be-ad0d-3682f14ef905` Templates
  - BLPX `23228989-849b-418a-b344-9a7c565d5ad1` BluePixel
  - BLGR `2ccf605e-6474-4df4-95da-76a70121f387` BlueGorilla
  - MOON `8a64261f-f129-4e67-8976-b3b116cf54d4` Moonraker
  - ARC `e05a2d3e-502f-4b5a-bac5-8ce189e41b21` ARC
- LAND UUID in `reference_plane_api.md` is wrong (duplicates ADS `b1b1b597...`); correct value from skill is `b7f45068-8020-4245-ab48-a2234a9c7d43`.
- Header convention: skill uses `X-API-Key`, reference uses `X-Api-Key`; HTTP headers are case-insensitive and both work — pick one (skill's `X-API-Key`) for consistency.

## Roles after sync (canonical vs derivative)

- **A. Skill (plane-pm/SKILL.md)** = operational SOP. Full how-to, Python pattern, all UUIDs, all state IDs, rate limits.
- **B. reference_plane_api.md** = compact API quick-card. Key, headers, endpoints, link to skill for full pattern.
- **C. project_plane_workspaces.md** = workspace + project semantics (what each workspace and project is for, module pattern).
- **D. Plane Pages** = in-app reader-facing summary so anyone in Plane (not just CLI users) can find the docs.

## Critical files to edit

1. `~/.claude/skills/plane-pm/SKILL.md`
2. `~/.claude/projects/-Users-home/memory/reference_plane_api.md`
3. `~/.claude/projects/-Users-home/memory/project_plane_workspaces.md`
4. Plane page (created via API): one page in AGENT project (todovibes) titled "Plane API + workspace reference", linking back to the three local files by path.

## Changes per file

### A. `~/.claude/skills/plane-pm/SKILL.md` (skill)

- Bump `Last updated: 2026-05-16`.
- Add **Clients workspace project UUIDs** table (TMPL/BLPX/BLGR/MOON/ARC with verified UUIDs above).
- Note "Clients workspace projects = one per client; modules = sub-customer or sub-scope" with pointer to `project_plane_workspaces.md` for the full pattern.
- Add a **See also** section at the bottom listing:
  - `~/.claude/projects/-Users-home/memory/reference_plane_api.md` (compact API quick-card)
  - `~/.claude/projects/-Users-home/memory/project_plane_workspaces.md` (workspace + project semantics)
  - `~/.claude/projects/-Users-home/memory/feedback_plane_task_always.md` (always-create-task rule)
  - In-app: AGENT project Pages → "Plane API + workspace reference" (link populated after page is created)
- Keep `X-API-Key` casing.

### B. `~/.claude/projects/-Users-home/memory/reference_plane_api.md` (memory: API quick-card)

- Bump verification date to 2026-05-16.
- Fix LAND UUID: replace duplicate `b1b1b597-02d6-475d-9b5c-37c64276e1ea` with correct `b7f45068-8020-4245-ab48-a2234a9c7d43`.
- Normalize header to `X-API-Key` (match skill).
- Add **Clients workspace project UUIDs** subsection (5 projects above).
- Trim the Python pattern down to "see skill for full pattern" — keep only the smallest curl example here. This file is meant to be the quick-card.
- Add **See also** footer with pointers to:
  - Skill `~/.claude/skills/plane-pm/SKILL.md` (full SOP)
  - `project_plane_workspaces.md` (semantics)
  - `feedback_plane_task_always.md` (rule)
  - Plane page (after creation)

### C. `~/.claude/projects/-Users-home/memory/project_plane_workspaces.md` (memory: workspace semantics)

- Append the Clients workspace UUID table (same 5 as above) so this file is the canonical project list for that workspace too.
- Verification date line: "verified live 2026-05-16".
- Add **See also** footer:
  - Skill `~/.claude/skills/plane-pm/SKILL.md`
  - `reference_plane_api.md`
  - `feedback_plane_task_always.md`
  - Plane page (after creation)
- Leave the COMM/community module pattern and "Plane CLI hardcodes workspace" gotcha intact.

### D. Plane Page (in-app)

Create via API at:
`POST /api/v1/workspaces/todovibes/projects/0e399778-93d9-4a95-ba2f-755990dd69bc/pages/`

Title: `Plane API + workspace reference`
Body (description_html, public access=0):
- One-paragraph "what Plane is here, where the docs live".
- Workspace table (todovibes / clients).
- Internal project UUID table.
- Clients project UUID table.
- Key retrieval one-liner.
- Header rules.
- **See also** block linking back to the 3 local files by absolute path so any operator on the machine can find them.

After creation, edit A/B/C `See also` blocks to include the Plane page URL.

## Verification

End-to-end check after edits:

1. `cf-deploy lint` not applicable — these are docs only.
2. Re-read each of A/B/C and confirm:
   - Cross-reference block lists the other three sources by path/URL.
   - UUIDs match the live API (re-run the `ssh zeroclaw curl` for each workspace's `/projects/`).
   - `Last updated` / `verified` date = 2026-05-16.
3. Hit Plane page in browser; confirm rendered HTML shows the same UUID tables and the See-also links to file paths.
4. Spot-check: in a fresh session ask "where do Plane docs live?" — answer should name all 4 sources (the three local files plus the Plane page).

## Sequencing

1. Edit A (skill) - add Clients UUIDs + See-also stub.
2. Edit B (api quick-card) - fix LAND UUID, normalize header, add Clients UUIDs, trim, See-also stub.
3. Edit C (workspaces) - add UUID table, bump date, See-also stub.
4. Create Plane page via API; capture page UUID and URL.
5. Edit A/B/C to populate the Plane page URL in their See-also block.
6. Commit skill change to `arc-web/claude-skills` (`~/.claude/skills` is the symlink; auto-commit per CLAUDE.md skill-edit rule).

## Out of scope

- No changes to `feedback_plane_task_always.md` (already correct).
- No changes to `agent_credential_map.md` or `openbao_admin_write_pattern.md`.
- No new memory file — three existing ones + one Plane page covers it.
