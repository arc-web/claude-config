# Path to Launch - `google_ads_agent` Production-Readiness Program

> **Plan file**: `google_ads_agent_production_readiness_program.md` (renamed from harness slug `witty-roaming-hoare.md` per memory rule `feedback_plan_naming.md`). Live relevancy-check pass dated 2026-05-16: see Section 1 footnotes for verified vs revised numbers.

> **Dual vocabulary**: this plan is read by two audiences. Owner + team use friendly words (Squad, Stage, Department, Tech Lead). Claude Code agents executing the work use technical words (sub-agent, phase, orchestrator, swarm). Both labels appear together throughout. See **Section 0 (Plain English Overview)** for the friendly view and **Section 12 (Translation Table)** for the mapping.

---

## 0. Plain English Overview

**Project name**: Path to Launch.

**What we're building**: back-of-house ad-tech work. Front-of-house = AI ad managers handling client campaigns. Back-of-house = the platform those AI ad managers run on. Path to Launch is the back-of-house team shipping v1.0 so the AI ad managers can do their job reliably.

**Org chart**:

```
OWNER (you)
  TECH LEAD (orchestrator; only one who pings you)

      TESTING DEPT - "is the code correct?"
        Cleanup Squad      cleans messy file pile
        Safety Net Squad   auto-checks every commit forever
        Test Squad         writes missing tests
        Workflow Squad     tests full client workflows top-to-bottom

      STAGING DEPT - "is THIS client package correct before they see it?"
        Format Squad       locks rules for what good package looks like
        Move Squad         moves 203 files to better folder
        Package QA Squad   checks every new client package forever

      PRODUCTION DEPT - "is the live system healthy?"
        Docs Squad         writes launch rulebook
        Launch Squad       runs trial + owns go-live rules
        Monitor Squad      watches live ads forever
        Recovery Squad     rolls back when stuff breaks, routes bug to Testing
```

**Eight stages** (1-7 = one-time setup; 8 = forever):

| Stage | Dept | What gets done | Why |
|---|---|---|---|
| **1 - File Cleanup** | Testing | Clean up 328 messy files | Can't trust anything in a dirty pile |
| **2 - Safety Nets** | Testing | Set up auto-checks (CI, pre-commit, lint) | Catch mistakes before they ship |
| **3 - Missing Tests** | Testing | Write missing tests (6 workflow tests + 25 entrypoint tests + barrier tests) | Prove the system works |
| **4 - Format Lock** | Staging | Lock file format for every staging package; kill broken old module | No more surprises from bad files |
| **5 - File Move** | Staging | Move 203 files into the right folder (3 waves, owner approves each wave) | Tidy up so client artifacts and machine state aren't mixed |
| **6 - Launch Rulebook** | Production | Write rulebook for going live + client signoff trail | Decide exactly when the live switch can flip |
| **7 - Trial Run** | Production | Full pretend-launch with every gate active. No live action. | Prove the system holds pressure |
| **8 - Live Ops** | All 3 depts (continuous) | After real go-live: Safety Nets on every commit, Package QA on every package, Monitor watching live ads, Recovery on standby | System never finishes - operates forever |

**Owner signoff gates**: one at the end of every stage (1-7). Plus one per wave in Stage 5 (3 extra). Total: 10 owner approvals across Stages 1-7. Stage 8 starts after - owner only pinged on incidents.

**Feedback loop when something breaks live** (Stage 8):

```
Live ad breaks
  v
Recovery Squad flips live-upload OFF (rollback)
  v
Bug ticket in Plane, routed to Testing dept
  v
Testing finds + fixes
  v
Goes through Staging again (Package QA re-validates)
  v
Goes through Production again (mini trial run)
  v
Owner re-greenlights
  v
Back live, Monitor Squad watching
```

**Plane prefix**: `[ARC-L1]` through `[ARC-L8]`. ARC = Advertising Report Card, L = Launch, # = stage. Department tag appended: `[ARC-L4] [Staging]`.

---

---

## 1. Context

The repo at `/Users/home/ai/agents/ppc/google_ads_agent` is a multi-tenant Google Ads automation system. It serves 31 clients across three agencies (`arc/`, `bluepixelmedia/`, `therappc/`). It generates Google Ads Editor staging CSVs and HTML/PDF client review packages across six workflow modes (`new_campaign`, `inherited_rebuild`, `revision`, `optimization`, `search_term_review`, `launch_readiness`).

The system **works**. It is also **operationally fragile**. Concrete evidence the swarm will treat as input state:

- **Working tree is dirty.** Branch `codex/client-folder-boundary-staging-ready` has **35 modified files plus 294 untracked entries (328 total porcelain entries)** across four in-flight workstreams (EMorrison budget revision, Full Tilt STR live API package, systemwide Client HQ completion across 31 clients, Full Tilt STR strategy packet). Bootstrap reports three blocking flags: `explicit-approval-required`, `split-commit-required`, `foundation_readiness: fail`. *Verified live 2026-05-16.*
- **167 of 200 Python modules under `shared/` and `presentations/` have no dedicated test.** 25 entrypoint wrappers in `presentations/tools/` have zero direct tests. 66 pytest files exist; most concentrate on `shared/rebuild/staging_validator.py`.
- **No CI, no pre-commit, no linter.** No `.github/workflows/`, no `Makefile`, no `.pre-commit-config.yaml`, no `.ruff.toml`. Only `pytest.ini` and `requirements-dev.txt`.
- **`foundation_readiness` is advisory.** The 10 gates in `shared/agent_routing/foundation_readiness.py:85-220` (AGENTS.md contract, git worktree clean, focused pytest, compile, git diff `--check`, docs hygiene, dep health, startup audit, router enforcement, deliverable lineage) report status but do not block.
- **Live API barrier is untested.** `shared/gads/core/google_ads_api_service.py:24-145` raises `LiveGoogleAdsAutomationDisabled` when `enable_live_mutations=False` (the default everywhere). No test asserts the barrier stays closed under refactor.
- **Deprecated module still importable.** `shared/google_ads_workflow.py` is a stub that exits non-zero on `__main__` but can still be `import`ed.
- **Boundary contract staged but unenforced.** Commit `b51816f` defines `clients/{agency}/{client}/` for client-visible artifacts and `docs/system_review/client_runs/{agency}/{client}/` for machine state. 203 candidate files are catalogued in `docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_LEDGER_2026-05-13.csv`. Migration deferred.
- **Markdown debt.** `docs/system_review/MARKDOWN_DISPOSITION_LEDGER.csv` has 360 data rows with descriptive disposition reasons (no status enum column). Stale/superseded subset to be quantified by `docs-curator` at Phase 0 entry. *Earlier "84 stale" figure unverified; revised down to "scope-TBD".*
- **No live-upload SOP, no client-signoff audit trail.** The six readiness labels (`guardrail-only` through `launch-ready` in `docs/INGESTION_OPERATING_SYSTEM.md:209-225`) are abstract prose.

**The constraint that ties the whole problem together**: "production" means a live Google Ads account change. It is currently OFF. This program makes everything ELSE around the live-upload switch production-ready - every gate, every test, every audit trail hardened - so that the eventual decision to flip `enable_live_mutations=True` is a single, deliberate, auditable owner action against a stable platform. **The program does not propose flipping the switch.**

Work is executed by a swarm of Claude Code sub-agents under one orchestrator. The owner approves each phase exit. Cadence inside each phase is the strict loop: **analyze → plan → build → test → repeat** until phase exit criteria pass automated verification, then pause for owner approval.

---

## 2. Out-of-Scope

The program does **not** do any of the following:

- Flip `enable_live_mutations` to true. The exception barrier in `shared/gads/core/google_ads_api_service.py` stays closed throughout.
- Refactor working systems. The staging validator, report builders, marine template extractor are harnessed where they are not tested, not rewritten.
- Introduce new client features. No new workflow modes, no new report sections, no PMAX, no new platforms.
- Migrate framework or runtime. Python stays Python. Pytest stays pytest. The `.venv` model stays.
- Change the staging model. Google Ads Editor CSV stays the human review surface.
- Purge, archive, delete, or rewrite any client data, source input, generated artifact, or branch without an owner-approved disposition in a ledger.
- Chase coverage percentages as a goal. Closes specific named gaps. Coverage is a side-effect, not a metric.
- Touch `legacy_archive/`, `worktrees/`, or `tasks/`.

