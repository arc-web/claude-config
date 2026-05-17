---
name: supabase ecosystem - app + agent repos
description: arc-web/supabase_mcp (MCP server) and arc-web/supabase_agent (agent config) - where they live, what's built, what's next
type: project
originSessionId: 87ec28e6-b43a-44b4-a8dc-df3581dd3338
---
## Two repos

**arc-web/supabase_mcp** (private) — MCP server (fork of @supabase/mcp-server-supabase, Apache-2.0)
**arc-web/supabase_agent** (private) — thin agent config that consumes supabase_mcp via MCP

Neither lives in aimacpro. Both are standalone repos per the repo-boundaries rule.

---

## arc-web/supabase_mcp

**Current state:**
- Local clone: `~/ai/platforms/supabase_mcp` (canonical). `/tmp/supabase_mcp` gone (verified 2026-05-01).
- `pnpm install && pnpm build` produces `dist/mcp/server.js` (built and present in `~/ai/platforms/supabase_mcp/dist/mcp/`)
- `node dist/mcp/server.js --version` prints `0.1.0`
- 48 unit tests passing (8/13 test files pass; 5 integration files blocked on missing deps - verified 2026-05-01)

**Merged PRs (all landed in main, verified 2026-05-01):**
- PR #1 `claude/feat/credential-layer` — `src/credentials/one_password.ts`: env var fast path → `op read op://ARC/Supabase Management API Token/credential`, in-process cache, `clearTokenCache()` for tests
- PR #2 `claude/feat/safety-layer` — `src/safety/`: SafetyLevel types, DEFAULT_SAFETY_CONFIG (all 31 original + 11 new tools), `applySafety()` wraps execute with confirmation gate, `mergeWithDefaults()` only-tighten rule
- PR #3 `claude/feat/access-layer` — `src/access/`: api.ts (re-export), cli.ts (subprocess, lazy env), ssh.ts (typed stub), router.ts
- PR #4 `claude/feat/new-tool-groups` — rls_tools (6) + schema_tools (5) added as `rls` and `schema` feature groups
- PR #5 `fix: rename supabase_app → supabase_mcp throughout`

**Tool groups (live):** docs, account, database, debug, development, functions, branching, storage, knowledge, rls (new), schema (new)

**Known test-suite gap:** `@electric-sql/pglite`, `date-fns`, `nanoid`, `prettier` still missing; blocks full vitest suite. `@ai-sdk/anthropic`, `ai`, `common-tags` were added in PR #1.

**Planned follow-ups:**
- Restore remaining test dev deps and get full suite green
- End-to-end smoke test against real ARC Supabase project (gates archiving original fallback agent)
- SSH adapter implementation (src/access/ssh.ts stub, needs `ssh2` npm package)
- ✅ `aimacpro/4_agents/platform_agents/supabase_agent/` ARCHIVED - path gone (verified 2026-05-01)

**Credential setup:** `SUPABASE_ACCESS_TOKEN=op://ARC/Supabase Management API Token/credential`

---

## arc-web/supabase_agent

**Current state (2026-04-14):**
- Initial import committed to main
- 4 files: agent.md, capabilities.json, safety.json, README.md + empty personas/

**capabilities.json:** `${HOME}/ai/platforms/supabase_mcp/dist/mcp/server.js` (path was stale `~/repos/...`; patched during audit 2026-05-01), lists all 42 tools

**Safety overrides:** apply_migration, execute_sql, merge_branch, deploy_edge_function, enable_rls, create_rls_policy, create_schema → confirm_destructive; delete_branch, reset_branch, disable_rls, drop_rls_policy → explicit_only

**Launch pattern:**
```
op run --env-file=.env.1p -- node ~/ai/platforms/supabase_mcp/dist/mcp/server.js
```
With `.env.1p`: `SUPABASE_ACCESS_TOKEN=op://ARC/Supabase Management API Token/credential`
