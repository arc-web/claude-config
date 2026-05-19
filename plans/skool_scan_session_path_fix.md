# Skool Scan - Session Path Mismatch Fix

## Context

User asked for a fresh Skool audit on `stackpack` (like the 2026-04-12 baseline). Last time it worked. Today:

- `skool_verify_session` -> `authenticated: true` (at /feed)
- `skool_auth_refresh` -> `already, Existing session is valid`
- `skool_scan` -> `scan failed: No session found. Run python3 scripts/collect.py --setup first.`

Two arc-browser modules disagree on where the Skool browser profile lives. The MCP wrote the session to one path; the scanner CLI looks at a different path. Until aligned, every scan fails with a 404-style "no session" even though the browser is logged in.

## Root cause (verified)

Two `settings.py` files in the arc-browser repo with different `BASE_DIR` resolution:

| Consumer | Imports | Resolves SESSIONS_DIR to | State |
|---|---|---|---|
| MCP server (`skool_verify_session`, `skool_auth_refresh`, `skool_scan`-launch shim) | `arc_browser.config.settings` | `/Users/home/ai/tools/browser/arc-browser/arc_browser/sessions/` | **exists**, has `skool/`, `ghl/`, `google-cloud-*`, `smoke/` |
| `scripts/collect.py` (what `skool_scan` actually invokes for the headed Chrome profile) | `browser.settings` | `/Users/home/ai/tools/browser/arc-browser/sessions/` | **does not exist** |

Evidence:
- `arc-browser/browser/settings.py:5` -> `BASE_DIR = dirname(dirname(__file__))` -> `arc-browser/`
- `arc-browser/arc_browser/config/settings.py:5` -> same idiom one level deeper -> `arc-browser/arc_browser/`
- `arc-browser/scripts/collect.py:21` `from browser.settings import SESSIONS_DIR`
- `arc-browser/scripts/collect.py:27` `SESSION_DIR = Path(SESSIONS_DIR) / "skool"`
- `arc-browser/scripts/collect.py:161` `if not SESSION_DIR.exists(): ...` -> trips the "No session found" error.
- `ls /Users/home/ai/tools/browser/arc-browser/arc_browser/sessions/skool` -> exists
- `ls /Users/home/ai/tools/browser/arc-browser/sessions/skool` -> ENOENT (parent missing entirely)

Third location `/Users/home/.skool/sessions/audit-account/` also exists - unrelated profile dir for a different account. Not the active one.

## Gaps + blind spots noted

- The Explore agent flagged the wrong fix line target on first pass (said collect.py:27, real fix is the import on line 21). Verified by reading the file.
- `skool_scan` MCP error message tells the user to run `collect.py --setup`. Running it would create an empty `arc-browser/sessions/skool` profile, then prompt a fresh login, **overwriting nothing but starting a second cookie store**. The already-good cookies in `arc_browser/sessions/skool` would go unused. So the on-screen instruction is a dead end, not a fix.
- arc-browser repo has Hermes + container deploys. Edit must not break the container build (`browser/` may be a legacy module kept for back-compat).
- `~/.skool/` (skool-manager) is separate from arc-browser sessions. Not part of this bug.

## Options

**A. Symlink (fast unblock, reversible)**
```
ln -s /Users/home/ai/tools/browser/arc-browser/arc_browser/sessions \
      /Users/home/ai/tools/browser/arc-browser/sessions
```
- Pros: 0 code change, 0 risk to container build, undo = `rm` the link.
- Cons: leaves two settings.py files diverged - next dev hits the same trap.

**B. Patch `collect.py` to use the canonical settings (real fix)**
- File: `/Users/home/ai/tools/browser/arc-browser/scripts/collect.py`
- Line 21: change `from browser.settings import SESSIONS_DIR` -> `from arc_browser.config.settings import SESSIONS_DIR`
- Then either delete `browser/settings.py` (if no other consumers) or leave it as a back-compat stub.
- Pros: fixes root cause, removes the trap.
- Cons: need to grep the repo for other `from browser.settings` consumers before deleting; arc-browser is a public repo so this is a PR-worthy change.

**C. Hybrid - do A now, queue B as a follow-up PR**
- Unblocks today's scan, schedules the real fix.

**Recommend: C.** User wants a Skool report now, not a refactor.

## Execution plan (once approved)

1. Create symlink (A) - one `ln -s` command, dangerouslyDisableSandbox not needed.
2. Re-run `skool_scan(slug="stackpack")` -> writes `~/.skool/scans/stackpack/<ts>/raw.json`.
3. Read raw.json, compare against 2026-04-12 baseline at `/Users/home/ai/community/skool-manager/examples/stackpack-baseline.json` to highlight deltas (new members, MRR, posts, plugin changes, course additions).
4. Generate styled HTML report at `~/Desktop/stackpack-audit-2026-05-20.html` (per global rule: reports go to Desktop, not /tmp; bump last-updated stamp).
5. Open in default browser for QA.
6. Open follow-up: grep `arc-browser` for `from browser.settings` consumers, patch `collect.py:21`, open PR via `gh` against arc-web/arc-browser.

## Verification

- After symlink: `ls -la /Users/home/ai/tools/browser/arc-browser/sessions/skool` resolves to the populated `arc_browser/sessions/skool` profile.
- `skool_scan` returns a JSON path, not the "No session found" error.
- raw.json contains `about.groupName == "StackPack..."` and `members.totalMembers >= 23`.
- HTML report opens with populated stats grid (no "—" placeholders in the 8 top cards).

## Critical files

- `/Users/home/ai/tools/browser/arc-browser/scripts/collect.py:21` (the bad import)
- `/Users/home/ai/tools/browser/arc-browser/arc_browser/config/settings.py:5-6` (canonical SESSIONS_DIR)
- `/Users/home/ai/tools/browser/arc-browser/browser/settings.py:5-6` (legacy SESSIONS_DIR)
- `/Users/home/ai/community/skool-manager/examples/stackpack-baseline.json` (delta source)
- `/Users/home/.claude/skills/skool-scan/SKILL.md` (report-design reference)

## Rename note

Harness pre-filled `listen-bro-you-going-steady-leaf.md`. Renamed to `skool_scan_session_path_fix.md` per global plan-naming rule.
