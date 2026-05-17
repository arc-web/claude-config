---
name: Agent credential access map (verified 2026-04-28)
description: Per-agent OpenBao auth method, policy, paths. Use to plan any credential wiring without re-discovering infrastructure. Hermes/zeroclaw/zeroclaw-bravo use bao agent sidecar on 8100; host-side cron uses /etc/openbao/*.env + /opt/openbao-wrapper/lib.sh. Claude Code uses root token from 1P ARC for writes only.
type: reference
originSessionId: 11d73955-4195-456c-b3f4-7f63a576b646
---
# Agent credential map

Verified live on zeroclaw 2026-04-28. AppRoles all read-only; writes need root token (1P ARC `hl23px33remaz2xecl5ecvvaem` field `root_token` - **VALID as of 2026-05-06**, root policy, no TTL).

## Container agents (bao agent sidecar, proxy on 127.0.0.1:8100)

| Container | Policy | Read scope | Creds dir |
|---|---|---|---|
| hermes-agent | hermes | secret/data/{hermes,shared,tool-infra}/* | /etc/openbao/hermes/{role_id,secret_id,agent.hcl} |
| zeroclaw | zeroclaw-alpha | secret/data/{zeroclaw-alpha,shared,tool-infra}/* | /etc/openbao/zeroclaw-alpha/ |
| zeroclaw-bravo | zeroclaw-bravo | secret/data/{zeroclaw-bravo,shared,tool-infra}/* | /etc/openbao/zeroclaw-bravo/ |

Inside container: `curl -s http://127.0.0.1:8100/v1/secret/data/<path> | jq -r .data.data.value` (no auth header).

## Host-side AppRoles (env files, no proxy)

| Role | Policy | Read scope | Env file |
|---|---|---|---|
| host-scripts | host-scripts | secret/data/{host-scripts,shared}/* | /etc/openbao/host-scripts.env |
| cron-scripts | cron-scripts | secret/data/{shared,tool-infra}/* | /etc/openbao/cron-scripts.env |
| approval-webhook | approval-webhook | secret/data/approval-webhook/* | /etc/openbao/approval-webhook.env |
| fathom | fathom | secret/data/fathom/* | /etc/openbao/fathom.env |
| paperclip | paperclip | secret/data/paperclip/* | /etc/openbao/paperclip.env |

Read pattern: `source /opt/openbao-wrapper/lib.sh; export BAO_AUTH_FILE=/etc/openbao/<role>.env; bao_auth >/dev/null && bao_get <path> <field>`.

## Claude Code (local Mac)

- AppRole: `claude-code-local` - own fingerprint in audit log (not zeroclaw)
- Bootstrap: 1P ARC item "OpenBao AppRole - claude-code-local" fields `role_id` + `secret_id`
- Reads: direct HTTP to `https://vault.aibrainbuilders.com` (Cloudflare Tunnel → openbao container)
- Policy: `claude-code-read` - covers shared/*, hosting/*, tool-infra/*, hermes/*, search-console/*, projects/*
- Token TTL: 8h
- Writes/admin: root token from 1P ARC `hl23px33remaz2xecl5ecvvaem` field `root_token`, via SSH to zeroclaw

## GitHub Actions (plane-sync workflow)

- AppRole: `github-actions` role, policy: `plane-read`
- plane-read policy: `secret/data/shared/plane-api-key` read-only
- role_id/secret_id stored in OpenBao at `secret/shared/github-actions-approle`
- Workflow fetches token at runtime via `vault.aibrainbuilders.com/v1/auth/approle/login`
- GitHub Secrets set: `OPENBAO_ROLE_ID`, `OPENBAO_SECRET_ID` on arc-web/review-workflows + arc-web/reportcard-agent

## Human team members (userpass auth, 2026-05-17)

- Endpoint: `https://vault.aibrainbuilders.com` (Cloudflare Tunnel → openbao:8200 on secrets-clients network)
- Auth: `POST /v1/auth/userpass/login/<username>` with `{"password": "<pass>"}`
- Policy: `team-read` (secret/data/{shared,hosting,tool-infra}/*)
- Users: `mike` (1P ARC "OpenBao userpass - mike"), `patrick` (1P ARC "OpenBao userpass - patrick")

## Top-level secret paths

`accounting/ approval-webhook/ code/ cron/ discord/ fathom/ hermes/ host-scripts/ hosting/ human-only/ paperclip/ projects/ shared/ tool-infra/ trading/ zeroclaw-alpha/ zeroclaw-bravo/`

## Discord bot tokens in OpenBao (added 2026-05-12)

All 6 Discord bot tokens now in OpenBao. Two paths:
- `secret/discord/<slug>` - root-only read (reference copy)
- `secret/shared/discord-<slug>` - host-scripts + root readable (use these)

| Slug | Server | 1P backup |
|------|--------|-----------|
| `discord-arc-web` | ARC guild (arc-web bot - EXPIRED, needs refresh) | ARC vault `fzyoo2zgu3mfpgsvucisn3bnfa` |
| `discord-stackpack` | StackPack.app | ARC vault `oml27d2saooujsrjvqmyg3pnr4` |
| `discord-claudeconference` | Conference | ARC vault `w5n6fih3jkg7qgl5h6hnmssmd4` |
| `discord-zeroclaw-alpha` | ARC channel management | Zeroclaw `u66axhap3bx6onbyp4ycqpgx4u` |
| `discord-zeroclaw-bravo` | - | Zeroclaw `qt63vj6w7b6qaonwdrvazzywhe` |
| `discord-zeroclaw-charlie` | ARC reads + posts | Zeroclaw `5elrtua2364vr2oogwqp4wch5q` |

Read via host-scripts: `ssh zeroclaw "export BAO_ADDR=http://127.0.0.1:8200 && source /opt/openbao-wrapper/lib.sh && export BAO_AUTH_FILE=/etc/openbao/host-scripts.env && bao_auth >/dev/null 2>&1 && bao_get shared/discord-arc-web"`

## Field convention

All consumed secrets use field `value`. Entrypoint `fetch()` helpers parse `.data.data.value`. Add metadata fields freely (`source`, `owner`, `scopes`).
