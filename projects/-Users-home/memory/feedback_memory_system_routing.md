---
name: Memory system routing - decision tree
description: Which memory system gets which type of fact. Prevents double-write across auto-memory and Brain Vault.
type: feedback
originSessionId: 44a55046-8629-451c-a4c9-2441d96b25dc
---
## Memory System Routing - Decision Tree

Where to save what. Prevents double-write (same fact in auto-memory + Brain Vault).

- Hard behavioral rule ("never X", "always Y") -> CLAUDE.md (human adds) or auto-memory rules_*.md
- Correction from user ("stop doing X") -> auto-memory feedback_*.md
- Project status, in-flight work -> auto-memory project_*.md
- External resource pointer (URL, dashboard, board) -> auto-memory reference_*.md
- Time-bounded fact (version number, deadline, system state) -> ctx_knowledge (has temporal validity)
- Raw session narrative -> Brain Vault Stop hook captures automatically; do not manually write

Do NOT write the same fact to multiple systems. Each fact has one home.
