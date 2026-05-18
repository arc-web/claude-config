# Agentic Dev Plan - SOP Rollout

## Context

User pasted a master `/agentic-dev-plan` prompt - a senior-director-style SOP that converts any dev request (feature, bug, infra, docs) into a full execution plan covering Plane tasks, repo selection, branches, PRs, testing, staging, prod gates, rollback, and Plane closure. Asked how to make it applicable across every dev agent (local + GitHub).

Goal: one canonical SOP, all dev-capable agents reference it, auto-applies on dev intent, rollout tracked in Plane.

User selections in AskUserQuestion:
- Deploy shape: **Shared SOP doc + thin per-agent triggers**
- Trigger scope: **Auto-applies on any dev request**
- Scope: **Full SOP repo + rollout + Plane tracking**

## Trade-off flag (read before approving)

Explore agent recommended hosting the SOP as a single skill file inside the existing `arc-web/claude-skills` repo instead of creating a new `arc-web/agent-sops` repo. Reason: claude-skills already auto-commits, all Claude Code agents already pick it up, no new CI to maintain. New repo adds ceremony.

This plan honors the user's "Full SOP repo" choice but flags it. If user wants the leaner path, swap step 1 to "add `agentic-dev-plan` skill under claude-skills" and skip new repo creation entirely. Same SOP content, half the rollout work.

## Target agents (verified by Explore)

| Agent | Where prompt lives | Trigger style |
|-------|-------------------|---------------|
| Claude Code (local) | `~/.claude/CLAUDE.md` + skills | Slash command + intent-detect import in CLAUDE.md |
| Codex CLI | `~/.codex/AGENTS.md` + `instructions.md` | Reference link + intent-detect rule |
| Hermes (container) | `/docker/hermes-agent/` entrypoint, rebuild pending | Bake link into entrypoint init prompt |
| ZeroClaw (container) | VPS Alpha, Rust binary | Add to startup config / system prompt |
| github_agent (local) | `~/ai/agents/development/github_agent/github_agent_config.py` | Inject SOP ref into config |
| meta_review_agent (local) | `~/ai/agents/development/meta_review_agent/llm_delegation_config.json` | Reference link |

Not targeting: comms/ops agents (discord_agent, gmail_mgmt, supabase_agent, plane_agent) - they don't ship code.

## Plan

### Step 1 - Create canonical SOP repo

- New repo: `arc-web/agent-sops` (private, default branch `main`)
- Structure:
  ```
  agent-sops/
    README.md                          # repo purpose, version policy
    sops/
      agentic-dev-plan.md              # the user's pasted prompt, v1
    triggers/
      claude-code.md                   # how Claude Code agents pick it up
      codex.md                         # how Codex picks it up
      container-agents.md              # Hermes/ZeroClaw injection pattern
    CHANGELOG.md
  ```
- Version policy: semver on `sops/*.md`, breaking changes get major bump, all agents pin to a version or `main`
- Local clone path: `~/ai/tools/agent-sops/` (matches existing `~/ai/tools/ai/claude-skills/` pattern)

### Step 2 - Author `sops/agentic-dev-plan.md`

- Copy user's pasted prompt verbatim as v1.0
- Add front-matter: version, last-updated, trigger keywords (build/ship/deploy/fix/refactor/PR/merge/new-repo)
- Append "Tooling Verified" section with Explore findings: confirms `plane tree create`, `plane new --repo/--evidence/...`, all 7 projects exist in todovibes
- Add "Skill cross-references" pointing to existing `swarm-program`, `plane-pm`, `github-pr-flow` skills (DRY - those keep procedural depth, SOP just decision-trees)

### Step 3 - Author thin per-agent triggers

Each trigger file = ~30 lines, tells the specific agent:
- Where to fetch SOP (file path or git URL)
- What intents auto-invoke it (regex list of trigger phrases)
- How to skip for trivial work (typo, single-line, docs-only)
- Where Plane tasks land for that agent
- Attribution string for commits/Plane comments

`triggers/claude-code.md` is the reference implementation; others adapt.

### Step 4 - Wire Claude Code (local)

- Create `~/.claude/skills/agentic-dev-plan/SKILL.md`:
  - Frontmatter: name, description with all trigger phrases ("ship this", "build X", "fix the Y bug", "deploy", "open PR", "new feature")
  - Body: short - fetch + display `~/ai/tools/agent-sops/sops/agentic-dev-plan.md`, then run the output-format section against the current request
  - Auto-trigger: rely on description matching (no hook needed)
