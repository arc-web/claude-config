# What went wrong - Gmail auth

## Failures, in order

1. **Missed claude.ai Gmail MCP already connected.** `claude mcp list` shows `claude.ai Gmail: https://gmailmcp.googleapis.com/mcp/v1 - Connected`. This was available the entire time. Should have run `claude mcp list` at the START of the session before building anything. Never did.

2. **Used deleted OAuth client without verifying.** Pulled `Gmail MCP - advertisingreportcard` from 1Password, wrote `gcp-oauth.keys.json` with that client_id, ran the OAuth flow - got `Error 401: deleted_client`. The 1Password note on the service account item explicitly said a prior OAuth client was "revoked 2026-05-03 after secret was pasted in chat." Should have verified the client was alive in GCP Console before using it.

3. **Arc-browser MCP is down.** `arc-browser: Failed to connect`. Cannot use it for browser automation. Should have checked MCP status before claiming arc-browser was an option.

4. **Kept asking user to run scripts.** Asked user to run `setup_oauth.py`, then tried to run it myself, user denied tool use. Should have used `claude.ai Gmail` MCP which was already authenticated.

5. **Built unnecessary infrastructure.** Built `messages.py`, `setup_oauth.py`, rewrote agent stubs - all to solve a problem that didn't exist. `claude.ai Gmail` was connected the whole time.

## Correct path (now)

1. Load `claude.ai Gmail` MCP tools
2. Test them against `me@advertisingreportcard.com`
3. Decide: does `claude.ai Gmail` cover all needs (search, thread, draft, send)?
   - If yes: agents call it directly, no CLI wrapper needed
   - If no (e.g., scope mismatch, wrong account): create fresh GCP OAuth client via GCP Console, complete flow
4. Update agents + memory to reflect actual working access method
5. Store any tokens/credentials in OpenBao

## Files that may need updating post-fix

- `gmail_thread_agent.py` - currently wired to CLI + direct API fallback
- `extract_locations_from_gmail.py` - same
- `gmail_location_extractor.py` - same
- `gmail_access.md` memory - needs to reflect actual access method
- `messages.py` + `setup_oauth.py` - may be unnecessary if claude.ai Gmail covers everything

## Pre-flight rule to add to memory

**Always run `claude mcp list` and check existing connected MCPs before building any new integration.**
