# GoHighLevel Full-Access Auth Architecture

## Context

Current state of GHL auth across the local stack:

- `~/ai/platforms/ghl-toolkit/autocli/skills/ghl-auth/` - **internal JWT refresh** flow against `backend.leadconnectorhq.com` / `services.leadconnectorhq.com`. Uses scraped browser tokens + 1-hour JWT + 30-day rotating refresh JWT. Internal API only, not public API.
- 1P ARC `GHL PIT - gohighlevel_mcp` (`7xqrb7z6...`) - **sub-account-scoped PIT** locked to `location_id: jANqJijuBX4MF5OaY4Uz`. Built for the gohighlevel_mcp MCP server.
- 1P Zeroclaw `GHL - DigitalAccessPartner - Agency Token` (`ydy2he7d...`) - **agency-level PIT** `pit-20f458f3-...`. "ALL scopes at create time" per 1P notes, but **Social Planner endpoints return 401** (probe confirmed 2026-05-18). Scope set was wide but Social Planner not in it - likely created before Social Planner GA scopes added.

User direction (locked):

- **Full agency PIT** = ALL scopes, all the time, no per-purpose narrowing on the token
- **Full sub-account PIT** = ALL scopes per location
- **Agent layer narrows scope**, not the token
- Stop short-cutting for this one project - build the canonical pattern future communities + clients reuse

Goal: replace the patchwork of partial PITs with a clean, documented, rotation-aware auth architecture that any agent / any project / any sub-account can plug into.

## Architecture

Three layers:

### Layer 1 - Tokens (full access, GHL-owned)

| Token | Scope | Created in | Lifetime | Rotation | Storage |
|---|---|---|---|---|---|
| **Agency PIT** | ALL agency scopes | Agency view → Settings → Private Integrations | Indefinite | 90 days recommended (7-day overlap) | OpenBao `secret/shared/ghl/agency-pit` field `value` + 1P ARC item "GHL Agency PIT - DigitalAccessPartner" |
| **Location PIT per sub-account** | ALL location scopes | Sub-account view → Settings → Private Integrations | Indefinite | 90 days recommended | OpenBao `secret/shared/ghl/locations/{location_id}-pit` field `value` + 1P ARC items "GHL Location PIT - {name}" |

GHL caps: max 5 agency PITs, max 5 PITs per location.

### Layer 2 - Auth library (shared, scope-aware)

Single Python + Node module that every agent imports:

- Resolves the right token for the call (agency vs location based on endpoint + companyId/locationId)
- Adds required headers (`Authorization: Bearer <PIT>`, `Version: 2021-07-28`, browser User-Agent)
- Caches in-memory for the session
- Logs every call: timestamp, endpoint, agent name, scope used
- No retry logic at this layer - retry belongs upstream

Suggested locations:
- Python module: `~/ai/platforms/ghl-toolkit/lib/ghl_auth.py` (new)
- Node module: `~/ai/platforms/ghl-toolkit/autocli/skills/ghl-auth/scripts/ghl-pit-lib.mjs` (sibling to existing JWT lib)

### Layer 3 - Agent capability narrowing (where scope shrinks)

Each agent declares its capability surface in its own config / system prompt:

- `stackpack-social-scheduler` agent: only calls `/social-media-posting/*` for `location_id: 7RtMOVzhbCIIgeBbjGQA`
- `arc-contact-sync` agent: only calls `/contacts/*` across all locations
- `gohighlevel_mcp` MCP server: full surface (legacy fallback)

Enforcement options:
- **Soft** (recommended for v1): system prompt declares allowed endpoints; agent self-polices; ghl_auth.py logs every call so violations show up in audit
- **Hard** (v2): wrapper layer in `ghl_auth.py` accepts an `agent_id` arg and refuses calls to endpoints not whitelisted for that agent

This is the inversion: **token = full**, **agent = scoped**. Easier to rotate, easier to audit, no per-purpose token sprawl.

## Plan steps

### Step 1 - Prep arc-browser session against GHL

arc-browser at `~/ai/tools/browser/arc-browser/` is the canonical stealth-browser MCP.

**Current state (verified 2026-05-18):** only `smoke` test session exists. No GHL session. **First-time login bootstrap required.**

