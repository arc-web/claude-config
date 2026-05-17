# Copy Engine Industry Guides

## Context

The `HeadlineGenerator` and `DescriptionGenerator` both accept `ctx.industry` but barely use it. Headlines only branches on `HEALTHCARE_INDUSTRIES` to add disclaimer text. Descriptions ignore it entirely - the system prompt is a hardcoded global string. Mix type requirements (`MIX_REQUIREMENTS`) are hardcoded constants that never change regardless of industry.

Result: When `marine_dealer` context is passed, the LLM is told to generate `proof` and `question` headlines in 25-30 chars with zero guidance on what those mean for marine context. It fails after 2 retries and the pipeline falls back to static copy. Same problem will hit every non-healthcare industry we add.

Fix: Industry guides as first-class YAML config (same pattern as `cta_profiles.yaml`), loaded by a config module, injected into the LLM prompts at generation time. Each industry can override mix type hints, mix requirements, system prompt injections, and forbidden/banned word lists.

---

## Files to Create

### `shared/config/industry_guides.yaml`

```yaml
# Industry guide config for the copy engine.
# Controls how HeadlineGenerator and DescriptionGenerator behave per industry.
# 'extends' inherits all settings from named parent, 'override' keys replace parent values.

general:
  mix_requirements:
    keyword_lead: 3
    benefit_lead: 2
    question: 1
    proof: 1
    geo: 1
    cta: 1
  mix_type_hints:
    keyword_lead: "Leads with a primary search term (e.g. 'Plumber In Austin TX')"
    benefit_lead: "Leads with a clear benefit or feature (e.g. 'Same-Day Service Available')"
    question: "Asks a direct question (e.g. 'Need Emergency Repairs?')"
    proof: "Cites credibility or social proof (e.g. '5-Star Rated Service')"
    geo: "Includes a location signal (e.g. 'Serving Austin & Round Rock')"
    cta: "Ends with an action verb (e.g. 'Get A Free Quote Today')"
  headline_system_injection: ""
  description_system_injection: ""
  description_tone: "professional and direct"
  extra_forbidden_words: []
  extra_banned_words: []

marine_dealer:
  extends: general
  mix_type_hints:
    keyword_lead: "Leads with a boat-buying search term (e.g. 'Boat Dealer In Miami', 'Boats For Sale Near Me')"
    benefit_lead: "Leads with a marine dealer benefit (e.g. 'Marine Financing Available', 'Full-Service Marine Center')"
    question: "Asks a boat-buying question under 30 chars (e.g. 'Need A New Boat?', 'Ready To Buy A Boat?', 'Searching For Boats?')"
    proof: "Cites dealer authority under 30 chars (e.g. 'Authorized Boat Dealer', 'Top-Rated Dealer', 'Award-Winning Service')"
    geo: "Location signal under 30 chars (e.g. 'Boats In Point Pleasant', 'NJ & FL Boat Dealer')"
    cta: "Action verb under 30 chars (e.g. 'Shop Boats Today', 'Browse Our Fleet', 'View Inventory Now')"
  headline_system_injection: |
    This is a marine boat dealership, not a healthcare provider. Apply these rules:
    - proof type = dealer authority (authorized dealer, top-rated, award-winning) — NOT medical claims
    - question type = boat-buying intent (Need A New Boat?, Ready To Buy?, Searching For Boats?)
    - benefit_lead = tangible dealer benefit (financing, full-service center, multiple brands)
    - Every headline must be 25-30 characters. Boat brand names count as keyword leads.
  description_system_injection: |
    Write for a marine boat dealership. Tone: aspirational, lifestyle-focused, confident.
    Valid CTA verbs: shop, visit, browse, explore, schedule, call, compare, find, see.
    Do NOT use: book a consultation, book an appointment, or any healthcare-adjacent language.
    At least 2 descriptions must naturally include a boat-buying keyword (boat, boats, boat dealer, marine).
  description_tone: "aspirational and lifestyle-focused"

health_therapy:
  extends: general
  mix_type_hints:
    proof: "Cites clinical credentials or outcomes (e.g. 'Licensed Therapists On Staff')"
    question: "Asks about mental health needs (e.g. 'Struggling With Anxiety?')"
    cta: "Low-pressure action (e.g. 'Schedule A Free Consult')"
  headline_system_injection: |
    This is a mental health or therapy practice. Apply healthcare advertising rules:
    - Never imply guaranteed outcomes or cures
    - proof type = credentials and experience, not outcome promises
    - question type = empathetic, stigma-free framing
  description_system_injection: |
    Write for a mental health practice. Tone: warm, empathetic, non-clinical.
    Avoid: cure, treat, diagnose, guaranteed, promise. Use: support, explore, work through.
  description_tone: "warm and empathetic"

legal:
  extends: general
  mix_type_hints:
    proof: "Cites legal credentials (e.g. 'Board-Certified Attorneys', '20+ Years Experience')"
    question: "Addresses legal situation (e.g. 'Injured In An Accident?', 'Facing Criminal Charges?')"
    cta: "Professional call to action (e.g. 'Get A Free Case Review', 'Speak With An Attorney')"
  headline_system_injection: |
    This is a law firm. Do not guarantee outcomes. proof = credentials and track record.
    question = addresses the client's legal situation directly and empathetically.
  description_system_injection: |
    Write for a law firm. Tone: authoritative, reassuring, outcome-focused without guarantees.
    Do not promise wins. Use: experienced, proven, dedicated, trusted.
  description_tone: "authoritative and reassuring"

home_services:
  extends: general
  mix_type_hints:
    proof: "Cites service credentials (e.g. 'Licensed & Insured', '500+ Five-Star Reviews')"
    question: "Addresses service urgency (e.g. 'AC Broken In Summer?', 'Roof Leaking?')"
    cta: "Urgency-driven action (e.g. 'Get A Free Estimate', 'Book Same-Day Service')"
  headline_system_injection: |
    This is a home services business (HVAC, plumbing, roofing, etc.).
    proof = licensing, insurance, review count. question = urgency or problem framing.
  description_system_injection: |
    Write for a home services company. Tone: reliable, fast, local, trustworthy.
    Emphasize speed, licensing, and local expertise.
  description_tone: "reliable and action-oriented"

automotive:
  extends: general
  mix_type_hints:
    proof: "Cites dealership credentials (e.g. 'Certified Pre-Owned Dealer', '#1 Rated Dealer')"
    question: "Addresses car-buying intent (e.g. 'Ready To Buy A New Car?', 'Need A Trade-In Quote?')"
    cta: "Action verb for auto (e.g. 'Schedule A Test Drive', 'View Our Inventory')"
  headline_system_injection: |
    This is an automotive dealership. proof = dealer certifications and ratings.
    question = car-buying intent framing. cta = dealership-specific actions.
  description_system_injection: |
    Write for a car dealership. Tone: confident, value-focused, inventory-aware.
    Valid CTAs: test drive, browse, compare, visit, call, see, explore, schedule.
  description_tone: "confident and value-focused"
```

