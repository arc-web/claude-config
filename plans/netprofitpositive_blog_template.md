# Plan: netprofitpositive.com Blog Template

## Context

netprofitpositive.com is a live, deployed static site on Cloudflare R2. It has no blog section. Source files were deleted after deploy. The site uses a "premium SaaS meets financial accountability" aesthetic - warm gold (#8A6B48), cream/off-white background, dark charcoal text, monochromatic flat icons.

Goal: build a two-file blog system (index + post template) that matches the site design, deploys to `/blog/` path on the same domain, and creates a visually rich, interactive reading experience that feels mesmerizing through animated data, pull quotes, example cards, and scroll-driven reveals.

---

## Design System (matching existing site)

**Colors** (from live site):
- `--bg: #FAF7F2` (cream)
- `--gold: #8A6B48`
- `--gold-light: #C4A882`
- `--ink: #1A1814`
- `--ink-mid: #4A4540`
- `--ink-light: #8A8580`
- `--green: #3D7A5F` (positive indicators)
- `--red: #B84040` (negative/warning)
- `--surface: #FFFFFF`
- `--border: #E8E3DC`

**Typography**: Space Grotesk (headings) + Inter (body) - matches site
**Effects stack**: Showcase Premium (AOS + anime.js + Atropos) - enables scroll reveals, animated counters, 3D cards

---

## Files to Build

### 1. `/blog/index.html` - Blog listing page
Sections:
- Sticky nav (matching main site nav)
- Hero: "Insights" header + subtitle + post count
- Post grid: 3-column cards (title, excerpt, tag, read time, date)
- Cards use Atropos 3D tilt on hover
- AOS stagger entrance on load
- Filter bar: All / Strategy / Data / Case Studies / Tools
- Footer matching main site

### 2. `/blog/post-template.html` - Individual post template
Sections:
- Sticky nav
- Post hero: category tag + H1 + author block + animated reading progress bar
- Two-column layout: main content (65%) + floating TOC sidebar (35%)
- Content components (all copy-paste blocks):
  - **Standard body text** - Inter, 18px, 1.7 line height
  - **Pull quote** - large gold-bordered left stripe, 1.4x size
  - **Callout box** - 4 types: insight (gold), warning (red), example (green), data (ink)
  - **Stat showcase** - 2-4 large animated numbers (anime.js counter sweep on scroll)
  - **Data chart** - inline SVG bar/line charts, animated on scroll entry
  - **Example card** - bordered card with "EXAMPLE" label, scenario + result
  - **Comparison table** - before/after with ✓/✗ marks (matching existing site style)
  - **Code/formula block** - monospace, dark surface
  - **Image + caption** - full-width with gold caption bar
  - **Section divider** - thin gold line with centered label
- Author bio card (bottom)
- Related posts (3-card grid, same Atropos cards as index)
- Footer

---

## Interactive / Mesmerizing Elements

| Element | Library | Trigger |
|---------|---------|---------|
| Scroll reveal (all sections) | AOS | Enter viewport |
| Staggered card entrance | AOS + delay | Index load |
| 3D tilt on post cards | Atropos | Mouse hover |
| Animated stat counters | anime.js | Enter viewport |
| SVG chart draw | anime.js | Enter viewport |
| Reading progress bar | Vanilla JS | Scroll |
| TOC active section highlight | Vanilla JS + IntersectionObserver | Scroll |
| Smooth anchor scroll | CSS scroll-behavior | Click |

**Reduced-motion**: All anime.js + AOS animations wrapped in `@media (prefers-reduced-motion: reduce)` guard - static fallback.

---

## Deploy Plan

Both files built as standalone HTML (single-file, inline CSS + CDN JS - no build step).

```bash
# Deploy both files to /blog/ path
cf-deploy deploy ./blog --domain netprofitpositive.com --path blog

# Run SEO audit after deploy
cf-deploy seo https://netprofitpositive.com/blog/
cf-deploy seo https://netprofitpositive.com/blog/post-template.html
```

**Credentials**: via `op` CLI (already configured in cloudflare_agent/lib/auth.js)

---

## File Locations

- `~/ai/agents/web/cloudflare_agent/` - deploy CLI (existing)
- `~/ai/agents/web/cloudflare_agent/skills/web-design.md` - design system ref
- `~/ai/agents/web/cloudflare_agent/skills/web-effects.md` - animation code
- `~/ai/agents/web/cloudflare_agent/skills/web-components.md` - HTML blocks
- Build target: `~/ai/projects/netprofitpositive/blog/` (new, create on build)
- Output: `index.html` + `post-template.html`

---

## Decisions (confirmed)

- **Index posts**: 6 placeholder cards with realistic titles/excerpts matching niche
- **TOC mobile**: Collapses to sticky expandable "Contents" button below nav
- **Nav links**: Match main site exactly (Problem / Coverage / Build / Pricing / Get Started)
- **No email subscribe CTA** - replace with two conversion paths:
  1. **ROI Calculator CTA** - prominent mid-post callout card linking to `/calculator` (main conversion action)
  2. **Related posts block** - 2-3 contextually matched posts at end, plus inline interlinks within body text when posts reference each other

---

## SEO + Blogging Best Practices (baked into template)

**SEO head block** (every post):
- `<title>` - post title + " | Net Profit Positive"
- `<meta name="description">` - 150-160 char excerpt
- `<meta property="og:*">` - Open Graph for social sharing
- `<link rel="canonical">` - self-referential canonical URL
- JSON-LD Article schema (injected via `cf-deploy schema inject`)
- `<meta name="robots" content="index, follow">`

**Content rules (enforced by template structure)**:
- No em dashes anywhere - use ` - ` (hyphen with spaces)
- Every H2 section has a dedicated image slot (full-width figure + caption)
- Heading hierarchy: H1 (title, one per page) > H2 (main sections) > H3 (subsections)
- Alt text placeholder on every `<img>`
- Semantic HTML: `<article>`, `<header>`, `<section>`, `<aside>` (TOC), `<footer>`
- Reading time estimate in post hero (calculated from word count)
- Published date in `<time datetime="...">` ISO format

**Internal linking components**:
- `<!-- INLINE INTERLINK -->` slot in body text - gold underline link style
- "Related reading" callout card (mid-post, contextual)
- ROI Calculator CTA card (mid-post, conversion)
- Related posts grid (end of post, 2-3 cards)
- Breadcrumb: Home > Blog > [Post Title]
