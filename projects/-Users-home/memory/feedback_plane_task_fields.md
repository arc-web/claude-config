---
name: Plane task fields - all required, time in human minutes
description: All Plane tasks must have all fields populated; time estimates reflect human time spent, not agent execution time
type: feedback
originSessionId: 9ae3ac9b-afd9-492d-a109-07c3b8188200
---
All Plane tasks must have every field populated - not just name and state.

**Required fields on every task:**
- Name (clear, action-oriented)
- State (Todo/In Progress/Done/Blocked)
- Description (what, why, acceptance criteria)
- Module (client or area assignment)
- Time estimate

**Why:** Humans are the ones tracking time and reviewing tasks. Incomplete tasks are noise.

**Time estimate rule - human minutes, not agent time:**
Humans deploy agents in minutes. The agent then runs parallel sub-agents for 20 minutes autonomously. Log the HUMAN time (the minutes it took to scope, deploy, review, and approve) - not the wall-clock agent execution time.

Example: human spends 5 minutes reviewing a plan and saying "go" → agent runs 20 minutes of parallel work → log 5 minutes on the task, not 20.

**How to apply:** When creating any Plane task, fill all fields before saving. When estimating, ask "how many human minutes did this take to direct and review?" not "how long did the agent run?"

---

## Handoff prompt (required on every task)

Every task must include a handoff prompt in the description - a ready-to-paste block another agent or team member can use to pick up exactly where the last person left off.

**Format:**
```
## Handoff prompt
Context: [what this task is, what's been done, what's left]
Repo/path: [where the code or files live]
Last state: [what was last completed or changed]
Next action: [exact first step to continue]
Run: [any command needed to get oriented - e.g. cd path && git log --oneline -5]
```

If a task is missing its handoff prompt: analyze the task name, description, and comments, then add the prompt. Do not skip this.

## Last-updated attribution (required on every comment and update)

Every task comment or description update must end with an attribution line:

```
— [Agent: claude-sonnet-4-6 via Claude Code | 2026-05-16] 
— [Human: [name] | 2026-05-16]
```

This makes it clear who did what and when, for both agents and humans reviewing later.
