# Plan: Implement Missing Items + Update Plane

## Context

Full session audit of Plane boards, Discord automation, and credential hygiene surfaced concrete gaps. This plan closes them, tests each fix, and updates all related Plane issues.

---

## Item 1 - Fix discord.sh read bug
**File:** `~/ai/agents/comms/discord_agent/discord.sh` lines 188-202

**Bug:** When Discord API returns an error dict (Unknown Channel, Missing Access), `for m in reversed(msgs)` iterates over dict keys (strings), then `m['author']` crashes. No error surfaced.

**Fix:** Add isinstance guard before iterating.

```python
msgs = json.load(sys.stdin)
if not isinstance(msgs, list):
    print(f"Error: {msgs.get('message','unknown')} (code {msgs.get('code','?')})", file=sys.stderr)
    sys.exit(1)
for m in reversed(msgs):
    author = m['author'].get('global_name') or m['author']['username']
    ...
```

**Test:** `~/ai/agents/comms/discord_agent/discord.sh -s arc read nonexistent-channel` → should print error, not traceback.

---

## Item 2 - Fix CHANNEL_AGENTS (INFRA #134)
**File:** `ssh zeroclaw /docker/zeroclaw-agent/cron-scripts/common/config.py`

**Bug:** `CHANNEL_AGENTS = "1476085985388531776"` points to deleted #zeroclaw channel. 5 cron jobs silently fail when posting.

**Steps:**
1. Query Discord API via ZeroClaw Alpha token to find channels the bot can post to: `curl -H "Authorization: Bot <alpha-token>" "https://discord.com/api/v10/guilds/1264976257888551045/channels"` filtered for type=0 (text channels)
2. Replace with correct channel ID in `common/config.py`
3. Candidate: `zeroclaw-speed` (1496750708496666685) — name suggests it replaced the old zeroclaw channel, or confirm with Mike

**Affected jobs** (all fixed by single config.py edit):
- `morning_health.py` lines 129, 136
- `evening_summary.py` line 71
- `weekly_review.py` lines 220, 227, 234
- `memory_consolidation.py` line 139
- `skill_optimizer.py` line 123

**Test:** `ssh zeroclaw "python3 /docker/zeroclaw-agent/cron-scripts/jobs/morning_health.py"` → Discord message appears in correct channel.

---

## Item 3 - Unpause cron scripts (INFRA #134 dependency)
**File:** VPS crontab (`ssh zeroclaw crontab -l`)

Paused 2026-04-25. Currently only morning_health, skill_optimizer, memory_consolidation running.
Paused: `evening_summary`, `weekly_review`, `gads_daily`, `gads_weekly`, `cost_report`.

**After Item 2 fix:** unpause the digest scripts (evening_summary, weekly_review) — NOT gads scripts until LAND smoke tests pass.

---

## Item 4 - INFRA #121 checkpoint (due 2026-05-18)
**Task:** Query `agent_disclaimer_telemetry` data on VPS, check pass criteria:
- All 4 agents disclaimer rate < 2% sustained
- Mike has not re-prompted `look back at messages` in 7+ days
- Failure A + B replicate-pass with same exact wording

**Steps:**
1. `ssh zeroclaw "python3 -c 'import sqlite3; ...'` query disclaimer_rate from telemetry DB
2. Report pass/fail against criteria
3. If pass → create INFRA issue for Tier 4 unified skills migration
4. If fail → iterate Step 5 wording per v2 §8 plan

---

## Item 5 - INFRA #133: Charlie bot channel access
**Action needed by Mike (can't be done programmatically — requires MANAGE_CHANNELS):**

1. Open `joan-task-update` forum in Discord (ID 1498722364412923964)
2. Channel Settings → Permissions → Add Member → search Charlie bot (ID: 1499924971911254178)
3. Grant: View Channel (allow=1024) only
4. Save — Daily Updates thread (1498813074008834189) inherits automatically

**After Mike does this, Claude verifies:**
```bash
ssh zeroclaw "docker exec zeroclaw-charlie \
  curl -s -H 'Authorization: Bot <charlie-token>' \
  'https://discord.com/api/v10/channels/1498813074008834189/messages?limit=1'"
```
Should return JSON list, not 403.

---

## Item 6 - Supabase PAT regeneration
**Action needed by Mike:** Log into Supabase dashboard → Account → Access Tokens → revoke old + create new PAT.

**After Mike provides new token, Claude:**
1. `op item edit zgledcogbu4wvtusstc4rkl7ka --vault ARC credential[password]="<new-token>"`
2. Test: `curl -s -H "Authorization: Bearer <new>" https://api.supabase.com/v1/projects`

---

## Item 7 - Update Plane issues

Close/update all issues touched or resolved today:

| Issue | Action |
|-------|--------|
| INFRA #143 (Plane Docker .env migration) | Set to Approved — backed up in OpenBao, migration pending proper planning |
| INFRA #134 (CHANNEL_AGENTS deleted) | Set to In Progress, then Done after Item 2 |
| INFRA #133 (Charlie bot access) | Update description with exact UI steps, set Needs Approval (Mike action) |
| INFRA #121 (14-day checkpoint) | After Item 4 evaluation, either pass → new issue, or fail → iterate |
| INFRA #62 (Restore nobody:nogroup ownership) | Check if still relevant after today's .env deletions |

Also update INFRA #[REF] Automation & Cron Registry (issue #142) with cron unpause status after Item 3.

---

## Execution order

1. Item 1 (discord.sh fix) — local, 2-min fix
2. Item 2 (CHANNEL_AGENTS) — need channel ID first, then SSH edit
3. Item 3 (unpause crons) — after Item 2 confirmed
4. Item 4 (INFRA #121 telemetry) — query VPS DB
5. Item 7 (Plane updates) — throughout, as each item completes
6. Item 5 (Charlie bot) — flag for Mike, can't execute
7. Item 6 (Supabase PAT) — flag for Mike, execute after they provide token

Items 5 and 6 unblock on Mike. All others executable now.
