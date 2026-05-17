---
name: Discord access and tools
description: discord_agent CLI is the only Discord interface. MCP plugin is off-limits per feedback_discord_tools_lookup.md. Check here before saying "no Discord access".
type: reference
originSessionId: 81ee8d7e-2ff0-4254-bfdd-600ece6e1edd
---
## Trigger phrases - act immediately, no research needed

"check our discord", "check discord", "look at discord", "what's in discord", "discord check" → run `discord.sh -s arc` or `discord_report.py --server arc` immediately. No confirmation needed.

"check stackpack", "stackpack discord" → run `discord.sh -s stackpack`.

"both servers" / "all servers" → run for arc + stackpack.

## discord_agent (CLI - canonical, multi-server)

Location: `~/ai/agents/comms/discord_agent/` (verified 2026-05-08; renamed from `discord_manager` for naming consistency, see `reference_discord_agent_naming.md`).

Python/shell tools managing 3 Discord guilds (arc, stackpack, conference) via Discord REST API. No VPS dependency.

### Top-level CLIs

- **`discord.sh -s <server> <cmd>`** - low-level: send, read, edit, delete, pin, react, threads, members, roles, broadcast, embed, server-info, member-search, cache-channels
- **`community_ops.py <group> <action>`** - high-level: audit (members/activity/channels/lurkers/report), channels (rename/topic/move/delete/scaffold/permissions), engage (shoutout/check-in/nudge-silent/countdown), pods, roster, event, it, dev
- **`discord_report.py [--server X]`** - scan all channels, LLM-draft replies, HITL approval loop. arc default scans 96 channels.
- **`llm_analyzer.py`** - Ollama-first (qwen2.5:14b), Anthropic Sonnet fallback. Ollama timeout 600s in `_call_ollama`.
- **`daily_win.py --mode draft`** - generate daily #wins embed via Gemini 2.5 Flash (OpenRouter), save to `.cache/win_state.json`. Runs at 9am via `com.arc.daily-win-draft` LaunchAgent.
- **`daily_win.py --mode status`** - print current win state JSON.
- **`win_bot.py`** - persistent discord.py WebSocket bot (StackPack.app token). Polls state every 60s, DMs Mike with Accept/Reject/Revise buttons. Handles button interactions + Revise modal. Runs 24/7 via `com.arc.daily-win-bot` LaunchAgent (KeepAlive). Restart: `launchctl kickstart -k gui/$(id -u)/com.arc.daily-win-bot`.

### Servers (servers.json) - verified 2026-05-09

| Key | Full name | Guild ID | Bot env | Default? |
|-----|-----------|----------|---------|----------|
| arc | **Advertising Report Card** (ARC) - agency internal + 17 client channels | 1264976257888551045 | bot.env | yes |
| stackpack | StackPack.app paid community | 1392196836378542162 | stackpack.env | no |
| conference | Workshop/event server, pod-a..pod-f | 1491955391792414841 | conference.env | no |

**Stackpack channel aliases** (in servers.json): `wins` = `1492514729980071986`

**Soul docs**: `souls/stackpack_soul.md` (voice/tone guide), `souls/anti_slop.md` (banned words/patterns for all community-facing copy)

**ARC = Advertising Report Card.** Always map "arc", "ARC", "advertising report card" to server key `arc`.

### Config / Credentials

- Token resolution order (config_loader.py, updated 2026-05-12): env var → OpenBao `secret/shared/discord-<slug>` → 1P fallback
- OpenBao canonical paths: `arc`=`secret/shared/discord-arc-web`, `stackpack`=`secret/shared/discord-stackpack`, `conference`=`secret/shared/discord-claudeconference`
- Also mirrored at `secret/discord/<slug>` but only root token can read those; `shared/` is readable by host-scripts AppRole
- Per-server env files: `bot.env` (arc), `stackpack.env`, `conference.env` - chmod 600
- `servers.json` - guild IDs, bot IDs, channel ID aliases
- Soul docs in `souls/` shape voice per server
- `CLAUDE.md` in repo root = natural-language -> tool map (authoritative skill inventory)

### Channel management - USE EXISTING CODE

- `discord_api.py` has `create_channel(name, channel_type, category_id)` and `delete_channel(channel_id)` and `edit_channel(channel_id, **kwargs)` - DO NOT write custom scripts
- `community_ops.py channels scaffold <yaml>` for bulk creation
- For one-off creation: `python3 -c "from discord_api import DiscordClient; c=DiscordClient('arc'); print(c.create_channel('name', 0, 'cat_id'))"`
- Zeroclaw Alpha/Bravo/Charlie are NOT ARC guild admins - don't use them for ARC channel management

### Known runtime gotchas

- `config_loader.py` hardcodes `op_loader` path - if 7_tools moves again, patch line 20
- Ollama timeout was 120s (too low for 17-channel batch) - now 600s
- `discord_report.py` send gate uses interactive `input()` - needs `--approve` flag for non-tty use
- urllib3/charset_normalizer version warning is cosmetic, ignore

### ARC server canonical bot: AlphaClaw (verified 2026-05-12)

OpenClaw/arc-web bot (1475745144912220311) is NOT in ARC server. Ignore all prior references to arc-web for ARC guild.

**ARC bots (live members as of 2026-05-12):**
| Bot | ID | Can do |
|-----|----|--------|
| AlphaClaw | 1476934805458259980 | Channel create/rename/delete, 100 channels visible |
| BravoClaw | 1491482529507573973 | TBD |
| CharlieClaw | 1499924971911254178 | Read + post messages, public channels |
| Hermes Agent | 1492911005473443870 | Hermes container ops |

**config_loader.py `arc` server now resolves to AlphaClaw** via `secret/shared/discord-zeroclaw-alpha` (OpenBao) → `op://Zeroclaw/ZeroClaw Alpha Discord Bot/discord_token` (1P fallback).

### discord.sh read - error handling bug (FIXED 2026-05-11)

Fixed with isinstance guard. Was crashing with `TypeError: string indices must be integers` on API errors. discord.sh now prints to stderr and exits 1 on non-list response. Commit: 36ce304 on `claude/feat/daily-win-hitl`.

---

## Which to use when

Every row routes through `discord_agent` CLI. MCP plugin off-limits per `feedback_discord_tools_lookup.md`.

| Need | Use |
|------|-----|
| Respond to a DM or guild message in real time | `discord.sh -s <server> send` (extend CLI if real-time loop needed) |
| Fetch recent messages from a channel | `discord.sh -s <server> read` |
| Batch scan/respond across ARC server channels | `discord_report.py --server arc` |
| Channel/member/role admin | `community_ops.py channels|engage|audit ...` |
| Send a one-off message to a specific channel | `discord.sh -s <server> send` |

---

## Deprecated: MCP plugin (do not use)

Bun-based MCP server lives at `~/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/discord/` but is **off-limits per policy** (`feedback_discord_tools_lookup.md`, 2026-04-27). Runtime files (`~/.claude/channels/discord/inbox/`, `access.json`) are missing - never fully wired. Do not enable, suggest, or fall back to it. Plugin tools (`reply`, `react`, `edit_message`, `fetch_messages`, `download_attachment`) and skills (`/discord:access`, `/discord:configure`) exist but are banned. Any real-time use case routes through CLI extension instead.
