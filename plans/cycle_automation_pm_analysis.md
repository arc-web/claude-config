# Cycle Automation + PM Stack Analysis

## Context

Just built a 42-issue tree in Plane (AGENT-342 + family) and you asked whether it should be a cycle. I answered "module" first - wrong. Cycle is the right word for a delivery batch with start/end dates. Question now expands to: how does Plane PM compare to GitHub PM, how does cycle planning work in general, when should agents recommend or auto-create cycles, and specifically should this 42-issue batch become a cycle right now. Outcome: clear cycle policy, an extension to the `plane` CLI (which today is read-only for cycles), and agent-inference rules so this never has to be asked manually again.

---

## Part 1 - PM in GitHub vs Plane vs general

### GitHub native PM stack

- **Issues**: labels, milestones, assignees, sub-issues (up to 100/parent, 8 levels deep; replaced retired task lists Apr 2025).
- **Projects v2**: custom fields, **iterations** (= cycles), board/table/roadmap views, built-in automations, burn-up charts.
- **Milestones**: time-boxed issue grouping; weaker than Projects.
- **Iterations**: auto date-range, @current/@next/@previous filters, but no burn-down, no velocity, no auto-transfer of incomplete items.
- **Webhooks**: 73+ events; can drive external sync.
- **Actions**: workflow-triggered automation.

### Plane PM stack (what's actually built)

- **Workspace > Project > Module/Cycle > Issue > sub-issue (parent field)**.
- **Module** = scope-grouping (theme/feature). Persistent.
- **Cycle** = time-grouping (sprint). Time-boxed.
- **Cycle status field is broken in CE** - empty on all cycles. `plane sprint` derives active state via date math (`start_date <= today <= end_date`), not status field.
- **Cycles in AGENT today**: 5 (1 active "Sprint 1 - Google APIs & GHL" 2026-05-16 to 2026-05-30 with 12 issues; 4 weekly buckets, 3 empty).
- **plane CLI cycle ops today**: only `plane cycles` (list) and `plane sprint` (cross-project active-cycle issues). NO create-cycle, NO add-issue-to-cycle, NO move-between-cycles. Plane API supports these endpoints but the CLI does not wrap them. SOP says "cycles need UI for now."

### Plane <-> GitHub bridge in our setup

- **No active sync.** No webhook, no Actions workflow, no sync daemon. SOP documents GitHub-backed task states (manual discipline: Plane state must mirror PR delivery state).
- **Repo exists**: `arc-web/plane-pm-agent`. Stale branch `Codex/docs/github-backed-plane-state` suggests prior exploration.
- **GH Iterations <-> Plane Cycles** are conceptually 1:1 but no automation crosses the boundary.

### PM in general - cycle theory

Five industry heuristics for "when to start a new cycle":
1. **Fixed cadence** (most common, most valuable): 1-2 week sprint length, kept constant. Rhythm beats clever triggers.
2. **Batch size threshold**: shrink batches iteratively to reduce WIP; balance vs context-switch cost.
3. **Stakeholder loop**: align cycle length to decision cadence (weekly review -> 1-week cycle).
4. **Deadline pressure**: shorter cycles approaching a hard date.
5. **Scope completion**: open new cycle when prior cycle >= 80% closed.

Strong consensus: fix the cadence, don't dynamic-trigger every batch. Cycles serve sync + planning, not project tagging.

---

## Part 2 - Does THIS 42-issue batch warrant a cycle?

**No, not on its own.** Reasoning:

- 42 issues span 6 sub-themes (A-F) and three projects (AGENT/INFRA/DEVOPS). Total estimate ~25-30 hours human time (sum of leaf minutes). That's 2-3 weeks of solo focused work or 4-6 weeks part-time.
- A cycle is a **delivery commitment** for a window. Committing all 42 to one cycle would either lock a 4-6 week cycle (too long; you have weekly cycles already) or overstuff a 1-2 week cycle.
- The batch is better expressed as the **module** ("OpenBao Hardening" - already created) plus **selective cycle attachment** of whichever leaves you actually plan to deliver in the current week.
- The active cycle "Sprint 1 - Google APIs & GHL" is themed for unrelated work. Don't pollute it.

