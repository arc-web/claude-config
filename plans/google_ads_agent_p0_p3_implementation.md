# Google Ads Agent: P0-P3 Implementation Plan

## Context

4 improvements from the BPM marine dealer build session:
- **P0**: `DEFAULT_DESCRIPTION_CTAS` hardcoded Python set in `staging_validator.py:78-97`. Breaks as new client industries are added (marine CTAs differ from therapy CTAs).
- **P1**: Marine build was 5 ad-hoc `/tmp/` scripts manually stitched. Need one batch CLI for any client, any template type.
- **P2**: RSA copy hand-crafted from Singleton pattern. `HeadlineGenerator` + `DescriptionGenerator` + `CopyGrader` (Kimi-K2 + Gemini 2.5 Flash) already exist but not wired into marine build path.
- **P3**: Geo coords manually looked up. Brand/store inventory URLs set to `/search/condition-new/` placeholder - resolvable from the inventory page HTML.

---

## P0 — CTA Config as Data File

### What exists now
```python
# staging_validator.py lines 78-97 — hardcoded, not extensible
DEFAULT_DESCRIPTION_CTAS = {
    "apply today", "book a consultation", "book a tasting menu",
    "book today", "book your reservation", "call today", "call us today",
    "check availability", "compare options", "confirm fit", "plan next steps",
    "request a quote", "request details", "reserve your table",
    "review program fit", "schedule a review", "schedule service", "schedule today",
}
```

Used in `has_description_cta(value: str) -> bool` at line 649:
```python
def has_description_cta(value: str) -> bool:
    lower = value.lower()
    return any(cta in lower for cta in DEFAULT_DESCRIPTION_CTAS)
```

### New file: `shared/config/cta_profiles.yaml`

```yaml
# CTA phrase sets by industry. 'extends' merges parent entries.
general:
  - apply today
  - book today
  - call today
  - call us today
  - check availability
  - compare options
  - confirm fit
  - plan next steps
  - request a quote
  - request details
  - schedule a review
  - schedule service
  - schedule today

marine_dealer:
  extends: general
  add:
    - visit our showroom
    - schedule a sea trial
    - see our inventory
    - view our fleet
    - shop our boats
    - get a trade quote

health_therapy:
  extends: general
  add:
    - book a consultation
    - book a tasting menu
    - book your reservation
    - reserve your table
    - review program fit
    - confirm fit

legal:
  extends: general
  add:
    - schedule a consultation
    - get a free case review
    - speak with an attorney
    - request a callback

home_services:
  extends: general
  add:
    - get a free estimate
    - book a service call
    - schedule an inspection
    - request a callback
```

### New file: `shared/rebuild/cta_config.py`

```python
"""Load and resolve CTA phrase sets from shared/config/cta_profiles.yaml."""
from __future__ import annotations
import yaml
from functools import lru_cache
from pathlib import Path

CONFIG_PATH = Path(__file__).resolve().parents[2] / "shared" / "config" / "cta_profiles.yaml"

@lru_cache(maxsize=None)
def _load_raw() -> dict:
    return yaml.safe_load(CONFIG_PATH.read_text(encoding="utf-8"))

def load_cta_set(profile: str = "general") -> frozenset[str]:
    """Return merged CTA set for a profile, resolving 'extends' chain."""
    raw = _load_raw()
    if profile not in raw:
        raise ValueError(f"Unknown CTA profile {profile!r}. Available: {list(raw)}")
    result = set()
    visited = []
    _resolve(raw, profile, result, visited)
    return frozenset(result)

def _resolve(raw: dict, profile: str, result: set, visited: list) -> None:
    if profile in visited:
        return
    visited.append(profile)
    entry = raw.get(profile, {})
    if isinstance(entry, list):
        result.update(entry)
        return
    parent = entry.get("extends")
    if parent:
        _resolve(raw, parent, result, visited)
    result.update(entry.get("add", []))

def available_profiles() -> list[str]:
    return list(_load_raw().keys())
```

### Modify: `shared/rebuild/staging_validator.py`

Three changes:
1. Replace hardcoded `DEFAULT_DESCRIPTION_CTAS` set with import + lazy load
2. Add `cta_profile: str = "general"` param to `validate_file()`
3. Add `--cta-profile` CLI arg

