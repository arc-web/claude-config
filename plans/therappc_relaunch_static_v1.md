# TheraPPC.com Relaunch - Static v1 via cloudflare_agent

## Context

Current site is GoHighLevel funnel - 3 pages, 211 KB HTML, 30+ JS bundles, 6 font families, empty sitemap, no schema, no security headers, generic GHL template visuals. User wants frontend rebuilt from scratch while keeping GHL backend (CRM, calendar, payments, DNS). Form submissions will POST to GHL inbound webhook so leads land in same workflow as current native GHL form.

Site repositioning per master content brief: from generic "PPC for therapists" funnel to evidence-based, math-first agency site addressing therapist psychology (Psychology Today collapse, identity conflict, ethics, pipeline math). Hybrid visual direction - light primary palette with dark hero/CTA sections, gold accent, sans-serif only.

MVP scope: 6 pages. Phase 2 adds segment pages (solo / first-hire / group / psychiatry) and blog. Phase 3 = interactive React calculator if static version proves limiting.

## Stack

- **Frontend:** static HTML/CSS/JS (no framework), deployed via `cf-deploy` to Cloudflare R2 + custom domain
- **Form handler:** Cloudflare Worker at `/api/lead` proxying to GHL webhook (URL stored as wrangler secret)
- **Security headers:** existing `templates/security-headers/` Worker, route added on therappc.com/*
- **Analytics:** GTM container preserved from current site
- **Calendar/payments:** unchanged (GHL booking URL deep-link, Authorize.Net stays in GHL)
- **DNS:** zone untouched, existing CF account

## Project home

`~/ai/agents/web/cloudflare_agent/clients/therappc/website_v1/`

```
website_v1/
├── src/
│   ├── index.html          # home
│   ├── pricing.html
│   ├── results.html
│   ├── pipeline-calculator.html
│   ├── privacy.html
│   ├── terms.html
│   ├── assets/
│   │   ├── css/site.css     # design tokens + components
│   │   ├── js/site.js       # nav, scroll, AOS init
│   │   ├── js/calculator.js # vanilla pipeline calc
│   │   ├── js/form.js       # webhook POST + validation
│   │   └── img/             # hero, charts, logo SVG
│   ├── robots.txt
│   └── sitemap.xml          # generated post-deploy
├── workers/
│   ├── lead-proxy/          # webhook proxy → GHL
│   │   ├── worker.js
│   │   └── wrangler.toml
│   └── security-headers/    # copied from cloudflare_agent/templates
├── content/
│   └── master_brief.md      # source of truth for copy (paste user brief)
├── scripts/
│   └── deploy.sh            # cf-deploy commands chained
└── README.md
```

## Design system

**Palette (CSS custom properties in `site.css`):**
```
--color-bg-light: #FAFAF7      /* primary bg */
--color-bg-dark: #0E0F12       /* hero, CTA bands */
--color-text-primary: #14161B
--color-text-muted: #5A5F6A
--color-text-on-dark: #F5F5F2
--color-accent-gold: #C9A24A   /* CTAs, key numbers */
--color-accent-gold-hover: #B8902F
--color-rule: #E8E6DF
--color-success: #2F7D5C
```

**Type:** Inter (variable, weights 400/500/600/700) only. Self-host woff2 → R2 (no Google Fonts call).

**Scale:** 14 / 16 / 18 / 22 / 28 / 36 / 48 / 64 px, line-height 1.5 body / 1.15 display.

**Layout:** max content width 1140px, section padding 96px desktop / 56px mobile, mobile-first.

**Tone calibration (from brief):** clinical, calm, evidence-based. No urgency, no countdowns, no dark patterns. Numbers prominent, generous whitespace.

## MVP page specs

### `index.html` - homepage

14 sections from brief Part 2, scroll order:
1. Nav (sticky, dark bg, gold CTA)
2. Hero (dark band) - headline A/B candidates: "Fill your clinicians' caseloads with clients who actually book." | subhead | dual CTA (qualify / scroll)
3. Validate the Past (light, 4 muted cards)
4. Psychology Today Collapse (light, line-chart image, ClearHealthCosts data points + source line)
5. Pipeline Math Preview (dark band) - static table v1 with 3 scenarios; "Run your own numbers" CTA → /pipeline-calculator
6. How We're Different (light, 4 cards)
7. Campaign Forensic (light + before/after visual)
8. What We Actually Do (4-phase process, accordion or stacked panels)
9. Compliance-Safe Tracking (light, no-jargon copy)
10. Growth Stage Selector (4 cards, link to Phase-2 segment pages or anchor sections for now)
11. Proof Layer (dark band, 4 numbered proof points, big numerals in gold)
12. Is It Ethical? (light, long-form prose, no bullets)
13. Offer summary + pricing snapshot (light, link to /pricing for full)
14. Qualification Assessment (5 yes/no, JS reveals CTA on 3+ yes)
15. FAQ (10 Qs, native `<details>` for zero-JS accordion)
16. Footer (dark, links + form CTA repeat)

### `pricing.html`
Core Monthly $1,500 / Core Annual $833 ($10,000) / Premium Annual (contact). Annual/monthly toggle (web-pricing.md pattern). Full inclusion list. "Why annual is discounted" explainer.

### `results.html`
4 anonymized case studies, consistent format: starting point / forensic findings / rebuild / 30-60-90 results / current state. Tagged by practice type (solo/group/psychiatry) and budget.

### `pipeline-calculator.html`
Vanilla JS calculator. Inputs: session rate, retention, close rate, monthly ad budget. Outputs: conservative/moderate/optimistic - inquiries, new clients, monthly revenue, ROI multiple, break-even. No React. ~150 LOC. CTA at bottom: book strategy call.

### `privacy.html` / `terms.html`
Rewrite from current GHL templates - strip GHL boilerplate, replace with TheraPPC-specific clauses. User reviews before publish.

## Form flow

1. Form on home + pricing + calculator pages, identical fields: name, email, practice name, role, monthly ad budget, message
2. Vanilla JS (`form.js`): client-side validation, honeypot field `_gotcha`, fetch POST to `/api/lead`
3. Worker `lead-proxy/worker.js`:
   - CORS allowlist: therappc.com only
   - Honeypot reject
   - Cloudflare Turnstile verify (optional, add if spam)
   - Rate limit (Cloudflare KV or rolling IP map)
   - Repackage payload, POST to GHL webhook URL (env var `GHL_WEBHOOK_URL` set via `wrangler secret put`)
   - Return `{ok:true}` or error JSON
4. GHL workflow (user-built) catches inbound webhook, creates contact, assigns pipeline stage, fires automations

Worker template starting point: `cloudflare_agent/skills/web-worker.md` (Resend pattern, swap email send for fetch to GHL URL).

## Reusable assets (no rebuild)

| Need | Source |
|------|--------|
| Design tokens, type scale | `cloudflare_agent/skills/web-design.md` |
| Nav, hero, feature cards, testimonials, CTA, footer HTML | `cloudflare_agent/skills/web-components.md` |
| Pricing toggle, tier cards | `cloudflare_agent/skills/web-pricing.md` |
| Form base + validation + multi-step | `cloudflare_agent/skills/web-forms.md` |
| AOS scroll reveals, counter anim | `cloudflare_agent/skills/web-effects.md` (Landing Standard, 18 KB) |
| Security headers Worker | `cloudflare_agent/templates/security-headers/` |
| Worker form proxy template | `cloudflare_agent/skills/web-worker.md` |
| Deploy / SEO / sitemap / robots / schema CLI | `cf-deploy` (`bin/cf-deploy.js`) |

## Build new

- Pipeline calculator (vanilla JS, no React)
- Campaign Forensic before/after visual (SVG)
- Psychology Today decline chart (SVG)
- TheraPPC SVG logo refresh (or extract from current site if keeping)
- Therapist-context illustrations (skip stock photos per brief)
- Qualification assessment widget (5-question reveal)
- 10-Q FAQ block (native `<details>`)

## Language rules baked into copy review

From brief Part 4: no "leads" / "funnel" / "scale" / "dominate" / "limited spots" / em dashes. Use "inquiries" / "client pathway" / "grow" / "see if you qualify" / semicolons. Run grep over all HTML before each deploy.

## SEO + structured data

- `cf-deploy schema inject src/index.html --type organization --name "TheraPPC" --url https://therappc.com`
- FAQPage schema for FAQ section (manual JSON-LD insertion)
- LocalBusiness or ProfessionalService schema considered (TBD - therappc is agency not clinic)
- Canonical tags on each page
- `cf-deploy sitemap therappc` post-deploy
- `cf-deploy robots therappc`
- `cf-deploy llms therappc --title "TheraPPC" --description "PPC management for therapy practices"`
- `cf-deploy seo therappc` to audit live site

