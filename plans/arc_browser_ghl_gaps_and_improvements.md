# arc-browser GHL Friction Audit + Improvement Plan

## Context

While executing the StackPack GHL auth plan (`ghl_full_access_auth_architecture.md`), arc-browser failed to autonomously create the agency PIT. The plan assumed arc-browser could "drive all GHL clicks" with the same fluency as Skool. Reality: it can drive a basic Skool flow because Skool has a registered recipe, but GHL has nothing - no site registry entry, no auto-login recipe, no dedicated tool surface, and several underlying tools (snapshot, persistent session lifecycle) are broken or under-built.

This plan does three things:
1. Inventory every error + friction point from this session against arc-browser
2. Map each to the underlying capability gap
3. Stage Plane tasks under a new "arc-browser hardening" track so the GHL flow (and every future SaaS-UI driving job) becomes scriptable instead of human-driven

## Error timeline (this session, 2026-05-18 → 19)

| # | Symptom | Tool / command | Root cause |
|---|---------|---------------|------------|
| 1 | First bootstrap script exited 12s into `asyncio.sleep(900)` | `arc_ghl_bootstrap.py` background task | stdio MCP client doesn't keep browser context alive across script lifecycle; browser closes when Python process exits |
| 2 | Login appeared to succeed (profile dir written 02:04 → 02:19) but next probe showed sign-in page | `browser_navigate` from new script | Session profile persists on disk, but live browser is killed; each script spawns a fresh patchright context that may invalidate session cookies if anti-detection patches reset them |
| 3 | `'Page' object has no attribute 'accessibility'` | `browser_snapshot` | Patchright dropped the `accessibility` namespace; `browser_snapshot` uses `page.accessibility.snapshot()` (server.py) - the API changed under it |
| 4 | "No browser context open for session 'ghl'. Call get_context() first." | `browser_evaluate` on new script | Tools call `current_page()` which assumes session active; doesn't auto-spin a context |
| 5 | `/v2/settings/private-integrations` returned empty body + title "Advertising Report Card" (sub-account context, not agency) | `browser_navigate` | GHL SPA loads slowly + iframe-nested settings; URL routes to last-active context not agency; no wait-for-hydration helper |
| 6 | No GHL entry in `site_registry.json` | router.py | Registry has 6 sites (linkedin, twitter, x, facebook, skool, github). No `app.gohighlevel.com` recipe. `browser_auto_login("app.gohighlevel.com")` returns "No auth recipe" |
| 7 | "Sub-Account" hardcoded sidebar nav unreachable by URL alone (SPA route guards) | navigation | GHL settings require clicking through left-rail; deep links don't always work because route guards check active company/location |
| 8 | No PIT-create macro - the whole PIT-creation flow is 5+ UI steps that this session's user (the planning agent) executed conceptually but arc-browser cannot execute as one call | none | No GHL-specific tool surface (Skool has dedicated `skool_auth_refresh / skool_verify_session / skool_scan / skool_onboard` - GHL has nothing) |
| 9 | No "select all scopes" automation for PIT scope picker | none | GHL scope picker is 100+ checkboxes; arc-browser has no helper to iterate a checkbox list and tick all |
| 10 | No PIT token-modal scraper | none | PIT token shown once in a modal; closing modal destroys token; arc-browser has no helper to detect "modal appeared" + extract specific text before close |

## Underlying capability gaps

Mapped from the errors above, grouped by improvement type:

### A) Broken / regressed tools
- **A1** `browser_snapshot` - patchright API mismatch. Either re-implement using `page.evaluate('document.body.outerHTML')` + DOM-to-AX-tree on the Python side, or pin patchright version, or use alternate snapshot path
- **A2** `browser_evaluate` on stale session - should auto-spin context instead of erroring

