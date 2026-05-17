---
name: Hermes GitHub access - via OpenBao + gh CLI
description: Hermes container has git + gh CLI installed and auto-authenticates as arc-web on startup using PAT from OpenBao secret/hermes/github-pat.
type: project
originSessionId: 5e4c15fa-4ed9-4e70-b9de-f4f25e3e31ae
---
# Hermes GitHub access

Set up 2026-04-28. Wiring staged on disk; **image rebuild pending** as of 2026-05-01 audit - running `hermes-agent:v0.8.0` image predates Dockerfile edit, has no `git`/`gh` installed. Until rebuilt, Hermes cannot clone/push/PR.

## What's wired (on-disk; not yet baked into running image)

- **Dockerfile** at `/docker/hermes-agent/repo/Dockerfile` on zeroclaw: adds `git`, `gh`, `jq`, `curl` via apt + GitHub CLI repo. Image tag `hermes-agent:v0.8.0` exists but was built before this edit - rebuild required.
- **OpenBao secret**: `secret/hermes/github-pat` field `value` = fine-grained PAT (originally from 1P item `xgdu6rg4kk2dshwzsjyd5tomey` titled "GitHub Fine-Grained PAT - github_agent"). Auth scope unverified - host AppRole `bao_get` returns "Failed to fetch"; root token returns 403 on this path. Confirm reachable from inside hermes-agent container before relying.
- **Entrypoint** (`/docker/hermes-agent/entrypoint-openbao.sh` bind-mounted): fetches PAT via existing `fetch()` helper, runs `gh auth login --with-token`, sets git user/email + credential helper, exports `GH_TOKEN` and `GITHUB_TOKEN`

## To activate

```bash
ssh zeroclaw 'cd /docker/hermes-agent/repo && docker build -t hermes-agent:v0.8.0 . && docker restart hermes-agent'
ssh zeroclaw 'docker exec hermes-agent gh auth status'
```

## Identity

- Authenticates as GitHub account `arc-web` (same as local Claude Code)
- Git author: `Hermes Agent <hermes@arc-web.local>`
- Per github-pr-flow rules: branch prefix `hermes/<topic>`, trailer `Co-Authored-By: Hermes Agent <hermes@arc-web.local>`

## Verify

```bash
ssh zeroclaw 'docker exec hermes-agent gh auth status'
ssh zeroclaw 'docker exec hermes-agent gh repo list arc-web --limit 5'
```

## Token rotation

To rotate the PAT, regenerate fine-grained PAT for `arc-web` org, then:
```bash
ROOT=$(op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token --reveal)
ssh zeroclaw "VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN='$ROOT' bao kv put secret/hermes/github-pat value='<new-pat>' owner=arc-web scopes=fine-grained"
ssh zeroclaw 'docker restart hermes-agent'
```

## Backups

- Dockerfile pre-edit: `/docker/hermes-agent/repo/Dockerfile.bak.20260428`
- Entrypoint pre-edit: `/docker/hermes-agent/entrypoint-openbao.sh.bak.20260428`
