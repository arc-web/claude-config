# Plan: Centralize + Complete the Plane System

## Context

Plane knowledge is split across `arc-web/plane-pm-agent` (CLI + SOP), `arc-web/claude-skills/plane-pm` (API reference), and 6+ memory files. A full audit found 15 gaps, 7 duplications, and 3 conflicting formats for the handoff prompt alone. The biggest problems:

- clients workspace (5 projects) has zero API documentation anywhere
- `estimate_point`, modules, comments, cycles have no API docs
- 3 different handoff prompt formats produce inconsistent agent output
- `plane mine`, `plane standup`, `--module` flag, and `plane intake` are unbuilt
- `task_intake.py` has no CLI entry point - its functions are stranded

**Goal:** Make `arc-web/plane-pm-agent` the single source of truth. Slim down the skill to execution-only. Strip memory duplication. Ship the 4 missing CLI features.

---

## Phase 1: Fetch live data (pre-work)

Before editing any docs, query the Plane API to get verified UUIDs:

```python
# Fetch clients workspace project UUIDs + state IDs
# GET /workspaces/clients/projects/
# GET /workspaces/clients/projects/<UUID>/states/  (for each)
# GET /workspaces/todovibes/projects/<UUID>/states/ for AGENT (verify all 6 states)
```

Use OpenBao AppRole `claude-code-local` pattern from SKILL.md. Output a verified UUID table before touching any file.

---

## Phase 2: plane-pm-agent repo changes

### 2a. New file: `API.md` (canonical API reference)

Create `/Users/home/ai/agents/projectmanagement/plane_agent/API.md`:

- Base URL + required headers (User-Agent: plane-cli/1.0)
- Both workspace slugs + all project UUIDs (todovibes AND clients) - live-verified
- Complete state ID tables for all projects
- Issue field types table (name, state UUID, description_html, priority, estimate_point UUID, sequence_id read-only, .id = PATCH UUID)
- Endpoints: issues, states, labels, members, cycles, comments, pages, modules
- Module assignment pattern (clients workspace - no CLI support, raw API required)
- PATCH pattern + known gotchas
- Postgres deletion pattern (API 403 on project delete)
- Rate limit behavior (no published limit, 429 backoff)

### 2b. Update `SOP.md`

File: `/Users/home/ai/agents/projectmanagement/plane_agent/SOP.md`

Add to "Hard rules" section:
- Time estimate = human minutes to scope/review, NOT agent wall-clock time
- Attribution format on every comment/update: `— [Agent: model via Claude Code | YYYY-MM-DD]`
- `estimate_point` must be a UUID (fetch from `/projects/<UUID>/estimates/`), never an integer

Add new section "Clients workspace":
- When to use clients vs todovibes workspace
- Module assignment = raw API (no CLI `--module` flag yet, until 2d ships)
- Pointer to API.md for UUIDs

Add to "Agent Intake Prompt" section:
- Canonical format = task_intake.py REQUIRED_SECTIONS (8 fields)
- Supersedes any other format

### 2c. Update `README.md`

File: `/Users/home/ai/agents/projectmanagement/plane_agent/README.md`

Add:
- Troubleshooting section (401 = token expired → `plane refresh --token`, 403 = permissions, 429 = rate limit back off 5s)
- Cache gotcha: 1h TTL can return stale data mid-sprint, force refresh with `plane projects --no-cache`
- Clients workspace usage note

### 2d. CLI additions to `plane` binary

File: `/Users/home/ai/agents/projectmanagement/plane_agent/plane`

**`plane mine`** - filter current project issues by assignee = current user
- Resolve current user via `GET /workspaces/<ws>/members/` (match email from OpenBao or env)
- Default: show In Progress + Todo, current project
- Flags: `--project`, `--state`, `--json`

**`plane standup`** - 24h delta report
- Issues moved to Done in last 24h (Yesterday)
- Issues In Progress now (Today)
- Issues Blocked (Blockers)
- Output: plain text standup format
- Flags: `--project`, `--json`

**`plane new --module <name>`** - module assignment on create
- Resolve module UUID via `GET /projects/<UUID>/modules/`
- Add `module_ids: [<uuid>]` to POST payload
- Required for clients workspace work

