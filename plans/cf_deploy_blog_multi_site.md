# cf-deploy blog: multi-site support

## Context

`cf-deploy blog` subcommands have `netprofitpositive.com` hardcoded as the default `--base-url` and require `--dir` to be typed manually every time. The registry already stores `source` (the blog dir path) and `url` (the site domain) per registered site. This plan wires those together so any registered site can run blog commands by name, and new sites (therappc, lonopack, aibrainbuilders, etc.) work without custom flags.

---

## Changes: `bin/cf-deploy.js`

All three blog subcommands (`scaffold`, `meta-init`, `index`) get the same treatment:

### Add `--site <name>` option (optional)

```javascript
.option('--site <name>', 'Registered site name — auto-fills --dir and --base-url from registry')
```

### Make `--dir` optional, resolve from registry when `--site` given

Change `.requiredOption('--dir ...')` → `.option('--dir ...')` on all three.

### Resolution logic (shared helper, top of blog section)

```javascript
function resolveBlogContext(opts) {
  // --site pulls dir + url from registry; explicit flags override
  let blogDir = opts.dir ? path.resolve(opts.dir) : null
  let baseUrl = opts.baseUrl ? opts.baseUrl.replace(/\/$/, '') : null

  if (opts.site) {
    const site = registry.get(opts.site)
    if (!site) {
      console.error(`[error] Site "${opts.site}" not found. Run: cf-deploy sites`)
      process.exit(1)
    }
    if (!blogDir) blogDir = path.resolve(site.source)
    if (!baseUrl) baseUrl = site.url.replace(/\/$/, '')
  }

  if (!blogDir) {
    console.error('[error] Provide --dir or --site')
    process.exit(1)
  }
  if (!baseUrl) {
    console.error('[error] Provide --base-url or --site')
    process.exit(1)
  }
  return { blogDir, baseUrl }
}
```

### Remove hardcoded NPN defaults

- `scaffold`: `'https://netprofitpositive.com'` default → removed
- `meta-init`: same
- `index`: same

### Update hint message at end of each action

Replace hardcoded `--dir ${opts.dir}` in output hints with `opts.site ? `--site ${opts.site}` : `--dir ${blogDir}``

---

## Changes: `lib/blog.js`

### `scaffoldPost`: site-local template lookup

Current: always reads `../templates/blog/post-template.html` (the NPN template).

New: look for `post-template.html` in the blog dir first; fall back to the bundled default.

```javascript
// Inside scaffoldPost(), replace hardcoded templatePath:
const localTemplate = path.join(blogDir, 'post-template.html')
const defaultTemplate = path.join(__dirname, '../templates/blog/post-template.html')
const templatePath = fs.existsSync(localTemplate) ? localTemplate : defaultTemplate
```

No new parameter needed — convention over configuration.

---

## Net result: usage patterns

**Existing NPN site (already registered):**
```bash
cf-deploy blog scaffold --site netprofitpositive-com \
  --slug google-ads/call-tracking/my-post --title "..." \
  --description "..." --category strategy

cf-deploy blog index --site netprofitpositive-com
cf-deploy update netprofitpositive-com
```

**New site (therappc, after registering its blog deploy):**
```bash
# Register once:
cf-deploy deploy ~/ai/agents/web/cloudflare_agent/clients/therappc/blog \
  --name therappc-blog --domain therappc.com --path blog

# Drop site-specific template:
cp ~/ai/agents/web/cloudflare_agent/templates/blog/post-template.html \
   ~/ai/agents/web/cloudflare_agent/clients/therappc/blog/post-template.html
# (edit branding in that copy)

# Then all blog ops use --site:
cf-deploy blog scaffold --site therappc-blog --slug features/my-feature \
  --title "..." --description "..." --category tools
cf-deploy blog index --site therappc-blog
cf-deploy update therappc-blog
```

**Override dir without site (still works):**
```bash
cf-deploy blog index --dir ~/ai/projects/newsite/blog --base-url https://newsite.com
```

**Mix: site for URL, explicit dir for filesystem:**
```bash
# Useful when blog is a subdir of a multi-page site source
cf-deploy blog index --site therappc --dir ~/therappc/src/blog
```

---

## Critical files

- `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js` — three blog command actions
- `~/ai/agents/web/cloudflare_agent/lib/blog.js` — `scaffoldPost` template lookup

---

## Verification

```bash
# Guard: missing both --site and --dir should error
node bin/cf-deploy.js blog index
# → [error] Provide --dir or --site

# NPN via --site
node bin/cf-deploy.js blog index --site netprofitpositive-com
# → Updated index.html with 12 post card(s)

# Explicit flags still work
node bin/cf-deploy.js blog index \
  --dir ~/ai/projects/netprofitpositive/blog \
  --base-url https://netprofitpositive.com
# → Updated index.html with 12 post card(s)

# scaffold with --site uses correct base URL in generated meta.json
node bin/cf-deploy.js blog scaffold --site netprofitpositive-com \
  --slug google-ads/test-post --title "Test" --description "desc" --category strategy
cat ~/ai/projects/netprofitpositive/blog/google-ads/test-post/meta.json | grep baseUrl
# → "baseUrl": "https://netprofitpositive.com"

# Template fallback: local template takes priority
# (place a custom post-template.html in a test blog dir, verify scaffold uses it)
```
