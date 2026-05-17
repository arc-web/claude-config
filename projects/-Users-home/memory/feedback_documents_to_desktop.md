---
name: Save documents to Desktop not /tmp
description: All generated documents (ODT, PDF, HTML reports) go to ~/Desktop, never /tmp
type: feedback
originSessionId: 44a55046-8629-451c-a4c9-2441d96b25dc
---
Save all generated documents to `~/Desktop/` by default. Never use `/tmp/` for documents.

**Why:** User wants files accessible on Desktop, not lost in /tmp.

**How to apply:** Any pandoc output, report, ODT, PDF, HTML file → `~/Desktop/<filename>`. Intermediate HTML source can still use /tmp if needed, but the final opened file goes to Desktop.
