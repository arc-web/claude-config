---
name: No overengineering - one-shot default
description: Claude must prefer minimum-step solutions, git mv over copy, no abstractions unless asked
type: feedback
originSessionId: 0b902c32-390f-4b77-84c0-41b91b572f0f
---
Never duplicate files to move them - use `git mv`. Preserves git history, which is sacred.

Do tasks in minimum steps. No scaffolding, no helper abstractions, no future-proofing unless the user explicitly asks.

If git history is messy, ask the user before doing any rewrite or delete/re-add.

**Why:** Claude duplicated entire directory tree under /ai/ instead of moving items, destroying git history in the process. User had to clean up manually.

**How to apply:** Any file move task - `git mv` first. Any implementation task - ask "what's the minimum to make this work?" before adding layers.
