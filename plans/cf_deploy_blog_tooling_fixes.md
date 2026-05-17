# cf-deploy Bug Fixes + Blog Tooling

## Context

Blog rollout to netprofitpositive.com surfaced 4 bugs in cf-deploy and exposed a missing blog authoring workflow. This plan fixes the bugs and adds `cf-deploy blog` subcommands so future blog rollouts (lonopack, aibrainbuilders, exitstorm, etc.) require one command per post, not manual HTML edits.

**What broke:**
1. `deploy` created a new bucket "blog" instead of using the existing `netprofitpositive-com` - no guard against re-deploying a registered site
2. All `/blog/`, `/blog/google-ads/` etc. returned 404 - `ensureIndexRewrite` only handled root `/`, and the directory key dual-upload had a bug for the path-prefixed root
3. `ensureIndexRewrite` used the `matches` regex operator which requires Cloudflare Business plan - blocked on Pro/Free
4. 40-file sequential upload timed out at 120s - one upload at a time, no concurrency

---

## Part 1: Bug Fixes

### Fix 1 - Deploy guard (`bin/cf-deploy.js`)

In the `deploy` command action, before calling `deploy({...})`, add two registry checks:

```javascript
// Check 1: site name already registered
const existing = registry.get(siteName)
if (existing) {
  console.error(`[error] Site "${siteName}" already registered. Use: cf-deploy update ${siteName}`)
  process.exit(1)
}
// Check 2: bucket name already in use under a different site name
const allSites = registry.list()
const conflict = Object.entries(allSites).find(([, s]) => s.bucket === project)
if (conflict) {
  console.error(`[error] Bucket "${project}" used by site "${conflict[0]}". Use: cf-deploy update ${conflict[0]}`)
  process.exit(1)
}
```

### Fix 2 - Concurrent uploads (`lib/deploy.js`)

Add a `runConcurrent(tasks, limit=5)` helper at the top of the file (no new npm deps):

```javascript
async function runConcurrent(tasks, limit = 5) {
  let i = 0
  async function worker() {
    while (i < tasks.length) { const idx = i++; await tasks[idx]() }
  }
  await Promise.all(Array.from({ length: Math.min(limit, tasks.length) }, worker))
}
```

Replace the `for...of` upload loop with:

```javascript
let done = 0
const total = all.length
await runConcurrent(all.map(({ full, key }) => async () => {
  const n = ++done
  process.stdout.write(`  [${n}/${total}] ${key}\n`)
  await uploadFile(bucket, key, full)
}), 5)
```

### Fix 3 - `ensureIndexRewrite` (`lib/api.js`)

Current code uses `(http.request.uri.path matches "/$")` - regex operator blocked on Pro plan. Directory key dual-upload handles all subdirectory paths. The Transform Rule only needs to handle true site root.

Replace the rule expression and action:

```javascript
const directoryIndexRule = {
  expression: '(http.request.uri.path eq "/")',    // eq works on all plans
  description: 'R2 directory index',
  action: 'rewrite',
  action_parameters: { uri: { path: { value: '/index.html' } } },  // static value, no concat needed
}
```

Also fix `hasCorrectRule` check to detect when old broken rule exists and replace it (compare both description AND expression).

### Fix 4 - SEO command accepts URL (`bin/cf-deploy.js`)

Change `seo <name>` to `seo <name-or-url>`. Before registry lookup, check for `http://` or `https://` prefix:

```javascript
.command('seo <name-or-url>')
.action(async (nameOrUrl) => {
  let auditUrl
  if (nameOrUrl.startsWith('http')) {
    auditUrl = nameOrUrl
    console.log(`SEO audit: ${auditUrl}\n`)
  } else {
    const site = registry.get(nameOrUrl)
    if (!site) { console.error(`Site "${nameOrUrl}" not found.`); process.exit(1) }
    auditUrl = site.url
    console.log(`SEO audit: ${nameOrUrl} (${auditUrl})\n`)
  }
  const results = await auditSeo(auditUrl)
  // ...rest unchanged
```

---

## Part 2: Blog Tooling

### New file: `lib/blog.js`

Exports three functions: `scaffoldPost`, `initMeta`, `buildIndex`.

#### `meta.json` schema (written alongside each post's `index.html`)

```json
{
  "title": "Google Ads Call Tracking Is Counting Wrong",
  "slug": "google-ads/call-tracking/call-tracking-counting-wrong",
  "description": "150-160 char excerpt...",
  "category": "strategy",
  "categoryLabel": "Strategy",
  "readTime": "6 min read",
  "date": "2026-05-09",
  "dateLabel": "May 9, 2026"
}
```

#### `scaffoldPost(opts)` - creates new post dir from template

