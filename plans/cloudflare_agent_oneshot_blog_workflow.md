# cloudflare_agent - One-Shot Site + Blog Workflow

## Context

This session built therappc.com v3 from scratch and exposed every gap in the current cloudflare_agent process: wrong palette defaults from incomplete tooling, no CRO layer in the audit process, no analytics setup skill, no blog capability, no documented end-to-end workflow. The goal is to close all gaps so any future client site - including a blog - can be executed in one session without rediscovery.

---

## What We Have (verified this session)

### cf-deploy capabilities (bin/cf-deploy.js)

- `deploy <source>` - creates R2 bucket, uploads, attaches domain, adds CNAME
- `update <name> --source <path>` - re-uploads files, purges cache
- `--path <prefix>` - deploys to a subdirectory (e.g. `--path blog` → `domain.com/blog/`)
- Built-in: sitemap generation, SEO audit, schema builders, llms.txt, robots.txt
- `launch-site.js` - separate CLI (TBD - check what this does)

### Existing skills in cloudflare_agent/skills/

| Skill | What it covers |
|---|---|
| web-audience.md | Archetypes, palette selection, therapy matrix, form conversion data, competitor research step (NEW today) |
| web-design.md | Design tokens, named palettes (Warm/Gold + Therapist/Sage), typography rationale |
| web-components.md | Nav, hero, feature cards, testimonials, pricing, stats, CTA, footer - copy-paste HTML blocks |
| web-forms.md | Form CSS, 10 components (base, validation, multi-step, rating, modal, exit intent, etc.) |
| web-effects.md | Animations, AOS, vanilla-tilt, anime.js |
| web-logos.md | Logo treatment, Simple Icons CDN pattern |
| web-pricing.md | Pricing page patterns |
| web-security.md | Security headers, CSP setup |
| web-worker.md | Cloudflare Worker templates (security-headers, lead-proxy) |

### Skills NOT YET IN cloudflare_agent/skills/ (gap)

- **web-blog.md** - does not exist
- **web-analytics.md** - does not exist
- **web-content.md** - does not exist

### page-review/SKILL.md (in arc-web/claude-skills)

Step 3b CRO conversion audit layer added today. Covers: CTA above fold, form fields, CTA copy, trust signals, analytics, mobile tap targets.

---

## Gaps Found This Session (documented for the record)

1. **Only Warm/Gold had full CSS tokens** in web-design.md → agent always defaulted to it. Fixed: Therapist/Sage added, web-audience.md now has full token set for each named palette.
2. **No competitor research step** before palette selection. Fixed: Step 0 added to web-audience.md.
3. **Therapy treated as monolithic** - no sub-categories. Fixed: therapy matrix added.
4. **No CRO audit layer** in page-review. Fixed: Step 3b added.
5. **No GA4 skill** - analytics is a manual "ask the client" step with no template.
6. **No blog skill** - no documented pattern for adding a blog to these sites.
7. **No end-to-end workflow document** tying all skills together in order.
8. **No version control for client work** - `clients/` was untracked until today.
9. **Index form had 6 fields** - should be 3 per our own CRO research (fixed today).
10. **No accessibility landmarks** on any page - no `<main>`, `<header>`, skip-nav, favicon (fixed today).

---

## The One-Shot Workflow (to be documented as web-workflow.md)

### Inputs required before starting

