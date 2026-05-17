---
name: Community Operations Platform project
description: Extending discord_agent into a full event/IT support/community management platform. Built from live Claude Code Conference session (April 10, 2026).
type: project
originSessionId: 4206b097-4951-4e74-b85c-a01d2674e6cf
---
## Status: Shipped under new path

Codebase: `~/ai/agents/comms/discord_agent/` (migrated from legacy `~/aimacpro/4_agents/discord_agent/` per directory law - aimacpro decomposed).
Plan file: original slug `cosmic-stirring-stearns.md` deleted before rename. Surviving plan files in `~/.claude/plans/`: `discord-agent-v2-release.md`, `discord_agent_llm_provider_chain.md`, `discord_agent_skill_cadence.md`, `discord-credential-access-bottleneck.md`.

## What happened
Managed a live 34-person workshop (StellarPH x KMC Claude Code Conference, Cebu) entirely through Discord bot + Claude Code. Solved 10+ distinct IT issues in real-time, reorganized pods 3x, distributed credentials, helped non-coders through terminal setup, guided 4 pods to build and deploy apps in one afternoon.

## What was built
Live in `~/ai/agents/comms/discord_agent/`:
- Event config system: `event_config.py`, `config_loader.py`, `events/`, `event_ops/`
- IT support module: `it_support/`, `fix_db/`
- Dev support: `dev_support/`
- Engagement tools: `engagement/`
- Top-level CLI: `community_ops.py` (+ `community_ops.sh` wrapper)
- Bot env: `bot.env`, `conference.env`

## Daily Win System (added 2026-05-09)

Automated daily post to Stackpack `#wins` with HITL approval.

- **`daily_win.py --mode draft`** - 9am cron generates embed (Gemini 2.5 Flash via OpenRouter), saves to `.cache/win_state.json`
- **`win_bot.py`** - persistent 24/7 bot (discord.py 2.x, WebSocket). Polls state every 60s. When draft found: DMs Mike with Accept/Reject/Revise buttons. Accept posts to #wins. Reject skips. Revise opens modal, collects note, regenerates embed, sends new DM.
- Features rotate from `features.yaml` (10 entries, `id/project/feature/mechanics/audience_hook` schema). State tracks `posted_ids` to avoid repeats.
- LaunchAgents: `com.arc.daily-win-draft` (9am calendar), `com.arc.daily-win-bot` (KeepAlive, always-on)
- Key lesson: discord.py 2.x deprecated `bot.loop.create_task` - use `@tasks.loop` + `poll_state.start()` in `on_ready`. launchd needs `PYTHONUNBUFFERED=1` + explicit `PATH=/opt/homebrew/bin:...` to find brew Python + op CLI.

## Cloudflare Worker (added 2026-05-13)

`workers/` dir added to discord_agent. Contains `daily-win-interactions` Worker (worker.js, wrangler.toml, broker/).
Deploy via `cd workers && ./deploy.sh` - calls `cf-deploy worker deploy` (cloudflare_agent CLI handles 1P credentials).
Do NOT call wrangler directly.

## Key lesson
Non-coders need Claude Code prompts, NEVER raw terminal commands. Add "Don't ask questions, just make it work" to every prompt.

## Conference server
- Discord: Claude Code Conference (ID: 1491955391792414841)
- Bot: claudeconference (token in `~/.claude/channels/discord/.env` and `~/ai/agents/comms/discord_agent/conference.env`)
- Workshop repo: https://github.com/arc-web/stellarph-claude-workshop
- Pod repos (verified 2026-05-01): pods A-D shipped as product apps `arc-web/{tindacheck,sakay-na,fitalarm,giftmaster}`; spare workspace repos `arc-web/claudeconference-pod-{e,f}` exist. No pod-{a,b,c,d} repos under that naming.
