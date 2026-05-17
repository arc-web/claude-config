# StackPack Plane Cleanup + Open-Issue Resolution

## Context

Communities project (COMM) now has 19 stackpack-related issues split across 3 epics (Website Redesign, Member Tier Buildout, Launch Operations) and the StackPack module. Two problems:

1. **Tasks don't meet the documented Plane criteria** (`feedback_plane_task_fields.md`): every issue is missing the **handoff prompt** block, the **attribution line**, and a **time estimate**. Some names are ambiguous, written hastily during creation.
2. **8 open TODOs have no resolution plan**. They list "what" but not "how" or "with what tools". Without a plan they'll sit.

Goal: bring every stackpack task to the Plane standard (full description, handoff prompt, attribution, estimate, clear name), and stage execution-ready plans for every open item so they're one click from `in_progress`.

## Plane criteria recap (`feedback_plane_task_fields.md`)

Every task must have:
- **Name** - action-oriented, unambiguous
- **State** - Backlog / Todo / In Progress / Done / Blocked
- **Description** - what, why, acceptance criteria
- **Module** - StackPack (already linked)
- **Time estimate** - human minutes (scope + review + approve, not agent wall-clock)
- **Handoff prompt block** - ready-to-paste context block
- **Attribution line** on every comment / description update - `— [Agent: claude-opus-4-7 via Claude Code | 2026-05-18]`

## Phase 1 - Rename ambiguous tasks

| Issue | Current name | New name |
|---|---|---|
| COMM-8 | StackPack - define community management workflows | Document StackPack community ops playbook (channels, moderation, weekly rituals) |
| COMM-10 | [StackPack] Cloudflare redirect cleanup - apex + www to skool.com | [StackPack] Remove legacy Cloudflare redirects routing stackpack.app to skool.com |
| COMM-11 | [StackPack] Initial site build - dark/purple single-page, Skool CTA | [StackPack] Site v1 single-page build (superseded by COMM-12 redesign) |
| COMM-12 | [StackPack] Full redesign - Linear/Vercel-style UI + depth | [StackPack] Rebuild stackpack.app as Linear-style multi-section community site |
| COMM-14 | [StackPack] Facebook group URL integration | [StackPack] Wire live Facebook group URL into Free-tier CTA on stackpack.app |
| COMM-16 | [StackPack] cloudflare_agent full toolchain audit | [StackPack] Run cf-deploy full audit (lint, sitemap, robots, llms, seo, dns, verify) |
| COMM-22 | [StackPack] Private Discord channel - provision + access flow | [StackPack] Provision private Discord channel for yearly members + access flow |
| COMM-23 | [StackPack] 1-on-1 strategy call booking system | [StackPack] Set up Cal.com booking page for yearly-tier 1-on-1 strategy calls |
| COMM-24 | [StackPack] Browser 301 cache - communications for early visitors | [StackPack] Publish hard-reload guidance for visitors hitting cached 301 to skool.com |

Others (COMM-13, 15, 17, 18, 19, 20, 21, 25, 26, 27) already clear enough - leave names, only update description.

## Phase 2 - Description rewrite template

Every issue's `description_html` rewritten to this shape:

```
<h3>What</h3>
<p>One-paragraph description of the work.</p>

<h3>Why</h3>
<p>One-paragraph reason - business outcome, dependency, deadline.</p>

<h3>Acceptance criteria</h3>
<ul>
  <li>Specific, testable outcome 1</li>
  <li>Specific, testable outcome 2</li>
  <li>...</li>
</ul>

<h3>Handoff prompt</h3>
<pre>
Context: [what this task is, what's been done, what's left]
Repo/path: [where the code or files live]
Last state: [what was last completed or changed]
Next action: [exact first step to continue]
Run: [command needed to get oriented]
</pre>

<p><em>— [Agent: claude-opus-4-7 via Claude Code | 2026-05-18]</em></p>
```

## Phase 3 - Time estimates (human minutes)

| Issue | Estimate (min) | Notes |
|---|---|---|
| COMM-10 redirect cleanup | 8 | Done; estimate retrospective |
| COMM-11 site v1 build | 15 | Done; superseded |
| COMM-12 redesign | 25 | Done |
| COMM-13 pricing update | 6 | Done |
| COMM-14 FB URL wiring | 2 | Done |
| COMM-15 OG + SEO | 10 | Done |
| COMM-16 cf-deploy audit | 6 | Done |
| COMM-17 repo extraction | 10 | Open |
| COMM-18 GA4 | 15 | Open |
| COMM-19 STACKPACK.md update | 15 | Open |
| COMM-20 FB content cadence | 30 | Open (planning-heavy) |
| COMM-21 Skool workshop calendar | 25 | Open |
| COMM-22 Discord channel + flow | 20 | Open |
| COMM-23 Cal.com 1-on-1 booking | 15 | Open |
| COMM-24 301 cache comms | 10 | Open |
| COMM-8 ops playbook | 20 | Open |
| COMM-25 Website epic | 0 | Roll-up, no direct work |
| COMM-26 Member Tier epic | 0 | Roll-up |
| COMM-27 Launch Ops epic | 0 | Roll-up |