```python
# REMOVE lines 78-97 (DEFAULT_DESCRIPTION_CTAS set)
# ADD at top of file:
from shared.rebuild.cta_config import load_cta_set

# CHANGE validate_file signature from:
def validate_file(csv_path: Path, match_type_mode: str = "new_rebuild", ...) -> dict:
# TO:
def validate_file(csv_path: Path, match_type_mode: str = "new_rebuild",
                  cta_profile: str = "general", ...) -> dict:

# CHANGE has_description_cta() call inside validate_file to pass profile:
#   currently: not has_description_cta(value)
#   becomes:   not has_description_cta(value, cta_set=load_cta_set(cta_profile))

# CHANGE has_description_cta() signature:
def has_description_cta(value: str, cta_set: frozenset[str] | None = None) -> bool:
    pool = cta_set if cta_set is not None else load_cta_set("general")
    lower = value.lower()
    return any(cta in lower for cta in pool)

# ADD to argparse in main():
parser.add_argument("--cta-profile", default="general",
                    choices=available_profiles(),
                    help="CTA phrase profile (default: general)")
```

---

## P1 — Generic Batch Runner

### Design

Two client build types:
- **`template`** — substitute {{placeholders}} in an existing template CSV (marine dealers, any client with a pre-extracted template)
- **`fresh_build`** — call `account_pipeline.py --mode build` (full website scan + copy engine + CSV generation from scratch)

The batch runner routes each client to the right pipeline and runs all steps.

### New file: `shared/batch_configs/bpm_marine_2026.yaml`

```yaml
batch_name: bpm_marine_dealers_2026_q2
agency: bluepixelmedia
discord_post: true
discord_bot: arc           # resolves via config_loader.py → AlphaClaw token

clients:
  - slug: gardenstate
    display_name: Garden State Yacht Sales
    type: template
    template: marine_search
    template_csv: clients/bluepixelmedia/onewatermarine/templates/marine_search/campaigns/account_export_template - one water marine.csv
    discord_channel_id: "1503445447170326601"
    daily_budget: 20.00
    website: https://www.gardenstateyachtsales.com
    primary_phone: "(732) 892-4222"
    primary_city: Point Pleasant
    primary_state: NJ
    states: NJ & FL
    stores:
      - {city: Point Pleasant, state: NJ}
      - {city: Cape Coral, state: FL}
    brands: [Cobia, Everglades, Pathfinder, Pursuit, Sea Pro]
    # ... remaining 7 dealers same structure

  # Example fresh_build entry for a new non-marine client:
  - slug: new_client_example
    display_name: New Client
    type: fresh_build
    website: https://www.newclient.com
    discord_channel_id: "1234567890"
    daily_budget: 50.00
    workflow: new_campaign    # passed to account_pipeline.py --workflow
```

### New file: `shared/rebuild/batch_runner.py`

```
CLI:  python -m shared.rebuild.batch_runner
Args:
  --config   PATH     batch YAML config (required)
  --clients  SLUG...  run only these slugs (default: all)
  --steps    STEPS    comma-separated: scan,fill,render,validate,post (default: all)
  --force             re-run even if output artifacts exist
  --dry-run           print what would run, execute nothing
  --parallel          run scan steps concurrently (ThreadPoolExecutor)
  --cta-profile STR   override CTA profile for validation (default: from config or "general")
```

**Step dispatch table (template type):**

| Step | Action | Input | Output |
|------|--------|-------|--------|
| scan | `website_scanner.py --url {website} --output-dir docs/website_scan/ --max-pages 12` | website URL | `docs/website_scan/website_scan.json` |
| fill | `marine_bindings_builder.py` (new) | scan JSON + client config | `templates/marine_search/config/template_bindings.yaml` |
| render | `marine_template.py render --template-csv ... --bindings ... --output ...` | bindings YAML | `build/current/{DealerName}++...+{date}.csv` |
| validate | `staging_validator.py --csv ... --cta-profile marine_dealer` | rendered CSV | console summary + `reports/validation_{date}.json` |
| post | Discord multipart POST with CSV + briefing message | rendered CSV | Discord message |

**Step dispatch table (fresh_build type):**

| Step | Action |
|------|--------|
| scan+fill+render | `account_pipeline.py --mode build --agency ... --client ... --workflow ...` |
| validate | `staging_validator.py --csv {build_dir}/staging/*.csv` |
| post | Discord post with HTML report + CSV |

