---
name: Failure pattern registry - infra/credential tasks
description: Eight named failure patterns from 2026-04-28 Hermes session. Each has trigger, wrong behavior, right behavior, real-time detect signal. Reference when self-correcting mid-task.
type: feedback
originSessionId: 11d73955-4195-456c-b3f4-7f63a576b646
---
# Failure patterns

## F1. Crawl-before-recall
- Trigger: needing a credential/path/admin pattern.
- Wrong: SSH-walk `/etc /opt /root` for `*token*`/`*root*`.
- Right: mem-search + read `openbao_admin_write_pattern.md` first; root token is in 1P ARC `hl23px33remaz2xecl5ecvvaem`.
- Detect: about to `find /etc /opt /root -name '*token*'`.

## F2. New-AppRole reflex
- Trigger: existing AppRole returns "permission denied" on a write.
- Wrong: design new AppRole/policy with write capability.
- Right: AppRoles are read-only by design. Use root token.
- Detect: drafting policy HCL or `bao write auth/approle/role/...` for a one-off secret write.

## F3. Field-name guess
- Trigger: writing a secret consumed by an entrypoint with `fetch()` helper.
- Wrong: invent `pat=`, `token=`, `credential=`.
- Right: field is always `value` (matches `.data.data.value`).
- Detect: `bao kv put ... <anything-other-than-value>=...`.

## F4. Ask-user shortcut
- Trigger: token not in first place looked.
- Wrong: ask user.
- Right (service token): env → OpenBao via SSH → VPS filesystem → only then user. Never 1P for service tokens.
- Right (account login): env → OpenBao → 1P → only then user.
- Detect: drafting question containing "what is the X token".

## F5. Decision-matrix sprawl
- Trigger: routine credential operation.
- Wrong: 4 plans with tradeoffs.
- Right: one plan, executed.
- Detect: typing "Option A / Option B" for credential write.

## F6. Serial-call inflation
- Trigger: multi-step inspection on remote host.
- Wrong: 50 separate `ssh zeroclaw` calls.
- Right: batch with `;`/`&&` in one SSH invocation.
- Detect: third sequential SSH within a minute.

## F7. Re-read same file
- Trigger: needing info already loaded.
- Wrong: ctx_read same path again.
- Right: check own context first.
- Detect: same path appears twice in tool history.

## F9. 1P-shortcut-for-service-token
- Trigger: any fetch of a service credential (API key, token, secret).
- Wrong: `op item get <id> --vault Zeroclaw` for a service token, with or without trying OpenBao first.
- Right: OpenBao via SSH only. If OpenBao fails, diagnose it. Declare emergency before any 1P fallback.
- Detect: writing `op item get` for anything that isn't a bootstrap item (root token, AppRole backup, op service account token).

## F10. Copying credential value to external system
- Trigger: any operation that moves a credential value OUT of OpenBao into another store.
- Wrong: `gh secret set KEY <<< $(bao kv get ...)`, writing key to .env, storing in GitHub Secrets.
- Right: design the consumer to fetch at runtime from OpenBao (SSH deploy key → zeroclaw fetch) or use a webhook receiver so zeroclaw calls out with local creds. Credential values stay in OpenBao.
- Detect: any command that pipes or redirects a credential value to `gh secret set`, a file write, or a remote API call that stores it.

## F8. Existing-infra-as-missing
- Trigger: container has working OpenBao integration.
- Wrong: design fresh mechanism.
- Right: read existing `entrypoint-openbao.sh` `fetch()` lines - usually one new line completes the task.
- Detect: writing more than 5 lines of new bash for credential injection.