Set via PATCH `estimate_point` field. Estimate-point is Plane's free-form integer field - 1 point = 1 human minute by our convention.

## Phase 4 - Resolution plans for open tasks (paste into description as "Resolution plan" section)

### COMM-17 - Extract to arc-web/stackpack-site repo
- Initialize git in `~/ai/clients/stackpack-site/`
- Write `.gitignore` (node_modules, .DS_Store, /tmp builds)
- Add minimal `README.md` pointing at https://stackpack.app + deploy command
- `gh repo create arc-web/stackpack-site --private --source . --push`
- Add memory entry mirroring `reference_therappc_site.md`
- Acceptance: repo exists, README.md visible at root on GitHub, local push works

### COMM-18 - GA4 measurement ID (dedicated property)
- Create new GA4 property "StackPack" in the ARC Google Analytics account (advertisingreportcard@gmail.com)
- Add Web data stream for `https://stackpack.app`, copy measurement ID `G-XXXXXXXXXX`
- Store ID in OpenBao at `secret/shared/stackpack-ga4-measurement-id` + mirror to 1P ARC vault
- Insert standard gtag.js snippet in `<head>` of `index.html` (before closing `</head>`)
- `cf-deploy update stackpack`
- Verify: open page, check Realtime in GA4, confirm hit lands
- Acceptance: dedicated StackPack GA4 property exists; Realtime shows stackpack.app pageview within 30s; cf-deploy lint no longer flags GA4 INFO

### COMM-19 - STACKPACK.md update in portfolio repo
- Clone or pull `arc-web/portfolio`
- Rewrite `STACKPACK.md` pricing section: $0 FB / $27 monthly Skool / $270 yearly Skool with 1-on-1 + Discord
- Update FB group link to live URL `facebook.com/groups/676156638441781`
- Drop founding-tier language
- Keep mission, focus areas, tech stack intact
- Commit "Update StackPack pricing model + FB group URL" + push
- Acceptance: portfolio README badge "StackPack" page reflects new tiers; renders in GitHub UI without errors

### COMM-20 - Facebook group content cadence + automation
- Draft 12-week content calendar in a Plane page under COMM project (3 post types: Highlight, Teardown teaser, Question thread)
- Pin a welcome post linking to Skool (template in description)
- Wire automation: Skool RSS → n8n flow → FB Graph API post (needs FB Page token in OpenBao at `secret/shared/facebook-graph-token`)
- Set posting schedule (e.g. Mon/Wed/Fri 10am ET)
- Acceptance: 12 posts drafted in calendar; n8n flow live + tested with 1 manual trigger; first cross-post visible on FB group; FB welcome post pinned

### COMM-21 - Skool workshop calendar (first 8 weeks)
- Pick 8 topics, 1 per Tue or Fri, each mapped to one of the 5 pillars:
  - Wk1: GHL custom field schemas that don't break (CRM Dev)
  - Wk2: n8n error handling + retry patterns (Workflow Optimization)
  - Wk3: Google Ads account hierarchy from scratch (Ads)
  - Wk4: Claude Code + MCP server intro (AI Integration)
  - Wk5: Email automation that doesn't get filed as spam (Marketing Automation)
  - Wk6: Docs-as-code SOPs (Business Systems)
  - Wk7: Meta creative testing framework (Ads)
  - Wk8: Cost-aware AI agent design (AI Integration)
- Assign owners per workshop (Mike, Oliver, or guest member)
- Write 2-sentence description per workshop
- Post all 8 to Skool calendar with Zoom/Riverside link
- Acceptance: 8 calendar entries in Skool with owner, time, description; first workshop also pinned in Skool community feed

### COMM-22 - StackPack Discord server (marketing surface for now)
- User decision: StackPack will eventually have its own Discord where all users land. For launch, the Discord is **a marketing claim on the site** rather than a fully gated yearly perk.
- Concrete launch scope:
  - Confirm StackPack Discord server exists (create if not)
  - Set up invite link, embed in Skool yearly welcome thread + Facebook pinned post
  - Public for now; gating to be added when yearly volume justifies it
  - Add `discord.gg/<invite>` to stackpack.app footer
- Acceptance: StackPack Discord server live with public invite; invite link present in Skool welcome thread, FB pinned post, and site footer
- Out of scope (deferred): role-gated channels, Skool → Discord webhook role grant, automated provisioning

