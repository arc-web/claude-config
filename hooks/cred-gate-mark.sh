#!/bin/bash
set -euo pipefail
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
SID="${CLAUDE_SESSION_ID:-default}"
SENTINEL="/tmp/cred-gate-${SID}"
case "$TOOL" in
  Read|View)
    PATH_ARG=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // empty' 2>/dev/null)
    if echo "$PATH_ARG" | grep -q "skills/credentials/SKILL.md"; then
      touch "$SENTINEL"
    fi
    if echo "$PATH_ARG" | grep -q "projects/-Users-home/memory/"; then
      touch "$SENTINEL"
    fi
    ;;
  *ctx_search*|*ctx_knowledge*)
    touch "$SENTINEL"
    ;;
esac
exit 0
