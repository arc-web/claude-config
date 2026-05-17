---
name: GitHub account, CLI, discovery, workflow, restrictions
description: arc-web personal account (not an org), gh CLI fallback, /gh-find for discovery, push/PR workflow, NEVER interact with BusyBee3333
type: reference
originSessionId: 0630a014-b62e-4ae2-a50d-a08a87e6044f
---
## Account

- GitHub account: **arc-web** — this is a **personal account, NOT an organization**. `gh api user/orgs` returns empty.
- All repos are under `arc-web`
- Primary repo: `arc-web/portfolio` (renamed from arc-web/arc-web - verified 2026-05-01)

## Discovery — invoke `/gh-find`

**Never** conclude "repo doesn't exist" after one failed `gh repo view`. Always run the `/gh-find` skill (`~/.claude/skills/gh-find/SKILL.md`), which:

1. Direct lookup under each account
2. List-match by name AND description
3. Global GitHub search (includes forks/archived)
4. Local filesystem cross-reference (`~/ai/agents/`, `~/ai/tools/`, `~/ai/workspaces/aimacpro/4_agents`, `~/ai/workspaces/aimacpro/7_tools`) + git remote inspection
5. Related-name fallback (`-mcp`, `-agent`, `-deployment`, `-server`, `-toolkit`)
6. Synthesized report

### Code-lives-in-parent pattern

Some projects live on disk as a subdirectory tracked inside a larger repo — the git remote of the local dir won't match the dir name. Always `cd <dir> && git remote -v` when you find a local match.

### Known aliases

| Query | Result |
|-------|--------|
| `ghost-browser` / `arc-browser` | `~/ai/tools/browser/arc-browser/` -> `arc-web/arc-browser`. "ghost-browser" was the old MCP name, now renamed to arc-browser |
| `hermes-agent` | no dedicated repo; deployment docs at `arc-web/hermes-deployment` |
| `github_agent` / `github-agent` | local `~/ai/agents/development/github_agent/` (migrated from aimacpro per directory law - verified 2026-05-01; sync/security router, not discovery) |

## CLI fallback

When GitHub MCP tools (`mcp__plugin_github_github__*`) fail with "invalid session" or any connection error, immediately fall back to the `gh` CLI:
- Use `/opt/homebrew/bin/gh` or `unalias gh 2>/dev/null; /opt/homebrew/bin/gh` (lean-ctx aliases can interfere)
- Never tell the user GitHub is unavailable — just use the fallback
- Applies to ALL GitHub operations: repos, PRs, issues, search, auth

## Push/PR workflow

- Can push and create PRs without asking for permission
- Always verify remote is `arc-web` before any push

## CRITICAL restriction

**NEVER interact with BusyBee3333.** Never push to, pull from, or reference BusyBee3333 repos. All repos are `arc-web`. Verify the remote before any push operation.
