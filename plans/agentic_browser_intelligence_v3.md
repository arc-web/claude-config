# Agentic Browser Intelligence v3 - 10x Research Plan

## Context

arc-browser v2 (P1 shipped 2026-05-19) hit a wall on GHL agency settings: page lazy-loads via SPA route guard, direct URL gives empty body, sidebar-click required. Discovery showed body_snippet empty even after 5s wait. The pattern is universal across modern SaaS - settings panels render on lazy-mount, not on URL hit.

This plan is a major research lap into SOTA agentic browser intelligence (browser-use, Stagehand, Skyvern, Computer Use, AgentQL) mapped against arc-browser's actual capabilities, then a concrete upgrade architecture so arc-browser stops being "scripted Playwright with a few macros" and becomes a real agentic browser that handles lazy-load, brittle selectors, and unknown SaaS without per-site hand-coding.

The user prompt: "PLAN 10X MORE RESARCH ON AGENTIC BROWSER USAGE INTELLINGENCE" - this is the answer.

## Research findings (2026 state of agentic browsers)

### Market signal
- $4.5B (2024) → $76.8B (2034) projected. Every major lab shipped one in 15 months.
- Google Chrome Auto Browse launched 2026-01-28 powered by Gemini 3.
- OpenAI ChatGPT Atlas (Oct 2025) - Agent Mode autonomous browse.
- Anthropic Computer Use - vision-only baseline.

### Reliability leaderboard (common browser tasks)
| Stack | Reliability | Approach |
|---|---|---|
| Playwright + Claude (hybrid) | 92% | DOM-first, AI for hard cases |
| Browserbase | 90% | Hybrid platform |
| Stagehand | 89% | TypeScript hybrid (act/extract/observe) |
| browser-use | 87% | Python DOM + LLM |
| Skyvern 2.0 | 85.85% (WebVoyager) | Vision-first, form specialty |
| Anthropic Computer Use | 78% | Pure vision/screenshot |

**Takeaway: DOM-driven > pure vision by 12-17 pp on common tasks. Vision-driven unlocks the long tail (canvas, iframes, anti-bot screens).**

### Architecture patterns
1. **Hybrid Playwright + AI** (recommended SOTA): Playwright for the 80% predictable, AI for the 20% ambiguous. Lowest cost, highest reliability.
2. **Natural-language locators (AgentQL, AI Locators)**: replace fragile CSS/XPath with "the create button in the integrations panel". Self-healing on UI change.
3. **act/extract/observe primitives (Stagehand)**: high-level "click X", "extract Y", "is Z visible" - LLM resolves the selector at call time, caches it for replay.
4. **Visual workflow builder (Skyvern)**: GUI-driven workflow recording, vision execution for canvas-heavy UIs.
5. **Vision fallback (Computer Use)**: when DOM is canvas, iframe-locked, or anti-bot-protected, screenshot + click coordinates.

### SPA / lazy-load handling
- **Mutation observer until stable** - wait until no DOM mutations for N ms (Stagehand, browser-use)
- **Network idle + framework-ready signal** - wait for React/Vue commit cycle done
- **Visible content guard** - poll for body.innerText.length > threshold or specific selector visible
- **Vision spinner detection** - Skyvern recognizes loading spinners + waits

### Token efficiency
- DOM accessibility tree compression: drop generics, keep role+name, ~10x token reduction vs raw HTML
- Stagehand caches resolved selectors per page for replay (no LLM call after first success)
- browser-use compresses with a "highlight clickable" overlay + minimal DOM diff

### Security / detection
- **Patchright + playwright-stealth** - DOM-level stealth (arc-browser uses)
- **Camoufox** - hardened Firefox fork (arc-browser uses via camofox.py)
- **CDP fallback** - real Chrome for anti-bot sites (arc-browser uses)
- **Bezier mouse + log-normal timing** - claimed in arc-browser, not verified active
- **Fingerprint canaries** - bot.sannysoft.com, browserleaks.com - run periodically

## Gap matrix: arc-browser today vs SOTA

