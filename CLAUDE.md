# Global Instructions

Backup at `~/.claude/CLAUDE.md.lean-ctx.bak`.

@~/.claude/projects/-Users-home/memory/MEMORY.md

@~/.claude/audit_directive.md

## Always-on rules

No skill override. All convos.

- **End-of-turn structure (temp 0.0).** Every response ends: `Done: / Open: / Recommend:`. If nothing left, say "done" and stop. No trailing questions. Recommend is a statement not a request. See `feedback_end_of_turn_structure.md`.
- **No em dashes** (U+2014). Use `-` everywhere.
- **Response format**: plain-English lead sentence, then bullets (where / what / why / what not done). No paragraphs for 2+ items. See `rules_response_format` in memory.
- **User is not a developer.** Plain English. Full technical detail, no buzzwords.
- **Last-updated stamps**: any file with `Last updated: YYYY-MM-DD` - bump to current date in same edit. Not optional.
- **Directory law**: `~/ai/<project>/` is the unit. Self-contained GitHub repo. No shared dirs. No monorepo. aimacpro is legacy being decomposed.
- **Never duplicate to move.** Use `git mv` to relocate files. Preserve git history. No copy-then-delete ever.
- **One-shot default.** Minimum steps. No scaffolding, no future-proofing, no helper abstractions unless explicitly asked.
- **Git history is sacred.** Never suggest deleting + re-adding files. If history is messy, ask before any rewrite.
- **Research named terms first.** User mentions a product, feature, tool, or term not 100% sure of - WebSearch before answering. No guessing on factual product questions. See `feedback_research_named_terms.md`.
- **Plan files: rename slug immediately.** Plan-mode pre-fills a path like `toasty-zooming-duckling.md`. Treat as placeholder, not directive. Write/mv to descriptive snake_case name (`openbao_diag_oneshot.md`). Never end a turn with a slug-named plan on disk. See `feedback_plan_naming.md`.
- **/plan = stop after ExitPlanMode.** Wait for explicit user "go" before any build. Auto-mode reminder firing post-plan is harness state, not user consent. See `feedback_plan_mode_approval.md`.
- **Plane tasks: always create + update.** Every meaningful unit of work (feature, fix, deploy, migration, audit) needs a Plane task. Create at start if none exists, update to Done on finish. AGENT project (ID: 0e399778-93d9-4a95-ba2f-755990dd69bc), workspace: todovibes. Applies to Claude Code, Codex, ZeroClaw, all agents. See `feedback_plane_task_always.md`.
- **Plane tasks: all fields + Agent Intake Prompt + attribution.** Every task must have all fields populated (name, state, description, module, time estimate). Description must include the current Agent Intake Prompt from `/Users/home/ai/agents/projectmanagement/plane_agent/task_intake.py` so any agent or human can pick up mid-task. Every normal create, move, close, comment, tree create, or intake update must preserve the prompt in `description_html`; `--no-intake` is only for emergency operator comments and the next normal update must repair it. Use `plane intake-audit --workspace <slug> --open-only --json` for read-only checks and `plane intake-backfill --workspace <slug> --open-only --dry-run --ledger <path>` before any live backfill apply. Every comment or update must end with attribution: `— [Agent: claude-sonnet-4-6 via Claude Code | YYYY-MM-DD]` or `— [Human: name | YYYY-MM-DD]`. If a task is missing its handoff prompt, analyze and add it. See `feedback_plane_task_fields.md`.
- **Skill edits auto-commit.** `~/.claude/skills/` is a symlink to `~/ai/tools/ai/claude-skills/` (arc-web/claude-skills). Any time a skill file is created or edited: `cd ~/ai/tools/ai/claude-skills && git add <file> && git commit -m "..." && git push`. Do this without being asked. Small edits go direct to main. Structural changes (new skill, major rewrite) get a branch + PR. Never leave skill edits uncommitted.

## Domain rules - read the corresponding file when the task matches

CLAUDE.md stays small. Task matches domain - Read target file once at start.

| When doing... | Read this |
|--------------|-----------|
| Credentials work (1P, Infisical, OpenBao, SSH keys, API tokens) | `~/.claude/skills/credentials/SKILL.md` |
| Deep linking / navigating the user to a URL | `~/.claude/skills/deep-link/SKILL.md` |
| New agent/app/tool scaffolding | `~/.claude/skills/scaffold-rule/SKILL.md` |
| Meaningful dev work (build, fix, refactor, deploy, ship, PR, merge, new repo) | `~/.claude/skills/agentic-dev-plan/SKILL.md` |
| API integration (new client, new MCP, new workflow) | `~/.claude/skills/api-integration/SKILL.md` |
| GitHub PR creation, branch strategy, commit trailers | `~/.claude/skills/github-pr-flow/SKILL.md` |
| GitHub repo discovery (is it public, where does it live) | `~/.claude/skills/gh-find/SKILL.md` |
| WordPress performance audit | `~/.claude/skills/wp-performance-review/SKILL.md` |
| WordPress security scan | `~/.claude/skills/wp-security/SKILL.md` |
| Skool group audit | `~/.claude/skills/skool-scan/SKILL.md` |
| Landing page UI/UX review | `~/.claude/skills/page-review/SKILL.md` |
| Any work on a client site (Cloudflare R2): building, updating, deploying, fixing palette/tokens/forms/CTA/analytics/workers, reviewing pages, CRO changes | `~/.claude/skills/web-workflow/SKILL.md` |
| Generate presentation deck | `~/.claude/skills/deck/SKILL.md` |
| Client intake (agency Phase 1) | `~/.claude/skills/agency-intake/SKILL.md` |
| Fathom meetings (transcripts, summaries) | `~/.claude/skills/fathom/SKILL.md` |
| Supabase SQL, client table, relationship model | `~/.claude/skills/supabase/SKILL.md` |
| Ad audits, creative generation, campaign planning | `~/.claude/skills/ads/ads/SKILL.md` |
| Plane task operations (create, update, query via API) | `~/.claude/skills/plane-pm/SKILL.md` |
| Plane swarm program (build a multi-agent task tree from a plan) | `~/.claude/skills/swarm-program/SKILL.md` |