**Recommendation:** Pick 3-6 leaves to deliver this week, attach those to a new 1-week cycle "OpenBao Hardening Week 1 - 2026-05-19 to 2026-05-25". Rest stay in the module, no cycle, until promoted.

Specific first-week candidates (highest leverage, low coupling):
- **INFRA-177 (B1)** Live AppRole TTL audit, 30min - unblocks B2 + C7
- **INFRA-187 (E6)** cloudflared upgrade 2026.3.0 -> 2026.5.0, 15min - quick win
- **AGENT-365 (F1)** Codex postmortem doc, 30min - documents fresh memory
- **AGENT-356 (C4)** Refresh agent_credential_map.md, 30min - touches stale memory
- **AGENT-358 (C6)** INFRA-145 coordination comment, 10min - cheap dependency mgmt
- **AGENT-366 (F4)** Close as Done (already verified during build), 5min

Sum ~2 hours. Realistic for one week alongside other work. Rest deferred to Week 2 cycle.

---

## Part 3 - When agents should recommend or auto-create cycles

### Decision tree (for the plane-pm-agent)

```
NEW ISSUES CREATED OR BATCH DETECTED
  |
  v
Is batch >= 3 issues with same module/parent/label, created within 24h?
  |
  No -> do nothing
  |
  Yes
  v
Is there an active cycle (today in start_date..end_date) in this project?
  |
  Yes
  v
Is active cycle <50% capacity? -> recommend attaching some leaves to active cycle
Is active cycle >=50% or thematically unrelated? -> recommend new cycle
  |
  No (no active cycle)
  v
Recommend new 1-week cycle starting next Monday OR today (per project preference)
```

### Inputs the agent should weigh

- **Batch size** (issue count, total time estimate sum)
- **Existing cycle theme overlap** (compare cycle name vs new-issue titles via embedding or keyword)
- **Capacity** (open issues in active cycle vs typical velocity)
- **Time-since-last-cycle-close** (if previous cycle 100% done >7d ago, prompt new)
- **Hard deadlines** in any issue description (parse for date strings)
- **Cycle cadence consistency** (favor matching prior cycle length over dynamic length)

### Recommend vs auto-create

- **Auto-create** is dangerous: cycles are commitments. Auto-spinning one creates phantom deadlines and pollutes burn-down/velocity if agents do it wrong.
- **Recommend, don't enact**: agent posts "Detected batch of 42 OpenBao issues. Suggest cycle 'OpenBao Hardening Week 1' 2026-05-19 to 2026-05-25 with leaves: INFRA-177, INFRA-187, AGENT-365, AGENT-356, AGENT-358, AGENT-366. Confirm with `plane cycle apply <recommendation-id>`."
- **Auto-attach existing-cycle membership** OK when thematically obvious + free capacity. Auto-create new cycle NOT OK without HITL.

---

## Part 4 - Implementation plan

### Critical files

- `~/ai/agents/projectmanagement/plane_agent/plane` - extend CLI with cycle write ops + recommendation
- `~/ai/agents/projectmanagement/plane_agent/SOP.md` - add cycle automation policy
- `~/ai/agents/projectmanagement/plane_agent/API.md` - document write endpoints already used
- `~/.claude/skills/plane-pm/SKILL.md` - cycle decision tree for agents
- `~/.claude/projects/-Users-home/memory/feedback_plane_cycle_automation.md` (new) - agent rule for when to recommend cycles

### Phase 1 - CLI write ops (foundation, ~2 hours)

Add three subcommands to `plane`:
1. `plane cycle new <project> <name> --start YYYY-MM-DD --end YYYY-MM-DD [--desc ...]` -> POST `/cycles/`
2. `plane cycle attach <cycle-ref> <issue-ref> [<issue-ref> ...]` -> POST `/cycles/<id>/cycle-issues/` with `{"issues": [uuid, ...]}`
3. `plane cycle detach <cycle-ref> <issue-ref>` -> DELETE `/cycles/<id>/cycle-issues/<issue-uuid>/`

