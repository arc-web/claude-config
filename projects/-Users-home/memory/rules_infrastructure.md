---
name: Infrastructure, deployment, DNS, naming, apps, MCPs
description: No subdomains, DNS debug protocol, MCP naming, provisioning keys, op-ref UUIDs, LibreOffice, computer-use bug
type: feedback
originSessionId: 48314f94-ae1f-4493-8507-4fbb8567aa04
---
# Never create subdomains unless instructed

Default to path-based deployment on existing domain. `lonopack.com/webdesign/`, not `webdesign.lonopack.com`.

Use `cf-deploy update <site> --source <file> --path <prefix>` to upload under a path key. Only `cf-deploy deploy` with new `--domain` when user explicitly requests new domain or subdomain.

**Why:** User was furious when we created `webdesign.lonopack.com` instead of `lonopack.com/webdesign/`. Subdomains create DNS entries, separate buckets, complicate management.

# DNS debugging - check resolver first, not cache

When freshly deployed site shows `ERR_NAME_NOT_RESOLVED`:

1. `scutil --dns | head -20` - what resolver is the machine using?
2. `dig <domain> @1.1.1.1 +short` - does public DNS resolve?
3. If public works, local doesn't: local resolver issue (VPN, Tailscale, Pi-hole). State once, give direct URL, move on.
4. If public also fails: actual DNS problem. Check zone records, nameservers, propagation.

Step 1 is always `scutil --dns`, never `dscacheutil -flushcache`.

**Why:** Cloudflare session jumped straight to `sudo dscacheutil -flushcache` without checking resolver. Tailscale (100.64.0.2) was intercepting. Would have found in step 1.

# MCP server naming convention

MCP servers get `_mcp` suffix on repo and package names. Not `_app`.

- New MCP server repo: `arc-web/<name>_mcp`
- package.json name: `<name>_mcp`
- Config file: `<name>_mcp.config.json`

The `6_apps/` directory in aimacpro is an internal layout detail, not a naming signal.

**Why:** "app" is confusing - it's not an app the user runs, it's a protocol server. `_mcp` makes type clear.

# Provisioning keys / native sub-key support

Do NOT say "third-party API keys are one-string, can't be derived, agents must get the real key."

Services with native provisioning/sub-keys/scoped child credentials:
- **OpenRouter** - provisioning keys mint per-consumer sub-keys via API, each with spend limit, revokable independently
- **Stripe** - restricted keys scoped per resource
- **AWS** - IAM users/roles with per-identity policies
- **GitHub** - fine-grained PATs, GitHub Apps with per-install tokens
- **Google Cloud** - service accounts with scoped IAM
- **Cloudflare** - scoped API tokens

When discussing credential layering / dynamic secrets / two-layer patterns, check whether the service has native sub-key support BEFORE claiming a vault feature is required. OpenBao's dynamic secrets are one path; native provisioning APIs are another and often better.

For OpenRouter: the answer is always "use provisioning keys to mint per-agent sub-keys". Never frame OpenRouter as a single-key service.

# op:// refs must use item UUIDs when title has special chars

When constructing `op read "op://VAULT/ITEM/field"` in code: if title contains parentheses or special characters, use item UUID instead.

- `op://ARC/Cloudflare (ARC)/email` fails with "invalid character in secret reference: '('"
- Before any `op read` call: `op item get "<title>" --vault <vault> --format json | jq '.id'` to get UUID
- If title has `(`, `)`, or special chars: `op://ARC/cbptqpxxwfvtfjgonr3lif2elq/email`
- Add comment with human-readable title: `// Cloudflare (ARC)`
- New items: use dashes not parens. `Cloudflare API Token - gsap-deck-deploy`.

# LibreOffice file opening - HARD RULE

**NEVER use bare `open <file>`.** That opens macOS default (Pages, Numbers, Preview). Always open explicitly.

- DOCX/ODT/spreadsheet: `soffice <file> &`
- Alternative: `open -a LibreOffice <file>`
- NEVER: `open <file>` alone - routes to Pages/Numbers silently

**Why:** Bare `open` opened report in Pages. User was furious. Rule existed in memory and was ignored.

If LibreOffice launches but file doesn't load, check for modal dialogs (Tip of the Day, recovery) blocking events. Kill process and relaunch.
Tip of the Day disabled 2026-04-10 in `~/Library/Application Support/LibreOffice/4/user/registrymodifications.xcu`.

# Computer-use MCP permission loop bug

`mcp__computer-use__request_access` returns "macOS Screen Recording permission(s) not yet granted" even when Screen Recording is enabled. Bug in the MCP, not a missing permission.

**Rule:** If `request_access` fails once, do NOT retry. Skip computer-use entirely, use Tier 1 tools (WebFetch, Read local files, curl headers, sentinel:headers). Follow the tool hierarchy in page-review skill.

**Why:** User showed System Settings with Claude toggle ON, we still retried 6+ times across two sessions.
