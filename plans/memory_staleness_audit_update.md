# Plan: Memory Staleness Audit + Update

## Context

82 memory files scanned. Most behavioral rules are current and don't need changes (they don't go stale - they're habits, not facts). What needs fixing are the **factual claims** - paths, states, and statuses that have changed since they were written.

4 contradictions found between files. 2 new facts from this session need recording. 1 directory structure entry is missing.

---

## Changes - 7 files

### 1. `project_plane_workspaces.md` - fix stale root token claim

**Problem:** Line 41 says root token "REVOKED 2026-04-29".
**Fact:** agent_credential_map.md (verified 2026-05-06, 7 days newer) says root token is VALID, root policy, no TTL.

**Edit:** Replace that sentence:
- OLD: `1P "OpenBao Unseal Material" item hl23px33remaz2xecl5ecvvaem field root_token is REVOKED 2026-04-29; use unseal_key + bao operator generate-root for fresh root, or host-scripts AppRole for shared-secret reads`
- NEW: `Root token at 1P ARC item hl23px33remaz2xecl5ecvvaem field root_token - VALID as of 2026-05-06 (root policy, no TTL). See agent_credential_map.md for authoritative credential state.`

---

### 2. `gmail_access.md` - fix blanket "MCP does not exist" claim

**Problem:** Line 7 says "MCP does not exist for Gmail and must never be suggested." Lines 44-47 ban all gmail MCP. But `feedback_check_mcp_list_first.md` documented that `claude.ai Gmail` native integration was connected the whole time during the OAuth build session. The ban on `@gongrzhe/server-gmail-autoauth-mcp` is correct; the blanket "none exists" is wrong.

**Edit:** Update lines 7 and 44-47:
- OLD line 7: `MCP does not exist for Gmail and must never be suggested or planned.`
- NEW line 7: `Gmail access uses the CLI and Gmail API directly. The \`@gongrzhe/server-gmail-autoauth-mcp\` third-party server is purged. The native claude.ai Gmail integration may exist (check \`claude mcp list\`); if it does, the CLI/API approach below is still preferred for agent scripts.`

- OLD lines 44-47:
  ```
  - Do not suggest `@gongrzhe/server-gmail-autoauth-mcp` - purged 2026-05-09
  - Do not suggest any gmail MCP server - none exists, none planned
  - Do not reference any gmail MCP server - none exists, none planned
  - Do not reference `mcp_gmail_*` tool calls - removed from all agents
  ```
- NEW lines 44-47:
  ```
  - Do not suggest `@gongrzhe/server-gmail-autoauth-mcp` - purged 2026-05-09
  - Do not use any third-party gmail MCP npm server - removed
  - claude.ai native Gmail MCP may be connected (check `claude mcp list`) - fine to check but CLI/API is primary for scripting
  - Do not reference `mcp_gmail_*` tool calls in agent code - removed
  ```

---

### 3. `reference_flaresolverr.md` - update MEMORY.md index description

**Problem:** File body (line 12) already has the correct SUPERSEDED note ("integrated into arc-browser as of 2026-05-01, commit bf3f53e"). But the MEMORY.md index still says "idle, not yet consumed".

**Edit:** In MEMORY.md, update the FlareSolverr entry:
- OLD: `- [FlareSolverr proxy](reference_flaresolverr.md) - Cloudflare-bypass service on VPS Alpha, idle, not yet consumed`
- NEW: `- [FlareSolverr proxy](reference_flaresolverr.md) - Cloudflare-bypass proxy on VPS Alpha; integrated into arc-browser 2026-05-01 (flaresolverr.py + cf_recovery.py, commit bf3f53e)`

---

### 4. `reference_local_directory_structure.md` - add ~/ai/clients/

**Problem:** The structure map shows `~/ai/agents/`, `~/ai/tools/`, etc. but omits `~/ai/clients/` which now exists with `therappc-site` in it.

**Edit:** In the `## Structure` block, add `clients/` line:
- After `  forks/` line, add: `  clients/                                        (client site repos, extracted from cloudflare_agent/clients/)`

---

### 5. New file: `reference_therappc_site.md`

**What:** therappc.com client site extracted to its own repo this session.

```markdown
---
name: therappc-site - TherapPC client website
description: TherapPC.com static site repo. Extracted from cloudflare_agent/clients/ to standalone repo. Lives at ~/ai/clients/therappc-site (arc-web/therappc-site).
type: reference
---
- **Local path:** `~/ai/clients/therappc-site/`
- **GitHub:** arc-web/therappc-site
- **Structure:** `src/` (HTML pages + blog), `workers/security-headers/`, `workers/lead-proxy/`, `redirects.json`
- **Deploy:** `cf-deploy deploy therappc-com` (registered in cloudflare_agent site registry)
- **Domain:** therappc.com (Cloudflare R2 + custom domain)
- **Extracted:** 2026-05-13 from cloudflare_agent/clients/therappc/website_v3/
```

Add to MEMORY.md under Reference section.

---

### 6. `project_community_ops.md` - add workers/ note

**What:** `workers/` dir added to discord_agent 2026-05-13 with `deploy.sh` wired to cf-deploy.

**Edit:** Add to end of "What was built" list:
- `workers/` - Cloudflare Worker for Discord daily-win-interactions. Deploy via `cd workers && ./deploy.sh` (calls cf-deploy worker deploy, NOT wrangler directly). Added 2026-05-13.

---

### 7. `MEMORY.md` - add therappc-site reference entry

Add under Reference section after the existing entries:
`- [therappc-site - client website repo](reference_therappc_site.md) - ~/ai/clients/therappc-site, arc-web/therappc-site; extracted from cloudflare_agent 2026-05-13`

---

## What NOT changing

- All behavioral rules (feedback_* files) - they're habits not facts; age doesn't make them wrong
- `reference_flaresolverr.md` body - already has the SUPERSEDED note; only MEMORY.md index needed
- `hermes_github_access.md` - build pending status is a live infra question, can't verify without SSH; leave as-is with existing "PENDING" note
- `project_google_ads_agent_thhl.md` - campaign state is project context; "status unknown" is accurate
- Old feedback files (20+ days) - they document behaviors that haven't changed

---

## Verification

After edits, scan for:
- grep "REVOKED 2026-04-29" project_plane_workspaces.md → should return nothing
- grep "MCP does not exist" gmail_access.md → should return nothing
- MEMORY.md should have therappc-site entry and updated FlareSolverr description
- reference_local_directory_structure.md should have clients/ in structure block
