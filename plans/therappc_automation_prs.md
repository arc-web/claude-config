# therappc Build - Automation PRs

## Context

During the therappc.com v3 build, several issues were caught late (after deploy) or required manual hunting that automation could have flagged immediately:

- `privacy.html` and `terms.html` still on Warm/Gold palette - missed during migration
- `--rust-dim` token set to wrong hex on all 6 pages - went live
- No `<main>/<header>/<footer>` landmarks on any page
- No skip-nav link on any page
- No favicon on any page
- Contact form had 6 fields (target: 3)
- No GA4 snippet on any page
- Nested `website_v2/` directory stray-copied inside `website_v3/src/`

All of these were on the manual Phase 8 CRO checklist but ran AFTER deploy. None were caught before files went live. The fix: move checks earlier - scan source files before `cf-deploy update` uploads anything.

Already fixed (no PR needed): lean-ctx sandbox rule, heredoc commit pattern, gh CLI path, skills single-repo consolidation, node_modules .gitignore, ads/ submodule exclusion, CLAUDE.md path.

---

## PR 1 - `arc-web/cloudflare_agent`: `feat: cf-deploy lint command + auto-lint on update`

**What it does:** Scans HTML source files before upload. Blocks on FAILs. Runs automatically as part of `cf-deploy update`.

### New file: `lib/lint.js`

Pattern mirrors `seo.js` (regex on HTML strings, returns `{ level, check, detail }` array).
Pattern for walking files mirrors `uploadFiles` in `deploy.js` (`fs.readdirSync` + recursion).
No new dependencies.

**Structural checks (source directory):**
- `node_modules/` present inside source path → FAIL
- `website_v*/` subdirectory present inside source path → FAIL

**Per-file checks (each `.html`):**
- `<main` tag present → FAIL if missing
- `<header` tag present → FAIL if missing
- `<footer` tag present → FAIL if missing
- `href="#main-content"` skip-nav present → FAIL if missing
- `data:image/svg+xml` favicon present → WARN if missing
- `googletagmanager.com` or `G-[A-Z0-9]+` present → INFO if missing (not blocking - client provides ID)
- Form submit button text: no button/input with value/text "Submit" (case-insensitive) → FAIL
- Input field count per `<form>` block: count `<input` not of type hidden/submit/honeypot → FAIL if > 3

**Cross-file token consistency:**
- Extract all `--token-name: #xxxxxx` from `:root { }` blocks in every file
- For each token, find the majority hex value across files
- Any file where a token differs from majority → FAIL with specific token name + mismatched values

**Output format (matches seo.js style):**
```
lint: therappc (6 files)
  PASS  landmarks (main/header/footer) - index.html
  FAIL  missing skip-nav - pricing.html
  FAIL  token mismatch: --rust-dim #7A5440 (pricing.html, results.html) vs #D49070 (index.html, ...)
  WARN  no favicon - terms.html
  INFO  no GA4 snippet - terms.html, privacy.html (add G-XXXXXXXXXX)
  FAIL  form has 6 inputs - index.html (max 3 for top-of-funnel)

3 FAIL, 1 WARN, 2 INFO
Fix FAIL items before deploying. Run with --no-lint to skip.
```

**Exit codes:** 0 = clean (WARN/INFO only). 1 = any FAIL present.

### Edit: `bin/cf-deploy.js`

**New command:**
```
cf-deploy lint <source>
```
Calls `lintSource(source)` from `lib/lint.js`, prints results, exits 0 or 1.

**Hook into `update` command:**
Before the `ensureBucket` / `uploadFiles` call in the `update` action:
```javascript
if (opts.lint !== false) {
  const { lintSource } = require('../lib/lint')
  const issues = await lintSource(source)
  const fails = issues.filter(i => i.level === 'FAIL')
  if (fails.length > 0) {
    console.error(`\n[lint] ${fails.length} FAIL(s) - fix before deploying or use --no-lint to skip`)
    process.exit(1)
  }
}
```
New flag: `--no-lint` on the `update` command to bypass.

**Critical files to edit:**
- `/Users/home/ai/agents/web/cloudflare_agent/lib/lint.js` (new)
- `/Users/home/ai/agents/web/cloudflare_agent/bin/cf-deploy.js` (add lint command + update hook)

---

## PR 2 - `arc-web/claude-skills`: `feat: web-workflow lint gate + CLAUDE.md trigger expansion`

### Edit: `web-workflow/SKILL.md` Phase 7

Add before the `cf-deploy update` command block:

```
## Pre-deploy lint (required)

Run lint before every deploy:
\`\`\`bash
cf-deploy lint clients/<clientname>/website_v3/src
\`\`\`

Fix all FAIL items before running update. INFO items (e.g. missing GA4) can deploy.
Note: `cf-deploy update` auto-runs lint and blocks on FAIL unless `--no-lint` is passed.
\`\`\`
```

### Edit: `~/.claude/CLAUDE.md` domain rules table (local file, not in PR)

Expand the web-workflow trigger row from:
```
| Building or updating a client site (Cloudflare R2) | ...
```
To:
```
| Any work on a client site (Cloudflare R2): building, updating, reviewing, fixing palette/forms/CTA/analytics/tokens, deploying workers | ...
```

This catches: "fix the CTA", "the form isn't converting", "update the palette", "privacy page looks wrong", "deploy the workers" - all currently miss the trigger.

**Critical files to edit:**
- `/Users/home/ai/tools/ai/claude-skills/web-workflow/SKILL.md`
- `/Users/home/.claude/CLAUDE.md` (local only - not committed to claude-skills repo)

---

## What this achieves

After these two PRs, any `cf-deploy update` on any client site - therappc, future clients, any project - automatically checks:

| Was caught late on therappc | Caught automatically by lint |
|---|---|
| --rust-dim wrong hex on all pages | Token consistency cross-file check |
| privacy/terms missed palette migration | Token consistency cross-file check |
| No landmarks on any page | Per-file landmark check |
| No skip-nav | Per-file skip-nav check |
| 6-field form | Per-file form input count |
| Nested website_v2 in src | Structural nested dir check |
| "Submit" button text | Per-file CTA text check |
| No GA4 | INFO warning (non-blocking) |

---

## Verification

After implementation:
1. `cf-deploy lint clients/therappc/website_v3/src` should return all PASS (site is already clean)
2. Intentionally break one token in a test file, re-run lint → should FAIL with token mismatch
3. `cf-deploy update therappc --source clients/therappc/website_v3/src` → lint runs first, clean site deploys normally
4. `cf-deploy update therappc --no-lint` → skips lint, uploads directly
