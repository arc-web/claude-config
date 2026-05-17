# Plan: Plane Workspace Gap Analysis & Recommendations

Date: 2026-05-16

## What we found (raw numbers)

| Project | Issues | Modules | Cycles | Labels | No Assignee | No Estimate |
|---------|--------|---------|--------|--------|-------------|-------------|
| INFRA   | 159    | 0       | 0      | 22     | 14.5%       | 80.5%       |
| AGENT   | 200    | 0       | 0 active | labels exist | 22%    | 50.5%       |
| ADS     | 48     | 0       | 0      | 14     | 89.6%       | 87.5%       |
| COMM    | 0      | 1 (planned, empty) | 0 | 0   | n/a         | n/a         |

---

## Critical problem: member roles are backwards

**Johan and Michael (the humans) are Guests. Claude Code and ZeroClaw are Admins.**

Guest role likely limits ability to: change issue states, assign work, create modules/cycles. This means Johan may not be able to action the tasks we just assigned him.

**Fix first:** Promote Johan + Michael to Member or Admin. Demote Claude Code + ZeroClaw to Member (they don't need admin).

---

## Gap 1: No modules anywhere

Modules are the missing layer between "project" and "individual task." Right now everything is a flat list. Modules should group tasks by feature area so you can see "how much auth work is left" vs "how much infra tooling work is left" without filtering.

### Recommended modules per project

**INFRA** (infrastructure tasks):
- `Authentication & Credentials` - OpenBao, 1Password, authentication_agent, api-keys. Tasks: INFRA-144, 145, 158, 159, 160, 161, 162, 143 (Plane Docker secrets)
- `Agent Platform` - MCP servers, zeroclaw, container sidecars, agent deployment. Tasks: zeroclaw migration tasks, MCP setup tasks
- `Tooling & Scripts` - arc-scripts, github-gang, desktop tooling. Tasks: arc-scripts updates, CLI tooling tasks

**AGENT** (agent development):
- `Google Workspace` - all agents touching Google APIs (Gmail, Drive, GTM, Analytics, Ads, Search Console, GMB, YouTube, Calendar). Tasks: AGENT-179, 180, 181 (GHL/Google SA/GA4 work)
- `Community & Discord` - discord_agent, community_ops, StackPack integrations. Tasks: COMM-adjacent tasks that leaked into AGENT
- `Business Intelligence` - reporting agents, model routing, accounting swarm

**ADS** (Google Ads work):
- `Foundation (P0)` - gads API suite core. Tasks: all issues labeled P0-foundation
- `Core Suite (P1)` - main ad management. Tasks: all issues labeled P1-suite
- `Utilities & Reporting (P2)` - secondary tooling. Tasks: all issues labeled P2-utilities

**COMM** (community operations):
- `Discord Bot` - charlie bot, arc bot, message ops
- `Plane Sync` - plane-discord-sync tool
- `StackPack` - already planned, stays

---

## Gap 2: No cycles (sprints) anywhere

Nothing is time-boxed. You can't answer "what ships this week?" without manually filtering by due date.

### Recommended cycle setup

Two-week cycles starting now. Same cadence across all active projects (INFRA, AGENT, ADS).

**Current cycle (2026-05-16 → 2026-05-30):**
- INFRA: INFRA-158, 162, 161 (auth PRs), INFRA-159 (stale path cleanup, after merges), INFRA-143 (Plane Docker secrets)
- AGENT: AGENT-179 (Google SA provision), AGENT-180 (GA4 API enable), AGENT-181 (GHL → OpenBao)
- ADS: current In Progress items (6 issues) + top-priority Todo items

**Next cycle (2026-05-30 → 2026-06-13):**
- INFRA: INFRA-160 (archive authentication_boss), INFRA-145 (OpenBao docs refresh)
- AGENT: whatever unblocked after current cycle

---

## Gap 3: Label inconsistency

Each project invented its own system. ADS uses `feature:name` + `P0/P1/P2`. INFRA uses `type:ops` + `infrastructure` + `agent:claudecode`. AGENT uses similar to INFRA. COMM has nothing.

### Recommended unified label taxonomy (cross-project)

**Who does the work:**
- `agent:claudecode` - Claude Code did/will do this
- `agent:zeroclaw` - ZeroClaw automated task
- `human` - requires human decision or click (merges, approvals, billing)
- `human:johan` - specifically Johan's action item

**What kind of work:**
- `type:ops` - operational/maintenance
- `type:feature` - new capability
- `type:bug` - something broken
- `type:research` - investigate before deciding
- `type:infra` - infrastructure change (replaces bare `infrastructure` label)

**Blockers:**
- `blocked:external` - waiting on third party
- `blocked:team` - waiting on another human
- `blocked:dependency` - waiting on another task

**Risk/cost:**
- `requires-budget-approval` - spend involved
- `cost-sensitive` - watch the bill

**Project-specific labels stay as-is** (ADS's `P0-foundation` etc. are fine - they're module-level tags).

**COMM needs all the standard labels created** - currently has zero.

---

## Gap 4: Estimates missing everywhere

INFRA: 80.5% of issues have no estimate. ADS: 87.5%. These numbers make sprint planning impossible.

### Recommended estimate scheme

1pt = ~30 min (agent does it, human clicks approve)
2pt = ~1 hr (rebase + verify + merge, or short research)
3pt = ~2 hr (new integration, moderate investigation)
5pt = ~half day (new feature, significant refactor)
8pt = ~full day (complex feature, architectural change)

**Populate estimates for:**
- All Needs Approval tasks (typically 1-2pt - just human action)
- All In Progress tasks (already scoped, estimate is known)
- All Todo tasks in current cycle

Backlog items can stay unestimated until they enter a cycle.

---

## Gap 5: COMM project is empty

COMM has 0 issues despite the discord_agent being actively developed and used.

### What should be in COMM

Tasks that belong in COMM (currently nowhere or misplaced in AGENT):
- Discord bot uptime / reliability
- plane-discord-sync maintenance and improvements
- StackPack community management workflows
- Workshop and event operations
- Engagement module work (daily wins, IT support, events)

---

## Gap 6: AGENT has 46.5% archived issues cluttering the view

200 issues with ~93 archived. The active backlog is probably ~60 real tasks. The noise makes it hard to see what's actually planned.

**Recommendation:** Don't delete - archiving is correct. But filter defaults should hide archived. Ensure the team view uses `exclude:archived` as default.

---

## Suggested execution order

1. Fix member roles (Johan + Michael → Member/Admin) - unblocks Johan from actioning tasks
2. Create modules in all 4 projects, assign existing issues to modules
3. Create current cycle (May 16-30) in INFRA, AGENT, ADS - pull in the right issues
4. Standardize labels - create missing ones in COMM, align naming in AGENT/INFRA
5. Bulk-estimate all Todo + Needs Approval issues in current cycle
6. Seed COMM with 5-10 real issues for active discord/plane-sync work

---

## What this doesn't cover

- Clients workspace (separate from todovibes) - not in scope here
- Individual issue cleanup (wrong labels, stale priorities) - separate audit
- Cycle retrospectives / velocity tracking - needs a few cycles of data first