### B) Persistent session lifecycle
- **B1** **arc-browser daemon mode** - one long-running MCP server with a persistent browser pool, not per-script. Currently every `python -m arc_browser.server` invocation is a fresh process + fresh browser. Daemon would let multiple Claude Code turns share one warm browser. (User-level launchd service: `com.arc.arc-browser-daemon`)
- **B2** **Session state query tool** - `browser_session_status(session_id)` returns `{authenticated: bool, current_url: str, cookies_age_s: int, browser_alive: bool}` without opening a new browser
- **B3** **Cookie-jar export/import** - persist cookies separately from Chrome profile dir so they survive patchright-version churn

### C) Site registry + auto-login coverage
- **C1** Add GHL entry to `site_registry.json` with: login URL, Google SSO toggle, verify URL (agency dashboard), risk profile, rate limit, post-nav settle ms, iframe-aware nav notes
- **C2** Add a `auth.flow: "google_sso"` recipe type (existing recipes only handle form-based email+password). Google SSO needs: click "Sign in with Google" button, handle account-picker, handle 2FA prompt with human pause
- **C3** Build dedicated GHL tool surface mirroring the Skool pattern:
  - `ghl_auth_refresh(force=False)` - login + verify
  - `ghl_verify_session()` - bool auth state
  - `ghl_switch_view(view="agency")` - flip between agency and sub-account context
  - `ghl_switch_subaccount(location_id)` - direct context switch
  - `ghl_create_pit(level, name, scopes=["all"])` - macro that drives the 5-step PIT create flow, captures token from modal, returns it
  - `ghl_list_pits(level)` - read displayed PIT list from settings page (count, names, ages)
  - `ghl_revoke_pit(name)` - delete PIT
  - `ghl_list_subaccounts()` - prefer API over UI scrape if PIT exists; UI fallback
  - `ghl_connect_social_account(location_id, provider="facebook")` - drive Social Planner connect flow with Lead Connector OAuth handshake

### D) UI macro primitives (cross-site, reusable)
- **D1** `wait_for_hydration(session, max_ms=8000)` - polls for SPA-ready signals (no in-flight XHR, React commit cycle done, body has text). Today's evaluate calls fire too early
- **D2** `iframe_focus(session, selector)` - focus an iframe by selector + run subsequent evaluates inside it (GHL nests settings in iframes)
- **D3** `tick_all_checkboxes(session, container_selector, exclude_labels=[])` - the "select all scopes" primitive
- **D4** `extract_modal_text(session, dismiss_after=True)` - detect any visible modal, scrape its body text, optionally close
- **D5** `click_by_text(session, text, role="button"|"link")` - resilient to className churn. GHL React classnames change every deploy
- **D6** `read_visible_text(session, max_chars=8000)` - rendered text snapshot (not innerText raw) for LLM-driven decisions

### E) Human-like timing audit
Already exists (verified): `human_click`, `human_type`, `human_delay` in `arc_browser/utils/`. But:
- **E1** No declared per-domain timing policy. GHL is a paid-plan SaaS, low bot-detection risk - over-cautious timing wastes minutes. Add per-site `actions_per_minute` ceiling instead of one global rate.
- **E2** Bezier/log-normal claim in README not verified active. Audit `human_click` to confirm mouse path is non-linear.
- **E3** Google SSO is the bot-detection hotspot, not GHL itself. Need slowest timing only on SSO sub-flow, fast inside GHL.

### F) Security / detection
- **F1** **Patchright stealth patches active?** README claims `playwright-stealth` + Patchright. Verify via `page.evaluate(...navigator.webdriver, plugin list, language, etc...)` - canary checks. Tasks: add `browser_fingerprint_check(session)` tool that runs against bot.sannysoft.com and reports passes/fails.
- **F2** **localStorage / IndexedDB clearing** - Patchright sometimes wipes IndexedDB on restart, killing the GHL JWT cache. Ship cookie+localStorage export step before context close.
- **F3** **CDP fallback** - for sites where Patchright fails (linkedin, x), arc-browser supports `mode: cdp` against user's real Chrome. Document GHL fallback: if `mode: headed` flagged on detection, downgrade to `cdp`.
- **F4** **2FA pause hook** - first-class tool that pauses execution and pings the user (Discord webhook? terminal bell?) when a 2FA challenge is detected. Resume on user confirmation.
- **F5** **reCAPTCHA detection** - Google occasionally serves reCAPTCHA on SSO. Need detection (DOM marker) + human handoff.

