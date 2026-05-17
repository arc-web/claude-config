# Claude Code Ops Reality Gate

## Context

Observed failure (live session):
- Task: "look up VPS and Hermes, full audit"
- Claude: called lean-ctx 20+ times, started with wrong host (alpha vs zeroclaw), never SSH'd
- User: "check outside your ctx memory" -> Claude called lean-ctx 7 MORE times

Root cause - three layers with no mechanical boundary:

| Layer | What it is | When to use |
|-------|-----------|-------------|
| **Memory** | `~/.claude/.../memory/*.md` | Historical facts, architecture decisions |
| **Cache** | `ctx_read` (local file reads) | Local code, local config, local docs |
| **Reality** | `ctx_shell('ssh zeroclaw ...')` or raw Bash SSH | Anything on VPS, containers, live APIs |

**Critical ground truth from lean-ctx docs:** `ctx_shell` IS live execution - it SSH's, runs docker, etc. and compresses actual output. NOT cached. The problem is Claude using `ctx_READ` on VPS paths instead of `ctx_SHELL` for live checks.

The audit sentinel pattern is the only proven mechanical enforcement. We extend it.

---

## Prerequisites

**Upgrade lean-ctx first:** currently on 3.4.2, latest is 3.4.7.

```bash
cargo install lean-ctx
```

3.4.5 added Agent Harness with 5 roles (coder/reviewer/debugger/ops/admin) + budget enforcement per role. `ops` role may restrict tool access appropriately for infra tasks - investigate after upgrade.

---

## Problem Decomposition

**Problem 1 - ctx_read on VPS paths = cached, not live**
- `ctx_read('/opt/hermes/config.yaml')` reads LOCAL cache, not VPS
- No error fires - lean-ctx returns something for most paths
- Fix: block `ctx_read` on VPS path patterns, require `ctx_shell('ssh ...')` instead

**Problem 2 - "Check reality" triggers more reads, not SSH**
- No hook intercepts live-check intent
- `ctx_shell` IS the right answer but Claude defaults to `ctx_read`
- Fix: infra sentinel forces at least one ctx_shell/SSH before turn ends

**Problem 3 - Credential auto-discovery never runs**
- Rules say: env -> 1P -> OpenBao -> SSH, never ask user
- Claude asked "do you have a Kimi key in OpenBao?"
- Fix: PreToolUse on AskUserQuestion blocks credential questions; Stop hook reads transcript to catch conversational asks

**Problem 4 - Wrong host cited from stale memory**
- Memory said alpha, reality is zeroclaw
- Memory was never verified live before being cited
- Fix: infra intent gate forces live check before any infra claim can close the turn

---

## What We're Building

Four hooks. One sentinel gate. Block format varies by event type (grounded in docs).

---

### Hook 1 - Infra Intent Detector (UserPromptSubmit)

**File:** `~/.claude/hooks/infra_intent.sh`

Scans incoming prompt for infra keywords. If detected, writes sentinel and clears log.

Keywords: `vps`, `zeroclaw`, `hermes`, `docker`, `container`, `openrouter`, `kimi api`, `ssh`, `deploy`, `server` (not `server-side rendering`), `agent` (when followed by `up`/`status`/`running`/`down`)

Sentinel: `~/.cache/infra-gate/active` (contains detected keywords list)
Clears: `~/.cache/infra-gate/live.log`

Block format for UserPromptSubmit (can block):
```json
{"decision": "block", "reason": "..."}
```
This hook does NOT block - it only sets the sentinel and exits 0.

---

### Hook 2 - VPS Read Blocker (PreToolUse on ctx_read)

**File:** `~/.claude/hooks/infra_vps_block.sh`

Intercepts `mcp__lean-ctx__ctx_read` calls. When sentinel active AND `live.log` empty:

Checks if the path argument contains VPS path patterns:
- `/opt/`, `/etc/openbao/`, `/root/`, `/home/ubuntu/`, `zeroclaw`

If match: DENY.

