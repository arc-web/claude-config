---
name: Memory audit edit style - rewrite assertively, cite rules, enumerate alternatives
description: When fixing a stale memory file during audit, follow the assertive-rewrite pattern observed from parallel agent on 2026-05-01. Rewrite status headers; cite governing rule; enumerate alternative pointers; use lifecycle vocabulary; no hedging.
type: feedback
originSessionId: 7e21b670-8839-4814-994f-a40d191f9629
---
# Audit edit style

## Pattern

1. **Rewrite status headers when status drifted** - if memory says `## Status: Plan approved, not yet implemented` and reality is shipped, rewrite header to `## Status: Shipped under new path` or similar. Body-only edits leave stale framing intact.

2. **Cite governing rule inline** - when justifying a structural change, name the rule. Example: `(migrated from legacy ~/aimacpro/4_agents/discord_agent/ per directory law - aimacpro decomposed)`. Rules to cite by name: directory law, plan-naming rule, no-em-dash rule, credential discovery order, repo boundaries.

3. **Enumerate alternatives, never single-pointer** - when one path dies, replace with full list of surviving alternatives. Example: dead `cosmic-stirring-stearns.md` -> `Surviving plan files in ~/.claude/plans/: discord-agent-v2-release.md, discord_agent_llm_provider_chain.md, discord_agent_skill_cadence.md, discord-credential-access-bottleneck.md`.

4. **Lifecycle vocabulary** - use state words: `legacy`, `migrated`, `shipped`, `surviving`, `deprecated`, `deleted before rename`, `superseded`. Not vague "old/new/gone".

5. **Backticks on every path** - paths, filenames, commands, config keys all in inline code.

6. **No hedging, no apology** - assertive flat statements. "X deleted before rename" not "X appears to have been deleted". "shipped as Y" not "may have been shipped as Y".

7. **Inline provenance dates** - when verifying live state, add `(verified YYYY-MM-DD)`. Distinguishes audited claims from imported memory.

## Why

Pattern observed from parallel agent edits to `project_workshop_scope.md` and `project_community_ops.md` on 2026-05-01. User confirmed style is the target. Consistent voice across agents avoids reading-cost when re-encountering the same file from a different session.

## How to apply

Every audit B-fix. Even small edits should match this style. C-purges don't apply (file deleted). A-keeps don't apply (no edit).