- Add ONE line to `~/.claude/CLAUDE.md` under domain rules table: "Any dev request (build/ship/deploy/fix/refactor/PR) | `~/.claude/skills/agentic-dev-plan/SKILL.md`"
- Commit + push claude-skills per always-on rule

### Step 5 - Wire Codex CLI

- Edit `~/.codex/AGENTS.md`: append a `## Agentic Dev Plan` section linking to `~/ai/tools/agent-sops/sops/agentic-dev-plan.md` with auto-invoke phrases
- No new files - Codex reads AGENTS.md every session

### Step 6 - Wire container agents (Hermes, ZeroClaw)

- Hermes is mid-rebuild (Dockerfile pending git/gh additions per inventory). Add SOP injection to that rebuild: entrypoint clones `agent-sops` repo to `/opt/agent-sops/`, sets `AGENTIC_DEV_PLAN_SOP=/opt/agent-sops/sops/agentic-dev-plan.md` env var, system prompt references it
- ZeroClaw: add same env var + system prompt reference via its config. Defer to ZeroClaw maintainer if config schema unclear (mark as Needs Approval child task)

### Step 7 - Wire local dev sub-agents

- `github_agent_config.py`: import SOP path, prepend to system prompt
- `meta_review_agent/llm_delegation_config.json`: add `sop_reference` field pointing to SOP path
- These are surgical edits, one line each

### Step 8 - Plane task tree

Create a parent + children under DEVOPS project (rollout work itself is delivery, not agent behavior):

- Parent: `Rollout | Multi-agent: Deploy agentic-dev-plan SOP across all dev agents`
- Children (in dependency order):
  1. Create `arc-web/agent-sops` repo + initial structure - Needs Approval (new repo gate)
  2. Author `sops/agentic-dev-plan.md` v1.0
  3. Author trigger docs (claude-code, codex, container-agents)
  4. Wire Claude Code skill + CLAUDE.md line
  5. Wire Codex AGENTS.md
  6. Wire Hermes (via rebuild) - Blocked-until-rebuild
  7. Wire ZeroClaw - Needs Approval (config touch)
  8. Wire github_agent + meta_review_agent
  9. End-to-end test: invoke a fake dev request on each agent, confirm SOP fires
  10. Document in `agent-sops/README.md` + close parent

Use `plane tree create` with markdown plan generated from this section.

### Step 9 - Verification

For each wired agent, run a contrived dev request and confirm:
- SOP triggers (output shows the required format sections)
- Plane parent task gets created
- Repo discovery step runs
- No production deploy without human approval prompt

## Critical files / paths

- New repo: `arc-web/agent-sops` (to be created, step 1)
- Local clone: `~/ai/tools/agent-sops/`
- Claude Code skill: `~/.claude/skills/agentic-dev-plan/SKILL.md`
- Claude Code rule: `~/.claude/CLAUDE.md` (one-line addition under domain rules table)
- Codex config: `~/.codex/AGENTS.md`
- Hermes: `/docker/hermes-agent/Dockerfile` + entrypoint (rebuild pending)
- ZeroClaw: VPS Alpha config (path TBD)
- github_agent: `~/ai/agents/development/github_agent/github_agent_config.py`
- meta_review_agent: `~/ai/agents/development/meta_review_agent/llm_delegation_config.json`

## Existing infra to reuse (no rebuild)

- `~/.claude/skills/swarm-program/SKILL.md` - already wraps `plane tree create`
- `~/.claude/skills/plane-pm/SKILL.md` - Plane API + state UUIDs
- `~/.claude/skills/github-pr-flow/SKILL.md` - PR + commit trailers + HITL merge gate
- `~/ai/agents/projectmanagement/plane_agent/SOP.md` - daily cadence rules
- `plane tree create/polish/status/verify/resume` CLI - all working
- `plane new --repo/--evidence/--next-step/--verify/--done` flags - all working

SOP references these, does not duplicate them.

## Open gates (human approval required)

- New repo creation (`arc-web/agent-sops`) - step 1
- ZeroClaw config edits - step 7
- Hermes rebuild trigger if blocking other work - step 6

## Verification (end-to-end)

1. `gh repo view arc-web/agent-sops` returns 200
2. From a fresh Claude Code session, type "I want to build a new analytics dashboard" - SOP should auto-fire and produce the required output format
3. From a Codex session, same test
4. `plane tree status <root-seq>` shows all rollout children Done
5. Spot-check Hermes after rebuild: SSH in, `echo $AGENTIC_DEV_PLAN_SOP` returns path
6. github_agent system prompt grep finds SOP reference
