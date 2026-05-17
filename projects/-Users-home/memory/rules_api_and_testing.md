---
name: API integration, testing, credentials, and LLM key rules
description: Probe APIs before typing, test tools by running them, check ecosystem before bootstrap scripts, credential workflow, never use Anthropic API keys
type: feedback
originSessionId: 48314f94-ae1f-4493-8507-4fbb8567aa04
---
# API-first rule - probe before writing types

Before writing any API client, types, or workflows for a new integration: probe the real endpoints first.

```bash
curl -H "Authorization: Bearer $KEY" "https://api.example.com/endpoint?limit=1" | jq .
```

Rules:
1. Check what the platform already provides before adding external deps to replicate it (Fathom generates summaries - don't add an LLM).
2. Probe 2-3 key endpoints and read actual responses before writing a single type.
3. Never put a 1Password ref in `.env.1p` for a secret that doesn't exist yet - comment it out.
4. Sibling packages in active dev use `file:` paths in package.json, not `github:`. npm skips devDeps for git packages so `prepare: "tsc"` silently fails.

# Testing tools and plugins

1. **Run the tool, don't simulate.** The test IS invoking the tool. Never craft scenarios to "trick" a tool. Never inject bad code to trigger a guard. Just run with real inputs.
2. **Read every file before writing a prompt that references code.** Source, tests, config, types, deps. Generic prompts like "your modules" produce useless output.
3. **Read the tool's own documentation before invoking.** SKILL.md, `--help`, MCP schema, required params, prerequisites.
4. **Every output must be directly pasteable** - see rules_response_format.md.
5. **When the first approach is wrong, throw it away completely.** Don't reword. Identify what was fundamentally wrong. Rebuild from zero.
6. **Never edit user files to test.** Testing a plugin means running it, not injecting garbage into production code.
7. **"Test X" means run X.** Not describe how to run X. The deliverable is execution or a pasteable invocation.

# Check ecosystem before bootstrap scripts

Before writing any `setup_X.sh` / `bootstrap_X.sh` / `create_X.sh`, map what exists:

- `4_agents/` - which agents already run, where, authentication?
- `7_tools/credentials/architecture.md` - the topology doc. Read first, don't redescribe.
- `secrets_manifest.yaml` - what already exists in each vault?
- `op item list --vault Zeroclaw` - if items come back, there's a working SA chain. Don't build a second.
- Running containers/services on the VPS - already have tokens plumbed. You're observing, not creating.

If the thing already works (reads succeed, items exist, architecture doc describes as live), your job is to DOCUMENT and VERIFY, not to create. Rotation scripts are framed as rotation (create new + revoke old + re-test), not bootstrap.

**The chain is wired.** 1P ↔ VPS, SSH, agents, Discord bots, Supabase access - assume "set up" until the repo or `op` command proves otherwise.

# Credential and SSH workflow rules

Procedures live in `~/.claude/skills/credentials/SKILL.md`. These are the anti-patterns:

- Do, don't instruct. `pbcopy` + `open URL`, never "go to X and paste Y".
- Check `--help` before using unfamiliar CLI flags.
- Never delete until the replacement is verified working.
- Search before create (`op item list | grep`) to avoid duplicates.
- Test with real operations (`op item list`), not status commands (`op whoami` lies with desktop app integration).
- If something fails twice the same way, stop and try a completely different approach.
- Report when done, not in progress - no status walls mid-task.
- Order: Generate → Register → Verify → Test → Backup → Clean up. Never skip ahead.

# Never hand-roll protocol parsers

If a library exists for a protocol, use it. Never write custom byte readers, frame parsers, or wire-format decoders.

- MCP → use `@modelcontextprotocol/sdk` `Client` + `StdioClientTransport`
- HTTP → use `fetch`/`httpx`, not raw socket reads
- JSON-RPC → use an RPC library, not `read(1)` loops

Hand-rolled parsers fail silently on unexpected output (stderr instead of stdout, wrong framing, connection drops) and have no built-in timeout. The SDK already handles all of this.

# Subprocess timeout - hard rule

Every subprocess spawn must have a hard timeout. No exceptions.

- Python: `proc.communicate(timeout=30)` - never `proc.stdout.read(1)` loops
- Bash: prefix with `timeout 30 <command>` - OS kills it hard
- Verify binary path exists before spawning: `test -f /path/to/bin || exit 1`
- Kill any previous instance first: `pkill -f script_name.py || true`

Blocking reads with no timeout → infinite hang at 100% CPU if child dies or writes to wrong fd.

# NEVER use Anthropic API keys

Never suggest, use, or ask about Anthropic API keys (`sk-ant-...`) in any agent, workflow, or tool. Existing Claude Code session auth is separate and fine - this rule is about programmatic API keys in code.

User does NOT use Anthropic API directly for personal Claude usage. They have a Claude account - tokens consumed via that subscription. Never suggest API key approaches for anything the user will run themselves. `/cost` in Claude Code session is the right way to measure token usage.

Defaults when an agent needs an LLM call:
1. Kimi (Moonshot AI) - `KIMI_API_KEY` / `bao kv get secret/kimi` (OpenBao, verified 2026-05-01)
2. DeepSeek - `DEEPSEEK_API_KEY` / `bao kv get secret/deepseek` (OpenBao, verified 2026-05-01)
3. Qwen (Alibaba) - `QWEN_API_KEY` / `bao kv get secret/qwen` (OpenBao)

All three route through OpenRouter in practice - see `rules_model_routing.md` for model/tier table and default (`moonshot/kimi-k2`). Keys are NOT in 1P ARC vault (op:// refs retired 2026-05-01). All three are OpenAI-compatible. Use `openai` npm package or `httpx` with custom base URL. Not `@anthropic-ai/sdk`.