---

## 3. Swarm Topology (Team Org)

### 3.1 Orchestrator (Tech Lead)

**Tech Lead** / `production-readiness-foreman` is the single orchestrator. Owns the phased program (8 stages), the swarm queue, the handoff ledger, the owner-engagement schedule. Runs no validators directly; delegates to squads (sub-agents) and reads back their handoff notes. **Only agent that asks the owner anything.**

Tech Lead responsibilities:

1. Pick the next phase from `docs/PRODUCTION_READINESS_PROGRAM.md` (the in-repo copy of this plan).
2. Read entry criteria. If unmet, stop and ask the owner.
3. Spawn the sub-agents listed for that phase, sequentially or in parallel where the phase permits.
4. Read each sub-agent handoff under `docs/system_review/agent_handoffs/`. Verify the endpoint label matches phase exit criteria.
5. Run the consolidated verification commands listed under the phase.
6. If verification passes, produce a phase exit packet at `docs/system_review/program_phases/PHASE_{N}_EXIT_{YYYYMMDD}.md` summarizing the phase, listing every changed file, attaching the test output, asking the owner: **approve / defer / rework / abandon**.
7. If verification fails, queue the failing sub-agent again with the failure detail.

The foreman never edits source under `shared/` or `presentations/` directly. It only reads, plans, and dispatches.

### 3.2 Sub-Agents (Squads)

**Ten specialized sub-agents** organized into 3 departments. Anything outside scope is escalated to the orchestrator (Tech Lead). Squads named in **bold** for friendly use; technical sub-agent identifier in `code style` for agent invocation.

#### TESTING DEPT (4 squads)

| Squad / Sub-agent | Scope | Touches | Does not touch |
|---|---|---|---|
| **Cleanup Squad** / `worktree-stabilizer` | Split 4 in-flight workstreams into focused commits, get tree clean. | Git commits, `WORKSTREAM_SPLIT_LEDGER_{date}.md`, handoff notes. | Shared module code, validator rules, report templates. |
| **Safety Net Squad** / `ci-pipeline-author` | Stand up CI, pre-commit, lint. Make `foundation_readiness` blocking. | `.github/workflows/*.yml`, `.pre-commit-config.yaml`, `pyproject.toml`, `docs/CI_AND_PRECOMMIT.md`. | Validator code, report builders, client folders. |
| **Test Squad** / `test-gap-closer` | Add tests for entrypoint wrappers, live-upload barrier, deprecated workflow. | `tests/test_entrypoint_*.py` (25 files), `tests/test_live_upload_barrier.py`, `tests/test_deprecated_workflow_blocked.py`, `tests/test_entrypoint_inventory.py`. | Validator rules, presentation templates, client folders. |
| **Workflow Squad** / `workflow-e2e-author` | One E2E test per workflow mode using fixture clients. | 6 files `tests/test_e2e_{mode}.py`, `tests/fixtures/clients/...`. | Live client folders under `clients/`. |

#### STAGING DEPT (3 squads)

| Squad / Sub-agent | Scope | Touches | Does not touch |
|---|---|---|---|
| **Format Squad** / `manifest-schema-enforcer` | Codify the run manifest as a versioned JSON schema with validator. | `shared/rebuild/run_manifest_schema.py`, `tests/test_run_manifest_schema.py`, `docs/RUN_MANIFEST_SCHEMA.md`. | Report rendering. |
| **Move Squad** / `boundary-completer` | Execute deferred 203-file migration, batched, owner-approved per wave. | `git mv` moves only, ledger updates, boundary enforcer test. | Client-visible artifacts (HTML, PDF, CSV, email draft, validation report). |
| **Package QA Squad** / `staging-validator-runner` | **(ongoing - Stage 8)** Run every validator on every new staging package before client review. Block packages that fail any check. | Validator invocations (`staging_validator.py`, `report_quality_audit.py`, `pdf_visual_audit.py`, manifest schema), per-package validation JSON, block/pass decisions. | Builder code, content generation logic. |

#### PRODUCTION DEPT (4 squads)

| Squad / Sub-agent | Scope | Touches | Does not touch |
|---|---|---|---|
| **Docs Squad** / `docs-curator` | Produce new operating docs; identify + prune stale Markdown ledger entries. | New docs in `docs/`, ledger updates with documented logical resolutions. | Source code, tests, generated client artifacts. |
| **Launch Squad** / `production-gate-author` | Produce live-upload SOP, client signoff trail, route planner criteria, dry-run runbook. | 4 new docs in `docs/`. | Code that toggles `enable_live_mutations`. |
| **Monitor Squad** / `live-ops-monitor` | **(ongoing - Stage 8)** Watch live Google Ads ops after launch. Read account health metrics, alert on anomalies, write daily health report. | Live API read-only calls, alert outputs, `docs/system_review/live_ops/daily_health_{date}.md`. | Anything that mutates live accounts. |
| **Recovery Squad** / `rollback-router` | **(ongoing - Stage 8)** When an incident hits: flip `enable_live_mutations=False`, open a bug task in Plane, route to Testing dept as new Stage 1 task. | Live-upload kill switch, Plane API (bug creation), handoff note for the incident. | Anything bug-fix related - that's Testing dept's job after routing. |

### 3.3 Communication Contract

Sub-agents do not call each other. The foreman is the only synchronizer. Sub-agents communicate by:

- Writing one timestamped handoff per task at `docs/system_review/agent_handoffs/AGENT_HANDOFF_{YYYYMMDD_HHMMSSZ}_{agent_role}_{task_slug}.md`, following the AGENTS.md format (agent identity, timestamp UTC, branch, files-changed-with-classification, tests run, next recommended action, live-action declaration which **must read `none`** for every sub-agent task in this entire program).
- Updating `docs/system_review/agent_handoffs/current.md` after every successful task.
- Writing every multi-step change as a single focused commit. No merge commits.
- Declaring the throughput endpoint label (`guardrail-only` ... `launch-ready`) in the handoff so the foreman can decide if the work matches phase target.

### 3.4 The HITL Gate

At the end of each phase, the foreman produces the **phase exit packet** at `docs/system_review/program_phases/PHASE_{N}_EXIT_{YYYYMMDD}.md` with:

- Phase number and name.
- Entry criteria evaluated (each must be `pass`).
- Exit criteria evaluated (each must be `pass`).
- All sub-agent handoffs in the phase, by SHA.
- Diff stat by file class (shared source, test, doc, config, client artifact, generated noise).
- Test output appended for the focused pytest selectors named in the phase.
- Outstanding risks transferred to the next phase.
- **One owner question: approve / defer / rework / abandon.**
- A one-paragraph plain-English summary at the top before any technical detail.

The owner replies in any channel. Approval is recorded by the foreman as a single line in `docs/system_review/program_phases/APPROVALS.md`:
```
PHASE_N | YYYY-MM-DD | approve|defer|rework|abandon | owner_email | optional_note
```
Until the line exists, the next phase does not start.

---

## 4. Documentation Set

Minimum complete set. Owner is the audience for operating docs; foreman is the audience for operating instructions; sub-agents read everything.

