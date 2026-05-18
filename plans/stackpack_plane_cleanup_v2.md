# StackPack Plane Cleanup + Open-Issue Resolution (v2)

> Supersedes `stackpack_plane_cleanup_and_resolution.md`. Incorporates 8 gaps surfaced in user feedback:
> contradictory COMM-22/23 names, missing COMM-28 create step, no preflight snapshot, wrong auth fallback
> order, no rate-limit handling, UI-based verification, unchecked FB Group API feasibility, vague memory
> step for COMM-17.

## Context

Communities project (COMM) holds 19 stackpack-related issues across 3 epics + StackPack module. Issues
fail the documented Plane criteria (no handoff prompt, no attribution, no estimate, some names
ambiguous). Eight TODOs have no concrete resolution plan. Codex audit also flagged structural risks
in the v1 execution plan: stale internals, missing preflight, wrong auth order, no backoff, naive
verification, unverified Meta Groups API path.

This v2 fixes all of those before any live PATCH lands.

## Plane criteria recap (`feedback_plane_task_fields.md`)

Every task: name (action-oriented), state, description (what / why / acceptance), module, time
estimate (human minutes), handoff prompt block, attribution line on every description and comment
update (`— [Agent: claude-opus-4-7 via Claude Code | 2026-05-18]`).

## Phase 0 - Live preflight snapshot + rollback artifact (NEW)

Before any write. Single read-only Python script:

1. Fetch all 19+ stackpack issues via `GET /workspaces/todovibes/projects/{COMM}/issues/?per_page=100`
2. For each, capture: `id`, `sequence_id`, `name`, `state`, `parent`, `description_html`,
   `estimate_point`, `label_ids`, `module_ids`, `cycle_id`, last `updated_at`
3. Fetch comments per issue: `GET /issues/{id}/comments/`
4. Write JSON snapshot to `~/.claude/plans/snapshots/stackpack_pre_cleanup_2026-05-18.json`
5. Verify snapshot ≥ 19 issues, each with non-empty `id`
6. Print one-line digest: count, oldest `updated_at`, newest `updated_at`

Rollback if Phase 5 corrupts data: re-PATCH each issue with its snapshotted `name`,
`description_html`, `estimate_point`, `parent`. Comments cannot be edited after creation - if a new
comment was added in error, DELETE via `/comments/{id}/`.

## Phase 1 - Rename ambiguous tasks (corrected)

| Issue | Current name | New name |
|---|---|---|
| COMM-8 | StackPack - define community management workflows | [StackPack] Document community ops playbook (channels, moderation, rituals) |
| COMM-10 | [StackPack] Cloudflare redirect cleanup - apex + www to skool.com | [StackPack] Remove legacy Cloudflare redirects routing stackpack.app to skool.com |
| COMM-11 | [StackPack] Initial site build - dark/purple single-page, Skool CTA | [StackPack] Site v1 single-page build (superseded by COMM-12 redesign) |
| COMM-12 | [StackPack] Full redesign - Linear/Vercel-style UI + depth | [StackPack] Rebuild stackpack.app as Linear-style multi-section community site |
| COMM-14 | [StackPack] Facebook group URL integration | [StackPack] Wire live Facebook group URL into Free-tier CTA on stackpack.app |
| COMM-16 | [StackPack] cloudflare_agent full toolchain audit | [StackPack] Run cf-deploy full audit (lint, sitemap, robots, llms, seo, dns, verify) |
| **COMM-22** | [StackPack] Private Discord channel - provision + access flow | **[StackPack] Stand up public StackPack Discord server + invite link (marketing claim for launch)** |
| **COMM-23** | [StackPack] 1-on-1 strategy call booking system | **[StackPack] Document Discord-DM flow for yearly-tier 1-on-1 access (no booking tool)** |
| COMM-24 | [StackPack] Browser 301 cache - communications for early visitors | [StackPack] Publish hard-reload guidance for visitors hitting cached 301 to skool.com |

COMM-22 and COMM-23 names now match the user-locked decisions (Discord = public marketing surface,
no booking tool). Other issues (COMM-13, 15, 17, 18, 19, 20, 21, 25, 26, 27) keep names.

## Phase 2 - Description rewrite template

