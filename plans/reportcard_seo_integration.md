# Reportcard Agent - Full SEO Integration

## Context

The reportcard_agent has a thin SEO section that only consumes Lighthouse scores + crawl counts from pre-run JSON files. A rich set of SEO probe tools exists across the codebase (forensic audit probes, schema validator, tech stack detector, Yoast REST reader) but none are wired into the reportcard pipeline. Google Search Console (GSC) auth infrastructure also exists but is unconnected. This plan integrates all of them.

---

## Architecture Recap (What Exists)

**Reportcard data flow:**
```
[Research Stage] → JSON files in data_dir → [Analyze Stage] → SectionOrchestrator → SectionTool.analyze(upstream) → DOCX
```

Tools communicate via:
1. `upstream` dict (in-memory, passed by orchestrator)
2. JSON files in `data_dir/` (disk, read by any tool)

**Orchestration order (fixed):**
`technical → web_design → seo → competitors → google_ads → social_ads → reputation`

SEO tool already reads `research_results.json` and `crawl_results.json` from disk. The plan is to add more JSON files to `data_dir/` and have `seo_tool.py` consume them.

---

## What Gets Added

### 1. `tools/seo_probes.py` (new file)
Thin wrapper that runs the forensic audit probes and saves standardized JSON to data_dir. Called from analyze stage before orchestration.

**Probes to run:**
- `OnPageSEOProbe` → `data_dir/seo_on_page.json`
- `SitemapProbe` → `data_dir/seo_sitemap.json`
- `RobotsProbe` → `data_dir/seo_robots.json`
- `SchemaProbe` → `data_dir/seo_schema.json`
- `TechStackProbe` → `data_dir/seo_tech_stack.json`
- `YoastRestProbe` → `data_dir/seo_yoast.json` (only if WordPress detected)

**Source probe paths (import from):**
- `~/ai/tools/security/arc-forensic-audit/probes/on_page_seo.py` → `OnPageSEOProbe`
- `~/ai/tools/security/arc-forensic-audit/probes/sitemap.py` → `SitemapProbe`
- `~/ai/tools/security/arc-forensic-audit/probes/robots_txt.py` → `RobotsProbe`
- `~/ai/tools/security/arc-forensic-audit/probes/schema_audit.py` → `SchemaProbe`
- `~/ai/tools/security/arc-forensic-audit/probes/tech_stack.py` → `TechStackProbe`
- `~/ai/tools/security/arc-forensic-audit/probes/yoast_rest.py` → `YoastRestProbe`

**Function signature:**
```python
def collect_seo_probes(domain: str, data_dir: str, force: bool = False) -> dict[str, bool]:
    """Run all SEO probes. Returns {probe_name: success}. Skips if JSON already exists."""
```

Each probe uses its built-in `force` flag + writes cached JSON to `data_dir` — matching existing pattern. Skip silently if probe fails (never block the report).

---

### 2. `tools/gsc_connector.py` (new file)
Fetches Google Search Console data for the client domain. Uses existing auth infrastructure.

**Auth reuse from:** `~/ai/infra/google-oauth-setup/storage.py` → `build_creds()`, `read_openbao()`

**GSC API calls:**
- `searchconsole.searchAnalytics().query()` — 90 days of data
- Dimensions: `['query', 'page']`
- Metrics: impressions, clicks, CTR, position
- Filter: domain property

**Output:** `data_dir/gsc_data.json`
```json
{
  "property": "https://example.com",
  "date_range": {"start": "YYYY-MM-DD", "end": "YYYY-MM-DD"},
  "rows": [
    {
      "query": "keyword phrase",
      "page": "https://example.com/page/",
      "impressions": 1200,
      "clicks": 45,
      "ctr": 0.0375,
      "position": 8.4
    }
  ],
  "opportunity_pages": [
    {"page": "...", "query": "...", "position": 9.1, "impressions": 800, "ctr": 0.018}
  ]
}
```

`opportunity_pages` = pages ranking 5-15 with impressions >100 and CTR below threshold (title/meta optimization targets).

**Function signature:**
```python
def fetch_gsc_data(domain: str, data_dir: str, account_slug: str, force: bool = False) -> bool:
    """Fetch GSC search analytics. Returns True if successful. Skips if JSON exists."""
```

**Graceful degradation:** If GSC not configured for client, log warning, skip, continue.

---

### 3. `tools/seo_tool.py` (extend existing)

**New `_load_*` methods:**
```python
def _load_on_page(self) -> dict         # seo_on_page.json
def _load_sitemap(self) -> dict         # seo_sitemap.json
def _load_robots(self) -> dict          # seo_robots.json
def _load_schema(self) -> dict          # seo_schema.json
def _load_tech_stack(self) -> dict      # seo_tech_stack.json
def _load_gsc(self) -> dict             # gsc_data.json
```

