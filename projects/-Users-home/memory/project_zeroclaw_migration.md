---
name: ZeroClaw migration - OpenClaw deprecated
description: OpenClaw is a deprecated historic project replaced by ZeroClaw. Never reference OpenClaw as active. Migration in progress.
type: project
originSessionId: 9931cd28-b35c-4980-9158-49b9c71bf069
---
OpenClaw (Node.js agent container) has been deprecated as of 2026-03-30 and replaced by ZeroClaw (Rust-based, distroless).

**Why:** ZeroClaw is faster, leaner, more secure (distroless image, no shell). OpenClaw was the original prototype.

**How to apply:**
- Never reference OpenClaw as an active tool or running service
- ZeroClaw is the primary agent container on VPS Alpha (Hostinger, 187.77.222.191, port 42617)
- All work previously done with OpenClaw should be prioritized for incorporation into ZeroClaw
- Nothing from OpenClaw gets deleted until it's been incorporated into ZeroClaw or archived in the arc-claw repo (arc-web/arc-claw does not exist yet - verified 2026-05-01)
- Full migration plan: `~/docs/superpowers/plans/2026-03-30-openclaw-to-zeroclaw-migration.md` (MISSING - ~/docs/ not present on local machine - verified 2026-05-01)
- GitHub repo plan for team tracking: `~/docs/superpowers/plans/2026-03-31-arc-claw-repo-and-migration-status.md` (MISSING - same - verified 2026-05-01)
- VPS purge is the final step - only after ZeroClaw is verified fully operational
