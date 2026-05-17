# Discord WLW Channel Creation - Post-Mortem & Fix Plan

**Context:** Created 8 WLW client channels in the ARC Discord server. Multiple mistakes made: wrong bots, custom scripts instead of existing tooling, duplicate channels, credential anti-patterns, missing servers.json updates, no OpenBao usage. This plan fixes all of it.

---

## Mistake Inventory

| # | Mistake | Root Cause | Impact |
|---|---------|-----------|--------|
| 1 | Used Zeroclaw Alpha/Charlie bots for ARC server | Should have used `arc-web` bot; Charlie=read-only, Alpha=partial perms | Alpha could POST but not GET; used wrong credentials entirely |
| 2 | arc-web bot token in 1P ARC vault is **expired/invalid** (401) | Token not rotated/refreshed | Couldn't use the correct bot at all |
| 3 | Wrote custom urllib/curl scripts | Didn't check `discord_api.py` — `create_channel()` and `delete_channel()` already exist | 4x custom script attempts, all broken |
| 4 | Bash emoji encoding → silent curl success + Python parse failure | Python stdout UnicodeDecodeError on emoji bytes | **Duplicate channels created (8 extras)** |
| 5 | Hardcoded bot tokens in `/tmp/*.py` scripts | Should fetch from OpenBao/1P at runtime | Credentials stored locally (now gone, but happened) |
| 6 | OpenBao never checked | Should check env→1P→OpenBao; skipped straight to 1P | Violated credential discovery order |
| 7 | servers.json never updated | Forgot after channel creation | WLW channels can't be referenced by alias in agents |
| 8 | Initial emoji set was non-boat (🌿🎿🏖☀🌅) for marine companies | Picked thematic emojis for company name, not industry | User had to correct; two rounds of channel creation |
| 9 | Test channels (`test-perm-check`) leaked | Created perm-check channels, cleanup was incomplete | Temporarily polluted the WLW category |

---

## Current State (post-session cleanup)

**WLW category (1478284078439596174) now has:**
```
🌊-wlw-bpm-onewatermarine       (original)
🪟-wlw-bpm-wrightsimpactwindow   (original)
⛵-wlw-bpm-gardenstate           (new - boat emoji)
🚢-wlw-bpm-norfolkmarine         (new - boat emoji)
🏄-wlw-bpm-slalomshop            (new - boat emoji)
🚤-wlw-bpm-smgboats              (new - boat emoji)
🌊-wlw-bpm-southshore            (new - boat emoji)
🛥-wlw-bpm-sundancemarine        (new - boat emoji)
🛳-wlw-bpm-sunrisemarine         (new - boat emoji)
⚓-wlw-bpm-onewateryachtgroup    (new - boat emoji)
```

**Confirmed:** All 8 new channels → `🚤` (speedboat). Need to rename 7 of the 8 (smgboats already has 🚤).

---

## Fix Plan

### Step 0 — Rename WLW Channels to Uniform 🚤 Emoji

**7 channels need renaming** (smgboats already has 🚤):

| Current Name | New Name |
|---|---|
| ⛵-wlw-bpm-gardenstate | 🚤-wlw-bpm-gardenstate |
| 🚢-wlw-bpm-norfolkmarine | 🚤-wlw-bpm-norfolkmarine |
| 🏄-wlw-bpm-slalomshop | 🚤-wlw-bpm-slalomshop |
| 🌊-wlw-bpm-southshore | 🚤-wlw-bpm-southshore |
| 🛥-wlw-bpm-sundancemarine | 🚤-wlw-bpm-sundancemarine |
| 🛳-wlw-bpm-sunrisemarine | 🚤-wlw-bpm-sunrisemarine |
| ⚓-wlw-bpm-onewateryachtgroup | 🚤-wlw-bpm-onewateryachtgroup |

**Method:** `discord_api.py` `edit_channel(channel_id, name=<new_name>)` — use arc-web bot (after Step 1 token refresh).

