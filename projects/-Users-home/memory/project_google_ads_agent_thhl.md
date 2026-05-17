---
name: THHL Google Ads rebuild - current state
description: ThinkHappyLiveHealthy.com (therappc client) - search campaign rebuild status, copy engine state, and what was deprecated
type: project
originSessionId: 50a200fd-5756-471f-a5c1-a4262e9c6352
---
## Status: Violations fixed 2026-04-29, campaign renamed, staging advanced (verified 2026-05-01)

**Copy engine: fully built.** All Stage 1-4 modules exist at `~/ai/agents/ppc/google_ads_agent/shared/copy_engine/` (verified 2026-05-01):
- `shared/copy_engine/models.py` - OpenRouterClient (kimi-k2 default, gemini-flash for JSON)
- `shared/copy_engine/editor/grader.py` - 7-sweep role-aware copy grader (gemini-2.5-flash only)
- `shared/copy_engine/editor/evaluator.py` - char limits, policy, plain English, mix compliance
- `shared/copy_engine/editor/reporter.py` - HTML HITL report generator
- `shared/copy_engine/orchestrator.py` - full pipeline runner (run_sweep / run_generate modes)
- `shared/copy_engine/search/headlines.py`, `descriptions.py`, `extensions.py` - generators

**THHL Campaign 1 staged:**
- Campaign: `ARC - Search - Services - V1` (renamed from `THHL - Search - Services - RevKey`; verified in `THHL_Search_Services_Editor_Staging_CURRENT.csv` 2026-05-01)
- CSV: `~/ai/agents/ppc/google_ads_agent/clients/therappc/thinkhappylivehealthy/campaigns/THHL_Search_Campaign_2026-04-28.csv` (verified 2026-05-01)
- Current staging: `~/ai/agents/ppc/google_ads_agent/clients/therappc/thinkhappylivehealthy/build/search_rebuild_test/THHL_Search_Services_Editor_Staging_CURRENT.csv` (verified 2026-05-01)
- 9 ad groups: Psychiatry, Adult Therapy, Child Psych Testing, Psychoeducational Evals, Gifted Testing, ADHD Testing, K-Readiness Testing, Autism Testing, Parent Child Services
- 130 phrase-only keywords, 9 RSAs, geo targeting with bid modifiers

**HITL review documents** (not on Desktop - in project build dir per directory law):
- `~/ai/agents/ppc/google_ads_agent/clients/therappc/thinkhappylivehealthy/build/2026-04-28_account_rebuild/`
- Surviving files: `campaign_review_2026-04-28_fixed.html`, `campaign_revisions_2026-04-29.html`, `Client_Rebuild_Review.html` (verified 2026-05-01)

**Taxonomy: 96 ad groups planned across 5 campaigns.** Naming: Service - Audience - IntentLayer (General/Local/City/State).

**Character violations: FIXED 2026-04-29** (verified live in `campaign_revisions_2026-04-29.html` - all headlines/descriptions show `char-ok`, no `char-bad`; violating strings replaced):
- ~~Psychiatry H9: "Skilled Psych Nurse Practitioners" = 33 chars~~ - fixed
- ~~Child Psych Testing H4: "Comprehensive Child Assessments" = 31 chars~~ - fixed
- ~~Gifted Testing H6: "Northern Virginia Gifted Testing" = 32 chars~~ - fixed
- ~~K-Ready H4: "Kindergarten Assessment Near You" = 32 chars~~ - fixed
- ~~Psychoeducational D1: 92 chars~~ - fixed
- ~~Autism Testing D1: 92 chars~~ - fixed

**Grader validated on K-Readiness Testing:** B/84, weakest sweep zero_risk (descriptions lack CTA).

## What Was Deprecated

- Seven Sweeps framework applied raw to 30-char headlines - wrong tool. Replaced with role-based Google Ads native rubric.
- Batch grading with kimi-k2 - kimi-k2 corrupts JSON mid-structure. All grading now uses gemini-2.5-flash per-asset.
- Phrase+Exact match strategy from initial THHL build - deprecated to phrase-only.

**Why:** Grader role-aware system: identifies headline role first (geo/credential/keyword_match etc), scores neutral (70) on inapplicable dimensions, excludes neutral dims from weighted average.

## What's Next

1. ~~Fix 6 character violations~~ - DONE (2026-04-29)
2. Run full grader sweep across all 9 ad groups - status unknown as of 2026-05-01 audit
3. Human review + approval of HITL document - status unknown as of 2026-05-01 audit
4. Import to Google Ads Editor staging - status unknown as of 2026-05-01 audit
5. Campaign 2 (Child Testing split) after 30-60 days data