---

### `shared/copy_engine/industry_config.py`

Same pattern as `cta_config.py`:

```python
from __future__ import annotations
from functools import lru_cache
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "shared" / "config" / "industry_guides.yaml"

@dataclass
class IndustryGuide:
    mix_requirements: dict[str, int]
    mix_type_hints: dict[str, str]
    headline_system_injection: str
    description_system_injection: str
    description_tone: str
    extra_forbidden_words: list[str]
    extra_banned_words: list[str]

@lru_cache(maxsize=None)
def _load_raw() -> dict: ...

def load_guide(industry: str = "general") -> IndustryGuide:
    """Resolve extends chain and return merged IndustryGuide."""
    ...

def available_industries() -> list[str]: ...
```

Resolves `extends` chain identically to `cta_config._resolve()`. Falls back to `general` silently if industry not found (logs warning).

---

## Files to Modify

### `shared/copy_engine/search/headlines.py`

**Change 1 - Load guide in `__init__`:**
```python
from copy_engine.industry_config import load_guide

class HeadlineGenerator:
    def __init__(self, client):
        self._client = client
        # guide loaded per generate() call based on ctx.industry
```

**Change 2 - `_build_system_prompt(ctx)` - inject mix type hints and system injection:**

Currently the mix requirements table lists generic descriptions. Replace the generic descriptions with industry-specific hints from the guide:

```python
guide = load_guide(ctx.industry)
mix_reqs = guide.mix_requirements  # override hardcoded MIX_REQUIREMENTS

# Build mix table using guide.mix_type_hints instead of hardcoded strings
mix_table = "\n".join(
    f"  - {mix_type} (need {n}): {guide.mix_type_hints.get(mix_type, '')}"
    for mix_type, n in mix_reqs.items()
)

# Append industry injection at end of system prompt
if guide.headline_system_injection:
    prompt += f"\n\nINDUSTRY CONTEXT:\n{guide.headline_system_injection}"
```

**Change 3 - `generate()` - use guide's mix_requirements instead of global constant:**
```python
guide = load_guide(ctx.industry)
mix_reqs = guide.mix_requirements  # not the module-level MIX_REQUIREMENTS

# Pass mix_reqs through to _find_mix_gaps() and retry logic
```

**Change 4 - `_filter()` - add industry extra_forbidden_words:**
```python
guide = load_guide(ctx.industry)
all_forbidden = FORBIDDEN_WORDS | set(guide.extra_forbidden_words)
```

Keep `MIX_REQUIREMENTS` module constant as the default/fallback. Do not delete it.

---

### `shared/copy_engine/search/descriptions.py`

**Change 1 - Replace hardcoded `SYSTEM_PROMPT` global with `_build_system_prompt(ctx)`:**

```python
def _build_system_prompt(ctx: AdGroupContext) -> str:
    from copy_engine.industry_config import load_guide
    guide = load_guide(ctx.industry)
    base = """...(existing hardcoded prompt text)..."""
    if guide.description_system_injection:
        base += f"\n\nINDUSTRY CONTEXT:\n{guide.description_system_injection}"
    return base
```

**Change 2 - In `generate()`, call `_build_system_prompt(ctx)` instead of using the `SYSTEM_PROMPT` constant.**

**Change 3 - In `validate()`, merge `BANNED_WORDS` with `guide.extra_banned_words`:**
```python
guide = load_guide(ctx.industry)
effective_banned = BANNED_WORDS | set(guide.extra_banned_words)
```

Keep `SYSTEM_PROMPT` as module-level constant for backward compatibility (still used as the base text).

---

## Files to Modify (Tests)

### `tests/test_copy_engine_search_contract.py`

Add new test class `TestIndustryGuides`:

```python
class TestIndustryGuides:
    def test_load_guide_marine_returns_correct_mix(self):
        guide = load_guide("marine_dealer")
        assert guide.mix_requirements["keyword_lead"] == 3
        assert "Need A New Boat?" in guide.mix_type_hints["question"]

    def test_load_guide_unknown_falls_back_to_general(self):
        guide = load_guide("nonexistent_industry_xyz")
        assert guide.mix_requirements == load_guide("general").mix_requirements

    def test_load_guide_extends_chain(self):
        marine = load_guide("marine_dealer")
        general = load_guide("general")
        # marine inherits mix_requirements from general (same values)
        assert marine.mix_requirements == general.mix_requirements

    def test_available_industries(self):
        industries = available_industries()
        assert "general" in industries
        assert "marine_dealer" in industries

    def test_headline_system_prompt_includes_marine_injection(self):
        # HeadlineGenerator._build_system_prompt should include marine injection
        from copy_engine.search.headlines import HeadlineGenerator
        from copy_engine.models import OpenRouterClient
        # Mock client - we just test the prompt, not the LLM call
        ctx = AdGroupContext(
            name="Boat General", service="boat sales", geo=["Point Pleasant, NJ"],
            USPs=["authorized dealer"], top_keywords=["boat dealer"],
            landing_url="https://example.com/", industry="marine_dealer",
        )
        gen = HeadlineGenerator(None)
        prompt = gen._build_system_prompt(ctx)
        assert "marine boat dealership" in prompt.lower()
        assert "Need A New Boat?" in prompt or "boat" in prompt.lower()

    def test_description_system_prompt_includes_marine_injection(self):
        from copy_engine.search.descriptions import _build_system_prompt
        ctx = AdGroupContext(
            name="Boat General", service="boat sales", geo=["Miami, FL"],
            USPs=["authorized dealer"], top_keywords=["boats for sale"],
            landing_url="https://example.com/", industry="marine_dealer",
        )
        prompt = _build_system_prompt(ctx)
        assert "marine boat dealership" in prompt.lower()
        assert "book a consultation" not in prompt.lower()  # healthcare phrase gone
```

### Add integration test: `tests/test_industry_guide_integration.py`