## Deploy sequence

```bash
# 1. Build complete - QA local file://
cd ~/ai/agents/web/cloudflare_agent/clients/therappc/website_v1

# 2. Schema injection on home
cf-deploy schema inject src/index.html --type organization \
  --name "TheraPPC" --url https://therappc.com

# 3. Worker: lead-proxy first (form needs endpoint live)
cd workers/lead-proxy
wrangler secret put GHL_WEBHOOK_URL    # paste GHL inbound webhook
wrangler deploy
# Add route therappc.com/api/* in CF dashboard

# 4. Deploy site to staging path first
cf-deploy deploy ./src --project therappc-staging --domain therappc.com --path staging
# QA at therappc.com/staging/

# 5. Production swap
cf-deploy deploy ./src --project therappc --domain therappc.com

# 6. SEO assets
cf-deploy sitemap therappc
cf-deploy robots therappc
cf-deploy llms therappc --title "TheraPPC" --description "PPC for therapy practices"

# 7. Security headers Worker
cd workers/security-headers
wrangler deploy
# Add route therappc.com/* in CF dashboard

# 8. Audit
cf-deploy seo therappc
```

## Verification

1. `curl -I https://therappc.com` - headers include CSP, HSTS, X-Frame-Options, Permissions-Policy
2. `cf-deploy seo therappc` - title, OG, canonical, h1, JSON-LD all present
3. `curl https://therappc.com/sitemap.xml` - all 6 pages listed
4. Lighthouse: Performance ≥ 95, Accessibility ≥ 95, SEO 100, Best Practices 100
5. Submit test form on each page - verify GHL contact created in target workflow
6. Submit form with honeypot field filled - verify rejected
7. Submit from non-therappc.com origin - verify CORS blocked
8. Mobile viewport (375 / 414 / 768) - all sections render, CTAs tappable
9. `grep -niE 'leads|funnel|—|limited spots|act now|guaranteed' src/*.html` - empty
10. Verify "Schedule A Call" links open GHL booking URL in new tab
11. GTM container loads - GA4 tag fires on pageview
12. Diff `cf-deploy verify therappc` - HTTP 200

