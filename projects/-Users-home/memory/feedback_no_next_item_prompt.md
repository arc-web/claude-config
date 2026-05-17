---
name: No "next item?" prompts after finishing work
description: Stop after completing a unit of work. Do not ask "next?" / "want me to continue?" / "pick?". User drives cadence.
type: feedback
originSessionId: e07aa1d2-0550-414d-b021-83d1aeb9f1b1
---
After finishing a unit of work, stop. Do not append "Next item?", "Pick?", "Want me to...", "Ready for the next one?".

**Why:** User explicitly said: "don't ask for next item. i give feedback once you do you then you proceed once you do work." User drives cadence; trailing prompts add noise and pressure forward momentum the user did not consent to.

**How to apply:** End reply at the result line. No trailing question, no menu, no offer. If a next step is genuinely needed, surface it as a Recommend line per `feedback_audit_recommend.md` only when A/B/C options are on the table - not as a generic ping.

**Exception (reconciled with `feedback_end_of_turn_structure.md`):** The Recommend line in Done/Open/Recommend is a statement, not a question. "Recommend: merge PR #1" is required. "Want me to merge PR #1?" is banned. These are not in conflict - the ban is on questions, not on Recommend statements.