**Skip logic:** each step checks its output artifact timestamp. Skip if exists AND not `--force` AND < 7 days old.

**Key internal functions:**
```python
def run_batch(config: dict, clients_filter: list[str], steps: list[str],
              force: bool, dry_run: bool, parallel: bool) -> dict[str, StepResult]

def run_client(client_cfg: dict, agency: str, steps: list[str],
               force: bool, dry_run: bool) -> StepResult

def run_scan(client_cfg: dict, base: Path, force: bool) -> Path   # returns scan JSON path
def run_fill(client_cfg: dict, base: Path, scan_path: Path) -> Path  # returns bindings path
def run_render(client_cfg: dict, base: Path, bindings_path: Path) -> Path  # returns CSV path
def run_validate(csv_path: Path, cta_profile: str) -> ValidationSummary
def run_post(client_cfg: dict, csv_path: Path, token: str) -> bool
```

**Output:** JSON summary of all steps + status per client printed to stdout.

### Modify: `shared/rebuild/marine_template.py` render command

Change `--output` to accept a directory OR file path. If dir given, auto-name the file:
```python
# In render argparse:
render.add_argument("--output", type=Path, required=True,
                    help="Output file path OR directory (auto-names if dir)")

# In main(), before calling render_template:
if args.output.is_dir() or not args.output.suffix:
    from datetime import date
    safe_name = bindings_data['campaign']['name'].replace('/', '-').replace(' ', '_')
    args.output = args.output / f"{safe_name}+{date.today().isoformat()}.csv"
    args.output.parent.mkdir(parents=True, exist_ok=True)
```

---

## P2 — Wire Copy Engine for RSA Generation

### What exists
- `shared/copy_engine/search/headlines.py` → `HeadlineGenerator(llm).generate(ctx: AdGroupContext) -> list[Headline]`
- `shared/copy_engine/search/descriptions.py` → `DescriptionGenerator(llm).generate(ctx: AdGroupContext) -> list[Description]`
- `shared/copy_engine/editor/grader.py` → `CopyGrader(llm)` uses Gemini 2.5 Flash (Kimi-K2 corrupts JSON grading)
- `shared/copy_engine/models.py` → `OpenRouterClient()` fetches key from 1P item `53matr2yq5fmikn3hl2obt5kku` vault ARC field `credential`
- `shared/copy_engine/context.py` → `AdGroupContext(name, service, geo, USPs, top_keywords, landing_url, industry, practice_name)`

### New file: `shared/rebuild/marine_bindings_builder.py`

Replaces the ad-hoc `/tmp/fill_bindings.py`. Builds `template_bindings.yaml` for a marine dealer using copy engine for RSA section.

```
CLI:  python -m shared.rebuild.marine_bindings_builder
Args:
  --agency       STR   e.g. bluepixelmedia
  --slug         STR   e.g. gardenstate
  --config       PATH  batch YAML config (reads dealer entry)
  --skip-copy-engine   use Singleton-pattern fallback copy (no LLM call)
  --cta-profile  STR   default: marine_dealer
```

**Internal flow:**

```
1. Load client entry from batch config YAML
2. Load website_scan.json from docs/website_scan/
3. Geocode each store city → lat/lon  [P3a]
4. Resolve brand URLs from inventory page  [P3b]
5. Build AdGroupContext:
     AdGroupContext(
         name="Boat General/Regional Terms",
         service="new and used boat sales",
         geo=[primary_city, state, *additional_states],
         USPs=["local marine dealer", "top brands", "financing available",
               "new & used inventory", f"{len(brands)} brands in stock"],
         top_keywords=["boat dealer", "boat sales", "boats for sale near me",
                       "new boats for sale", "used boats for sale"],
         landing_url=f"https://www.{domain}/",
         industry="marine_dealer",
         practice_name=display_name,
     )
6. llm = OpenRouterClient()
7. headlines = HeadlineGenerator(llm).generate(ctx, count=15)
8. descriptions = DescriptionGenerator(llm).generate(ctx, count=4)
   → verify each description contains a marine_dealer CTA; retry once if not
9. Build full bindings dict (all 15 landing page URLs, stores, geo targets, brands)
10. Write template_bindings.yaml
```

