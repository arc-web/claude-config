---
name: arc-web GitHub organization structure
description: Central repo structure — arc-web holds all agents/apps/tools, each repo is one project, aimacpro/arc-web are infrastructure
type: reference
originSessionId: dad85fa9-1492-4d97-9506-adc535ebf590
---
## Org Structure

**arc-web** (GitHub org) = central storage for all projects
- Each repository under arc-web represents ONE agent, app, tool, or standalone project
- arc-web itself is NOT an agent
- aimacpro is NOT an agent — it's local orchestration/infrastructure
- Clean separation: arc-web repos are distributed/shareable/standalone; aimacpro is local coordination

## Key Distinction

- **arc-web repos**: standalone, versioned, can be shared/deployed anywhere
- **aimacpro** (`~/ai/workspaces/aimacpro/`): local monorepo for orchestration glue, agent configs, swarm coordination - NOT versioned/shared in same way

Each arc-web repo gets its own:
- README describing the agent/app/tool
- CI/CD pipeline
- Versioning/releases
- Deployment target

## Local organization

All repos live under `~/ai/` organized by category:
- `~/ai/agents/{accounting,comms,creative,development,mcp,ppc,seo,web}/` (verified 2026-05-01; business/platform/infrastructure/meta subcats do not exist)
- `~/ai/tools/{security,github,browser,ai,media}/`
- `~/ai/platforms/`
- `~/ai/apps/{products,workshop-apps}/`
- `~/ai/docs/`
- `~/ai/community/`
- `~/ai/infra/`
- `~/ai/workspaces/` (aimacpro, aimacmini)
- `~/ai/forks/`

Each repo has GitHub topic tags `cat-<category>` and `sub-<subcategory>`. Query: `gh repo list arc-web --topic cat-agents`
