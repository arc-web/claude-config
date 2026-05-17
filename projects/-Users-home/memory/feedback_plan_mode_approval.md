---
name: /plan command requires explicit approval before build
description: After ExitPlanMode, do NOT auto-execute even if auto-mode reminder fires - wait for user approval message
type: feedback
originSessionId: 435446a2-2ce7-4c11-ade3-cef3d7bf0461
---
After `/plan` and `ExitPlanMode`, STOP. Wait for explicit user approval ("yes", "go", "build it") before any Write/Edit/Bash that mutates state.

**Why:** User invoked /plan to get a reviewable plan, not auto-execution. Auto-mode reminders that fire post-approval-screen are misleading - the harness shows "plan approved" but user has not actually said go. Building anyway = wasted work + user anger. Happened 2026-04-27 on OpenBao diag.sh - user explicitly said "i didn't tell you to build shit, i told you to fucking plan".

**How to apply:**
- /plan -> Phase 1-4 -> ExitPlanMode -> **HARD STOP** until user says proceed
- Ignore "auto mode active" reminder if it fires immediately after ExitPlanMode - that is harness state, not user consent
- "Plan approved" from the harness is approval to *exit plan mode*, not approval to *execute the plan*
- Re-prompt is fine: "Plan saved. Approve to build?" - then wait
- Applies to every /plan invocation regardless of session mode
