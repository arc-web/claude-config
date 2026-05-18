---
name: arc-browser-ghl-friction-2026-05-19
description: "Durable record of why arc-browser failed during the StackPack GHL PIT-creation flow. Stops future agents from re-assuming \"arc-browser can just do it\"."
metadata: 
  node_type: memory
  type: failure
  originSessionId: 5d3f43d0-98f1-4d27-9fde-0673f55479c6
---

## What happened

User asked arc-browser to autonomously create a GoHighLevel agency PIT for StackPack. arc-browser drove the Google SSO login (manual click-through), reached the GHL agency dashboard, then **could not** drive Settings → Private Integrations → Create New → tick scopes → submit → scrape token.

## Root causes

1. **No GHL entry in `site_registry.json`** (now fixed). Registry had 6 sites. None for `app.gohighlevel.com`. `browser_auto_login` returned "No auth recipe".
2. **No `google_sso` flow type in `auto_login`** (now fixed). Existing recipe schema only handled email+password form. Google SSO needs button click + account picker + 2FA pause.
3. **`browser_snapshot` broken on Patchright** (now fixed). Patchright dropped `page.accessibility.snapshot()` namespace; replacement DOM-walker shipped.
4. **No GHL tool surface** (now fixed). Skool has `skool_auth_refresh / verify / scan / onboard`. GHL had nothing. Shipped `ghl_auth_refresh / ghl_verify_session / ghl_create_pit / ghl_switch_view / ghl_switch_subaccount / ghl_list_pits`.
5. **No PIT macro** (now fixed). PIT creation is a 5-step UI flow. Without macro, every script re-implements it. Shipped `ghl_create_pit(level, name, scopes='all')`.
6. **No tick-all-checkboxes primitive** (now fixed). GHL scope picker has 100+ checkboxes. Shipped `tick_all_checkboxes(page, container)` helper.
7. **No modal-text scraper** (now fixed). PIT token shown once. Shipped `extract_modal_text(page, modal_selector)`.
8. **No 2FA pause flow** (partially fixed). Shipped `agentic_browser_prompt(message, session)` posting to Discord `#agentic-browser` + polling for reply. Auto-detection of 2FA challenge wired into `_login_google_sso`.
9. **No session daemon - browser closes when script exits** (P2 - not yet fixed). Profile dir persists but live browser dies. Workaround: keep one long-running stdio MCP client open across multi-step flows.
10. **No manual-fallback default policy** (now fixed via `MANUAL_FALLBACK.md` + `agentic_browser_prompt` integration). When a macro fails, agent now asks the user via Discord before falling back to manual click-through.

## What shipped (2026-05-19)

- `arc_browser/config/site_registry.json` - added `app.gohighlevel.com` entry
- `arc_browser/browser.py` - extended `auto_login` for `google_sso` flow; added `_login_google_sso`, `_detect_any_selector`, `wait_for_hydration`, `extract_modal_text`, `tick_all_checkboxes`, `click_by_text`
- `arc_browser/server.py` - added 7 new MCP tools (`ghl_auth_refresh`, `ghl_verify_session`, `ghl_switch_view`, `ghl_switch_subaccount`, `ghl_create_pit`, `ghl_list_pits`, `agentic_browser_send_prompt`); fixed `browser_snapshot`
- `arc_browser/utils/prompt.py` - new `agentic_browser_prompt(message, session, channel)` helper
- `MANUAL_FALLBACK.md` - manual-fallback protocol doc
- Discord channel `#agentic-browser` created (id `1505998313453781186`) on ARC server, Agents category

## Verified

- `python -m arc_browser.server` registers 31 tools (was 24); all 7 new ones surface in `list_tools`
- Module-level import clean (no missing symbols, no syntax errors)
- Tools wire correctly to underlying helpers in `browser.py`

## Not yet verified (next session)

- End-to-end `ghl_create_pit("agency", "stackpack-full-agency", scopes="all")` against the live GHL UI
- 2FA pause flow against Google SSO challenge
- Modal-token scrape against the actual PIT-display modal

## Plane tracking

All work tracked under epic COMM-35 ("arc-browser hardening v2") in `arc-browser hardening` module, `arc-browser v2` cycle. P1 tasks (COMM-36 through COMM-40, COMM-58, COMM-59, COMM-60) marked Done after this session. P2-P4 (COMM-41 through COMM-57) remain Todo.

## How to apply

When designing automation against a SaaS UI:
- Check `site_registry.json` first; add an entry before any script reads it
- Mirror Skool/GHL pattern: dedicated `<site>_*` tool surface + macros, not raw click chains
- Wrap every brittle step in try/except + `agentic_browser_prompt` for human handoff
- Don't assume the browser is alive across script invocations - keep one long-running stdio client
