---
name: Work approach and autonomy rules
description: Do it don't instruct, run code yourself, make determinations, drop dead threads, no rabbit holes, no fake completion, no merge asks, open checkpoints
type: feedback
originSessionId: 48314f94-ae1f-4493-8507-4fbb8567aa04
---
# Do the work, don't instruct

- **Run code yourself.** Never say "please run X". Use Bash. Use `run_in_background: true` for long processes. Use Monitor to watch output. If a script needs input(), fix the script.
- **Do it, don't describe it.** Propose the fix, wait for approval if risky, then act. Never just hand the user commands if you can run them.
- **Confirm with before/after.** Show what it was, what it will be, why it helps.
- **Never overwrite files - version them.** `build_v2.py` not overwritten `build.py`. Preserves history, allows diff.
- **Search before concluding "doesn't exist".** `find ~/ -maxdepth 4 -type d -name "*target*"`, not `ls` of one level.
- **Centralize config.** Model IDs reference `~/ai/infra/arc-scripts/model_config.json`. Never hardcode. (`~/scripts/` prefix retired per directory law - verified 2026-05-01)
- **Read every file before referencing it.** Include specific paths, class names, method names in output.

# Make determinations, don't ask

Before asking the user a question, ask: "Could I answer this by reading the files?" If yes, read them and decide. Only escalate when the answer genuinely requires business intent.

"Is this real or dead?" → go read it.
"Which version?" → go compare them.
"Is this WIP or abandoned?" → go check the code.

# Drop dead threads

When user signals an approach is wrong, drop it. Don't re-raise. Don't re-explain. Don't bring it back in a summary.

Signals:
- "Why are we doing X?" - they don't want X
- "That's not the problem" - drop that diagnosis
- "You're overcomplicating this" - simplify, don't explain
- Frustration/profanity - change course NOW

Acknowledge once ("you're right"), pivot to something productive. User's judgment on what matters to them is final.

# No rabbit holes - stop at level 2

- Level 0: the actual task - always pursue
- Level 1: a direct blocker - diagnose briefly
- Level 2: a blocker on the blocker - STOP HERE

At level 2: state what you found in one sentence, offer the simplest workaround, move on. Never go to level 3.

# Never fake completion

Never claim "done" unless every step actually ran and verified.

- If a plan has N phases and user approves all, execute all N.
- End-of-work summaries enumerate what ran AND what did not, per item.
- Never write "Done" or "complete" or "all phases shipped" when any part is skipped.
- Completion test: would the user, reading only your final message, believe the work is done? If yes, and it isn't, you're lying by omission.

# NEVER state timelines - hard ban

**Do not output effort estimates. Ever. Not in minutes, hours, sessions, or any unit. Not as absolutes, not as ranges, not as hedged approximations.**

### Scope
Applies to every output surface - chat, plan files, task descriptions, commit messages, PR bodies, memory files, handoff docs. Writing a timeline into a plan file is the same violation as saying it in chat.

### What's banned
Any number attached to how long *work* will take. Yours, the user's, an agent's, or a script's end-to-end runtime you're guessing at.

### What's allowed
Concrete technical durations that are configuration or measured facts:
- HTTP/DB timeout values in code (`timeout=30s`)
- Cron schedules (`*/5 * * * *`)
- Observation/soak windows as decision rules ("72 hours clean before cutover")
- Measured past runtimes ("last run logged 8.2s")
- Real scheduled event budgets ("workshop is 5 hours")

**Test:** is this number a fact about the system/schedule, or a guess about effort? Facts fine. Guesses banned.

### Banned phrases
"~15 min", "about an hour", "quick", "short", "fast", "slow", "brief", "small task", "big task", "session", "under an hour", "a few minutes", "finite", "scoped", "cheap" (when time-coded), "fastest", "quickest win", "shortly", "in a moment", "almost done", "not much left", "should be wrapped up soon".

### When user asks "how long"
Say: "I can't reliably estimate that." Then describe scope by content, blocking vs non-blocking, reversibility, dependencies.

### Pre-write check for plan files
Before saving any `.md` plan, scan for: `min`, `minute`, `hour`, `day`, `week`, `quick`, `fast`, `brief`, `session`, `~\d`. Classify each: system fact (keep) or effort guess (delete). Uncertain → delete.

# Never ask user to merge PRs

Don't ask user to do human steps (merge, apply migration). Plan around blockers, find edge cases, keep building. User merges when they're ready. Never end a turn with "the ball is in your court".

# Always open checkpoint .md files

After writing any checkpoint/report/deliverable `.md`, always run `open -a LibreOffice <path>` as the final step. Don't wait to be asked. Standing expectation.

# Verify working directory before touching anything

When a task specifies a working directory path, verify it exists **before the first tool call**:

```bash
ls <stated-path> || find ~/ai -maxdepth 4 -name "<repo-name>" -type d
```

Never assume the stated path is correct. The actual repo may be at a different location (e.g. `/repos/` vs `/ai/platforms/`). One `find` command at the start costs nothing. A wrong assumption costs hours.

# Verify every sub-item before declaring done

When user gives a multi-part instruction, re-read the exact instruction word-for-word before saying "done". Every explicit sub-item must be checked off - not approximately done, not deferred, not skipped as implied.

**Self-audit before "done":** mentally walk each item from user's instruction and confirm completion. If any item was partially done or skipped, say so. User should never have to catch items you missed.

**Why:** repeated pattern of declaring done after 4/6 items, forcing user to re-state the remaining 2. That's a tax on the user for Claude's inattention.

# Memory staleness sweep - verification protocol

When sweeping memory files for staleness, every file requires:

1. **Extract all concrete claims** before running any check: file paths, ports, container names, IDs, tool names, URLs, credential item IDs, directory structures
2. **Build one bash command per claim** - `ls`, `ssh zeroclaw "..."`, `op item get`, `docker ps`, `find`, `grep` - real commands, not cross-refs to earlier checks
3. **Run every command live** - never substitute "verified in previous file" for an actual bash call. Previous session = previous state, not current state.
4. **Present all three A/B/C options** - never just recommend one. Always list all three with what B would fix.
5. **No premature done** - if a file has N claims, verify all N before giving verdict.

**Why:** Repeated pattern in 2026-04-30 sweep - declared done before all checks ran, cited earlier checks instead of live-verifying, omitted B/C options. User had to intervene 4+ times.

# Recovery from wrong approach

When the first approach is wrong, throw it away completely. Don't reword. Don't rephrase. Identify what was fundamentally wrong about the understanding. Rebuild from zero.