## Out of scope (Phase 2+)

- Solo / first-hire / group / psychiatry segment pages (Phase 2)
- Blog index + 8 blog posts (Phase 2)
- Interactive React calculator (Phase 3 if vanilla limits)
- A/B test framework (Phase 3)
- Video walkthrough of calculator (Phase 3)
- Client portal / login (out)
- Stripe migration (off, Authorize.Net stays in GHL)
- HubSpot/CRM swap (out, GHL stays)

## Open items pre-build

1. GHL webhook URL - user creates inbound webhook trigger workflow, supplies URL when Worker stage hits
2. Logo SVG - reuse current TheraPPC mark from live site or refresh? (defer; extract for now)
3. Brand color match - confirm gold hex matches any existing brand guideline or use proposed `#C9A24A`
4. ClearHealthCosts source citations - exact URLs for the 357→40 / 128→28 stats (user supplies or I research)
5. Ontario case study data - confirm "$3,400 spend / 91 inquiries / $37 CPA / 13% CVR" can be public-facing (anonymous OK)
6. Calendar URL - exact GHL booking page URL for "Schedule A Call" button
7. GTM container ID - extract from current site or new container

## Critical files to read at build time

- `/Users/home/ai/agents/web/cloudflare_agent/skills/web-design.md`
- `/Users/home/ai/agents/web/cloudflare_agent/skills/web-components.md`
- `/Users/home/ai/agents/web/cloudflare_agent/skills/web-forms.md`
- `/Users/home/ai/agents/web/cloudflare_agent/skills/web-effects.md`
- `/Users/home/ai/agents/web/cloudflare_agent/skills/web-pricing.md`
- `/Users/home/ai/agents/web/cloudflare_agent/skills/web-worker.md`
- `/Users/home/ai/agents/web/cloudflare_agent/skills/web-security.md`
- `/Users/home/ai/agents/web/cloudflare_agent/templates/security-headers/worker.js`
- `/Users/home/ai/agents/web/cloudflare_agent/bin/cf-deploy.js`
- `/tmp/therappc_scan/home.html` (current site reference - extract any salvage copy/assets)
