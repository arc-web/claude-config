# TheraPPC Blog Launch

## Context

TheraPPC has no blog. The main site is live at therappc.com (Google Ads management for therapy practices). Adding a blog at therappc.com/blog/ serves two goals: SEO for therapist-focused search terms ("Google Ads for therapists", "HIPAA tracking", "therapy practice marketing") and authority/trust-building with the target audience. Mirror the exact pipeline used for aibrainbuilders.com/blog/.

---

## Site Snapshot

- **Source:** `/Users/home/ai/agents/web/cloudflare_agent/clients/therappc/website_v3/src/`
- **Bucket:** `therappc`
- **Domain:** `therappc.com`
- **Registry entry:** `therappc` (path: null = root deploy)
- **Blog target:** `therappc.com/blog/` → new registry entry `therappc-blog`

---

## Design System (match exactly)

- **Bg:** `#F5F0E8` (cream) / dark: `#1E2D2A` (deep teal)
- **Primary accent:** `--gold: #6B8F71` (sage green)
- **Secondary accent:** `--rust: #B87355`
- **Text:** `--ink: #2C2A26`
- **Fonts:** Plus Jakarta Sans (headings), Inter (body)
- **Radius:** 10px cards, 50px pills
- **Max-width:** 1160px
- **Card hover:** `translateY(-4px)` + shadow lift
- **No Atropos** (that's aibrainbuilders-specific) - use plain CSS hover cards

---

## Blog Categories (3)

| Filter | slug | Color |
|--------|------|-------|
| All | - | - |
| Strategy | `strategy` | sage `#6B8F71` |
| Guide | `guide` | rust `#B87355` |
| Case Study | `case-study` | muted teal `#4A7A6D` |

---

## Posts (3)

### Post 1 - Case Study
**Title:** "$3,400 in Ad Spend. 91 Inquiries. 12 New Clients. One Practice's 30-Day Snapshot"
**Slug:** `case-studies/ontario-group-practice-30-day-snapshot`
**Category:** case-study
**Date:** 2026-05-12
**Read time:** 7 min
**Source data:** Ontario group practice from therappc.com homepage
- $3,400 spend → 91 inquiries at $37 CPL
- 73 consults booked (80% book rate)
- 12 clients started (16% close rate)
- ~$36k estimated revenue
**Sections:** The Situation → The Setup → The Numbers → What Drove the Results → Takeaway

### Post 2 - Guide
**Title:** "HIPAA-Compliant Google Ads Tracking for Therapists: What to Track, What to Never Touch"
**Slug:** `guides/hipaa-compliant-google-ads-tracking`
**Category:** guide
**Date:** 2026-05-12
**Read time:** 9 min
**Source data:** Tracking/compliance section of therappc.com
- Track: form submissions, phone connections, device type, source
- Never track: names, form content, PHI
- Tools: GTM, GA4, Google Ads conversion tracking
**Sections:** Why Compliance Matters → What's Safe to Track → What's Never Safe → The Setup Checklist → Red Flags to Audit

### Post 3 - Strategy
**Title:** "Why Your Psychology Today Profile Can't Scale Your Practice (And What Does)"
**Slug:** `strategy/psychology-today-vs-google-ads-therapy`
**Category:** strategy
**Date:** 2026-05-10
**Read time:** 8 min
**Source data:** Site positioning copy + pipeline math
- Directory listings = passive/waiting
- Search ads = active/intent-based (someone searching right now)
- Pipeline math: cost per inquiry → book rate → close rate → revenue
**Sections:** The Shift in How Clients Find Therapists → Directory Math vs Search Math → Intent Advantage → The Pipeline Model → Making the Switch

---

## Steps

1. **Create blog directory structure**
   - `src/blog/index.html` - blog landing with therappc design system
   - `src/blog/post-template.html` - reusable template

2. **Write 3 posts** (all HTML inline styles, therappc design tokens)
   - `src/blog/case-studies/ontario-group-practice-30-day-snapshot/index.html`
   - `src/blog/case-studies/ontario-group-practice-30-day-snapshot/meta.json`
   - `src/blog/guides/hipaa-compliant-google-ads-tracking/index.html`
   - `src/blog/guides/hipaa-compliant-google-ads-tracking/meta.json`
   - `src/blog/strategy/psychology-today-vs-google-ads-therapy/index.html`
   - `src/blog/strategy/psychology-today-vs-google-ads-therapy/meta.json`

3. **Add Blog link to main site nav** - edit index.html, pricing.html, pipeline-calculator.html, google-ads-for-therapists-results.html (add `<a href="/blog">Blog</a>` before the CTA button)

4. **Register blog** - `cf-deploy blog register --site therappc-blog --bucket therappc --domain therappc.com --source <path> --path blog`

5. **Build index** - `cf-deploy blog index --site therappc-blog`

6. **Deploy** - `cf-deploy update therappc-blog`

7. **Update sitemap** - `cf-deploy sitemap therappc`

8. **Deploy main site** (nav change) - `cf-deploy update therappc`

---

## Critical Files

- `src/blog/index.html` - NEW
- `src/blog/post-template.html` - NEW
- All 3 post HTML + meta.json - NEW
- `src/index.html` - add Blog nav link
- `src/pricing.html` - add Blog nav link
- `src/pipeline-calculator.html` - add Blog nav link
- `src/google-ads-for-therapists-results.html` - add Blog nav link

---

## Verification

- `https://therappc.com/blog/` - loads blog index, 3 cards visible
- Filter buttons: All / Strategy / Guide / Case Study - each working
- Each post URL loads correctly
- Nav on main site shows Blog link
- Sitemap includes new blog URLs
