---
name: Tool transparency - declare, surface, interpret
description: When agents use tools proactively, they must name the tool, show the finding, and say what the human should do with it. Applies to all agents and all tools.
type: feedback
originSessionId: a22d15ea-e482-4623-9066-f6110ae081d1
---
# Tool transparency - 3-part format

Every proactive tool use (agent-initiated, not directly commanded) follows this format:

```
[Declaration]: I ran `<command>`.
[Finding]: What it returned - the actual data, shaped for reading.
[Interpretation]: What this means and what the human can decide based on it.
```

**Why:** "The board shows two blockers" is unverifiable. "I ran `plane standup` - here's what it returned" is traceable and trustworthy. Humans can't act on outputs they can't source.

## Rules

- Always name the tool. Never say "the board shows" or "Discord says" without citing the command.
- Don't dump raw terminal output. Shape it: remove formatting noise, keep the data, make it readable.
- Every finding ends with a "so what" - one sentence on what the human should do, or "nothing urgent."
- If the tool returns nothing actionable, say that explicitly. Example: "standup clean - no blockers, sprint is moving."

## What NOT to do

Raw terminal dump (banned for proactive use):
```
Yesterday (completed in last 24h):
  AGENT-330  Centralize Plane system
Today (in progress):
  INFRA-42  Docker restart loop
Blockers:
  (none)
```

## Standup example (correct format)

```
Ran `plane standup`:

Done in last 24h:
- AGENT-330: Centralize Plane system

In progress:
- INFRA-42: Docker restart loop

Blockers: none

Sprint is clean. INFRA-42 is the only active item - check before starting new work.
```

## Applies to

All agents: Claude Code, Codex, ZeroClaw, any future agent.
All tools: plane CLI, discord_agent, gh CLI, arc-browser, any external API call.

## When this triggers

- Agent uses a tool without being explicitly told to (session-start standup, proactive sprint check, etc.)
- Agent uses a tool as part of a workflow step and the result affects human decisions

## When this does NOT apply

- Agent uses a tool because the user directly asked for it ("run standup") - still shape the output, but no declaration needed since the user already knows what was run
