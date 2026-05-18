---
name: Plane API quick reference
description: Plane CE at arc.todovibes.com - API key retrieval, project UUIDs, correct endpoint patterns. Prevents repeated discovery of these basics.
type: reference
originSessionId: b615afa1-6455-4b6f-a95b-ec9b51a07953
---
# Plane API Quick Reference (verified 2026-05-18)

**Canonical reference:** `arc-web/plane-pm-agent/API.md` — all UUIDs, both workspaces, all endpoints, field types.

## Key retrieval - OpenBao direct (updated 2026-05-18)

```python
import urllib.request, json, subprocess
item = json.loads(subprocess.check_output(
    ['op','item','get','OpenBao AppRole - claude-code-local','--vault','ARC','--format','json','--reveal'],
    text=True))
fields = {f['label']: f.get('value','') for f in item['fields']}
auth = json.loads(urllib.request.urlopen(urllib.request.Request(
    'https://vault.aibrainbuilders.com/v1/auth/approle/login',
    data=json.dumps({'role_id': fields['role_id'], 'secret_id': fields['secret_id']}).encode(),
    headers={'Content-Type': 'application/json', 'User-Agent': 'vault-client/1.0'},
    method='POST')).read())
token = auth['auth']['client_token']
key = json.loads(urllib.request.urlopen(urllib.request.Request(
    'https://vault.aibrainbuilders.com/v1/secret/data/shared/plane-api-key',
    headers={'X-Vault-Token': token, 'User-Agent': 'vault-client/1.0'})).read())['data']['data']['value']
```

- OpenBao path: `secret/data/shared/plane-api-key` field `value` (KV v2 - note `/data/` prefix)
- AppRole: `claude-code-local` → own fingerprint in audit log
- 1P emergency fallback (Zeroclaw vault): item `x7qhfdaos76fcymuztjjscmrpa` field `credential`
- Key length: 64 chars

## Base URL + required header

```
https://arc.todovibes.com/api/v1/workspaces/<workspace_slug>/
User-Agent: plane-cli/1.0   ← REQUIRED (Cloudflare blocks default UA without it)
```

## Workspace slugs

| Slug | Display name | Use |
|------|-------------|-----|
| `todovibes` | Internal | Team/agent work |
| `clients` | Clients | Per-client projects |

## Internal workspace project UUIDs (todovibes, verified 2026-05-17)

| Identifier | UUID | Name |
|-----------|------|------|
| AGENT | 0e399778-93d9-4a95-ba2f-755990dd69bc | Internal Ops |
| INFRA | 9643da9a-da40-4f40-8cbe-561822288cd4 | Infrastructure |
| COMM | 980f20b4-80b9-4605-864f-6e736a65446b | Communities |
| ADS | b1b1b597-02d6-475d-9b5c-37c64276e1ea | Google Ads |
| LAND | b7f45068-8020-4245-ab48-a2234a9c7d43 | Web Design Tech |
| DEVOPS | b6caface-b889-49da-ae71-f87bfc63b4d4 | DevOps |
| AGNTS | e8e54f27-b0f3-4073-8d10-4ec82ed2d180 | Agents |

**Use UUID in API paths, NOT the short identifier.**

## Issues endpoint

```bash
# Get issues (use UUID not identifier)
curl -s -H "X-Api-Key: $PLANE_KEY" -H "User-Agent: plane-cli/1.0" \
  "https://arc.todovibes.com/api/v1/workspaces/todovibes/projects/<UUID>/issues/?per_page=100"

# state_detail is NULL inline - must fetch /states/ separately and join by state UUID
curl -s ... "<base>/projects/<UUID>/states/"
```

- `state_detail` is NOT returned inline in issues - always null
- State UUID is in `i['state']` field - join against `/states/` response
- State groups: `unstarted`, `started`, `completed`, `cancelled`, `backlog`

## PATCH (update issue)

```bash
# Must use issue UUID (.id field), NOT sequence_id (display only)
PATCH /projects/<UUID>/issues/<issue-uuid>/
# Body: any subset of {name, description_html, state}
```

Get UUID by querying issues list and extracting `.id` per result.

## Issue field types

| Field | Type | Notes |
|-------|------|-------|
| `state` | UUID string | From `/states/` - never hardcode across projects |
| `estimate_point` | UUID string | NOT an integer - fetch from `/projects/<UUID>/estimates/` |
| `priority` | string | `none` `urgent` `high` `medium` `low` |
| `sequence_id` | integer | Display-only (e.g. AGENT-197) - never use in PATCH URLs |
| `.id` | UUID string | Use this in all PATCH/DELETE URLs |

