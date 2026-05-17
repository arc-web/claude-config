# OpenBao Remediation Sequence, 2026-05-13

Status: Stage B plan artifact confirmed. No live service config, Docker container, or repository file was changed while gathering this evidence.

Primary sources:
- OpenBao Agent API proxy: https://openbao.org/docs/agent-and-proxy/agent/apiproxy/
- OpenBao Agent process supervisor: https://openbao.org/docs/agent-and-proxy/agent/process-supervisor/
- OpenBao AppRole auto-auth: https://openbao.org/docs/agent-and-proxy/autoauth/methods/approle/
- Supabase CLI reference: https://supabase.com/docs/reference/cli/overview

## Evidence Snapshot

Collection host: local `/Users/home`, remote `ssh zeroclaw`.

Git state:
- `/Users/home`: not a git repository, verified by `git -C /Users/home status --short --branch --untracked-files=all`.
- `/Users/home/ai/arcbao`: branch `main`, tracking `origin/main`, clean, verified by `git -C /Users/home/ai/arcbao status --short --branch --untracked-files=all`.

Live Docker inventory from `ssh zeroclaw 'docker ps --format ...'`:

| Object | Purpose | Current state | Networks | Evidence source | Next action |
|---|---|---|---|---|---|
| `openbao` | OpenBao server | running, healthy, image `openbao/openbao:2.2.0` | `plane_default` only | `docker ps`, `docker inspect` | Add `secrets-clients` in Stage A after sidecars pass Stage C checks. |
| `hermes-agent` | Discord gateway and coordination agent | running, healthy | `hermes-agent_hermes-net`, `plane_default`, `secrets-clients` | `docker ps`, `docker inspect` | Stage C HCL hardening and permission fix. Stage A process-supervisor/env-only GH token migration. |
| `zeroclaw` | ZeroClaw alpha runtime | running, healthy | `plane_default`, `secrets-clients`, `zeroclaw-agent_default` | `docker ps`, `docker inspect` | Stage C HCL hardening and permission fix. Stage A avoid Python dependency assumption. |
| `zeroclaw-bravo` | ZeroClaw bravo runtime | running, healthy | `plane_default`, `secrets-clients`, `zeroclaw-agent_default` | `docker ps`, `docker inspect` | Stage C HCL hardening and permission fix. Stage A avoid Python dependency assumption. |
| `zeroclaw-charlie` | ZeroClaw charlie runtime | running, healthy | `plane_default`, `secrets-clients`, `zeroclaw-agent_default` | `docker ps`, `docker inspect` | Stage C HCL hardening and permission fix. Stage A avoid Python dependency assumption. |
| `approval-webhook` | Approval webhook service | running, no Docker healthcheck | `plane_default` | `docker ps`, `docker inspect` | Stage A remove long-running `BAO_ROLE_ID` and `BAO_SECRET_ID` env exposure. |
| `paperclip-server` | Paperclip server | running, healthy | `plane_default` | `docker ps`, `docker inspect` | Stage A remove long-running `BAO_ROLE_ID` and `BAO_SECRET_ID` env exposure. |
| `daily-win-openbao-broker` | Daily-win broker | running, no Docker healthcheck | `plane_default`, `secrets-clients` | `docker ps`, `docker inspect` | Stage A remove long-running `BAO_ROLE_ID` and `BAO_SECRET_ID` env exposure. |
| `daily-win-broker-named-tunnel` | Named Cloudflare tunnel | running | `secrets-clients` | `docker ps`, `docker inspect` | Keep. Smoke before removing any temporary tunnel remnants. |
| `daily-win-broker-tunnel` | Temporary daily-win tunnel | missing | `n/a` | `docker inspect daily-win-broker-tunnel` | No live container to remove; keep named tunnel verification in Stage A. |

## Confirmed Deviations

| Deviation | Exact object | Current state | Evidence source | Remediation gate |
|---|---|---|---|---|
| AppRole credential files are mode `604` | `/etc/openbao/hermes/{role_id,secret_id}`, `/etc/openbao/zeroclaw-alpha/{role_id,secret_id}`, `/etc/openbao/zeroclaw-bravo/{role_id,secret_id}`, `/etc/openbao/zeroclaw-charlie/{role_id,secret_id}` | `-rw----r-- root:root` | `stat -c "%A %U:%G %n"` on `zeroclaw` | Stage C `chmod 600`. |
| API proxy allows caller token override | Four live sidecar HCL files plus `/Users/home/ai/arcbao/templates/agent.hcl` | `use_auto_auth_token = true` | `grep -nE` and local template read | Stage C set to `"force"`. |
| Supabase management token missing from OpenBao | `secret/data/tool-infra/supabase-access-token` | missing or inaccessible; 1Password `Supabase MCP Master Token` candidates returned management API `403` | `bao kv metadata get`, 1Password candidate validation by status only | Do not add in Stage C unless a real token validates. |
| Long-running service AppRole env exposure | `approval-webhook`, `paperclip-server`, `daily-win-openbao-broker` | env names include `BAO_ROLE_ID` and `BAO_SECRET_ID` | `docker inspect` env-name extraction only | Stage A migrate to supervisor or sidecar injection. |
| Stale cache stanza | Four live sidecar HCL files plus `/Users/home/ai/arcbao/templates/agent.hcl` | `cache {}` present | `grep -nE "cache \\{"` | Stage A remove unless a consumer is documented. |
| Secret ID retained after read | Four live sidecar HCL files plus `/Users/home/ai/arcbao/templates/agent.hcl` | `remove_secret_id_file_after_reading = false` | `grep -nE` | Stage A remove override so copied tmp secret ID is cleared. |
| OpenBao network isolation blocks direct `secrets-clients` DNS | `openbao` | attached only to `plane_default` | `docker inspect`, `docker network inspect` | Stage A attach `openbao` to `secrets-clients`, prove consumers, then decide whether to keep `plane_default`. |

