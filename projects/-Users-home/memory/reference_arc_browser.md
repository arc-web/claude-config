---
name: ARC Browser - consolidated browser automation
description: arc-browser is the single repo for ALL browser automation (generic + Skool). Public on GitHub. Formerly called ghost-browser in MCP config.
type: reference
originSessionId: e07aa1d2-0550-414d-b021-83d1aeb9f1b1
---
## ARC Browser

- **Repo**: `arc-web/arc-browser` (PUBLIC, default branch `main`)
- **Local**: `/Users/home/ai/tools/browser/arc-browser/`
- **MCP name**: `arc-browser` (was `ghost-browser` before 2026-04-19 rename)
- **Server**: `python3 /Users/home/ai/tools/browser/arc-browser/arc_browser/server.py`

## State (verified 2026-05-01)

- PR #3 merged: Camofox stealth Firefox sidecar integration. PR #2 CLOSED ("chore: remove stale google_ads docs moved to ppc vertical" - verified 2026-05-01; no open PRs).
- Latest main HEAD includes `arc_browser/camofox.py` + 2 new MCP tools (`browser_camofox_health`, `browser_camofox_view`).
- 21 MCP tools (server.py @mcp.tool decorators): autonomous + primitive + auth + Skool + Camofox.

## Tree

- `arc_browser/` - MCP server. Modules: `server.py`, `agent.py`, `browser.py`, `router.py`, `site_analyzer.py`, `flaresolverr.py`, `cf_recovery.py`, `camofox.py`, `config/`, `utils/`.
- `skool/` - Skool scanner, 21-feature gap analysis, HTML report generator.
- `scripts/` - CLI tools (collect, onboard, interpret, deliver, run_scan).
- `browser/` - Skool-tuned browser primitives (used by scripts/).
- `playwright/` - Legacy TypeScript Playwright MCP (reference only).
- `app_integrations/` - Provider-specific browser recipes.
- Root: `README.md`, `PRIMITIVES.md`, `requirements.txt`, `.env.example`, `docs/`, `examples/`, `templates/`.

## Cloudflare integration note

`reference_flaresolverr.md` previously said FlareSolverr was rejected for arc-browser. SUPERSEDED: `arc_browser/flaresolverr.py` + `cf_recovery.py` now exist (commit bf3f53e). FlareSolverr was integrated.

## Camofox sidecar (added PR #3, 2026-05-01)

- Stealth Firefox alternative when Patchright Chromium fingerprint is detected (Turnstile, Datadome, PerimeterX).
- Sidecar repo: `arc-web/camofox-browser` (fork of `jo-inc/camofox-browser`), local at `~/ai/tools/browser/camofox-browser/`.
- Run sidecar: `cd ~/ai/tools/browser/camofox-browser && PORT=9377 node server.js &`. REST API on `:9377`.
- Client: `arc_browser/camofox.py`. Env: `CAMOFOX_URL` (default `http://127.0.0.1:9377`), optional `CAMOFOX_ACCESS_KEY` bearer.
- MCP tools: `browser_camofox_health`, `browser_camofox_view(url, session)` -> accessibility snapshot.
- NOT YET wired: router auto-escalation, browser-use Firefox integration, VPS deploy.

## Ghost-browser footnote

User says "ghost-browser" -> means `arc-browser`. Old MCP registration name pre-consolidation.

## Consolidated from

- `arc-web/skool-manager` - Skool scanner/reports.
- `arc-web/browser-automation` - Legacy Playwright MCP.
- Original `arc-web/arc-browser` - Generic stealth browser MCP.