1. Enable arc-browser MCP for this session: `claude plugin enable arc-browser@my-claude-plugins` (or however it's surfaced)
2. Call arc-browser tool to create session named `ghl` pointing at `app.gohighlevel.com`
3. arc-browser opens the browser, navigates to GHL login
4. User signs in once (manual - 2FA may apply, can't automate Google SSO reliably)
5. Cookies persist to `~/ai/tools/browser/arc-browser/arc_browser/sessions/ghl/Default/`
6. Verify by tasking arc-browser to navigate Agency dashboard → assert sub-account list contains "StackPack.app"
7. Document session name in memory entry `reference_ghl_api.md`

Login: `digital.access.partners@gmail.com` via Google SSO. 2FA challenge may surface - handle manually in the arc-browser window when prompted.

### Step 2 - arc-browser creates the canonical Agency PIT (full scope)

Driven by arc-browser, not user:

1. arc-browser navigates to `app.gohighlevel.com` in Agency view
2. arc-browser clicks Settings → Private Integrations
3. arc-browser counts existing agency PITs (cannot exceed 5)
4. arc-browser clicks "Create New Integration"
5. arc-browser fills name field: `stackpack-full-agency`
6. arc-browser ticks every scope checkbox in the scope picker (handle "Select All" if button exists, otherwise iterate every box)
7. arc-browser clicks Create
8. arc-browser **immediately captures the displayed token** before the modal closes (PIT shown once)
9. arc-browser returns token to the calling agent

Plan then:
- Writes token to OpenBao `secret/shared/ghl/agency-pit` field `value`
- Mirrors to 1P ARC as item "GHL Agency PIT - StackPack-full"
- Probes endpoints to verify all-scope coverage:
  - `/social-media-posting/{stackpack_loc}/posts/list` (target: 200 - was 401 with old PIT)
  - `/locations/search?limit=200`
  - `/contacts/?locationId={stackpack_loc}&limit=1`
  - `/opportunities/search?location_id={stackpack_loc}&limit=1`
  - `/calendars/?locationId={stackpack_loc}`
  - `/conversations/search?locationId={stackpack_loc}&limit=1`
- Logs probe results to `~/.cache/ghl-auth/agency-pit-bootstrap-2026-05-18.jsonl`

### Step 3 - arc-browser creates the StackPack Location PIT (full scope)

Only StackPack. Other sub-accounts not in scope for this plan.

1. arc-browser switches into StackPack.app sub-account (`7RtMOVzhbCIIgeBbjGQA`) - either via Agency dashboard click or direct URL navigation
2. Settings → Private Integrations
3. Click "Create New Integration"
4. Name: `stackpack-full-location`
5. Tick every scope checkbox available at location level
6. Create → capture displayed token
7. Returns token to caller

Plan then:
- Writes to OpenBao `secret/shared/ghl/locations/7RtMOVzhbCIIgeBbjGQA-pit` field `value`
- Mirrors to 1P ARC as item "GHL Location PIT - StackPack.app"
- Probes Social Planner endpoints against this PIT to verify location-level posting works
- Logs to `~/.cache/ghl-auth/stackpack-pit-bootstrap-2026-05-18.jsonl`

### Step 4 - Build shared auth library

`~/ai/platforms/ghl-toolkit/lib/ghl_auth.py` (new):

```python
# Pseudocode
class GHLAuth:
    def __init__(self, agent_id: str = None):
        self.agent_id = agent_id or 'unknown'
        self._agency_pit = None
        self._loc_pits = {}

    def for_agency(self) -> dict:
        # Returns headers + base URL for agency-scoped call
        if not self._agency_pit:
            self._agency_pit = self._fetch_openbao('secret/shared/ghl/agency-pit')
        return self._headers(self._agency_pit)

    def for_location(self, location_id: str) -> dict:
        # Returns headers + base URL for location-scoped call
        if location_id not in self._loc_pits:
            try:
                self._loc_pits[location_id] = self._fetch_openbao(
                    f'secret/shared/ghl/locations/{location_id}-pit'
                )
            except NotFound:
                # Fallback: use agency PIT for location-scoped endpoints
                # GHL allows this for most endpoints
                return self.for_agency()
        return self._headers(self._loc_pits[location_id])

    def _headers(self, token: str) -> dict:
        return {
            'Authorization': f'Bearer {token}',
            'Version': '2021-07-28',
            'User-Agent': 'Mozilla/5.0 ... Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }

    def log(self, endpoint: str, method: str):
        # Append to ~/.cache/ghl-auth/audit.jsonl
        ...
```

Sibling Node implementation at `autocli/skills/ghl-auth/scripts/ghl-pit-lib.mjs`.

### Step 5 - Rotation discipline

GHL recommends 90-day rotation. PITs can be regenerated in-UI; old token works for 7 days alongside new.

- Add to LaunchAgent or cron: monthly reminder `com.arc.ghl-pit-rotation-check` that posts a Discord `#announcements` message every 30 days listing PITs older than 60 days
- Memory entry `reference_ghl_api.md` documents rotation cadence + the 7-day overlap window pattern

### Step 6 - Documentation

New memory file `~/.claude/projects/-Users-home/memory/reference_ghl_api.md`:
- Token type table (Agency PIT vs Location PIT vs internal JWT)
- OpenBao paths
- Required headers (Authorization, Version, User-Agent, optional location)
- Endpoint scope decision tree (when to use agency vs location token)
- Existing tooling map (`ghl-toolkit`, `gohighlevel_mcp`, `GoHighLevel-MCP`, `arc-mcp-server/src/integrations/gohighlevel.js`, `autocli/skills/ghl-auth`)
- Rate limit notes (10 req / 10s per location default; agency has higher pool)
- Common gotchas (Cloudflare WAF requires browser User-Agent; `Version: 2021-07-28` header is mandatory; some endpoints reject location PIT and require agency PIT, others vice versa)

Index entry added to `MEMORY.md` under `## Reference` section.

### Step 7 - Wire StackPack social automation (the original COMM-20 task)

After Step 2-6 are done and tokens are verified:

1. Link FB Page `facebook.com/stackpackapp` to FB Group `676156638441781` inside Facebook (one-time UI step)
2. Add Lead Connector as authorized app on the FB Group
3. In StackPack GHL sub-account (`7RtMOVzhbCIIgeBbjGQA`) → Social Planner → Settings → Connect FB Group + Page
4. Via API (using StackPack location PIT), call `GET /social-media-posting/7RtMOVzhbCIIgeBbjGQA/accounts` to retrieve Page + Group `accountId`s
5. Store accountIds at OpenBao `secret/shared/ghl/locations/7RtMOVzhbCIIgeBbjGQA-social-accounts` (fields `fb_page`, `fb_group`)
6. Write content calendar in Plane page under COMM (12 weeks, 3 post types)
7. Schedule via `POST /social-media-posting/7RtMOVzhbCIIgeBbjGQA/posts` loop with mandatory 1.1s sleep between (respects 10/10s rate limit)

## Files to be modified

- `~/ai/platforms/ghl-toolkit/lib/ghl_auth.py` (new)
- `~/ai/platforms/ghl-toolkit/autocli/skills/ghl-auth/scripts/ghl-pit-lib.mjs` (new sibling to existing JWT lib)
- `~/.claude/projects/-Users-home/memory/reference_ghl_api.md` (new)
- `~/.claude/projects/-Users-home/memory/MEMORY.md` (new index entry)
- 1P ARC: 6 new items ("GHL Agency PIT - DigitalAccessPartner" + 5 "GHL Location PIT - {name}")
- OpenBao: 6 new paths under `secret/shared/ghl/`

## Out of scope

- Marketplace OAuth app flow (different surface; PIT path is enough)
- Per-agent hard scope enforcement (deferred to v2 of auth library)
- Migrating `gohighlevel_mcp` MCP server from existing location PIT to new agency PIT (separate cleanup task once new arch proven)
- Internal JWT refresh flow (`ghl-auth` skill) - leave as-is; PIT path is for public API only

## User-locked decisions

1. ✅ arc-browser drives all GHL clicks (no user click-through)
2. ✅ Scope this plan to **StackPack only**: 1 agency PIT + 1 location PIT (StackPack.app). No ARC/501PPC/Moonraker/BluePixel provisioning in this plan.
3. ✅ Retire existing narrow `gohighlevel_mcp` PIT after new arch proves out - but first do usage audit (grep `~/ai` for PIT prefix + 1P reference + OpenBao path) to find live callers, then retire on 7-day overlap once known callers swapped to new PIT
4. ✅ GHL login = `digital.access.partners@gmail.com` (Google SSO assumed)

## Pre-execution usage audit (added per user direction)

Before retiring the existing narrow `gohighlevel_mcp` PIT, find every caller:

- `grep -r "gohighlevel_mcp" ~/ai --include="*.py" --include="*.js" --include="*.ts" --include="*.mjs"`
- `grep -r "pit-c59005fd" ~/ai`
- `grep -r "jANqJijuBX4MF5OaY4Uz" ~/ai`
- Check OpenBao paths under `secret/` for any reference
- Check LaunchAgent plists / cron / docker-compose envs

Output of audit committed to the issue description before any PIT retirement.

## Plane tasks spawned by this plan

To be created under COMM project, parent epic = COMM-26 (Member Tier Buildout):

- "[StackPack] arc-browser GHL session bootstrap (digital.access.partners@gmail.com)"
- "[StackPack] arc-browser creates full-scope Agency PIT"
- "[StackPack] arc-browser creates full-scope StackPack Location PIT"
- "[StackPack] Build shared ghl_auth.py + ghl-pit-lib.mjs"
- "[StackPack] Audit narrow gohighlevel_mcp PIT usage + retire"
- "[StackPack] Write reference_ghl_api.md memory entry"
- "[StackPack] Wire Social Planner accounts to GHL (link Page + Group, connect via OAuth)"
