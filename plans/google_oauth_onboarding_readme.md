# Plan: google-oauth-setup README + Repo Discoverability

## Context

`arc-web/google-oauth-setup` is the right repo. The code handles one-shot Google OAuth for any account across 10 services. The gap: the README reads like a command reference, not an onboarding guide. Someone setting up a new Google account has no idea they need a GCP project, OAuth consent screen, and a Desktop app client before running setup. The "GCP Client setup" section exists but is buried at the bottom. Also no GitHub topics = invisible in org search.

---

## Changes

### 1. README.md - Add onboarding section before Prerequisites

Insert a "New account onboarding" section immediately after the service table. This section covers the full path for someone who has never used the tool with a new account. The existing command reference stays intact.

**New section to insert at line 19 (after the services table, before Prerequisites):**

```markdown
## New account onboarding (start here)

Do this once per Google account. Takes about 10 minutes.

### Step 1 - GCP project

You need a GCP project linked to the Google account you're authing. If you already have one, skip to Step 2.

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (or use an existing one for this account)
3. Note the **Project ID** - you'll pass it as `--gcp-project`

### Step 2 - OAuth consent screen

1. In GCP Console: **APIs & Services** → **OAuth consent screen**
2. User type: **External** → Create
3. Fill in App name (anything) and your email for support/developer fields
4. Scopes: skip (the CLI adds them per service)
5. Test users: add the Google account email you're authing
6. Save

### Step 3 - OAuth client credentials

1. **APIs & Services** → **Credentials** → **+ Create Credentials** → **OAuth client ID**
2. Application type: **Desktop app**
3. Create → copy the **Client ID** and **Client Secret**

On first run, the CLI will ask you to paste them. They get stored in OpenBao automatically.

### Step 4 - Run setup

```bash
cd ~/ai/infra/google-oauth-setup
python3 google_oauth.py setup --account you@example.com --all --gcp-project YOUR_PROJECT_ID
```

The CLI will:
1. Ask you to paste the client JSON (first time only - stored in OpenBao after that)
2. Open API enable pages in your browser (enable each one, then type `done`)
3. Open a browser auth flow for each service (sign in as the target account)
4. Store all tokens in OpenBao + 1Password + local cache
5. Run smoke tests and print a results table

**Subsequent runs** (token refresh, re-auth): client credentials load automatically from OpenBao.
```

### 2. README.md - Update Prerequisites to reference the onboarding section

Change the GCP line from:
```
- GCP OAuth 2.0 Client ID (Desktop app type) - create once at console.cloud.google.com/apis/credentials
```
To:
```
- GCP project + OAuth consent screen + Desktop app client ID - see "New account onboarding" above
```

### 3. GitHub topics

```bash
gh repo edit arc-web/google-oauth-setup \
  --add-topic cat-infra \
  --add-topic sub-credentials \
  --add-topic google-oauth \
  --add-topic openbao \
  --add-topic one-shot
```

---

## File to touch

| File | Change |
|------|--------|
| `/Users/home/ai/infra/google-oauth-setup/README.md` | Insert onboarding section after line 18, update Prerequisites line |

---

## Verification

```bash
# Check topics applied
gh repo view arc-web/google-oauth-setup --json repositoryTopics

# Confirm README renders (open in browser)
gh repo view arc-web/google-oauth-setup --web
```
