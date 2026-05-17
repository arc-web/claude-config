# CRO Inspection - Process Gap Analysis + therappc.com Audit

## Context

Current process (`page-review/SKILL.md`) is a structural/technical audit - HTML semantics, HTTP headers, accessibility, source code. It does NOT have a conversion layer. CRO = converting visitors to leads, and none of the conversion-specific checks (CTA placement, form design, copy clarity, trust signals, analytics) exist in the skill. therappc.com just launched v3 (new palette + form) and has never had any audit run on the live site.

---

## Part 1 - What the Current Process Covers

`~/.claude/skills/page-review/SKILL.md` — 4 steps:

1. **Structural audit** (WebFetch) - semantic HTML, heading hierarchy, meta tags, accessibility, content quality, mobile viewport
2. **HTTP headers** (curl + sentinel:headers) - security headers, caching, HTTPS
3. **Source code review** (Read local file) - CSS consistency, responsive breakpoints, JS errors, font loading, form accessibility, canonical URL
4. **Visual analysis** (computer-use, optional/buggy) - screenshot hero, scroll sections, mobile resize

Output: PASS/WARN/FAIL per item, severity buckets (Critical → Low), fix in source + redeploy.

---

## Part 2 - What Is Missing

The skill covers "does the page work correctly." It does not cover "does the page convert."

### Missing: Conversion Layer (no checks exist for any of this)

| Gap | Why it matters |
|---|---|
| CTA above fold on mobile | If the first CTA requires scrolling on 375px, conversion drops significantly |
| Form field count audit | web-audience.md: 3 fields = 25% conversion, 7 fields = 11.4% - need to verify pricing.html form hits target |
| CTA copy quality | "Submit" = 14%, first-person CTA = +25% lift - need to check every form button |
| Trust signal inventory | Testimonials: named + photo? Social proof count above fold? Credentials visible? |
| Headline clarity test | H1 must answer "what do you do + for who" in one scan - no check exists |
| Value prop above fold | 5-second test: can a cold visitor understand the offer before scrolling? |
| Analytics presence | No check that GA4/pixel is installed and firing - no data = no CRO loop |
| Page speed | No Lighthouse / Core Web Vitals step - speed directly affects Quality Score + conversion |
| Copy audit (AI slop) | web-audience.md has slop rules but page-review doesn't cross-reference them |
| Mobile CTA tap targets | 44px minimum - no check exists |

### Missing: Tooling Integration

- `web-audience.md` (audience archetypes, slop rules, form conversion data) is never referenced in page-review
- No explicit step to run WebSearch for competitor benchmark comparison

---

## Part 3 - What to Run on therappc.com Now

Nothing has been run on v3 (deployed today). Full audit is clean slate.

### Run now (via existing page-review skill):

1. **Structural + headers audit** on `therappc.com` (index.html) - WebFetch + curl
2. **Source review** on all 4 pages: index, pricing, results, pipeline-calculator
3. **Form audit** on pricing.html specifically:
   - Count fields on lead capture form
   - Check CTA button copy
   - Verify 3-field target from web-audience.md is met

### Run now (conversion checks not in skill yet):

4. **CTA above fold check** - index.html and pricing.html at 375px
5. **Trust signal inventory** - testimonials named? photos? proof count?
6. **H1 clarity check** on all 4 pages - does each answer what + for who?
7. **Analytics check** - is GA4 or any pixel present in `<head>`?
8. **Copy slop scan** - cross-reference against web-audience.md Section 2 rules

---

## Part 4 - Files to Edit

### Add CRO Layer to page-review skill

**File:** `~/.claude/skills/page-review/SKILL.md`

Add new **Step 3b: Conversion Audit** between Step 3 (source review) and Step 4 (visual). Checks:

- [ ] CTA present above fold without scroll (mobile 375px and desktop 1280px)
- [ ] Form field count <= 3 for top-of-funnel forms
- [ ] CTA button copy is first-person or action-specific (not "Submit")
- [ ] H1 answers "what + for who" on each page
- [ ] Trust signals present above fold: testimonials with name + photo, social proof count
- [ ] Analytics tag present in `<head>` (GA4, Meta Pixel, or equivalent)
- [ ] No AI slop copy patterns (cross-ref web-audience.md Section 2)
- [ ] Mobile tap targets >= 44px on all CTAs
- [ ] Page weight check: WebFetch + note external script count

### Run full audit on therappc.com

Execute page-review steps 1-3 + new step 3b against live site. Fix all Critical and High findings in v3 source, redeploy.

---

## Execution Order

1. Add CRO layer to `page-review/SKILL.md` (10 min)
2. Run full audit on therappc.com - index.html first, then pricing.html (most conversion-critical pages)
3. Run CRO-layer checks on all 4 pages
4. Fix any Critical/High findings in website_v3/src/
5. Redeploy v3: `cf-deploy update therappc --source clients/therappc/website_v3/src`

---

## Verification

- All PASS/WARN/FAIL items documented per page
- Form on pricing.html: <= 3 fields, first-person CTA confirmed
- GA4 or tracking tag found (or documented as missing for client to add)
- No Critical severity findings remain post-fix