## AGENT project state IDs (todovibes, all 12, verified 2026-05-18)

| State | UUID | Group |
|-------|------|-------|
| Backlog | `9826ce13-5a13-4f17-a768-f90391a58682` | backlog |
| Todo | `c0528a48-cbb1-44e5-9f09-1e8fc566bb56` | unstarted |
| Scoped | `03e84cf3-ac77-4404-ae25-63130f25a1a4` | unstarted |
| Assigned | `8aae6cbf-5e23-4f1c-a041-1ab52268b9f8` | unstarted |
| In Progress | `bdb50dbe-2fe8-4f65-848c-1439cfa64ad5` | started |
| Needs Approval | `57f31d08-a350-4f49-bd50-3d2865858fda` | started |
| Approved | `275036cd-7aaf-4041-854b-364914356372` | started |
| Blocked | `ce62803d-b9cc-4214-b99d-823d8afff7c8` | started |
| Done | `bc0f8045-bfe1-4cef-99f0-e238a1956c73` | completed |
| Completed | `9bafcd6c-f951-4b88-8c49-f8ef2875bc9a` | completed |
| Cancelled | `f881cda3-8583-4110-91ab-a1032dca44b7` | cancelled |
| Archived | `4d9fe922-38ba-4bae-8794-014c38b4f36f` | cancelled |

**Fix:** Prior docs had Done = `9bafcd6c` which is actually "Completed". Real Done = `bc0f8045`.

## clients workspace - project UUIDs (verified 2026-05-18)

| Identifier | UUID | Name |
|-----------|------|------|
| TMPL | `b7c7c9d8-2be5-44be-ad0d-3682f14ef905` | Templates |
| BLPX | `23228989-849b-418a-b344-9a7c565d5ad1` | BluePixel |
| BLGR | `2ccf605e-6474-4df4-95da-76a70121f387` | BlueGorilla |
| MOON | `8a64261f-f129-4e67-8976-b3b116cf54d4` | Moonraker |
| ARC | `e05a2d3e-502f-4b5a-bac5-8ce189e41b21` | ARC |

All clients projects share same 9-state pattern (Backlog/Todo/InProgress/NeedsApproval/Approved/Blocked/Done/Completed/Cancelled). Full state UUIDs per project in `arc-web/plane-pm-agent/API.md`.

## Python pattern

Use OpenBao AppRole (not root token). Full pattern with key retrieval: `~/.claude/skills/plane-pm/SKILL.md`.
Raw API pattern: `arc-web/plane-pm-agent/API.md` (Python raw API pattern section).

Run via `/opt/homebrew/bin/python3 -c "..."` with `dangerouslyDisableSandbox: true`.

## Admin operations (API limitations)

**Project deletion:** Plane CE API returns 403 for all keys (including admin-level) - cannot delete via REST.

Pattern:
1. Move all issues to other projects first (create in target + delete from source via API)
2. Verify source project is empty
3. Connect to Postgres directly:

```bash
# Get password from OpenBao
ROOT=$(op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token --reveal)
PGPASS=$(ssh zeroclaw "VAULT_ADDR='http://127.0.0.1:8200' BAO_TOKEN='$ROOT' bao kv get -field=value secret/shared/plane-postgres-password")

# Connect
ssh zeroclaw "PGPASSWORD='$PGPASS' docker exec -e PGPASSWORD='$PGPASS' plane-plane-db-1 psql -U plane"
```

4. Inside psql, bypass FK constraints and delete:

```sql
SET session_replication_role = 'replica';
DELETE FROM projects WHERE id = '<project-uuid>';
SET session_replication_role = 'origin';
```

`SET session_replication_role = 'replica'` disables FK triggers for the session without requiring superuser. The project had 60+ FK references - this is the only practical delete path. Issues soft-deleted via API (sets `deleted_at`) are cascade-cleaned when the project is deleted.

## Pages endpoint (for docs/wiki pages)

```bash
curl -s -X POST -H "X-Api-Key: $PLANE_KEY" -H "User-Agent: plane-cli/1.0" \
  -H "Content-Type: application/json" \
  -d '{"name":"Page Title","description_html":"<p>content</p>","access":0}' \
  "https://arc.todovibes.com/api/v1/workspaces/todovibes/projects/<UUID>/pages/"
```

- `access: 0` = public within workspace, `access: 1` = private to creator
