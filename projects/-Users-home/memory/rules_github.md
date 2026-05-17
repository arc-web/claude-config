---
name: GitHub, repos, project boundaries, file moves, scaffolding, plan naming
description: Self-contained projects, search before create, move checklist, verify before archive, data preservation, scaffold tool, plan file naming
type: feedback
originSessionId: 48314f94-ae1f-4493-8507-4fbb8567aa04
---
# Project boundaries - every project is self-contained

`~/ai/<category>/<project-name>/` is the unit. Contains everything the project needs.

- No imports from `~/ai/<other-project>/`. Shared code gets published as a package.
- No hardcoded absolute paths to any `~/ai/` directory. Code runs from a fresh clone.
- Credentials via `.env.1p` with `op://` refs only. No shared credential loaders across projects.
- aimacpro (`~/ai/workspaces/aimacpro/`) is a legacy artifact being decomposed. Do not add to it.
- Every new project: `gh repo create arc-web/<name> --private`, clone into `~/ai/<category>/`, build inside that directory.

**File nesting:** new files go inside the component that owns the logic. Never repo root. Never parent directory. For accounting-swarm, bank_feed code goes in `packages/specialists/bank_feed/`.

**Final decision (2026-04-20):** aimacpro should not exist. `/ai/` is the head directory. Each project directory is self-contained. No different than cloning a GitHub repo locally.

**Why:** aimacpro monorepo caused 1,450+ hardcoded paths, credential leakage, agents that couldn't run outside monorepo, multi-day migrations, 21,000 LOC lost to incorrect archival.

# Search for existing repo before creating

Before `gh repo create`, search the owner org:

```bash
gh search repos --owner arc-web <purpose-keyword>
```

- Local folder names are not repo names. Check `git remote -v`.
- Read sibling repo descriptions - they often name dependencies explicitly.
- Name mismatches are a signal the local folder is out of sync with canonical repo, not a license to create new.

**Why:** Created duplicate repo when `arc-web/arc-browser` already existed - local folder was `ghost-browser` (old MCP name). Wasted work, cleanup required.

# Pre-move checklist (mandatory)

Before moving any directory or file:

1. **Verify destination** - Read destination agent's README. Confirm content belongs there.
2. **Check naming** - Destination dir name must be snake_case.
3. **Search for path references** - grep key locations for old path BEFORE moving.
4. **Move the directory**
5. **Update internal paths** - Fix all references inside moved files.
6. **Update destination README** - Add new content to agent's README/AGENT.md.
7. **Update memory** - If any memory file references old path, update.
8. **Verify** - ls old location (should not exist) and new location (should have contents).

**Why:** Previous session moved 50+ files, 10+ dirs without updating references. 68+ stale paths. README didn't document new content. Naming violations introduced.

# Verify before archive

Before archiving or deleting ANY directory:

- Read main entry point and source files (not just README or listing).
- Count actual LOC excluding READMEs, node_modules, generated files.
- If LOC > 100, read key source files to assess whether code is functional.
- Report findings with LOC counts to user before action.
- NEVER call a directory "empty" or "scaffold" without reading source files.

**Why:** April 2026 ecosystem cleanup - 8 dirs with ~21,000 LOC of real functional code (including 7,486-LOC SaaS platform) were incorrectly archived as "empty scaffolds" because only listings/counts were checked.

# Data is sacred - link, don't delete

Default to PRESERVING data, not deleting. Never propose dropping columns/tables/rows unless user explicitly asked or data is verified empty AND user approved.

- Cleaning up "redundancy" (duplicate columns): MOVE data to canonical column, SOFT-DEPRECATE old one (`_deprecated` suffix). Don't drop in same operation.
- Column "looks empty" or "unused" doesn't justify dropping. User may want it for future data. Default is keep.
- Cleanup requests: lead with what to preserve, link, consolidate. Drops come last with explicit "drop X" instruction.
- "Data linkage problem" = "add foreign keys + indexes + match orphan records", not "delete orphans".
- Contact names ARE valid match data even as text. Don't dismiss as "just strings".

**Why:** User burned twice by Claude dropping columns without permission. Strong negative response each time.

# Use scaffold tool

When creating any agent/app/tool/script directory, use:
`~/ai/agents/development/infrastructure_agent/apps/scaffolding_app/tools/scaffold_tool/scripts/scaffold_ai.sh`
(migrated from legacy `~/aimacpro/4_agents/infrastructure_agent/...` per directory law - aimacpro decomposed, verified 2026-05-01)

Types:
- `--type agent --name NAME` - aimacpro swarm agent
- `--type claude-agent --name NAME` - Claude Code agent (creates `~/ai/agents/<category>/NAME/` with AGENT.md - `~/agents/` prefix retired per directory law, verified 2026-05-01)
- `--type app --name NAME` - standalone app
- `--type script/tool/workflow --name NAME` - utilities

Enforces snake_case. Rejects hyphens, uppercase, spaces.

Before `mkdir`, check if scaffold can create it. If manual needed, follow same structure.

# Plan file naming

Always use descriptive snake_case/kebab-case filename stating what the plan is about. Never random three-word slugs like `mossy-wondering-clarke.md`.

- If plan mode auto-generates a slug name, rename before `ExitPlanMode`. Write to a descriptive filename from the start.
- Legitimate active plans with slug names get renamed to their topic.
- Topic-first: what is the work.
- If plan tool locks filename, `mv` on disk after the fact, note real name in response.