**Fallback copy (--skip-copy-engine or LLM failure):**
Uses the Singleton-style templates with dealer-specific substitution, same as the current one-off script. Writes a `# GENERATED_BY: fallback` comment in the YAML.

**RSA descriptions with marine CTAs (hardcoded fallback):**
```python
MARINE_DESC_TEMPLATES = [
    "Own a boat built for your lifestyle. Compare local brands and call us today for expert guidance",
    "Find the right boat in {city}. Browse {dealer} inventory and compare options from top brands",
    "Shop new and used boats at {short_name}. Local inventory available. Request a quote today",
    "Shop {short_name} boat sales. {b1}, {b2} & {b3} available. Compare options and call us today",
]
```
Each contains at least one `marine_dealer` CTA phrase - passes validator.

---

## P3 — Geocoding + Brand URL Resolver

### P3a: Geocoding

**New file: `shared/tools/geo/__init__.py`** — empty package init

**New file: `shared/tools/geo/geocoder.py`**

```python
"""City name → (lat, lon) using Nominatim with local JSON cache."""
from __future__ import annotations
import json, time
from pathlib import Path

CACHE_PATH = Path(__file__).parent / "geocode_cache.json"
USER_AGENT = "google_ads_agent/1.0"

def geocode_city(city: str, state: str) -> tuple[float, float]:
    """
    Return (lat, lon) rounded to 4dp. Caches results to geocode_cache.json.
    Raises: RuntimeError if geocoding fails and no cache entry exists.
    """
    key = f"{city}, {state}"
    cache = _load_cache()
    if key in cache:
        return tuple(cache[key])

    from urllib.request import Request, urlopen
    from urllib.parse import urlencode
    import urllib.error

    params = urlencode({"q": f"{city}, {state}, USA", "format": "json", "limit": 1})
    url = f"https://nominatim.openstreetmap.org/search?{params}"
    req = Request(url, headers={"User-Agent": USER_AGENT})
    time.sleep(1.1)  # Nominatim rate limit: 1 req/sec
    try:
        with urlopen(req, timeout=10) as resp:
            results = json.loads(resp.read())
    except Exception as e:
        raise RuntimeError(f"Geocode failed for {key!r}: {e}") from e

    if not results:
        raise RuntimeError(f"No geocode result for {key!r}")

    lat = round(float(results[0]["lat"]), 4)
    lon = round(float(results[0]["lon"]), 4)
    cache[key] = [lat, lon]
    _save_cache(cache)
    return lat, lon

def geo_target_string(city: str, state: str, radius_mi: int = 75) -> str:
    """Return target_geo binding string: '(75mi:40.0878:-74.0464)'"""
    lat, lon = geocode_city(city, state)
    return f"({radius_mi}mi:{lat}:{lon})"

def _load_cache() -> dict:
    if CACHE_PATH.exists():
        return json.loads(CACHE_PATH.read_text())
    return {}

def _save_cache(cache: dict) -> None:
    CACHE_PATH.write_text(json.dumps(cache, indent=2))
```

No new dependencies - uses only stdlib `urllib` (same as `website_scanner.py`).

### P3b: Brand URL Resolver

**New function in `marine_bindings_builder.py`:** `resolve_inventory_metadata(domain: str, brands: list[str]) -> dict`

```python
def resolve_inventory_metadata(domain: str, brands: list[str]) -> dict:
    """
    Fetch /search/condition-new/ and extract:
    - sbdealer slug  (for /search/sbdealer-{slug}/make-{Brand}/)
    - store IDs       (for /search/myStoreBoats-{id}/)

    Returns:
      {
        "dealer_slug": "south-shore-marine-huron" | None,
        "store_ids": {"Huron": 12} | {},
        "brand_inventory_urls": {"Grady-White": "/search/sbdealer-.../make-Grady-White/"} | {}
      }
    Falls back to empty dicts silently (caller uses /search/condition-new/ placeholder).
    """
    import re, urllib.request, urllib.error

    try:
        url = f"https://www.{domain}/search/condition-new/"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=15) as r:
            html = r.read().decode("utf-8", errors="replace")
    except Exception:
        return {"dealer_slug": None, "store_ids": {}, "brand_inventory_urls": {}}

    # Extract sbdealer slug from hrefs like /search/sbdealer-<slug>/make-<Brand>/
    dealer_slugs = re.findall(r'/search/sbdealer-([^/]+)/make-', html)
    dealer_slug = dealer_slugs[0] if dealer_slugs else None

    # Extract myStoreBoats IDs from hrefs like /search/myStoreBoats-12/
    store_ids_raw = re.findall(r'/search/myStoreBoats-(\d+)/', html)
    # Can't map IDs to city names from HTML alone - return list of IDs found
    store_id_list = [int(i) for i in set(store_ids_raw)]

    brand_urls = {}
    if dealer_slug:
        for brand in brands:
            brand_urls[brand] = f"/search/sbdealer-{dealer_slug}/make-{brand}/"

    return {
        "dealer_slug": dealer_slug,
        "store_id_list": store_id_list,  # list of discovered IDs
        "brand_inventory_urls": brand_urls,
    }
```

