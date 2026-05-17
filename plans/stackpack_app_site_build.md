# stackpack.app - Single-Page Marketing Site Build

## Context

StackPack is a Skool community for working professionals (marketing automation, CRM, AI integration, dev, ops). Domain `stackpack.app` confirmed active on Cloudflare (zone `f3120fe759485b31cea91094ec97de8e`), no R2 site deployed yet. Source content lives in `arc-web/portfolio/STACKPACK.md` (~6000 words of mission, offerings, tiers, focus areas). Goal: ship a single-page site that reads as written by an operator, not by ChatGPT - tight, opinionated, specific - and routes visitors to the Skool community signup. Build via the existing `cloudflare_agent` + `web-workflow` skill pipeline.

## Anti-AI-slop content rules (enforced on every section)

- No headline starts with "Unlock", "Transform", "Empower", "Revolutionize", "Welcome to", "Join the", "Discover".
- No three-adjective stacks ("strategic, scalable, sustainable").
- No "we believe", "we're passionate about", "in today's fast-paced world".
- No emoji headers.
- Every claim names a specific tool, role, outcome, or number - never abstractions alone.
- Sentences mix lengths. Fragments OK. No paragraph longer than 3 sentences.
- Pain points written as the visitor would think them ("Your n8n workflow broke at 2am and nobody on Reddit knows GHL"), not as a marketer would describe them ("Common challenges in workflow automation").
- No "Join today" CTA copy. CTAs name the action ("See what's inside the community", "Read the founding member terms").
- Hero subhead reads like a sentence the user would say in a call, not a slogan.

## Site scope - single page, deep

One page (`index.html`), seven sections, no nav menu (anchor jump only):

1. **Hero** - one-line positioning + one-line proof + CTA to Skool. No carousel, no gradient mesh background. Plain background, strong typography.
2. **Who this is for** - four named roles with one specific frustration each. Not buckets - frustrations:
   - Developer building integrations alone, no one to review your GHL custom field schema
   - Marketing operator who can write a campaign but not the Zap that fires it
   - Operator running a 6-person team, drowning in Notion templates that nobody follows
   - Founder shipping a SaaS, needs honest review not LinkedIn applause
3. **What you get** - four blocks, plain English, no bullet salad:
   - Strategy: tear-downs of your stack with people who've actually shipped it
   - Education: workshops on n8n, GHL, Claude Code, MCP - recorded, searchable
   - Advertising guidance: Google Ads + Meta playbooks from people running real spend
   - AI guidance: when to use Claude, when to use Gemini, what to skip
   - Dev guidance: code review, MCP server help, integration patterns
5. **Why we built this** - co-founder note from Mike + Oliver. "We" voice (community itself is full of leaders, the "we" is honest). Names the gap: most "communities" are link dumps + AMAs with people who haven't built anything in 5 years. StackPack is the inverse. Signed `- Mike + Oliver, co-founders`.
6. **What it costs** - Free tier + Pro $97/mo + Founding member (limited). No "limited time only!!!" - state the actual cap.
7. **What happens after you join** - 4 steps, named days not vague timelines. "Day 1: intro thread + skill tags. Day 3: matched to active project if interested. Day 7: first office hours."
8. **CTA block** - one button to Skool signup. One sentence under it stating what isn't included if they're not ready ("If you're looking for free tutorials, our YouTube has those - link below").

Footer: minimal. Domain, contact email, links to Skool, GitHub org, YouTube.

## Visual direction

- Palette: dark neutral background (`#0F0F1A` matches existing portfolio badge), one accent (purple `#7B2FBE` already in portfolio branding) - kept consistent with arc-web/portfolio presentation badge so the brand reads as one company.
- Typography: Inter for body (system-safe, no rendering surprises), JetBrains Mono or IBM Plex Mono for code/technical accents (the audience reads code daily, the font signals it).
- No stock photos. No 3D mesh gradients. No animated blobs. Subtle scroll reveals only (already in `web-effects.md`).
- One illustration max: a simple SVG diagram showing "your stack -> community review -> shipped". Hand-drawn feel, not corporate flat.

## Implementation - exact steps

### Step 1 - Directory + audience prep
Create `~/ai/clients/stackpack-site/website_v3/src/`. Skip Phase 1 of web-workflow (audience research) since user-defined content + voice is already locked in STACKPACK.md and this plan. Note palette/font choices in `BRIEF.md` next to src.

