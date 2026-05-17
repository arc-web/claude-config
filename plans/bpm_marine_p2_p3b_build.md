# BPM Marine P2 + P3b Build Plan

## Context

Three GitHub/Plane tasks outstanding for the Google Ads agent marine batch pipeline:
- ADS-47 / GH#55 - Replace static hand-crafted RSA copy with AI-generated copy (Kimi-K2 + Gemini grader)
- ADS-48 / GH#56 - Auto-detect brand page URLs from dealer inventory HTML instead of using `/search/condition-new/` placeholder
- ADS-49 / GH#57 - Auto-detect per-store inventory URLs from dealer inventory HTML instead of placeholder

All three land in a single new file: `shared/rebuild/marine_bindings_builder.py`. The existing `batch_runner.py` `run_fill` function gets wired to call it.

**Critical discovery from exploration:** The current `_build_bindings` in `batch_runner.py` writes the wrong YAML key structure. `marine_template.py` expects `copy.rsa.headline_1...15` and `description_1...4` (numbered), plus ~12 additional fields (`client.display_name`, `client.website_host`, `campaign.status`, `target_geo`, `brand_summary`, etc.) that are completely missing. The render step would fail on a real run. This gets fixed as part of P2.

---

## What Gets Built

### `shared/rebuild/marine_bindings_builder.py` (new file)

**Function: `build_bindings(config: dict, dealer: dict) -> dict`**

Returns the complete YAML dict that `marine_template.py` expects. Called by `batch_runner.py run_fill`.

#### Step 1 - Fetch and parse inventory page HTML (P3b)

```python
def _fetch_inventory_html(domain: str) -> str:
    url = f"https://www.{domain}/search/condition-new/"
    req = urllib.request.Request(url, headers={"User-Agent": "..."})
    with urllib.request.urlopen(req, timeout=15) as r:
        return r.read().decode("utf-8")
```

Parse with stdlib `html.parser`:
- **sbdealer slug** - scan `<option>` or `<a>` values for pattern `sbdealer-{slug}` in filter dropdowns
- **myStoreBoats IDs** - scan for `myStoreBoats-{id}` values, map numeric ID to store city via text content

Build brand URLs: `https://www.{domain}/search/sbdealer-{slug}/make-{BrandName}/`
Build store URLs: `https://www.{domain}/search/myStoreBoats-{id}/`