**New finding generators (internal methods):**
- `_findings_from_on_page(data)` → findings for missing H1s, title length violations, meta description gaps, alt text below 80%
- `_findings_from_schema(data)` → findings for missing LocalBusiness/Organization/WebSite schema, missing required properties
- `_findings_from_robots(data)` → findings for crawl-delay, blocked paths, missing sitemap directive
- `_findings_from_sitemap(data)` → findings for suspicious staging URLs, sitemap not found
- `_findings_from_gsc(data)` → findings for high-impression/low-CTR pages, position 5-15 opportunities

**Updated `downstream_data` keys:**
```python
downstream_data={
    # existing
    "lighthouse": {...},
    "keyword_gaps": [...],
    "indexing_issues": [...],
    "nap_issues": [...],
    "aeo_gaps": [...],
    # new
    "gsc_opportunities": [...],     # pages at position 5-15 with impressions
    "schema_gaps": [...],           # missing schema types
    "on_page_issues": [...],        # title/meta/H1/alt violations
    "is_wordpress": bool,           # from tech_stack, used by downstream
}
```

---

### 4. `tools/seo_analyzer.py` (extend existing)

Add new sub-section generators:

**`generate_technical_seo_subsection()`** — robots.txt + sitemap health
- Table: Sitemap URL count, suspicious URLs found, robots.txt crawl-delay, critical blocks
- Findings: any issues from probes

**`generate_on_page_subsection()`** — per-page optimization metrics
- Table: pages analyzed, % with optimized titles, % with good meta, H1 coverage, image alt text %
- Findings: worst violations

**`generate_schema_subsection()`** — structured data coverage
- Table: schema types found, types missing, pages with schema, pages without
- Findings: missing critical types, invalid properties

**`generate_gsc_subsection()`** — search console performance (only if gsc_data.json exists)
- Table: top 10 queries by impressions, position, CTR
- Opportunity table: pages at position 5-15 → "fix title/meta to move to page 1"
- Findings: specific pages + queries that are underperforming

---

### 5. `stages/analyze.py` (extend, wire in collection)

Add two calls at the top of the analyze stage, before `SectionOrchestrator.run()`:

```python
from tools.seo_probes import collect_seo_probes
from tools.gsc_connector import fetch_gsc_data

# Run probes (skip if JSON cached, fail silently)
collect_seo_probes(domain, data_dir, force=config.get("force_refresh", False))

# Fetch GSC (skip if not configured)
if config.get("gsc_account_slug"):
    fetch_gsc_data(domain, data_dir, config["gsc_account_slug"])
```

Client YAML gets new optional field:
```yaml
gsc_account_slug: advertisingreportcard-gmail-com
```

---

## Files Modified

| Action | Path |
|--------|------|
| New | `~/ai/agents/development/reportcard_agent/tools/seo_probes.py` |
| New | `~/ai/agents/development/reportcard_agent/tools/gsc_connector.py` |
| Extend | `~/ai/agents/development/reportcard_agent/tools/seo_tool.py` |
| Extend | `~/ai/agents/development/reportcard_agent/tools/seo_analyzer.py` |
| Extend | `~/ai/agents/development/reportcard_agent/stages/analyze.py` |

No new orchestrator registration needed - SEO tool is already registered. Only its internal data sources expand.

---

## Dependencies to Add

```
# Already present in google-oauth infra, need to add to reportcard requirements:
google-api-python-client>=2.0.0
google-auth>=2.0.0
google-auth-oauthlib>=1.0.0

# Already present in forensic probes, verify in reportcard env:
requests
beautifulsoup4
```

Forensic probe files are imported via PYTHONPATH. `seo_probes.py` adds `~/ai/tools/security/arc-forensic-audit` to `sys.path` at import time. Probes stay in their original location - single source of truth, changes apply everywhere.

---

## Verification

1. Run existing report against a client domain — should produce identical DOCX as before (graceful degradation if probes fail)
2. Check `data_dir/` for new JSON files: `seo_on_page.json`, `seo_sitemap.json`, `seo_robots.json`, `seo_schema.json`, `seo_tech_stack.json`
3. Verify new sub-sections appear in DOCX SEO section (Technical SEO Health, On-Page Optimization, Schema Coverage)
4. Run `~/ai/infra/google-oauth-setup/google_oauth.py smoke-test --account advertisingreportcard@gmail.com --service search-console`
5. With `gsc_account_slug` in YAML: verify `data_dir/gsc_data.json` populated, GSC Performance sub-section in DOCX

---

## What's NOT in This Plan

- Screaming Frog agent integration (Playwright dependency, slow - separate tool)
- External rank tracking APIs (SERPstat, Ahrefs) - Phase 3 after GSC proven
- AEO FAQ module - separate effort
- Backlink analysis - requires external API
- Yoast integration is included but only activates on WordPress sites (TechStackProbe detects CMS)
