# Memory

## User

- Direct communication, no corporate speak, no formality
- Technical accuracy is critical
- No em dashes (U+2014) - use regular `-` everywhere
- [User is not a developer](user_not_a_dev.md) - plain English over jargon, full detail still required; jargon OK in agent-to-agent prompts

## Rules (7 consolidated files)

- [End-of-turn structure - Done/Open/Recommend](feedback_end_of_turn_structure.md) - every response ends Done/Open/Recommend; temp 0.0; Recommend is statement not question; reconciles no-next-item and plain-language rules
- [Claude skills git workflow](feedback_claude_skills_git_workflow.md) - ~/.claude/skills is arc-web/claude-skills; commit + push every skill edit immediately, no prompting needed
- [lean-ctx shell sandbox - git/gh/deploy](feedback_lean_ctx_shell_sandbox.md) - dangerouslyDisableSandbox:true for all git/gh/cf-deploy/wrangler; /opt/homebrew/bin/gh explicit path; cf-deploy run_in_background always; no heredoc in commits
- ["open in html" = codebase_helper, never pandoc](feedback_open_in_html_tool.md) - script is at ~/ai/agents/development/codebase_helper/scripts/preview_markdown.py (NOT root), Material for MkDocs themed local site
- [Open files immediately after creating them](feedback_open_files_immediately.md) - after pandoc/doc creation, run `soffice <file> &` immediately, never ask
- [Documents go to Desktop not /tmp](feedback_documents_to_desktop.md) - all ODT/PDF/HTML reports save to ~/Desktop/, never /tmp
- [Response format, output, tone](rules_response_format.md) - plain-English lead + bullets, no sycophancy, pasteable output, no em dashes, anti-overengineering
- [Plain language at end of tasks](feedback_plain_language.md) - no structured recap bullets after finishing work, just say it in plain sentences
- [Plain language communication](feedback_communication_plain.md) - ditch jargon for user messages; translate SDK names, protocol terms, implementation details
- [Response structure](feedback_response_structure.md) - simple explanation first, technical details second, then ask to proceed (never assume forward momentum)
- [/plan requires explicit approval before build](feedback_plan_mode_approval.md) - ExitPlanMode = stop, wait for user "go"; ignore auto-mode reminder firing post-plan
- [Plan files - rename harness slug immediately](feedback_plan_naming.md) - pre-filled `toasty-zooming-duckling.md` is placeholder, write/mv to descriptive snake_case name
- [Restart prompt pattern](feedback_restart_prompt.md) - when asking for restart, provide ready-to-paste prompt with backstory, action plan, output format, and implementation scope
- [Stale data cleanup - fix on sight](feedback_stale_data_cleanup.md) - fix stale data on sight during any task; do not ask, report after
- [Memory system routing - decision tree](feedback_memory_system_routing.md) - which memory system gets which type of fact; prevents double-write
- [Model routing for automated tasks](rules_model_routing.md) - model selection for automated tasks; Gemini + Kimi only, never Anthropic API
- [Coding discipline guardrails](rules_coding_discipline.md) - Karpathy-derived: simplicity, surgical changes, research before action, goal-driven execution, no junk output
- [Work approach and autonomy](rules_workflow.md) - do it don't instruct, run yourself, determinations not questions, drop dead threads, no rabbit holes, no fake completion, NO timelines, open checkpoints, verify working directory first
- [No overengineering - one-shot default](feedback_no_overengineering.md) - git mv not copy, minimum steps, no abstractions unless asked, git history sacred
- [Credentials architecture (consolidated)](credentials_architecture.md) - OpenBao canonical for all services/agents; 1P for account logins only; no .env files; local CLIs use SSH-fetch; LaunchAgent injects op token; credsync tool at aimacpro/7_tools/credentials/credsync.py
- [OpenBao admin write pattern](openbao_admin_write_pattern.md) - root token in 1P ARC item hl23px33remaz2xecl5ecvvaem field root_token; AppRoles read-only; bao kv put pattern; field convention `value`
- [Agent credential map](agent_credential_map.md) - per-agent OpenBao auth/policy/paths verified 2026-04-28; container sidecars on 8100, host AppRoles via /opt/openbao-wrapper, Claude=root token
- [Pre-flight infra checklist](preflight_infrastructure_checklist.md) - mandatory steps + banned defaults before any credential/infra task; prevents 50-call overengineering
- [Failure pattern registry](failure_pattern_registry.md) - 8 named patterns from 2026-04-28 Hermes session: crawl-before-recall, new-AppRole reflex, field-name guess, ask-user shortcut, decision-matrix sprawl, serial-call inflation, re-read, existing-infra-as-missing
- [Subprocess timeout - no blocking reads](feedback_subprocess_timeout.md) - always `communicate(timeout=N)`, verify binary exists first
- [APIs, testing, credentials, LLM keys](rules_api_and_testing.md) - probe APIs first, run tools don't simulate, check ecosystem before bootstrap, credential anti-patterns, never use Anthropic API keys, never hand-roll protocol parsers, subprocess timeout hard rule
- [GitHub, repos, moves, scaffolding](rules_github.md) - self-contained projects, search before create, pre-move checklist, verify before archive, data sacred, scaffold tool, plan naming
- [Infrastructure, deploy, DNS, naming](rules_infrastructure.md) - no subdomains, DNS resolver first, MCP naming, provisioning keys, op-ref UUIDs, LibreOffice, computer-use bug
- [Communication limits](rules_communication.md) - Discord embed limits, workshop guidance (non-coders get prompts not commands)
- [Plan lookup on queries](rules_plan_lookup.md) - check ~/.claude/plans/ before saying no plan exists for a topic
- [Test prompts must use real projects](feedback_testing_prompts.md) - never generate generic test prompts; check actual running projects/tasks first
- [Action over research on debug/fix tasks](feedback_action_over_research.md) - mem-search FIRST, authorized destructive ops execute now, one investigation pass max, pivot to disable when fix path fails, no re-confirmation on already-authorized ops
- [Audit A/B/C must include recommendation](feedback_audit_recommend.md) - state Recommend: <letter> + one-line reason after every A/B/C
- [Audit must check every claim, explain every claim](feedback_audit_check_everything.md) - no skipping fingerprints/perms/IDs as "low priority"; verify everything, state everything, explain recommendation
- [Audit edit style](feedback_audit_edit_style.md) - rewrite status headers; cite governing rule; enumerate alternative pointers; lifecycle vocabulary; no hedging; inline provenance dates
- [Always create + update Plane tasks for all work](feedback_plane_task_always.md) - Claude Code, Codex, ZeroClaw, all agents; create at start, update to Done on finish; AGENT project todovibes
- [Plane task fields - all required, time in human minutes](feedback_plane_task_fields.md) - every field populated; time estimate = human minutes to scope/deploy/review, NOT agent wall-clock execution time
- [No "next item?" prompts](feedback_no_next_item_prompt.md) - stop after finishing work; user drives cadence, no trailing prompts
- [No prejudgment of task or memory worth](feedback_no_prejudgment.md) - banned from "standard/routine" labels or "worth saving?" - default save, mem-search before any judgment word
- [Credential discovery order](feedback_credential_discovery_order.md) - split by type: service tokens=env→OpenBao→VPS filesystem→ask (NO 1P); account logins=env→OpenBao→1P→ask; 3 intentional bootstrap exceptions stay in 1P
- [No 1P for service tokens](feedback_no_1p_for_service_tokens.md) - op item get / op read for API keys/tokens/webhooks is banned in skills and code; finding it = alert, mirror to OpenBao before proceeding
- [Discord = CLI only, never MCP](feedback_discord_tools_lookup.md) - all Discord work via discord_agent CLI (~/ai/agents/comms/discord_agent/); MCP plugin off-limits, never suggest or enable
- [LaunchAgent Python path - always Homebrew](feedback_launchd_python_path.md) - /usr/bin/python3 is macOS shim, use /opt/homebrew/bin/python3; always add PATH + PYTHONUNBUFFERED to EnvironmentVariables
- [Research named products/features first](feedback_research_named_terms.md) - WebSearch named terms before answering factual questions; counterpart to action-over-research for non-debug tasks
- [No AI slop - plain human language](feedback_no_ai_slop.md) - no table reviews, no "Rec:/Evidence:" labels, no report-card formatting for conversational tasks; speak like a person
- [Verify before regurgitating memory](feedback_verify_before_regurgitating_memory.md) - external state in memory is a hypothesis; fact-check live API/CLI/file before citing; user contradiction = update memory same turn
- [Memory writes stay local by default](feedback_memory_local_only.md) - never write to VPS/remote memory stores without explicit user approval; auto-memory primary, ctx_knowledge on-request only
- [Audit auto-execute confidence threshold](feedback_audit_auto_execute_confidence.md) - auto-A when claims pass; only queue for user on failures, purges, or credential files