---

### Step 1 — Refresh arc-web Bot Token

**Problem:** Token in `op://ARC/Discord Bot Token - arc-web/credential` returns 401.

**Fix:**
1. Go to Discord Developer Portal → arc-web application → Bot → Reset Token
2. Update 1P ARC vault item `fzyoo2zgu3mfpgsvucisn3bnfa` with new token
3. Verify: `op run --env-file=~/ai/agents/comms/discord_agent/.env.1p.arc -- python3 -c "from discord_api import DiscordClient; c = DiscordClient('arc'); print(c.get_channels()[:2])"`

**Files:** `~/.env.1p.arc` (no change needed — just update 1P item)

---

### Step 2 — Migrate Discord Tokens to OpenBao

**Problem:** All Discord bot tokens live in 1P only. OpenBao has zero Discord entries. Should be canonical source.

**Migration plan (write to OpenBao, keep 1P as backup):**

```bash
# Pattern: bao kv put secret/discord/<slug> value="<token>"
bao kv put secret/discord/arc-web value="<refreshed token from step 1>"
bao kv put secret/discord/stackpack value="$(op read 'op://ARC/Discord Bot Token - StackPack.app/credential')"
bao kv put secret/discord/claudeconference value="$(op read 'op://ARC/Discord Bot Token - claudeconference/credential')"
bao kv put secret/discord/zeroclaw-alpha value="$(op read 'op://Zeroclaw/ZeroClaw Alpha Discord Bot/discord_token')"
bao kv put secret/discord/zeroclaw-bravo value="$(op read 'op://Zeroclaw/ZeroClaw Bravo Discord Bot/discord_token')"
bao kv put secret/discord/zeroclaw-charlie value="$(op read 'op://Zeroclaw/ZeroClaw Charlie Discord Bot/discord_token')"
```

**OpenBao root token:** `op item get hl23px33remaz2xecl5ecvvaem --vault ARC --reveal --fields root_token`

---

### Step 3 — Update config_loader.py to Check OpenBao First

**File:** `~/ai/agents/comms/discord_agent/config_loader.py`

**Change credential resolution order:**
```
BEFORE: env var → 1P direct call
AFTER:  env var → OpenBao (ssh zeroclaw bao_get) → 1P fallback
```

**New resolution logic to add (before the 1P call):**
```python
# Try OpenBao first
import subprocess
op_slug = {"arc": "arc-web", "stackpack": "stackpack", "conference": "claudeconference"}
slug = op_slug.get(server_name, server_name)
try:
    result = subprocess.run(
        ["ssh", "zeroclaw",
         f"source /opt/openbao-wrapper/lib.sh && bao_auth >/dev/null 2>&1 && bao_get discord/{slug} value"],
        capture_output=True, text=True, timeout=10
    )
    if result.returncode == 0 and result.stdout.strip():
        token = result.stdout.strip()
except Exception:
    pass  # fall through to 1P
```

---

### Step 4 — Update servers.json with WLW Channel Aliases

**File:** `~/ai/agents/comms/discord_agent/servers.json`

**Add to `arc.aliases`:**
```json
"wlw-bpm-gardenstate": "1503445447170326601",
"wlw-bpm-norfolkmarine": "1503445450680828055",
"wlw-bpm-slalomshop": "1503445453516050575",
"wlw-bpm-smgboats": "1503445457295376507",
"wlw-bpm-southshore": "1503445460608745502",
"wlw-bpm-sundancemarine": "1503445463586705418",
"wlw-bpm-sunrisemarine": "1503445483140550846",
"wlw-bpm-onewateryachtgroup": "1503445487292776598"
```

*(Channel IDs confirmed from API response in session)*

---

### Step 5 — Fix Agent Channel-Creation Workflow

**Problem:** Agents improvised with custom scripts instead of using the existing tooling.

