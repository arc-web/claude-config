# SEO Full-Stack Audit & Roadmap

## Context

User asked for a comprehensive inventory of every SEO-related tool, agent, skill, and gap across the full stack - GitHub repos, agents, skills, deployed sites, and keyword/indexing infrastructure. Goal: understand what exists, what's missing, and what to build first for better keyword targeting, organic indexing, and search performance.

---

## What Exists (Full Inventory)

### Technical SEO Crawling
- **Screaming Frog Agent** `~/ai/agents/seo/seo_agent/seo_apps/screaming_frog_app/`
  - Full website crawler via Screaming Frog API + CLI
  - Detects: title/meta/H1/links/redirects/status codes/internal links
  - ~6000 lines, modular, exports CSV/JSON
  - Limitation: no ranking data, no content scoring

- **Arc Forensic Audit Probes** `~/ai/tools/security/arc-forensic-audit/probes/`
  - `on_page_seo.py` - audits 50 pages: title length, meta length, H1/H2/H3 hierarchy, image alt text %
  - `sitemap.py` - parses sitemap.xml/index, flags staging/test URLs
  - `robots_txt.py` - parses directives, flags crawl-delay >5s, critical blocks
  - `schema_audit.py` - validates JSON-LD per page
  - Weight: 15% of total forensic audit score

### On-Page SEO at Deploy Time
- **cloudflare_agent/lib/seo.js** `~/ai/agents/web/cloudflare_agent/lib/seo.js`
  - Audits 18 signals before deploy: title, meta, OG tags, canonical, H1, JSON-LD, viewport, twitter card, noindex detection, sitemap.xml, robots.txt, **llms.txt**
  - Blocks deploy if robots noindex detected

- **cloudflare_agent/lib/sitemap.js** - generates sitemap.xml + robots.txt from S3 metadata
- **cloudflare_agent/lib/llms.js** - generates llms.txt for AI agent indexing
- **cloudflare_agent/lib/schema.js** - injects JSON-LD (WebSite/Article/Organization/Product)
- **cf-deploy CLI** commands: `sitemap`, `robots`, `llms`

