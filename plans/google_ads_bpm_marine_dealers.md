# Google Ads Agent: BPM Marine Dealer Builds (8 Clients)

## Context

Singleton Marine was built as the first marine dealer in the OWM/BPM group. It produced a working template (`clients/bluepixelmedia/onewatermarine/templates/marine_search/`) that can be rendered for any marine dealer by swapping a `template_bindings.yaml`. We need to replicate this for all 8 remaining BPM dealerships. Each gets its own client directory, filled bindings file, rendered CSV, and validation pass.

---

## The 8 Dealers

| Slug | Display Name | Website | Discord Channel ID |
|------|-------------|---------|-------------------|
| `gardenstate` | Garden State Yacht Sales | gardenstateyachtsales.com | 1503445447170326601 |
| `norfolkmarine` | Norfolk Marine | norfolkmarine.com | 1503445450680828055 |
| `slalomshop` | Slalom Shop | slalomshop.com | 1503445453516050575 |
| `smgboats` | SMG Boats | smgboats.com | 1503445457295376507 |
| `southshoremarine` | South Shore Marine | southshoremarine.com | 1503445460608745502 |
| `sundancemarine` | Sundance Marine | sundancemarineusa.com | 1503445463586705418 |
| `sunrisemarine` | Sunrise Marine | sunrisemarine.com | 1503445483140550846 |
| `onewateryachtgroup` | One Water Yacht Group | owyg.com | 1503445487292776598 |

---

## Reference: How Singleton Was Built