| Path | Owner sub-agent | Updated in | Status today |
|---|---|---|---|
| `docs/PRODUCTION_READINESS_PROGRAM.md` | docs-curator | Phase 0 produces; later phases update Status section only. | **New.** Mirrors this plan. |
| `docs/SWARM_OPERATING_MANUAL.md` | docs-curator | Phase 0 produces. | **New.** How the orchestrator + 8 sub-agents work. |
| `docs/CI_AND_PRECOMMIT.md` | ci-pipeline-author | Phase 1 produces. | **New.** Runbook for the workflows + hooks. |
| `docs/RUN_MANIFEST_SCHEMA.md` | manifest-schema-enforcer | Phase 3 produces. | **New.** JSON schema reference. |
| `docs/GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md` | production-gate-author | Phase 5 produces; Phase 6 reads. | **New.** Conditions required before any future enablement. |
| `docs/CLIENT_APPROVAL_AUDIT_TRAIL.md` | production-gate-author | Phase 5 produces; Phase 6 exercises. | **New.** Per-client approval ledger schema. |
| `docs/ROUTE_PLANNER_ENDPOINT_CRITERIA.md` | production-gate-author | Phase 5 produces. | **New.** Concrete per-label exit criteria. |
| `docs/PRODUCTION_DRY_RUN_PLAYBOOK.md` | production-gate-author | Phase 6 produces. | **New.** Phase 6 procedure. |
| `docs/system_review/program_phases/APPROVALS.md` | foreman | Every owner approval. | **New.** Append-only log. |
| `docs/system_review/program_phases/PHASE_{N}_EXIT_{YYYYMMDD}.md` | foreman | Every phase. | **New.** One per phase exit. |
| `docs/INGESTION_OPERATING_SYSTEM.md` | docs-curator | Phase 2 + Phase 5 amendments. | Exists; minor edits only. |
| `docs/HUMAN_IN_THE_LOOP_REVIEW_STAGE.md` | docs-curator | Phase 5 pointer added. | Exists. |
| `docs/GOOGLE_ADS_AGENT_PROCESS.md` | docs-curator | Phase 5 pointer added. | Exists. |
| `AGENTS.md` | docs-curator | Phase 5 one-line pointer. | Exists. |
| `docs/system_review/CLIENT_FOLDER_BOUNDARY_PR_PACKET_2026-05-13.md` | boundary-completer | Phase 4 supersedes. | Exists. |
| `docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_LEDGER_2026-05-13.csv` | boundary-completer | Phase 4 marks each row. | Exists. |
| `docs/system_review/MARKDOWN_DISPOSITION_LEDGER.csv` | docs-curator | Every phase prunes its scope. | Exists. |
| `docs/system_review/agent_handoffs/current.md` | foreman | Every sub-agent task. | Exists. |

Existing docs not on this list (`README.md`, `docs/CLIENT_DIRECTORY_SCAFFOLDING.md`, `docs/CLIENT_MANAGEMENT_SOP.md`, `docs/HTML_PDF_CLIENT_REPORT_STANDARD.md`, `docs/CLIENT_FACING_LANGUAGE_RULES.md`, `docs/SOURCE_ATTRIBUTION_AND_BRAND_RULES.md`) stay as-is. The docs-curator does not rewrite them.

---

## 5. Phased Program

Six phases. Each runs the analyze→plan→build→test loop until automated verification passes, then a phase exit packet for owner approval.

### Phase 0 - Stabilize the working tree

**Goal**: bring repo from **328 dirty entries (35 modified + 294 untracked)** to clean baseline by splitting the four in-flight workstreams into focused commits and triaging the untracked scaffold tail.

**Entry criteria**:
- Owner has signed approval for this program in `APPROVALS.md`.
- Branch is `codex/client-folder-boundary-staging-ready`.
- Latest handoff in `agent_handoffs/current.md` is the artifact triage handoff from 2026-05-13.

**Exit criteria**:
- `git status --short --untracked-files=all` returns empty.
- Every modified or untracked file is either committed, `.gitignore`d with a justified rule, or has a logical resolution ledger entry.
- The four workstreams (EMorrison revision; Full Tilt STR live; systemwide Client HQ completion; Full Tilt STR strategy packet) are each a single commit or tightly scoped commit series.
- `docs/system_review/WORKSTREAM_SPLIT_LEDGER_{date}.md` exists, mapping every changed file to its commit SHA.

**Sub-agents**: `worktree-stabilizer`.

**Deliverables**:
- Series of focused commits on `codex/client-folder-boundary-staging-ready`.
- `docs/system_review/WORKSTREAM_SPLIT_LEDGER_{date}.md`.
- Updated `docs/system_review/agent_handoffs/current.md`.

**Verification**:
- `git status --short --untracked-files=all` empty.
- `git log --since=<phase_start> --oneline` shows commit messages clearly tied to one workstream each.
- `python presentations/tools/audit_markdown_inventory.py` reports `disposition_gaps=0`.
- `python presentations/tools/bootstrap_agent_context.py --message "post-phase-0"` reports `git worktree clean: pass`.

**Owner approval**: reviews the four workstream commits + ledger.

**Complexity**: **L** (bumped from M after live recount: 328 dirty entries, not ~124; untracked tail is mostly systemwide Client HQ artifacts across 31 clients).

---

### Phase 1 - Foundation hardening

**Goal**: turn the existing `foundation_readiness` checks from advisory into blocking via CI + pre-commit + lint.

**Entry criteria**: Phase 0 approved.

**Exit criteria**:
- `.github/workflows/readiness.yml` exists; runs `python presentations/tools/check_foundation_readiness.py --require-pr-ready` on every push and PR.
- `.github/workflows/tests.yml` exists; runs `python -m pytest -q` on every push and PR.
- `.pre-commit-config.yaml` exists; runs at minimum: `git diff --check`, `python -m compileall -q shared presentations/tools tests`, ruff format check, ruff lint.
- `pyproject.toml` exists with `[tool.ruff]` + `[tool.pytest.ini_options]` only. No project-metadata or packaging changes.
- `docs/CI_AND_PRECOMMIT.md` exists; documents what each workflow runs, what each hook runs, how to interpret failure, how to escalate (the answer is: ask the owner).
- `pre-commit run --all-files` exits 0 on a clean tree.
- Both CI workflows exit 0 on the head SHA.

**Sub-agents**: `ci-pipeline-author`.

**Deliverables**: as listed under exit criteria.

**Verification**:
- `gh workflow list` shows both workflows.
- `gh run list --workflow readiness.yml --limit 1` shows a passing run.
- `gh run list --workflow tests.yml --limit 1` shows a passing run.
- `pre-commit run --all-files` exits 0 locally.
- A deliberate trailing-whitespace change triggers the hook and is rejected.

**Owner approval**: approves CI + pre-commit introduction. Reads `docs/CI_AND_PRECOMMIT.md`.

**Complexity**: M.

**Special note**: the bootstrap's `gh pr view` check needs a CI-context flag (no auth in CI). Document the conditional skip in `docs/CI_AND_PRECOMMIT.md`.

---

### Phase 2 - Test coverage for entrypoints, workflow modes, live-upload barrier

**Goal**: close the 167-module test gap where it matters most.

**Entry criteria**: Phase 1 approved. CI is enforcing tests.

**Exit criteria**:
- Each of 25 wrappers in `presentations/tools/` has `tests/test_entrypoint_{wrapper}.py` asserting: arg parsing, help-text exit code, dry-run path exits 0, no writes outside declared output directories.
- 6 new E2E tests `tests/test_e2e_{workflow_mode}.py` (one per `WorkflowName`), each: runs route planner and the relevant build/report command against a fixture client under `tests/fixtures/clients/`; asserts run manifest exists; manifest passes schema (interim minimal schema in this phase, formalized in Phase 3); `live_upload: false`; staging CSV exists; report HTML exists.
- `tests/test_live_upload_barrier.py` asserts every public method of `GoogleAdsAPIService` raises `LiveGoogleAdsAutomationDisabled` when `enable_live_mutations=False`.
- `tests/test_deprecated_workflow_blocked.py` asserts importing `shared.google_ads_workflow` exposes no callable able to perform a mutation.
- `tests/test_entrypoint_inventory.py` enumerates `presentations/tools/*.py` and fails when a new wrapper is added without a matching test.
- Test suite runtime under owner-set budget (default 5 min).

**Sub-agents**: `test-gap-closer`, `workflow-e2e-author`.

**Deliverables**: as listed.

**Verification**:
- `python -m pytest tests/test_entrypoint_*.py tests/test_e2e_*.py tests/test_live_upload_barrier.py tests/test_deprecated_workflow_blocked.py -q` exits 0.
- CI tests workflow exits 0.
- A deliberate regression in one wrapper or workflow mode causes a named test to fail.

**Owner approval**: spot-checks fixture client folders to confirm no real client names slipped in; reads two random entrypoint tests; reads one E2E test.

**Complexity**: L.

---

### Phase 3 - Validator + manifest hardening; deprecation sweep

**Goal**: lock down the manifest contract and the quality-gate cores. Make deprecated imports impossible to misuse.

**Entry criteria**: Phase 2 approved.

