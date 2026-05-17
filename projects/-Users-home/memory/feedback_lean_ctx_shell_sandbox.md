---
name: lean-ctx shell sandbox - git/gh/deploy commands
description: lean-ctx intercepts shell commands and fails with _lc command not found. Use dangerouslyDisableSandbox + explicit binary paths for git, gh, cf-deploy.
type: feedback
originSessionId: 8cab95d3-0c83-4722-af67-bc247670d7d7
---
lean-ctx wraps shell execution. Any git, gh, or cf-deploy command run through normal Bash will fail with `_lc command not found` unless sandbox is bypassed.

**Rule:** For git, gh, wrangler, cf-deploy, and any other CLI tool that lean-ctx intercepts - always use:

```json
{ "dangerouslyDisableSandbox": true }
```

**Explicit binary paths required:**
- git: `git` (works with dangerouslyDisableSandbox)
- gh: `/opt/homebrew/bin/gh`
- cf-deploy: `cf-deploy` (works with dangerouslyDisableSandbox)
- wrangler: `wrangler` (works with dangerouslyDisableSandbox)
- /bin/ls, /bin/cp, /bin/mv, /bin/rm: always use full path

**Heredoc in git commit messages breaks via lean-ctx.** Use direct string:
```bash
# BREAKS:
git commit -m "$(cat <<'EOF'
message
EOF
)"

# WORKS:
git commit -m "message line 1\n\nline 2" 
# OR pass multi-line directly as a quoted string with dangerouslyDisableSandbox: true
```

**cf-deploy blocks the shell** - always run with `run_in_background: true`, then `sleep 12 && cat <output-file>` to read result.

**ctx_read does NOT satisfy Edit's native Read requirement.** Must call native Read tool on a file before Edit will accept it. lean-ctx reads and native reads are tracked separately.

**Shell functions (`ci() { ... }`) break entirely.** Defining a function and calling it fails - lean-ctx injects `_lc` and the function invocation hits `command not found`. Use Python subprocess directly instead. See `reference_plane_api.md` for the working multi-issue pattern.

**Why:** lean-ctx hooks into shell execution for compression/logging. This intercepts subprocess calls and breaks binary resolution. dangerouslyDisableSandbox bypasses the hook entirely.

**How to apply:** Any turn involving git operations, gh CLI, wrangler deploy, or cf-deploy - set dangerouslyDisableSandbox: true on those Bash calls before running them. Don't discover this mid-commit.
