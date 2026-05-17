# Daily Win Post - Stackpack #wins

## Context

Automate one motivating "win" post per day to Stackpack's `#wins` channel. Each post highlights one real feature or milestone from ARC projects (agent cluster, discord_agent, Google Ads agent, etc.). Short Discord embed, entertaining, founder-tone voice per stackpack_soul.md. HITL gate: draft posts to ARC for review before going live in Stackpack.

---

## Architecture

Two-step cron, single script with `--mode` flag:

```
09:00  daily_win.py --mode draft    → generate embed, post preview to ARC #agents-ops
12:00  daily_win.py --mode publish  → check ✅ reaction on preview → post to Stackpack #wins
```

State persisted in `.cache/win_state.json`. Fully re-runnable (idempotent).

---

## Files

| File | Action | Purpose |
|------|--------|---------|
| `~/ai/agents/comms/discord_agent/daily_win.py` | Create | Main script (~150 lines) |
| `~/ai/agents/comms/discord_agent/features.yaml` | Create | Rotating feature list (seed 10 entries) |
| `~/ai/agents/comms/discord_agent/servers.json` | Edit | Add `wins` alias under stackpack (channel ID discovered at build time) |
| `~/Library/LaunchAgents/com.arc.daily-win-draft.plist` | Create | Cron: 9am daily |
| `~/Library/LaunchAgents/com.arc.daily-win-publish.plist` | Create | Cron: 12pm daily |

---

## Script Flow

### `--mode draft` (9am)

1. Load `features.yaml`
2. Load `.cache/win_state.json` (posted IDs + today's pending)
3. If already drafted today → exit (idempotent)
4. Read Stackpack `#wins` last 30 messages → extract embed titles → build seen-set
5. Pick next feature: rotation order, skip IDs in posted list, skip if title fuzzy-matches seen-set
6. Call Gemini API (gemini-2.0-flash) → generate embed JSON (see prompt below)
7. Post draft embed to ARC `#agents-ops` with caption: `"🔍 Win draft for today - react ✅ to post or ❌ to skip"`
8. Add ✅ and ❌ reactions to the preview message (so user just clicks)
9. Save state: `pending.message_id`, `pending.channel_id`, `pending.feature_id`, `pending.embed`

### `--mode publish` (noon)

1. Load state → check `pending` entry
2. If no pending, or `pending.date != today`, or `already_published` → exit
3. Fetch reactions on `pending.message_id` in ARC `#agents-ops`
4. If ❌ reaction present → mark skipped, exit
5. If ✅ reaction present → post `pending.embed` to Stackpack `#wins`
6. Update state: append feature ID to `posted_ids`, set `last_posted = today`, clear `pending`

---

## LLM Call (Gemini)

**Model:** `gemini-2.0-flash`  
**Credential path:** OpenBao `secret/agents/gemini` or `op://ARC/Gemini API Key/credential`

**System prompt:** Content of `souls/stackpack_soul.md` (punchy, action-bias, founder tone, no em dashes, 1-2 emoji max)

**User prompt:**
```
Feature entry:
{yaml_block}

Write a Discord embed JSON for the #wins channel. Rules:
- title: ≤ 60 chars, punchy, no filler
- description: 2-4 sentences max, explain what it does + why it's a win, plain English
- one field named "What's next" with 1 sentence on the roadmap
- color: 3066993 (green)
- Return ONLY valid JSON: {"title":"...","description":"...","color":3066993,"fields":[{"name":"What's next","value":"...","inline":false}]}
```

---

## features.yaml Schema

```yaml
features:
  - id: discord-agent-multiserver          # unique, kebab-case, never reuse
    project: discord_agent
    feature: Multi-server Discord management
    what_it_does: One CLI manages ARC, Stackpack, and conference servers via Discord REST - channel ops, member audits, embed posts, HITL review gates
    win_angle: What used to be 3 separate bots is now one tool we run from the terminal
    status: shipped
    tags: [discord, automation, agents]
  # ... 9 more entries seeded at build time
```

**Seed projects to include (10 entries):**
- discord_agent multi-server
- ARC agent cluster (Hermes orchestration)
- Google Ads copy engine (THHL campaign)
- daily_win automation itself (meta-win)
- OpenBao credential layer
- DesktopAI / PDF agent
- supabase_agent
- github-gang CLI
- ZeroClaw migration
- Model Mogul routing library

---

## Duplicate Detection

Two layers:
1. **Local state** - `posted_ids[]` in `win_state.json` - skip if feature ID already in list
2. **Live channel check** - fetch last 30 Stackpack `#wins` messages, extract `embeds[0].title`, skip if any title substring-matches proposed feature name (case-insensitive)

---

## State File (`.cache/win_state.json`)

```json
{
  "posted_ids": ["discord-agent-multiserver"],
  "last_posted": "2026-05-07",
  "pending": {
    "date": "2026-05-08",
    "feature_id": "arc-agent-cluster",
    "message_id": "1234567890123456789",
    "channel_id": "1234567890123456789",
    "embed": {"title": "...", "description": "...", "color": 3066993, "fields": [...]}
  }
}
```

---

## Scheduling (launchd, macOS)

`com.arc.daily-win-draft.plist`:
```xml
<key>StartCalendarInterval</key>
<dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
<key>ProgramArguments</key>
<array>
  <string>/usr/bin/python3</string>
  <string>/Users/home/ai/agents/comms/discord_agent/daily_win.py</string>
  <string>--mode</string><string>draft</string>
</array>
```

Same pattern for `com.arc.daily-win-publish.plist` with `Hour=12`.

Both plists write stdout/stderr to `.cache/daily_win.log`.

---

## Pre-build Step: Discover `wins` Channel ID

At build time, run:
```bash
cd ~/ai/agents/comms/discord_agent
bash discord.sh -s stackpack cache-channels
cat .cache/stackpack_channels.json | python3 -c "import sys,json; d=json.load(sys.stdin); [print(v,k) for k,v in d.items() if 'win' in k.lower()]"
```

Add the returned channel ID to `servers.json` under `stackpack.aliases.wins`.

---

## What You're Currently Missing

1. **Cycle exhaustion handling** - when all features have been posted, should it loop back from the start or stop? Plan: loop back (reset `posted_ids` to `[]` when all exhausted, log a notice).
2. **Gemini credential path** - need to confirm at build time whether it's OpenBao or 1P, so script knows where to fetch.
3. **ARC review channel** - plan uses `#agents-ops` for the HITL preview. Confirm this is the right spot or name a preferred channel.
4. **Reaction polling timeout** - if you never react by noon, the post is skipped silently. Considered acceptable (just re-runs tomorrow). Script logs the skip.
5. **Wins channel ID** - must be discovered before build (see pre-build step above).

---

## Verification

1. Run `python3 daily_win.py --mode draft` manually → ARC `#agents-ops` preview embed appears with ✅/❌
2. React ✅ on the message
3. Run `python3 daily_win.py --mode publish` → Stackpack `#wins` post appears
4. Check `.cache/win_state.json` - feature ID in `posted_ids`, `pending` cleared
5. Re-run draft → confirms next feature selected, not same one
6. Re-run publish with no ✅ → confirms nothing posts
7. `launchctl load` both plists → `launchctl list | grep arc` shows both registered