**Exit criteria**:
- `shared/rebuild/run_manifest_schema.py` defines a JSON schema for `run_manifest.json` covering every field in `docs/INGESTION_OPERATING_SYSTEM.md:114-127` (`workflow_type`, `source_artifacts`, `evidence_quality_summary`, `staging_file`, `report_html`, `report_pdf`, `client_email_draft`, `validation_results`, `visual_audit_dir`, `live_upload`, `next_action`). Versioned (`schema_version: 1`). Exposes `validate(manifest_path) -> ValidationResult`.
- Every workflow exit calls the validator. Non-conformant manifests fail.
- `tests/test_run_manifest_schema.py` covers happy paths + three named failure modes: missing required field; wrong type; `live_upload: true` rejected when `enable_live_mutations=False`.
- `docs/RUN_MANIFEST_SCHEMA.md` documents the schema.
- HTML/PDF audit cores have direct tests: `tests/test_report_quality_audit_core.py`, `tests/test_pdf_visual_audit_core.py`, each covering a normal-case audit + a fail-on-overlap audit + a fail-on-missing-asset audit.
- `shared/google_ads_workflow.py` is either removed (with import path raising `ImportError` from a tombstone in `shared/__init__.py`) **or** replaced with a module that raises `ImportError` on import. Choice owner-approved before commit. **Recommendation: tombstone, preserves deprecation hint.**
- One named regression test each for `provider_token_validator.py`, `match_type_policy.py`, `rsa_headline_quality.py`, `code_boundary_audit.py` - asserts the validator does its job on a known-bad fixture and stays quiet on a known-good fixture.

**Sub-agents**: `manifest-schema-enforcer`, `test-gap-closer` (validator coverage), `docs-curator` (schema doc).

**Verification**:
- `python -m pytest tests/test_run_manifest_schema.py tests/test_report_quality_audit_core.py tests/test_pdf_visual_audit_core.py -q` exits 0.
- Deliberate broken manifest in a fixture fails the schema test with the expected error.
- `python -c "import shared.google_ads_workflow"` raises `ImportError` or path no longer exists.

**Owner approval**: approves the manifest schema (it becomes the contract going forward); confirms deprecation strategy.

**Complexity**: M.

---

### Phase 4 - Boundary completion

**Goal**: execute the deferred 203-file boundary migration from `clients/**` to `docs/system_review/client_runs/**`, in owner-approved waves.

**Entry criteria**: Phase 3 approved. Manifest schema is enforced.

**Exit criteria**:
- Every row of `docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_LEDGER_2026-05-13.csv` marked `migrated`, `deferred-with-reason`, or `not-applicable-with-reason`. Zero `pending`.
- Every `git mv` preserves history. **No copy-then-delete.** (Memory: `feedback_no_overengineering.md` - "git mv not copy".)
- `tests/test_client_folder_boundary.py` enforcer test fails if a new machine-state file appears under `clients/{agency}/{client}/` outside the allowed list (client-visible only: HTML/PDF review docs, staging CSV, `client_email_draft`, source materials, owner-approved exceptions).
- `docs/system_review/CLIENT_FOLDER_BOUNDARY_PR_PACKET_2026-05-13.md` + `..._STAGING_LEDGER_2026-05-13.md` marked superseded with forward pointer to `CLIENT_FOLDER_MACHINE_MIGRATION_COMPLETION_{date}.md`.
- `python presentations/tools/audit_client_structure.py --all` exits 0 across all 31 clients.

**Sub-agents**: `boundary-completer` plus `worktree-stabilizer` for per-wave commit hygiene.

**Deliverables**:
- One commit per migration wave (`git mv` only) with per-wave handoff note.
- `tests/test_client_folder_boundary.py`.
- `docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_COMPLETION_{date}.md`.

**Verification**:
- `python presentations/tools/audit_client_structure.py --all` exits 0.
- `python -m pytest tests/test_client_folder_boundary.py -q` exits 0.
- Deliberate misplaced file in feature branch triggers enforcer test failure.
- `git log --diff-filter=R --oneline --since=<phase_start>` confirms move history preserved.

**Owner approval**: approves each wave separately. **Default batching: per agency (3 waves: arc, bluepixelmedia, therappc).** Owner can override.

**Complexity**: XL. Largest data movement in the program.

---

### Phase 5 - Production-gate documentation

**Goal**: produce the operating documents that govern any future live-upload decision. No code change - this phase is the rulebook.

**Entry criteria**: Phase 4 approved.

**Exit criteria**:
- `docs/GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md` exists. Lists every condition required before flipping `enable_live_mutations=True`:
  - All six phases approved.
  - Live-upload barrier tests green.
  - Signed credentials present at documented path + audited.
  - Per-client owner signoff in approvals ledger.
  - Dry-run packet for target client.
  - Two-person approval signature on a single approval line. **(Default. Owner may pick single-owner; document accordingly.)**
  - Explicit downstream rollback plan documented + tested.
- `docs/CLIENT_APPROVAL_AUDIT_TRAIL.md` exists. Defines per-client approval ledger at `docs/system_review/client_runs/{agency}/{client}/approvals.csv` with columns: `date_utc`, `deliverable_sha`, `deliverable_path`, `approver_email`, `decision`, `scope`, `signed_artifact_path`, `notes`. Append-only; validated.
- `docs/ROUTE_PLANNER_ENDPOINT_CRITERIA.md` exists. Per-label concrete criteria for each of the six labels: which files must exist, which validations must pass, which tests must be green, which manifest fields are required, what next step is.
- `docs/PRODUCTION_DRY_RUN_PLAYBOOK.md` exists. Specifies Phase 6 dry-run protocol.
- Cross-references added to `docs/INGESTION_OPERATING_SYSTEM.md`, `docs/HUMAN_IN_THE_LOOP_REVIEW_STAGE.md`, `docs/GOOGLE_ADS_AGENT_PROCESS.md`, `AGENTS.md`.
- `tests/test_client_approvals_ledger.py` asserts schema + append-only invariant.

**Sub-agents**: `production-gate-author`, `docs-curator`.

**Verification**:
- `docs hygiene` check in `shared/agent_routing/foundation_readiness.py:239-257` passes (no em-dashes, no broken links).
- `python -m pytest tests/test_client_approvals_ledger.py -q` exits 0.
- Markdown inventory audit reports clean ledger additions.

**Owner approval**: reads each new operating document in full. **Content-heavy review** - flagged in exit packet.

**Complexity**: M.

---

### Phase 6 - Pre-production dry run

**Goal**: exercise the whole hardened pipeline end-to-end on one owner-picked client, every gate active, no live action.

**Entry criteria**: Phase 5 approved. Owner has named target client + target workflow mode.

**Recommendation**: a recently scaffolded `new_campaign` against a low-risk client, so the dry run does not depend on existing artifacts the owner cares about.

**Exit criteria**:
- Route planner produces `build-ready` or `deliverable-ready` for the target.
- Build runs to completion producing: staging CSV; HTML review; PDF review; `client_email_draft.md`; `validation_report.json`; `pdf_visual_audit.json`; `report_static_audit.json`; `run_manifest.json`.
- Run manifest passes Phase 3 schema validator.
- `live_upload: false` recorded in the manifest.
- All gates: static audit `errors=0 warnings=0`; PDF visual audit `failures=0`; validator suite passes on staging CSV; entrypoint inventory test passes; live-upload barrier tests pass; boundary enforcer test passes.
- Per-client approval ledger entry appended with `decision=dry-run-only`.
- Phase 6 exit packet at `docs/system_review/program_phases/PHASE_6_EXIT_{date}.md` attaches manifest, audit JSONs, test outputs.

**Sub-agents**: foreman drives. Sub-agents only re-engage if a gate fails AND the fix is small enough to land within phase without re-opening an earlier phase.

**Verification**:
- Every named gate produces a documented `pass` line in the exit packet.
- The barrier in `shared/gads/core/google_ads_api_service.py` never raises `LiveGoogleAdsAutomationDisabled` during the dry run (because no code path attempts to call it). Exit packet records this explicitly.
- Owner spot-checks generated HTML/PDF + opens the staging CSV in Google Ads Editor.

**Owner approval**: approves dry-run packet. **System is now declared production-ready.** The owner is the only person who can flip `enable_live_mutations`, and only by following `docs/GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md` in a separate, deliberate action that is not part of this program.