Reuse existing `api()`, `paginate()`, `resolve_proj()`, `find_issue()`. Pattern matches existing `cmd_new`, `cmd_move`.

### Phase 2 - Recommendation engine (~3 hours)

New subcommand `plane cycle recommend [<project>]`:
- Pull all issues created in last 48h via `created_at` filter.
- Group by module + parent + label clusters.
- For each cluster >=3 issues, compute:
  - Total time estimate (sum of `human minutes` parsed from descriptions)
  - Active cycle overlap (theme keyword match)
  - Active cycle capacity
- Emit JSON or table: cluster_id, suggested_action (attach/create), target_cycle_name, target_dates, issue_refs.
- DOES NOT execute. Prints suggestion + ready-to-paste `plane cycle new` + `plane cycle attach` commands.

### Phase 3 - Agent rule (memory + skill)

- New memory file `feedback_plane_cycle_automation.md`:
  - When creating >=3 issues in same Plane batch, run `plane cycle recommend <project>` before end of turn.
  - Surface recommendation to user with one-line summary + ready-to-paste commands.
  - Never auto-execute cycle creation.
- Update `~/.claude/skills/plane-pm/SKILL.md` cycle section: link to recommend command + decision tree.

### Phase 4 - Apply to current batch (~10 min after Phase 1)

- Run `plane cycle new AGENT "OpenBao Hardening Week 1" --start 2026-05-19 --end 2026-05-25`
- Run `plane cycle attach AGENT-<new-cycle> INFRA-177 INFRA-187 AGENT-365 AGENT-356 AGENT-358 AGENT-366`
- Cycles in INFRA + DEVOPS skipped this week; week 2 may add them.

### Phase 5 - Optional GitHub bridge (deferred)

Out of scope for this plan but worth a separate ticket:
- Webhook listener that mirrors GH PR state to linked Plane issue (PR opened -> In Progress; merged -> Completed). Documented as manual discipline in SOP today.

---

## Verification

After Phase 1-4 execute:

1. `plane cycles AGENT` shows new "OpenBao Hardening Week 1" cycle with correct dates.
2. `plane sprint AGENT --json | jq` returns 6 issues attached.
3. Each of the 6 issues' detail shows cycle membership when fetched via API.
4. `plane cycle recommend AGENT` returns at minimum the OpenBao cluster suggestion (sanity-check it does not re-suggest cycle for issues already attached).
5. `~/.claude/projects/-Users-home/memory/MEMORY.md` index has new feedback memory entry.
6. End-of-turn agent behavior on next batch-create: recommendation surfaces without user prompt.

---

## Decisions needed before execute

- Cycle cadence preference: weekly (matches existing "Week of ..." cycles) or 2-week sprints (matches "Sprint 1") - **default to weekly** unless overridden
- Cycle naming convention: `<Module> Week N - YYYY-MM-DD` or freeform - **default to module+week**
- Recommendation auto-run cadence: every batch-create (verbose) or only when user asks (`plane cycle recommend`) - **default to user-on-demand**, agent surfaces a single one-line hint after batch creation

---

## Done / Open / Recommend

Done: PM stack mapped (GitHub native, Plane native, ours). Cycle theory + 5 industry heuristics captured. Current batch evaluated - module yes, full-batch cycle no. Recommendation engine designed. CLI gaps identified (no cycle write ops today). Decision tree for agent inference drafted.

Open: 3 cadence + naming + recommend-trigger defaults need confirmation. plane-pm-agent repo state (whether anyone else is mid-edit) unverified.

Recommend: Approve plan. Build Phase 1 (CLI write ops) first since it unblocks Phase 4 (current batch cycle). Defer Phase 5 (GitHub bridge) to its own plan.