---

## Files Summary

| File | Action | Notes |
|------|--------|-------|
| `shared/config/cta_profiles.yaml` | CREATE | ~50 lines, industry CTA sets |
| `shared/rebuild/cta_config.py` | CREATE | ~35 lines, YAML loader with extends resolution |
| `shared/rebuild/batch_runner.py` | CREATE | ~250 lines, multi-client batch CLI |
| `shared/batch_configs/bpm_marine_2026.yaml` | CREATE | All 8 BPM dealer entries |
| `shared/rebuild/marine_bindings_builder.py` | CREATE | ~200 lines, scan→bindings with copy engine |
| `shared/tools/geo/__init__.py` | CREATE | Empty package init |
| `shared/tools/geo/geocoder.py` | CREATE | ~60 lines, stdlib-only geocoder |
| `shared/rebuild/staging_validator.py` | MODIFY | Replace hardcoded set, add --cta-profile arg |
| `shared/rebuild/marine_template.py` | MODIFY | --output accepts dir, auto-names file |

No new pip dependencies. Uses only: stdlib `urllib`, existing `yaml`, existing copy engine, existing `OpenRouterClient`.

---

## Build Order

1. `cta_profiles.yaml` + `cta_config.py` → modify `staging_validator.py` (P0 - isolated)
2. `geocoder.py` (P3a - isolated)
3. `marine_template.py` --output dir fix (isolated)
4. `marine_bindings_builder.py` (P2+P3b - depends on geocoder + copy engine)
5. `bpm_marine_2026.yaml` (config file)
6. `batch_runner.py` (P1 - depends on all above)

---

## Verification

```bash
# P0: marine_dealer CTAs now pass for marine CSVs
python -m shared.rebuild.staging_validator \
  --csv "clients/bluepixelmedia/gardenstate/build/current/*.csv" \
  --cta-profile marine_dealer
# Expect: 0 description_missing_cta errors (was 4 per dealer)

# P0: general profile still works for non-marine
python -m shared.rebuild.staging_validator --csv ... --cta-profile general

# P3a: geocoder
python -c "
from shared.tools.geo.geocoder import geocode_city, geo_target_string
print(geocode_city('Point Pleasant', 'NJ'))      # (40.0878, -74.0464) approx
print(geo_target_string('Pompano Beach', 'FL'))  # (75mi:26.2379:-80.1248) approx
"

# P2+P3b: build bindings for one dealer using copy engine
python -m shared.rebuild.marine_bindings_builder \
  --agency bluepixelmedia --slug gardenstate \
  --config shared/batch_configs/bpm_marine_2026.yaml
# Expect: template_bindings.yaml written with LLM RSA copy + real geo + brand URLs

# P1: dry run all 8 dealers
python -m shared.rebuild.batch_runner \
  --config shared/batch_configs/bpm_marine_2026.yaml \
  --dry-run
# Expect: table of 8 clients × 5 steps, no execution

# P1: full re-run one dealer
python -m shared.rebuild.batch_runner \
  --config shared/batch_configs/bpm_marine_2026.yaml \
  --clients gardenstate --force
# Expect: scan → fill (LLM copy) → render → validate (0 CTA errors) → Discord post

# P1: render+validate only (skip scan/fill, already done)
python -m shared.rebuild.batch_runner \
  --config shared/batch_configs/bpm_marine_2026.yaml \
  --steps render,validate
# Expect: 8 CSVs rendered, validation summaries
```
