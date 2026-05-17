# Google Ads Agent - Bulk Pipeline + Agent Improvements

## Context

Built 8 BPM marine dealer Campaign 1 CSVs this session (gardenstate, norfolkmarine, slalomshop, smgboats, southshoremarine, sundancemarine, sunrisemarine, onewateryachtgroup). Every step was a manually wired ad-hoc script: website scan → fill bindings → render → validate → Discord post. Each step required knowing file paths, arg formats, and running in sequence. This plan fixes that with a batch runner + addresses every improvement found along the way.

---

## What Was Accomplished This Session

| # | Task | Status |
|---|------|--------|
| 1 | Created 8 WLW Discord channels (🚤 emoji, boat emoji) | Done |
| 2 | Deleted duplicate channels, kept boat-emoji set | Done |
| 3 | Fixed discord_agent config_loader.py (AlphaClaw as canonical ARC bot, OpenBao-first) | Done |
| 4 | Migrated 6 Discord bot tokens to OpenBao secret/shared/discord-* | Done |
| 5 | Updated servers.json + server_docs.md with all 10 WLW channel aliases | Done |
| 6 | Updated all memory + reference docs for Discord | Done |
| 7 | Created 8 Supabase company records (parent: onewatermarine) | Done |
| 8 | Created 8 Supabase client records (intermediate: BPM, relationship: WLW) | Done |
| 9 | Scaffolded 8 client dirs under clients/bluepixelmedia/ | Done |
| 10 | Ran website scans on all 8 dealer sites | Done |
| 11 | Filled template_bindings.yaml for all 8 dealers ($20/day, scan data + web fetch) | Done |
| 12 | Rendered 8 Google Ads Editor CSVs via marine_template.py | Done |
| 13 | Posted all 8 CSVs to Discord with BPM briefing checklist | Done |

---

## Issues Found (Improvements Needed)

### P0 - Blocking for any future new dealer

**#1 marine_template.py hardcodes Singleton constants (lines 20-70)**
- File: `shared/rebuild/marine_template.py`
- Problem: `SINGLETON_CAMPAIGN`, `SINGLETON_BRAND`, `SINGLETON_HOST`, `SINGLETON_STORES`, `SINGLETON_BRANDS`, `SINGLETON_PHONE_MAP`, `SINGLETON_URL_MAP`, `SINGLETON_GEO_MAP` are hardcoded
- These are used during template EXTRACTION (analyze/extract commands) to reverse-map Singleton URLs → {{placeholders}}
- The render command does NOT use them - render only uses the bindings YAML
- Fix: The extract command should accept a `--source-bindings` arg to know which URLs to replace. For new dealers, extraction is never re-run (template already extracted). So these constants don't break rendering. Mark as low-priority cleanup.
- **Actual severity: low** - render works fine without touching these

**#2 RSA copy descriptions don't use approved CTAs**
- Problem: The 4 descriptions we generated use "stop by today", "shop now", "visit today" which are NOT in `DEFAULT_DESCRIPTION_CTAS` in staging_validator.py
- Approved CTAs: "call us today", "call today", "compare options", "schedule today", "request a quote", "request details", "book today"
- Current validation: 4 `description_missing_cta` errors per dealer (32 total across 8)
- Fix: Update description templates in bindings fill script to include an approved CTA in each description

**#3 Website scanner crawled only 5 pages (max_pages=5 - wrong default)**
- Default is 12 pages. We ran with max_pages=5 in a prior session (reduced to avoid timeout)
- Missed: inventory pages, contact, finance, brand pages
- We had to make 40+ additional WebFetch calls manually to fill the gaps
- Fix: Run scanner at default 12 pages, or add targeted URL list (known OWM URL patterns)

### P1 - Bulk pipeline (the main improvement)

**#4 No batch runner - everything was ad-hoc**
- Every step required a manual script
- Scan → fill → render → validate → post = 5 separate invocations per dealer × 8 dealers = 40 manual steps
- Fix: `shared/rebuild/marine_batch.py` - single CLI that orchestrates all steps from a dealer config YAML

### P2 - Copy engine not wired

**#5 RSA copy hand-crafted, not copy-engine generated**
- Copy engine exists at `shared/copy_engine/orchestrator.py` with `--mode generate`
- Uses Kimi-K2 for generation + Gemini 2.5 Flash for grading
- Currently not wired into the marine template build pipeline
- We used Singleton's RSA pattern as a manual template
- Fix: Call copy_engine generate per dealer ad group before filling bindings

**#6 copy_engine generate mode not wired to CSV output**
- `orchestrator.py --mode generate` produces an HTML HITL report but doesn't write to bindings YAML
- Fix: Add `--output-bindings` flag to orchestrator, or create a thin shim in marine_batch.py that reads copy engine output and writes to bindings

### P3 - Data quality

**#7 Geo coordinates manually looked up**
- We geocoded 8 dealers manually (searching known city lat/lon)
- Fix: Add geocoding helper using Google Maps Geocoding API or a geocoder library
- File to add: `shared/tools/geo/geocoder.py`

**#8 Brand inventory URLs are placeholders**
- All 8 dealers use `/search/condition-new/` as brand inventory URL placeholder
- Real pattern: `/search/sbdealer-{dealer-slug}/make-{BrandName}/`
- Dealer slug is unique per site (e.g., Singleton = "singleton-marine-blue-creek-marina")
- Fix: Fetch `/search/condition-new/` and parse the filter dropdown to find the sbdealer slug

**#9 Store-specific inventory URLs unknown (myStoreBoats IDs)**
- Real pattern: `/search/myStoreBoats-{id}/` where id is a site-specific integer
- We used `/search/condition-new/` as placeholder for all
- Only South Shore Marine (id=12) was discoverable from homepage HTML
- Fix: Parse the store dropdown on the inventory page to find per-store IDs