**Files:**
- Template CSV (extracted from Singleton's account export): `clients/bluepixelmedia/onewatermarine/templates/marine_search/campaigns/account_export_template.csv`
- Blank bindings: `clients/bluepixelmedia/onewatermarine/templates/marine_search/config/template_bindings.yaml`
- Renderer: `shared/rebuild/marine_template.py`
- Scaffolder: `shared/rebuild/scaffold_client.py`
- Validator: `shared/rebuild/staging_validator.py`
- Website scanner: `shared/tools/website/website_scanner.py`

**Template structure uses `{{placeholder}}` tokens for every Singleton-specific value:**
- Client: `display_name`, `short_name`, `website_url`, `primary_phone`, `secondary_phone`
- Campaign: `name`, `daily_budget`, `status`
- Landing pages: 15 URL slots (homepage, about, contact, finance, new/used inventory, etc.)
- Stores: per-city + per-city inventory URL
- Geo targets: `(75mi:LAT:LON)` or county name
- RSA copy: 15 headlines + 4 descriptions
- Brands: name + inventory URL + brand page URL

---

## Build Steps (Per Dealer)

### Step 1 — Scaffold client directories (8x)

```bash
cd ~/ai/agents/ppc/google_ads_agent
for slug in gardenstate norfolkmarine slalomshop smgboats southshoremarine sundancemarine sunrisemarine onewateryachtgroup; do
  python3 shared/rebuild/scaffold_client.py --agency bluepixelmedia --client $slug
done
```

Creates: `clients/bluepixelmedia/<slug>/` with standard layout (build/, campaigns/, config/, docs/, reports/).

### Step 2 — Website scan each dealer

```bash
python3 shared/tools/website/website_scanner.py --url https://www.gardenstateyachtsales.com
# ... repeat per dealer
```

Extracts: all page URLs, phone numbers, boat brands detected. Store output in each dealer's `docs/`.

### Step 3 — Fill template_bindings.yaml per dealer

Copy blank template to each dealer:
```
clients/bluepixelmedia/<slug>/templates/marine_search/config/template_bindings.yaml
```

Fill in per-dealer data from website scan output:
- `client.display_name`, `short_name`, `website_url`, `primary_phone`
- All 15 `landing_pages.*` URLs (map from scan results)
- `stores[].city` + `stores[].inventory_url`
- `target_geo[].location` — use `(75mi:LAT:LON)` from dealer city coordinates
- `brands[]` — from website scan
- `copy.rsa` — generate via copy engine (Step 4)
- `campaign.daily_budget` — **TBD, needs BPM input**

### Step 4 — Generate RSA copy via copy engine

For each dealer, run `shared/copy_engine/search/copy_matrix.py` with:
- Client context: dealer name, location, brands, services
- Ad group: "Boat General/Regional Terms" (same structure as Singleton)

Copy engine uses Kimi-K2 for generation, Gemini 2.5 Flash for grading.

Populate `copy.rsa` in the bindings YAML with validated output.

### Step 5 — Render template → CSV

```bash
python3 shared/rebuild/marine_template.py render \
  --bindings clients/bluepixelmedia/<slug>/templates/marine_search/config/template_bindings.yaml \
  --template clients/bluepixelmedia/onewatermarine/templates/marine_search/campaigns/account_export_template.csv \
  --output clients/bluepixelmedia/<slug>/build/current/
```

Generates: `<DealerName>++Search - <Dealer> - Boat General-Regional Terms+8_Ad groups+<date>.csv`

### Step 6 — Validate CSV

```bash
python3 shared/rebuild/staging_validator.py \
  --csv clients/bluepixelmedia/<slug>/build/current/<output>.csv
```

Fix any character violations, policy flags, RSA mix failures before proceeding.

---

## What We're Missing Per Dealer (needs research or BPM input)

| Item | Source |
|------|--------|
| Phone numbers | Website scan (Step 2) |
| Landing page URLs | Website scan (Step 2) |
| Boat brands carried | Website scan (Step 2) |
| Store locations / cities | Website scan (Step 2) |
| Geo target coordinates | Geocode from city (can auto) |
| Daily budgets | **BPM must provide** |
| RSA copy | Copy engine (Step 4) |
| Account IDs (Google Ads) | BPM must provide when accounts created |

---

## Improvements Found Along the Way

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| 1 | `marine_template.py` hardcodes Singleton constants at top (`SINGLETON_CAMPAIGN`, `SINGLETON_BRAND`, `SINGLETON_HOST`, etc.) — breaks if you use it without Singleton as source | `shared/rebuild/marine_template.py` lines 20-70 | Accept `--source-client` flag or read from bindings; don't rely on hardcoded Singleton values for new renders |
| 2 | Blank `template_bindings.yaml` lives inside a client dir (`clients/bluepixelmedia/onewatermarine/templates/`) — not in shared | `clients/bluepixelmedia/onewatermarine/templates/marine_search/config/` | Copy/symlink to `shared/rebuild/templates/marine_search/template_bindings.yaml` as the canonical blank |
| 3 | No batch scaffold script — 8 `scaffold_client.py` calls must be done manually | `shared/rebuild/scaffold_client.py` | Add `--batch` mode or a simple loop wrapper |
| 4 | Website scanner not wired into onboarding pipeline — manual step | `shared/tools/website/website_scanner.py` | Invoke automatically from `scaffold_client.py` when `--website` flag provided |
| 5 | Geo target coordinates require manual lookup per dealer | `template_bindings.yaml` `target_geo` | Add geocoding helper that takes city names from store list → lat/lon radius targets |
| 6 | `template_manifest.json` lives in the client dir with no generator — must be hand-created | `clients/bluepixelmedia/onewatermarine/templates/marine_search/template_manifest.json` | Generate manifest automatically when rendering template |
| 7 | Discord channel IDs already in Supabase (`clients` table) but not auto-wired to `client_hq.json` | `docs/client_hq/client_hq.json` | Scaffold step should pull discord_channel_id from Supabase by slug when creating client dir |

---

## Execution Order

1. Scaffold all 8 dirs (Step 1) — fast, no dependencies
2. Website scan all 8 (Step 2) — parallel, no dependencies
3. Fill bindings YAML for each (Step 3) — depends on scan output; budgets blocked on BPM
4. Generate RSA copy (Step 4) — depends on bindings
5. Render CSVs (Step 5) — depends on filled bindings + copy
6. Validate (Step 6) — depends on rendered CSVs
7. Fix improvements #1 and #2 — unblock before Step 5

---

## Out of Scope

- Creating the actual Google Ads accounts (BPM does this)
- Uploading to Google Ads Editor (manual step after client review)
- Campaign 2+ builds (brand, performance max, etc.) — after Campaign 1 data
