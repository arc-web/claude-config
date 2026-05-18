# OpenBao Per-Task Tokens + Codex Failure Analysis

## Context

External feedback (Mike's contact) recommends minting **short-lived per-task tokens scoped to just the secrets a task needs** instead of long-lived AppRole sessions, citing prompt-injection blast-radius reduction. Codex was asked to compare this to our setup, derailed by anchoring on the zeroclaw SSH pathway, missed the local Cloudflare Tunnel pathway entirely on first pass, then crashed during compact before delivering a corrected plan. This plan documents (a) what Codex got wrong and why, (b) what our actual architecture does vs the feedback's model, (c) the hardening to adopt.

---

## Part 1 - Codex Failure Postmortem

### What Codex got wrong

1. **Wrong primary pathway.** First plan treated `ssh zeroclaw` as the credential access surface. Reality: local Claude Code, GitHub Actions, and the human team all hit `https://vault.aibrainbuilders.com` via Cloudflare Tunnel (`daily-win-broker`, ID `56d29a80-dfb1-4ceb-a31d-70d37a09feb3`). Zeroclaw is the destination, not the access method.
2. **Skipped local SOP.** The OpenBao SOP at `~/ai/agents/development/codebase_helper/.cache/transient-previews/openbao-sop/docs/index.md` explicitly documents the tunnel, container network, and AppRole login URL. Plane-PM skill (`~/ai/tools/ai/claude-skills/plane-pm/SKILL.md` L14-39) shows the exact `creation_ttl=3600, renewable` AppRole login through that URL.
3. **Search pollution.** Broad `rg` across `/Users/home/ai` pulled in n8n binary trees, frontend deps, and Codex JSONL session archives, drowning the relevant arcbao + cloudflare_agent + discord_agent broker signal.
4. **Misread "fingerprint."** User's "keep fingerprint" = stable public DNS + tunnel identity at `vault.aibrainbuilders.com` so clients trust a managed boundary; not TLS pinning per se, but consistent identity across container restarts vs raw SSH to host.
5. **Crashed on compact.** Lost the corrected analysis. No persisted artifact.

### Why it failed (research-path issues)

- **Pattern-match on "zeroclaw" without reading upstream.** Memory mentions zeroclaw heavily → Codex anchored there before reading architecture docs that put the tunnel in front.
- **No exclusion hygiene on broad searches.** Should glob-exclude `node_modules`, `.cache`, `*.jsonl`, dependency dirs by default.
- **Read template docs (`arcbao/docs/setup.md`) instead of live state first.** Template TTL numbers (1h/24h) are examples, not necessarily live role config.
- **RTK wrapper blocked compound `find` predicates.** Workflow friction pushed it toward broader `rg` that returned junk.

### Pathway issues exposed (need rectifying)

- **Two parallel credential pathways exist with no documented client-selection rule.** Tunnel (`vault.aibrainbuilders.com`) for local + GH Actions + humans. Sidecar proxy (`127.0.0.1:8100`) for hermes/zeroclaw/paperclip containers. Codex defaulted wrong because nothing says "local Claude Code uses the tunnel."
- **The arcbao docs predate the tunnel pathway.** `setup.md` and `architecture.md` describe sidecar AppRole only.
- **No per-task token primitive anywhere.** All clients hold one persistent token for container/session lifetime.

---

## Part 2 - What We Do vs What They Do

### Us (current)

| Surface | Auth | Endpoint | Token lifetime |
|---|---|---|---|
| Local Claude Code | AppRole (1P bootstrap) | `vault.aibrainbuilders.com` (CF Tunnel) | `creation_ttl=3600s`, renewable, `explicit_max_ttl=0`, so practical = role `token_max_ttl` ceiling (template says 24h) |
| GitHub Actions | AppRole (GH Secrets) | `vault.aibrainbuilders.com` | 5min (CI-tight) |
| Hermes / zeroclaw containers | AppRole via bao-agent sidecar | `127.0.0.1:8100` | Renewable to role ceiling |
| daily-win-broker | AppRole (env) | `http://openbao:8200` (docker net) | Renewable |
| Humans (mike/patrick) | userpass | Tunnel | Session |

Single token per session/container. Scope = per-agent policy (broad: any path the policy allows). No wrap, no child, no per-task scoping. Renewal hides expiry from the workload.

### Them (feedback model)

- Long-lived AppRole exists only as the **minter**.
- Each autonomous task request → mint a fresh **child token** with `ttl` measured in minutes, `explicit_max_ttl` hard-cap, `num_uses` low (often 1-5), policy bound to **exactly the secret(s)** this task touches.
- Token dies when task ends (revoke on exit) or hits TTL, whichever first.
- Prompt injection that hijacks the agent mid-task can only exfil what that task already had access to, for the seconds it has left.

### Why we do what we do

- Sidecar + renewable AppRole was built for **continuous services** (hermes polling, broker handling Discord interactions inside 3s ACK windows, zeroclaw cron). They need uninterrupted access without re-auth latency.
- Tunnel + AppRole for local was built so the **same vault** serves laptop + CI + humans without exposing SSH or duplicating secret stores. Fingerprint stability matters because clients pin on hostname.
- One-token-per-session was the simplest thing that worked once 1P-only was migrated off.

### Why they do what they do

- They run **autonomous agent jobs** (one prompt → many tool calls → exit). The shape fits per-task minting cleanly: known secret set, bounded runtime, exit signal available.
- Prompt-injection risk for autonomous agents is real and asymmetric (a leaked long token = days of access; a leaked 5-minute token scoped to one secret = minutes of access to one thing).
- They likely have a broker/launcher that already gates work, so adding "mint a token first, hand it to the task" is one line.

---

## Part 3 - What We Should Do

### Keep

- Cloudflare Tunnel as the local + CI + human surface. Don't change DNS or tunnel identity.
- bao-agent sidecar for long-running services (hermes, broker, paperclip, zeroclaw daemons). Continuous workloads stay on renewable tokens; per-task minting adds latency they can't afford for sub-second ACK paths.
- OpenBao canonical, 1P fallback-only.

### Add (per-task token layer for autonomous + interactive Claude work)

1. **Tighten role ceilings on the long-lived AppRoles first.** Inspect each live role; set explicit `token_max_ttl` (not 0) and a positive `secret_id_ttl` per service role after a read-only audit. Document deltas vs template.
2. **Create task-scoped policies.** Examples: `task-plane-read`, `task-discord-post`, `task-google-oauth-bootstrap`. Each binds to **exact** `secret/data/...` paths, not a wildcard.
3. **Add a token role per task type** under `auth/token/roles/agent-task-*`:
   - Short `period` or `ttl` (5-15min).
   - Positive `explicit_max_ttl` (15-60min hard cap).
   - `allowed_policies` = the one task policy.
   - `disallowed_policies` includes anything that can mint more tokens.
   - `orphan = true` so revocation doesn't cascade upward unexpectedly.
   - Metadata: task id, agent id, repo path, parent session.
4. **Minter gate.** Only a trusted launcher (broker-side or a thin local CLI) holds the policy to mint child tokens. Normal agents cannot self-elevate or mint siblings.
5. **Wrap-then-handoff.** Minter returns `wrap_ttl=60s` cubbyhole; task unwraps once at start. Stops the token from ever sitting on disk or in logs.
6. **Revoke on exit.** Wrapper exits → `auth/token/revoke-self` from the task token. Belt-and-suspenders alongside the TTL.
7. **Pilot first.** One low-risk read-only task (Plane read or Discord sync health probe). Verify: short TTL holds, allowed paths read OK, unrelated paths return 403, revoke on clean exit, task completes. Only after pilot, migrate writers.
8. **Document the client-selection rule.** Update `~/ai/arcbao/docs/architecture.md` + new `pathways.md`: which client uses tunnel vs sidecar vs local-mint, and why. Add a "fingerprint" note explaining tunnel identity stability.

### Critical files

- `~/ai/arcbao/docs/architecture.md` - add tunnel pathway section + per-task token layer
- `~/ai/arcbao/docs/setup.md` - revise TTL guidance, add `explicit_max_ttl` + token-role examples
- `~/ai/arcbao/templates/` - new `task-role-example.hcl`, `task-policy-example.hcl`
- new minter CLI under `~/ai/arcbao/bin/` (or extend bao-agent wrapper) - mints + wraps task tokens

### Verification

- `bao read auth/approle/role/<role>` for each live role - record current ceilings.
- `bao token create -role=agent-task-plane-read -wrap-ttl=60s` on pilot - verify TTL, policy, wrap.
- Unwrap from task process; attempt read of allowed path (200) and forbidden path (403).
- Exit task; confirm `bao token lookup <accessor>` returns revoked.
- Re-run pilot task end-to-end through normal entrypoint with new flow.

---

## Open questions

- Live AppRole role config for hermes/zeroclaw/broker - is `token_max_ttl` actually 24h or something else? Needs read-only `bao read auth/approle/role/<role>` per role.
- Does the broker pattern (worker → broker → vault) already isolate enough that per-task tokens add little? Likely yes for Daily Win; the gains are mostly for local Claude Code + autonomous Codex runs.
- Who is "they" in the feedback? If they're running OpenAI Agent SDK / Codex CLI specifically, ask for a config snippet before reinventing.

## Done / Open / Recommend

Done: Codex failure traced (wrong-pathway anchor, no exclusion hygiene, template-vs-live confusion, compact crash). Architecture mapped (tunnel + sidecar + broker, single-token-per-session everywhere). Per-task token design drafted with pilot + verification.

Open: Live role TTL audit not run. Minter CLI not built. Docs not yet updated. Need confirmation from feedback source on their exact minting flow.

Recommend: Run the read-only live-role audit first (one ssh + a few `bao read` calls), then build the minter against one pilot task before touching any service-level config. Don't change the tunnel or sidecar; add the task layer alongside them.
