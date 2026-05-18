# OpenBao Blind-Spot Plane Task Tree

## Context

User identified 35 blind spots across the OpenBao stack after a derailed Codex investigation and feedback to adopt per-task short-lived tokens. Need to map each blind spot to existing Plane work (link if real, ignore if duplicate) or to a NEW task, and lay out a proper parent/child tree so the work has one anchor. AGENT-225 "OpenBao Canonical Enforcement - Epic" was the prior anchor but is Cancelled with no successor, and the six phase tasks under it never had `parent` set in Plane - so the tree has to be rebuilt from scratch in a new epic, with references back to AGENT-225 for continuity, not revival.

## Mapping: blind spot → existing task or NEW

Notation: **EXIST** = link to that issue; **NEW** = create; **SUCCESS** = successor to cancelled/archived prior. State as of scan: AGENT-225/226/227/229/230/303 = Cancelled; INFRA-144 = Done; INFRA-145 = state unread (partial overlap, scope is migration cleanup not new pathway).

| # | Blind spot | Status | Notes |
|---|---|---|---|
| 1 | Per-task short-lived token layer | NEW | Core feedback ask. Zero coverage. |
| 2 | Live AppRole TTL ceiling audit | NEW | Distinct from INFRA-144 (that was sidecar hardening). |
| 3 | Pathway selection rule doc | NEW | Tunnel vs sidecar vs SSH client-routing doc. |
| 4 | Minter CLI + wrap_ttl handoff | NEW | |
| 5 | Prompt-injection blast-radius framing | NEW | Threat model parent. |
| 6 | arcbao docs - tunnel pathway | PARTIAL EXIST (INFRA-145) | INFRA-145 scope is migration cleanup; split out tunnel pathway as separate child. |
| 7 | Codex investigation postmortem | NEW | |
| 8 | AGENT-225 cancellation reason | EXIST (AGENT-225) | Read comments, capture rationale. |
| 9 | Live epic to anchor everything | NEW | This plan creates it. |
| 10 | Subtask linkage process | NEW (process) | CLI parent-set verify, then backfill. |
| 11 | `explicit_max_ttl=0` on AppRole tokens | NEW | Under hardening sub-epic. |
| 12 | Orphan-token strategy | NEW | |
| 13 | `num_uses` limits | NEW | |
| 14 | Response wrapping (`wrap_ttl`) | NEW | |
| 15 | Per-secret policy granularity | NEW | |
| 16 | Revoke-on-exit hook | NEW | |
| 17 | CF Tunnel access policy on `vault.aibrainbuilders.com` | NEW | |
| 18 | AppRole on-disk single-factor (`/etc/openbao/<agent>/`) | NEW | |
| 19 | 1P bootstrap creds rotation schedule | NEW | |
| 20 | GH Actions OIDC trust (replace secret-id in GH Secrets) | NEW | |
| 21 | 1P ↔ OpenBao drift detector | SUCCESS (AGENT-230 Cancelled / DEVOPS-14 Phase F) | Revive scope under new epic. |
| 22 | AppRole login-failure alert | NEW | |
| 23 | OpenBao audit-device enable + review cadence | NEW | |
| 24 | Token-creation rate ceiling | NEW | |
| 25 | Revocation playbook | NEW | |
| 26 | OpenBao Raft backup + restore test | NEW | |
| 27 | Tunnel SPOF mitigation | NEW | |
| 28 | cloudflared upgrade 2026.3.0 → 2026.5.0 | NEW (small) | |
| 29 | `agent_credential_map.md` staleness refresh | NEW | Memory file, but task to refresh + verify live. |
| 30 | TTL value rationale in setup.md | FOLDED into #6 | |
| 31 | Threat model doc | NEW | |
| 32 | OpenBao-down runbook | NEW | |
| 33 | Codex "SOP-first" memory lesson | NEW (process) | Memory write, but tracked as task. |
| 34 | RTK wrapper compound-predicate fix | NEW (tool fix, separate repo) | |
| 35 | Default `.rgignore` for JSONL/node_modules | NEW (tool fix) | |

**Net: 31 NEW tasks + 1 new live epic + 2 successor links + 1 investigative read of AGENT-225.**

## Proposed Plane tree

Workspace: `todovibes`. Project: `AGENT` (Internal Ops). All children get `parent` set to the new epic via Plane API.