Fall back to `/search/condition-new/` gracefully if parsing fails (logs warning, doesn't crash).

#### Step 2 - Build AdGroupContext for copy generation (P2)

```python
AdGroupContext(
    name="Boat General/Regional Terms",
    service="new and used boat sales",
    geo=[f"{s['city']}, {s['state']}" for s in dealer["stores"]],
    USPs=["authorized dealer", "multiple brands in stock", "marine financing available", "full-service center"],
    top_keywords=["boat dealer", "boats for sale", "new boats", brand_names...],
    landing_url=f"https://www.{dealer['domain']}/",
    industry="marine_dealer",
    additional_context=f"Brands carried: {', '.join(dealer['brands'])}. Serving {dealer['states']}.",
)
```

#### Step 3 - Generate and grade copy (P2)

```python
from shared.copy_engine.search.headlines import HeadlineGenerator
from shared.copy_engine.search.descriptions import DescriptionGenerator
from shared.copy_engine.editor.grader import CopyGrader
from shared.copy_engine.models import OpenRouterClient
from shared.rebuild.cta_config import load_cta_set

llm = OpenRouterClient()
headlines = HeadlineGenerator(llm).generate(ctx, count=15)   # returns list[Headline]
descs = DescriptionGenerator(llm).generate(ctx, count=4)     # returns list[Description]

# Validate descriptions have marine CTA phrase
cta_set = load_cta_set("marine_dealer")
for d in descs:
    if not any(cta in d.text.lower() for cta in cta_set):
        # log warning - grader will surface this
        pass

grade = CopyGrader(llm).grade_ad_group(
    headlines=[h.text for h in headlines],
    descriptions=[d.text for d in descs],
    context=f"Marine boat dealer, {dealer['primary_city']}",
)
# grade summary logged but does not block - grader is advisory
```

#### Step 4 - Assemble full bindings dict

Produce the exact schema `marine_template.py` expects:

```yaml
client:
  display_name: <dealer.display_name>
  short_name: <dealer.short_name>
  website_url: https://www.<domain>/
  website_host: www.<domain>
  primary_phone: <dealer.primary_phone>
  secondary_phone: <dealer.secondary_phone or primary_phone>
  location_coverage_claim: "Serving <dealer.states>"

campaign:
  name: "Search - <display_name> - Boat General/Regional Terms"
  status: Paused
  ad_group_status: Enabled
  default_asset_status: Eligible
  daily_budget: <dealer.daily_budget>
  bid_strategy_type: Manual CPC

landing_pages:
  homepage_url: https://www.<domain>/
  about_url: https://www.<domain>/about-us/
  contact_url: https://www.<domain>/contact-us/
  locations_url: https://www.<domain>/contact-us/#locations/
  new_inventory_url: https://www.<domain>/search/condition-new/
  used_inventory_url: https://www.<domain>/search/condition-used/
  finance_url: https://www.<domain>/financing/
  store_sales_url: https://www.<domain>/search/condition-new/
  trade_value_url: https://www.<domain>/trade-in/
  sell_boat_url: https://www.<domain>/sell-my-boat/
  specials_url: https://www.<domain>/specials/

stores:
  - city: <city>
    state: <state>
    path_city: <city.replace(" ", "-").lower()>
    inventory_url: <parsed myStoreBoats URL or fallback>
    lat: <geocoded>
    lon: <geocoded>
    phone: <primary for first, secondary for rest>

target_geo:
  - location: "<city>, <state>"   # one per store

brand_summary:
  label: "<b0>, <b1> & <b2>"
  short: "<b0> & <b1>"
  full: "<b0>, <b1>, <b2>, ..."

brands:
  - name: <brand>
    inventory_url: <parsed sbdealer+make URL or fallback>
    brand_url: <parsed sbdealer+make URL or fallback>

copy:
  rsa:
    headline_1: <headlines[0].text>
    headline_2: <headlines[1].text>
    ...
    headline_15: <headlines[14].text>
    description_1: <descs[0].text>
    description_2: <descs[1].text>
    description_3: <descs[2].text>
    description_4: <descs[3].text>
```

---

### `shared/rebuild/batch_runner.py` (edit)

Replace `_build_bindings` and its call in `run_fill`:

```python
# Before (remove):
bindings = _build_bindings(config, dealer)

# After:
from shared.rebuild.marine_bindings_builder import build_bindings
bindings = build_bindings(config, dealer)
```

Remove the old `_build_bindings` function entirely.

---

## Execution Plan (post-approval)

Sub-agent 1 builds `marine_bindings_builder.py` (all three tasks in one file).
Sub-agent 2 edits `batch_runner.py` to wire it in and remove `_build_bindings`.

### Verification

```bash
# Dry-run to confirm paths resolve
python3 -m shared.rebuild.batch_runner \
  --config shared/batch_configs/bpm_marine_2026.yaml \
  --dealers gardenstate --steps fill,render,validate --dry-run

# Real run on one dealer (gardenstate) - fill + render + validate, no post
python3 -m shared.rebuild.batch_runner \
  --config shared/batch_configs/bpm_marine_2026.yaml \
  --dealers gardenstate --steps fill,render,validate
```

Check: CSV renders without `{{...}}` placeholders, validator passes with `marine_dealer` CTA profile, grade report logged to console.

### Plane + GitHub cleanup (after verify passes)

- PATCH ADS-47, 48, 49 → Done state (`f8affb80-7133-436b-b199-1941f5c1d30e`)
- Close GH#55, #56, #57 with comment linking to commit

---

## Critical Files

| File | Action |
|------|--------|
| `shared/rebuild/marine_bindings_builder.py` | Create |
| `shared/rebuild/batch_runner.py` | Edit - swap `_build_bindings` for import |
| `shared/copy_engine/search/headlines.py` | Read-only (reuse `HeadlineGenerator`) |
| `shared/copy_engine/search/descriptions.py` | Read-only (reuse `DescriptionGenerator`) |
| `shared/copy_engine/editor/grader.py` | Read-only (reuse `CopyGrader`) |
| `shared/copy_engine/models.py` | Read-only (reuse `OpenRouterClient`) |
| `shared/rebuild/cta_config.py` | Read-only (reuse `load_cta_set`) |
| `shared/tools/geo/geocoder.py` | Read-only (reuse `geocode`) |
