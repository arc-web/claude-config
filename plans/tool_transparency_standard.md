# Tool Transparency Standard - Analysis + Implementation

## Context

**The problem:** Agents use tools but humans can't tell what was checked, what it returned, or what to do with it.

An agent saying "the board shows two blockers" is unverifiable. An agent saying "I ran `plane standup` - here's what it returned, here's what matters, here's your decision" is transparent and actionable. The difference is trust. Without source attribution on tool output, humans either re-check manually or act on outputs they can't trace.

**Why this matters now:** The plane CLI now has `standup`, `mine`, `intake` - tools designed to surface state to agents and humans. But there's no standard for how an agent presents that output. The SOP covers how agents work tasks. It doesn't cover how agents communicate tool use or shape output for human decisions.

**Scope of this work:**
- Write the analysis as a memory rule (permanent, applies to all agents + tools)
- Apply it concretely to `plane standup` as the first implementation
- Update SOP.md with the session-start standup protocol and output format

---

## The Gap (from feedback analysis)

Three things the user's feedback establishes:

1. **Response format rule** (`rules_response_format.md`): Lead with a plain-English sentence. Bullets for details. Output must be directly usable - name things directly, say the actual thing.

2. **Plain language rule** (`feedback_communication_plain.md`): Translate tool mechanics. User cares about outcome, not mechanism. But this is NOT "hide what you did" - it's "explain it clearly."

3. **SOP agent review format** (`SOP.md` section 3): Agent returns: task ref, state, summary, evidence checked, what it did, blockers, next action. Tool output is evidence. It must be cited.

The gap: when an agent uses a tool proactively (standup, mine, sprint), there's no matching standard for: declare it, surface the finding, connect it to a decision.

---

## The Standard (applies to all tools, all agents)

Every proactive tool use follows this 3-part format:

```
[Tool declaration]: I ran `<command>`.
[Finding]: What it returned - the actual data, not paraphrased.
[Interpretation]: What this means + what the human can decide based on it.
```

Rules:
- Never hide the tool name. "The board shows X" is banned - say which command produced it.
- Don't dump raw terminal output - shape it for reading. Remove formatting noise, keep the data.
- Every finding ends with a "so what" - one sentence on what the human should do, or "nothing urgent."
- If the tool returns nothing actionable, say that explicitly ("standup clean - no blockers, no stale in-progress").

---

## Standup: Concrete Spec

### When agents run standup proactively

Trigger: session start before picking up sprint work, or when user asks about current state.

### What the agent says (not raw terminal dump)

```
Ran `plane standup`:

Done in last 24h:
- AGENT-330: Centralize Plane system

In progress:
- INFRA-42: Docker restart loop

Blockers:
- (none)

Sprint is clean. No blockers, one in-progress to check before starting new work.
```

vs what NOT to do (raw dump):
```
Yesterday (completed in last 24h):
  AGENT-330  Centralize Plane system
Today (in progress):
  INFRA-42  Docker restart loop
Blockers:
  (none)
```

The raw dump is machine output. The shaped version is a briefing.

### Human interaction with standup output

The human reads it and makes one decision from a short list:
- Pick up the in-progress item
- Unblock a blocker
- Start new work (if sprint is clean)
- Reprioritize (if something is overdue)

The agent's job is to surface which of those applies. Not just report data.

---

## Deliverables

### 1. New memory file: `rules_tool_transparency.md`

General rule. Applies to all agents (Claude Code, Codex, ZeroClaw) and all tools (plane CLI, discord_agent, gh CLI, browser).

Content:
- The 3-part format (declaration + finding + interpretation)
- The "so what" requirement
- Ban on "the board shows" without citing the command
- Applies to proactive tool use (agent-initiated), not just tool use in response to a direct command

### 2. SOP.md additions

Two new sections:

**"Session-start protocol"** (under Daily section):
```
Agent picking up sprint work runs standup first:
  plane standup
Returns it shaped (not raw) with a recommendation on what to work next.
```

**"Tool transparency"** (new section, before Hard rules):
The 3-part format, the standup output spec, and the ban on tool-output-without-interpretation.

### 3. MEMORY.md index update

Add `rules_tool_transparency.md` to the Rules section.

---

## Files to modify

| File | Change |
|------|--------|
| `~/ai/agents/projectmanagement/plane_agent/SOP.md` | Add session-start protocol + tool transparency section |
| `~/.claude/projects/-Users-home/memory/rules_tool_transparency.md` | NEW - general rule for all tools/agents |
| `~/.claude/projects/-Users-home/memory/MEMORY.md` | Add index entry for new rule file |

Skills commit: not required (SOP.md is in plane_agent repo, not claude-skills).
Memory files: local only (no remote push needed per `feedback_memory_local_only.md`).

---

## Verification

After implementation:
1. SOP.md contains "Tool transparency" section with the 3-part format
2. SOP.md contains "Session-start protocol" under Daily
3. `rules_tool_transparency.md` exists with type=feedback and correct content
4. MEMORY.md index has the new entry
5. Manual test: ask any agent to run standup and check that the output follows the shaped format, not raw terminal dump