```
<h3>What</h3>
<p>One paragraph.</p>

<h3>Why</h3>
<p>Business outcome / dependency / deadline.</p>

<h3>Acceptance criteria</h3>
<ul>
  <li>Specific, testable outcome.</li>
  <li>Specific, testable outcome.</li>
</ul>

<h3>Resolution plan</h3>
<ol>
  <li>Step.</li>
  <li>Step.</li>
</ol>

<h3>Handoff prompt</h3>
<pre>
Context: [what / done / left]
Repo/path: [paths]
Last state: [last commit / deploy / decision]
Next action: [exact next step]
Run: [single command to orient]
</pre>

<p><em>— [Agent: claude-opus-4-7 via Claude Code | 2026-05-18]</em></p>
```

## Phase 3 - Time estimates (human minutes, set via `estimate_point`)

| Issue | Estimate | State |
|---|---|---|
| COMM-10 redirect cleanup | 8 | Done |
| COMM-11 site v1 build | 15 | Done |
| COMM-12 redesign | 25 | Done |
| COMM-13 pricing update | 6 | Done |
| COMM-14 FB URL wiring | 2 | Done |
| COMM-15 OG + SEO | 10 | Done |
| COMM-16 cf-deploy audit | 6 | Done |
| COMM-17 repo extraction | 10 | Open |
| COMM-18 GA4 (dedicated property) | 15 | Open |
| COMM-19 STACKPACK.md update | 15 | Open |
| COMM-20 FB content cadence | 30 | Open (gated on feasibility - see below) |
| COMM-21 Skool workshop calendar | 25 | Open |
| COMM-22 Discord stand-up | 12 | Open |
| COMM-23 DM-flow doc | 8 | Open |
| COMM-24 301 cache comms | 10 | Open |
| COMM-8 ops playbook | 20 | Open |
| **COMM-28 site copy fix** | 5 | Open (new) |
| COMM-25/26/27 epics | 0 | Roll-ups |

## Phase 4 - Resolution plans for open tasks

### COMM-17 - Extract to arc-web/stackpack-site repo
- `git init` in `~/ai/clients/stackpack-site/`
- `.gitignore`: node_modules, .DS_Store, /tmp builds, og-card.png if regenerable
- Minimal `README.md` (stackpack.app link, deploy command, brief)
- `gh repo create arc-web/stackpack-site --private --source . --push`
- **Memory entry (corrected per gap 8)**:
  - Writer: auto-memory system via `memory_organization.md` decision tree
  - Target file: `~/.claude/projects/-Users-home/memory/reference_stackpack_site.md`
  - Type: `reference`
  - Mirror structure of `reference_therappc_site.md` (proven pattern)
  - Evidence required in body: repo URL (`https://github.com/arc-web/stackpack-site`), first commit SHA, deploy command used
  - Index entry to add to `MEMORY.md` under `## Reference` section
  - If automem write fails (token/quota): fall back to manual file create + MEMORY.md index line edit; commit nothing else
- Acceptance: repo private on arc-web, README visible, push works, memory file + MEMORY.md index entry both present and contain repo URL

### COMM-18 - GA4 (dedicated property)
- Create new GA4 property "StackPack" in ARC Google Analytics account (`advertisingreportcard@gmail.com`)
- Web stream for `https://stackpack.app` → copy measurement ID `G-XXXXXXXXXX`
- Store ID: OpenBao `secret/shared/stackpack-ga4-measurement-id` field `value` (KV v2)
- Mirror to 1P ARC vault as item "StackPack GA4 - Measurement ID"
- Inject gtag.js in `<head>` of `index.html` before `</head>`
- `cf-deploy update stackpack`
- Verify: open page, GA4 Realtime within 30s
- Acceptance: dedicated property exists, ID stored in OpenBao + 1P, Realtime shows pageview, cf-deploy lint INFO cleared

