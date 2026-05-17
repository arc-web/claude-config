---
name: Audit auto-execute confidence threshold
description: When to auto-execute A/B/C audit decisions vs queue for user - don't ask for confirmation on obvious keeps
type: feedback
originSessionId: 8f17e42e-a837-44a0-807a-97adee423646
---
If recommendation is A (keep as-is) and all claims verified clean, execute without asking user.

**Why:** User challenged "if you think keep as-is, why ask me?" on 2026-05-01 memory audit run. Asking for confirmation on obvious A decisions wastes turns.

**How to apply:** Auto-execute A when all claims pass and content is accurate. Only queue for user when: (1) claims genuinely fail, (2) purge (C) is the recommendation, (3) file is explicitly flagged as credentials/high-risk category requiring user approval per plan rules.
