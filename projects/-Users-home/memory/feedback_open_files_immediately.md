---
name: Open files immediately after creating them
description: When user asks to create a report/doc and open it, open it immediately - never ask for confirmation
type: feedback
originSessionId: 44a55046-8629-451c-a4c9-2441d96b25dc
---
When creating any document (ODT, PDF, HTML, etc.) and opening it is part of the request or obviously expected: open it immediately using `soffice <file>` for LibreOffice files. Never ask "did you want me to open it?" or "should I force it with soffice?". Just open it.

**Why:** User explicitly said to never ask again. Just do it.

**How to apply:** After any `pandoc` or document-creation command, immediately follow with `soffice <path> &` (backgrounded so it doesn't block).