| Capability | arc-browser today | SOTA reference | Gap severity |
|---|---|---|---|
| DOM walker snapshot | ✅ fixed P1 (post-Patchright accessibility) | Stagehand DOM-flattened tree | medium - works but verbose |
| Click by selector | ✅ `browser_click` | Stagehand `act("click X")` | high - no NL fallback |
| Click by text | ✅ shipped P1 `click_by_text` | AgentQL `click($button:has-text("X"))` | medium - text-only, no role+context |
| Wait for hydration | ✅ shipped P1 (basic) | Stagehand mutation-observer + framework signals | high - 8s timeout, no signal awareness |
| Lazy-load detection | ❌ none | Skyvern vision spinner + browser-use mutation-stable | **critical** - this is the GHL blocker |
| AI element resolution | ❌ none | Stagehand `observe("the create button")` | **critical** - no fallback when text-match misses |
| Vision fallback | ⚠️ camofox + screenshot only | Anthropic Computer Use, Skyvern | high - no vision agent loop |
| Self-healing selectors | ❌ none | AgentQL recompiles on UI change | high |
| Site recipe registry | ⚠️ 7 sites (added GHL P1) | Stagehand `useText` pattern | medium |
| Action caching | ❌ none | Stagehand caches resolved selectors | medium |
| Form filling | ⚠️ basic `browser_type` | Skyvern 85.85% WebVoyager | high - no schema-aware fill |
| Network idle detection | ❌ none | Playwright `networkidle` baseline | high |
| Framework-ready signal | ❌ none | React DevTools detection | medium |
| 2FA / captcha pause | ✅ shipped P1 (Discord ping) | Stagehand human-handoff | parity |
| Token efficiency | ✅ DOM walker compresses | Stagehand caches | parity-ish |
| Cost tracking | ❌ none | Stagehand cost metrics per action | low |
| Session daemon | ❌ P2 todo | browser-use shared context | high |

## Upgrade architecture (4 layers, additive)

```
+-------------------------------------------------------+
|  Layer 4: Site Intelligence (per-SaaS knowledge)     |
|  - GHL flow recipes, Skool flow recipes              |
|  - Settings nav helpers per site                     |
|  - Known PIT-create / OAuth / connect flows          |
+-------------------------------------------------------+
|  Layer 3: AI Element Resolution (the missing brain)  |
|  - act("click create button") -> LLM picks selector  |
|  - observe("is modal visible") -> LLM yes/no         |
|  - extract("token from modal") -> LLM regex/scan     |
|  - Selector cache by URL signature + replay          |
+-------------------------------------------------------+
|  Layer 2: SPA-aware primitives                       |
|  - wait_dom_stable(ms)  - mutation observer          |
|  - wait_network_idle(ms)                             |
|  - wait_react_ready()                                |
|  - wait_visible_content(min_chars)                   |
|  - wait_spinner_gone()                               |
+-------------------------------------------------------+
|  Layer 1: Hardened existing primitives               |
|  - browser_navigate (already exists)                 |
|  - browser_click / type / evaluate (already exists)  |
|  - browser_snapshot (fixed P1)                       |
|  - human_click / human_type / human_delay            |
+-------------------------------------------------------+
|  Layer 0: Patchright + Camofox + CDP (existing)      |
+-------------------------------------------------------+
```

The GHL failure was a Layer 2 + Layer 3 gap. We have Layer 0/1, partial Layer 2, no Layer 3, partial Layer 4.

## Concrete new capabilities (Layer 2 + 3 + 4)

### Layer 2 - SPA-aware primitives (P1-CRITICAL)

- **`wait_dom_stable(page, idle_ms=800, timeout_ms=15000)`** - install MutationObserver in page, return when no mutations for `idle_ms`. This is what GHL needed.
- **`wait_network_idle(page, idle_ms=1500, timeout_ms=20000)`** - patchright already exposes `networkidle` but wrap with timeout-tolerant retry.
- **`wait_framework_ready(page, timeout_ms=15000)`** - detect React/Vue/Angular finishing commit cycle. Inject probe: `window.__REACT_DEVTOOLS_GLOBAL_HOOK__` or `window.Vue` or fall back to `requestIdleCallback`.
- **`wait_visible_content(page, min_chars=200, timeout_ms=15000)`** - poll body innerText length until > threshold.
- **`wait_spinner_gone(page, spinner_selectors=[".spinner", "[role='progressbar']", "svg[class*='spin']"], timeout_ms=15000)`**.
- **`wait_for_app(page, ms=10000)`** - composite: networkidle + dom_stable + visible_content. The one tool to call after every navigate.

