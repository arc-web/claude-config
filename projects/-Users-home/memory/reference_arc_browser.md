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

## State (verified 2026-05-20)

- Last push 2026-05-18. Default branch `main`. PUBLIC.
- PR #4 MERGED 2026-05-18 (MCP startup + OAuth handoff fix). PR #5 OPEN (GHL site profile, google_sso, PIT macros, manual-fallback protocol) - GHL tools already in main, PR #5 is documentation/cleanup.
- PR #3 MERGED 2026-05-01: Camofox stealth Firefox sidecar. PR #1 MERGED 2026-04-14: v2 generic primitives.
- 31 MCP tools (was 21 on 2026-05-01; +10 between then and 2026-05-19 main).

## Tool inventory (31 total, verified 2026-05-20)

Generic browser primitives (11): `browser_navigate`, `browser_screenshot`, `browser_snapshot`, `browser_click`, `browser_type`, `browser_evaluate`, `browser_wait`, `browser_analyze_site`, `browser_preflight`, `browser_introspect`, `browser_plan_action`.

Auth + session (4): `browser_auto_login`, `browser_verify_auth`, `browser_task`, `browser_task_confirmed` (CDP-required for LinkedIn/Twitter/Facebook).

Camofox stealth fallback (2): `browser_camofox_health`, `browser_camofox_view`.

Google Cloud OAuth (3): `browser_google_cloud_prepare_oauth`, `browser_google_cloud_status`, `browser_google_cloud_resume`.

Skool (4 - READ/AUTH only, NO post/comment): `skool_auth_refresh`, `skool_verify_session`, `skool_scan`, `skool_onboard`. To post in Skool, drive browser_navigate + browser_click + browser_type manually.

GoHighLevel (6, shipped 2026-05-19): `ghl_auth_refresh`, `ghl_verify_session`, `ghl_create_pit`, `ghl_list_pits`, `ghl_switch_view`, `ghl_switch_subaccount`.

Manual fallback (1): `agentic_browser_send_prompt` - posts to `#agentic-browser` Discord channel, waits for human reply. Use when autonomous flow blocked.

## Defunct skool_agent

`~/ai/agents/.../skool_agent` no longer exists. All Skool functionality absorbed into arc-browser MCP tools above. If user mentions "skool_agent", route to arc-browser.

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
