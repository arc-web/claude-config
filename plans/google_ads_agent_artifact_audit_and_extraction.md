# Plan: google_ads_agent full audit → reusable artifact builder → render this plan + future docs

## Context

User has many parallel threads and wants to confirm alignment before I touch anything. Stated intent (confirmed via AskUserQuestion):

1. **Audit first** - full critical pass over every subsystem in `~/ai/agents/ppc/google_ads_agent/`. Not just `shared/presentation/` - include `shared/agent_routing/`, `shared/copy_engine/`, `shared/rebuild/`, `shared/new_campaign/`, `shared/tools/`, `shared/validators/`, `shared/gads/`, `shared/utils/`, `shared/scripts/`, `shared/creative_assets/`, `clients/`, `supabase/`, `presentations/`, `tasks/`, `docs/`, `legacy_archive/`.
2. **Then extract** the reusable artifact-builder pattern from those fragments. Today it's locked inside Google-Ads-client-specific pipelines (build_new_campaign_report, build_creative_asset_package, build_review_doc, build_fixed_campaign_review, build_search_term_report, prepare_client_review_html, etc.) plus shared CSS (`page_break_rules.css`, `section_header.css`) and lookups (`artifact_lookup.py`, `rendered_artifact_lineage.py`).
3. **Then use** the extracted builder to render `~/.claude/plans/plane_docs_sync.md` (and future docs) into the same styled HTML the client-facing deliverables get.

Earlier failure: my first search globbed only `~/ai/tools/` + `~/ai/agents/development/` and missed `~/ai/agents/ppc/`. That's why this plan exists.

## What I already know from a quick read

- `docs/system_review/AUTOMATION_ARTIFACT_TAXONOMY.md` (2026-05-09) defines 9 artifact categories (Source inputs, Normalized evidence, Strategy artifacts, Staging artifacts, Client-facing deliverables, Validation evidence, Revision artifacts, Handoff evidence, Generated-noise) + a mermaid chain diagram. This is the map.
- `docs/system_review/RENDERED_ARTIFACT_LINEAGE_AUDIT_2026-05-09.md` + `RENDERED_ARTIFACT_LINEAGE_LEDGER_2026-05-09.csv` already classify 24 rendered files (11 keep, 6 needs-lineage-check, 1 source-of-truth, 6 superseded).
- `docs/system_review/CLIENT_ARTIFACT_TRIAGE_DELTA_2026-05-16.md` exists - delta against the 05-09 ledger; today's drift signal.
- `shared/presentation/` has ~17 `build_*` / `prepare_*` / `audit_*` modules + 2 CSS files; `presentations/tools/` has CLI wrappers around the same modules. Duplication is likely.
- `shared/presentation/artifact_lookup.py` is the registry; `shared/agent_routing/rendered_artifact_lineage.py` is the lineage tracer.

## Plan

### Phase A - Read the existing audit material first

Don't reinvent. Files to read in order before exploring code:

1. `docs/system_review/AUTOMATION_ARTIFACT_TAXONOMY.md` (full)
2. `docs/system_review/RENDERED_ARTIFACT_LINEAGE_AUDIT_2026-05-09.md` (full)
3. `docs/system_review/CLIENT_ARTIFACT_TRIAGE_DELTA_2026-05-16.md` (full)
4. `docs/system_review/CLIENT_ARTIFACT_TRIAGE_HANDOFF_2026-05-13.md`
5. `shared/presentation/LESSONS_TO_TOOLS.md`
6. `presentations/README.md`
7. Most recent file under `docs/system_review/agent_handoffs/` (state of play)
8. `AGENTS.md` / `README.md` at repo root if present

This phase gives me the existing mental model. Do not skip and re-derive.

### Phase B - Full repo audit (3 parallel Explore agents)

Spawn three Explore agents in parallel, each with a tight focus:

- **Agent 1 - Presentation/render layer.** Map every file under `shared/presentation/`, `presentations/`, and the CSS. For each: inputs, outputs, downstream callers, output filetype, whether it's a shared primitive or a client-specific consumer. Note duplication between `shared/presentation/build_X.py` and `presentations/tools/build_X.py`.
- **Agent 2 - Artifact registry + lineage.** Map `shared/presentation/artifact_lookup.py`, `shared/agent_routing/rendered_artifact_lineage.py`, `presentations/tools/audit_rendered_artifact_lineage.py`, `presentations/tools/check_client_deliverable_lineage.py`, related tests under `tests/test_rendered_artifact_lineage.py` + `tests/test_artifact_lookup.py`. Document: what gets registered, how lineage edges are tracked, what storage backs it (Supabase? file?), the disposition vocabulary.
- **Agent 3 - Surrounding subsystems.** Sweep `shared/agent_routing`, `shared/copy_engine`, `shared/rebuild`, `shared/new_campaign`, `shared/tools`, `shared/validators`, `shared/gads`, `shared/utils`, `shared/scripts`, `shared/creative_assets`, `shared/batch_configs`, `shared/config`, `shared/health`, `shared/clients`, `clients/`, `supabase/`, `tasks/`, `templates/`, `legacy_archive/`, `worktrees/`. For each subdir: 1-paragraph description, anything that emits or consumes rendered artifacts, anything obviously dead/legacy.

