---
name: Local directory structure - ~/ai/ self-contained projects
description: ~/ai/<project>/ is the unit. Every project is a self-contained GitHub repo. No shared directories. No monorepo. aimacpro is legacy being decomposed.
type: reference
originSessionId: 87ec28e6-b43a-44b4-a8dc-df3581dd3338
---
## The rule

`~/ai/<category>/<project-name>/` is the unit. Treat every project directory exactly like a freshly cloned GitHub repo - it contains 100% of what it needs and imports nothing from outside itself.

## Structure

```
~/ai/
  agents/{accounting,comms,creative,development,mcp,ppc,seo,web}/  (verified 2026-05-01; business/platform/infrastructure/meta retired)
  tools/{security,github,browser,ai,media}/
  platforms/
  apps/{products,workshop-apps}/
  docs/
  community/
  infra/
  forks/
  clients/                (client site repos, e.g. therappc-site; extracted from cloudflare_agent/clients/)
```

Category subdirectories are local filing only. They are not dependency containers. A project never imports from a sibling project's directory.

## Creating a new project

```bash
gh repo create arc-web/<name> --private --description "<desc>"
gh repo edit arc-web/<name> --add-topic cat-<category>,sub-<subcategory>
cd ~/ai/<category>/<subcategory>/
gh repo clone arc-web/<name>
```

## What goes inside a project

Everything it needs: code, tools/, apps/, tests/, requirements.txt or package.json, .env.1p (op:// refs only). No venv/, node_modules/, dist/, secrets in git.

## Credentials

`.env.1p` with `op://ARC/<item>/credential` refs. Use `op run --env-file=.env.1p` to inject at runtime. No shared op_loader.py - each project handles credentials independently.

## aimacpro

`~/ai/workspaces/aimacpro/` is a legacy monorepo. Do not add anything new to it. Its contents are extraction targets - each piece becomes its own `~/ai/<category>/<project>/`.

Full registry: `~/ai/CATEGORIES.md`

_Established 2026-04-20. Architecture decision: aimacpro does not exist as a concept going forward._
