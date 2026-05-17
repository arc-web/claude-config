# End-of-Turn Structure Rule

## Context

Every response currently ends whenever the work is done, with no consistent summary of state or next steps. The user expects every turn to close with three things: what was done, what's still open, and a recommendation. This is temperature 0.0 - no exceptions. If there's nothing left, say "done" and stop. The existing rules conflict with this: `feedback_no_next_item_prompt.md` says stop after work and don't prompt forward; `feedback_plain_language.md` says no structured recap bullets. Both need to be reconciled with the new rule - not deleted, but updated to clarify the distinction between "no trailing questions" (preserved) and "always summarize state" (new).

---

## Rule (exact text to enforce)

**Every response ends with:**

```
Done: [what was completed this turn - one line or short list]
Open: [what still needs doing - explicit list, or "none"]
Recommend: [specific next step(s) - actionable, not a question]
```

If open = none and recommend = none: say "done" and stop. No trailing question. No "want me to?". Just the three lines - then silence.

Exceptions: short factual answers (one-word lookups, yes/no), mid-task tool calls, plan mode turns. Not every tool call needs it - only the final user-facing response per turn.

---

## Reconciliation with existing rules

- `feedback_no_next_item_prompt.md` - preserved: still no "want me to?" / "next?" questions. The Recommend line is a statement, not a request. "Recommend: merge PR #1" not "Want me to merge PR #1?".
- `feedback_plain_language.md` - preserved: the three lines are plain sentences, not bullet walls. Short and direct.
- `feedback_response_structure.md` - layer 3 becomes the Recommend line. No longer a question.

---

## Files to change (in order)

1. **Create** `~/.claude/projects/-Users-home/memory/feedback_end_of_turn_structure.md`
   - New feedback memory with the exact rule + reconciliation notes

2. **Update** `~/.claude/projects/-Users-home/memory/feedback_no_next_item_prompt.md`
   - Add: "Exception: Recommend line is required - it is a statement not a question. 'Recommend: X' is mandatory; 'Want me to X?' is banned."

3. **Update** `~/.claude/projects/-Users-home/memory/feedback_plain_language.md`
   - Add: "Exception: Done/Open/Recommend summary is required at end of every turn. Three plain lines, not a bullet wall."

4. **Update** `~/.claude/CLAUDE.md` always-on section
   - Add rule immediately after the no-em-dash rule (first in list = highest visibility):
   ```
   - **End-of-turn structure (temp 0.0).** Every response ends: Done / Open / Recommend. If nothing left, say "done" and stop. No trailing questions. Recommend line is a statement not a request. See `feedback_end_of_turn_structure.md`.
   ```

5. **Update** `~/.claude/projects/-Users-home/memory/MEMORY.md`
   - Add index entry for `feedback_end_of_turn_structure.md`

---

## Verification

After implementation: the next response after this plan is approved must itself close with Done / Open / Recommend. That's the test.

---

## Files to modify

- `~/.claude/CLAUDE.md`
- `~/.claude/projects/-Users-home/memory/feedback_end_of_turn_structure.md` (create)
- `~/.claude/projects/-Users-home/memory/feedback_no_next_item_prompt.md`
- `~/.claude/projects/-Users-home/memory/feedback_plain_language.md`
- `~/.claude/projects/-Users-home/memory/MEMORY.md`