### COMM-23 - 1-on-1 access via Discord DM (no booking tool)
- User decision: no Cal.com / Calendly. Yearly members message Mike or Oliver directly on Discord to schedule.
- Concrete scope:
  - Document the DM flow in Skool yearly welcome thread ("Yearly member? DM @mike or @oliver on Discord with 3 lines: your stack, your biggest blocker, the outcome you want from 30 min")
  - Update site copy (Pricing tier yearly bullet) from "1-on-1 strategy call with our team" to "Direct DM access to Mike + Oliver on Discord for 1-on-1 strategy"
  - Update FAQ entry "What do I get with yearly" to match
- Acceptance: Skool welcome thread documents DM flow; stackpack.app pricing + FAQ updated and redeployed; no booking tool created

### COMM-24 - Hard-reload guidance for cached 301 visitors
- User decision: skip on-site banner. Social posts only.
- Draft short post: "If stackpack.app keeps redirecting to skool.com - hard reload (Cmd+Shift+R / Ctrl+Shift+R) or open in a private window. Browser cached our old redirect. Will clear within a few days."
- Post to: Facebook group (pinned 14 days), Skool announcement, brief LinkedIn note from Mike, Discord announcement
- Acceptance: post live in 4 channels; ≥ 14-day pin on FB and Skool

### COMM-8 - StackPack community ops playbook
- Document in a Plane page under COMM project: `StackPack - Ops Playbook`
- Sections:
  - Channel ownership matrix (who moderates what)
  - Posting rituals (Mike Mon strategy thread, Oliver Wed tooling thread, member showcase Fri)
  - Office hours roster (Tue + Fri, rotating owners)
  - Member onboarding script (Day 1 / Day 7 / Day 30 touchpoints)
  - Removal criteria (selling without value, repeat off-topic, harassment)
  - Cross-posting rules (FB highlight → Skool, never the reverse)
- Acceptance: Plane page exists, linked from epic COMM-27; Mike + Oliver review + sign off

## Phase 5 - Execution batch

Single Python script via plane-pm pattern (1P fallback for vault DNS), one PATCH per issue:
- `name` (where renamed)
- `description_html` (rewritten with What/Why/Acceptance/Handoff/Attribution)
- `estimate_point` (minutes)

Add comments on the 7 done tasks (COMM-10..16) summarizing actual outcome + linking commits where applicable, each ending with attribution line.

## Critical files to modify

- Plane issues (live API) - no local file edits, all via `arc.todovibes.com/api/v1/...`
- `~/.claude/plans/stackpack_plane_cleanup_and_resolution.md` (this plan, only file allowed to edit pre-approval)

After execution:
- `~/ai/clients/stackpack-site/` (for COMM-17 repo extraction)
- `~/ai/clients/stackpack-site/website_v3/src/index.html` (GA4 injection for COMM-18)
- `arc-web/portfolio/STACKPACK.md` (COMM-19 update)
- New Plane page under COMM for COMM-8 (ops playbook)

## Reused patterns / paths

- `~/.claude/skills/plane-pm/SKILL.md` - canonical Plane CLI pattern + auth
- `~/.claude/projects/-Users-home/memory/feedback_plane_task_fields.md` - task field criteria
- `~/.claude/projects/-Users-home/memory/reference_plane_api.md` - API quick ref
- `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js` - deploy/lint/SEO/audit for COMM-17, 18
- `~/ai/agents/comms/discord_agent/` - role grant + webhook integration for COMM-22
- `~/.claude/skills/credentials/SKILL.md` - 1P / OpenBao patterns for FB token, GA4 OAuth, Discord token

## Verification

After cleanup + execution:
1. `curl ... /issues/?per_page=100` and confirm every stackpack issue has `description_html` containing both `Handoff prompt` and `[Agent:`
2. Same query confirms `estimate_point` is set on all 19 issues
3. Open Plane UI: navigate to COMM project → StackPack module → confirm 3 cycles each show their epic + children with no orphans
4. For each renamed task: confirm new name appears in UI
5. For each Phase 4 resolution plan: confirm "Resolution plan" section visible inside description

## User-confirmed inputs (locked 2026-05-18)

1. **GA4**: Create new dedicated GA4 property for stackpack.app under ARC account.
2. **Discord**: StackPack runs its own Discord server (future home for all users). For launch, used as a marketing claim on the site - public invite link, no role-gated channels yet.
3. **Booking tool**: None. Yearly members DM Mike or Oliver on Discord directly. Update site copy + FAQ to match.
4. **301 banner**: Skip. Social posts to FB, Skool, LinkedIn, Discord only.

## Additional task spawned by user input

**COMM-28 (new)** - "[StackPack] Update site copy + FAQ: yearly perk = Discord DM access (not Cal.com booking)"
- One-line edit in pricing tier + FAQ entry on stackpack.app
- Redeploy via cf-deploy update
- Estimate: 5 min
- Cycle: Member Tier Buildout
- Parent: COMM-26 epic