- Client name + domain
- Target audience (brief description)
- Primary CTA goal (book a call / get a quote / sign up / buy)
- GA4 measurement ID (ask client - can't deploy analytics without it)
- Brand colors if they exist (or use palettes from web-audience.md)

### Phase 0 - Verify directory structure

```
clients/<clientname>/
  website_v1/src/   ← original if it exists
  website_v1/workers/
  website_v2/src/   ← previous live version
  website_v3/src/   ← working version (always v+1 from live)
  website_v3/workers/
```

First deploy: skip v1/v2, start at v3.

### Phase 1 - Audience Research (web-audience.md)

1. Step 0: research 5 real competitor sites in exact niche (not archetype broadly)
2. Identify archetype: Care Seeker / Builder-Operator / Consumer
3. If Care Seeker: check therapy sub-category matrix for positioning row
4. Pick palette + typography from match (do NOT default to Warm/Gold without research)
5. Confirm: palette, heading font, body font, primary CTA color

### Phase 2 - Site Build (web-design.md + web-components.md + web-effects.md)

Pages to build per standard client site:
- `index.html` - homepage (hero, proof, how it works, results, contact form)
- `pricing.html` - pipeline calculator + 4-field lead form (name, practice, email, phone)
- `results.html` - case studies / proof page
- `pipeline-calculator.html` - standalone calculator

For each page:
- Apply `:root` token block from chosen palette
- Add Google Fonts import for chosen typography
- Add `<header>`, `<main id="main-content">`, `<footer>` landmarks
- Add skip-nav link before `<header>`
- Add SVG favicon inline: `<link rel="icon" href="data:image/svg+xml,...">`
- Add GA4 snippet in `<head>` (requires measurement ID)

### Phase 3 - Forms (web-forms.md)

- Top-of-funnel contact form: **3 fields max** (name + email + one qualifying question)
- Lead capture after calculator: **4 fields** acceptable (name, practice, email, phone - warmer lead)
- CTA button copy: first-person or action-specific - **never "Submit"**
- Multi-step if > 3 fields needed
- Include honeypot field

### Phase 4 - Blog Setup (web-blog.md - NEW SKILL)

Blog lives inside `src/blog/`:
- `src/blog/index.html` - post listing page
- `src/blog/post-slug.html` - individual post pages
- No build tool needed - Claude writes HTML directly using the site's design tokens

Deploy is automatic - `cf-deploy update` picks up `blog/` as part of `src/`.

Post writing workflow (one-shot per post):
1. User provides topic + key points (2-3 sentences)
2. Claude writes full post as HTML using site tokens
3. Claude adds to `blog/index.html` card listing
4. `cf-deploy update <client> --source clients/<client>/website_v3/src`

### Phase 5 - Analytics (web-analytics.md - NEW SKILL)

GA4 setup:
- Snippet in `<head>` on all pages
- CSP must whitelist `googletagmanager.com` and `google-analytics.com` (security-headers worker handles this)
- Events to track: form submit (custom event), CTA clicks (if using GTM), calculator interactions
- If client has GTM: use GTM snippet instead, fire GA4 through it

### Phase 6 - Workers (web-worker.md)

Two workers per client site (already templated):
- `workers/security-headers/` - adds HSTS, CSP, X-Frame-Options, Permissions-Policy
- `workers/lead-proxy/` - proxies form submissions to Formspree or webhook

Deploy workers separately: `wrangler deploy` from each worker directory.

### Phase 7 - CRO Audit (page-review/SKILL.md Step 3b)

Run after deploy. Fix Critical + High before calling done:
- CTA above fold mobile + desktop
- Form fields count verified
- Testimonials have real names (or documented exception for privacy-sensitive niches)
- Analytics firing (check Network tab for gtag calls)
- `<main>`, `<header>`, `<footer>` present
- Skip-nav present
- Favicon visible

### Phase 8 - Git + PR

```bash
cd ~/ai/agents/web/cloudflare_agent
git checkout -b feat/<clientname>-site
git add clients/<clientname>/
git commit -m "feat: add <clientname> site (v1-v3) + workers"
git push -u origin feat/<clientname>-site
gh pr create ...
```

---

## Skills to Create

### 1. `cloudflare_agent/skills/web-blog.md` (NEW)

Contents:
- Blog directory structure inside `src/blog/`
- `blog/index.html` template (post card grid using site tokens)
- `blog/post-template.html` (full post layout: hero title, author/date, body, related posts CTA)
- RSS feed pattern (`blog/feed.xml` - static, manually updated)
- SEO checklist per post: title tag, meta description, og:title, og:description, canonical
- Content brief format (what user provides → what Claude generates)
- One-shot publish command: `cf-deploy update <name> --source clients/<name>/website_v3/src`

### 2. `cloudflare_agent/skills/web-analytics.md` (NEW)

Contents:
- GA4 snippet template (parametrized with `G-XXXXXXXX`)
- CSP additions needed for analytics (already in security-headers worker but document it)
- Key events to instrument: form_submit, cta_click, calculator_use, scroll_depth
- GTM alternative snippet
- Verification: how to confirm GA4 is firing (DebugView, Network tab pattern)
- Event schema for the lead-proxy worker (what data to pass back)

### 3. `cloudflare_agent/skills/web-workflow.md` (NEW)

The master checklist tying all skills together. References each skill at the right phase. Inputs, outputs, order, deploy command. This is the one file to read at the start of any new client site engagement.

---

## Files to Create/Edit

| File | Action |
|---|---|
| `cloudflare_agent/skills/web-blog.md` | Create |
| `cloudflare_agent/skills/web-analytics.md` | Create |
| `cloudflare_agent/skills/web-workflow.md` | Create |
| `~/.claude/CLAUDE.md` | Add row to domain rules table: landing page / site build → read `web-workflow.md` |

All three new skills go into cloudflare_agent (not arc-web/claude-skills) because they are project-specific tooling, not general Claude Code skills.

---

## Verification

After creating all three skill files:
- Read web-workflow.md top-to-bottom and check every phase links to a real skill that exists
- Confirm `web-blog.md` post template uses CSS token variables (not hardcoded hex)
- Confirm `web-analytics.md` snippet matches what the security-headers worker CSP allows
- Add row to CLAUDE.md domain rules table and confirm it reads correctly
- Commit all three to cloudflare_agent on a branch + PR
