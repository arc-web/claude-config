# Plan: cloudflare_agent ↔ discord_agent Worker Integration

## Context

discord_agent has a Cloudflare Worker (`workers/`) that was manually deployed via wrangler CLI (no deploy script existed). cloudflare_agent already has `deployWorker(workerDir)` which accepts any absolute path and runs `wrangler deploy` with 1Password-backed credentials - but the CLI only exposes this through a site-registry lookup (`cf-deploy workers <site-name>`).

Goal: make cf-deploy the single deploy path for all Cloudflare Workers regardless of whether they belong to a registered site, and wire discord_agent to use it.

---

## What's already there (reuse, don't rewrite)

- `lib/workers.js: deployWorker(workerDir)` - runs wrangler in any dir, handles 1P credentials. Already works standalone.
- `lib/workers.js: getWranglerEnv()` - credential injection from 1P. Already handles token vs key+email fallback.
- `bin/cf-deploy.js`: `workers` (plural) command = site-registry-based. Keep untouched.

---

## Changes

### 1. cloudflare_agent - new `worker` (singular) command

**File**: `bin/cf-deploy.js`

Add after the existing `redirects` command block, before `program.parseAsync`:

```javascript
// --- worker (standalone, no registry) ---
program.command('worker deploy <path>')
  .description('Deploy a Cloudflare Worker from an arbitrary directory (no site registry needed)')
  .action(async (workerPath) => {
    const abs = path.resolve(workerPath)
    if (!fs.existsSync(path.join(abs, 'wrangler.toml'))) {
      console.error(`No wrangler.toml found in ${abs}`)
      process.exit(1)
    }
    const { deployWorker } = require('./lib/workers')
    deployWorker(abs)
  })
```

That's the entire change to cloudflare_agent. `deployWorker` already does everything else.

---

### 2. discord_agent - add deploy script

**New file**: `discord_agent/workers/deploy.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cf-deploy worker deploy "$SCRIPT_DIR"
```

Short, explicit. Assumes `cf-deploy` is on PATH (it's linked globally via `npm link` or `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js`).

---

### 3. discord_agent - update CLAUDE.md

Add a "Worker Deployment" section to `discord_agent/CLAUDE.md`:

```
## Worker Deployment
The Cloudflare Worker lives in `workers/`. Deploy via:
  cd workers && ./deploy.sh
This calls cf-deploy (cloudflare_agent CLI) which handles credentials from 1Password.
Do NOT call wrangler directly.
```

---

## Interface contract

| Side | Command | What it does |
|------|---------|--------------|
| discord_agent | `cd workers && ./deploy.sh` | Shell-execs cf-deploy |
| cloudflare_agent | `cf-deploy worker deploy <path>` | Validates wrangler.toml present, calls deployWorker() |
| Any future agent | Same pattern | Same deploy.sh → cf-deploy |

No HTTP API. No shared library. No monorepo. Shell-to-CLI only.

---

## What this does NOT do

- No agent catalog/registry - agents are standalone, path is sufficient
- No changes to `workers` (plural) site-based command
- No changes to how broker deploys (deploy_zeroclaw.sh stays for VPS side)
- No route configuration - wrangler.toml route is already unset; that's a separate task

---

## Verification

1. `cd cloudflare_agent && node bin/cf-deploy.js worker deploy /path/to/no-wrangler-toml` → should exit with error message
2. `cd cloudflare_agent && node bin/cf-deploy.js worker deploy /Users/home/ai/agents/comms/discord_agent/workers` → should run wrangler deploy
3. `cd discord_agent/workers && ./deploy.sh` → same result as #2

---

## Files touched

- `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js` - add ~10 lines
- `~/ai/agents/comms/discord_agent/workers/deploy.sh` - new file (~4 lines)
- `~/ai/agents/comms/discord_agent/CLAUDE.md` - add 4-line section