## Decision Record

ZeroClaw images are BusyBox-style runtimes. `docker exec` found BusyBox and `/opt/bin/jq`, but did not find Python. Do not standardize Stage A on Python inside `zeroclaw`, `zeroclaw-bravo`, or `zeroclaw-charlie`. Use OpenBao Agent process supervisor env injection or a separately staged image dependency change.

OpenBao API proxy hardening uses `use_auto_auth_token = "force"` because the OpenBao API proxy docs state that `true` can be overridden by a caller-provided token, while `"force"` ignores an attached token and uses the auto-auth token.

Process-supervisor migration is the Stage A target for long-running services because OpenBao process supervisor mode can render secrets into environment variables for a child process and restart that process on secret updates.

## Rollback Points

Before Stage C or Stage A mutation, create timestamped backups on `zeroclaw`:

```bash
ts=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p /root/openbao-remediation-backups/$ts
tar -C / -czf /root/openbao-remediation-backups/$ts/etc-openbao.tgz etc/openbao
tar -C / -czf /root/openbao-remediation-backups/$ts/docker-service-paths.tgz docker/hermes-agent docker/zeroclaw-agent
tar -C / -czf /root/openbao-remediation-backups/$ts/opt-service-paths.tgz opt/approval-webhook opt/paperclip opt/discord-agent-daily-win opt/openbao opt/openbao-wrapper
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Networks}}' > /root/openbao-remediation-backups/$ts/docker-ps.txt
```

Restore shape:
- For Stage C HCL or mode rollback, restore exact files from `etc-openbao.tgz` and recreate affected sidecars.
- For Stage A compose or entrypoint rollback, restore exact service path tarball, run the matching service `docker compose up -d --force-recreate`, then repeat Stage C checks.
- Do not delete backup directories until all acceptance checks pass and a separate cleanup decision is recorded.

## Stage C Test Matrix

1. Confirm affected containers are running:
   `ssh zeroclaw 'docker ps --format "{{.Names}}\t{{.Status}}\t{{.Networks}}" | grep -E "^(openbao|hermes-agent|zeroclaw|zeroclaw-bravo|zeroclaw-charlie|approval-webhook|paperclip-server|daily-win-openbao-broker|daily-win-broker-named-tunnel)\b"'`
2. Confirm AppRole file modes:
   `ssh zeroclaw 'find /etc/openbao -maxdepth 3 -type f \( -name role_id -o -name secret_id \) -exec stat -c "%a %U:%G %n" {} \;'`
3. Confirm HCL value:
   `ssh zeroclaw 'grep -R "use_auto_auth_token" /etc/openbao/hermes /etc/openbao/zeroclaw-*'`
4. Confirm proxy self lookup in each sidecar:
   `GET http://127.0.0.1:8100/v1/auth/token/lookup-self` inside `hermes-agent`, `zeroclaw`, `zeroclaw-bravo`, and `zeroclaw-charlie`.
5. Forced-token boundary:
   inside each sidecar, send a bogus caller token to `lookup-self`; it must still succeed through the forced auto-auth token.
6. Logs:
   `docker logs --tail 120` for affected services. Verify no auth loops, no secret values, and no startup failures.
7. Audit:
   inspect `/opt/openbao/audit` for expected AppRole login and scoped reads; verify no new broad root-token routine usage.
8. Supabase:
   run only where `supabase` exists. First `test -n "$SUPABASE_ACCESS_TOKEN"` without printing it, then read-only Supabase CLI smoke commands.

## Stage A Implementation Plan