**`plane intake <issue-ref>`** - CLI entry for task_intake.py
- Wraps `task_intake.py:refresh_agent_intake_text()` / `format_agent_intake_comment()`
- Fetches current issue body, strips old intake, writes new intake + posts comment
- Flags: `--dry-run` (print without posting), `--json` (structured output)

### 2e. `task_intake.py` - add entry point

File: `/Users/home/ai/agents/projectmanagement/plane_agent/task_intake.py`

Add `if __name__ == "__main__":` block:
- `python3 task_intake.py AGENT-197 --dry-run`
- Uses argparse, calls existing functions
- No new logic, just wires the entry point

---

## Phase 3: claude-skills slim-down

File: `/Users/home/.claude/skills/plane-pm/SKILL.md`

Remove duplicated content now in API.md:
- Full project UUID tables → replace with pointer to plane-pm-agent/API.md
- State ID tables → replace with pointer + keep AGENT states inline (most-used)
- Endpoints table → pointer to API.md

Keep in SKILL.md (execution-critical for agents calling raw API):
- OpenBao key retrieval Python pattern (needed inline, not worth a round-trip)
- Python create/update curl pattern
- Branch name generator
- Linked Task PR body format
- Rate limit retry pattern
- Issue field types table (keep, it's short and directly action-relevant)

---

## Phase 4: Memory file fixes

### `reference_plane_api.md`
- Add missing state IDs (Backlog + Needs Approval) for AGENT project
- Add clients workspace project UUIDs (live-verified)
- Add pointer: "Full API reference: arc-web/plane-pm-agent/API.md"
- Remove duplicated OpenBao key retrieval code (→ just say "see SKILL.md")

### `project_plane_workspaces.md`
- Update with post-JOHAN-deletion state (verified)
- Add clients workspace project UUIDs + module lists (fetched in Phase 1)
- Note: CLI hardcoded to todovibes (--workspace flag not built)

### `project_plane_client_structure.md`
- Add all 5 clients projects + their module UUIDs (not just TheraPPC)

### `feedback_plane_task_fields.md`
- Align handoff format with task_intake.py's 8 REQUIRED_SECTIONS (they diverge today)
- Keep time estimate rule + attribution format rule

---

## Commit strategy

- `plane-pm-agent` changes: one PR (`claude/feat/plane-system-docs-cli-v2`)
  - API.md, SOP.md, README.md, plane CLI, task_intake.py in one branch
  - Plane task: AGENT project, create at start
- `claude-skills` changes: direct to main (docs slim-down = small edit)
- Memory files: local only, no git

---

## Verification

```bash
# CLI new commands
plane mine                           # returns issues assigned to me
plane standup                        # prints yesterday/today/blockers
plane new COMM "test" --module ARC-TheraPPC  # creates in module
plane intake AGENT-197 --dry-run     # prints updated intake

# Clients workspace
python3 -c "... GET /workspaces/clients/projects/ ..."  # returns UUIDs matching API.md

# task_intake.py entry
python3 task_intake.py --help        # shows usage

# Docs
grep -n "clients" ~/ai/agents/projectmanagement/plane_agent/API.md    # has UUID table
grep -n "estimate_point" ~/ai/agents/projectmanagement/plane_agent/SOP.md  # in hard rules
grep -n "plane mine" ~/ai/agents/projectmanagement/plane_agent/README.md   # documented
```

---

## Files touched

| File | Change |
|------|--------|
| `plane_agent/API.md` | CREATE - canonical API reference |
| `plane_agent/SOP.md` | ADD - hard rules, clients workspace section, unified handoff format |
| `plane_agent/README.md` | ADD - troubleshooting, cache gotcha |
| `plane_agent/plane` | ADD - mine, standup, --module, intake commands |
| `plane_agent/task_intake.py` | ADD - __main__ entry point |
| `claude-skills/plane-pm/SKILL.md` | SLIM - remove duplicated UUID/state tables, add pointers |
| `memory/reference_plane_api.md` | FIX - complete state IDs, add clients UUIDs, pointer to API.md |
| `memory/project_plane_workspaces.md` | UPDATE - post-JOHAN state, clients modules |
| `memory/project_plane_client_structure.md` | UPDATE - all 5 clients projects + modules |
| `memory/feedback_plane_task_fields.md` | FIX - align handoff format with task_intake.py |
