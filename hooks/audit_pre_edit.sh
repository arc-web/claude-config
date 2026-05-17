#!/bin/bash
# PreToolUse hook (Edit/Write/MultiEdit): block edits to audited file until all claims checked
SENTINEL="${MEMORY_AUDIT_CACHE:-$HOME/.cache/memory-audit/active}/sentinel"
[ ! -f "$SENTINEL" ] && exit 0

# Read tool input from stdin (Claude Code sends JSON)
INPUT=$(cat)
TARGET=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

AUDITED=$(cat "$SENTINEL")
[ "$TARGET" != "$AUDITED" ] && exit 0

# Same file - check if all claims verified
GATE_OUT=$(python3 "$HOME/.claude/scripts/memory_audit/verify.py" gate 2>&1)
GATE_EXIT=$?

if [ $GATE_EXIT -eq 2 ]; then
  python3 -c "
import json
result = json.loads('''$GATE_OUT''')
print(json.dumps({
    'decision': 'block',
    'reason': f\"Cannot edit audited memory file. {result['unchecked_count']}/{result['total']} claims unchecked. Run their verify_cmd first.\"
}))
"
  exit 0
fi
exit 0