### G) Observability
- **G1** **Per-tool audit log** - `~/.cache/arc-browser/audit.jsonl` with timestamp, tool, session, target URL, success/fail, elapsed. None today.
- **G2** **Failure replay** - on any tool error, dump page screenshot + last 100 console messages + network log to `~/.cache/arc-browser/failures/<timestamp>/`. Today errors return string only.
- **G3** **Session-state diff** - before/after every tool call, optional snapshot of URL + visible-text-hash to detect "did this actually change the page".

## Skills / docs to add (Claude Code side)

- **S1** New skill `~/.claude/skills/arc-browser/SKILL.md` - canonical tool surface, when to use which tool, daemon setup, GHL-specific notes
- **S2** Memory entry `reference_arc_browser.md` updated with: tool count, daemon mode, site registry coverage, known broken tools
- **S3** Memory entry `reference_ghl_arc_browser.md` (new) - explicit GHL-via-arc-browser playbook for future agents
- **S4** Memory entry `failure_arc_browser_2026-05-19.md` (new) - durable record of this session's friction so future agents don't repeat the assumption that "arc-browser can just do it"

## Speed + security tradeoffs (concrete)

| Concern | Current state | Recommended |
|---|---|---|
| Click speed on GHL UI | Generic human_delay 0.5-1.5s | Per-site policy: GHL = 0.2-0.6s (paid SaaS, low detection), Google SSO = 1.5-3.0s |
| Mouse path | Unverified Bezier | Audit + verify; ship `browser_fingerprint_check` |
| Session persistence across runs | Profile dir only; live state lost | Daemon mode + cookie-jar export |
| 2FA / captcha | No handler | Pause + Discord ping + resume tool |
| Stealth canaries | None | Add fingerprint check tool + monthly cron run |
| Rate limit on UI clicks | Hour-window per site | Add per-minute ceiling for short bursts (avoids "tick 100 checkboxes in 8s" trip wire) |

## Plane tasks to create (COMM project, new module "arc-browser hardening")

All under new module `arc-browser hardening`. Cycle: "arc-browser v2" (2026-05-20 → 2026-06-15).

Priority 1 - unblocks current StackPack flow:
- "[arc-browser] Add GHL site_registry entry (login, verify_url, mode, rate, hydration ms)"
- "[arc-browser] Implement `ghl_auth_refresh` + `ghl_verify_session` tools (Google SSO recipe)"
- "[arc-browser] Implement `ghl_create_pit(level, name, scopes='all')` macro"
- "[arc-browser] Implement modal-token-scraper helper for PIT create"
- "[arc-browser] Fix `browser_snapshot` Patchright accessibility regression"

Priority 2 - unblocks future SaaS work:
- "[arc-browser] Daemon mode + launchd plist (`com.arc.arc-browser-daemon`)"
- "[arc-browser] Session-state query tool (`browser_session_status`)"
- "[arc-browser] Wait-for-hydration helper (SPA-ready signals)"
- "[arc-browser] Iframe-focus helper for nested settings UIs"
- "[arc-browser] `tick_all_checkboxes` primitive for scope pickers"
- "[arc-browser] `click_by_text` resilient-to-className-churn helper"
- "[arc-browser] 2FA pause + Discord-ping resume flow"
- "[arc-browser] reCAPTCHA detection + human handoff"

