---
name: Plane workspaces and structure
description: Plane self-hosted at arc.todovibes.com has TWO workspaces - Internal (slug=todovibes) and Clients (slug=clients). API key works across both. Project/module patterns differ per workspace.
type: project
originSessionId: e22fe797-26c8-461f-964b-77cbaf03233a
---
Plane self-hosted on zeroclaw VPS at `arc.todovibes.com`. Postgres in `plane-plane-db-1` container.

**Workspaces (verified live 2026-04-30):**
- `todovibes` slug = display name "Internal" - operator/team work
- `clients` slug = display name "Clients" - external client engagements

**API key:** single key at OpenBao `secret/shared/plane-api-key` works for both workspaces. Read via host-scripts AppRole. Cloudflare blocks default UA - send `User-Agent: plane-cli/1.0`.

**Internal workspace projects (todovibes slug, verified 2026-05-17):**
- AGENT - Internal Ops
- INFRA - Infrastructure
- COMM - Communities (mirrors clients pattern - community = module)
- ADS - Google Ads
- LAND - Web Design Tech
- DEVOPS - DevOps
- AGNTS - Agents
- JOHAN project deleted 2026-05-17 - all 31 tasks migrated to AGENT/INFRA/COMM before deletion

**Clients workspace structure (slug=clients):**
- One project per client (TMPL Templates, BLPX BluePixel, BLGR BlueGorilla, MOON Moonraker, ARC ARC)
- Modules within project = sub-customer/sub-scope (e.g. BLPX modules = PhilDillBoats, CCMarine, RamboMarine, etc., each tagged WLW or CO)

**Communities pattern (NEW, mirrors clients):**
- Project COMM in Internal workspace
- Module per community (StackPack first, added 2026-04-30)
- Issues under modules = ops/dev tasks for that community

**Why:** User asked to map communities like clients. Stackpack first community module. Auto-welcome bot deploy lives as issue under StackPack module.

**How to apply:**
- New community → create module under COMM project, name = community brand name
- Per-community ops/dev tasks → issue with `module_ids: [<module_id>]`
- Cross-community shared work → issue without module link, lives at COMM project root

**API gotchas:**
- CLI hardcoded `PLANE_WORKSPACE=todovibes`, no workspace switching - use raw API for clients workspace
- Root token at 1P ARC item `hl23px33remaz2xecl5ecvvaem` field `root_token` - VALID as of 2026-05-06 (root policy, no TTL). See agent_credential_map.md for authoritative credential state.
- Plane CLI cache (`~/.cache/plane/*`) ignores PLANE_WORKSPACE env override - cache key not per-workspace
