---
name: Plan files - rename harness slug immediately
description: Treat plan-mode pre-filled slug path as placeholder, never write a plan to a random three-word slug filename
type: feedback
originSessionId: 435446a2-2ce7-4c11-ade3-cef3d7bf0461
---
Harness opens plan mode with a pre-filled path like `~/.claude/plans/toasty-zooming-duckling.md`. That is a placeholder, not a directive. Always write the plan to a descriptive snake_case/kebab-case filename describing the work (e.g. `openbao_diag_oneshot.md`, `fix_plan_naming_rule.md`).

**Why:** Slug filenames are seen as failure - nobody names files that way, they look auto-generated and untraceable. User has corrected this multiple times across sessions (2026-04-27 incidents on `toasty-zooming-duckling`, prior on `flickering-cuddling-lecun`, `mossy-wondering-clarke`). Root cause of repeated failure: model treats system-reminder pre-filled path as authoritative instruction. It is not. It is the same as `untitled-1.txt` - rename on contact.

**How to apply:**
- First action in any /plan invocation, before writing any content: pick a descriptive filename for the plan based on the user's request.
- If harness lets you write to your chosen path directly, do that. If harness locks the path during plan mode, write to the slug, then `mv` to descriptive name immediately after ExitPlanMode (before any other tool call).
- Never end a turn with a slug-named plan still on disk.
- Pair rule: `feedback_plan_mode_approval.md` (also /plan workflow gate - no auto-build after ExitPlanMode).