```
EPIC (NEW): OpenBao per-task token layer + pathway hardening + Codex investigation hygiene
│   Reference: supersedes Cancelled AGENT-225. Do not revive 225 - link in description.
│
├── SUB-EPIC A: Per-task token layer
│   ├── A1 Design task-scoped policies (task-plane-read, task-discord-post, task-google-oauth-bootstrap, ...)
│   ├── A2 Token roles under auth/token/roles/agent-task-* (short ttl, explicit_max_ttl, num_uses, orphan)
│   ├── A3 Minter CLI under ~/ai/arcbao/bin/ - mints + wraps (wrap_ttl=60s)
│   ├── A4 Task wrapper: unwrap → run → revoke-self on exit
│   ├── A5 Pilot: one read-only task (Plane read or Discord sync health probe)
│   └── A6 Migrate writer tasks after pilot pass
│
├── SUB-EPIC B: AppRole hardening (long-running services)
│   ├── B1 Read-only live TTL audit per role (bao read auth/approle/role/<role>) - record current ceilings
│   ├── B2 Set positive explicit_max_ttl + secret_id_ttl per service role
│   ├── B3 Add num_uses ceiling where workload bounded
│   ├── B4 secret_id rotation schedule
│   └── B5 On-disk perms review: /etc/openbao/<agent>/ (already 600; document + alert on drift)
│
├── SUB-EPIC C: Pathway + docs
│   ├── C1 Pathway selection rule doc (which client uses tunnel vs sidecar vs SSH, why)
│   ├── C2 Update ~/ai/arcbao/docs/architecture.md - add tunnel pathway section
│   ├── C3 New ~/ai/arcbao/docs/pathways.md
│   ├── C4 Refresh ~/.claude/projects/-Users-home/memory/agent_credential_map.md (verify live first)
│   ├── C5 Threat model doc ~/ai/arcbao/docs/threat-model.md (prompt-injection, single-factor on disk, tunnel SPOF)
│   ├── C6 OpenBao-down runbook ~/ai/arcbao/docs/runbook-down.md
│   └── C7 Link in to INFRA-145 to avoid duplicate doc work
│
├── SUB-EPIC D: Security posture
│   ├── D1 Verify CF Access policy on vault.aibrainbuilders.com (read-only check)
│   ├── D2 GitHub OIDC trust relationship → replace secret-id in GH Secrets
│   ├── D3 1P bootstrap AppRole creds rotation schedule + alert on age > N days
│   ├── D4 Enable OpenBao audit device, define review cadence
│   └── D5 Token-creation rate ceiling
│
├── SUB-EPIC E: Operational resilience
│   ├── E1 1P ↔ OpenBao drift detector (successor to Cancelled AGENT-230 / DEVOPS-14)
│   ├── E2 AppRole login-failure alerting (prompt-injection signal)
│   ├── E3 Revocation playbook (compromised AppRole → revoke + rotate steps)
│   ├── E4 OpenBao Raft backup + restore test
│   ├── E5 Tunnel SPOF mitigation (secondary tunnel or fallback path)
│   └── E6 cloudflared upgrade 2026.3.0 → 2026.5.0
│
└── SUB-EPIC F: Codex / research hygiene
    ├── F1 Codex investigation postmortem doc (wrong-pathway anchor, search pollution, template vs live)
    ├── F2 RTK wrapper - compound find predicates (separate repo issue)
    ├── F3 Default .rgignore for JSONL/node_modules/.cache (tool fix)
    ├── F4 Read AGENT-225 cancellation comment, capture rationale
    └── F5 Memory rule: SOP-first before broad search on OpenBao topics
```

**Total: 1 epic + 6 sub-epics + 33 leaf tasks = 40 issues.** Some leaves may collapse after AGENT-225 read (F4).

## Critical files referenced (no edits in plan mode)

- `~/ai/arcbao/docs/architecture.md` - tunnel pathway gap
- `~/ai/arcbao/docs/setup.md` - TTL guidance
- `~/ai/arcbao/templates/agent.hcl`, `policy-example.hcl` - template config
- `~/ai/agents/projectmanagement/plane_agent/plane` - CLI parent-set capability (verify)
- `~/ai/agents/projectmanagement/plane_agent/API.md` - parent field usage
- `~/.claude/projects/-Users-home/memory/agent_credential_map.md` - 2026-04-28, likely stale
- `~/ai/agents/development/codebase_helper/.cache/transient-previews/openbao-sop/docs/index.md` - canonical SOP that Codex skipped

## Existing tasks to reference (link, not duplicate)

- AGENT-225 (Cancelled, Epic) - read cancellation comment first
- AGENT-230 / DEVOPS-14 (Phase F credsync, Cancelled) - drift detector successor link
- AGENT-227 / DEVOPS-12 (Phase C skill patches, Cancelled) - reference if any skill repatch needed
- INFRA-144 (sidecar hardening, Done) - prior art for B sub-epic
- INFRA-145 (doc refresh, open) - coordinate to avoid duplicate doc PRs
- AGENT-322 (team access + Plane-GitHub bridge rebuild, Completed) - reference

## Verification

