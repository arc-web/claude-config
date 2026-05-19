---
name: FlareSolverr - Cloudflare bypass proxy on VPS Alpha
description: Endpoint, request format, and usage rules. Currently idle - deployed but zero consumers in ~/ai/. Use for one-shot HTTP scraping, not interactive browsing.
type: reference
originSessionId: acd5be6d-7ebf-4afd-8bbb-9bdd9702c4db
---
- **Endpoint**: http://187.77.222.191:8191/v1 (POST, JSON)
- **Container**: `flaresolverr` on VPS Alpha
- **Status as of 2026-05-20**: Wired into arc-browser as CF-recovery path. Confirmed live in `~/ai/tools/browser/arc-browser/arc_browser/flaresolverr.py` + `cf_recovery.py`.
- **Use when**: `requests.get()` / `fetch()` against a Cloudflare-gated URL returns 403 or a challenge page. arc-browser auto-escalates to FlareSolverr when CF challenge detected during a browse.
- **Do NOT use for**: non-CF sites, or anything needing persistent authenticated sessions (use arc-browser direct for those).
- **Decision record**: Initially rejected for arc-browser 2026-04-21. SUPERSEDED 2026-04-23 (integration commit bf3f53e, predated this file's prior claim of 2026-05-01 by 8 days - prior date was wrong). Re-verified 2026-05-20. Full docs: `~/ai/infra/paperclip/docs/flaresolverr.md`.
