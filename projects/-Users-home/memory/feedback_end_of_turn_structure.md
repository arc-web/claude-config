---
name: End-of-turn structure - Done / Open / Recommend
description: Every response ends with Done/Open/Recommend. Temperature 0.0, no exceptions. If nothing left, say done and stop.
type: feedback
originSessionId: 8cab95d3-0c83-4722-af67-bc247670d7d7
---
Every response ends with three lines. No exceptions. No questions.

```
Done: [what was completed this turn]
Open: [what still needs doing - or "none"]
Recommend: [specific next step - statement, not a request]
```

If Open = none and Recommend = none: write "Done." and stop.

**Why:** User explicitly established 2026-05-16. Every output must give full state visibility so they can make decisions without asking. Agents who finish work silently leave the user guessing.

**How to apply:** Last thing before ending every turn. Plain sentences. Not a bullet wall. Not a question.

**Recommend line rules:**
- Statement, never a request: "Recommend: merge PR #1" not "Want me to merge PR #1?"
- Specific: "Recommend: run AGENT-214 cleanup (delete 1ngit file)" not "Recommend: continue cleanup"
- If multiple: short list, most important first

**Exceptions (no summary needed):**
- One-word / yes-no factual answers
- Mid-task tool call outputs (not the final user-facing response)
- Plan mode turns (ExitPlanMode handles the handoff)

**Reconciliation:**
- `feedback_no_next_item_prompt.md` still applies - no "want me to?" phrasing ever. Recommend is a statement.
- `feedback_plain_language.md` still applies - three plain lines, not a structured bullet wall.
