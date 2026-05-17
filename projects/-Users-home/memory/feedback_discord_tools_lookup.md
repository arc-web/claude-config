---
name: Discord = CLI only, never MCP
description: All Discord work routes through discord_agent CLI (~/ai/agents/comms/discord_agent/). MCP plugin is OFF-LIMITS. Never suggest, enable, or fall back to it.
type: feedback
originSessionId: 256b0f1e-ab23-4732-aa4a-1753494d8987
---
Discord operations - read, send, scan, react, edit, channel/member/role ops - use `discord_agent` CLI exclusively (`/Users/home/ai/agents/comms/discord_agent/`). Do NOT use, suggest, enable, or mention the Discord MCP plugin.

**Why:** Session 2026-04-27 - user explicitly said "we don't want to use the mcp at all, we want to use the cli only". Decision is final, not task-specific. Earlier same session I defaulted to MCP path on a generic "discord tools" request and got corrected ("i didn't say mcp did i?"). Root cause of original slip: empty ToolSearch result primed MCP-only thinking, `reference_discord.md` leads with MCP section causing recency bias, and "tools" was conflated with "MCP tools".

**How to apply:**
- Discord task arrives → go straight to `~/ai/agents/comms/discord_agent/` (`discord.sh`, `discord_api.py`, `discord_report.py`, `community_ops.sh`, `event_ops/`, `it_support/`)
- Never run ToolSearch for discord MCP tools
- Never propose `claude plugin enable discord` or any MCP-enable step
- Never suggest MCP as fallback even for real-time DM/reply use cases - extend CLI instead
- `reference_discord.md` MCP section = ignore; only "Discord Agent (CLI)" section is in scope
- If user asks about real-time bot behavior, answer: CLI only, no MCP
