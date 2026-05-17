---
name: Restart prompt pattern
description: When asking user to restart Claude Code, provide a ready-to-paste prompt with context, action plan, and debug format
type: feedback
originSessionId: 2f694a2f-6a7e-4f73-9ab5-d5744481bb66
---
**Rule:** When restart is needed, don't just say "restart Claude Code". Provide a complete prompt the user can paste immediately after restart - no follow-up prompting needed.

**Why:** Restart workflow breaks context. User shouldn't have to re-explain the work or re-scaffold the prompt. I should handle that cognitive load upfront.

**How to apply:** When recommending restart:

1. Draft a prompt that includes:
   - **Backstory**: What just happened, what files were created/modified
   - **Action plan**: Next concrete steps in natural language
   - **Output format**: Exactly how you want results (plain text lists, JSON, markdown tables, debug fields to include)
   - **Implementation scope**: Any files that need updating (CLAUDE.md, skills/*.md, settings.json, etc)

2. Format it as a code block the user can copy/paste verbatim

3. Example structure:
   ```
   I just set up Gmail MCP (start.sh, launchd plist, mcp.json created).
   After you restart:
   - Complete the Gmail OAuth flow for advertisingreportcard@gmail.com
   - Then list all non-live clients from Supabase with their current statuses
   - Format as: [Client Name | Type | Current Status | Needed Status]
   - Include debug: client_id, google_ads_status value, discord_channel_id
   
   After listing, we'll backfill the status columns. Plan to document the status-update workflow in CLAUDE.md and skills/supabase/SKILL.md so future audits don't need rescaffolding.
   ```

4. User pastes, restarts, has all context and structure—no "what do I do now?" needed.
