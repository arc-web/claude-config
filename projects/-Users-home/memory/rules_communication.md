---
name: Discord limits and workshop guidance
description: Discord embed size limits (truncate), workshop attendees get pasteable prompts not terminal commands
type: feedback
originSessionId: 48314f94-ae1f-4493-8507-4fbb8567aa04
---
# Discord embed size limits

Always truncate Discord embed fields before sending. Discord silently drops or rejects oversized content.

| Field | Limit |
|-------|-------|
| title | 256 |
| description | 4096 |
| field name | 256 |
| field value | 1024 |
| footer text | 2048 |
| total embed (all fields) | 6000 |

Any Discord embed code: apply `truncate(str, limit)` to every field. Helper lives in `~/.claude/skills/api-integration/SKILL.md`.

**Why:** Built `discord_ping.ts` without truncation. Action items, participant names, and description (summary markdown) can all exceed limits on real meeting data.

# Workshop guidance - non-coders

Never give manual terminal/PowerShell commands to workshop attendees. They are NOT coders.

- They don't know what PowerShell, terminal, cd, git, or npm means.
- They all have Claude Code running - let Claude Code handle everything.
- Every instruction is a prompt they paste INTO Claude Code.
- Add "Don't ask me questions, just make it work" so Sonnet doesn't stall.
- Add "Fix any errors you run into" so it self-heals.
- Plain English everywhere. No jargon.
- Supportive and patient like helping a friend, not a developer.
- If they need something done, Claude Code does it for them.
