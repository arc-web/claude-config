# Cloudflare Agent - Ship Current Work + Feature PRs

## Context

This session did a full audit-and-fix cycle on therappc.com (6 pages) and uncovered structural gaps in the cf-deploy tool. Two bugs were fixed live:

1. `deploy.js` was stripping `.html` from R2 keys (clean URLs) but the condition `rel === 'index.html'` didn't protect nested index files - `blog/index.html` became key `blog/index` (wrong). Fixed to include `rel.endsWith('/index.html')`.
2. Old `.html` keys lingered in R2 after rename (e.g. `results.html` still served content after migration to `google-ads-for-therapists-results`). Had to delete manually with a Node script.
3. Worker redirects had to be hand-coded in JS - no CLI, no config.

The branch `feat/therappc-client-site-and-sage-palette` has uncommitted changes and a stack of untracked files. This must ship first, then 4 feature branches follow.

---

## Accomplishments This Session

- Full mobile + desktop audit across 6 pages: a11y landmarks, iOS zoom (font-size → 1rem), skip-nav, canonical URLs, og: tags, GA4 placeholders
- Clean URL migration: deploy.js strips `.html` from R2 keys; source files keep `.html` for MIME detection
- Results page: renamed `results.html` → `google-ads-for-therapists-results.html` via `git mv`; SEO title, H2>H1 pattern, proper canonical
- CSS arrow bug: `content:'&#8594;'` rendered as literal text; fixed to `content:'→'`
- Security-headers worker: added REDIRECTS map (7 routes including `/results`, `/results.html`, all `.html` variants, `/blog`)
- Stale R2 keys deleted: `results.html`, `pricing.html`, `pipeline-calculator.html`, `privacy.html`, `terms.html`
- deploy.js nested index bug fixed (`blog/index.html` key preservation)
- Blog deployed (was 404) - includes Ontario case study + HIPAA tracking guide
- 14/14 URLs pass audit (200 or proper 301)

---

## PR 0 - Ship Current Branch

**Branch:** `feat/therappc-client-site-and-sage-palette`  
**Type:** Direct commit + PR to main

### What to commit

Stage and commit in two logical commits:

**Commit A - "fix: clean URLs, nested index key, therappc v3 page audit"**
Files:
- `lib/deploy.js` (clean URL stripping + nested index fix)
- `clients/therappc/website_v3/src/index.html`
- `clients/therappc/website_v3/src/pricing.html`
- `clients/therappc/website_v3/src/pipeline-calculator.html`
- `clients/therappc/website_v3/src/privacy.html`
- `clients/therappc/website_v3/src/terms.html`
- `clients/therappc/website_v3/src/google-ads-for-therapists-results.html` (renamed from results.html)
- `clients/therappc/website_v3/workers/security-headers/worker.js`

**Commit B - "feat: therappc blog system"**
Files (untracked):
- `clients/therappc/website_v3/src/blog/` (entire directory)

**Then:** Skip `registry/` and `services/` - those are unrelated discord-agent scaffold, commit separately.

---

## PR 1 - feat/worker-deploy-cli

**Branch:** `feat/worker-deploy-cli`  
**What it solves:** No way to deploy Workers without leaving the agent and manually running `wrangler deploy` with credential gymnastics.

### New command: `cf-deploy workers <site>`

**Changes:**
- `bin/cf-deploy.js` - add `workers` subcommand with `deploy` and `list` subcommands
- `lib/workers.js` (new) - wraps wrangler programmatically

**Implementation:**
```
cf-deploy workers deploy <site> [--worker security-headers|lead-proxy|all]
cf-deploy workers list <site>
```

**`lib/workers.js`** logic:
1. Look up site in registry → get source path (e.g. `clients/therappc/website_v3`)
2. Derive workers dir: `{source}/../workers/` (or configurable path)
3. Get CF credentials from 1P via `getAuth()` (already in `lib/auth.js`)
4. Set `CLOUDFLARE_API_KEY` + `CLOUDFLARE_EMAIL` env vars
5. Spawn `wrangler deploy` in the worker directory via `child_process.spawn`
6. Stream stdout/stderr to console

**Registry enhancement:** Add `workersPath` field to site registry entry (or derive from `source`).

**Files to create/modify:**
- `lib/workers.js` (new, ~80 lines)
- `bin/cf-deploy.js` (add `workers` command block, ~30 lines)

**Verification:** `cf-deploy workers deploy therappc --worker security-headers` should show wrangler output and deployed version ID.

---

## PR 2 - feat/redirects-config

**Branch:** `feat/redirects-config`  
**What it solves:** REDIRECTS map is hand-coded in each client's `worker.js`. Changing a URL requires editing JS, deploying the worker manually. No CLI. No validation.

### New command: `cf-deploy redirects <site>`

**New files:**
- `clients/therappc/website_v3/redirects.json` (created with current redirects)
- `lib/redirects.js` (new) - read/write/validate redirects.json
- `templates/security-headers/worker.js` - update to load REDIRECTS from bundled JSON or inline array

**Implementation approach:** Build-time injection (not KV at runtime)

At deploy/worker-deploy time:
1. Read `redirects.json` from client dir
2. Stringify and inject into worker.js as the REDIRECTS const
3. Write a temp worker file, deploy it, delete temp