**`discord_api.py` already has (no code change needed):**
- `create_channel(name, channel_type, category_id)` — line ~368
- `delete_channel(channel_id)` — line ~409
- `get_categories()` — fetch all category channels

**`community_ops.py` already exposes:**
- `channels scaffold <yaml>` — create from YAML
- `channels list` — with categories

**What IS missing:** A `channels create <name> --category <name>` convenience command in community_ops.py.

**Fix:** Add `channels create` subcommand to `community_ops.py` that:
1. Resolves category by name using `get_categories()`
2. Calls `create_channel(name, 0, category_id)`
3. Auto-adds alias to servers.json

**Add to community_ops.py channels subcommand block:**
```python
elif action == "create":
    # channels create <name> --category <category_name>
    ch_name = args[0]
    cat_name = args[args.index("--category") + 1] if "--category" in args else None
    cat_id = client.resolve_category(cat_name) if cat_name else None
    result = client.create_channel(ch_name, 0, cat_id)
    if result:
        print(f"Created: {result['name']} ({result['id']})")
    else:
        print("Failed to create channel")
```

---

### Step 6 — Update Memory & Documentation

**Files to update:**

**`~/.claude/projects/-Users-home/memory/reference_discord.md`**
- Add: "arc-web bot = canonical bot for ARC guild channel management"
- Add: "discord_api.py has create_channel/delete_channel — USE IT, don't write custom scripts"
- Add: "Zeroclaw Alpha/Bravo/Charlie = NOT members of ARC guild with admin perms; don't use for ARC"
- Add: "channel creation: use `community_ops.py channels create <name> --category <cat>`"

**`~/.claude/projects/-Users-home/memory/agent_credential_map.md`**
- Add Discord token OpenBao paths: `secret/discord/arc-web`, `secret/discord/stackpack`, etc.

**`~/.claude/projects/-Users-home/memory/credentials_architecture.md`**
- Note Discord tokens added to OpenBao under `secret/discord/<slug>`

**`~/ai/agents/comms/discord_agent/server_docs.md`**
- Add WLW category structure + all 10 channel names and IDs

---

### Step 7 — Verify Final State

```bash
# 1. Confirm arc-web token works
op run --env-file=~/ai/agents/comms/discord_agent/.env.1p.arc -- \
  python3 -c "from discord_api import DiscordClient; c=DiscordClient('arc'); print('OK', len(c.get_channels()))"

# 2. Confirm all 10 WLW channels present (2 original + 8 new)
op run --env-file=~/ai/agents/comms/discord_agent/.env.1p.arc -- \
  python3 -c "
from discord_api import DiscordClient
c = DiscordClient('arc')
chans = c.get_channels()
wlw = [x for x in chans if x.get('parent_id')=='1478284078439596174']
for ch in sorted(wlw, key=lambda x: x['position']): print(ch['name'])
"

# 3. Confirm OpenBao has discord tokens
bao kv list secret/discord/

# 4. Confirm servers.json aliases resolve
python3 -c "
import json
d = json.load(open('servers.json'))
aliases = d['servers']['arc']['aliases']
for k in [x for x in aliases if 'wlw' in x]: print(k, aliases[k])
"
```

---

## Execution Order

1. [User] Refresh arc-web token in Discord Dev Portal → update 1P
2. Verify arc-web token works (Step 7 check #1)
3. Rename 7 channels to 🚤 emoji (Step 0) — needs working arc-web token
4. Migrate tokens to OpenBao (Step 2)
5. Update config_loader.py (Step 3)
6. Update servers.json (Step 4)
7. Add `channels create` to community_ops.py (Step 5)
8. Update memory + server_docs.md (Step 6)
9. Full verify (Step 7 checks #2-4)

---

## Out of Scope

- Bot permission audit in Discord Dev Portal (need user to do in browser)
- Zeroclaw bot membership in ARC guild — those bots shouldn't be in ARC at all; not fixing unless user asks