1. Build staging service variants using the Stage C-hardened HCL as the baseline.
2. Replace app-side JSON parsing in BusyBox-style services with OpenBao Agent process supervisor env injection, or explicitly stage an image dependency change. Do not add `jq` as the default migration answer.
3. Remove long-running `BAO_ROLE_ID` and `BAO_SECRET_ID` env exposure from `approval-webhook`, `paperclip-server`, and `daily-win-openbao-broker`.
4. Keep direct AppRole env files only for short-lived host or cron scripts.
5. Remove `cache {}` unless a documented consumer requires it. If retained, document cache clear and rotation behavior.
6. Remove `remove_secret_id_file_after_reading = false` so the copied tmp secret ID is cleared after read.
7. Attach `openbao` to `secrets-clients`, prove all consumers still work, then decide whether `plane_default` can be removed.
8. Keep `daily-win-broker-named-tunnel`; remove only verified temporary tunnel remnants after named tunnel health and routing pass.
9. Replace Hermes persistent `gh auth login` with env-only `GH_TOKEN` unless a documented workflow requires persistent auth.

## Final Acceptance Tests

- Staging containers pass the Stage C test matrix before live rollout.
- Live rollout recreates one service at a time with rollback backups preserved.
- No long-running app container exposes `BAO_ROLE_ID` or `BAO_SECRET_ID` in Docker env.
- Required runtime env vars are present by name and non-empty, verified without printing values.
- OpenBao audit paths match expected scoped reads.
- Daily-win broker health, named tunnel routing, and Worker-to-broker smoke pass.
- Supabase smoke script passes in a CLI-capable runtime after a valid `SUPABASE_ACCESS_TOKEN` exists.

## Completion Record

Completed at 2026-05-13 04:43 UTC on `zeroclaw`.

Rollback points created:
- `/root/openbao-remediation-backups/20260513T042453Z`
- `/root/openbao-remediation-backups/20260513T043304Z-stage-a-pre`

Changed live files:
- `/etc/openbao/hermes/agent.hcl`
- `/etc/openbao/zeroclaw-alpha/agent.hcl`
- `/etc/openbao/zeroclaw-bravo/agent.hcl`
- `/etc/openbao/zeroclaw-charlie/agent.hcl`
- `/etc/openbao/approval-webhook/{role_id,secret_id,agent.hcl}`
- `/etc/openbao/paperclip/{role_id,secret_id,agent.hcl}`
- `/etc/openbao/daily-win-openbao-broker/{role_id,secret_id,agent.hcl}`
- `/docker/hermes-agent/entrypoint-openbao.sh`
- `/docker/zeroclaw-agent/entrypoint-openbao.sh`
- `/opt/approval-webhook/entrypoint-openbao.sh`
- `/opt/approval-webhook/docker-compose.yml`
- `/opt/paperclip/entrypoint-openbao.sh`
- `/opt/paperclip/docker-compose.yml`
- `/opt/paperclip/.env`
- `/opt/discord-agent-daily-win/broker/entrypoint-openbao.sh`
- `/opt/discord-agent-daily-win/broker/docker-compose.yml`
- `/opt/discord-agent-daily-win/broker/server.js`
- `/opt/discord-agent-daily-win/broker/.env`

Changed local repo file:
- `/Users/home/ai/arcbao/templates/agent.hcl`

Verification results:
- AppRole credential files are `600`. ZeroClaw credential files are owned by UID/GID `65534` so the non-root BusyBox containers can read them while preserving mode `600`.
- All sidecar HCL files use `use_auto_auth_token = "force"` and no longer contain `cache {}` or `remove_secret_id_file_after_reading = false`.
- `approval-webhook`, `paperclip-server`, and `daily-win-openbao-broker` no longer expose `BAO_ROLE_ID` or `BAO_SECRET_ID` in Docker config env.
- `openbao` is attached to `plane_default` and `secrets-clients`.
- Forced-token proxy lookup returned HTTP `200` in all seven sidecar-backed containers.
- Running containers after rollout: `openbao`, `hermes-agent`, `zeroclaw`, `zeroclaw-bravo`, `zeroclaw-charlie`, `approval-webhook`, `paperclip-server`, `daily-win-openbao-broker`, and `daily-win-broker-named-tunnel`.
- `paperclip-server`, `hermes-agent`, and all ZeroClaw containers are healthy according to Docker health checks.
- `approval-webhook` responded on `/health`.
- `daily-win-openbao-broker` responded on local `/healthz` and `https://daily-win-broker.stackpack.app/healthz`.
- Worker health passed at `https://discord-agent-daily-win-interactions.advertisingreportcard.workers.dev/healthz`.
- Broker OpenBao read smoke returned field names only for `discord-agent/daily-win`: `application_id,discord_public_key,operator_user_id,wins_channel_id`.
- OpenBao audit after Stage A showed expected AppRole logins and scoped reads, with no root-token request rows after 2026-05-13 04:33 UTC in the checked tail.
- Supabase access-token write was skipped because candidate 1Password tokens returned Supabase Management API `403`, `secret/data/tool-infra/supabase-access-token` remained missing, and no affected runtime currently has the `supabase` CLI installed.

Stage A adjustment:
- ZeroClaw remains BusyBox-only and does not use Python. Its OpenBao JSON extraction now uses the already-present `/opt/bin/jq` binary instead of an ad hoc `sed` parser. No image dependency was added during this rollout.
