# Chat Learnings Propagation Plan

## Context

This session established several new rules, patterns, and capabilities that are only partially propagated. The Plane task discipline rule is in CLAUDE.md and memory but not in ZeroClaw's SOUL.md or the Codex/Claude Code collaboration protocol. A new `cf-deploy worker deploy` pattern exists but has no skill. Plane API PATCH patterns and the lean-ctx shell function failure were learned but not written down. This plan closes all those gaps.

---

## 1. New skill: `plane-pm`

**File:** `~/.claude/skills/plane-pm/SKILL.md`

What it covers:
- Plane API quick workflow (create issue, update issue, query issues)
- AGENT project UUID + state IDs (Todo, Done, In Progress, Blocked)
- Python subprocess pattern for multi-issue operations (shell functions fail with lean-ctx hook)
- Rate limit awareness: 429 backoff with exponential retry
- PATCH `/issues/<uuid>/` for updates (title, description_html, state)
- UUID lookup: GET issues, extract `.id` field (sequence_id is display only, not URL param)
- Key retrieval: `op item get x7qhfdaos76fcymuztjjscmrpa --vault Zeroclaw --reveal --fields credential`
- `User-Agent: plane-cli/1.0` required (Cloudflare blocks default UA)

Add to CLAUDE.md domain rules table:
```
| Plane task operations (create, update, query via API) | `~/.claude/skills/plane-pm/SKILL.md` |
```

Auto-commit to arc-web/claude-skills after creating.

---

## 2. Update `web-worker` skill

**File:** `~/.claude/skills/web-worker/SKILL.md`

Add one block near the top under deploy steps:

```
## Deploying

Use `cf-deploy worker deploy <path>` — NOT wrangler directly.
`cf-deploy` handles 1Password credentials automatically.
```

For agent-repo workers (discord_agent etc.): `cd workers && ./deploy.sh` which calls cf-deploy.

Auto-commit to arc-web/claude-skills after editing.

---

## 3. Update `reference_plane_api.md` memory

**File:** `~/.claude/projects/-Users-home/memory/reference_plane_api.md`

Add section:

```
**PATCH (update issue):**
- Endpoint: `PATCH /issues/<uuid>/` (use `.id` field, NOT sequence_id)
- Body: any subset of `{name, description_html, state}`
- UUID lookup: GET issues list, extract `.id` per result

**AGENT project state IDs (todovibes):**
- Todo: c0528a48-cbb1-44e5-9f09-1e8fc566bb56
- In Progress: bdb50dbe-2fe8-4f65-848c-1439cfa64ad5
- Done: 9bafcd6c-f951-4b88-8c49-f8ef2875bc9a
- Blocked: ce62803d-b9cc-4214-b99d-823d8afff7c8

**Multi-issue Python pattern (shell functions fail with lean-ctx hook):**
```python
import subprocess, json
key = subprocess.check_output(['op','item','get','x7qhfdaos76fcymuztjjscmrpa',
    '--vault','Zeroclaw','--reveal','--fields','credential'], text=True).strip()
headers = ['-H',f'X-API-Key: {key}','-H','User-Agent: plane-cli/1.0','-H','Content-Type: application/json']
url = 'https://arc.todovibes.com/api/v1/workspaces/todovibes/projects/<UUID>/issues/'
r = subprocess.check_output(['curl','-s','-X','POST',*headers,'-d',json.dumps(payload),url], text=True)
```
Run via: `/opt/homebrew/bin/python3 -c "..."` with `dangerouslyDisableSandbox: true`
```

---

## 4. Update `feedback_lean_ctx_shell_sandbox.md` memory

**File:** `~/.claude/projects/-Users-home/memory/feedback_lean_ctx_shell_sandbox.md`

Add one bullet:

```
- **Shell functions break**: defining `ci() { curl ... }` and calling it fails — lean-ctx hook intercepts and injects `_lc` causing `command not found`. Use Python subprocess directly instead (see reference_plane_api.md for pattern).
```

---

## 5. Update ZeroClaw SOUL.md

**File:** `/Users/home/ai/infra/zeroclaw-workspace/SOUL.md`

Add to the **Guardrails** section (after "Always log to Discord with timestamp + commit hash"):

```
- **Plane tasks**: create a Plane task before starting any meaningful unit of work (feature, fix, deploy, migration). Update state to In Progress when starting, Done when complete, Blocked if stuck. Workspace: todovibes, project AGENT (ID: 0e399778-93d9-4a95-ba2f-755990dd69bc). API key at OpenBao secret/shared/plane-api-key.
```

After editing: commit SOUL.md to zeroclaw-workspace repo (if it is a git repo), or note that Hermes must pick up the change via its read-only mount.

---

## 6. Update WalkieTalkie AGENTS.md

**File:** `/Users/home/ai/agents/development/infrastructure_agent/agents/walkietalkie_agent/AGENTS.md`

Add to **Core operating rules** section:

```
- **Plane tasks**: Codex and Claude Code both create + update Plane tasks for work done in a session. Create at start, update to Done on completion. AGENT project in todovibes workspace. No silent work.
```

---

## Verification

1. `plane-pm` skill created → `claude skills list` shows it; auto-committed to arc-web/claude-skills
2. CLAUDE.md domain table has `plane-pm` row → visible in `~/.claude/CLAUDE.md`
3. SOUL.md updated → grep for "Plane tasks" in SOUL.md; ZeroClaw picks up on next container restart
4. `reference_plane_api.md` has state IDs → future API calls use correct UUIDs without lookup
5. `feedback_lean_ctx_shell_sandbox.md` has shell function note → no more wasted `ci()` attempts

---

## Files to edit (in order)

1. `~/.claude/skills/plane-pm/SKILL.md` — create new
2. `~/.claude/skills/web-worker/SKILL.md` — add cf-deploy note
3. `~/.claude/CLAUDE.md` — add plane-pm to domain rules table
4. `~/.claude/projects/-Users-home/memory/reference_plane_api.md` — add PATCH + state IDs + Python pattern
5. `~/.claude/projects/-Users-home/memory/feedback_lean_ctx_shell_sandbox.md` — add shell function note
6. `/Users/home/ai/infra/zeroclaw-workspace/SOUL.md` — add Plane task guardrail
7. `/Users/home/ai/agents/development/infrastructure_agent/agents/walkietalkie_agent/AGENTS.md` — add Plane task rule
