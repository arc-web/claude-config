# Action over research - debug ops fast

Triggered 2026-04-25 by repeated failure pattern across one session: bridge.jsonc delete (asked confirmation on already-authorized destructive op), op TCC popup spam (gave instructions instead of fixing root), claude-hang (found offender in first ps aux but kept investigating instead of disabling). User had to interrupt 5+ times. Memory entry for `OP_SERVICE_ACCOUNT_TOKEN launchctl setenv` already existed and would have solved both popup and hang in one command - never queried.

## Hard rules - debug/fix AND credential/infra tasks

1. **mem-search FIRST.** Before any debug/fix task OR any credential/infra task ("write secret", "wire up access", "connect to vault", "give X access to Y"), run mem-search on the symptom or the system name (openbao, hermes, vault, github-pat). If a prior session solved it, use that solution. Do NOT re-derive from scratch. Specifically for credential lookups, also walk the discovery order in `feedback_credential_discovery_order.md` BEFORE any tool call.

2. **Authorized destructive ops execute immediately.** User says "delete X", "kill Y", "remove Z" with explicit purpose - do it. If exact target missing, act on closest match by name + report. NEVER ask "should I delete the closest match instead?" - that is a stall.

3. **One investigation pass max.** First ps/grep/read finds the offender → act on it. Do not run 4 more searches "to be sure". If the first read confirms the suspect, disable/kill/remove now.

4. **When fix path fails, pivot to disable.** Patched script's cache prime failed → rename to `.disabled`, ship, debug later. Do NOT keep iterating on the broken path.

5. **No "confirm before X" on already-authorized ops.** User authorization in prior message = standing authorization for that op. No re-asking.

6. **High thinking mode ≠ more deliberation per step.** For ops/debug, thinking budget goes into root-cause selection, not into more research rounds.

## Anti-patterns documented

- Found offender in `ps aux` → kept grepping for "where is it registered" instead of disabling it
- Treated cache-prime failure as new puzzle → should have pivoted to disable
- Asked "want me delete bridge-state.json instead?" after user already authorized delete with named purpose
- Ignored memory entry on `launchctl setenv OP_SERVICE_ACCOUNT_TOKEN` - the exact fix for the exact problem
- Surface-level fix (flip 1Password Developer toggle) when root was a script spawning op per-launch

## Decision tree for debug/fix tasks

```
User reports symptom
  → mem-search symptom keywords
    → Match found? Apply that fix.
    → No match? Run ONE investigation command (ps, grep, read).
      → Offender identified? Disable/kill/fix. Report.
      → Not identified? Run ONE more. Then decide.
  Never exceed 3 investigation commands before acting.
```

## Last updated

2026-04-28
