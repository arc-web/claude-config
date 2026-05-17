# Path to Launch — Sonnet Swarm Execution Plan

> Plan file: `google_ads_agent_sonnet_swarm_execution.md` (renamed from harness slug `witty-roaming-hoare-agent-a741d3ac7fec35b98.md` per memory rule `feedback_plan_naming.md`).
>
> Sister plan to `google_ads_agent_production_readiness_program.md`. That plan defines **what** the 8 stages build. This plan defines **how** Sonnet sub-agents execute those 8 stages with self-test + self-correct, with all state in Plane, with no manual Opus per-task work.

---

## 1. Context

You already have a complete plan for what to build (`google_ads_agent_production_readiness_program.md`). You already have 66 Plane tasks under root `AGENT-231 [ARC-L] Path to Launch` — root + 8 stage parents (AGENT-232..239) + 57 leaves (AGENT-241..297). Stage 1 was executed manually by Claude Opus across 9 commits today (AGENT-241..246 closed; AGENT-247 sitting in **Needs Approval** waiting on your gate). Stages 2-8 (57 remaining leaves) sit in **Backlog**.

That manual model does not scale. You hand-drove every Opus session for Stage 1. Stages 2-8 are 50+ leaves; some are doc work, some are test-writing, some are mechanical `git mv` waves. Most of them are **shape work** — predictable enough that a smaller, cheaper model (Claude Sonnet) can do them well, if the scope is tight, the verification is automated, and the handoff is durable.

This plan does three things:

1. **Restructure** the 66 existing tasks from a parent/sub-issue tree into **Plane-native primitives**: one module (`google_ads_agent`), 8 cycles (one per stage), 57 leaf tasks freed of redundant parent navigation. Cycles replace stage parents as the iteration unit. The root issue stays as a program-tracker pointer. Cycles are how Plane was built to do this kind of work; we should use them.
2. **Stand up a Sonnet swarm**: one foreman session (you launch Opus once per stage) that dispatches 3-5 concurrent Sonnet sub-agents via Claude Code's `Agent` tool. Each Sonnet sub-agent is scoped to **one** task. It reads the task body, claims it in Plane, does the work, runs the task-type-specific self-test, commits, comments evidence to Plane, and moves to **Completed**. If the self-test fails 3 times, the Sonnet writes a Blocked handoff and the foreman escalates to you.
3. **Make Plane the only state**. No external queue, no spreadsheet, no markdown ledger of work-in-progress. Every task's body holds the work description. Every task's comments hold the running handoff. Every task's state is the agent's current position. The CLI is the only interface (`plane issue`, `plane move`, `plane comment`).

**Why this works**: the existing Production-Readiness plan already lists per-stage exit criteria + verification commands. Those become per-task acceptance tests automatically. The `plane` CLI already auto-appends Agent Intake Prompts to every comment. The `Agent` tool already supports `model: "sonnet"`. The swarm-program skill already produced + polished the tree. The remaining work is the swarm dispatch loop and the per-task body upgrades so every leaf is self-describing to a Sonnet sub-agent that has never seen the parent plan.

**Why not skip restructure**: parent/sub-issue trees in Plane are visual nesting, not iteration units. Cycles are the iteration unit. Today's tree gives the owner a navigation tool but gives the agent zero scheduling signal. Cycles fix that. Modules give long-lived grouping (`google_ads_agent` lives across many cycles); cycles give time-boxing (Stage 2 starts Monday, ends Friday). Use both, drop the redundant stage parents.

---

## 2. Out of Scope

- **Building anything new for the google_ads_agent repo.** This plan only restructures Plane + stands up the swarm. The work the swarm does is already specified in `google_ads_agent_production_readiness_program.md`.
- **Flipping `enable_live_mutations`.** That stays off through every stage. Already baked into the parent plan.
- **Touching tasks outside the Path to Launch tree.** Other AGENT-project tasks (BPM dealers, ZeroClaw work, copy-engine items) are untouched.
- **Rewriting the `plane` CLI** beyond the minimum gap (module/cycle assignment, which today requires direct REST calls — see Section 7.4 for the small helper to add).
- **A "Tech Lead" daemon.** The foreman is you opening one Claude Code session at the start of each stage, dispatching, and walking away. No always-on background process. No cron. No launchd.
- **Cross-cycle parallelism.** Stages run sequentially per owner-gate design. Within a cycle, leaves run parallel where dependency-free.
- **Adding new agents to the workspace.** We use the existing `Claude Code` workspace user (`4f0a2c9c-...`); Sonnet sub-agents inherit that identity. We add **one new label** (`agent:sonnet`) to distinguish swarm-spawned tasks from Opus-driven ones.

---

## 3. Plane Restructure

### 3.1 Recommended structure

```
AGENT project (todovibes workspace, UUID 0e399778-93d9-4a95-ba2f-755990dd69bc)
├── Module: google_ads_agent  (long-lived, all Path to Launch work + future)
│
├── Cycle: Stage 1 — File Cleanup            (CLOSED, Stage 1 already done)
├── Cycle: Stage 2 — Safety Nets
├── Cycle: Stage 3 — Missing Tests
├── Cycle: Stage 4 — Format Lock
├── Cycle: Stage 5 — File Move
├── Cycle: Stage 6 — Launch Rulebook
├── Cycle: Stage 7 — Trial Run
└── Cycle: Stage 8 — Watch Live              (rolling, never closes)
```

All 66 existing tasks live inside Module `google_ads_agent`. Each leaf lives in its matching Stage cycle. The root issue and the 8 stage-parent issues are handled per **Option B** below.

### 3.2 Decision on the 9 navigation issues — Recommended: Option B

| Option | What it means | Trade-off |
|---|---|---|
| **A** | Drop all 9. Cycles fully replace stages. | Cleanest. Loses the one-click program-overview URL the owner already bookmarks. Reparenting 57 leaves to "no parent" is one REST loop. |
| **B (recommended)** | Keep **AGENT-231 root only**. Drop the 8 stage parents. Cycles replace them. | Owner keeps the program URL. Stage parents are redundant once cycles exist. Reparenting 57 leaves to **AGENT-231 directly** is the same REST loop. |
| **C** | Keep all 9. Mark stage parents as "navigation only" with a label. | Three sources of truth (parent issue + cycle + module) for the same grouping. Confusing for Sonnet sub-agents reading task bodies. |

