# Plan: Skill + Memory Updates - Plane field types & Retroactive PR

## Context

Two operational learnings from the codebase_helper session need to be written into the right places as clear instructions (not error logs). Both will recur:

1. **Plane `estimate_point` is a UUID, not an integer** - the API returns `{"estimate_point":["Invalid pk \"30\" - object does not exist."]}` when you pass an integer. No field types reference exists in either the skill or memory.

2. **Retroactive PR procedure** - when a commit lands on main but a PR was required, the pattern is: branch from current main (retains the change) → revert main → push both → PR → merge. Not documented anywhere. Force-pushing main is explicitly refused in the skill but no recovery path is given.

## Files to edit (4 surgical additions)

### 1. `~/.claude/skills/plane-pm/SKILL.md`

Add new section **"Issue field types"** after the "Endpoints quick reference" table (~line 171).

Content:
```markdown
## Issue field types

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Issue title |
| `state` | UUID string | From `/states/` endpoint - never hardcode |
| `description_html` | string | HTML, use `<p>content</p>` |
| `priority` | string | `none` `urgent` `high` `medium` `low` |
| `estimate_point` | UUID string | NOT an integer - fetch from `/projects/<UUID>/estimates/` |
| `sequence_id` | integer | Display-only (e.g. AGENT-197) - read field only, never use in PATCH |
| `.id` | UUID string | Use this in all PATCH URLs |
```

Also bump `Last updated:` date to 2026-05-18 (already correct per file - verify).

### 2. `~/.claude/skills/github-pr-flow/SKILL.md`

Add new section **"Retroactive PR"** before "Known fragilities" (~line 219).

Content:
```markdown
## Retroactive PR

When a commit is already on main but a PR is required (e.g., you committed directly instead of branching):

```bash
# 1. Branch from current main - this retains the change
git checkout -b <agent>/<type>/<slug>
git push -u origin <agent>/<type>/<slug>

# 2. Revert main
git checkout main
git revert <sha-of-commit> --no-edit
git push

# 3. PR from branch → main
gh pr create --title "..." --body "..."
```

Do NOT force-push main. Do NOT cherry-pick. Branch first, revert second - branch already has the change, main is now clean.
```

### 3. `~/.claude/projects/-Users-home/memory/reference_plane_api.md`

Add **"Issue field types"** section after the PATCH section (~line 84).

Same table as plane-pm/SKILL.md, condensed:
```markdown
## Issue field types

- `state` → UUID string (from `/states/`)
- `estimate_point` → UUID string (from `/projects/<UUID>/estimates/`) - NOT an integer
- `priority` → string: `none` `urgent` `high` `medium` `low`
- `sequence_id` → display-only integer, never use in PATCH URLs
- `.id` → UUID to use in PATCH URLs
```

Bump `Last updated:` / verified date to 2026-05-18.

### 4. `~/.claude/projects/-Users-home/memory/rules_github.md`

Add **"Retroactive PR"** section at end of file.

Content:
```markdown
# Retroactive PR (commit already on main)

When a commit landed on main that should have been a PR:

1. Branch from current main (retains the change): `git checkout -b <branch>`
2. Push branch: `git push -u origin <branch>`
3. Revert main: `git checkout main && git revert <sha> --no-edit && git push`
4. Open PR from branch → main, merge normally

Never force-push main. Never cherry-pick to avoid the revert. Branch first, revert second.
```

## Commit rules

- Skills in `~/.claude/skills/` = symlink to `~/ai/tools/ai/claude-skills/` → commit + push after both skill edits (single commit, both files)
- Memory files = local only, no git needed
- Both skill edits are small → direct to main (no PR required per skill rule)

## Verification

After edits:
- `grep -n "estimate_point" ~/.claude/skills/plane-pm/SKILL.md` → shows UUID row in field types table
- `grep -n "Retroactive" ~/.claude/skills/github-pr-flow/SKILL.md` → shows new section
- `grep -n "estimate_point" ~/.claude/projects/-Users-home/memory/reference_plane_api.md` → shows field type entry
- `grep -n "Retroactive" ~/.claude/projects/-Users-home/memory/rules_github.md` → shows new section
- `cd ~/ai/tools/ai/claude-skills && git log --oneline -3` → shows commit with both skill files
