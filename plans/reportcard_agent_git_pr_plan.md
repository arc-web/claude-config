# reportcard_agent - Git/PR Feature-by-Feature Plan

## Context

`reportcard_agent` lives at `~/ai/agents/development/reportcard_agent` with GitHub remote `arc-web/advertising-report-card`.

**Problem:** Local `origin` URL points to `reportcard-agent` (non-existent repo). Actual GitHub repo is `advertising-report-card`. Nothing has been pushed yet. Local `main` is 2 commits ahead of a broken remote.

**Goal:** Fix remote, push existing commits, then create one PR per feature group for all uncommitted work.

---

## Step 0 — Fix Remote URL

```bash
git -C ~/ai/agents/development/reportcard_agent remote set-url origin https://github.com/arc-web/advertising-report-card.git
```

Check what's on GitHub main before pushing (may be empty, may have initial import).

---

## Step 1 — Push Existing SEO Integration Commits to main

Two commits already on local `main` get pushed directly (they were already reviewed/tested):

- `ec53092` feat: integrate forensic SEO probes and GSC into reportcard pipeline
- `eed3f85` fix: resolve probe import collision and wire findings into rendered report

Files: `tools/seo_probes.py`, `tools/gsc_connector.py`, `tools/seo_tool.py`, `tools/seo_analyzer.py`, `stages/analyze.py`, `config/schema.py`

```bash
git push origin main
```

If GitHub main has diverged: rebase local onto remote first, then push.

---

## Step 2 — Feature PRs (6 branches)

Each branch cuts from current `main`, commits its files, pushes, opens PR.

### PR 1: `feat/screenshot-popup-dismissal`
**What:** Playwright popup/modal dismissal before screenshots; timeout 20s → 45s; page load "networkidle" → "load"
**Why:** Real sites show cookie banners / modals that obscure the page in screenshots
**Files:** `stages/screenshot.py`

### PR 2: `feat/docx-formatting-improvements`
**What:** Issue:/Recommendation: line parsing with distinct styling; image width 6.0" → 4.9"; caption italics → normal; `add_image_text_table` delegates to `add_image`
**Why:** Formatting fixes for professional report output quality
**Files:** `stages/formatting.py`

### PR 3: `feat/web-design-audit-prompts`
**What:** 25-element `ELEMENT_AUDIT` dict (hero, CTA, nav, forms, trust signals, etc.); structured issue/recommendation findings replace generic captions
**Why:** Web design section now produces actionable audit findings per annotated element instead of generic text
**Files:** `tools/web_design_analyzer.py`

### PR 4: `feat/annotate-stage`
**What:** New pipeline stage that copies screenshots to annotated output directory (scaffolded; visual overlay pending)
**Why:** Establishes stage slot in pipeline for future annotation rendering
**Files:** `stages/annotate.py`

### PR 5: `feat/revision-report`
**What:** New pipeline stage generating client-facing DOCX for Google Ads pre-launch revisions from YAML config; validation script; tests
**Why:** Separate report type for revision review workflow distinct from main report card
**Files:** `stages/revision_report.py`, `tests/test_revision_report.py`, `verify_revision_report.py`

### PR 6: `chore/thhl-client-config`
**What:** Think Happy Live Healthy client YAML (15 pages, GSC slug, probe config, sections) and revisions YAML
**Why:** First real client config for the pipeline; enables full end-to-end test runs
**Files:** `clients/thinkhappylivehealthy.com.yaml`, `clients/thinkhappylivehealthy.com.revisions.yaml`

---

## What Gets Skipped

- `CODEX_AUDIT.md` — internal audit note, not repo content; skip
- `output/` — generated artifacts, never committed
- `__pycache__/` dirs — never committed

---

## Execution Order

1. Fix remote URL
2. Push existing main (SEO commits)
3. PRs 1-3 in parallel (independent, no deps)
4. PRs 4-6 in parallel (independent, no deps)
5. Merge all PRs

---

## Verification

After all PRs merged:
```bash
git -C ~/ai/agents/development/reportcard_agent log --oneline -10
gh pr list --repo arc-web/advertising-report-card --state merged
python3 ~/ai/agents/development/reportcard_agent/pipeline.py \
  --client thinkhappylivehealthy.com \
  --skip-validation --skip-research
```

Grader output should show `seo: findings=5, subs=3` as before.