### Step 2 - Build `index.html`
Single self-contained file. Inline CSS via `:root` tokens block. Vanilla JS (no React, no build step). Reference components from `~/.claude/skills/web-components/SKILL.md` only for layout primitives (hero, feature grid, CTA banner) - rewrite all copy. Use scroll reveal pattern from `web-effects.md`. Use form components only for the final CTA (no form, just button - signups go to Skool, not us).

### Step 3 - SEO + schema
Run `cf-deploy schema inject` with `--type website --name "StackPack" --url https://stackpack.app`. Add `<meta name="description">` (one sentence, plain). OpenGraph card: simple text-on-color, 1200x630, no AI art.

### Step 4 - Skool signup link
Primary CTA + footer link to `https://www.skool.com/stackpack/about`. `target="_blank"` + `rel="noopener"`. No tracking parameter unless GA4 cross-domain set up later.

### Step 5 - Deploy via cf-deploy
```bash
cd ~/ai/agents/web/cloudflare_agent
node bin/cf-deploy.js deploy ~/ai/clients/stackpack-site/website_v3/src \
  --project stackpack --domain stackpack.app
```
Idempotent. Creates R2 bucket, attaches custom domain, registers in local site registry.

### Step 6 - Post-deploy
- `cf-deploy sitemap stackpack` + `cf-deploy robots stackpack`
- `cf-deploy llms stackpack --title "StackPack" --description "Working community for marketing, automation, AI, and dev professionals"`
- `cf-deploy verify stackpack` to confirm 200 OK
- `cf-deploy open stackpack` for visual review

### Step 7 - Extract to client repo (matches therappc-site pattern)
After live + reviewed:
```bash
cd ~/ai/clients/stackpack-site && git init && git add -A
gh repo create arc-web/stackpack-site --private --source . --push
```
Memory entry added: another instance of the one-site-per-repo pattern.

## Files to be created/modified

- `~/ai/clients/stackpack-site/website_v3/src/index.html` - the page
- `~/ai/clients/stackpack-site/website_v3/src/style.css` - inline preferred, separate if file > 600 lines
- `~/ai/clients/stackpack-site/website_v3/src/og-card.png` - 1200x630 OG image (generated locally, plain text on dark bg)
- `~/ai/clients/stackpack-site/BRIEF.md` - audience, palette, fonts, voice rules
- `~/ai/clients/stackpack-site/.gitignore`

## Reused assets (do not rewrite)

- `~/.claude/skills/web-workflow/SKILL.md` - orchestrator
- `~/.claude/skills/web-components/SKILL.md` - hero/grid/footer primitives
- `~/.claude/skills/web-effects.md` - scroll reveal pattern (load via `~/ai/agents/web/cloudflare_agent/skills/web-effects.md` if global missing)
- `~/.claude/skills/web-security/SKILL.md` - headers worker if needed
- `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js` - deploy + DNS + schema + SEO
- Voice / anti-slop rules from memory: `feedback_no_ai_slop.md`, `feedback_communication_plain.md`

## Verification

- `curl -sI https://stackpack.app` returns `200 OK`
- Open in browser: no AI-tells (no "Unlock", no emoji headers, no 3-adjective stacks, no fake testimonials)
- Skool CTA links to real signup, opens in new tab
- Mobile (375px) - hero readable, CTA reachable without horizontal scroll
- Lighthouse: Performance >= 95, Accessibility >= 95, SEO >= 95
- `cf-deploy verify stackpack` passes
- View `og-card.png` - text-only, on-brand, no AI artifacts

## Out of scope

- No blog (separate build later if needed)
- No member portal, no auth - Skool handles all member-facing flows
- No live chat, no popups, no exit intent
- No analytics setup beyond GA4 measurement ID if user supplies one - skip otherwise (don't fake events)
- No contact form - email link only in footer

## User-confirmed inputs (locked)

1. **Skool signup URL:** `https://www.skool.com/stackpack/about` - used in primary CTA + footer.
2. **GA4:** Pull existing ARC GA4 measurement ID from credential store before deploy. Single property reused across ARC properties.
3. **Founder voice:** Co-founder note from Mike + Oliver. Voice is "we" because the community itself is filled with leaders contributing - the "we" is honest, not corporate. Section title: "Why we built this" (signed `- Mike + Oliver`).
4. **Founding member cap:** State exact number on page. Default to **50 founding seats** unless user names a different cap before build. Counter visual ("X of 50 taken") only if accurate count maintainable - otherwise just "50 founding seats" without a counter (more credible than a fake "47 left" gauge).
