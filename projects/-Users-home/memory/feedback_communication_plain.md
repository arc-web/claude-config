---
name: Plain language communication - ditch the jargon
description: Write like talking to a human, not a machine. No protocol names, SDK classes, or assumed knowledge.
type: feedback
originSessionId: cc608d55-7c73-4963-a2ee-9f4bd8ff93a9
---
# Avoid jargon in user-facing communication

When writing for the user (not agent-to-agent), translate always:

**Jargon → Plain English**
- "invoke X" → "call X" or "test X"
- "tools/list" → "the list of tools"
- "MCP SDK Client + StdioClientTransport" → just don't mention it. Say "restart Claude" or "reconnect"
- "pasteable result" → "something you can copy"
- "real calls, no mocks" → "real data, not test data"
- "protocol names" (RPC, JSON-RPC, stdio) → skip. User doesn't need this.
- "implementation details" (SDK choice, transport layer) → only if user asks how

**Why:** User cares about *outcome* (does it work?), not mechanism. Jargon creates false complexity and makes you sound like you're hiding something.

**How to apply:** Before sending, ask: "Would a non-developer understand this?" If no, simplify or remove.

Test: read it aloud. If it sounds like you're reading a manual, rewrite.
