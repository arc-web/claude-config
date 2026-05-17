---
name: aimacpro repo boundaries (hard rule, 2026-04-14)
description: New standalone tools get their own GitHub repo - never land in aimacpro. 7_tools/packages/ is frozen. Existing tools are extraction targets.
type: project
originSessionId: 87ec28e6-b43a-44b4-a8dc-df3581dd3338
---
**Hard rule landed in PR #24 (2026-04-14):** New standalone tools do NOT go into the aimacpro repo. They get their own GitHub repo from day one.

**aimacpro is for:**
- Agent-swarm orchestration
- aimacpro-specific glue/config
- Genuinely shared internal infrastructure (credentials loader, naming validator, project-wide scripts)

**Own repo is for:**
- CLIs, scanners, installable libraries, shippable products
- Anything with its own users, versioning needs, or could plausibly be shared/open-sourced

**Decision rule:** if in doubt, make it its own repo. Extraction later is expensive; starting separate is free.

**`7_tools/packages/` is retired** - subdirectory no longer exists in `~/ai/workspaces/aimacpro/7_tools/` (verified 2026-05-01). Rule intent preserved: no new tools land in aimacpro.

**Why this exists:** PR #23 tried to land a 48-file `wp_security_scanner` into `7_tools/packages/`. That tool has its own users, its own versioning needs, and should be installable/contributable in isolation. Compounding failures: hardcoded credentials, directory-rule drift, tools teammates couldn't install/contribute to in isolation.

**Rule clarification (2026-04-14):** Agents also get their own repos when they have identity beyond a 4-file config stub. Default is: if in doubt, own repo.

**Existing extraction backlog (do progressively, do not add to):**
- ✅ `6_apps/supabase_app/` → `arc-web/supabase_mcp` (DONE; repo renamed from `supabase_app` to `supabase_mcp` post-extraction - verified 2026-05-01; source gone from `6_apps/`)
- ✅ `4_agents/server_supabase_v2_agent/` → `arc-web/supabase_agent` (DONE; actual aimacpro source path was `server_supabase_v2_agent` not `supabase_agent` - verified 2026-05-01)
- `7_tools/packages/` retired - no longer exists as a path

**How to scaffold a new tool the right way:**
```
gh repo create arc-web/<name> --private
# develop in that repo, install/run independently
```

The `team-repo` CLI exists for managing these. Use it.

**Successful extraction precedents:**
- `wp_security_scanner` → `arc-web/wp-security-scanner` (private repo - verified EXISTS via gh CLI 2026-05-01; clone + `pip install -e .` + `pytest` works on clean checkout)
- `supabase_app` → `arc-web/supabase_mcp` (repo renamed post-extraction; verified EXISTS via gh CLI 2026-05-01; clone + `pnpm install && pnpm build` → `dist/mcp/server.js --version` prints 0.1.0)

**Extraction recipe (proven twice, use as template):**
1. `gh repo create arc-web/<name> --private --gitignore Node` (or language-appropriate)
2. `git clone` the new empty repo to `/tmp/<name>_extract`
3. `cp -R aimacpro/<path>/. /tmp/<name>_extract/` (include dotfiles)
4. Rename package `@aimacpro/<name>` → `<name>` (no scope for private)
5. Add `LICENSE` + `NOTICE` (preserve upstream attribution if vendored)
6. Rewrite internal docs to reference clone-local paths, not aimacpro paths
7. `git add . && git commit -m "feat: initial import from aimacpro/<path>" && git push`
8. Clean-clone to `/tmp/<name>_verify`, run build + tests, fix any config lag
9. On aimacpro: `git rm -rf <path>` + update docs that point at it + open PR
10. Update this memory file to mark extraction done

**Reference docs in repo:** see `CLAUDE.md` "Repository Boundaries (hard rule)" section.
