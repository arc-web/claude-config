# Context

Industry guides system just shipped and passed all tests (17 unit + 2 integration). The gardenstate batch has NOT been re-run since industry guides went live — real-world validation still pending. Plane/GitHub tracking for the industry guides work is also missing. This plan covers the next execution block.

---

# Step 1: Gardenstate end-to-end validation

Confirm the full pipeline works with industry guides active. No "Copy engine failed, using static fallback" in output.

**Command:**
```bash
cd /Users/home/ai/agents/ppc/google_ads_agent
PYTHONPATH=.:shared python3 -m shared.rebuild.batch_runner \
  --config shared/batch_configs/bpm_marine_2026.yaml \
  --dealers gardenstate \
  --steps fill,render,validate
```

**Pass criteria:**
- No `Copy engine failed` warning in stdout
- Output CSV exists under `clients/bluepixelmedia/gardenstate/`
- Validate step exits clean (0 errors)
- Headlines in CSV are real LLM copy (not static fallback "Book A Free Consultation Today" style)

**If it fails:** Check stderr for which step fails. If `fill` step fails, likely a PYTHONPATH or import issue in `marine_bindings_builder.py`. If `render` fails, template binding mismatch. If `validate` fails, copy violations.

---

# Step 2: Expand to 2-3 more BPM marine dealers

Once gardenstate passes, run the same pipeline for a few others to confirm the guide generalizes. Candidates from `clients/bluepixelmedia/`:

- `norfolkmarine`
- `southshoremarine`
- `smgboats`

**Command:**
```bash
PYTHONPATH=.:shared python3 -m shared.rebuild.batch_runner \
  --config shared/batch_configs/bpm_marine_2026.yaml \
  --dealers norfolkmarine southshoremarine smgboats \
  --steps fill,render,validate
```

Same pass criteria. Any dealer that fails: isolate with `--dealers <dealer>` and debug individually.

---

# Step 3: Plane + GitHub bookkeeping

**Plane task (AGENT project, todovibes workspace):**
- Create ADS-50: "Industry Guides System - marine_dealer + general framework"
- Description: industry guides YAML + IndustryGuide dataclass + HeadlineGenerator/DescriptionGenerator wired to guides + root_repeat_limit field + quantity fill loop + 17 unit + 2 integration tests passing
- State: Done
- Include handoff prompt and attribution

**GitHub:**
- Open issue on arc-web/google-ads-agent (or equivalent repo) titled "Industry guides system shipped - marine_dealer baseline"
- Mark as closed with commit reference `AGENT-245d`

---

# Files touched in this plan

- No code changes expected (read-only validation + Plane/GH admin)
- If batch fails: likely `shared/rebuild/marine_bindings_builder.py` or `shared/batch_configs/bpm_marine_2026.yaml`

---

# Verification

1. Gardenstate CSV exists and opens cleanly
2. No fallback copy in headlines column (check for "Book A Free Consultation" or "Same-Day Service")
3. ADS-50 in Plane marked Done
4. GH issue closed with commit reference
