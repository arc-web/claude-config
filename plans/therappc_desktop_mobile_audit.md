# Context

Full-site audit of therappc.com across all 6 pages at desktop (1280px) and mobile (375px). Triggered after hero card CRO fix revealed systemic copy, trust, and positioning problems. Several known issues from this session are unresolved; audit will uncover more. All issues fixed inline - this is fix-as-you-go, not a report.

---

## Pages in scope

| File | URL path |
|------|----------|
| `src/index.html` | / |
| `src/pricing.html` | /pricing.html |
| `src/results.html` | /results.html |
| `src/pipeline-calculator.html` | /pipeline-calculator.html |
| `src/privacy.html` | /privacy.html |
| `src/terms.html` | /terms.html |

Source root: `/Users/home/ai/agents/web/cloudflare_agent/clients/therappc/website_v3/src/`

---

## Phase 1 - Structural audit (WebFetch, all 6 pages in parallel)

Fetch each live URL. For each page check:
- Semantic HTML (header/main/footer present, single h1)
- Heading hierarchy (h1 → h2 → h3, no skips)
- Meta tags (title, description, og:*, canonical, viewport)
- Accessibility (aria-*, alt text, skip-nav, labels with `for`)
- External resources (CDN failures, render-blocking scripts)
- Mobile viewport meta present
- Broken links (href="#" without handlers, dead anchors)

---

## Phase 2 - Source code CRO audit (Read each HTML file)

Run against each file. Known issues to verify + fix:

### index.html (High priority fixes)
- **H1 copy** - "Fill your clinicians' caseloads" → alienates solo therapists; rewrite to cover both solo + group (e.g. "Fill your caseload - and your schedule")
- **Primary CTA** - "See if your practice qualifies" → weak/gatekeeping; rewrite to outcome-led ("See what ads would do for your practice")
- **Stats section** - currently shows Ontario group practice numbers (91 inquiries, $37 CPI, 13% CVR) as site-wide aggregates; add label clarifying source or replace with true aggregate
- **Above-fold CTA desktop** - verify CTA visible at 1280px without scroll
- **Above-fold CTA mobile** - verify CTA visible at 375px without scroll; tap target ≥ 44px
- **Trust signals** - count named logos or client proof visible above fold
- **AI slop copy scan** - flag: "transformative", "leverage", "game-changing", "cutting-edge", "comprehensive", "seamlessly", "unlock your potential"
- **GA4** - verify tag present in `<head>`
- **External script count** - flag if > 6 in `<head>`

### pricing.html
- **H1 cold-eye test** - "See what Google Ads would actually do for your practice" - passes 5-sec test? Verify
- **CTA copy** - "Get my custom pricing →" - first-person, good
- **Form fields** - 3 visible (name, email, phone) - phone is optional; consider making it visually optional or removing
- **Management fee transparency** - $1,500/mo shown in assumptions box; verify this doesn't front-load sticker shock before ROI math
- **Mobile form usability** - input sizes, label visibility, button tap target

### results.html
- **GA4 missing** - confirmed absent; add GA4 snippet (flag as High if client G-ID available, INFO if not)
- **H1 length** - "No client names. No manufactured testimonials. Actual performance data from actual accounts." - long; verify renders cleanly on mobile
- **Stats banner** - same Ontario numbers as index; add `(single account, 30-day period)` sub-label to all 4 stats
- **Case study trust** - anonymized is intentional; verify "outcome" narrative in each card is specific enough to be believable

### pipeline-calculator.html
- **H1** - "Run the math before you commit." - verify passes 5-sec what+for-who test
- **Slider usability mobile** - range inputs are notoriously bad on mobile; check if touch targets are adequate or if number inputs are better
- **Break-even callout** - verify it's visible without scroll on mobile
- **CTA post-calculation** - after user runs numbers, is there a clear next step CTA in view?

### privacy.html + terms.html
- These were fixed (header/skip-nav/favicon) last session; verify lint still passes
- No CRO concerns; check canonical and title tags only

---

## Phase 3 - Mobile-specific checks (375px mental model)

For index, pricing, calculator specifically:
- Nav: hamburger present and functional?
- Hero card (funnel): does it stack cleanly or overflow at 375px?
- Font sizes: minimum 16px body to prevent iOS zoom on input focus
- Horizontal scroll: any elements wider than viewport?
- Button tap targets: every interactive element ≥ 44px height

---

## Phase 4 - Fix inline

Fix all Critical + High + Medium issues directly in source files. For each fix:
- Edit the file
- Note what changed and why in the plan as a running fix log

Do NOT fix GA4 on results.html unless client G-ID is in the code already - flag as INFO instead.

---

## Phase 5 - Pre-deploy lint + deploy

```bash
node bin/cf-deploy.js lint clients/therappc/website_v3/src
```

Fix any remaining FAIL items. Then:

```bash
node bin/cf-deploy.js update therappc website_v3
```

Run from: `/Users/home/ai/agents/web/cloudflare_agent/`

---

## Severity reference

| Level | Definition |
|-------|-----------|
| Critical | Breaks functionality - JS errors, broken forms, missing viewport |
| High | Hurts conversion or UX - weak CTA, missing analytics, alienating copy, missing a11y landmarks |
| Medium | Polish - spacing, type scale, animation, trust signal placement |
| Low | Nice-to-have - micro-interactions, perf, favicon |

---

## Fix log

| Severity | File | Fix |
|----------|------|-----|
| High | index.html | H1: "Fill your clinicians' caseloads" → "Fill your practice with clients who actually book." |
| High | index.html | CTA: "See if your practice qualifies →" → "Book my strategy call →" |
| Medium | index.html | form-input font-size: 0.92rem → 1rem (prevents iOS zoom on focus) |
| Medium | pricing.html | lead-input font-size: 0.95rem → 1rem (prevents iOS zoom on focus) |
| Medium | index.html | Meta description + og:description + schema.org: removed "and group practices" framing |
| Medium | index.html | Mobile hero funnel: replaced hide-steps-3-4 hack with 2x2 grid at 480px; all 4 steps now visible |
| Medium | results.html | Stats banner: added source note to 91-inquiry stat ("Ontario group practice, $3,400 spend") |
| INFO | index/pricing/results/calculator | GA4: added commented-out placeholder in `<head>`; uncomment when client provides G-XXXXXXXXXX |
