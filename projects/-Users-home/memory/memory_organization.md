---
name: Memory organization rules
description: How to categorize, file, and maintain memory entries - read this before creating or updating any memory
type: reference
originSessionId: 639a3602-091a-418a-8fa5-c74ed12609c6
---
## Memory file structure

All memory lives in `/Users/home/.claude/projects/-Users-home/memory/`. Index is `MEMORY.md`. Every index entry must link to a real file. No orphaned links.

## Naming convention (NEW - 2026-04-25)

**Format:** `memory_<topic>_<subtopic>_<detail>.md`

- Always start with `memory_` so all files cluster together alphabetically.
- Then the topic - what subject this concerns (`credentials`, `github`, `workflow`, `discord`, etc.).
- Then optional subtopic and detail to disambiguate (`fallback`, `1pass`, `openbao`, `restart`).

Examples:
- `memory_credentials_fallback_1pass.md` - credentials topic, fallback subtopic, 1Password detail
- `memory_credentials_openbao_local.md` - credentials topic, OpenBao subtopic, local-machine detail
- `memory_workflow_no_timelines.md` - workflow topic, no-timelines detail
- `memory_response_format.md` - response format topic, no further disambiguation needed

Type (user/feedback/project/reference) lives in the YAML frontmatter `type:` field, not in the filename. Filename describes the SUBJECT, not the category.

**Migration policy:** Old type-prefixed files (`feedback_*`, `project_*`, `reference_*`, `rules_*`, `user_*`) stay where they are. When a file is touched/edited, rename it to the new pattern in the same edit and update MEMORY.md links. Do not mass-rename - that creates a useless commit and breaks any external references.

## 4-type taxonomy (lives in frontmatter, not filename)

| Type | What belongs here |
|------|-------------------|
| `user` | User's role, expertise, preferences, communication style |
| `feedback` | Corrections, validated approaches, how to work |
| `project` | Ongoing work, goals, stakeholders, current status |
| `reference` | Pointers to external systems, tools, accounts, infrastructure |

## Current consolidated files

| File | What belongs here |
|------|-------------------|
| `rules_response_format.md` | Output format, tone, no em dashes, pasteable output, anti-overengineering |
| `rules_workflow.md` | Work approach: do vs instruct, autonomy, no timelines, verify working dir |
| `rules_api_and_testing.md` | APIs, credentials, LLM keys, subprocess timeouts, testing approach |
| `rules_github.md` | Repos, PRs, scaffolding, pre-move checklist, naming |
| `rules_infrastructure.md` | Servers, DNS, MCP naming, provisioning, LibreOffice |
| `rules_communication.md` | Discord embed limits, workshop guidance |
| `rules_plan_lookup.md` | Check ~/.claude/plans/ before saying no plan exists |
| `feedback_plain_language.md` | No structured recap bullets after tasks |
| `feedback_restart_prompt.md` | Restart prompts must include backstory + action plan |
| `feedback_subprocess_timeout.md` | Always communicate(timeout=N), verify binary first |
| `feedback_testing_prompts.md` | Never generic test prompts; check real projects first |
| `reference_github.md` | arc-web account, gh CLI, BusyBee3333 restriction |
| `reference_infrastructure.md` | VPS Alpha, model config, agents dir, path boundaries |

## Decision tree for filing new memories

- Formatting/output/tone rule? -> `rules_response_format.md`
- Work approach/autonomy/completion? -> `rules_workflow.md`
- API/testing/credentials/LLM keys? -> `rules_api_and_testing.md`
- GitHub/git/PRs/repos/scaffolding? -> `rules_github.md`
- Servers/DNS/deploy/infrastructure? -> `rules_infrastructure.md`
- Communication limits (Discord, workshops)? -> `rules_communication.md`
- Ongoing project (goals, status, stakeholders)? -> `project_*.md`
- User's role, expertise, preferences? -> `user_*.md`
- External tool/service/account pointer? -> `reference_*.md`
- Doesn't fit above? -> New file only if genuinely distinct category

## Rules

1. Check existing files before creating new. Most rules merge into existing files.
2. File by topic, not by conversation origin.
3. Never create a file for a single one-line rule. Merge or inline in MEMORY.md.
4. Every MEMORY.md entry must have a real file on disk. Verify after adding.
5. Keep MEMORY.md concise - one line per entry, no inline content. (50-line limit retired 2026-05-01: index grew to 82 lines as rules system expanded; hard limit was unenforceable, intent preserved as format rule.)
6. Update existing entries, don't duplicate.
7. Prune stale project entries when deadlines pass or work is done.
