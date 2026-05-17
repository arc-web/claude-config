# Archive Readiness Checklist - authentication_boss

Date prepared: 2026-05-13
Status: READY TO REVIEW - do not execute without explicit approval

## What would be archived: arc-web/authentication_boss

The functionality has been absorbed into authentication_agent:
- manage_api_keys.py → cli/apikey_commands.py (OpenBao-backed)
- test_api_keys.py → cli/apikey_commands.py (cmd_test)
- manage_specs.py → cli/policy_commands.py

## Pre-archive verification steps (human must confirm each)

- [ ] `auth apikey list` returns same keys as authentication_boss would have
- [ ] `auth apikey test` passes for all services that passed before
- [ ] `auth policy update` works against a known spec URL
- [ ] No other repo imports from authentication_boss (grep arc-web org)
- [ ] No agent AGENT.md references authentication_boss as a dependency
- [ ] No running process or LaunchAgent points at authentication_boss path
- [ ] ~/.cli.db has been checked: if it contains data, migrate with:
    python3 - << 'EOF'
    import sqlite3, subprocess, json
    conn = sqlite3.connect(str(Path.home() / ".cli.db"))
    rows = conn.execute("SELECT service, api_key, notes, organization_name, organization_slug FROM api_keys WHERE active=1").fetchall()
    for svc, key, notes, org_name, org_slug in rows:
        slug = (org_slug or "default").lower().replace(" ", "-")
        path = f"secret/api-keys/{svc.lower().replace(' ', '-')}/{slug}"
        print(f"Would write: {path}")
    EOF
  Then actually write to OpenBao using backends/openbao.py write()

## Archive command (do NOT run until checklist is complete)

    gh repo archive arc-web/authentication-boss --yes
    # Note: repo name on GitHub may differ from local dir name (authentication_boss)
    # Verify with: gh repo view arc-web/authentication-boss

## What is NOT being archived

- authentication_agent - actively developed, now on feature/auth-agent-openbao-consolidation
- google-oauth-setup - kept as standalone infra tool
- arc-scripts auth.py - generalized in Phase 6, actively used by gmail agents

## Stale OpenBao paths (pre-migration)

These exist from before the slug fix. Do NOT delete until explicitly approved.
  secret/gmail/advertisingreportcard
  secret/google-drive/advertisingreportcard
  secret/google-tag-manager/advertisingreportcard
  secret/google-analytics/advertisingreportcard
  secret/google-ads/advertisingreportcard
  secret/search-console/advertisingreportcard
  secret/gmb/advertisingreportcard
  secret/youtube/advertisingreportcard
  secret/calendar/advertisingreportcard
  secret/people/advertisingreportcard

When ready to clean: verify the new slug paths (me-advertisingreportcard-com)
all return valid tokens first, then delete the old ones with:
  bao kv metadata delete secret/{service}/advertisingreportcard
