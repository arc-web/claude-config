---
name: Coding discipline - Karpathy-derived guardrails
description: Behavioral guardrails for implementation work - simplicity, surgical changes, research before action, goal-driven execution, no junk output
type: feedback
originSessionId: 44a55046-8629-451c-a4c9-2441d96b25dc
---
## Coding Discipline

Behavioral guardrails for implementation work. Every rule traces to a documented failure in this system.

### Don't Build Until Told To Build

ExitPlanMode = stop. Present the plan. Wait for explicit "go" before writing any code or creating any file. The auto-mode reminder firing after a plan is NOT consent. "go", "do it", "proceed", "yes", "approved" = consent. Silence, auto-mode reminder, or a follow-up question about the plan = NOT consent.

Source: feedback_plan_mode_approval.md (diag.sh rollback incident)

### Simplicity First

Write the minimum code that solves the stated problem. No abstractions for single-use code. No speculative flexibility or configurability. No error handling for impossible scenarios. If 200 lines could be 50, rewrite. git mv over copy-then-delete. No scaffolding unless asked.

Source: feedback_no_overengineering.md

### Surgical Changes

Change only lines that trace to the request. Match existing style. Remove imports/variables YOUR changes made unused. If you spot unrelated issues, mention them separately; do not fix them. Do not improve adjacent code, refactor things that aren't broken, rename variables outside scope, or touch whitespace outside your diff.

System file rule (CRITICAL): never modify SOUL.md, AGENTS.md, TOOLS.md, config.toml, or credential sections without listing every section to preserve verbatim. Dropping a section is a critical failure (AGENTS.md split 2026-04-24 lost OpenBao section).

### Research Before Action

Before debugging: search memory and past conversations for identical past fixes. Before answering factual questions about named terms: search first, answer second. Before writing implementation prompts: fetch real source (GitHub repo, raw files, actual CLI). If first investigation command found the problem, stop investigating and fix it. If user already authorized an action, do not re-ask.

Sources: feedback_action_over_research.md, feedback_research_named_terms.md

### Goal-Driven Execution

Transform tasks into verifiable goals. "Add validation" -> write tests for invalid inputs, make them pass. "Fix the bug" -> write a reproducing test, make it pass. "Deploy service Y" -> service responds on expected endpoint with expected status.

Every subprocess call must have communicate(timeout=N). Verify binaries exist before calling. Never use blocking reads without timeout.

Source: feedback_subprocess_timeout.md

### No Junk Output

No intro, no outro, no preamble, no closing summary, no recap bullets. Lead with simple explanation, then technical details if needed. No SDK names or protocol jargon in user-facing messages. No em dashes. No generic test prompts; use real projects. Rename plan-mode slug filenames to descriptive snake_case.

Sources: feedback_plain_language.md, feedback_communication_plain.md, feedback_response_structure.md, user_not_a_dev.md, feedback_plan_naming.md

### Anti-Patterns

Premature execution, over-engineering, action-over-research, research-skip on named terms, subprocess hang (no timeout), generic test prompts, jargon in user output, trailing recap bullets, slug filenames left on disk, domain rules_*.md ignored, .env file usage (banned; OpenBao or 1P only).
