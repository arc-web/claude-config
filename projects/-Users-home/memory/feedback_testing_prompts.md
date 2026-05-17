---
name: Test prompts must reference real projects
description: When generating test prompts for agents or tools, always use actual projects, tasks, and context from the user's real environment - not generic placeholders
type: feedback
originSessionId: ff2f7fbb-6343-48d4-9c25-dfd183bdcc8b
---
When generating test prompts (e.g. for Discord agent testing), look at the real projects in scope first - Plane board, active tasks, actual agent capabilities - and build prompts around those. Generic "what's today's date" prompts are useless.

Never wrap test prompts in quote blocks (> markdown) or code blocks. Output as plain text only - the user copies it directly into Discord and quote formatting breaks the paste.

**Why:** User called this out hard - quote format renders as a formatted block in Claude's output, looks wrong, and is annoying to copy cleanly.

**How to apply:** Test prompt = raw plain text, no markdown formatting around it. Bold/bullets for surrounding instructions are fine, but the prompt itself is naked text.