After execution (not in this plan):

1. `PLANE_WORKSPACE=todovibes plane --json issues AGENT > /tmp/agent_after.json` then assert new epic exists with all 6 sub-epic `parent` UUIDs pointing to it.
2. `plane issue AGENT-<epic_seq>` shows sub-epic count = 6.
3. Each leaf task has `parent` set to its sub-epic (verify via `--json` dump and python).
4. Description on each task includes handoff prompt per memory rule `feedback_plane_task_fields.md`: context / repo / last state / next action / run command.
5. Comment trailer on every comment matches `— [Agent: claude-opus-4-7 via Claude Code | YYYY-MM-DD]`.
6. AGENT-225 has a new comment linking to the new epic UUID.
7. Spot-check 3 leaf tasks have non-default time estimates (human minutes, per memory rule `feedback_plane_task_fields.md`).

## Decisions (confirmed)

- **Project routing: split.** Epic in AGENT (Internal Ops). Sub-epic B (AppRole hardening) → INFRA. Sub-epics E1/E4/E5/E6 → INFRA. Sub-epic F2 (RTK fix) + F3 (.rgignore) → DEVOPS. Everything else stays in AGENT.
- **Time estimates: per leaf.** Human minutes per memory rule `feedback_plane_task_fields.md` (scope/deploy/review time, not agent wall-clock). 33 leaves get estimates.
- **Single-source.** One canonical issue per task in its chosen project. Other projects get a one-line reference comment when relevant. No duplicate issues.
- **Open tree in parallel with AGENT-225 read.** Build now; F4 captures cancellation rationale separately. If 225 reason was "superseded by X" and X is live, F4 may collapse scope after the fact.

## Cross-project routing detail

| Sub-epic | Project | Reason |
|---|---|---|
| EPIC anchor | AGENT | Internal Ops owns cross-cutting initiatives |
| A (per-task tokens) | AGENT | Agent-runtime concern |
| B (AppRole hardening) | INFRA | Infrastructure / live role config |
| C (Pathway + docs) | AGENT | Docs + memory live in agent workflow |
| D (Security posture) | AGENT | Cross-cutting; D1 verify could go INFRA, keep grouped for now |
| E1 (1P↔OpenBao drift) | INFRA | Successor to DEVOPS-14 / AGENT-230 - INFRA closer to credsync |
| E2 (login-fail alert) | AGENT | Alerting flows through agents |
| E3 (revocation playbook) | AGENT | Doc |
| E4 (Raft backup test) | INFRA | Infra |
| E5 (tunnel SPOF) | INFRA | Infra |
| E6 (cloudflared upgrade) | INFRA | Infra |
| F1 (Codex postmortem) | AGENT | Agent process |
| F2 (RTK fix) | DEVOPS | Tool repo |
| F3 (.rgignore default) | DEVOPS | Tool config |
| F4 (read 225 comment) | AGENT | Investigative |
| F5 (memory rule) | AGENT | Memory write |

**Module assignment open** - to be decided at execute time; suggest using existing OpenBao-related modules where present, else create one new module "OpenBao Hardening" in each of AGENT/INFRA/DEVOPS.

## Execution order (when approved)

1. Verify Plane CLI parent-set capability (read `~/ai/agents/projectmanagement/plane_agent/API.md` + CLI source). If CLI lacks it, use direct API PATCH on `parent` field.
2. Create EPIC in AGENT with description that links to AGENT-225 (Cancelled) and references the 35-blind-spot scan.
3. Create 6 sub-epics, set `parent` = EPIC UUID, route to AGENT/INFRA/DEVOPS per routing table.
4. Create 33 leaf tasks, set `parent` = matching sub-epic UUID. All fields populated: name, state=Backlog, description with handoff prompt, module, time estimate (human minutes per memory rule).
5. Post one comment on AGENT-225 with link to new epic UUID, attribution trailer.
6. Run F4 in parallel: read AGENT-225 comments, capture cancellation rationale; if scope-collapsing, mark affected leaves Cancelled with link to surviving work.
7. Verify with the 7 checks in the Verification section above.

## Done / Open / Recommend

Done: 35 blind spots mapped (31 NEW, 2 successor, 1 partial-overlap, 1 investigative). Tree drafted: 1 epic + 6 sub-epics + 33 leaves = 40 Plane issues. Routing confirmed: split AGENT/INFRA/DEVOPS. Per-leaf time estimates. Single-source. AGENT-225 read in parallel.

Open: Plane CLI parent-set exposure unverified (API supports it). Module names per project unconfirmed - default to new "OpenBao Hardening" module if no existing match.

Recommend: Approve plan. On execute, start with CLI capability check (step 1) before creating any issues, since wrong parent linkage = 40 manual fix-ups.