Block format for PreToolUse (requires hookSpecificOutput, NOT decision:block):
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "INFRA GATE: ctx_read on VPS path is cached, not live. Use ctx_shell('ssh zeroclaw cat /opt/...') instead."
  }
}
```

After first SSH logged to live.log, block lifts.

`ctx_shell` on VPS paths is NOT blocked - that IS live execution.

---

### Hook 3 - Live Check Logger (PostToolUse on Bash + ctx_shell)

**File:** `~/.claude/hooks/infra_log_bash.sh`

**PostToolUse CANNOT block.** This hook only writes to live.log.

When sentinel exists: appends to `~/.cache/infra-gate/live.log` if command qualifies as live:
- Raw Bash: contains `ssh zeroclaw`, `bao kv get`, `bao read`, `op item get`, `curl` to external host
- ctx_shell: contains `ssh zeroclaw`, `docker`, `bao`, `op item get`

Matcher covers both: `Bash|mcp__lean-ctx__ctx_shell`

Reads stdin JSON, extracts `tool_input.command` or `tool_input` string, runs pattern match, appends to log if qualifying.

---

### Hook 4 - Infra Stop Gate (Stop)

**File:** `~/.claude/hooks/infra_stop_gate.sh`

When sentinel active:
1. Reads `live.log`
2. If empty: block - "INFRA GATE: infra task with no live check. Run: ctx_shell('ssh zeroclaw docker ps') or ssh zeroclaw 'docker ps'"
3. If populated: allow, clear sentinel + log

Block format for Stop:
```json
{"decision": "block", "reason": "INFRA GATE: ..."}
```

Stop hook ALSO reads `transcript_path` (available in all hook input JSON) to scan last assistant message for credential question patterns:
- `do you have a`
- `is there a ... key`
- `what is the ... token`
- `have you set up`

If found: block with "CREDENTIAL GATE: question to user is banned. Discovery order: env -> 1P ARC -> OpenBao -> SSH filesystem. Run discovery."

This handles conversational credential asks (not tool-based).

---

### Hook 5 - Credential Question Tool Blocker (PreToolUse on AskUserQuestion)

**File:** `~/.claude/hooks/cred_question_gate.sh`

Intercepts `AskUserQuestion` tool. Reads `tool_input.question`. If contains credential keywords (`key`, `token`, `credential`, `secret`, `password`, `api key`, `bao`, `vault`): DENY.

Block format (PreToolUse):
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "CREDENTIAL GATE: discovery order is env -> 1P ARC (hl23px33remaz2xecl5ecvvaem) -> OpenBao -> SSH. Never ask user."
  }
}
```

---

## Hook Response Format Reference (Grounded)

| Event | Block format | Can block? |
|-------|-------------|-----------|
| UserPromptSubmit | `{"decision": "block", "reason": "..."}` | Yes |
| PreToolUse | `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "..."}}` | Yes |
| PostToolUse | Exit 2 only (JSON block ignored) | No (exit 2 = non-blocking error) |
| Stop | `{"decision": "block", "reason": "..."}` | Yes |

---

## Settings.json Changes

Append to existing hook arrays (do not replace):

```json
"UserPromptSubmit": [
  {"matcher": "*", "hooks": [{"type": "command", "command": "bash $HOME/.claude/hooks/infra_intent.sh"}]}
],
"PreToolUse": [
  {"matcher": "mcp__lean-ctx__ctx_read", "hooks": [{"type": "command", "command": "bash $HOME/.claude/hooks/infra_vps_block.sh"}]},
  {"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": "bash $HOME/.claude/hooks/cred_question_gate.sh"}]}
],
"PostToolUse": [
  {"matcher": "Bash|mcp__lean-ctx__ctx_shell", "hooks": [{"type": "command", "command": "bash $HOME/.claude/hooks/infra_log_bash.sh"}]}
],
"Stop": [
  {"matcher": "*", "hooks": [{"type": "command", "command": "bash $HOME/.claude/hooks/infra_stop_gate.sh"}]}
]
```

---

## Files

| File | Action |
|------|--------|
| `~/.cache/infra-gate/` | CREATE dir |
| `~/.claude/hooks/infra_intent.sh` | CREATE |
| `~/.claude/hooks/infra_vps_block.sh` | CREATE |
| `~/.claude/hooks/infra_log_bash.sh` | CREATE |
| `~/.claude/hooks/infra_stop_gate.sh` | CREATE |
| `~/.claude/hooks/cred_question_gate.sh` | CREATE |
| `~/.claude/settings.json` | MODIFY - append to existing arrays |
| lean-ctx binary | UPGRADE 3.4.2 -> 3.4.7 (cargo install lean-ctx) |

---

## Verification

End-to-end after build:

```bash
# Scenario A - infra task
claude
> check hermes container status

# Expected:
# UserPromptSubmit: sentinel written
# Claude tries ctx_read('/opt/hermes/...') -> DENIED (VPS path + empty live.log)
# Claude runs ctx_shell('ssh zeroclaw docker ps') -> logged to live.log
# Stop hook: live.log populated -> passes
```

```bash
# Scenario B - credential question via tool
# Claude tries AskUserQuestion("do you have a Kimi API key?")
# -> DENIED immediately
```

```bash
# Scenario C - conversational credential ask
# Claude writes "Do you have a Kimi key in OpenBao?" in response text
# Stop hook reads transcript_path JSONL, finds pattern in last assistant message
# -> blocks turn end
```

```bash
# Scenario D - non-infra task (no regression)
claude
> what's in my CLAUDE.md
# No infra keywords -> no sentinel -> all hooks pass through
```

Manual check after Scenario A:
```bash
cat ~/.cache/infra-gate/active    # keywords list
cat ~/.cache/infra-gate/live.log  # ssh commands logged
```
