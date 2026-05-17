#!/bin/bash
set -euo pipefail
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0
KEYWORDS='credential|cred|secret|vault|bao|openbao|ssh zeroclaw|vps|approle|token|api.key|sudo|adduser|onboard|access|deploy|provision|hostinger|1password|op item|op get|settings.local'
if echo "$CMD" | grep -qiE "$KEYWORDS"; then
  SID="${CLAUDE_SESSION_ID:-default}"
  SENTINEL="/tmp/cred-gate-${SID}"
  if [ ! -f "$SENTINEL" ]; then
    cat << BLOCK
{"decision":"block","reason":"MANDATORY GATE: Before any credential/infrastructure Bash, you MUST first: (1) Read ~/.claude/skills/credentials/SKILL.md OR (2) Read any file in ~/.claude/projects/-Users-home/memory/ that covers this domain. After reading, this gate auto-clears. Routing reference: feedback_memory_system_routing.md"}
BLOCK
    exit 0
  fi
fi
exit 0
