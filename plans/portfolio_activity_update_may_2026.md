# Portfolio + Activity Update - May 2026

## Context

`arc-web/portfolio` README "Current Focus" frozen at March 2026. `arc-web/activity` feed last entry = `2026/03-march`. Since then user pushed to 18+ repos (April 28 - May 13), totaling part of 692 contributions. Public-facing repos look dormant. Goal: add April + May entries to activity feed, refresh portfolio "Current Focus" + weekly-update pointer, match existing tone/format. No restructuring - drop into existing slots.

## Existing style (must match)

**Activity month entry** (`2026/03-march/README.md`):
- H1 month name. 2-3 sentence opener framing the month.
- `## Public Projects Shipped` - one bold project name, 2-4 sentence punchy description per project. No bullets within entry.
- `## Private Projects Advanced` - same format, `(private)` suffix.
- Closing italic note for context anomalies if any.
- Top-level `README.md` "Current Focus" + Archive list updated to point at new months.

**Portfolio README** (`arc-web/portfolio/README.md`):
- Markdown badges, emoji headers, table-of-contents-ish layout. "What I Build / Current Focus" sections updated, not restructured.

## What changed since March 2026 (raw inputs for entries)

Pulled from `gh repo list arc-web` push dates + memory.

**Public (April 28 - May 13)**
- `arcbao` - OpenBao Agent sidecar proxy pattern for AI agent containers. Live secret fetching mid-session.
- `arc-tables` - Interactive HTML schema diagrams + plain-English DB audits. Single file, zero config.
- `advertising-report-card` - Moonraker client proposal repo.
- `review-workflows` - Reusable GitHub Actions for AI review + Semgrep.
- `pr-agent-settings` - Org-wide PR-Agent config for AI code review.
- `arc-browser` - Stealth browser automation MCP. FlareSolverr integration + cf_recovery shipped 2026-05-01 (commit bf3f53e). 21 tools, public.
- `camofox-browser` - Stealth headless Firefox for AI agents, bypass Cloudflare/bot detection. Drop-in Puppeteer/Playwright replacement.
- `discord-agent` - Discord CLI + API client + Charlie bot integration for ARC channel reads.
- `google-ads-agent` - Google Ads campaign management agent (THHL search rebuild work driving development).

**Private (April 28 - May 13)**
- `cloudflare_agent` - cf-deploy CLI for R2 static site lifecycle (deploy/update/teardown).
- `reportcard-agent` - Automated report generation + quality grading engine.
- `skill-systematic-debugging`, `skill-find-skills` - Guarded Skills.sh intake + audit + smoke-test packages.
- `therappc-site` - Client site repo, extracted from `cloudflare_agent` 2026-05-13. R2-deployed static.
- `google-oauth-setup` - One-shot Google OAuth CLI working with OpenBao + 1Password for any Google account.
- `todovibes` - AI + human project management infra (Plane-based).
- `arc-scripts` - Infrastructure scripts + shared utilities (gmail_mgmt CLI lives here).
- `claude-skills` - Live home for `~/.claude/skills/` (symlinked).
- `fathom_agent` - Fathom.video meeting integration + automation.

## Implementation

### File 1 - create `2026/04-april/README.md`

Two-paragraph opener: April was infra-and-glue month. Browser stealth stack went public (arc-browser + camofox-browser companion). OpenBao sidecar pattern (`arcbao`) extracted. Review automation org-wide (`review-workflows` + `pr-agent-settings`). Schema audit tool (`arc-tables`) shipped.

Public projects section: arc-browser, camofox-browser, arcbao, arc-tables, review-workflows, pr-agent-settings, advertising-report-card.

Private projects section: arc-ecosystem-vps, n8n-data-stored (migration backup 2026-04-27).

### File 2 - create `2026/05-may/README.md`

Opener: May = client delivery + skills infra. cf-deploy CLI + client site extraction (`therappc-site`). Discord stack matured (Charlie bot, channel reads). Google Ads agent active build (THHL rebuild). Skills moved into version-controlled repos (claude-skills, skill-find-skills, skill-systematic-debugging). Google OAuth one-shot CLI.

Public projects section: discord-agent, google-ads-agent, arc-browser FlareSolverr integration (note: continuing from April).

Private projects section: cloudflare_agent, therappc-site, reportcard-agent, google-oauth-setup, todovibes, arc-scripts, claude-skills, skill-find-skills, skill-systematic-debugging, fathom_agent.

Note may end with italic line: month in progress, entry covers through May 13.

### File 3 - edit `README.md` (activity root)

Update three blocks:
1. `## Current Focus (March 2026)` -> `## Current Focus (May 2026)`. Replace bullet list with 6-8 new highlights pulled from April+May (arc-browser stealth stack, cf-deploy + R2 sites, OpenBao sidecar `arcbao`, Discord agent w/ Charlie, Google Ads agent THHL build, skill repos extraction, schema audit `arc-tables`, review automation `review-workflows`/`pr-agent-settings`).
2. Archive list - insert `[May 2026]` and `[April 2026]` lines above March 2026.
3. Leave "What We Build" categories intact (still accurate).

### File 4 - edit `arc-web/portfolio/README.md`

Two surgical edits:
1. `## 🚀 Current Focus` block - replace 4 bullets with current state: stealth browser automation (arc-browser/camofox public), Google Ads campaign management agent, Cloudflare R2 client delivery pipeline, OpenBao-backed credential infrastructure, AI-review automation across org repos.
2. `Tech stack:` line - add Rust (lean-ctx + camofox), Cloudflare R2/Workers, OpenBao, Plane.
3. Leave ADVERTISING-REPORT-CARD.md + STACKPACK.md as-is (no changes requested).

## Critical files

- `/Users/home/ai/...nothing local` - both repos cloud-only, work via `gh api` PATCH/PUT or clone-edit-push.
- Editing approach: clone both to `/tmp/portfolio` and `/tmp/activity`, edit with native Edit, `git commit` + `git push` via `gh` auth. Branch direct to main (small content edits, public-facing, no PR ceremony).

## Verification

After push:
- `gh api repos/arc-web/activity/contents/2026/04-april/README.md` returns 200.
- `gh api repos/arc-web/activity/contents/2026/05-may/README.md` returns 200.
- View https://github.com/arc-web/activity in browser - Current Focus shows May 2026, archive shows April + May entries.
- View https://github.com/arc-web/portfolio - Current Focus reflects May work.
- Optional: rebuild GitHub Pages presentation (`arc-web.github.io/portfolio/` + `arc-web.github.io/activity/`) only if it auto-reads from README; otherwise leave.

## Out of scope

- No restructuring of either repo (folder layouts intact).
- No weekly-update files in `TEMPLATE-WEEKLY-UPDATE.md` style - format unused for any prior month, skip.
- No edits to ADVERTISING-REPORT-CARD.md, STACKPACK.md, presentation HTML.
- No GitHub Pages rebuild unless verification shows stale page.
