---
name: FlareSolverr - Cloudflare bypass proxy on VPS Alpha
description: Endpoint, request format, and usage rules. Currently idle - deployed but zero consumers in ~/ai/. Use for one-shot HTTP scraping, not interactive browsing.
type: reference
originSessionId: acd5be6d-7ebf-4afd-8bbb-9bdd9702c4db
---
- **Endpoint**: http://187.77.222.191:8191/v1 (POST, JSON)
- **Container**: `flaresolverr` on VPS Alpha
- **Status as of 2026-04-21**: Idle. Zero consumers across ~/ai/. Kept available for future HTTP scrapers.
- **Use when**: `requests.get()` / `fetch()` against a Cloudflare-gated URL returns 403 or a challenge page.
- **Do NOT use for**: interactive browser automation (arc-browser), non-CF sites, or anything needing persistent authenticated sessions.
- **Decision record**: Initially rejected for arc-browser 2026-04-21. SUPERSEDED 2026-05-01: arc-browser now ships `arc_browser/flaresolverr.py` + `cf_recovery.py` (commit bf3f53e). FlareSolverr integrated for CF-gated recovery path. Full docs: `~/ai/infra/paperclip/docs/flaresolverr.md`.