- Reads `templates/blog/post-template.html`
- Replaces `[POST TITLE]`, `[post-slug]`, `[150-160 character excerpt...]`, `[YYYY-MM-DD]`, `[Month DD, YYYY]`, `[Category]` placeholders
- Writes `index.html` + `meta.json` to `blogDir/slug/`
- Throws if dir already exists

#### `initMeta(blogDir, opts)` - one-time migration for existing posts

- Walks all subdirs with `index.html` but no `meta.json`
- Extracts from HTML: `<title>` tag, `<meta name="description">`, `<link rel="canonical">`, `<meta property="article:published_time">`
- Derives `slug` from canonical URL (strip base + `/blog/` prefix + trailing slash)
- Estimates `readTime` from word count of `<article>` element text
- Uses `--default-category` flag (default: `strategy`) and `--default-date` (default: today)
- Writes `meta.json` for each post found without one

#### `buildIndex(blogDir, baseUrl)` - regenerates index.html card grid

- Walks `blogDir` recursively for all `meta.json` files
- Sorts by `date` descending
- Generates card HTML matching the existing Atropos card structure
- Replaces between `<!-- CARDS:START -->` and `<!-- CARDS:END -->` sentinels in `blog/index.html`
- Also updates Atropos init between `<!-- ATROPOS:START -->` and `<!-- ATROPOS:END -->` sentinels

### New file: `templates/blog/post-template.html`

Copy of `~/ai/projects/netprofitpositive/blog/post-template.html`. This makes the template portable across projects and committed to the repo.

### Wiring in `bin/cf-deploy.js`

Add `blog` command group (same pattern as `dns` and `schema`):

```
cf-deploy blog scaffold --dir ~/blog --slug google-ads/call-tracking/my-post \
  --title "My Post" --description "150 char desc" --category strategy \
  --date 2026-05-09 --base-url https://netprofitpositive.com

cf-deploy blog meta-init --dir ~/blog --default-category strategy

cf-deploy blog index --dir ~/blog --base-url https://netprofitpositive.com
```

After `index`, run `cf-deploy update <site-name>` to deploy.

### One-time setup: add sentinel comments to `blog/index.html`

The `buildIndex` function requires two pairs of sentinel comments in the existing `~/ai/projects/netprofitpositive/blog/index.html`:

- Wrap the `.post-grid` content with `<!-- CARDS:START -->` / `<!-- CARDS:END -->`
- Wrap the Atropos forEach call in `<script>` with `<!-- ATROPOS:START -->` / `<!-- ATROPOS:END -->`

---

## Implementation Order

1. `lib/api.js` - Fix `ensureIndexRewrite` expression (isolated, test with `verify`)
2. `lib/deploy.js` - Add `runConcurrent`, replace upload loop (test with small deploy)
3. `bin/cf-deploy.js` - Add deploy guard + SEO URL support
4. `templates/blog/post-template.html` - Copy template file
5. `lib/blog.js` - Implement `scaffoldPost`, `initMeta`, `buildIndex`
6. `bin/cf-deploy.js` - Wire `blog` subcommand group
7. `~/ai/projects/netprofitpositive/blog/index.html` - Add sentinel comments
8. Run `cf-deploy blog meta-init` on existing 11 post dirs to generate `meta.json` files
9. Run `cf-deploy blog index` to verify card regeneration matches current manual HTML
10. Commit everything on the current branch

## Verification

- `cf-deploy deploy ~/ai/projects/netprofitpositive/blog --domain netprofitpositive.com --path blog` - must fail with "already registered" error
- `cf-deploy update netprofitpositive-com` - must upload all files in ~5 concurrent batches (< 30s total)
- `curl -I https://netprofitpositive.com/blog/` - must return 200
- `cf-deploy seo https://netprofitpositive.com/blog/google-ads/call-tracking/call-tracking-counting-wrong/` - must pass with 0 failures
- `cf-deploy blog scaffold --dir /tmp/test-blog --slug test/post --title "Test" --description "desc" --category strategy` - must create dir with `index.html` and `meta.json`
- `cf-deploy blog meta-init --dir ~/ai/projects/netprofitpositive/blog` - must write `meta.json` in all 11 post dirs
- `cf-deploy blog index --dir ~/ai/projects/netprofitpositive/blog` - must regenerate `index.html` cards matching current content

## Critical Files

- `~/ai/agents/web/cloudflare_agent/lib/deploy.js` - upload logic
- `~/ai/agents/web/cloudflare_agent/lib/api.js` - Transform Rules
- `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js` - CLI commands
- `~/ai/agents/web/cloudflare_agent/lib/blog.js` - NEW
- `~/ai/agents/web/cloudflare_agent/templates/blog/post-template.html` - NEW (copy)
- `~/ai/projects/netprofitpositive/blog/index.html` - add sentinel comments