Priority 3 - observability + hardening:
- "[arc-browser] Per-tool audit log (`~/.cache/arc-browser/audit.jsonl`)"
- "[arc-browser] Failure-replay artifact dump (screenshot + console + network)"
- "[arc-browser] `browser_fingerprint_check` against bot.sannysoft.com"
- "[arc-browser] Per-site click-speed policy (GHL fast, SSO slow)"
- "[arc-browser] Cookie+localStorage export/import (cross-version persistence)"

Priority 4 - rest of GHL surface:
- "[arc-browser] `ghl_switch_view(agency|subaccount)` tool"
- "[arc-browser] `ghl_switch_subaccount(location_id)` tool"
- "[arc-browser] `ghl_list_pits` + `ghl_revoke_pit` tools"
- "[arc-browser] `ghl_connect_social_account(location_id, provider)` macro for FB Page+Group OAuth handshake"

Each task description follows `feedback_plane_task_fields.md` (what / why / acceptance / handoff prompt / attribution).

## Critical files

- `~/ai/tools/browser/arc-browser/arc_browser/server.py` - tool surface (add `ghl_*` tools)
- `~/ai/tools/browser/arc-browser/arc_browser/browser.py` - context factory (snapshot fix, daemon support)
- `~/ai/tools/browser/arc-browser/arc_browser/router.py` - site classifier (no change)
- `~/ai/tools/browser/arc-browser/arc_browser/config/site_registry.json` - add GHL entry
- `~/ai/tools/browser/arc-browser/arc_browser/utils/` - human-timing + add fingerprint check + iframe helper + tick-all-checkboxes
- `~/ai/tools/browser/arc-browser/arc_browser/sites/ghl.py` (new) - GHL-specific flow code
- `~/.claude/skills/arc-browser/SKILL.md` (new)
- `~/.claude/projects/-Users-home/memory/reference_arc_browser.md` (update)
- `~/.claude/projects/-Users-home/memory/failure_arc_browser_2026-05-19.md` (new)
- LaunchAgent plist `~/Library/LaunchAgents/com.arc.arc-browser-daemon.plist` (new)

## Verification

- After Priority 1 ships: re-run StackPack GHL plan end-to-end. `ghl_create_pit("agency", "stackpack-full-agency", scopes="all")` returns a `pit-*` token in one call. No manual click-through.
- After Priority 2 ships: another sub-account (e.g. ARC) can have a Location PIT created with a single tool call.
- Audit log shows every action with timing data; failure-replay artifacts exist for every error.
- Fingerprint check returns 0 detection flags against bot.sannysoft.com.

## Out of scope

- Replacing arc-browser with another tool (browser-use, Stagehand, etc.) - we own arc-browser, fixing is cheaper
- Building a desktop UI - terminal + Claude Code is the interface
- Adding non-SaaS site support (banking, government portals) - too risky for this iteration

## User-locked decisions (2026-05-19)

1. ✅ Daemon mode = Priority 2 (after PIT macros prove value)
2. ✅ 2FA / pause-ping channel = new Discord channel `#agentic-browser` under **agents** category on ARC server. Tasks include: create channel + wire `agentic_browser_prompt(message)` helper that posts via Charlie bot. Future tools (`browser_2fa_pause`, `browser_captcha_pause`, `browser_human_handoff`) post here.
3. ✅ Manual fallback policy = **agent asks first, then assists**. New protocol: when arc-browser tooling fails, agent surfaces a clear prompt to the user - "Automation hit X. Want to do this manually? I'll keep the window open and guide you click-by-click." Manual fallback is the user's explicit opt-in, not the agent's default. Document protocol in `MANUAL_FALLBACK.md` + memory entry.
4. Audit log retention - default 30 days, configurable per `~/.cache/arc-browser/config.json`.

## Spawned task (additional to Priority lists above)

- "[arc-browser] Create Discord channel #agentic-browser under agents category"
- "[arc-browser] Build agentic_browser_prompt helper (Charlie bot post + reply listener)"
- "[arc-browser] Document MANUAL_FALLBACK.md protocol: agent asks user, doesn't default to manual"
