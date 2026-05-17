# AiBrainBuilders Blog: End-to-End Launch Test

## Context

This is a full test of the blog post dev/write/launch pipeline on aibrainbuilders.com. The site is live (8 pages, dark theme, Bebas Neue + Inter fonts, violet/teal palette) but has no blog. Source files were deployed from `/tmp/aibrainbuilders-site` which no longer exists locally. Goal: create the blog locally, wire it into cf-deploy's registry under the existing bucket, write 3 real posts, and deploy to `aibrainbuilders.com/blog/`.

---

## Step 1: Add `cf-deploy blog register` command

**Gap:** No way to associate a blog with an existing root site registration. `deploy` would fail (domain already registered). Need a command that creates a new registry entry pointing to the same R2 bucket with a `blog` path prefix.

**File:** `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js`
**File:** `~/ai/agents/web/cloudflare_agent/lib/blog.js`

```bash
cf-deploy blog register --root aibrainbuilders \
  --name aibrainbuilders-blog \
  --dir ~/ai/projects/aibrainbuilders/blog
```

Implementation in `bin/cf-deploy.js` (new `blog register` subcommand):

```javascript
blog
  .command('register')
  .description('Register a blog on an existing site\'s bucket')
  .requiredOption('--root <name>', 'Existing registered site name (e.g. aibrainbuilders)')
  .requiredOption('--name <name>', 'New registry name for the blog (e.g. aibrainbuilders-blog)')
  .requiredOption('--dir <path>', 'Local blog source directory')
  .option('--path <prefix>', 'URL path prefix (default: blog)', 'blog')
  .action((opts) => {
    const root = registry.get(opts.root)
    if (!root) { console.error(`[error] Site "${opts.root}" not found`); process.exit(1) }
    if (registry.get(opts.name)) { console.error(`[error] "${opts.name}" already registered`); process.exit(1) }
    const blogDir = path.resolve(opts.dir)
    registry.add(opts.name, {
      bucket: root.bucket,
      domain: root.domain,
      source: blogDir,
      url: root.url,
      path: opts.path,
    })
    console.log(`Registered: ${opts.name}`)
    console.log(`  Bucket:  ${root.bucket}`)
    console.log(`  URL:     ${root.url}/${opts.path}/`)
    console.log(`  Source:  ${blogDir}`)
    console.log(`\nNext: cf-deploy blog scaffold --site ${opts.name} --slug ...`)
  })
```

No changes to `lib/blog.js` needed for this step.

---

## Step 2: Create local aibrainbuilders blog source

**Directory:** `~/ai/projects/aibrainbuilders/blog/`

### Design system (from live site)

| Token | Value |
|-------|-------|
| `--bg` | `#050811` |
| `--bg-2` | `#090d1a` |
| `--surface` | `#0f1628` |
| `--violet` | `#8b5cf6` |
| `--teal` | `#00d4aa` |
| `--amber` | `#f59e0b` |
| `--text` | `#e8edf5` |
| `--text-2` | `#7a91b0` |
| `--border` | `#1a2540` |
| Heading font | `Bebas Neue` |
| Body font | `Inter` |
| Label font | `JetBrains Mono` |

### Files to create

**`blog/index.html`** - Blog listing page matching AiBB dark theme:
- Sticky frosted-glass nav (matching live site: Home, AI Agents, Training, Conferences, Sponsors)
- Hero with Bebas Neue headline + teal/violet stat block
- Filter bar: All / AI Agents / Training / Strategy / Case Study
- 3-col Atropos card grid with dark glassmorphic cards (surface bg, border, violet hover)
- `<!-- CARDS:START -->` / `<!-- CARDS:END -->` sentinels
- `// ATROPOS:START` / `// ATROPOS:END` sentinels in `<script>`
- Footer matching live site

**`blog/post-template.html`** - Post template matching AiBB theme:
- Same nav, dark bg, violet/teal accents
- Reading progress bar (violet)
- Floating TOC (dark surface, teal active state)
- Pull quote, callout blocks, stat showcase in AiBB colors
- JSON-LD Article schema
- Author bio: "AiBrainBuilders Team"
- Related posts grid

---

## Step 3: Register the blog

```bash
mkdir -p ~/ai/projects/aibrainbuilders/blog
cf-deploy blog register \
  --root aibrainbuilders \
  --name aibrainbuilders-blog \
  --dir ~/ai/projects/aibrainbuilders/blog
```

---

## Step 4: Write 3 real blog posts

### Post 1 - `ai-agents/agents-vs-chatbots/`
- **Title:** "AI Agents Are Not Chatbots: The Difference That Determines ROI"
- **Category:** strategy
- **Audience:** Business decision-makers evaluating AI investment
- **Core argument:** Chatbots answer questions; agents take actions. The distinction changes cost structure, integration requirements, and measurable ROI.
- **Data points:** Task completion rate, cost per interaction, integration touchpoints
- **CTA:** "See our agent builds" → `/ai-agents`

### Post 2 - `training/claude-code-workshop-what-you-build/`
- **Title:** "What You Actually Build in a Claude Code Workshop (Day by Day)"
- **Category:** guide
- **Audience:** Event organizers and corporate training buyers
- **Core argument:** Walk through the full workshop day: morning setup, afternoon agent build, deliverables each attendee leaves with
- **Data points:** Typical attendee output, completion rate, post-workshop adoption stats
- **CTA:** "Book a workshop" → contact form

### Post 3 - `training/choosing-ai-training-format/`
- **Title:** "Executive Suite vs Conference: Which AI Training Format Fits Your Team"
- **Category:** data
- **Audience:** HR/L&D leads and executives choosing training tier
- **Core argument:** Compare all 4 tiers (group size, format, customization, venue, price signal) with a decision matrix
- **Data points:** Tier 1-4 specs, ROI comparison, ideal use case per tier
- **CTA:** "See training levels" → `/training`

---

## Step 5: Run the pipeline

```bash
# After creating blog/index.html and blog/post-template.html:

# Meta-init on the 3 posts
cf-deploy blog meta-init --site aibrainbuilders-blog

# Manually tune categories/descriptions in each meta.json if needed

# Regenerate index card grid
cf-deploy blog index --site aibrainbuilders-blog

# Deploy to aibrainbuilders.com/blog/
cf-deploy update aibrainbuilders-blog

# Regenerate sitemap + llms
cf-deploy sitemap aibrainbuilders
cf-deploy llms aibrainbuilders
```

---

## Verification

```bash
# Confirm /blog/ loads
curl -I https://aibrainbuilders.com/blog/
# → 200

# Confirm a post URL loads
curl -I https://aibrainbuilders.com/blog/ai-agents/agents-vs-chatbots/
# → 200

# SEO audit on a post
cf-deploy seo https://aibrainbuilders.com/blog/ai-agents/agents-vs-chatbots/
# → 0 failures

# SEO audit on blog index
cf-deploy seo https://aibrainbuilders.com/blog/
# → 0 failures
```

---

## Critical files

- `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js` - add `blog register` subcommand
- `~/ai/projects/aibrainbuilders/blog/index.html` - NEW (AiBB-branded listing page)
- `~/ai/projects/aibrainbuilders/blog/post-template.html` - NEW (AiBB-branded post template)
- `~/ai/projects/aibrainbuilders/blog/ai-agents/agents-vs-chatbots/index.html` - NEW
- `~/ai/projects/aibrainbuilders/blog/training/claude-code-workshop-what-you-build/index.html` - NEW
- `~/ai/projects/aibrainbuilders/blog/training/choosing-ai-training-format/index.html` - NEW
- `~/.cf-deploy/sites.json` - updated by `blog register`
