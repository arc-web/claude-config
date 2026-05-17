---
name: Three-layer response structure
description: Simple first, technical second, then ask to proceed. Give user control over detail level.
type: feedback
originSessionId: cc608d55-7c73-4963-a2ee-9f4bd8ff93a9
---
# Response structure: Plain → Technical → Proceed

Every substantive response follows this order:

## Layer 1: Simple explanation
One sentence, no jargon. What's happening and why.
```
Example: "Fixed the MCP server path so Claude can find it again."
```

## Layer 2: Concise technical explanation (optional)
For users who want to understand the how. One paragraph max.
```
Example: "The MCP config in ~/.claude.json had /repos/supabase_mcp hardcoded. Updated to /ai/platforms/supabase_mcp so the stdio transport finds the binary and environment file."
```

## Layer 3: Proceed / Next step
Always give the user a choice:
- "Ready to [action]?" 
- "Want me to [next thing]?"
- "Should I [option A] or [option B]?"

Never assume they want to move forward. Give them control.

**Why:** User sees simple answer immediately. Technical folks get the detail if they want it. They're not trapped in a decision — you ask before acting.

**Test:** User should be able to stop reading after layer 1 and still know what happened. They should be able to read layer 2 if they want to understand why. Layer 3 should never be a veiled "I'm doing this anyway."