Read matching memory rule file when behavior-specific:
- `rules_workflow.md` - approach/autonomy/completion
- `rules_api_and_testing.md` - API/testing/credential/LLM-key
- `rules_github.md` - repo/move/archive/scaffolding
- `rules_infrastructure.md` - deploy/DNS/subdomain/MCP-naming
- `rules_response_format.md` - default response shape (auto-applied)
- `rules_communication.md` - Discord embeds, workshop attendees

## Document creation (inline - no skill)

Design-first. HTML/CSS inline styles first, then convert.

- `.docx/.odt`: `pandoc input.html -o output.docx`
- `.pptx`: use pptx skill or pptxgenjs from HTML
- `.xlsx`: skip HTML, use ExcelJS direct
- `.pdf`: browser print or `soffice --headless --convert-to pdf`

Target: LibreOffice. Never assume MS Office, Numbers, Pages, Keynote.

## lean-ctx MCP (always-on via hooks)

Prefer lean-ctx over native for token savings. Exception: use native `Read` before `Edit/Write` - Edit requires it, `ctx_read` does not satisfy tracking.

| PREFER | OVER |
|--------|------|
| `ctx_read(path)` | `Read` / `cat` / `head` / `tail` |
| `ctx_shell(command)` | `Shell` / `bash` |
| `ctx_search(pattern, path)` | `Grep` / `rg` |
| `ctx_tree(path, depth)` | `ls` / `find` |

Write, Delete, Glob: use normally. Never loop on Edit failures - switch to `ctx_edit` immediately.

## Plugin / MCP defaults

- Only `composure` plugin enabled (required by `/github-pr-flow`). Others disabled. Enable per-task: `claude plugin enable <name>@my-claude-plugins`.
- `lean-ctx` MCP stays on. Other MCPs load on demand.
- Task needs `design-forge`, `sentinel`, `shipyard`, `testbench`, or cloud MCP: enable, do work, disable.

## When things feel off

Underperforming or slow - say so and say why. Check: plugin hook noise, silent MCP failures, competing plugin instructions. Flag env issues, don't apologize.

# lean-ctx — Context Engineering Layer
<!-- lean-ctx-rules-v8 -->

CRITICAL: ALWAYS use lean-ctx MCP tools. NOT optional.

| ALWAYS USE | NEVER USE | Why |
|------------|-----------|-----|
| `ctx_read(path)` | `Read` / `cat` / `head` / `tail` | Cached, 8 compression modes, re-reads ~13 tokens |
| `ctx_shell(command)` | `Shell` / `bash` / terminal | Pattern compression for git/npm/cargo output |
| `ctx_search(pattern, path)` | `Grep` / `rg` | Compact, token-efficient results |
| `ctx_tree(path, depth)` | `ls` / `find` | Compact directory maps |

`ctx_read` replaces READ only. Native Edit/Write/StrReplace unchanged. "Use Edit or Write only" rules compatible - lean-ctx only changes reads, not edits.

Edit needs native Read and Read unavailable - use `ctx_edit(path, old_string, new_string)`.
Write, Delete, Glob - use normally. NEVER loop on Edit failures - switch to `ctx_edit` immediately.
<!-- /lean-ctx -->

<!-- lean-ctx -->
<!-- lean-ctx-claude-v2 -->
## lean-ctx — Context Runtime

Always prefer lean-ctx MCP tools over native equivalents:
- `ctx_read` instead of `Read` / `cat` (cached, 10 modes, re-reads ~13 tokens)
- `ctx_shell` instead of `bash` / `Shell` (90+ compression patterns)
- `ctx_search` instead of `Grep` / `rg` (compact results)
- `ctx_tree` instead of `ls` / `find` (compact directory maps)
- Native Edit/StrReplace stay unchanged. If Edit requires Read and Read is unavailable, use `ctx_edit(path, old_string, new_string)` instead.
- Write, Delete, Glob — use normally.

Full rules: @rules/lean-ctx.md

Verify setup: run `/mcp` to check lean-ctx is connected, `/memory` to confirm this file loaded.
<!-- /lean-ctx -->

@RTK.md
