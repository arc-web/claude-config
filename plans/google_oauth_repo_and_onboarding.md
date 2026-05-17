# Plan: Google OAuth Setup - Repo Recommendation + Onboarding Readiness

## Context

The credential system was just rebuilt. The question is where this code should live and whether it's ready to one-shot onboard any new Google email. The answer: the right repo already exists (`arc-web/google-oauth-setup`, private). No new repo needed. But the README doesn't clearly surface the "new account onboarding" flow, and the repo lacks GitHub topics for discoverability.

---

## Recommendation: Keep arc-web/google-oauth-setup as-is

**Why no new repo:**
- The tool is already account-agnostic. `--account` is a required parameter on every command. Running it against a new email is exactly what it was designed for.
- Splitting "credential creation" from this repo would create a dependency between two repos doing the same thing - violates the self-contained project rule.
- The other auth repos found in arc-web (`credential-system`, `authentication-agent`, `authentication-boss`, `token-agent`) are unrelated - none are locally cloned and none handle Google OAuth provisioning specifically.

**What it already does for a new email:**
```bash
python3 google_oauth.py setup --account newperson@example.com --all --gcp-project 123456789
```
That single command:
1. Looks up client credentials from OpenBao/1P (or prompts to paste if missing)
2. Opens all 10 API enable pages in browser
3. Runs OAuth browser flow per service
4. Writes all tokens to OpenBao + 1Password + local cache (chmod 600)
5. Smoke-tests every service
6. Prints a summary table

---

## What's Missing (Two Small Gaps)

### Gap 1: GCP client credentials for a new account

The current flow assumes the GCP OAuth client already exists in OpenBao at `secret/google-oauth-client/{slug}`. For a brand-new email/GCP project, it doesn't. The code handles this with `resolve_client()` - it falls back to prompting the user to paste the client JSON.

**This works but isn't documented clearly.** The README says "paste the JSON" but doesn't say WHERE to create it (GCP Console) or WHAT type (Desktop app). The README's "GCP Client setup" section exists but is buried at the bottom.

### Gap 2: README doesn't have a "New account onboarding" section

The README shows the `setup` command but doesn't walk someone through the full new-account path (create GCP project → enable OAuth consent screen → create Desktop app client → run setup). Someone unfamiliar would be confused.

---

## What to Do

### 1. Update README with a prominent "Onboarding a new Google account" section

Place it at the top, above "Usage". Covers:

```
## Onboarding a new Google account (one-shot)

Prerequisites:
- GCP project for this account (create at console.cloud.google.com)
- OAuth consent screen configured (External, test mode is fine)
- Desktop app OAuth client created (see "GCP Client setup" below)

Then:
python3 google_oauth.py setup --account you@domain.com --all --gcp-project YOUR_PROJECT_ID
```

### 2. Add GitHub topics to arc-web/google-oauth-setup

Run:
```bash
gh repo edit arc-web/google-oauth-setup \
  --add-topic cat-infra \
  --add-topic sub-credentials \
  --add-topic google-oauth \
  --add-topic openbao \
  --add-topic one-shot
```

### 3. No code changes needed

The tool is already correct after the credential chain rewrite. No functional changes required.

---

## Files to Touch

| File | Change |
|------|--------|
| `/Users/home/ai/infra/google-oauth-setup/README.md` | Add "Onboarding a new account" section at top |

---

## Verification

After README update:
```bash
# Confirm repo has topics
gh repo view arc-web/google-oauth-setup --json topics

# Confirm README renders correctly  
gh repo view arc-web/google-oauth-setup --web
```

The functional one-shot test (verified already working):
```bash
python3 google_oauth.py setup --account me@advertisingreportcard.com --services gmail
python3 google_oauth.py smoke-test --account me@advertisingreportcard.com --service gmail
```