Each agent returns a structured report under ~600 words: bullet inventory + flagged duplications + flagged dead code + flagged extraction candidates.

### Phase C - Synthesize audit (no code)

Consolidate the three reports into `~/Desktop/google_ads_agent_audit_2026-05-16.md`:

- Subsystem map (one paragraph each).
- **Findings table:** duplication, dead code, broken handoffs, missing lineage, superseded artifacts not yet purged.
- **Extraction candidates:** which build_*/prepare_* modules + which CSS + which lookups together form the minimum reusable "build a styled HTML doc from markdown + metadata" primitive.
- **Recommended consolidation:** how to collapse duplicates between `shared/presentation/` and `presentations/tools/`; whether to keep the artifact_lookup + lineage layer as-is or simplify; which legacy_archive items are safe to delete.

Render this audit doc itself with codebase_helper (`feedback_open_in_html_tool`) for browser review.

### Phase D - Extract reusable builder

Decide between two implementations based on Phase C:

- **D1.** New standalone module `tools/render_artifact.py` (or extend `codebase_helper` agent) that depends on extracted primitives from `shared/presentation/`. Cleanest separation, but adds a new entry point.
- **D2.** Genericize `shared/presentation/prepare_client_review_html.py` to accept any markdown + title + footer + class, drop the Google-Ads-specific assumptions, then call from anywhere.

Whichever wins: must accept `(markdown_path, output_path, title=None, footer=None, theme=None)`, use the existing CSS, register in the artifact_lookup if the registry stays.

### Phase E - Render `plane_docs_sync.md` with the new builder

End-to-end test:

```
build_artifact ~/.claude/plans/plane_docs_sync.md --output ~/Desktop/plane_docs_sync.html --title "Plane Docs Sync Plan"
open ~/Desktop/plane_docs_sync.html
```

Visually confirm it matches the look of an existing client-facing HTML (e.g. one of the 11 `keep` artifacts from the lineage audit).

### Phase F - Wire into default

Update `feedback_open_in_html_tool.md` memory so "open in html" prefers the new builder when the source is a plan/doc, falls back to codebase_helper for pure preview-site needs. (Or merge codebase_helper into the new builder, depending on Phase C outcome.)

## Critical files (read or modify)

Read-only during audit:
- `~/ai/agents/ppc/google_ads_agent/docs/system_review/AUTOMATION_ARTIFACT_TAXONOMY.md`
- `~/ai/agents/ppc/google_ads_agent/docs/system_review/RENDERED_ARTIFACT_LINEAGE_AUDIT_2026-05-09.md`
- `~/ai/agents/ppc/google_ads_agent/docs/system_review/CLIENT_ARTIFACT_TRIAGE_DELTA_2026-05-16.md`
- `~/ai/agents/ppc/google_ads_agent/docs/system_review/CLIENT_ARTIFACT_TRIAGE_HANDOFF_2026-05-13.md`
- `~/ai/agents/ppc/google_ads_agent/shared/presentation/LESSONS_TO_TOOLS.md`
- All files in `shared/presentation/`, `presentations/tools/`, `shared/agent_routing/`
- One handoff file from `docs/system_review/agent_handoffs/` (most recent)

Will modify in Phase D-F:
- New: `tools/render_artifact.py` (or whichever path Phase C picks)
- Possibly: `shared/presentation/prepare_client_review_html.py`
- Memory: `~/.claude/projects/-Users-home/memory/feedback_open_in_html_tool.md`

Out of scope:
- Touching client data under `clients/therappc`, `clients/arc`, `clients/bluepixelmedia`.
- Touching `.venv`, `__pycache__`, `.pytest_cache`.
- Touching Supabase schema.

## Plane tracking

Per `feedback_plane_task_always` rule: create AGENT-XXX task at Phase B start, update through Done at Phase F.

## Verification

- All three Explore reports archived under `~/Desktop/google_ads_agent_audit_2026-05-16/agent_{1,2,3}.md`.
- Synthesis doc exists at `~/Desktop/google_ads_agent_audit_2026-05-16.md` and renders cleanly.
- New builder runs on `~/.claude/plans/plane_docs_sync.md` and output HTML opens with custom styling matching existing client deliverables (visual diff against one of the 11 `keep` artifacts).
- `pytest` on `tests/test_artifact_lookup.py` and `tests/test_rendered_artifact_lineage.py` still passes if I touched anything in that path.
- Memory `feedback_open_in_html_tool.md` reflects new tool of record.

## Stop conditions

- Phase A finds a doc that already does exactly this and I missed it → stop, point you at it.
- Phase B finds the codebase is in mid-refactor (handoff doc dated within 24h) → stop, summarize state, ask whether to proceed or hand back to whoever is mid-edit.
- Phase C finds extraction would require >2 file rewrites in `shared/presentation/` → stop, present the trade-off (D1 vs D2 vs leave-alone), ask which.

## Confirmation request

This plan reflects: full repo audit → synthesize → extract → render this plan doc with the extracted tool → make it the default for "open in html". You answered "all of the above, in that order" + "full google_ads_agent repo, all subsystems." If anything above is wrong - especially the assumption that I should build a new tool rather than just identify the existing one - say so before approval.
