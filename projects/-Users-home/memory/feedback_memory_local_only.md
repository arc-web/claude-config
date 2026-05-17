---
name: Memory writes stay local unless user explicitly says VPS
description: Never write to VPS-side memory stores (ZeroClaw brain.db, remote ctx_knowledge rooms, etc) unless user explicitly asks. Local memory systems only by default.
type: feedback
originSessionId: 94f04b01-b1c9-481c-b306-1771e5593585
---
# Memory writes - local only by default

Triggered 2026-04-27 by user directive: "never write memory to vps unless i ask, you only manage memory locally unless i say otherwise."

## Rule

**Default scope for any memory write = local only.**

Local systems (allowed without asking):
- `~/.claude/projects/-Users-home/memory/MEMORY.md` + `*.md` files (auto-memory)
- `ctx_knowledge(action=remember)` with default/local room - if invoked
- `~/ai/brain/Vault/` Obsidian notes (managed by hooks, not direct writes)

Remote systems (require explicit user approval per write):
- ZeroClaw `brain.db` on VPS
- Any `ctx_knowledge` room scoped to remote/shared
- Plane wiki / Plane comments as memory
- Any agent-side persistent store on VPS containers (paperclip, hermes, descript)
- 1Password / OpenBao secret writes (separate rule, but same principle)

## Why

User wants control over what propagates beyond the Mac. Remote memory writes have side effects (visible to other agents, harder to delete, may sync across machines). Default = local. User says "save this to VPS" / "push to ZeroClaw brain" / "remember in shared room" -> then write remote.

## How to apply

- Saving a fact -> always check destination first. If remote, ask.
- Hooks that auto-persist remotely (if any) - do not add new ones without asking.
- Cross-system mirroring - do not duplicate a local memory to VPS just because both exist.
- If user asks where something was saved, name the exact file path / system - no ambiguity.

## lean-ctx ctx_knowledge usage

`ctx_knowledge` is available but not currently in active rotation. If user wants it used, they will say so. Until then:
- Auto-memory (`~/.claude/projects/-Users-home/memory/`) = primary
- `ctx_knowledge` = call only when user requests, or when a fact is genuinely cross-session structured (not text rules)
- No silent dual-write between auto-memory and ctx_knowledge

## Last updated

2026-05-01
