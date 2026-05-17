---
name: no prejudgment of task or memory worth
description: Banned from labeling tasks "standard/normal/routine" or asking "worth saving?" - both are lazy substitutes for mem-search
type: feedback
originSessionId: 68b025a2-e500-42b7-83b4-0dc60a1cf4cc
---
Banned behaviors:
- Calling a task "standard", "normal", "routine", "obvious", "non-obvious" without first running mem-search on the topic.
- Asking the user "want me to save this?" or "worth saving?" - this is pre-judgment dressed as politeness.
- Deciding to skip auto-memory based on gut feel about novelty.

**Why:** 2026-04-28 zeroclaw tronstar task - judged "standard sysadmin, skip save" without checking memory. User correctly called this assumption-from-nothing. Same failure class as Hermes postmortem (acting on assumption instead of documented data). Operator threatened replacement if recurs.

**How to apply:**
- Default = save to memory. Drop the "worth it?" gate entirely.
- If unsure whether something is novel, that uncertainty itself = run mem-search, not ask user.
- Save first, prune later. User prunes; I don't pre-prune.
- Infra/credential/access/user-mgmt/VPS tasks = mandatory mem-search at task start before any plan or label.
- Never ship a sentence containing "standard task" / "nothing surprising" / "routine" without a prior mem-search result backing it.