**Recommendation: Option B.** Keep AGENT-231 as the program tracker (state stays In Progress for the whole run; closes only when Stage 7 owner-gate is approved). Drop AGENT-232 through AGENT-239 (move to **Cancelled**, not deleted, so URLs in old chat threads don't 404). Reparent every Stage N leaf directly to AGENT-231.

**Why drop, not move-to-Done**: stage parents were never "done work" — they were containers. Marking them Done implies a completed deliverable. **Cancelled** is the honest label: container superseded by cycle.

### 3.3 What changes per task

| Task | Today | After restructure |
|---|---|---|
| AGENT-231 (root) | Parent of 8 stage issues, In Progress | Parent of 57 leaves directly. Module = `google_ads_agent`. No cycle. Stays In Progress until Stage 7 owner-gate. |
| AGENT-232..239 (stage parents) | Parent of 7-10 leaves each, mix of Completed (232) / Backlog | **Cancelled.** Module = `google_ads_agent`. No cycle. No children. Frozen for historical link integrity. |
| AGENT-241..247 (Stage 1 leaves) | Children of AGENT-232 | Parent = AGENT-231. Module = `google_ads_agent`. Cycle = `Stage 1 — File Cleanup`. States unchanged (most Completed, AGENT-247 Needs Approval). |
| AGENT-248..297 (Stages 2-8 leaves) | Children of AGENT-233..239 | Parent = AGENT-231. Module = `google_ads_agent`. Cycle = matching Stage N cycle. State = **Backlog** (will move to **Approved** when foreman dispatches). |

### 3.4 Cycle dates (recommended defaults, owner can override)

| Cycle | Start | End | Notes |
|---|---|---|---|
| Stage 1 — File Cleanup | 2026-05-16 | 2026-05-18 | Already done. Close cycle after AGENT-247 owner gate. |
| Stage 2 — Safety Nets | 2026-05-19 | 2026-05-22 | 7 leaves. Mostly CI scaffolding. |
| Stage 3 — Missing Tests | 2026-05-23 | 2026-05-30 | 6 leaves but 31 test files generated. Largest cycle. |
| Stage 4 — Format Lock | 2026-05-31 | 2026-06-04 | 7 leaves. Manifest schema + deprecation. |
| Stage 5 — File Move | 2026-06-05 | 2026-06-15 | 10 leaves across 3 waves. Owner gates each wave. |
| Stage 6 — Launch Rulebook | 2026-06-16 | 2026-06-20 | 7 leaves. Doc-heavy. |
| Stage 7 — Trial Run | 2026-06-21 | 2026-06-26 | 7 leaves. Foreman drives, not Sonnet. |
| Stage 8 — Watch Live | 2026-06-27 | open-ended | Rolling cycle; closes never. |

Dates are guidance, not contracts. Owner gates set true cadence.

### 3.5 New label needed

`agent:sonnet` — applied to every leaf the swarm processes. Distinguishes Sonnet-executed work from Opus-executed work (Stage 1's six closed tasks keep their existing `agent:claudecode` label, which the polish step set yesterday). The label tells you, at a glance in Plane UI, who did each task.

Create via Plane UI (the CLI has no label-create command):
- Name: `agent:sonnet`
- Color: `#10b981` or `#a855f7` (any color not yet used in the table at line 90 of SOP.md output)

After creation, capture the UUID via `plane labels AGENT | grep agent:sonnet` and store it as an env var for the foreman session.

---

## 4. Swarm Architecture

### 4.1 Two-tier model

```
You (owner)
  │
  ▼
FOREMAN  ── single Claude Code session, model=Opus (recommended)
  │       opens at start of each stage, dispatches, closes at owner gate
  │
  ├──► Sonnet sub-agent 1  (scoped to AGENT-248)
  ├──► Sonnet sub-agent 2  (scoped to AGENT-249)
  ├──► Sonnet sub-agent 3  (scoped to AGENT-250)
  ├──► Sonnet sub-agent 4  (scoped to AGENT-251)
  └──► Sonnet sub-agent 5  (scoped to AGENT-252)
       all dispatched in a single parent message via 5 parallel Agent tool calls
       each runs to completion, writes results to Plane, then ends
```

### 4.2 Foreman: Opus or Sonnet?

**Recommended: Opus.** Foreman responsibilities:

- Read all leaves in current cycle, decide dispatch order (which can run parallel, which must serialize)
- Read Sonnet handoffs as they come back, judge whether each is genuinely done
- Read failing retries, decide whether to keep dispatching or escalate to owner
- Write the per-stage owner-gate packet
- Catch edge cases a Sonnet wouldn't notice (drift between task body and actual file state, dependency violations, scope creep)

These are judgment-heavy tasks where Opus's reasoning depth pays off. Foreman runs once per stage (8 sessions total) for maybe 30-60 minutes of wall clock. Cost is small relative to swarm Sonnet calls.

**Alternative: Sonnet foreman.** Cheaper. Acceptable if the cycle has only dependency-free leaves (Stage 2 qualifies; Stage 5 does not because of wave gates). Owner picks per cycle.

### 4.3 Dispatch pattern

**One parent message, multiple Agent calls in parallel.** Claude Code's `Agent` tool supports up to N concurrent sub-agents per message — the runtime executes them in parallel and returns all results before the parent continues.

The foreman, mid-cycle, sends a message like:

> Dispatching Stage 2 wave 1 — 4 leaves in parallel.

…with 4 `Agent` tool calls in that single message, each with `model: "sonnet"` and the worker prompt template from Section 6 filled in for one specific task.

When all 4 return, foreman reads each result, marks each leaf's actual outcome in Plane (using the foreman's view, not the Sonnet's claim), and dispatches the next wave.

### 4.4 Concurrency cap

**3-5 Sonnet workers per wave.** Reasons:

- **Plane API rate limit**: 60 req/min per token. Each worker makes ~5-8 API calls (read task, claim, intermediate comments, complete). 5 workers × 8 calls = 40 calls per wave. Safe.
- **Foreman context discipline**: 5 concurrent Agent results coming back in one message is the comfortable upper bound for the foreman to digest in one read.
- **Git serialization**: workers commit to the same branch. More than 3-4 simultaneous commits creates merge conflicts. Workers run `git pull --rebase` before commit, which is fine for 3-5 but ugly above that.

### 4.5 Cycle-progression rule

```
Cycle N opens
  │
  ▼
Foreman reads all leaves in cycle, marks dispatchable ones as Approved
  │
  ▼
Foreman dispatches wave 1 (parallel-safe leaves only)
  │
  ▼ workers run, complete or fail
  │
Foreman judges results. Wave 2 if dependencies now satisfied. Repeat.
  │
  ▼
All leaves Completed (or Blocked with owner escalation)
  │
  ▼
Foreman writes owner-gate packet for stage exit
  │
  ▼
Owner approves → AGENT-{stage-gate-leaf} moves to Completed
  │
  ▼
Cycle N closes. Cycle N+1 opens.
```

**Stage N+1 cycle never opens until Stage N owner-gate is approved.** This is the only hard serialization in the program.

### 4.6 Within-stage parallel rules

Per cycle, the foreman pre-computes the dispatch graph. Examples from real leaves:

**Stage 2 (Safety Nets) — all 6 non-gate leaves are dependency-free.**
- AGENT-248 (readiness.yml), AGENT-249 (tests.yml), AGENT-250 (.pre-commit-config.yaml), AGENT-251 (pyproject.toml), AGENT-252 (CI_AND_PRECOMMIT.md), AGENT-253 (verify CI green) — dispatch first 5 in parallel; AGENT-253 (verify) runs serially after, depends on the previous 5 landing.

**Stage 3 (Missing Tests) — bottleneck is the 25 entrypoint tests.**
- AGENT-255 (25 entrypoint tests) is itself parallel-internal — Sonnet writes them in one Agent session but the actual file production is parallel-amenable. Recommended split: foreman expands AGENT-255 into 5 sub-batches of 5 tests each in the leaf body, dispatches 5 Sonnets in parallel; or treats it as one larger session.
- AGENT-256 (6 E2E tests), AGENT-257 (live-upload barrier), AGENT-258 (deprecated workflow), AGENT-259 (entrypoint inventory), AGENT-260 (fixture clients) — fully parallel. Dispatch all 5 in one wave.

**Stage 5 (File Move) — strictly serial.**
- AGENT-269 (Wave 1 arc) → AGENT-270 (owner gate) → AGENT-271 (Wave 2 bpm) → AGENT-272 (owner gate) → AGENT-273 (Wave 3 therappc) → AGENT-274 (owner gate) → AGENT-275/276/277/278 (cleanup) → AGENT-278 (final gate).

The foreman computes this graph from each cycle's task bodies + ledger files. It's not a separate scheduler — it's the foreman reading and dispatching.

---

## 5. Worker Lifecycle

Every Sonnet sub-agent follows this exact sequence. The worker prompt template in Section 6 enforces it.

```
1. READ TASK
   ▼ plane issue AGENT-XXX        (get title, description, state)
   ▼ plane --json issue AGENT-XXX (get full body + intake prompt)
   ▼ pwd cd to /Users/home/ai/agents/ppc/google_ads_agent
   ▼ git pull --rebase            (get latest)

2. CLAIM
   ▼ plane move AGENT-XXX "In Progress"
   (CLI auto-leaves an Agent Intake Prompt comment)

3. WORK
   ▼ do exactly what the task body says, no more
   ▼ if scope-creep detected, stop and write Needs Approval comment

4. SELF-TEST
   ▼ run the task-type-specific verification (see Section 5.2)
   ▼ if pass: continue
   ▼ if fail: go to step 5

5. SELF-CORRECT (only on fail)
   ▼ retry attempt #1: re-read failure output, adjust, re-run self-test
   ▼ retry attempt #2: same with more detailed retry
   ▼ retry attempt #3: same, last chance
   ▼ if all 3 fail: skip to step 8 (BLOCKED)

6. COMMIT
   ▼ git add <files actually touched>     (never -A)
   ▼ git commit -m "AGENT-XXX: <short description>"
   ▼ git push origin codex/client-folder-boundary-staging-ready

7. COMPLETE
   ▼ plane comment AGENT-XXX "<evidence packet — see template>"
   ▼ plane move AGENT-XXX "Completed"
   ▼ exit

8. BLOCKED (only on 3 failed retries or scope ambiguity)
   ▼ plane comment AGENT-XXX "<blocked handoff — see template>"
   ▼ plane move AGENT-XXX "Blocked"        (or Needs Approval if owner-decision needed)
   ▼ exit
```

### 5.1 Worker never:

- Moves a task to **Done** (humans only).
- Touches a task outside its scope (foreman handles cross-task work).
- Calls `plane comment --no-intake` (emergency flag, reserved for the foreman).
- Skips self-test ("looks right to me" is not allowed).
- Commits without a task-ID reference.

### 5.2 Self-test patterns per task type

The foreman fills in the worker prompt's `SELF_TEST_CMD` field based on the task's nature. Library:

| Task type | Self-test command | Pass condition |
|---|---|---|
| **File cleanup / commit** | `git status --short --untracked-files=all` | empty output |
| **Test-writing** | `python -m pytest <test_path> -q -x` | exit 0, at least 1 test ran |
| **Test-writing with regression check** | `python -m pytest <test_path> -q && python -m pytest -q -k <related_keyword>` | both exit 0 |
| **CI workflow scaffolding** | `python -c "import yaml; yaml.safe_load(open('<file>'))"` | exits 0, no exception |
| **Pre-commit config** | `pre-commit run --all-files` | exits 0 |
| **Doc creation** | `python presentations/tools/audit_markdown_inventory.py --since=<doc_path>` then visual line check | reports `disposition_gaps=0` for the new doc |
| **Doc with broken-ref check** | `grep -E "\[.*\]\(.*\)" <doc> \| python -c "import sys, re, os.path; [sys.exit(1) for line in sys.stdin if not os.path.exists(re.search(r'\((.+?)\)', line).group(1))]"` | exits 0 |
| **Manifest schema** | `python -m pytest tests/test_run_manifest_schema.py -q` | exit 0 |
| **Migration (git mv)** | `git log --diff-filter=R --oneline --since=<phase_start>` then per-row ledger update check | every moved row has SHA recorded |
| **Boundary enforcement test** | `python -m pytest tests/test_client_folder_boundary.py -q` | exit 0 |
| **Tombstone (import block)** | `python -c "import shared.google_ads_workflow" 2>&1 \| grep -q ImportError` | exits 0 |
| **End-to-end gate (Stage 7)** | The full Phase 6 verification suite from `google_ads_agent_production_readiness_program.md` Section 6 | every gate `pass` |
| **OWNER GATE leaf** | **No self-test.** Worker must not claim; foreman writes the packet and pings owner. | N/A |

### 5.3 Self-correct loop detail

Each retry sends a progressively richer prompt back to the same Sonnet session. The Agent tool's behavior is single-shot per call — so "retry" means the worker, mid-session, re-runs the work step + test step before giving up. The retry prompt structure inside the worker session:

```
Retry attempt #N of 3.
Previous attempt failed with:
<verbatim self-test output, last 30 lines>

Re-read the task body and acceptance criteria.
Inspect the failing file(s): <files>.
Identify the specific cause of failure.
Apply a minimal fix.
Re-run the self-test.
```

After retry #3 fails, the worker stops trying and writes the Blocked handoff. **Never retry past 3.** Triple-fail signals something the task body didn't anticipate, which means owner needs to look.

### 5.4 Foreman re-claim on stuck worker

If a worker stops responding mid-task (Agent tool times out or returns empty), the leaf stays in **In Progress** with no recent comment. The foreman polls every cycle:

```
plane --json issues AGENT --state "In Progress" | jq '.[] | select(.assignees[]? == "4f0a2c9c-83b4-4aea-b8d9-3d9589a8c998") | select((now - (.updated_at | fromdate)) > 7200) | .sequence_id'
```

Any leaf with no update in 2 hours gets dispatched fresh (same task, new Sonnet). Worker session must be idempotent — re-reading task body, checking `git status` to see if prior worker partially committed, picking up from there.

---

## 6. Worker Prompt Template

This is the standard prompt every Sonnet worker receives. The foreman fills the seven `<...>` slots per task.

```
You are a Sonnet sub-agent in the google_ads_agent production-readiness swarm.
You work exactly one task. You read it from Plane, claim it, do it,
self-test it, and complete it. You do not touch anything outside this task.

YOUR TASK: <AGENT-XXX>
REPO: /Users/home/ai/agents/ppc/google_ads_agent
BRANCH: codex/client-folder-boundary-staging-ready

═══════ STEP 1: READ THE TASK ═══════
plane issue <AGENT-XXX>
plane --json issue <AGENT-XXX>
Read the body. Read the Agent Intake Prompt at the bottom. The task body
is your contract — do exactly what it says, no more, no less.

═══════ STEP 2: PREP ═══════
cd /Users/home/ai/agents/ppc/google_ads_agent
git pull --rebase origin codex/client-folder-boundary-staging-ready
git status --short

═══════ STEP 3: CLAIM ═══════
plane move <AGENT-XXX> "In Progress"
The CLI will auto-append an Agent Intake Prompt comment.

═══════ STEP 4: DO THE WORK ═══════
<TASK-SPECIFIC GOAL IN PLAIN ENGLISH>

Files you may touch:
<EXPLICIT FILE LIST OR PATTERN>

Files you must not touch:
<EXPLICIT EXCLUSION LIST — typically: clients/**, legacy_archive/**,
worktrees/**, tasks/**, .venv/**>

If the task body and your reading of the repo disagree, stop, write a
Needs Approval comment explaining the disagreement, and move the task
to "Needs Approval" — do not guess.

═══════ STEP 5: SELF-TEST ═══════
Run this command. It must exit 0 and meet the pass condition.

  Command: <SELF_TEST_CMD>
  Pass condition: <PASS_CONDITION>

If it fails, retry up to 3 times. On retry, re-read the failure output,
identify the cause, apply a minimal fix, re-run. After retry #3, stop
and go to STEP 8 (Blocked).

═══════ STEP 6: COMMIT ═══════
git add <FILES YOU TOUCHED>     # named files only, never -A or .
git commit -m "<AGENT-XXX>: <ONE LINE WHAT YOU DID>

<2-4 LINES WHY + EVIDENCE>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push origin codex/client-folder-boundary-staging-ready

═══════ STEP 7: COMPLETE ═══════
Write a final Plane comment with the evidence packet:

plane comment <AGENT-XXX> "Completed.

Files changed:
- <path1>
- <path2>

Self-test:
  $ <SELF_TEST_CMD>
  $ <RESULT — exit code, key output line>

Commit: <SHA short>
Branch: codex/client-folder-boundary-staging-ready
Next step: foreman reviews"

plane move <AGENT-XXX> "Completed"

═══════ STEP 8 (only on triple-fail or scope ambiguity): BLOCKED ═══════
Write a Plane comment with options:

plane comment <AGENT-XXX> "Blocked after <N> retries.

Self-test command: <SELF_TEST_CMD>
Final failure (last 20 lines):
<verbatim>

Cause analysis: <one paragraph>

Options for unblock:
- Option A: <name> — <plain English>
- Option B: <name> — <plain English>  [RECOMMENDED]
- Option C: <name> — <plain English>

Need: <owner decision OR specific access OR upstream dependency>
Next step: owner reads this comment and replies in Plane."

plane move <AGENT-XXX> "Blocked"
# OR if owner-decision needed:
plane move <AGENT-XXX> "Needs Approval"

═══════ HARD RULES ═══════
- Never run a destructive git command (reset --hard, push --force, etc).
- Never touch a file outside your task's allowed list.
- Never claim more than one task per session.
- Never move a task to "Done" — that's a human-only state.
- Never skip the self-test.
- Never call `plane comment --no-intake`.
- Never exceed 3 retries.
- Stay on branch codex/client-folder-boundary-staging-ready.
- After completion, exit your session. Do not start a new task.
```

### 6.1 Filled example — AGENT-250 (Stage 2, create `.pre-commit-config.yaml`)

```
YOUR TASK: AGENT-250
REPO: /Users/home/ai/agents/ppc/google_ads_agent
BRANCH: codex/client-folder-boundary-staging-ready

STEP 4 — TASK-SPECIFIC GOAL:
Create .pre-commit-config.yaml at repo root with hooks for:
- git diff --check (whitespace + conflict markers)
- python -m compileall -q shared presentations/tools tests
- ruff format --check
- ruff check

Files you may touch: .pre-commit-config.yaml only.
Files you must not touch: shared/**, presentations/**, tests/**,
clients/**, docs/**, .github/** (those are owned by other Stage 2 tasks).

STEP 5 — SELF-TEST:
  Command: pre-commit run --all-files
  Pass condition: exit code 0
```

### 6.2 Filled example — AGENT-269 (Stage 5 Wave 1, git mv arc agency)

```
YOUR TASK: AGENT-269
REPO: /Users/home/ai/agents/ppc/google_ads_agent
BRANCH: codex/client-folder-boundary-staging-ready

STEP 4 — TASK-SPECIFIC GOAL:
Execute Wave 1 of the 203-file boundary migration.
Wave 1 scope: every row in docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_LEDGER_2026-05-13.csv
where agency_dir == "arc". Use git mv only. Never copy + delete.

For each source path:
  git mv <src> <dst>

After all moves complete, update the ledger CSV:
  for each row processed, set status="migrated", commit_sha=<your-commit-SHA>

Files you may touch:
- clients/arc/** (move only, via git mv)
- docs/system_review/client_runs/arc/** (destinations)
- docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_LEDGER_2026-05-13.csv

Files you must not touch:
- clients/bluepixelmedia/** (wave 2 owns)
- clients/therappc/** (wave 3 owns)
- any test file
- any code under shared/ or presentations/

STEP 5 — SELF-TEST:
  Command: git log --diff-filter=R --oneline --since="1 hour ago" | wc -l && python -c "import csv; rows=list(csv.DictReader(open('docs/system_review/CLIENT_FOLDER_MACHINE_MIGRATION_LEDGER_2026-05-13.csv'))); pending=[r for r in rows if r['agency_dir']=='arc' and r['status']=='pending']; print(len(pending)); exit(1 if pending else 0)"
  Pass condition: rename count matches arc rowcount AND zero pending arc rows
```

---

## 7. Plane Updates Pattern

### 7.1 At every lifecycle step

| Step | Worker command | What plane stores |
|---|---|---|
| Read | `plane issue AGENT-XXX` | (no write) |
| Claim | `plane move AGENT-XXX "In Progress"` | state change + auto intake comment |
| Mid-progress | `plane comment AGENT-XXX "<update>"` | comment with auto-appended intake |
| Self-test fail mid-retry | `plane comment AGENT-XXX "Retry #N — <reason>"` | comment with intake |
| Complete | `plane comment AGENT-XXX "<evidence>"` + `plane move AGENT-XXX "Completed"` | comment + state change |
| Block | `plane comment AGENT-XXX "<blocker + options>"` + `plane move AGENT-XXX "Blocked"` | comment + state change |
| Need owner decision | `plane comment AGENT-XXX "<decision request>"` + `plane move AGENT-XXX "Needs Approval"` | comment + state change |

### 7.2 Foreman uses

```bash
# At cycle start — read all leaves in current cycle
plane --json issues AGENT | jq '.[] | select(.module_ids? | any(. == "<google_ads_agent module UUID>")) | select(.cycle_id == "<cycle UUID for current stage>")'

# Mark dispatchable leaves as Approved before dispatch
plane move AGENT-248 "Approved"
plane move AGENT-249 "Approved"
...

# Track in-flight workers
plane issues AGENT --state "In Progress" | grep ARC-L

# Audit completed leaves before owner gate
plane issues AGENT --state Completed | grep "ARC-L<stage>\\."

# Spot blocked work
plane issues AGENT --state Blocked
```

### 7.3 Sequence of commands worker runs (literal copy-paste from prompt)

For AGENT-250 happy path:

```bash
plane issue AGENT-250
plane --json issue AGENT-250
cd /Users/home/ai/agents/ppc/google_ads_agent
git pull --rebase origin codex/client-folder-boundary-staging-ready
plane move AGENT-250 "In Progress"
# … create .pre-commit-config.yaml …
pre-commit run --all-files
# (exit 0)
git add .pre-commit-config.yaml
git commit -m "AGENT-250: add .pre-commit-config.yaml with 4 hooks

Hooks: git diff --check, compileall, ruff format check, ruff check.
pre-commit run --all-files exits 0 on clean tree.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push origin codex/client-folder-boundary-staging-ready
plane comment AGENT-250 "Completed.

Files changed:
- .pre-commit-config.yaml (new, 47 lines)

Self-test:
  \$ pre-commit run --all-files
  \$ exit 0 (all 4 hooks passed on clean tree)

Commit: a1b2c3d
Branch: codex/client-folder-boundary-staging-ready
Next step: foreman reviews; Stage 2 dependency cleared for AGENT-253"
plane move AGENT-250 "Completed"
```

### 7.4 Module + cycle assignment — the one missing CLI piece

The current `plane` CLI has **no** subcommand to add a task to a module or cycle. This is the one operational gap for the restructure. Three options:

| Option | What it means | Recommended? |
|---|---|---|
| **A** | Manual UI: drag each of 66 tasks into module + cycle in the Plane web UI | One-time toil but reliable. ~15 min via bulk select in UI. Acceptable for one-shot restructure. |
| **B** | One-off Python script using `requests` against the Plane REST API. Endpoints: `POST /workspaces/{ws}/projects/{pid}/modules/{mid}/module-issues/` and `POST /workspaces/{ws}/projects/{pid}/cycles/{cid}/cycle-issues/` | Reusable, but adds tooling. |
| **C** | Extend the `plane` CLI with `plane assign AGENT-XXX --module google_ads_agent --cycle "Stage 2 — Safety Nets"` | Best long-term, but is itself a separate development task — out of scope here. |

**Recommendation: B for restructure, then C added later by a separate task in the plane_agent repo.** Script lives at `~/ai/agents/projectmanagement/plane_agent/scripts/migrate_path_to_launch.py` and:

1. Reads 66 task UUIDs by sequence ID from `plane --json issues AGENT`
2. Looks up `google_ads_agent` module UUID (create via UI first; then UUID is captured one-time)
3. Looks up 8 stage cycle UUIDs (create cycles via UI first)
4. POSTs each task to matching module + cycle
5. Reparents 57 leaves to AGENT-231 by PATCHing `parent` field
6. Cancels AGENT-232..239 by PATCHing state to Cancelled

This script is single-shot. It does not become part of swarm runtime.

### 7.5 Plane query for daily foreman dashboard

The foreman, mid-cycle, gets the state of play in one command:

```bash
plane --json issues AGENT | jq '
  .[]
  | select(.sequence_id >= 241 and .sequence_id <= 297)
  | {seq: .sequence_id, title: .name[0:60], state: .state_detail.name, assignee: .assignees[0]}
  | "\(.seq) \(.state | .[0:10] | ljust(10)) \(.title)"
' -r | sort
```

Or just `plane issues AGENT --search "ARC-L"` for a quick view.

---

## 8. Per-Stage Worker Specs

### Stage 2 — Safety Nets (7 leaves, AGENT-248..254)

| Leaf | Task | Self-test | Parallel-safe? |
|---|---|---|---|
| AGENT-248 | Create `.github/workflows/readiness.yml` running `bootstrap_agent_context.py --require-pr-ready` | `python -c "import yaml; yaml.safe_load(open('.github/workflows/readiness.yml'))"` exit 0 | yes |
| AGENT-249 | Create `.github/workflows/tests.yml` running `pytest -q` | same YAML parse | yes |
| AGENT-250 | Create `.pre-commit-config.yaml` with 4 hooks | `pre-commit run --all-files` exit 0 | yes |
| AGENT-251 | Create `pyproject.toml` with `[tool.ruff]` + `[tool.pytest.ini_options]` | `python -c "import tomllib; tomllib.load(open('pyproject.toml', 'rb'))"` exit 0 | yes |
| AGENT-252 | Write `docs/CI_AND_PRECOMMIT.md` runbook | broken-ref grep + audit_markdown_inventory.py disposition gap = 0 | yes |
| AGENT-253 | Verify CI runs green on head SHA | `gh run list --workflow readiness.yml --limit 1 --json conclusion -q '.[0].conclusion'` == success AND same for tests.yml | **no — depends on 248-252** |
| AGENT-254 | OWNER GATE — Approve Stage 2 exit | none (foreman writes packet, no worker) | N/A |

**Dispatch plan**: Wave 1 = 248, 249, 250, 251, 252 in parallel (5 Sonnets). Wave 2 = 253 alone. Owner gate. ~1 day wall clock.

### Stage 3 — Missing Tests (6 leaves, AGENT-255..261)

| Leaf | Task | Self-test | Parallel-safe? |
|---|---|---|---|
| AGENT-255 | 25 entrypoint wrapper tests | `pytest tests/test_entrypoint_*.py -q` exit 0 AND 25 test files exist | internal-parallel (foreman splits to 5 sub-batches) |
| AGENT-256 | 6 E2E workflow tests | `pytest tests/test_e2e_*.py -q` exit 0 AND 6 test files exist | yes |
| AGENT-257 | `test_live_upload_barrier.py` | `pytest tests/test_live_upload_barrier.py -q` exit 0 | yes |
| AGENT-258 | `test_deprecated_workflow_blocked.py` | `pytest tests/test_deprecated_workflow_blocked.py -q` exit 0 | yes |
| AGENT-259 | `test_entrypoint_inventory.py` | `pytest tests/test_entrypoint_inventory.py -q` exit 0 AND adding new wrapper without test fails it | yes (but depends on 255 existing) |
| AGENT-260 | Fixture client folders under `tests/fixtures/clients/` | `pytest tests/test_e2e_*.py --collect-only -q` doesn't ERROR | yes |
| AGENT-261 | OWNER GATE | none | N/A |

**Dispatch plan**: Wave 1 = 256, 257, 258, 260 (4 Sonnets). Wave 2 = AGENT-255 split into 5 batches of 5 wrappers = 5 Sonnets. Wave 3 = 259 alone. Owner gate. ~3 days wall clock.

### Stage 4 — Format Lock (7 leaves, AGENT-262..268)

| Leaf | Task | Self-test | Parallel-safe? |
|---|---|---|---|
| AGENT-262 | Build `shared/rebuild/run_manifest_schema.py` + test | `pytest tests/test_run_manifest_schema.py -q` exit 0 | yes (foundational; do first) |
| AGENT-263 | Write `docs/RUN_MANIFEST_SCHEMA.md` | broken-ref check | yes (depends on 262) |
| AGENT-264 | `tests/test_report_quality_audit_core.py` | `pytest tests/test_report_quality_audit_core.py -q` exit 0 | yes |
| AGENT-265 | `tests/test_pdf_visual_audit_core.py` | `pytest tests/test_pdf_visual_audit_core.py -q` exit 0 | yes |
| AGENT-266 | 4 validator regression tests | `pytest tests/test_provider_token_validator_regression.py tests/test_match_type_policy_regression.py tests/test_rsa_headline_quality_regression.py tests/test_code_boundary_audit_regression.py -q` exit 0 | yes |
| AGENT-267 | Tombstone `shared/google_ads_workflow.py` | `python -c "import shared.google_ads_workflow" 2>&1 \| grep -q ImportError` exit 0 | yes (independent) |
| AGENT-268 | OWNER GATE | none | N/A |

**Dispatch plan**: Wave 1 = 262, 264, 265, 266, 267 (5 Sonnets). Wave 2 = 263 alone (depends on 262 landed). Owner gate. ~2 days wall clock.

### Stage 5 — File Move (10 leaves, AGENT-269..278) — STRICT SERIAL with wave gates

| Leaf | Task | Self-test | Order |
|---|---|---|---|
| AGENT-269 | Wave 1 — git mv arc agency rows (~65 files) | rename count matches CSV rowcount AND zero pending arc rows | 1st |
| AGENT-270 | OWNER GATE — approve Wave 1 | none | 2nd |
| AGENT-271 | Wave 2 — git mv bluepixelmedia rows (~80 files) | same check, bpm rows | 3rd (after 270) |
| AGENT-272 | OWNER GATE — approve Wave 2 | none | 4th |
| AGENT-273 | Wave 3 — git mv therappc rows (~58 files) | same check, therappc rows | 5th (after 272) |
| AGENT-274 | OWNER GATE — approve Wave 3 | none | 6th |
| AGENT-275 | Write `tests/test_client_folder_boundary.py` enforcer | `pytest tests/test_client_folder_boundary.py -q` exit 0 AND deliberate misplacement fails | 7th |
| AGENT-276 | Mark boundary PR packet superseded | doc edit only, line check | 8th, parallel with 277 |
| AGENT-277 | Write `CLIENT_FOLDER_MACHINE_MIGRATION_COMPLETION_{date}.md` | broken-ref check | 8th, parallel with 276 |
| AGENT-278 | OWNER GATE — approve Stage 5 exit | none | 9th |

**Dispatch plan**: one Sonnet per wave (no parallel — too easy to mis-route a file). After wave gates, 275, 276, 277 in parallel. Owner gate. ~5-7 days wall clock with 3 owner gates.

### Stage 6 — Launch Rulebook (7 leaves, AGENT-279..285)

| Leaf | Task | Self-test | Parallel-safe? |
|---|---|---|---|
| AGENT-279 | Write `GOOGLE_ADS_API_UPLOAD_AUTHORIZATION_GATE.md` | broken-ref check + audit_markdown_inventory disposition gap = 0 | yes |
| AGENT-280 | Write `CLIENT_APPROVAL_AUDIT_TRAIL.md` | same | yes |
| AGENT-281 | Write `ROUTE_PLANNER_ENDPOINT_CRITERIA.md` | same | yes |
| AGENT-282 | Write `PRODUCTION_DRY_RUN_PLAYBOOK.md` | same | yes |
| AGENT-283 | Write `tests/test_client_approvals_ledger.py` | `pytest tests/test_client_approvals_ledger.py -q` exit 0 | yes |
| AGENT-284 | Add cross-references to 4 existing docs | broken-ref check across all 4 docs | yes (light-touch edits) |
| AGENT-285 | OWNER GATE | none | N/A |

**Dispatch plan**: Wave 1 = 279, 280, 281, 282 (4 Sonnets). Wave 2 = 283, 284 (2 Sonnets). Owner gate. ~2 days wall clock (doc-heavy but mechanical).

### Stage 7 — Trial Run (7 leaves, AGENT-286..292) — FOREMAN DRIVES

| Leaf | Task | Self-test | Notes |
|---|---|---|---|
| AGENT-286 | Owner picks target client + workflow mode | none — owner action | requires owner input before dispatch |
| AGENT-287 | Run route planner against target | `python presentations/tools/route_agent_message.py --client <X> --workflow <Y>` exits 0 with `endpoint_label=build-ready` or `deliverable-ready` | foreman, not Sonnet |
| AGENT-288 | Run build pipeline (full hardened flow) | All 8 artifacts exist + manifest schema validates | foreman |
| AGENT-289 | Verify every gate produces pass | every gate's verification script exits 0 | foreman |
| AGENT-290 | Append approvals ledger entry decision=dry-run-only | grep approvals.csv for new row | foreman |
| AGENT-291 | Write PHASE_6_EXIT packet | packet file exists at `docs/system_review/program_phases/PHASE_6_EXIT_{date}.md` | foreman |
| AGENT-292 | OWNER GATE — final, declare production-ready | none | owner approves whole program |

**Dispatch plan**: foreman runs 287-291 sequentially, no Sonnet dispatch. Stage 7 is judgment-dense — too risky to fan out. Owner picks target at start; final gate is the program completion. ~1 day foreman wall clock.

### Stage 8 — Watch Live (5 leaves, AGENT-293..297) — ROLLING, NEVER CLOSES

| Leaf | Task | Self-test | Cadence |
|---|---|---|---|
| AGENT-293 | Continuous CI — Safety Nets run on every push/PR | `gh run list --limit 1 --json conclusion` shows success on tip | already in flight after Stage 2 — leaf stays In Progress forever |
| AGENT-294 | Continuous Package QA — validates every new staging package | per-package validation JSON exists at expected path | rolling, fires on each package creation |
| AGENT-295 | Continuous Monitor — daily health report | `docs/system_review/live_ops/daily_health_{date}.md` exists for today | one Sonnet dispatch per business day via separate cron/launchd (out of scope for this swarm plan) |
| AGENT-296 | On-demand Recovery — rollback + bug routing | simulated incident in pre-prod triggers all 4 actions in minutes | dormant until incident |
| AGENT-297 | Pre-prod simulated incident dry-fire test | dry-fire test passes | one-time, dispatched once after Stage 7 gate |

**Dispatch plan**: Stage 8 isn't a fan-out stage — it's a forever-watch stage. After Stage 7 gate, foreman dispatches AGENT-297 once (simulated incident test). The other 4 are operational, not project work. They get separate runtime (Monitor cron, CI hooks, package-qa hook in build pipeline) — design covered in `google_ads_agent_production_readiness_program.md` Section 5 Phase 7. The Sonnet swarm wraps up after AGENT-297 passes.

---

## 9. Owner Engagement Model

### 9.1 When you get pinged

| Trigger | What you see |
|---|---|
| Stage 1 owner gate (AGENT-247) | already pending — your queue |
| Stage 2 owner gate (AGENT-254) | foreman writes packet, posts URL to your Plane queue |
| Stage 3 owner gate (AGENT-261) | same |
| Stage 4 owner gate (AGENT-268) | same |
| Stage 5 Wave 1 gate (AGENT-270) | same |
| Stage 5 Wave 2 gate (AGENT-272) | same |
| Stage 5 Wave 3 gate (AGENT-274) | same |
| Stage 5 exit gate (AGENT-278) | same |
| Stage 6 owner gate (AGENT-285) | same |
| Stage 7 target-pick (AGENT-286) | foreman asks you which client + workflow mode |
| Stage 7 final gate (AGENT-292) | program-completion packet — system declared production-ready |
| Any worker triple-fail → Blocked | foreman batches into a daily summary; one ping per day max |
| Owner-decision Blocked (Needs Approval) | foreman batches into same daily summary |
| Critical anomaly (security, data loss risk) | foreman pings immediately, out-of-band |

**Total expected pings**: 11 owner gates + ~3-5 in-program decisions across 7 stages = ~15 owner interactions. Same shape as the original plan budget.

### 9.2 What an owner-gate packet looks like

Foreman writes one Plane comment on the gate task (AGENT-{stage-gate}) with this shape:

```
Stage <N> exit packet — <Stage Name>

Cycle: <Stage N — Name>
Leaves: <X> completed, <Y> blocked, <Z> needs approval
Wall clock: <start date> → <end date>
Commits: <N> on codex/client-folder-boundary-staging-ready

What got done (one paragraph plain English):
<...>

Verification commands (foreman ran these, all pass):
- <cmd1> → exit 0
- <cmd2> → exit 0
- <cmd3> → expected output

Files changed:
- <count> by type (source / test / doc / config)

Outstanding risk:
- <none, or list>

One question: approve / defer / rework / abandon?

[link to APPROVALS.md in repo if applicable]
```

You reply in Plane (or any channel) with one word + optional reason. Foreman records to `docs/system_review/program_phases/APPROVALS.md` and proceeds.

### 9.3 Daily Blocked summary (only when there's something to report)

If the foreman has Blocked or Needs Approval leaves, you get one consolidated message per day:

```
Daily blocker summary — <date>

Blocked (need access or unblock):
- AGENT-XXX: <one-line cause>. Need: <what>.

Needs Approval (need your decision):
- AGENT-YYY: <one-line context>. Options: A / B (recommended) / C.

All others: progressing.
```

If both are empty, no message. You only hear from the foreman when there's a real reason.

---

## 10. Failure + Recovery

| Failure mode | Detection | Recovery |
|---|---|---|
| Worker crashes mid-task (Agent tool times out) | Plane task stuck in In Progress with no comment for >2h | Foreman polls; re-dispatches fresh Sonnet on same task. New session is idempotent — reads task body, checks `git status` for partial work, picks up. |
| Plane API 429 (rate limit) | CLI returns 429 | CLI auto-retries with backoff. No worker action. If persistent, worker writes Blocked, foreman waits 10 min and re-dispatches. |
| Plane API 401 (token rotated) | CLI returns 401 | Worker runs `plane refresh --token`, retries once. If still 401, writes Blocked, foreman escalates. |
| Plane API 502/503/504 | CLI returns 5xx | CLI auto-retries. Same as 429. |
| Self-test fails 3x | Worker counts retries internally | Worker writes Blocked handoff with last failure output + cause analysis + 3 options + recommendation. Moves to Blocked or Needs Approval. |
| Worker hits unexpected file outside scope | Worker reads scope from prompt, sees mismatch | Stop immediately. Write Needs Approval comment describing the mismatch. Do not guess. |
| Git push conflict (concurrent worker) | `git push` fails non-fast-forward | Worker runs `git pull --rebase`, re-runs self-test (to confirm rebase didn't break anything), pushes again. If self-test breaks after rebase, writes Blocked. |
| Workspace dispatch limit hit | Agent tool returns capacity error | Foreman pauses dispatch, waits 60s, retries. |
| Worker session blows context | Sonnet truncates mid-task | New worker dispatch on same task. Use idempotency: worker checks if work already committed before re-doing. |
| Foreman session context overflow | Opus session can't track all leaves | End foreman session, owner opens a fresh one. New foreman queries Plane to reconstruct state — no external state. |
| Self-test command itself broken | Worker can't reach a verdict | Treat as triple-fail. Worker writes Blocked with note "self-test command was \<X>, failure was tooling not work". Foreman fixes prompt template + re-dispatches. |
| Owner away during gate | Stage cycle stalls in completed-leaves-but-no-gate-approval state | Acceptable. Cycle stays open. Next stage cycle doesn't open. No work lost. |

### 10.1 Stuck-task recovery — owner-runnable command

If the swarm appears stuck, owner can run:

```bash
plane --json issues AGENT | jq '
  .[]
  | select(.sequence_id >= 241 and .sequence_id <= 297)
  | select(.state_detail.name == "In Progress")
  | {seq: .sequence_id, title: .name[0:50], updated: .updated_at, mins_idle: (((now - (.updated_at | fromdate)) / 60) | floor)}
' | jq -s 'sort_by(.mins_idle) | reverse'
```

Any task with `mins_idle > 120` is presumed stuck. Owner can either wait (foreman polls eventually) or message Claude Code: "AGENT-XXX has been stuck 3 hours, re-dispatch fresh."

---

## 11. Implementation Steps

This is the concrete sequence to go from "today" (66 manual tasks in old tree) to "Stage 2 swarm running."

### Phase A — Plane restructure (one-shot, ~30 minutes total)

1. **Add `agent:sonnet` label** in Plane UI (AGENT project → Labels → New). Capture UUID via `plane labels AGENT | grep agent:sonnet`.

2. **Create module** in Plane UI (AGENT project → Modules → New): name = `google_ads_agent`. Capture UUID from URL or `plane --json projects` (requires CLI extension — easier to grab from the module URL in UI).

3. **Create 8 cycles** in Plane UI (AGENT project → Cycles → New) with dates from Section 3.4. Capture each cycle UUID.

4. **Run migration script** (the one-off Python at `~/ai/agents/projectmanagement/plane_agent/scripts/migrate_path_to_launch.py` from Section 7.4). This script:
   - Adds 66 tasks to module `google_ads_agent`
   - Adds Stage N leaves to Stage N cycle
   - Reparents 57 leaves to AGENT-231
   - Cancels AGENT-232..239

5. **Verify restructure**: `plane --json issues AGENT | jq '.[] | select(.module_ids[]? == "<gads UUID>") | .sequence_id'` returns 66. Spot-check 5 random leaves in Plane UI — confirm module, cycle, parent.

6. **Update task descriptions** for Stages 2-8 leaves where today's body is just a one-line stub. Each leaf needs the worker-prompt-ready fields:
   - Plain English goal (1-2 sentences)
   - Files you may touch (explicit list/pattern)
   - Files you must not touch (explicit exclusion)
   - Self-test command + pass condition
   - Acceptance criteria (copy from parent plan's exit criteria for matching stage)

   This is a one-time foreman pass — Opus reads `google_ads_agent_production_readiness_program.md` Section 5, the current 57 leaf bodies, and updates each leaf body via `plane comment` + body PATCH (Plane API). Estimated 2-3 hours.

### Phase B — Foreman dry-run on Stage 2 (~2 hours)

7. **Open foreman session**: launch Claude Code in `/Users/home/ai/agents/ppc/google_ads_agent`. Paste this prompt:

   > You are the foreman for Path to Launch Stage 2. Read `~/.claude/plans/google_ads_agent_sonnet_swarm_execution.md` Section 8. Read the 7 Stage 2 leaves via `plane --json issues AGENT --search "ARC-L2"`. Move dispatchable leaves (248, 249, 250, 251, 252) to "Approved." Dispatch them as 5 parallel Sonnet sub-agents using the worker prompt template in Section 6. When all 5 return, mark each leaf's actual outcome in Plane. Dispatch AGENT-253 alone. When it completes, write the Stage 2 owner gate packet on AGENT-254 and ping me.

8. **Foreman dispatches**. Watch the foreman's terminal — it will print 5 Agent tool calls in one message, then summarize each return.

9. **Read Plane** in browser or `plane issues AGENT --state Completed | grep ARC-L2`. Confirm all 6 work leaves Completed, AGENT-254 sitting Needs Approval.

10. **Approve Stage 2 gate**: comment on AGENT-254 with "approve" + reason. Foreman moves it to Completed. Cycle closes.

### Phase C — Full run (Stages 3-7, ~3-4 weeks wall clock)

11. **Stage 3 dispatch**: same shape as Stage 2 but with more leaves. Open foreman session. Foreman reads Stage 3 cycle leaves, dispatches in waves per Section 8 Stage 3. Owner gate.

12. **Stages 4, 5, 6**: same pattern. Stage 5 has 3 wave gates inside it — owner gets 3 mid-stage pings.

13. **Stage 7**: foreman drives directly (no Sonnet dispatch). Owner picks target client at AGENT-286. Foreman runs route planner, build, verification, packet. Owner approves AGENT-292 — system declared production-ready.

### Phase D — Stage 8 cutover

14. **Foreman dispatches AGENT-297** (one-time simulated incident dry-fire). On pass, Stage 8 work transitions to operational runtime (Monitor cron, Package QA hook, Recovery on-demand). Foreman role ends. Swarm dissolved.

### Phase E — Plan retro (optional, ~1 hour)

15. **Foreman writes retro**: `docs/system_review/program_phases/PATH_TO_LAUNCH_RETRO_{date}.md` listing: what stages took the wall-clock time projected vs actual, which workers had to retry, which Blockeds escalated to owner, lessons for next swarm program. Updates `~/.claude/skills/swarm-program/SKILL.md` if any patterns generalize.

---

## 12. Verification — how to confirm the swarm works before unleashing on all 7 stages

**Smoke test on AGENT-250** (the simplest dependency-free Stage 2 leaf):

1. Restructure complete (Phase A done).
2. Manually move AGENT-250 to **Approved**.
3. Dispatch a single Sonnet sub-agent with the worker prompt template Section 6.1 filled in.
4. Watch the Sonnet run end-to-end in one tool-call sequence.
5. Verify after return:
   - File `.pre-commit-config.yaml` exists at repo root and contains 4 hooks
   - `git log --oneline -1` shows commit with `AGENT-250:` prefix
   - `plane issue AGENT-250` shows state **Completed**
   - Plane comment thread shows: claim → in-progress → evidence packet
   - Comment contains an Agent Intake Prompt with all 8 required sections
6. If all 5 check out, the contract is sound — proceed to full Stage 2 dispatch.
7. If anything fails, identify which step broke (was self-test wrong? Was scope unclear? Did Sonnet skip a step?), fix the worker prompt template, re-run smoke test on a different leaf (AGENT-251 or AGENT-252).

**Acceptance for "swarm works"**:
- One smoke-test leaf completes end-to-end correctly with no foreman intervention.
- One self-test failure case triggers proper Blocked behavior (force-fail the test in a sandbox dispatch on a fixture leaf — confirm worker retries 3x, writes Blocked comment with 3 options, moves state to Blocked).
- One owner-decision case triggers proper Needs Approval behavior (give worker a task with intentionally ambiguous scope — confirm worker stops, writes Needs Approval comment, moves state).

These three smoke tests together prove: happy path, fail path, and ambiguity path. After they pass, dispatch Stage 2 wave 1 with confidence.

---

## 13. Critical Files Map

**Read at swarm setup (existing files, don't modify):**
- `/Users/home/.claude/plans/google_ads_agent_production_readiness_program.md` — the source of truth for what each stage builds
- `/Users/home/ai/agents/projectmanagement/plane_agent/SOP.md` — Agent task review SOP (canonical lifecycle pattern)
- `/Users/home/ai/agents/projectmanagement/plane_agent/task_intake.py` — Agent Intake Prompt formatter, gives us the comment format we rely on
- `/Users/home/.claude/skills/swarm-program/SKILL.md` — the existing skill that built the 66-task tree; this plan extends it
- `/Users/home/ai/agents/ppc/google_ads_agent/AGENTS.md` — repo contract every worker must respect

**Created at swarm setup (Phase A):**
- `~/ai/agents/projectmanagement/plane_agent/scripts/migrate_path_to_launch.py` — one-shot module/cycle assignment + reparent script
- 57 updated task bodies in Plane (no local file — Plane is the storage)

**Created during operation (Phases B-D):**
- All deliverables in `google_ads_agent_production_readiness_program.md` Section 9 (created by Sonnet workers per stage)
- `docs/system_review/program_phases/PHASE_{N}_EXIT_{YYYYMMDD}.md` per stage gate (foreman writes)
- `docs/system_review/program_phases/APPROVALS.md` append-only log (foreman writes per owner gate)
- Plane comments on every leaf (worker writes; CLI auto-appends Intake Prompt)

**Updated (extended) for module/cycle support — optional, post-swarm:**
- `~/ai/agents/projectmanagement/plane_agent/plane` — add `plane assign AGENT-XXX --module <name> --cycle <name>` subcommand
- `~/ai/agents/projectmanagement/plane_agent/SOP.md` — document the new subcommand
- `~/.claude/skills/swarm-program/SKILL.md` — reference module/cycle handling in the polish step

---

## 14. Open Decisions for Owner

Before Phase A kicks off, the owner answers each line. Defaults shown.

| # | Decision | Default | Owner picks |
|---|---|---|---|
| 1 | Drop stage parents (AGENT-232..239) or keep as Cancelled? | **Cancelled** (preserves URLs, removes from active queue) | |
| 2 | Foreman model | **Opus** | |
| 3 | Sonnet model | **Claude Sonnet 4.5** (latest as of 2026-05-18) | |
| 4 | Max concurrent workers per wave | **5** | |
| 5 | Branch strategy | **Stay on `codex/client-folder-boundary-staging-ready`** (parent plan default) | |
| 6 | New `agent:sonnet` label color | `#10b981` (green) or owner pick | |
| 7 | Cycle dates | per Section 3.4 (5/19 - 6/26 for active work) | |
| 8 | Owner notification channel for daily summaries | **Plane comments only** (alternative: also Discord ping) | |
| 9 | Stage 7 dry-run target client + workflow | owner picks at AGENT-286 — default = recently scaffolded `new_campaign` against a low-risk client | |
| 10 | Stage 2 first dispatch as smoke test (one leaf) or full wave? | **Smoke test on AGENT-250 first**, then full wave on confirmation | |
| 11 | Approve building `migrate_path_to_launch.py` one-shot, or do module/cycle via UI bulk select? | **One-shot script** (faster, audit trail) | |
| 12 | Acceptable per-stage wall clock budget before "this is taking too long" owner check-in | **Stage end-date + 3 days** (Section 3.4 dates are soft) | |

After answering 11/12, owner says "go" and Phase A begins.

---

Done: drafted the full Sonnet swarm execution plan (~6,500 words) covering Plane restructure, swarm architecture, worker lifecycle, per-stage specs, Plane CLI patterns, owner engagement, failure recovery, implementation steps, and verification. The plan is concrete (real task IDs, real commands, real file paths) and identifies the one operational gap — the `plane` CLI has no module/cycle assignment subcommand, which needs a one-shot REST script for restructure.

Open: I could not write the plan to disk — this read-only planning mode has no Write tool available, and the harness-suggested path is `/Users/home/.claude/plans/witty-roaming-hoare-agent-a741d3ac7fec35b98.md` (placeholder slug). Need owner approval on (a) the 12 Open Decisions in Section 14, especially decision #1 (drop or cancel stage parents) and #11 (script vs UI for restructure), and (b) the final filename, with recommendation `google_ads_agent_sonnet_swarm_execution.md`.

### Critical Files for Implementation
- /Users/home/.claude/plans/google_ads_agent_production_readiness_program.md
- /Users/home/ai/agents/projectmanagement/plane_agent/plane
- /Users/home/ai/agents/projectmanagement/plane_agent/SOP.md
- /Users/home/ai/agents/projectmanagement/plane_agent/task_intake.py
- /Users/home/.claude/skills/swarm-program/SKILL.md

Recommend: owner reviews the plan inline above, picks values for the 12 Open Decisions in Section 14, and gives an explicit "go" so I can switch out of plan mode and (in order) write the plan to disk, rename to `google_ads_agent_sonnet_swarm_execution.md`, then proceed to Phase A — create the `agent:sonnet` label, create the `google_ads_agent` module, create 8 stage cycles, and build the one-shot migration script.