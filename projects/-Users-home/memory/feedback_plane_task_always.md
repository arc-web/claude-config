---
name: Always create and update Plane tasks for work
description: Every agent (Claude Code, Codex, ZeroClaw, all local agents) must create a Plane task at start of work and update it to Done on completion. No silent work.
type: feedback
originSessionId: 8cab95d3-0c83-4722-af67-bc247670d7d7
---
Every meaningful unit of work must have a Plane task. No exceptions.

**Applies to:** Claude Code, Codex, ZeroClaw, all local agents and automation scripts.

**When to create:** At the start of any feature build, fix, deploy, migration, audit, or investigation.

**When to update:** Mark In Progress when starting, Done when complete, Blocked if stuck.

**Why:** AGENT-200 — user established this as a hard rule 2026-05-16. Silent work (no task = no visibility) is not acceptable.

**How to apply:** Before starting any task in a session, check if a Plane task exists (search AGENT project). If not, create one. Update state on completion. Workspace: todovibes, project: AGENT (ID: 0e399778-93d9-4a95-ba2f-755990dd69bc).