### P4 - Minor improvements

**#10 template_bindings.yaml canonical blank lives in wrong place**
- Currently in `clients/bluepixelmedia/onewatermarine/templates/marine_search/config/`
- Should be in `shared/rebuild/templates/marine_search/config/`
- Partially addressed (canonical blank exists in shared/) but not enforced

**#11 No template_manifest.json generator**
- `template_manifest.json` must be hand-created (currently only in onewatermarine)
- Fix: Auto-generate in marine_template.py extract command or scaffold

**#12 Discord channel IDs in Supabase not auto-wired**
- After Supabase insert, `client_hq.json` still needs manual update
- Fix: scaffold_client.py should query Supabase by slug to pull discord_channel_id

---

## Recommended Implementation: marine_batch.py

Single new file: `shared/rebuild/marine_batch.py`

### What it does

```bash
python -m shared.rebuild.marine_batch \
  --agency bluepixelmedia \
  --config shared/rebuild/templates/marine_search/bpm_dealers.yaml \
  [--steps scan,fill,render,validate,post] \
  [--dealers gardenstate norfolkmarine] \   # subset filter
  [--dry-run]
```

### Config file: bpm_dealers.yaml

```yaml
# shared/rebuild/templates/marine_search/bpm_dealers.yaml
template_csv: clients/bluepixelmedia/onewatermarine/templates/marine_search/campaigns/account_export_template - one water marine.csv
discord_bot: arc   # resolves via config_loader.py

dealers:
  - slug: gardenstate
    display_name: Garden State Yacht Sales
    short_name: Garden State
    domain: gardenstateyachtsales.com
    primary_phone: "(732) 892-4222"
    secondary_phone: "(678) 929-6268"
    primary_city: Point Pleasant
    states: NJ & FL
    discord_channel_id: "1503445447170326601"
    daily_budget: 20.00
    stores:
      - city: Point Pleasant
        state: NJ
      - city: Cape Coral
        state: FL
  # ... 7 more dealers
```

### Steps

1. **scan** - Run website_scanner.py per dealer (parallel via ThreadPoolExecutor)
   - Output: `clients/{agency}/{slug}/docs/website_scan/website_scan.json`
   - Skip if fresh scan exists (< 7 days old)

2. **fill** - Read scan + config → write template_bindings.yaml
   - Extract phones, landing pages, brands from scan JSON
   - Apply $daily_budget, RSA copy template (Singleton-pattern)
   - **Fix CTA issue**: Use "Call us today" + "Compare options" in descriptions
   - Geocode store cities → lat/lon targets (cache results)

3. **render** - Run marine_template.py render per dealer
   - Output: `clients/{agency}/{slug}/build/current/{DealerName}++...+{date}.csv`
   - Construct filename via csv_naming.py convention

4. **validate** - Run staging_validator.py per dealer
   - Write JSON report to `clients/{agency}/{slug}/reports/validation_{date}.json`
   - Print error/warning summary
   - Known-OK errors (exact match keywords, Location ID header) are pre-filtered

5. **post** - Post CSV + briefing to Discord channel
   - AlphaClaw bot via 1P credential
   - Message template: dealer name, budget, brands, stores, geo, what BPM needs to confirm

### Files to create/modify

| File | Change |
|------|--------|
| `shared/rebuild/marine_batch.py` | **NEW** - main batch orchestrator |
| `shared/rebuild/templates/marine_search/bpm_dealers.yaml` | **NEW** - dealer config YAML |
| `shared/rebuild/marine_template.py` | **MODIFY** - improve `--output` to accept dir and auto-name file |
| `shared/rebuild/staging_validator.py` | **MODIFY** - add `--known-ok-rules` flag to suppress template noise |
| `shared/tools/geo/geocoder.py` | **NEW** - city name → lat/lon (use geopy or hardcoded cache) |

### Description CTA fix (immediate, no batch needed)

In the bindings fill logic, change 4 descriptions to use approved CTAs:
- DESC1: "...Call us today for expert guidance on finding the right boat for your needs"
- DESC2: "...Compare options from top brands at {DealerName}. Request details today"
- DESC3: "...Browse inventory in {city}. Compare local boat brands and call us today"
- DESC4: "...{B1}, {B2} and {B3} in stock. Compare options at {sname} today"

---

## Out of Scope (This Plan)

- Campaign 2+ builds (brand, performance max) - after Campaign 1 data
- Google Ads account ID wiring (BPM provides)
- copy_engine RSA generation (separate task after copy engine --mode generate is fixed)
- Singleton marine_template.py constant cleanup (render works fine, low priority)
- Merging BluePixelMedia.io Supabase duplicate

---

## Verification

After implementing marine_batch.py:

```bash
# Dry run all 8 dealers - see what would run
python -m shared.rebuild.marine_batch \
  --agency bluepixelmedia \
  --config shared/rebuild/templates/marine_search/bpm_dealers.yaml \
  --dry-run

# Re-run just render + validate for one dealer (bindings already filled)
python -m shared.rebuild.marine_batch \
  --agency bluepixelmedia \
  --config shared/rebuild/templates/marine_search/bpm_dealers.yaml \
  --dealers gardenstate \
  --steps render,validate

# Full run for a new dealer added to the config
python -m shared.rebuild.marine_batch \
  --agency bluepixelmedia \
  --config shared/rebuild/templates/marine_search/bpm_dealers.yaml \
  --dealers newdealer \
  --steps scan,fill,render,validate,post
```

Expected output:
- Zero `description_missing_cta` errors (fix #2 applied)
- Same skipped-row count as current (indexed placeholders for missing brands/stores/geo)
- CSV posted to Discord with 1 command vs 5 ad-hoc scripts
