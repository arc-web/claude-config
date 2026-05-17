---
name: OpenBao admin write pattern - root token from 1P ARC vault
description: How to write secrets to OpenBao on zeroclaw. Root token lives in 1P ARC item hl23px33remaz2xecl5ecvvaem. AppRoles are read-only, must use root for writes/policies.
type: reference
originSessionId: 5e4c15fa-4ed9-4e70-b9de-f4f25e3e31ae
---
# OpenBao admin writes on zeroclaw

**Root token location (canonical write auth):**
- 1Password vault: ARC
- Item ID: `hl23px33remaz2xecl5ecvvaem` (verified VALID 2026-05-06 - `bao token lookup` returns root policy, ttl=0)
- Item title: "OpenBao Unseal Material — ARC" (renamed from earlier "OpenBao Root Token (temp)"; verified 2026-05-01)
- Field name: `root_token` (not `password` or `credential` - custom field)
- Also has: `unseal_key`, `bao_addr` (`http://127.0.0.1:8200`), `bao_addr_container` (`http://openbao:8200`)

**Why root needed:** All AppRoles (host-scripts, hermes, zeroclaw-alpha/bravo, approval-webhook, fathom, paperclip, cron-scripts) are scoped read-only on their own paths. None can write secrets or manage policies. Confirmed via `sys/capabilities-self` test 2026-04-28.

**Write pattern (one-liner from local machine):**
```bash
ROOT=$(op item get hl23px33remaz2xecl5ecvvaem --vault ARC --fields root_token --reveal)
SECRET=$(op item get <source-item> --vault ARC --fields credential --reveal)
ssh zeroclaw "VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN='$ROOT' bao kv put secret/<path> value='$SECRET' source=1p:<source-item-id> owner=<owner>"
```

**Field convention:** Existing entrypoint scripts (e.g. `/docker/hermes-agent/entrypoint-openbao.sh`) read `.data.data.value` via the `fetch()` function. Always use field name `value` for the primary secret to match the existing pattern. Add metadata fields freely (`source`, `owner`, `scopes`, etc.) - they don't break fetch.

**Read pattern (from VPS host using AppRole):**
```bash
source /opt/openbao-wrapper/lib.sh
export BAO_AUTH_FILE=/etc/openbao/host-scripts.env
bao_auth && bao_get <path> <field>
```

**Read pattern (inside container via agent proxy):**
```bash
curl -s http://127.0.0.1:8100/v1/secret/data/<path> | jq -r .data.data.value
```
No auth header - proxy injects token via auto-auth.

**AppRole credential locations on zeroclaw:**
- `/etc/openbao/host-scripts.env` - shell-style env for `bao_auth`
- `/etc/openbao/{hermes,zeroclaw-alpha,zeroclaw-bravo}/{role_id,secret_id,agent.hcl}` - per-container agents
- `/etc/openbao/{approval-webhook,cron-scripts,fathom,paperclip}.env` - other host-side AppRoles

**1Password backup of AppRole creds (ARC vault):**
- `OpenBao AppRole - hermes` (`s762kv5ax6bryjniwxuewdiqry`)
- `OpenBao AppRole - zeroclaw-alpha` (`3x4cawmo6lmnlvljklvy72ennu`)
- `OpenBao AppRole - zeroclaw-bravo` (`dftj5xd2dhhr4ycp66dtxhpwsq`)
- `OpenBao AppRole - host-scripts` (`teydke7azjvf6rdopku4grhvg4`)
- `OpenBao AppRole - approval-webhook`, `OpenBao AppRole - paperclip`, `OpenBao AppRole - fathom`

**Network:** OpenBao container on `plane_default` Docker network, bound to `127.0.0.1:8200` on host only.

**Wrapper has no `bao_put`** - `/opt/openbao-wrapper/lib.sh` only provides `bao_auth` + `bao_get`. For writes, use `bao kv put` directly with `VAULT_TOKEN` env.