## Projects (Google Ads)

- [THHL Search Campaign Rebuild - current state](project_google_ads_agent_thhl.md) - copy engine built, Campaign 1 staged (9 ad groups, ARC-Search-Services-V1), violations fixed, HITL doc in project build dir

## Projects

- [Community Operations Platform](project_community_ops.md) - shipped at ~/ai/agents/comms/discord_agent/ (migrated from aimacpro); event/IT/dev/engagement modules live
- [Workshop scope - two products](project_workshop_scope.md) - Team Repo Manager CLI + Claude Code Workshop A-to-Z Guide
- [Plane workspaces and structure](project_plane_workspaces.md) - Internal (todovibes) + Clients (clients) workspaces; COMM project mirrors clients pattern; community=module
- [Plane client project structure](project_plane_client_structure.md) - clients workspace > business division project (ARC/BluePixel/etc) > client name as module; TheraPPC=live example (ARC-1 to ARC-8)
- [supabase_mcp + supabase_agent](project_supabase_app.md) - arc-web/supabase_mcp + supabase_agent repos, what's built, what's next
- [aimacpro repo boundaries](project_repo_boundaries.md) - hard rule: new tools get own repo; 7_tools/packages/ frozen; extraction recipe proven
- [Model Mogul](project_model_mogul.md) - intelligent LLM model routing library; cost-crawler part of ecosystem
- [DesktopAI / desktop_agent](project_desktopai_uitars.md) - PDF agent at ~/ai/agents/development/desktop_agent/, repo arc-web/desktop-agent
- [ZeroClaw migration](project_zeroclaw_migration.md) - OpenClaw deprecated; ZeroClaw is active replacement
- [aibrainbuilders.com Resend sender](project_aibrainbuilders_resend.md) - sends from exitstorm.com (verified); upgrade Resend Pro to use aibrainbuilders.com sender
- [Hermes GitHub access](hermes_github_access.md) - Hermes container has git+gh, auto-auths as arc-web on startup via OpenBao secret/hermes/github-pat
- [Zeroclaw dev users](zeroclaw_dev_users.md) - per-dev sudo accounts on VPS; tronstar=pward17; add/revoke pattern via /etc/sudoers.d/