**Complexity**: M.

---

### Phase 7 - Live Ops (Stage 8) - Continuous post-launch operations

**Goal**: keep the system healthy after real go-live. Runs forever. Three squads stay on duty across all three departments; one squad activates only on incident.

**Entry criteria**: Phase 6 approved AND owner has separately followed `docs/GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md` to flip `enable_live_mutations=True` for at least one client. **This program does not flip the switch.** Stage 8 begins after the owner does, in a separate authorized action.

**Operational continuous loops** (not exit criteria - this stage has no exit):

1. **Testing layer continuous**: Safety Net Squad CI runs on every push and PR. Test suite stays green or main is blocked.
2. **Staging layer continuous**: Package QA Squad (`staging-validator-runner`) runs on every new staging package. Generates `docs/system_review/client_runs/{agency}/{client}/package_qa_{date}.json`. Any failure blocks the package from owner review.
3. **Production layer continuous**: Monitor Squad (`live-ops-monitor`) reads live account health metrics on a schedule (recommended: daily). Writes `docs/system_review/live_ops/daily_health_{date}.md`. Alerts on anomalies via the owner notification channel.
4. **Production layer on-demand**: Recovery Squad (`rollback-router`) fires only on incident. Sequence:
   - Flip `enable_live_mutations=False` for affected accounts (kill switch).
   - Write incident handoff at `docs/system_review/agent_handoffs/AGENT_HANDOFF_{UTC}_recovery_INC-{nnn}.md`.
   - Create Plane incident parent task `[ARC-INC-{nnn}]` with child Stage 1 task routing the bug back to Testing dept.
   - Owner gets one notification: incident + rollback complete + bug routed.
   - Bug runs through Stages 1-7 again, mini-trial, owner re-greenlights, Stage 8 resumes.

**Sub-agents** (squads): `staging-validator-runner` (Package QA), `live-ops-monitor` (Monitor), `rollback-router` (Recovery). Safety Net Squad's CI continues from Phase 1.

**Deliverables** (recurring, not one-time):
- Per-package validation JSON under `docs/system_review/client_runs/{agency}/{client}/`.
- Daily health report under `docs/system_review/live_ops/daily_health_{date}.md`.
- Per-incident handoff + Plane chain `[ARC-INC-{nnn}]` -> Stage 1 bug task.

**Verification** (per-incident, not per-stage):
- A simulated incident in a pre-prod environment causes Recovery Squad to: flip kill switch, write handoff, open Plane incident task, route bug to Testing. All four happen within minutes.
- Daily health report exists for every business day after go-live.

**Owner approval**: Stage 8 has no exit gate - it never ends. Owner is pinged ONLY on incident notifications. Owner approves the **incident rollback packet** when Recovery Squad fires, and re-approves the **mini-launch packet** when the bug-fix loop completes.

**Complexity**: L (ongoing). Setup cost is small; operational cost is constant.

---

## 6. Verification & Approval Gates (consolidated)

| Phase | Automated (foreman runs) | Manual (owner verifies) | Rollback |
|---|---|---|---|
| 0 | `git status --short --untracked-files=all` empty; markdown audit; bootstrap shows `git worktree clean: pass`. | Reviews 4 workstream commits + split ledger. | `git reset --soft` to phase-start SHA. |
| 1 | `gh workflow list` shows 2 workflows; both runs pass; `pre-commit run --all-files` exits 0; readiness check exits 0. | Reads `CI_AND_PRECOMMIT.md`; introduces a deliberate trailing-whitespace change to confirm the hook catches it. | Remove workflow files + pre-commit; manual revert. |
| 2 | Named pytest selectors exit 0; CI green. | Spot-checks fixture clients; reads 2 random entrypoint tests + 1 E2E test. | Tests quarantined with a marker, not deleted. |
| 3 | Manifest schema tests + audit-core tests exit 0; `import shared.google_ads_workflow` raises `ImportError`. | Reads `RUN_MANIFEST_SCHEMA.md`; verifies broken manifest fails CI. | Schema validator gated by env var; tombstone or revert to previous stub. |
| 4 | `audit_client_structure.py --all` exits 0; boundary enforcer test exits 0; zero pending ledger rows. | Spot-checks 5 random migrated rows; verifies `git log` history preserved; reviews boundary PR supersession. | Per-wave `git revert`. Ledger preserves source path. |
| 5 | docs hygiene passes; approvals ledger test exits 0; cross-references resolve. | Reads each new operating doc in full. | Documents marked draft. |
| 6 | Every named gate produces `pass` line; manifest validates; barrier not triggered; approvals entry exists. | Inspects generated HTML/PDF; opens CSV in Google Ads Editor; confirms nothing uploaded. | Generated package marked deferred; no production change happened. |
| 7 (Stage 8) | Package QA blocks malformed staging packages; Monitor writes daily health report; Recovery test-fires successfully in pre-prod. | Receives daily health report; receives + approves incident rollback packet on each real incident; re-approves mini-launch packet after bug-fix loop. | Per-incident: kill switch already flipped; bug routes back to Testing dept as fresh Stage 1 task. |

For every phase, the handoff note has the AGENTS.md-required fields:

- Agent identity or role.
- UTC timestamp.
- Branch + worktree path.
- Task name + current phase number.
- Exact files changed.
- Per-file classification from AGENTS.md taxonomy (`shared source` | `client source fact` | `generated client artifact` | `test` | `process doc` | `health evidence` | `handoff evidence` | `generated/tool-context noise`).
- Reason for each file change.
- Tests, audits, or commands run with output summary.
- Next recommended action (`commit` | `review` | `regenerate` | `restore` | `superseded` | `generated-noise` | `owner decision`).
- **Live-action declaration. Default `none`. Must read `none` for every sub-agent task in this entire program.**

---

## 7. Risk Register

| # | Risk | Severity | Phase | Owner | Resolution artifact |
|---|---|---|---|---|---|
| 1 | Live-upload barrier untested; future refactor could remove exception path silently. | Critical | 2 | test-gap-closer | `tests/test_live_upload_barrier.py` |
| 2 | Deprecated `shared/google_ads_workflow.py` still importable. | High | 3 | manifest-schema-enforcer | Tombstone in `shared/__init__.py` + `tests/test_deprecated_workflow_blocked.py` |
| 3 | `foundation_readiness` is advisory, not blocking. | High | 1 | ci-pipeline-author | `.github/workflows/readiness.yml` + `.pre-commit-config.yaml` |
| 4 | 167 untested modules under `shared/` + `presentations/`. | High | 2 | test-gap-closer, workflow-e2e-author | 25 entrypoint tests + 6 E2E tests + Phase 3 validator regressions |
| 5 | **328 dirty entries** on active branch (35 M + 294 ??); 4 overlapping workstreams; risk of accidental commit of mixed change. Untracked tail is mostly Client HQ completion artifacts across 31 clients + BPM marine scaffolds. | High | 0 | worktree-stabilizer | Workstream split ledger + focused commit chain |
| 6 | 203-file boundary migration deferred; contract staged but unenforced. | High | 4 | boundary-completer | Migration completion ledger + boundary enforcer test |
| 7 | No client-approval audit trail. No way to prove a client signed off. | Critical | 5 | production-gate-author | `CLIENT_APPROVAL_AUDIT_TRAIL.md` + `tests/test_client_approvals_ledger.py` + per-client `approvals.csv` |
| 8 | No live-upload SOP; off-by-default but no rulebook for turning it on. | Critical | 5 | production-gate-author | `GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md` |
| 9 | Run manifest in prose only, not validated. | High | 3 | manifest-schema-enforcer | `shared/rebuild/run_manifest_schema.py` + test + doc |
| 10 | Readiness labels abstract; sub-agents disagree on `deliverable-ready`. | Medium | 5 | production-gate-author | `ROUTE_PLANNER_ENDPOINT_CRITERIA.md` |
| 11 | HTML/PDF audit cores have no direct tests; only wrappers. | Medium | 3 | test-gap-closer | `tests/test_report_quality_audit_core.py` + `tests/test_pdf_visual_audit_core.py` |
| 12 | Markdown ledger has 360 entries with descriptive dispositions; stale/superseded subset to be quantified by docs-curator at Phase 0 entry (no status enum exists today, only free-text reasons). | Low | every | docs-curator | Phase 0 quantification pass + disposition ledger updates per phase |
| 13 | STR ownership drift: input vs deliverable. | Low | 5 | production-gate-author | `ROUTE_PLANNER_ENDPOINT_CRITERIA.md` declares STR boundaries |
| 14 | No CI runtime budget; future careless test could slow the loop. | Low | 1 | ci-pipeline-author | Runtime budget in `CI_AND_PRECOMMIT.md`; pytest `slow` marker |
| 15 | Bootstrap depends on `gh pr view`; in CI without `gh` auth it reads `fail`. | Low | 1 | ci-pipeline-author | Conditional gate in `readiness.yml`; documented in `CI_AND_PRECOMMIT.md` |

