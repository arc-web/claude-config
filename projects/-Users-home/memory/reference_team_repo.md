---
name: github-gang CLI (formerly team-repo)
description: CLI tool for provisioning, managing, and monitoring GitHub repo infrastructure for teams. Repo renamed arc-web/team-repo → arc-web/github-gang (verified 2026-05-01).
type: reference
originSessionId: 1de0e5e9-7d10-497e-bb4e-c7613565245d
---
**Repo:** https://github.com/arc-web/github-gang (renamed from arc-web/team-repo - verified 2026-05-01)

**Local install:** not present - `team-repo` not in PATH, no local clone found (verified 2026-05-01). Clone before use: `gh repo clone arc-web/github-gang`.

**Commands:**
- `team-repo init config.json` - provision hub + team repos from JSON config
- `team-repo status` - dashboard: files, notes.md fill state, commit velocity, stalled detection
- `team-repo status -t a` - specific team
- `team-repo context -t a --building "description"` - update team CLAUDE.md
- `team-repo deploy -t a --pages` - enable GitHub Pages
- `team-repo deploy -t b --local --port 3001` - clone and run locally (auto-detects static/Vite/Next.js)
- `team-repo nudge --custom -t a` - context-aware prompt based on repo state
- `team-repo nudge --final-push` - final push prompt for all teams

**Requires:** `gh` CLI authenticated with org access.

**How to apply:** Use for any scenario managing multiple GitHub repos for teams - workshops, hackathons, software company squads. The config JSON defines org, teams, members, and event details.