### Layer 3 - AI element resolution (P1-CRITICAL)

Two AI options - decide via config:

**Option 3A - Local Ollama** (zero cost, slower):
- `ai_resolve_selector(page, description, role_hint=None)` - send compact DOM tree + description to Ollama qwen2.5:14b → returns CSS selector + confidence.
- Cache results by `(page_url_path, description)` → 90%+ replays skip LLM.

**Option 3B - OpenRouter cheap-model** (small cost, faster, more reliable):
- Same interface, route via Gemini 2.5 Flash or Kimi.
- Per `model_routing.md` memory: never use Anthropic API key. Use Gemini/Kimi.

New tools:
- `agentic_click(description, session)` - LLM picks selector + clicks
- `agentic_observe(description, session)` - returns bool/structured
- `agentic_extract(description, session)` - returns structured data from page

### Layer 4 - Site intelligence expansion (P1-CRITICAL for GHL specifically)

New module per high-value SaaS:
- `arc_browser/sites/ghl.py` - GHL-specific flows (PIT create, Social Planner connect, sub-account switch)
- `arc_browser/sites/skool.py` - move existing skool_* tools here
- `arc_browser/sites/facebook.py` - FB Page+Group link flow

Each site module exports:
- `nav_to(page, destination)` - knows that Settings is sidebar-click on GHL, direct URL on Skool
- `wait_panel_ready(page, panel_name)` - per-panel hydration markers
- `Flow` classes - end-to-end macros (PITFlow, SocialConnectFlow)

### Plus: framework integrations to consider (P2)

- **browser-use Python sidecar** - mature, MIT license, fits arc-browser's stack. Wire as fallback when AI element resolution fails. github.com/browser-use/browser-use
- **AgentQL** - AI query language; integrate as a tool: `agentql_find(query)` returns elements. Hosted service + free tier.
- **Stagehand** - TypeScript only, sidecar route only. Probably not worth in MVP.
- **Skyvern** - separate runtime (Docker), use for form-heavy flows specifically. Defer until form-filling becomes a bottleneck.

## Plane task creation (~25 new tasks)

Under existing epic COMM-35 ("arc-browser hardening v2") - add new module "arc-browser v3 intelligence". New cycle "arc-browser v3" (2026-05-25 → 2026-07-15).

### P1-CRITICAL - unblocks GHL + every future SaaS (10 tasks)
- `[arc-browser] wait_dom_stable - MutationObserver-based SPA stability wait`
- `[arc-browser] wait_network_idle - Patchright networkidle with timeout-tolerant wrapper`
- `[arc-browser] wait_framework_ready - React/Vue/Angular commit cycle detection`
- `[arc-browser] wait_visible_content - body innerText threshold poll`
- `[arc-browser] wait_spinner_gone - vision-free spinner-selector poll`
- `[arc-browser] wait_for_app composite (networkidle + dom_stable + visible_content)`
- `[arc-browser] agentic_click - LLM resolves selector from description`
- `[arc-browser] agentic_observe - LLM yes/no observation`
- `[arc-browser] agentic_extract - LLM structured extract from page`
- `[arc-browser] Selector cache layer (URL signature -> selector lookup, replay on hit)`

### P1-GHL specific (5 tasks)
- `[arc-browser] arc_browser/sites/ghl.py module - PITFlow, nav_to_settings, find_create_button`
- `[arc-browser] Re-test ghl_create_pit with wait_for_app + agentic_click fallback chain`
- `[arc-browser] ghl_nav_to_settings - sidebar-click discovery + click sequence`
- `[arc-browser] Document GHL agency lazy-load + sidebar nav pattern in failure_arc_browser memory`
- `[arc-browser] ghl_connect_social_account using new layers`

### P2 - framework integration (3 tasks)
- `[arc-browser] Wire browser-use as fallback agent for unresolved goals`
- `[arc-browser] Evaluate AgentQL natural-language query integration`
- `[arc-browser] Compare cost/latency of agentic_click via Ollama vs Gemini Flash`

### P2 - vision fallback (3 tasks)
- `[arc-browser] vision_click(description) - screenshot + Computer Use loop`
- `[arc-browser] Auto-fallback chain: text-match -> agentic_click -> vision_click`
- `[arc-browser] Cost/reliability dashboard per resolution path`