---

## 8. Owner Engagement Model

Owner is non-developer, surgical, anti-overengineering. Engagement is terse, structured, infrequent.

**When the owner is pinged**:
- Once at program kickoff: foreman presents this plan, asks for sign-off, recorded as `PHASE_0_PRE` in approvals ledger.
- At every phase exit: one ping, one packet, one question (approve / defer / rework / abandon).
- Within a phase, only if a sub-agent hits a blocking decision only the owner can make (e.g. Phase 3 deprecation strategy; Phase 4 batching strategy; Phase 5 signers policy). **Budget: 3-5 in-phase asks across the entire program.** More than that means the planning was wrong.
- Never for routine fixes. Never for sub-agent disagreements - foreman resolves those by reading the documents and existing patterns.

**How the owner is pinged**:
- Phase exit packet at `docs/system_review/program_phases/PHASE_{N}_EXIT_{YYYYMMDD}.md`.
- Foreman writes a single short summary in `docs/system_review/agent_handoffs/current.md` linking to the packet.
- Foreman posts the packet path in whatever channel the owner uses (Discord, email, in-chat). The packet is the source of truth; the channel is just the doorbell.

**Plain-English assurance at every phase exit**:
- One paragraph at the top of every exit packet, plain English, no jargon, explaining what was done, why, and what the owner is being asked to approve. Followed by technical detail the owner can skip but the foreman must attach.

---

## 9. Critical Files Map

**Read by every phase (not modified)**:
- `AGENTS.md`
- `README.md`
- `docs/INGESTION_OPERATING_SYSTEM.md`
- `docs/CLIENT_DIRECTORY_SCAFFOLDING.md`
- `docs/GOOGLE_ADS_AGENT_PROCESS.md`
- `docs/HUMAN_IN_THE_LOOP_REVIEW_STAGE.md`
- `docs/HTML_PDF_CLIENT_REPORT_STANDARD.md`
- `docs/CLIENT_FACING_LANGUAGE_RULES.md`
- `docs/SOURCE_ATTRIBUTION_AND_BRAND_RULES.md`
- `shared/agent_routing/foundation_readiness.py`
- `shared/agent_routing/agent_bootstrap.py`
- `shared/rebuild/ingestion_contract.py`
- `shared/gads/core/google_ads_api_service.py`

**Created by the program**:

*Phase 0*: `docs/system_review/WORKSTREAM_SPLIT_LEDGER_{date}.md`.

*Phase 1*: `.github/workflows/readiness.yml`; `.github/workflows/tests.yml`; `.pre-commit-config.yaml`; `pyproject.toml`; `docs/CI_AND_PRECOMMIT.md`.

*Phase 2*: 25 × `tests/test_entrypoint_{wrapper}.py`; 6 × `tests/test_e2e_{workflow_mode}.py`; `tests/test_live_upload_barrier.py`; `tests/test_deprecated_workflow_blocked.py`; `tests/test_entrypoint_inventory.py`; `tests/fixtures/clients/...`.

*Phase 3*: `shared/rebuild/run_manifest_schema.py`; `tests/test_run_manifest_schema.py`; `tests/test_report_quality_audit_core.py`; `tests/test_pdf_visual_audit_core.py`; 4 × validator regression tests; `docs/RUN_MANIFEST_SCHEMA.md`.

*Phase 4*: `tests/test_client_folder_boundary.py`; `docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_COMPLETION_{date}.md`; per-wave handoffs.

*Phase 5*: `docs/GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md`; `docs/CLIENT_APPROVAL_AUDIT_TRAIL.md`; `docs/ROUTE_PLANNER_ENDPOINT_CRITERIA.md`; `docs/PRODUCTION_DRY_RUN_PLAYBOOK.md`; `tests/test_client_approvals_ledger.py`.

*Phase 6*: generated client package at `clients/{agency}/{client}/build/{date}_{workflow}/...`; machine state at `docs/system_review/client_runs/{agency}/{client}/...`; `docs/system_review/program_phases/PHASE_6_EXIT_{date}.md`.

*Created at program start, maintained throughout*: `docs/PRODUCTION_READINESS_PROGRAM.md`; `docs/SWARM_OPERATING_MANUAL.md`; `docs/system_review/program_phases/APPROVALS.md`.

**Deleted or tombstoned**: `shared/google_ads_workflow.py` (Phase 3, owner-approved).

**Moved (not deleted) via `git mv`**: 203 candidate files from `clients/{agency}/{client}/...` to `docs/system_review/client_runs/{agency}/{client}/...` across Phase 4 waves.

**Updated but not rewritten**: `docs/INGESTION_OPERATING_SYSTEM.md`; `docs/HUMAN_IN_THE_LOOP_REVIEW_STAGE.md`; `docs/GOOGLE_ADS_AGENT_PROCESS.md`; `AGENTS.md`; `docs/system_review/MARKDOWN_DISPOSITION_LEDGER.csv`; `docs/system_review/agent_handoffs/current.md`; `docs/system_review/CLIENT_FOLDER_BOUNDARY_PR_PACKET_2026-05-13.md`; `docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_LEDGER_2026-05-13.csv`.

---

## 10. Open Decisions for Owner (kickoff conversation)

Before the foreman starts Phase 0, the owner must answer the following. Each is one line; the program adapts to whichever choice is made. Plan defaults are shown.

| # | Decision | Default | Owner picks |
|---|---|---|---|
| 1 | Branching strategy | Continue on `codex/client-folder-boundary-staging-ready`; one PR per phase. | |
| 2 | Phase 0 workstream split granularity | One commit per workstream (4 commits total). | |
| 3 | Phase 3 deprecated workflow disposition | Tombstone (`shared/google_ads_workflow.py` raises `ImportError`). | |
| 4 | Phase 4 boundary batching | Per agency (3 waves: arc, bluepixelmedia, therappc). | |
| 5 | Phase 6 dry-run target | Recently scaffolded `new_campaign` against a low-risk client. | |
| 6 | CI provider | GitHub Actions. | |
| 7 | Live-upload authorization signers | Two-person (owner + named delegate). If owner is solo, document "owner solo" policy. | |
| 8 | CI runtime budget | Tests under 5 min; readiness under 2 min. | |
| 9 | Cadence between phases | Hard stop per phase (default). Can be overridden per phase with "run through Phase N+1 if all green". | |
| 10 | Owner notification channel | Local file path canonical; foreman additionally posts to one named channel. | |

---

## 11. Verification: how to test the program end-to-end

Once Phase 6 approves:

1. Open `docs/system_review/program_phases/APPROVALS.md`. Confirm one approve line per phase 0..6.
2. Run `python presentations/tools/bootstrap_agent_context.py --message "system production-ready"`. Bootstrap should report `foundation_readiness: pass` with all 10 gates green.
3. Run `python -m pytest -q`. All tests pass.
4. Run `pre-commit run --all-files`. Exits 0.
5. Run `python presentations/tools/audit_client_structure.py --all`. Exits 0 across 31 clients.
6. Open the Phase 6 dry-run packet. Confirm every gate marked `pass` and the per-client approvals ledger entry exists.
7. Open `shared/gads/core/google_ads_api_service.py`. Confirm `enable_live_mutations=False` is still the default and the barrier is still in place.
8. Open `docs/GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md`. Confirm the rulebook reads correctly and the owner is the gatekeeper for any future enablement.

At that point: **the system is production-ready.** The live-upload switch is the next deliberate, gated, separate decision - **not part of this program**.

---

## 12. Translation Table (friendly vs technical)

