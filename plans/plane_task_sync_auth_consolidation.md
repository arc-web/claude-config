# Plan: Plane task sync - auth agent consolidation

## Context

Phases 1-7 of authentication_agent consolidation are complete (PR #1 open on arc-web/authentication-agent). Plane has several related tasks in AGENT and INFRA projects that are either stale, need state updates, or have no task at all for the new work.

---

## What Plane shows (relevant tasks)

| ID | Project | State | Name |
|----|---------|-------|------|
| AGENT-158 | AGENT | **Backlog** | Credential Management Protocol |
| AGENT-181 | AGENT | Approved | Mirror GHL agency PIT from 1P to OpenBao |
| AGENT-179 | AGENT | Approved | Provision shared Google Workspace SA + enable GTM API |
| AGENT-180 | AGENT | Approved | Enable GA4 Data API + add SA to all client GA4 properties |
| INFRA-145 | INFRA | **Backlog** | Refresh OpenBao credential model docs after 2026-05-13 rollout |
| INFRA-144 | INFRA | **Backlog** | OpenBao sidecar hardening + task reconciliation, 2026-05-13 |
| INFRA-143 | INFRA | Approved | Migrate Plane Docker /opt/plane/.env secrets to OpenBao injection |

---

## Actions

### 1. Update existing tasks

**AGENT-158 "Credential Management Protocol"**: Backlog → In Progress  
- Project: AGENT (`0e399778-93d9-4a95-ba2f-755990dd69bc`)  
- State UUID for In Progress: `bdb50dbe-2fe8-4f65-848c-1439cfa64ad5`  
- Add description note: "PR #1 open at arc-web/authentication-agent - SQLite removed, OpenBao backend live, Google OAuth + authentication_boss absorbed, arc-scripts auth.py generalized."

**INFRA-145 "Refresh OpenBao credential model docs after 2026-05-13 rollout"**: Backlog → In Progress  
- Project: INFRA (`9643da9a-da40-4f40-8cbe-561822288cd4`)  
- State UUID for In Progress: `371a2559-67d4-4215-b70b-69daaad8b0bc`  
- Add note: "authentication_agent PR #1 is the implementation reference for the new model. Doc refresh follows merge."

---

### 2. Create new tasks in INFRA project

**New task A - merge the PR:**
- Name: `Merge authentication_agent PR #1 - OpenBao consolidation`
- Project: INFRA
- State: Todo (`d553546e-93a0-4b23-9925-a33ae177f20a`)
- Description:
  ```
  Review and merge arc-web/authentication-agent PR #1.
  Branch: feature/auth-agent-openbao-consolidation
  PR: https://github.com/arc-web/authentication-agent/pull/1

  What changed:
  - core/database.py: SQLite replaced by OpenBao (backends/openbao.py)
  - backends/onepassword.py: controlled fallback, not ambient
  - core/crypto.py: deleted (OpenBao encrypts at rest)
  - Google OAuth: GoogleOAuthManager + cli/google_commands.py + REST routes
  - authentication_boss absorbed: cli/apikey_commands.py + cli/policy_commands.py
  - arc-scripts/gmail-mgmt/auth.py: get_credentials(service, account) - any Google service

  Test plan before merge:
  - auth google status --account me@advertisingreportcard.com
  - auth apikey list (walks secret/api-keys/ in OpenBao)
  - python3 web/server.py starts without import errors
  ```

**New task B - stale OpenBao path cleanup:**
- Name: `Delete stale OpenBao paths - pre-slug-fix tokens (advertisingreportcard slug)`
- Project: INFRA
- State: Todo
- Description:
  ```
  10 stale paths exist from before the account slug fix (slug was 'advertisingreportcard',
  correct slug is 'me-advertisingreportcard-com').

  Only execute AFTER PR #1 is merged and new slug paths verified working.

  Paths to delete:
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

  Command per path (on zeroclaw):
    bao kv metadata delete secret/{service}/advertisingreportcard
  ```

**New task C - archive authentication_boss:**
- Name: `Archive authentication_boss repo (after authentication_agent merge)`
- Project: INFRA
- State: Todo
- Description:
  ```
  Checklist: ~/.claude/plans/auth_agent_archive_checklist.md

  Prereqs (must all pass before archiving):
  - auth apikey list returns expected keys
  - auth apikey test passes for all services
  - No other repo imports from authentication_boss
  - ~/.cli.db checked and migrated if it contains data
  - PR #1 merged

  Archive command:
    gh repo archive arc-web/authentication-boss --yes
  ```

---

## API calls to execute

All use workspace `todovibes`, INFRA project = `9643da9a-da40-4f40-8cbe-561822288cd4`, AGENT project = `0e399778-93d9-4a95-ba2f-755990dd69bc`.

Need to:
1. PATCH AGENT-158 state → `bdb50dbe-2fe8-4f65-848c-1439cfa64ad5` + add description
2. PATCH INFRA-145 state → `371a2559-67d4-4215-b70b-69daaad8b0bc` + add description
3. POST 3 new issues to INFRA project

Plane issue PATCH endpoint: `PATCH /api/v1/workspaces/{slug}/projects/{project_id}/issues/{issue_id}/`  
Plane issue POST endpoint: `POST /api/v1/workspaces/{slug}/projects/{project_id}/issues/`

Need to fetch issue UUIDs for AGENT-158 and INFRA-145 (not in the list output, requires a detail fetch or parse from full list).