### Reporting & SEO Section
- **reportcard_agent/tools/seo_tool.py** `~/ai/agents/development/reportcard_agent/tools/seo_tool.py`
  - Consumes: Lighthouse scores, crawl results, on_page_seo probe data
  - Exports downstream: `keyword_gaps`, `indexing_issues`, `nap_issues`, `aeo_gaps`
  - Gap detection is binary (exists/doesn't exist), not quantified or prioritized
  - Connects SEO gaps → PPC opportunities

- **reportcard_agent/tools/seo_analyzer.py** - generates SEO subsections from Lighthouse + crawl data

### Keyword Management (Paid Search Only)
- **search_keyword_validator.py** (3 copies across ppc agent variants)
  - Validates match types, length limits, negative keyword coverage
  - Enforces broad match blocking, phrase match default
  - Zero SERP or research intelligence - account structure validation only

- **client-hq keyword change protocol** `~/ai/client-hq/docs/keyword-change-protocol.md`
  - Lifecycle: document → retire → content handling → LocalFalcon campaign swap
  - DB pattern: `tracked_keywords.retired_at` + `retired_reason` (never hard delete)

### Skills with SEO Steps
- **web-design/SKILL.md** - enforces: title <60 chars, meta 150-160 chars, canonical, all OG + Twitter card, html lang attribute
- **web-blog/SKILL.md** - adds: article:published_time, Article schema JSON-LD, RSS alternate link
- **wp-performance-review/SKILL.md** - mentions sitemap + robots.txt caching issues
- **ads/SKILL.md** - landing page CRO, no organic SEO intelligence

---

## Critical Gaps (Ranked by ROI)

| # | Gap | Why it Matters | Effort | External API? |
|---|-----|----------------|--------|--------------|
| 1 | **Google Search Console integration** | Real impression/position/CTR data, free, clients already have it | 2-3 days | No (GSC API, OAuth already proven) |
| 2 | **On-page SEO scoring per page** | Screaming Frog crawls but doesn't score optimization quality | 2-3 days | No (extend existing probe) |
| 3 | **SERP meta preview** | See how title/description render in Google before publishing | 1 day | No (client-side simulation) |
| 4 | **Content gap prioritizer** | Combine GSC + competitor crawl → actionable content list | 3-4 days | No (reuse screaming_frog) |
| 5 | **AEO (Answer Engine Optimization)** | FAQ schema, featured snippet eligibility, AI chatbot indexability | 2-3 days | No (extend screaming_frog) |
| 6 | **SERP rank tracking** | Track organic position over time | 5-7 days | Yes (SERPstat, SE Ranking, Ahrefs) |
| 7 | **Keyword research (volume/difficulty)** | Know which keywords to target before writing content | 4-6 days | Yes (same vendors) |
| 8 | **Backlink analysis** | Link equity, competitor link gaps | 4-5 days | Yes (Ahrefs, SEMrush) |

---

## Recommended Build Order

### Phase 1 - No external APIs, high ROI (build first)
1. **GSC Connector** → extend `reportcard_agent/tools/seo_tool.py`
   - Auth via Google OAuth (same pattern as google_ads_agent)
   - Pull: search queries, impressions, clicks, CTR, average position per URL
   - Output: "high-impression / low-CTR" → title/meta optimization targets
   - "low-position / high-impression" → content depth opportunities
   - File to extend: `~/ai/agents/development/reportcard_agent/tools/seo_tool.py`

2. **SERP meta preview** → extend `page-review` skill
   - Render how `<title>` + `<meta description>` appear at 600px wide Google SERP card
   - Flag truncation at 60/160 chars, missing brand suffix, passive voice in description
   - File to extend: `~/.claude/skills/page-review/SKILL.md`

3. **On-page SEO scoring module** → extend `screaming_frog_agent`
   - Score each page 0-100: title optimization, meta quality, heading structure, alt text %, schema presence, internal link count
   - Output prioritized "pages needing work" list
   - File to extend: `~/ai/agents/seo/seo_agent/seo_apps/screaming_frog_app/screaming_frog_agent.py`

### Phase 2 - Moderate effort, no external APIs
4. **Competitor content audit** - run screaming_frog on competitor domains → compare word count, heading structure, schema types
5. **Content freshness tracker** - scheduled crawl diff → detect decay (404s, traffic drops correlated with no-update date)
6. **AEO module** - FAQ schema detection, structured data for featured snippets, llms.txt optimization

### Phase 3 - External APIs (decide vendor first)
7. SERP rank tracker (SERPstat or SE Ranking preferred - cost-effective)
8. Keyword research (same vendor)
9. Backlink gap analysis (Ahrefs has best data, SEMrush bundle if already paying)

---

## Key Reuse Opportunities

- **Ads skill copy frameworks** (AIDA/PAS/BAB) → feed into content optimization and meta copy
- **Reportcard cross-section data flow** → proven pattern for GSC → SEO → Ads connection
- **Google Ads OAuth pattern** → reuse for GSC auth (same Google API, same credentials flow)
- **Screaming Frog crawler architecture** → foundation for competitor + content audit modules
- **credentials skill + OpenBao** → inject SERPstat/Ahrefs keys when Phase 3 starts

---

## Decision Needed Before Building

1. **Phase 1 only, or full roadmap?** - Phase 1 delivers real ranking data immediately with zero external cost
2. **GSC access** - do client sites have GSC verified? Need to confirm which client(s) to connect first
3. **Standalone SEO skill or reportcard extension?** - GSC data fits best in reportcard; standalone skill better for ad-hoc audits

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Extend | `~/ai/agents/development/reportcard_agent/tools/seo_tool.py` |
| New | `~/ai/agents/development/reportcard_agent/tools/gsc_connector.py` |
| Extend | `~/ai/agents/seo/seo_agent/seo_apps/screaming_frog_app/screaming_frog_agent.py` |
| New | `~/.claude/skills/seo/SKILL.md` (dedicated SEO skill) |
| Extend | `~/.claude/skills/page-review/SKILL.md` (SERP preview section) |
