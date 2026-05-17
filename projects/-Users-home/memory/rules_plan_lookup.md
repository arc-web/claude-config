---
name: Check plans directory on "what is the plan for" queries
description: When user asks about plans, search ~/.claude/plans/ first before saying no plan exists
type: feedback
originSessionId: c049a9e8-ec0d-4ca3-ae0d-55ec0a4fbde0
---
When user asks "what is the plan for [topic]" or similar, always check `/Users/home/.claude/plans/` for matching plan files before answering that no plan exists.

**Why:** Plans accumulate in that directory over time and are easy to forget. A grep or directory scan prevents duplicate planning work and helps resurface prior analysis.

**How to apply:** On any query about existing plans, run `ctx_tree /Users/home/.claude/plans/` or `ctx_search` to find related files before claiming "no plan found". Check the filename pattern—plans use topic-based names like `accounting-swarm-migration-backfill-p-and-l.md`, not random slugs.