Both vocabularies refer to the same things. Owner + team read the left column. Claude Code agents read the right column.

| Friendly (you) | Technical (agent invocation) |
|---|---|
| Path to Launch | Production-Readiness Program |
| Tech Lead | Orchestrator / `production-readiness-foreman` |
| Squad | Sub-agent |
| 10 Squads | Swarm of 10 sub-agents |
| Department | Functional cluster |
| Stage | Phase |
| Stages 1-7 | Phases 0-6 |
| Stage 8 (Live Ops) | Continuous operations layer / Phase 7 |
| Owner signoff | HITL gate / phase exit packet |
| Launch rulebook | `docs/GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md` |
| Trial run | Pre-production dry run |
| Cleanup Squad | `worktree-stabilizer` sub-agent |
| Safety Net Squad | `ci-pipeline-author` sub-agent |
| Test Squad | `test-gap-closer` sub-agent |
| Workflow Squad | `workflow-e2e-author` sub-agent |
| Format Squad | `manifest-schema-enforcer` sub-agent |
| Move Squad | `boundary-completer` sub-agent |
| Package QA Squad | `staging-validator-runner` sub-agent |
| Docs Squad | `docs-curator` sub-agent |
| Launch Squad | `production-gate-author` sub-agent |
| Monitor Squad | `live-ops-monitor` sub-agent |
| Recovery Squad | `rollback-router` sub-agent |
| Testing dept | Cluster: Cleanup, Safety Net, Test, Workflow |
| Staging dept | Cluster: Format, Move, Package QA |
| Production dept | Cluster: Docs, Launch, Monitor, Recovery |
| File Cleanup (Stage 1) | Phase 0 - Stabilize the working tree |
| Safety Nets (Stage 2) | Phase 1 - Foundation hardening (CI + pre-commit + lint) |
| Missing Tests (Stage 3) | Phase 2 - Test coverage for entrypoints, workflows, barrier |
| Format Lock (Stage 4) | Phase 3 - Validator + manifest hardening; deprecation sweep |
| File Move (Stage 5) | Phase 4 - Boundary completion (203-file migration) |
| Launch Rulebook (Stage 6) | Phase 5 - Production-gate documentation |
| Trial Run (Stage 7) | Phase 6 - Pre-production dry run |
| Live Ops (Stage 8) | Phase 7 - Continuous post-launch operations |
| Plane prefix `[ARC-L1]`-`[ARC-L8]` | Maps 1:1 to Phases 0-7 |
| Incident task `[ARC-INC-{nnn}]` | Recovery-Squad-created bug parent that routes to Phase 0 / Stage 1 |

---

## Appendix A: Sub-agent prompts (skeleton)

Each sub-agent is invoked by the foreman with a prompt of this shape:

```
You are <sub-agent role>. You are running Phase <N> of the
Production-Readiness Program (docs/PRODUCTION_READINESS_PROGRAM.md).

Scope: <one paragraph from section 3.2 of the program>.
Inputs: <list>.
Outputs: <list of file paths>.
Success criteria: <list, copied from phase exit criteria>.
You do not touch: <list>.

Run the analyze-plan-build-test loop. When you believe you are
done, run the verification commands listed under the phase. If
they pass, write a handoff note at
docs/system_review/agent_handoffs/AGENT_HANDOFF_<UTC>_<role>_<slug>.md
following the AGENTS.md format, set live-action declaration to
"none", declare your endpoint label, and stop. Do not contact
the owner. The foreman will read your handoff.

If you hit a blocking decision only the owner can make, write a
short blocking-decision handoff note, do not proceed, and stop.
```

## Appendix B: Foreman startup prompt (skeleton)

```
You are the production-readiness-foreman. You own the phased
program documented in docs/PRODUCTION_READINESS_PROGRAM.md.

Current state: read docs/system_review/program_phases/APPROVALS.md
to find the highest approved phase. The next phase to drive is N+1.

Read the entry criteria for phase N+1. If any are unmet, stop
and write a single short message in
docs/system_review/agent_handoffs/current.md describing what
needs to be done and ask the owner.

If entry criteria are met, dispatch the sub-agents listed for
phase N+1 with the prompt skeleton from Appendix A of the
program document. You may dispatch sub-agents in parallel where
the phase permits.

When all sub-agent handoffs are in and report success, run the
phase verification commands. If they pass, produce a phase exit
packet at docs/system_review/program_phases/PHASE_<N+1>_EXIT_<date>.md
following the structure in section 3.4 of the program. Then
stop. Wait for the owner reply.

You never edit shared/, presentations/, or clients/. You only
read, plan, dispatch, and write phase-level docs.
```

---

## Appendix C: Live Plane Task Tree (created 2026-05-16)

> **Future programs**: this tree was built manually. Programs after this one use `/swarm-program <plan>` (skill) which wraps `plane tree create/polish/status/verify` and produces the same shape automatically. See `~/.claude/skills/swarm-program/SKILL.md` and `~/ai/agents/projectmanagement/plane_agent/SOP.md` Tree commands section.

The Path to Launch program is now live in Plane (AGENT project, workspace `todovibes`). 66 tasks total. Tree:

### Root + Stage Parents
| Plane ID | Title |
|---|---|
| AGENT-231 | `[ARC-L]` Path to Launch - google_ads_agent Production-Readiness Program (root, In Progress) |
| AGENT-232 | `[ARC-L1] [Testing]` Stage 1 - File Cleanup (Todo) |
| AGENT-233 | `[ARC-L2] [Testing]` Stage 2 - Safety Nets (Backlog) |
| AGENT-234 | `[ARC-L3] [Testing]` Stage 3 - Missing Tests (Backlog) |
| AGENT-235 | `[ARC-L4] [Staging]` Stage 4 - Format Lock (Backlog) |
| AGENT-236 | `[ARC-L5] [Staging]` Stage 5 - File Move (203 files, 3 waves) (Backlog) |
| AGENT-237 | `[ARC-L6] [Production]` Stage 6 - Launch Rulebook (Backlog) |
| AGENT-238 | `[ARC-L7] [Production]` Stage 7 - Trial Run (Backlog) |
| AGENT-239 | `[ARC-L8] [All Depts (continuous)]` Stage 8 - Live Ops (Backlog) |

### Stage 1 Children (Cleanup Squad / Testing)
| Plane ID | Title |
|---|---|
| AGENT-241 | `[ARC-L1.1]` Commit workstream: EMorrison budget revision |
| AGENT-242 | `[ARC-L1.2]` Commit workstream: Full Tilt STR live API package |
| AGENT-243 | `[ARC-L1.3]` Commit workstream: Systemwide Client HQ completion (31 clients) |
| AGENT-244 | `[ARC-L1.4]` Commit workstream: Full Tilt STR strategy packet |
| AGENT-245 | `[ARC-L1.5]` Triage 294 untracked files + .gitignore rules |
| AGENT-246 | `[ARC-L1.6]` Write WORKSTREAM_SPLIT_LEDGER doc |
| AGENT-247 | `[ARC-L1.7]` OWNER GATE - Approve Stage 1 exit (Needs Approval) |

### Stage 2 Children (Safety Net Squad / Testing)
| Plane ID | Title |
|---|---|
| AGENT-248 | `[ARC-L2.1]` Create .github/workflows/readiness.yml |
| AGENT-249 | `[ARC-L2.2]` Create .github/workflows/tests.yml |
| AGENT-250 | `[ARC-L2.3]` Create .pre-commit-config.yaml |
| AGENT-251 | `[ARC-L2.4]` Create pyproject.toml (ruff + pytest sections only) |
| AGENT-252 | `[ARC-L2.5]` Write docs/CI_AND_PRECOMMIT.md runbook |
| AGENT-253 | `[ARC-L2.6]` Verify CI runs green on head SHA |
| AGENT-254 | `[ARC-L2.7]` OWNER GATE - Approve Stage 2 exit |

