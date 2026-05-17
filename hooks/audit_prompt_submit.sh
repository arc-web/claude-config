#!/bin/bash
# UserPromptSubmit hook: prepend audit state if sentinel active
SENTINEL="$HOME/.cache/memory-audit/active/sentinel"
[ ! -f "$SENTINEL" ] && exit 0

FILE=$(cat "$SENTINEL")
STATUS=$(python3 "$HOME/.claude/scripts/memory_audit/verify.py" status 2>/dev/null)

cat <<EOF
MEMORY AUDIT ACTIVE
File: $FILE
Status: $STATUS claims verified

Required: run remaining verify_cmd from claims.json before any other action. Cannot Edit file or end turn until all checked. Present A/B/C with all three options every time.
EOF
exit 0