### P3 - observability + cost (4 tasks)
- `[arc-browser] Per-action cost log (LLM tokens, vision tokens, latency)`
- `[arc-browser] Selector cache hit rate metric`
- `[arc-browser] Action-replay reliability metric (cache replay vs LLM re-resolve)`
- `[arc-browser] Weekly fingerprint canary cron (bot.sannysoft.com)`

## Files to be created / modified

- `arc_browser/utils/waits.py` (new) - all Layer 2 wait_* helpers
- `arc_browser/agentic/` (new package) - LLM-driven resolution
  - `agentic/resolver.py` - DOM compression + LLM prompt + cache
  - `agentic/cache.py` - URL-signature keyed cache
  - `agentic/providers.py` - Ollama / OpenRouter switch
- `arc_browser/sites/` (new package)
  - `sites/__init__.py`
  - `sites/ghl.py` (GHL-specific flows)
  - `sites/skool.py` (move existing skool tools here, leave thin shim in server.py)
- `arc_browser/server.py` - add `agentic_click`, `agentic_observe`, `agentic_extract` tools; rewire `ghl_create_pit` to use new layers
- `arc_browser/browser.py` - add `wait_for_app` composite; ensure auto_login calls it after every nav
- `arc_browser/config/site_registry.json` - add `hydration_markers` per site (signals for wait_framework_ready)
- `tests/test_waits.py` (new) - fixtures for the 5 wait primitives
- `tests/test_agentic.py` (new) - mock LLM responses, verify cache hit
- `tests/test_ghl_flow.py` (new) - PIT macro against fixture HTML

## Reused / inspiration

- `~/ai/tools/browser/arc-browser/arc_browser/browser.py` - existing context factory + auto_login (extend)
- `~/ai/tools/browser/arc-browser/arc_browser/camofox.py` - vision-capable Firefox (use for canvas-heavy fallback)
- `~/ai/tools/browser/arc-browser/arc_browser/utils/human.py` - human_click + human_type (compose with new layers)
- `~/ai/agents/comms/discord_agent/llm_analyzer.py` - existing OpenRouter+Ollama chain pattern (mirror for agentic resolver)
- `~/.claude/projects/-Users-home/memory/rules_model_routing.md` - never Anthropic API for automation; Gemini Flash + Kimi only

## Verification

- After P1-CRITICAL ships: re-run GHL agency PIT discovery script. `wait_for_app` after nav returns within 5s with non-empty body. `agentic_click("create new integration button")` resolves the right element 95%+ of the time on first call, 100% on cached replay.
- After P1-GHL ships: `ghl_create_pit("agency", "stackpack-full", "all")` returns a `pit-*` token in one tool call. End-to-end <60s.
- After P2 ships: vision fallback unblocks at least one canvas-only SaaS (test fixture: Figma comments, Notion gallery view).
- Cost dashboard shows per-flow LLM spend.
- Selector cache hit rate > 70% on second visit per page.

## Out of scope (v3)

- Replacing arc-browser core with browser-use - integrate as fallback, don't rewrite
- Hosting AgentQL ourselves - use their cloud service if integrated
- Building a visual workflow builder (Skyvern-style) - skip for now
- Multi-tab orchestration - single-tab per session for v3
- Cross-browser support (Firefox/Safari) - Patchright + Camofox cover Chromium/Firefox already

## Open questions

1. **LLM provider for agentic resolver** - Ollama local (zero cost, qwen2.5:14b already running) or OpenRouter Gemini Flash (faster, $0.075/M tokens)? Recommend: Ollama for observe/extract, Gemini for act (where speed matters).
2. **Action cache scope** - per-session, per-domain, or global? Recommend: per-domain (selectors stable per site, cache survives session restart).
3. **Vision fallback budget** - cost cap per session? Recommend: $0.50/session hard limit on vision calls.
4. **GHL-specific deadline** - finish the GHL flow (PIT + Social Planner) as part of v3 P1, or ship v3 layers first and re-attempt GHL after? Recommend: ship Layer 2 + 3 first (4-6 hours of work), then re-attempt GHL (which becomes 1 hour).
5. **browser-use sidecar** - install it as direct dependency or run as subprocess? Recommend: subprocess (sandboxed, easier to disable).
