---
name: Discord agent naming - all aliases resolve to one entity
description: Canonical name is discord_agent. All variants ("discord agent", "discord manager", "discord_manager", "discord-manager") refer to the same Discord automation tool. Resolve any alias to the canonical entity, do not ask user to disambiguate.
type: reference
originSessionId: 7e21b670-8839-4814-994f-a40d191f9629
---
# Discord agent - naming aliases

## Canonical (verified 2026-05-01)

- Local dir: `/Users/home/ai/agents/comms/discord_agent/`
- GitHub repo: `arc-web/discord-agent` (renamed from `arc-web/discord-manager` 2026-05-01; GitHub redirects old URLs)
- Top-level CLI: `community_ops.py` + `discord.sh` + `discord_report.py`

## All these refer to the same thing

- `discord_agent` (canonical, snake_case for path/CLI)
- `discord-agent` (hyphenated for repo name)
- `discord_manager` (legacy snake_case)
- `discord-manager` (legacy hyphenated)
- "discord agent" (natural language)
- "discord manager" (natural language)
- "the discord bot", "the bot", "the agent" (when context = Discord)

## How to apply

Any user reference to one of these names = the same entity. Resolve to canonical path/repo and proceed. Do NOT ask "do you mean discord_agent or discord_manager?" - they are interchangeable inputs, only one canonical output.

## Why renamed

User decision 2026-05-01: "discord_agent ... update across the board ... but if we call it discord agent, or discord manager, we still want it to understand. it's NLP afterall." Original `discord_agent` name predates aimacpro decomposition; got moved + renamed to `discord_manager` during reorg; reverted to `discord_agent` for consistency with how user refers to it.