### Stage 3 Children (Test Squad + Workflow Squad / Testing)
| Plane ID | Title |
|---|---|
| AGENT-255 | `[ARC-L3.1]` Write 25 entrypoint wrapper tests |
| AGENT-256 | `[ARC-L3.2]` Write 6 E2E workflow tests (one per WorkflowName) |
| AGENT-257 | `[ARC-L3.3]` Write tests/test_live_upload_barrier.py |
| AGENT-258 | `[ARC-L3.4]` Write tests/test_deprecated_workflow_blocked.py |
| AGENT-259 | `[ARC-L3.5]` Write tests/test_entrypoint_inventory.py |
| AGENT-260 | `[ARC-L3.6]` Create fixture client folders under tests/fixtures/clients/ |
| AGENT-261 | `[ARC-L3.7]` OWNER GATE - Approve Stage 3 exit |

### Stage 4 Children (Format Squad / Staging)
| Plane ID | Title |
|---|---|
| AGENT-262 | `[ARC-L4.1]` Build shared/rebuild/run_manifest_schema.py + test |
| AGENT-263 | `[ARC-L4.2]` Write docs/RUN_MANIFEST_SCHEMA.md |
| AGENT-264 | `[ARC-L4.3]` Write tests/test_report_quality_audit_core.py |
| AGENT-265 | `[ARC-L4.4]` Write tests/test_pdf_visual_audit_core.py |
| AGENT-266 | `[ARC-L4.5]` 4 validator regression tests |
| AGENT-267 | `[ARC-L4.6]` Tombstone shared/google_ads_workflow.py |
| AGENT-268 | `[ARC-L4.7]` OWNER GATE - Approve Stage 4 exit |

### Stage 5 Children (Move Squad / Staging)
| Plane ID | Title |
|---|---|
| AGENT-269 | `[ARC-L5.1]` Wave 1 - arc agency migration (git mv batch) |
| AGENT-270 | `[ARC-L5.2]` OWNER GATE - Approve Wave 1 (arc agency) |
| AGENT-271 | `[ARC-L5.3]` Wave 2 - bluepixelmedia agency migration |
| AGENT-272 | `[ARC-L5.4]` OWNER GATE - Approve Wave 2 (bluepixelmedia agency) |
| AGENT-273 | `[ARC-L5.5]` Wave 3 - therappc agency migration |
| AGENT-274 | `[ARC-L5.6]` OWNER GATE - Approve Wave 3 (therappc agency) |
| AGENT-275 | `[ARC-L5.7]` Write tests/test_client_folder_boundary.py enforcer |
| AGENT-276 | `[ARC-L5.8]` Mark boundary PR packet superseded |
| AGENT-277 | `[ARC-L5.9]` Write CLIENT_FOLDER_MACHINE_MIGRATION_COMPLETION ledger |
| AGENT-278 | `[ARC-L5.10]` OWNER GATE - Approve Stage 5 exit |

### Stage 6 Children (Docs + Launch Squads / Production)
| Plane ID | Title |
|---|---|
| AGENT-279 | `[ARC-L6.1]` Write docs/GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md |
| AGENT-280 | `[ARC-L6.2]` Write docs/CLIENT_APPROVAL_AUDIT_TRAIL.md |
| AGENT-281 | `[ARC-L6.3]` Write docs/ROUTE_PLANNER_ENDPOINT_CRITERIA.md |
| AGENT-282 | `[ARC-L6.4]` Write docs/PRODUCTION_DRY_RUN_PLAYBOOK.md |
| AGENT-283 | `[ARC-L6.5]` Write tests/test_client_approvals_ledger.py |
| AGENT-284 | `[ARC-L6.6]` Add cross-references in 4 existing docs |
| AGENT-285 | `[ARC-L6.7]` OWNER GATE - Approve Stage 6 exit |

### Stage 7 Children (Launch Squad / Production)
| Plane ID | Title |
|---|---|
| AGENT-286 | `[ARC-L7.1]` Owner picks target client + workflow mode for trial |
| AGENT-287 | `[ARC-L7.2]` Run route planner against target |
| AGENT-288 | `[ARC-L7.3]` Run build pipeline (full hardened flow) |
| AGENT-289 | `[ARC-L7.4]` Verify every gate produces pass |
| AGENT-290 | `[ARC-L7.5]` Append approvals ledger entry with decision=dry-run-only |
| AGENT-291 | `[ARC-L7.6]` Write PHASE_6_EXIT packet + final summary |
| AGENT-292 | `[ARC-L7.7]` OWNER GATE - Approve final - declare production-ready |

### Stage 8 Children (Live Ops - continuous, all 3 depts)
| Plane ID | Title |
|---|---|
| AGENT-293 | `[ARC-L8.1]` Continuous - CI Safety Nets run on every push/PR |
| AGENT-294 | `[ARC-L8.2]` Continuous - Package QA Squad validates every new staging package |
| AGENT-295 | `[ARC-L8.3]` Continuous - Monitor Squad writes daily health report |
| AGENT-296 | `[ARC-L8.4]` On-demand - Recovery Squad: rollback + bug routing protocol |
| AGENT-297 | `[ARC-L8.5]` Pre-prod simulated incident dry-fire test |

**Plane deeplink format**: `https://arc.todovibes.com/todovibes/browse/AGENT-{sequence}`

Root task: https://arc.todovibes.com/todovibes/browse/AGENT-231

### Polish backlog (apply per task before agent claim, not blocking)

Tasks created above have title + description + parent linkage + state. Owner-set fields still missing (per the 7-essential quality gate in `/Users/home/ai/apps/products/todovibes/CLAUDE.md`): priority, labels, assignee, target date, estimate. Two paths:

- **A**: Owner polishes each task in the Plane UI before flipping it to Approved. Manual, slow, owner-controlled.
- **B**: Run a follow-up agent (`task-polish` style) to bulk-apply sensible defaults (medium priority, +3d target, M estimate, agent label) and let owner override on the few outliers. Fast, then owner only reviews exceptions.

**Recommend B.** Saves owner time. Owner picks A or B before claiming Stage 1 starts.

---

## SUPERSEDED 2026-05-19 - HARD SCOPE CUT

After review, the 8-stage / 66-task program above was too much for a 1-person operation. Cut to **5 critical streams** focused on the live-upload switch. The rest deferred until after first real live use proves the platform.

**Cancelled in Plane** (2026-05-19): AGENT-232..239 (8 stage parents) + AGENT-248..297 (52 Stage 2-8 leaves). 58 tasks total moved to `Cancelled` state with explanatory comment.

**Kept** (Stage 1 work, already complete + gate pending): AGENT-241..246 (Completed) + AGENT-247 (Needs Approval). AGENT-231 root (In Progress) retained as program tracker.

**Replaced with 5 hard-scope streams** under AGENT-231:

| Plane ID | Stream | Why critical |
|---|---|---|
| **AGENT-331** | `[ARC-HS1]` Live-upload safety tests | Barrier never tested. Future refactor could silently remove it. |
| **AGENT-332** | `[ARC-HS2]` Manifest schema + deprecation tombstone | Output contract proven + dead module impossible to misuse. |
| **AGENT-333** | `[ARC-HS3]` E2E workflow tests | Prove all 6 workflow modes actually work end-to-end. |
| **AGENT-334** | `[ARC-HS4]` Launch rulebook + client signoff trail | Define exactly when + how live switch can flip. |
| **AGENT-335** | `[ARC-HS5]` Trial run on real client (no live action) | Final proof before declared production-ready. |

**What was dropped (and why we'll add later if needed)**:
- **CI / pre-commit / lint** (was Stage 2): nice-to-have. Manual checks for now. Add after first live use stresses the workflow.
- **25 entrypoint wrapper tests** (was Stage 3.1): speculative coverage. Cores tested via E2E suite is enough.
- **203-file boundary migration** (was Stage 5): cosmetic. Current mingling isn't breaking anything. Defer.
- **Route planner endpoint criteria doc** (was Stage 6.3): over-specified. Existing INGESTION_OPERATING_SYSTEM.md sufficient.
- **Watch Live (Monitor + Recovery)** (was Stage 8): ops work, not project work. Set up as cron + on-demand after first live use.

**Cost basis**: 5 Opus sessions estimated total. No Sonnet swarm. No restructure. No new infrastructure beyond what's already built (CLI tree commands, swarm-program skill, plane-pm-agent repo, codebase_helper).

**Sister plan also superseded**: `google_ads_agent_sonnet_swarm_execution.md` (Sonnet swarm execution) is parked. Hard scope means Opus drives all 5 streams serially. Plan stays on disk for reference if scope reopens later.

---

**End of plan.**
