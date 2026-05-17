# Plan: Agent Ecosystem Overview + Auth Agent Gap Analysis

## Context

User asked if an auth agent exists and where google-oauth-setup fits in the broader collection. This is a landscape overview, not an implementation task. The answer: two auth agents exist but neither does what google-oauth-setup does. There's a clear gap in the architecture.

---

## Full Agent Inventory

### Local agents at ~/ai/agents/

**Comms (4)**
| Agent | What it actually does |
|-------|----------------------|
| `comms_agent` | Parent orchestrator for all comms tools |
| `discord_agent` | Manages ARC/StackPack Discord servers - member roster, channels, events, audits |
| `fathom_agent` | Fathom.video - transcripts, action items, meeting summaries |
| `reddit_assistant` | Reddit post/comment scraping, keyword tracking, sentiment |

**Development (13)**
| Agent | What it actually does |
|-------|----------------------|
| `authentication_agent` | AES-256-GCM encryption, SQLite credential store, FastAPI server, JWT auth, audit log |
| `authentication_boss` | CLI for auditing/testing API keys, SQLite persistence, API policy manager |
| `client_director` | CRM/client management with Airtable/Supabase |
| `desktop_agent` | Desktop automation and system control |
| `development_agent` | Parent orchestrator for dev tools |
| `github_agent` | GitHub repo sync, security scan, branch mgmt, backup verification |
| `google_cloud_agent` | GCP management and automation |
| `huggingface_agent` | HuggingFace model/dataset management |
| `infrastructure_agent` | VPS, deployment, monitoring |
| `janitor_agent` | System maintenance and cleanup |
| `meta_review_agent` | Evaluates LLM code reviews against engineering best practices |
| `reportcard_agent` | Automated report generation and quality grading |
| `sales_agent` | Sales pipeline and CRM operations |

**Accounting/Finance (4)**
| Agent | What it actually does |
|-------|----------------------|
| `accounting_agent` | Parent orchestrator for financial tools |
| `accounting_swarm` | 10+ specialist agents: Stripe, QuickBooks, bookkeeper, reconciliation, invoicing, payroll |
| `token_agent` | Token and credential lifecycle management |
| `trading_agent` | Financial trading and market analysis |

**Creative (5)**
| Agent | What it actually does |
|-------|----------------------|
| `ARC_Music` | Local AI music generation (ACE-Step 1.5) |
| `Claude_Creative_Director` | Image editing orchestrator with Replicate API |
| `creative_director_agent` | Creative direction orchestration |
| `descript_agent` | Descript video/audio editing and management |
| `music_agent` | Music composition and analysis |

**Web/SEO/PPC (6)**
| Agent | What it actually does |
|-------|----------------------|
| `cloudflare_agent` | Cloudflare R2 site management via cf-deploy CLI |
| `google_ads_agent` | Google Ads campaign management and optimization |
| `google_youtube_agent` | YouTube metadata, transcripts, playlists, downloads |
| `seo_agent` | SEO analysis, optimization, competitive research |
| `travel_agent` | Travel planning and booking |
| `web_agent` | Parent orchestrator for web dev tools |

**Other (4)**
| Agent | What it actually does |
|-------|----------------------|
| `dyad_agent` | Paired agent system for collaborative workflows |
| `mcp_agent` | MCP server management and testing |
| `mcp_management_agent` | Autonomous MCP server testing, monitoring, dashboard |
| `plane_agent` | Project management via Plane |
| `supabase_agent` | Supabase database management via MCP |

---

## Auth/Credential Repos in arc-web

| Repo | Location | What it does |
|------|----------|-------------|
| `google-oauth-setup` | `~/ai/infra/` | Acquires Google OAuth tokens for any account across 10 services; stores to OpenBao + 1P + local cache |
| `authentication_agent` | `~/ai/agents/development/` | Manages credentials with AES-256-GCM + SQLite - no OpenBao integration |
| `authentication_boss` | `~/ai/agents/development/` | CLI auditing/testing of API keys in its own SQLite DB - no OpenBao integration |
| `arcbao` | GitHub only | OpenBao sidecar proxy for agent containers - live secret delivery |
| `credential-system` | GitHub only | Centralized credential management - not locally cloned |
| `credentials-dashboard` | GitHub only | Credential status dashboard - not locally cloned |

---

## Where google-oauth-setup Fits

The credential stack has three layers:

```
ACQUISITION (google-oauth-setup)
  - Runs the browser OAuth flow
  - Distributes tokens to OpenBao + 1Password + local cache
  - One-time per account, re-runnable per service

STORAGE (OpenBao on zeroclaw)
  - Canonical source for all service tokens
  - Root token auth via 1Password item hl23px33remaz2xecl5ecvvaem
  - secret/{service}/{account-slug} path convention

CONSUMPTION (auth.py in arc-scripts, agents)
  - Agents call get_gmail_credentials() or equivalent
  - Reads from OpenBao first, 1P fallback, local cache last
  - Token refresh writes back to OpenBao automatically
```

**authentication_agent and authentication_boss are not part of this chain.** They have their own separate SQLite credential database using AES-256-GCM encryption. They predate the OpenBao-based system and don't integrate with it. They're solving a different problem: generic API key management across cloud platforms (AWS, GCP, Azure, etc.) with audit logging - not Google OAuth token acquisition.

---

## The Actual Gap

No agent in the collection acts as a **unified credential gateway** - a single thing you can ask "give me credentials for Gmail for account X" and it handles OpenBao → 1P → local cache fallback transparently.

Right now:
- `auth.py` in arc-scripts does this for Gmail only, hardcoded to `me@advertisingreportcard.com`
- Each agent that needs Google auth has to implement its own lookup or import `auth.py`
- Nothing handles credentials for Drive, GTM, Analytics, etc. in agent context

**Whether to build an auth agent** depends on how many agents need Google auth. Currently only Gmail agents use it. If Drive/Calendar/etc. agents are coming, a shared credential gateway makes sense. If not, `auth.py` is sufficient.

---

## Recommendation

No action needed today. The current architecture is correct for its scale:

- `google-oauth-setup` = acquisition tool (infra, not agent)
- `auth.py` in arc-scripts = consumption layer for Gmail agents specifically
- OpenBao = canonical credential store

If/when a second Google service needs agent-level auth (e.g., a Drive agent, Calendar agent), that's when to extract `auth.py` logic into a shared `google-auth` library or lightweight credential service that all agents can call.
