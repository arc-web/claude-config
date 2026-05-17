# win_bot: Discord Interaction Failure - Root Cause + Fix

## Context

Every time the Accept/Reject button is tapped in the DM, Discord shows "This interaction failed" and the log shows:
```
discord.errors.NotFound: 404 (error code: 10062): Unknown interaction
```
on the `await interaction.response.defer()` call — which is literally the first line of the handler.

---

## How Discord button interactions are supposed to work

1. User taps a button → Discord starts a **3-second timer**
2. Discord delivers an `INTERACTION_CREATE` event to the bot via WebSocket gateway
3. discord.py receives the raw WS message, parses it, dispatches `on_interaction`
4. `on_interaction` calls `interaction.response.defer()` → HTTP POST to `discord.com/api/v10/interactions/{id}/{token}/callback` with `{"type": 6}`
5. Discord sees the response → stops the timer → shows no error
6. Bot then does actual work (publish, disable buttons, send followup)

**The entire sequence from step 2 to step 4 must complete in under 3 seconds.**
If `defer()` hits Discord after the timer expires → 404 error code 10062 ("Unknown interaction").

---

## What was implemented

### `win_bot.py` structure
- `discord.Client` on the WebSocket gateway (correct approach)
- `@bot.event async def on_interaction` receives component interactions
- Routes to `handle_accept`, `handle_reject`, or opens `ReviseModal`
- `handle_accept` / `handle_reject` call `await interaction.response.defer()` as first line
- `@tasks.loop(seconds=60) async def poll_state` polls the state file and sends DM when pending draft found

### What's actually blocking the event loop

**`get_stackpack_client()` is called synchronously from async code** on every interaction path AND in `poll_state` every 60 seconds.

Call chain:
```
get_stackpack_client()
  → DiscordClient("stackpack")               ← discord_api.py:116
    → load_server_config("stackpack")         ← config_loader.py:35
      → _op_load("DISCORD_BOT_TOKEN", ...)    ← config_loader.py:53
        → subprocess.run(["op", "read", ...]) ← BLOCKING subprocess on event loop
```

The `op` CLI communicates with the 1Password app/daemon. When the system is busy, the screen is locked, or the app session is warming up, `op read` can take **2-5+ seconds**. This runs directly on the asyncio event loop (not in a thread), freezing it.

**Timing in the logs:**
- `poll_state` runs at connect time → calls `get_stackpack_client()` → blocks event loop for op call
- If user taps button during this window → interaction event sits in the WS buffer unprocessed
- 3-second timer expires before Python's event loop is free to call `defer()`
- `defer()` fires, Discord returns 404 10062

My previous fix (`asyncio.to_thread` on `requests.post()`) was correct but incomplete — it missed `get_stackpack_client()` itself, which runs synchronously before any `to_thread` calls in both `post_win_dm()` and `publish_to_wins()`.

Additionally: `resolve_channel()` in `publish_to_wins` calls `discover_channels()` (HTTP GET) synchronously on first use — but this is avoided in practice because `"wins"` is already in `self.aliases`, so it short-circuits to a dict lookup.

---

## What should actually exist

### Single fix: initialize DiscordClient ONCE at startup

`get_stackpack_client()` must NEVER run during interaction handling. The `op` subprocess should run exactly once — at bot startup, in a thread — and the resulting client cached forever.

```python
# Module level
_sp: "DiscordClient | None" = None

def get_stackpack_client() -> "DiscordClient":
    return _sp  # zero-cost lookup after init
```

```python
@bot.event
async def on_ready():
    global _sp
    print(f"[win_bot] Connected as {bot.user}")
    _sp = await asyncio.to_thread(DiscordClient, "stackpack")  # op runs here, in thread
    print("[win_bot] StackPack client ready")
    poll_state.start()
```

This means:
- The `op` subprocess runs once, in a thread, during bot startup — no event loop impact
- Every subsequent `get_stackpack_client()` call is a Python variable lookup (~0 µs)
- The event loop is free to process interactions the instant they arrive

### Secondary fix: add diagnostic logging + graceful 10062 handling

Add timestamps to `on_interaction` so future failures are diagnosable:

```python
@bot.event
async def on_interaction(interaction: discord.Interaction):
    import time
    t0 = time.monotonic()
    if interaction.type == discord.InteractionType.component:
        cid = interaction.data.get("custom_id", "")
        print(f"[win_bot] Button {cid} received")
        if cid == "win_revise":
            await interaction.response.send_modal(ReviseModal())
            return
        if cid in ("win_accept", "win_reject"):
            try:
                await interaction.response.defer()
                print(f"[win_bot] Deferred in {time.monotonic()-t0:.3f}s")
            except discord.NotFound:
                print(f"[win_bot] Interaction expired ({time.monotonic()-t0:.3f}s elapsed) — 10062")
                return
            if cid == "win_accept":
                await handle_accept(interaction)
            else:
                await handle_reject(interaction)
    elif interaction.type == discord.InteractionType.modal_submit:
        ...
```

`handle_accept` / `handle_reject` then remove their own `defer()` calls (already done by `on_interaction`).

---

## Files to change

**`win_bot.py`** only. Changes:
1. Add `_sp: DiscordClient | None = None` at module level
2. Rewrite `get_stackpack_client()` to return `_sp`
3. Rewrite `on_ready` to init `_sp` via `asyncio.to_thread` before calling `poll_state.start()`
4. Add timestamp logging + graceful 10062 catch in `on_interaction`
5. Remove `defer()` calls from `handle_accept` and `handle_reject` (moved to `on_interaction`)

---

## Verification

1. `launchctl kickstart -k gui/$(id -u)/com.arc.daily-win-bot`
2. Check log shows `[win_bot] StackPack client ready` before `poll_state` starts
3. Reset state: `python3 -c "from daily_win import *; s=load_state(); s['pending']['dm_message_id']=None; s['pending']['channel_id']=None; save_state(s)"`
4. Wait for new DM (up to 60s)
5. Tap Accept → should see `[win_bot] Button win_accept received` + `[win_bot] Deferred in 0.0XXs` in log
6. Confirm no 10062 error, ephemeral "Done. Posted to Stackpack #wins." appears in Discord