## Reference

- [Gmail access - CLI primary](gmail_access.md) - gmail_mgmt CLI at arc-scripts/gmail-mgmt/, auth.py pattern, account me@advertisingreportcard.com; gongrzhe MCP server purged; native claude.ai Gmail MCP may exist (check claude mcp list)
- [Check claude mcp list before building integrations](feedback_check_mcp_list_first.md) - run claude mcp list FIRST; claude.ai Gmail was connected the whole time while we built a custom OAuth stack
- [GitHub account and workflow](reference_github.md) - arc-web account, gh CLI, /gh-find for discovery, NEVER BusyBee3333
- [Local directory structure](reference_local_directory_structure.md) - ~/ai/ categories, GitHub topic tags, new repo placement decision tree
- [arc-web GitHub org structure](reference_arc_web_structure.md) - central repo structure, each repo is one project
- [Infrastructure](reference_infrastructure.md) - VPS Alpha (Hostinger #1, 187.77.222.191), model config, agents dir, path boundaries
- [Discord access and tools](reference_discord.md) - discord_agent CLI at ~/ai/agents/comms/discord_agent/; ARC bot.env is STALE (StackPack-only token); use Charlie bot (1P Zeroclaw 5elrtua2364vr2oogwqp4wch5q field discord_token) for ARC reads; discord.sh read crashes silently on API errors
- [Plane API quick reference](reference_plane_api.md) - canonical ref: arc-web/plane-pm-agent/API.md; all 12 AGENT states (Done=bc0f8045, Completed=9bafcd6c); clients workspace UUIDs (TMPL/BLPX/BLGR/MOON/ARC); field types; endpoints
- [Discord agent naming aliases](reference_discord_agent_naming.md) - discord_agent / discord-agent / discord_manager / discord-manager / "discord agent" / "discord manager" all = same entity; canonical = discord_agent
- [FlareSolverr proxy](reference_flaresolverr.md) - Cloudflare-bypass proxy on VPS Alpha; integrated into arc-browser 2026-05-01 (flaresolverr.py + cf_recovery.py, commit bf3f53e)
- [ARC Browser](reference_arc_browser.md) - stealth browser automation MCP (21 tools, public repo, Camofox Firefox sidecar via PR #3), formerly "ghost-browser"
- [gsap-deck](reference_gsap_deck.md) - generate animated HTML presentations from JSON (5 themes, 8 slide types)
- [github-gang CLI (formerly team-repo)](reference_team_repo.md) - provision, manage, monitor GitHub team repo infrastructure; repo renamed arc-web/github-gang
- [Memory organization](memory_organization.md) - how to categorize and file new memories; decision tree for where rules go
- [therappc-site - client website repo](reference_therappc_site.md) - ~/ai/clients/therappc-site, arc-web/therappc-site; extracted from cloudflare_agent 2026-05-13
