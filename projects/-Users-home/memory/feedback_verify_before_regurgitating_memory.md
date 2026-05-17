---
name: Verify before regurgitating memory
description: Memory can be stale. When user contradicts memory or memory describes external system state (Plane workspaces, Discord servers, repo lists, API endpoints), fact-check live FIRST, then update memory. Never lead with stale memory as if it were truth.
type: feedback
originSessionId: e22fe797-26c8-461f-964b-77cbaf03233a
---
When memory describes external/mutable state, treat it as a hypothesis, not fact. Memory of "todovibes is the only Plane workspace" was stale - user has Internal + Clients workspaces. Acting on stale memory wastes user time and erodes trust.

**Why:** User got angry 2026-04-30 after I cited a stale Plane SOP claiming only `todovibes` workspace exists, when user has separate Internal + Clients workspaces. I should have fact-checked the live API first.

**How to apply:**
1. If memory describes external state (workspaces, projects, channels, repos, endpoints, schemas) and the user references something not in memory → live API/CLI/file check FIRST
2. If user contradicts memory → believe the user, verify live, update memory in same turn (do not just patch the response)
3. Stop using "memory says X" as a defensive shield - it's not authoritative for live system state
4. Update or delete the stale memory in the same response that surfaces the gap
5. Internal logic/preferences stored in memory are reliable. Live system inventory is not.