**CLI commands:**
```
cf-deploy redirects list <site>           # print all redirects
cf-deploy redirects add <site> <from> <to>  # append to redirects.json + redeploy worker
cf-deploy redirects remove <site> <from>    # remove from redirects.json + redeploy worker
cf-deploy redirects test <site>             # curl each redirect, verify 301 + Location header
```

**`redirects.json` format:**
```json
{
  "/results.html": "/google-ads-for-therapists-results",
  "/results": "/google-ads-for-therapists-results",
  "/pricing.html": "/pricing",
  "/pipeline-calculator.html": "/pipeline-calculator",
  "/privacy.html": "/privacy",
  "/terms.html": "/terms",
  "/blog": "/blog/"
}
```

**Files:**
- `lib/redirects.js` (new, ~100 lines)
- `clients/therappc/website_v3/redirects.json` (new, populated from current worker)
- `clients/therappc/website_v3/workers/security-headers/worker.js` - REDIRECTS const generated from file
- `templates/security-headers/worker.js` - update to same pattern
- `bin/cf-deploy.js` - add `redirects` command block

**Verification:** `cf-deploy redirects test therappc` should return all OK.

---

## PR 3 - feat/update-clean

**Branch:** `feat/update-clean`  
**What it solves:** `cf-deploy update` uploads files but never deletes orphaned R2 keys. After renaming or deleting a page, the old key stays live and serves duplicate/stale content. Had to delete manually with a Node script this session.

### New flag: `cf-deploy update <site> --clean`

**Changes to `bin/cf-deploy.js`:** Add `--clean` and `--dry-run` options to `update` command.

**Changes to `lib/deploy.js`:** New function `syncFiles()` that wraps `uploadFiles()` + adds deletion of orphaned keys.

**Logic:**
1. List all current R2 keys (`listBucketObjects`)
2. Collect all keys that would be uploaded from source (run the same collect() logic without actually uploading)
3. Diff: keys in R2 but not in upload set = orphaned
4. Exclude protected keys: `robots.txt`, `sitemap.xml`, `llms.txt`, `404.html`
5. With `--dry-run`: print orphaned keys, exit
6. Without `--dry-run`: delete orphaned keys, then upload new files

**Command:**
```
cf-deploy update therappc --clean           # upload + delete orphans
cf-deploy update therappc --clean --dry-run # show what would be deleted, don't touch R2
```

**Files:**
- `lib/deploy.js` - add `syncFiles()` function (~50 lines)
- `bin/cf-deploy.js` - add `--clean` and `--dry-run` flags to `update` command

**Verification:** Add a dummy file to bucket manually, run `--clean --dry-run` to see it listed, run `--clean` to delete it, verify it's gone.

---

## PR 4 - feat/lint-cmd

**Branch:** `feat/lint-cmd`  
**What it solves:** `lib/lint.js` exists with solid checks (landmarks, skip-nav, form fields ≤3, CTA copy, CSS token consistency, GA4) but is NOT exposed as a CLI command and NOT wired into deploy.

### New command + deploy integration

**Changes:**
- `bin/cf-deploy.js` - add `lint <site>` command that calls `lintSource(path)`
- `bin/cf-deploy.js` - auto-run lint before deploy/update, fail on FAIL-level results (unless `--no-lint`)

**Commands:**
```
cf-deploy lint therappc                    # lint source files, print results
cf-deploy deploy ./src --domain x.com      # auto-lints first, blocks on FAIL
cf-deploy update therappc --no-lint        # skip lint (escape hatch)
```

**Files:**
- `bin/cf-deploy.js` - add `lint` command + pre-deploy lint hook (~40 lines)

**Verification:** Introduce a deliberate lint failure (e.g. add a form with 5 fields), run `cf-deploy lint therappc`, confirm FAIL output and deploy blocked.

---

## PR Sequence

```
main
  └─ feat/therappc-client-site-and-sage-palette (PR 0) ← ship first
       └─ after merge:
            ├─ feat/worker-deploy-cli (PR 1)   ← parallel
            ├─ feat/redirects-config (PR 2)    ← parallel
            ├─ feat/update-clean (PR 3)        ← parallel
            └─ feat/lint-cmd (PR 4)            ← parallel (easiest, ~40 lines)
```

PRs 1-4 are independent. Build and merge in any order after PR 0 lands.

---

## Critical Files

| File | Relevant To |
|------|-------------|
| `lib/deploy.js` | PR 0 (bug fixes), PR 3 (syncFiles) |
| `lib/auth.js` | PR 1 (getAuth for wrangler env) |
| `lib/registry.js` | PR 1 (workersPath lookup) |
| `lib/lint.js` | PR 4 (already complete, just wire) |
| `bin/cf-deploy.js` | All PRs (command surface) |
| `clients/therappc/website_v3/workers/security-headers/worker.js` | PR 0, PR 2 |
| `templates/security-headers/worker.js` | PR 2 (sync with client pattern) |
| `clients/therappc/website_v3/redirects.json` | PR 2 (new file) |

---

## Notes

- Workers deployment (`wrangler`) needs `CLOUDFLARE_API_KEY` + `CLOUDFLARE_EMAIL`, not `CLOUDFLARE_API_TOKEN`. Auth pattern from this session confirmed working.
- `ensureIndexRewrite()` in `lib/api.js` only handles root `/` → `/index.html`. Subdirectory indexes handled by dual-key upload strategy in `deploy.js`. No change needed.
- `registry/` and `services/` (untracked on current branch) are discord-agent scaffold - commit to a separate branch, not part of this plan.
