---
name: Infrastructure - servers, model config, directory structure, paths
description: VPS Alpha (Hostinger #1, 187.77.222.191) - primary machine. Model config location, agents directory structure, path boundaries for all output. OpenClaw deprecated 2026-03-30.
type: reference
originSessionId: 9931cd28-b35c-4980-9158-49b9c71bf069
last_verified: 2026-04-30
---
## Model configuration

- Central config: `~/ai/infra/arc-scripts/model_config.json` - single source of truth for all model IDs (last updated 2026-03-16)
- Daily checker script: `~/ai/infra/arc-scripts/check_claude_models.py` - exists but NOT active. Has hardcoded stale `~/scripts/` paths internally and no launchd job configured. Needs path fixes before use.
- Current latest (March 2026): Opus 4.6, Sonnet 4.6, Haiku 4.5
- Default: Sonnet 4.6 (set in `~/.claude/settings.json`)

## Servers

- **VPS Alpha** (Hostinger, 187.77.222.191) - machine #1. SSH alias `zeroclaw` in `~/.ssh/config`
- **OpenClaw** - DEPRECATED 2026-03-30. Replaced by ZeroClaw.

## VPS Alpha Services

Use these plain-language names to reference services. Skill files for each live at `/opt/paperclip/data/skills/` on VPS Alpha.

| Plain Language | Container | Port | What It Does |
|----------------|-----------|------|--------------|
| "Hermes", "the infra agent" | hermes-agent | no external port | VPS manager - SSH host access, cron jobs, health monitoring |
| "ZeroClaw Alpha", "the Discord bot" | zeroclaw | 42617 | Primary Discord bot + autonomous agent (Rust) |
| "ZeroClaw Bravo", "Bravo" | zeroclaw-bravo | 42618 | Secondary Discord bot instance (standby/parallel) |
| "Paperclip", "the orchestrator" | paperclip-server | 3100 (internal) | Agent orchestration platform |
| "Plane", "the task tracker" | plane-api-1 | 8000 | Project management REST API |
| "the approval webhook" | approval-webhook | 3002 (ext) → 3001 (int) | Plane task approval webhook handler |
| "Kuma", "status monitoring" | uptime-kuma | 3001 (internal) | Uptime monitoring dashboard (status.todovibes.com) |
| "kuma gateway" | kuma-gateway | 3003 (internal) | API gateway wrapping uptime-kuma |
| "OpenBao", "secrets store" | openbao | 8200 (internal) | Credential vault - sole source of truth for all VPS/agent secrets |
| "FlareSolverr", "the scraping proxy" | flaresolverr | 8191 | Cloudflare WAF bypass proxy. Integrated into arc-browser via `arc_browser/flaresolverr.py` + `cf_recovery.py` (2026-05-01). Also usable for one-shot HTTP scrapers needing `cf_clearance` cookies. |
| "Plane frontend" | plane-web-1 | 8082 (via proxy) | React UI (arc.todovibes.com) |

Full service table and restart order: `/opt/paperclip/data/skills/vps-context/SKILL.md` on VPS Alpha.

## Directory structure

All projects live under `~/ai/`. No `~/agents/` or `~/aimacpro/` - both deprecated and migrated.

**`~/ai/agents/`** - agents organized by category:
- `accounting/` - accounting/finance agents
- `comms/` - communication agents
- `creative/` - creative/media agents
- `development/` - dev tooling agents (includes infrastructure_agent)
- `mcp/` - MCP-related agents
- `ppc/` - paid advertising agents
- `seo/` - SEO agents
- `web/` - web agents

**`~/ai/infra/`** - infrastructure scripts, model config, arc-scripts

**Scaffolding tool**: `~/ai/agents/development/infrastructure_agent/apps/scaffolding_app/tools/scaffold_tool/scripts/scaffold_ai.sh`
- Supports: `--type agent|claude-agent|app|tool|script|workflow`
- Enforces snake_case naming, rejects hyphens/uppercase

Plans live inside the agent or app they belong to, in a `plans/` subdirectory.

## Path boundaries

- Claude Code output goes under `~/ai/` (not bare `~/`)
- Plans go to the owning agent's `plans/` directory (e.g., `~/ai/agents/development/infrastructure_agent/plans/`)
- When a skill says `docs/plans/` (relative), find the relevant agent and put it in that agent's `plans/` dir
- Cross-cutting reference docs: `~/ai/docs/arc-docs/reference/`
- Lessons/corrections log: `~/ai/docs/claude-config/tasks/lessons.md`
- Detailed operating rationale: `~/ai/docs/arc-docs/reference/operating-guidelines.md`