```python
"""Live integration test - calls real LLM. Run manually, not in CI."""
# pytest -m integration tests/test_industry_guide_integration.py

import pytest

@pytest.mark.integration
def test_marine_headline_generator_completes_without_fallback():
    """HeadlineGenerator with marine_dealer context must not raise RuntimeError."""
    from copy_engine.search.headlines import HeadlineGenerator
    from copy_engine.models import OpenRouterClient
    from copy_engine.context import AdGroupContext

    ctx = AdGroupContext(
        name="Boat General/Regional Terms",
        service="new and used boat sales",
        geo=["Point Pleasant, NJ", "Cape Coral, FL"],
        USPs=["authorized dealer", "multiple brands", "marine financing"],
        top_keywords=["boat dealer", "boats for sale", "new boats"],
        landing_url="https://www.gardenstateyachtsales.com/",
        industry="marine_dealer",
        additional_context="Brands: Cobia, Everglades, Pathfinder, Pursuit, Sea Pro. Serving NJ & FL.",
    )
    gen = HeadlineGenerator(OpenRouterClient())
    headlines = gen.generate(ctx, count=15)

    assert len(headlines) == 15
    texts = [h.text for h in headlines]
    mix_types = [h.mix_type for h in headlines]
    assert mix_types.count("question") >= 1
    assert mix_types.count("proof") >= 1
    assert all(len(h.text) <= 30 for h in headlines)

@pytest.mark.integration
def test_marine_description_generator_completes():
    from copy_engine.search.descriptions import DescriptionGenerator
    from copy_engine.models import OpenRouterClient
    from copy_engine.context import AdGroupContext

    ctx = AdGroupContext(
        name="Boat General/Regional Terms",
        service="new and used boat sales",
        geo=["Point Pleasant, NJ"],
        USPs=["authorized dealer"],
        top_keywords=["boat dealer", "boats for sale"],
        landing_url="https://www.gardenstateyachtsales.com/",
        industry="marine_dealer",
    )
    gen = DescriptionGenerator(OpenRouterClient())
    descs = gen.generate(ctx, count=4)

    assert len(descs) == 4
    assert all(len(d.text) <= 90 for d in descs)
    assert descs[0].role == "pas"
```

---

## Execution Order

1. Create `shared/config/industry_guides.yaml`
2. Create `shared/copy_engine/industry_config.py`
3. Modify `shared/copy_engine/search/headlines.py` (4 targeted changes)
4. Modify `shared/copy_engine/search/descriptions.py` (3 targeted changes)
5. Run unit tests: `python3 -m pytest tests/test_copy_engine_search_contract.py -v`
6. Fix any failures
7. Run integration test: `python3 -m pytest -m integration tests/test_industry_guide_integration.py -v -s`
8. If HeadlineGenerator still fails: iterate on `marine_dealer.headline_system_injection` wording until it passes
9. Run full batch: `python3 -m shared.rebuild.batch_runner --config shared/batch_configs/bpm_marine_2026.yaml --dealers gardenstate --steps fill,render,validate`
10. Confirm no "Copy engine failed, using static fallback" in output
11. Plane: create ADS-50 "Industry guide system" and mark Done
12. GitHub: open + close issue in arc-web/google-ads-agent

---

## Critical Files

| File | Action |
|------|--------|
| `shared/config/industry_guides.yaml` | Create |
| `shared/copy_engine/industry_config.py` | Create |
| `shared/copy_engine/search/headlines.py` | Modify (4 changes) |
| `shared/copy_engine/search/descriptions.py` | Modify (3 changes) |
| `shared/config/cta_profiles.yaml` | Read-only (pattern reference) |
| `shared/rebuild/cta_config.py` | Read-only (pattern reference) |
| `tests/test_copy_engine_search_contract.py` | Modify (add TestIndustryGuides class) |
| `tests/test_industry_guide_integration.py` | Create |

---

## What "Until It Works" Means

Pass condition: `gardenstate` fill step completes with copy grade logged (not "WARN Copy engine failed") and HeadlineGenerator produces all 6 mix types in 15 headlines. If prompt engineering alone doesn't fix it after 2 attempts, widen the retry from 2 to 3 retries and reduce `question` from 1 to 0 required (marine doesn't need questions the way healthcare does). That's a last resort - try prompt first.