### COMM-19 - STACKPACK.md update in portfolio repo
- Pull `arc-web/portfolio`
- Rewrite pricing section: $0 FB / $27/mo Skool / $270/yr Skool with Discord DM + invite + workshops
- Update FB link to `facebook.com/groups/676156638441781`
- Drop founding-tier language
- Drop Cal.com / booking-tool references (don't introduce them in first place)
- Commit + push
- Acceptance: GitHub renders STACKPACK.md cleanly, pricing matches live site, no founding lingo, no booking-tool references

### COMM-20 - Facebook content cadence via GoHighLevel Social Planner API

**Path chosen:** GHL Social Planner API (verified 2026-05). GHL exposes FB Groups as first-class destination, not a toggle on Page posts. Skips Meta Graph API deprecation pain entirely.

**Prerequisites:**
1. StackPack FB Page exists ✅ (user confirmed) - Group will be linked to it
2. Mike or Oliver has admin role on the FB Group
3. "Lead Connector" app authorized as a Facebook app for the Group (one-time, inside FB Group settings)
4. GHL plan with API access ($297+ Pro/Agency tier) on the StackPack sub-account

**GHL Auth - REUSE existing tokens (verified after inventory lap):**

Pre-existing infra not to recreate:
- **PIT in 1P ARC**: `GHL PIT - gohighlevel_mcp` (item `7xqrb7z6m3mpnlrzjdpj6l3efu`) - 1 week old, was created for `gohighlevel_mcp` MCP server. Verify scopes cover Social Planner before reuse; if missing scopes, regenerate at agency level rather than create new.
- **Agency token in 1P Zeroclaw**: `GHL - DigitalAccessPartner - Agency Token` (item `ydy2he7d4vss5vmadt7ofo3jd4`) - 2 weeks old
- **Existing GHL tooling**: `~/ai/platforms/ghl-toolkit` (520+ tool MCP server) + `~/ai/platforms/mcp_tools/servers/gohighlevel_mcp` + `~/ai/platforms/GoHighLevel-MCP` + `arc-mcp-server/src/integrations/gohighlevel.js`
- **Auth skill**: `~/ai/platforms/ghl-toolkit/autocli/skills/ghl-auth` (canonical pattern, follow it)
- **Workflow skill**: `~/ai/platforms/ghl-toolkit/autocli/skills/ghl-workflow-builder`

Step 1 - verify existing PIT covers Social Planner scopes:
- Read `~/ai/platforms/ghl-toolkit/autocli/skills/ghl-auth/SKILL.md` to confirm canonical scope list and PIT vs OAuth decision rule
- Probe `/social-media-posting/{anyExistingLocationId}/posts/list` with current PIT
- If 200: reuse as-is
- If 403/scope-denied: extend scopes in agency settings, regenerate, update OpenBao

Step 2 - store/confirm canonical secret paths:
- `secret/shared/ghl-agency-pit` field `value` = the PIT (single source of truth across all agents)
- `secret/locations/stackpack-ghl` fields `location_id`, `fb_group_account_id`, `fb_page_account_id`
- Both 1P items remain as emergency fallbacks per `credentials_architecture.md`

Step 3 - document both auth modes (user request "cover both to avoid future walls"):
- Agency PIT = preferred, cross-account
- Sub-account OAuth = fallback if any endpoint becomes sub-account-token-only
- Decision rule for scripts: try PIT first, fall back to OAuth refresh-token flow on 403/scope-denied, log the endpoint that required it
- Memory entry to consolidate: `reference_ghl_api.md` (new) covering canonical PIT location, fallback OAuth pattern, Social Planner endpoint list, rate limits, existing tooling map (`ghl-toolkit`, `gohighlevel_mcp`, etc.)

**Setup (one-time, in order):**
1. In FB: confirm StackPack Page, link StackPack Group to Page (Page → More → Link Group → select Group → confirm)
2. In FB Group settings: add Lead Connector as authorized Facebook app
3. In GHL Agency: provision/confirm StackPack sub-account (separate from ARC; see "Sub-account choice" below)
4. In GHL StackPack sub-account → Social Planner → Settings → "Connect a new Facebook Group and Page" → authorize Lead Connector → select StackPack Group + Page
5. In GHL Agency Settings → API → Private Integrations: create token "StackPack + Communities Automation" with above scopes
6. Retrieve `accountId`s for Page + Group via `GET /social-media-posting/{locationId}/oauth/facebook/accounts` (or `get-facebook-page-group/` endpoint)
7. Store credentials in OpenBao:
   - `secret/shared/ghl-agency-pit` → `value` = PIT
   - `secret/locations/stackpack-ghl` → `location_id`, `fb_group_account_id`, `fb_page_account_id`
8. Mirror to 1P ARC vault (item "GoHighLevel - Agency PIT" + item "StackPack GHL Location")
9. Add memory entry `reference_ghl_api.md` covering: agency vs sub-account auth, PIT scopes, Social Planner endpoints, rate limits, location lookup pattern

**Automation flow:**
- Python script (or n8n) loops over content calendar entries
- Calls `POST /social-media-posting/{locationId}/posts` with body containing both `accountId` values (Page + Group) in destinations + scheduledAt timestamp
- Respects 10 req / 10s rate limit (sleep 1.1s between calls)
- Bulk-schedule 12 weeks of posts in one run

**Content calendar (Plane page under COMM):**
- 12 weeks, 3 post types: Highlight, Teardown teaser, Question thread
- Schedule: Mon 10am ET / Wed 1pm ET / Fri 11am ET
- First post: pinned welcome linking Skool community

**Risks logged in description:**
- GHL Social Planner abstracts Meta Graph API - if Meta breaks Groups posting upstream, our flow breaks too. GHL has historically updated within days.
- Group posts identify as the linked Page, not as Mike or Oliver personally. Acceptable for brand voice.
- Rate limits per location: 10 req / 10s. Bulk scheduling of 36 posts (12 weeks × 3) finishes in ~10s with mandated sleep.

**Acceptance:**
- StackPack FB Page exists + Group linked to it
- Lead Connector authorized as Group app
- GHL location has both Page + Group connected (verified via `get-facebook-page-group` returning both `accountId`s)
- 12-week content calendar drafted in Plane page
- Python automation script committed to `~/ai/clients/stackpack-site/scripts/ghl_social_scheduler.py` (or chosen location)
- First batch of 4 weeks scheduled in GHL (visible in GHL Social Planner UI + retrievable via `posts/list` API)
- First scheduled post lands successfully in both Page + Group at scheduled time

### COMM-21 - Skool workshop calendar (8 weeks)
- 8 topics, 1 per Tue or Fri, mapped to 5 pillars:
  - Wk1: GHL custom field schemas (CRM Dev)
  - Wk2: n8n error handling + retry (Workflow Opt)
  - Wk3: Google Ads account hierarchy (Ads)
  - Wk4: Claude Code + MCP intro (AI Integration)
  - Wk5: Email automation deliverability (Marketing Auto)
  - Wk6: Docs-as-code SOPs (Business Systems)
  - Wk7: Meta creative testing framework (Ads)
  - Wk8: Cost-aware AI agent design (AI Integration)
- Owners assigned (Mike, Oliver, or guest)
- 2-sentence description per workshop
- Post to Skool calendar with Zoom or Riverside link
- Acceptance: 8 calendar entries with owner/time/description; first workshop pinned in Skool feed

### COMM-22 - Embed StackPack Discord invite (server already exists)

**Reality check (after full inventory lap):** StackPack Discord is LIVE.
- Guild ID: `1392196836378542162`
- Bot: `StackPack.app` (id `1492471281319415949`)
- 20 members (16 human as of 2026-04-11), 14+ channels organized COMMUNITY / BUILDS & AGENTS / TOOLS / AGEX
- Bot token already at OpenBao `secret/shared/discord-stackpack`, 1P fallback `Discord Bot Token - StackPack.app`
- Soul/voice doc at `~/ai/agents/comms/discord_agent/souls/stackpack_soul.md`
- discord_agent CLI fully wired: `discord.sh -s stackpack`, `community_ops.py --server stackpack`, `discord_report.py --server stackpack`

**Concrete launch scope (narrowed):**
- Generate permanent invite link from `#general` channel (or pick a welcome channel) via `discord_api.py` or Discord UI
- Store invite URL at OpenBao `secret/shared/stackpack-discord-invite` field `value` + mirror to 1P ARC
- Embed invite in 3 surfaces:
  - `stackpack.app` footer (edit `~/ai/clients/stackpack-site/website_v3/src/index.html`, redeploy via cf-deploy)
  - Skool yearly welcome thread
  - FB group pinned post
- Optional polish: confirm `#welcome` or `#intros` is set as the landing channel for new invitees
- Optional polish: rename or tweak channels to match new public marketing message if needed (use `community_ops.py channels rename --server stackpack`)

**Out of scope (deferred):**
- New channels - existing structure is sufficient
- Role-based gating - public invite is fine until volume warrants
- Skool → Discord webhook role provisioning

**Acceptance:**
- Permanent invite URL stored at OpenBao + 1P
- Invite live in 3 surfaces (footer, Skool, FB)
- New visitor can click invite → land in StackPack server with default-channel access

### COMM-23 - Document Discord DM flow for yearly 1-on-1s
- Skool yearly welcome thread: "Yearly member? DM @mike or @oliver on Discord with 3 lines: your stack, your biggest blocker, your desired outcome from 30 min."
- Update stackpack.app pricing yearly bullet: replace "1-on-1 strategy call with our team" → "Direct DM access to Mike + Oliver on Discord for 1-on-1 strategy"
- Update FAQ entry "What do I get with yearly" to match
- Redeploy via `cf-deploy update stackpack`
- Acceptance: Skool welcome thread documents flow; live site pricing + FAQ updated; no Cal.com / Calendly artifacts anywhere

### COMM-24 - Hard-reload guidance for cached 301 visitors
- Skip on-site banner per user decision
- Draft short post: "If stackpack.app keeps redirecting to skool.com - hard reload (Cmd+Shift+R / Ctrl+Shift+R) or open in a private window. Browser cached our old redirect. Should clear within a few days."
- Publish: FB group (pinned 14 days), Skool announcement (pinned 14 days), LinkedIn note from Mike, Discord `#announcements`
- Acceptance: post live in 4 channels, pinned on FB + Skool for 14 days

### COMM-8 - StackPack community ops playbook
- Plane page under COMM project: "StackPack - Ops Playbook"
- Sections:
  - Channel ownership matrix
  - Posting rituals (Mike Mon strategy, Oliver Wed tooling, member showcase Fri)
  - Office hours roster (Tue + Fri, rotating owners)
  - Member onboarding script (Day 1 / Day 7 / Day 30)
  - Removal criteria (selling without value, repeat off-topic, harassment)
  - Cross-posting rules (FB highlight → Skool, never reverse)
- Acceptance: Plane page exists, linked from COMM-27 epic, Mike + Oliver review + sign off

### COMM-28 (NEW) - Site copy + FAQ fix: yearly perk = Discord DM
- Edit `~/ai/clients/stackpack-site/website_v3/src/index.html`:
  - Pricing yearly tier bullet: "1-on-1 strategy call with our team" → "Direct DM access to Mike + Oliver on Discord for 1-on-1 strategy"
  - FAQ "What do I get with yearly": rewrite to mention Discord DM access + invite, drop call language
- `cf-deploy update stackpack`
- Acceptance: live site shows updated copy, FAQ matches, cf-deploy lint passes

## Phase 5 - Execution batch (corrected)

Single Python script. Run order: Phase 0 snapshot → Phase 1 PATCH (renames) → Phase 2/3/4 PATCH
(description + estimate, plus the per-issue resolution plan embedded in description) → POST new
COMM-28 → link COMM-28 to module + cycle + parent → comments on done tasks.

**Auth (corrected per gap 4):**
- OpenBao direct is canonical. Fetch Plane key from `vault.aibrainbuilders.com` (per `reference_plane_api.md` line 18-26 - new vault host) via `claude-code-local` AppRole.
- If OpenBao fails: **diagnose first** (DNS? AppRole expired? path moved?), then declare in plan output: `⚠ EMERGENCY FALLBACK: OpenBao [host] [reason] - using 1P. Needs fixing.`
- Only after declaration: 1P fallback via `op item get x7qhfdaos76fcymuztjjscmrpa --vault Zeroclaw --reveal --fields credential`
- Do NOT silently fall back.

**Rate-limit handling (NEW per gap 5):**
- Sequential PATCH only (no parallel)
- `time.sleep(0.15)` between calls (~6.5 req/s, well below typical Plane CE thresholds)
- Wrap each call in retry loop:
  - On 429: read `Retry-After` header, sleep that many seconds + 0.5, retry once
  - On 5xx: exponential backoff (1s, 2s, 4s, max 3 retries)
  - On other non-2xx: abort the batch, dump snapshot path + remaining work to console
- Track per-call success/fail in a list; print summary at end: `N patched / M failed`
- If any fail: print rollback command using snapshot path

**Execution order:**
1. Phase 0 snapshot (read-only) → write JSON to `~/.claude/plans/snapshots/`
2. Sanity: re-read snapshot, confirm 19 entries, confirm all UUIDs non-null
3. PATCH each issue: `name` (where renamed), `description_html` (rewritten template), `estimate_point` (minutes)
4. POST COMM-28 with full description + estimate; capture returned UUID
5. PATCH COMM-28: set `parent` to COMM-26 epic UUID
6. POST `/modules/{stackpack_module_id}/module-issues/` to link COMM-28 to StackPack module
7. POST `/cycles/{member_tier_cycle_id}/cycle-issues/` to link COMM-28 to Member Tier Buildout cycle
8. Add comments to 7 done tasks (COMM-10..16) with actual outcomes + links (commits, deployed URLs); each comment ends with attribution line

## Phase 6 - Verification via API (corrected per gap 6)

All read-only API calls. No UI assumptions.

1. `GET /issues/?per_page=100` filtered to stackpack issues:
   - Every issue has `description_html` containing both `Handoff prompt` and `[Agent: claude-opus-4-7`
   - Every issue has `estimate_point > 0` (epics may be 0 explicitly)
   - Renamed issues: `name` matches Phase 1 table
2. `GET /modules/{stackpack_module_id}/module-issues/` → confirm all 20 issues (19 + COMM-28) listed
3. For each cycle (Website Redesign, Member Tier Buildout, Launch Ops): `GET /cycles/{id}/cycle-issues/` → confirm correct issue UUIDs present
4. For each child issue (COMM-10..24, 28): `GET /issues/{id}/` → confirm `parent` field matches expected epic UUID (25/26/27)
5. For COMM-28: confirm UUID present in COMM-26 cycle, StackPack module, parent = COMM-26 epic
6. Print pass/fail per check; on any fail, print exact issue/expectation/actual

## Critical files

- Plane API (live) - all writes via `arc.todovibes.com/api/v1/...`
- `~/.claude/plans/snapshots/stackpack_pre_cleanup_2026-05-18.json` - rollback artifact
- `~/.claude/plans/stackpack_plane_cleanup_v2.md` - this plan
- Post-execution (per resolution plans):
  - `~/ai/clients/stackpack-site/` (COMM-17 repo extraction)
  - `~/ai/clients/stackpack-site/website_v3/src/index.html` (COMM-18 GA4, COMM-28 copy fix)
  - `arc-web/portfolio/STACKPACK.md` (COMM-19)
  - `~/.claude/projects/-Users-home/memory/reference_stackpack_site.md` (COMM-17 memory)
  - New Plane page under COMM (COMM-8)

## Reused patterns

- `~/.claude/skills/plane-pm/SKILL.md` - canonical Plane patterns
- `~/.claude/projects/-Users-home/memory/feedback_plane_task_fields.md` - field criteria
- `~/.claude/projects/-Users-home/memory/reference_plane_api.md` - API endpoints, auth (new `vault.aibrainbuilders.com` host)
- `~/.claude/projects/-Users-home/memory/credentials_architecture.md` - OpenBao-first, declared fallback
- `~/.claude/projects/-Users-home/memory/memory_organization.md` - memory routing (for COMM-17)
- `~/.claude/projects/-Users-home/memory/reference_therappc_site.md` - template for `reference_stackpack_site.md`
- `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js` - deploy + lint + SEO
- `~/.claude/skills/credentials/SKILL.md` - 1P / OpenBao patterns

## User-confirmed inputs (locked 2026-05-18)

1. GA4: new dedicated property for stackpack.app under ARC account
2. Discord: own StackPack Discord, public invite for launch (no gating yet)
3. Booking: none, Discord DM only
4. 301 banner: skip, social posts only

## User-confirmed inputs round 2 (2026-05-18)

1. ✅ Vault host: `vault.aibrainbuilders.com`
2. ✅ FB posting: **GoHighLevel Social Planner API** (not Meta Graph API direct, not Meta Business Suite manual). GHL exposes FB Groups as first-class destination.

## Sub-account choice for StackPack (locked per user direction: "cover both")

User decision: document both auth modes regardless. Sub-account dimension still needs picking because GHL Social Planner connections live inside one sub-account, not at agency level.

Options:
- A) New dedicated StackPack sub-account (clean separation, costs one slot, isolates Social Planner views and analytics)
- B) Reuse existing ARC sub-account (no new slot, but ARC + StackPack socials mix in one Social Planner)
- C) Reuse another existing sub-account (e.g. exitstorm) - same tradeoff as B with different mixing

Either way, agency PIT works across all of them.

## Open questions still needing answer before Phase 5

1. **GHL sub-account for StackPack social connections** - A / B / C above. Affects `locationId` stored in OpenBao + downstream automation reference.
2. **StackPack Discord state** - does the server exist already, or does COMM-22 include creating it? Determines whether COMM-22 = "collect invite + embed" or "create server + channels + invite".

## Plan file naming

This file is at `stackpack_plane_cleanup_v2.md`. The harness-generated slug
`rippling-inventing-spark.md` is unused. If the harness wrote one, it will be removed post-approval
by `git mv` or `rm`.
