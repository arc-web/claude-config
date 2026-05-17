#!/bin/bash
# Stop hook: gate turn end on verifier pass
SENTINEL="${MEMORY_AUDIT_CACHE:-$HOME/.cache/memory-audit/active}/sentinel"
[ ! -f "$SENTINEL" ] && exit 0

GATE_OUT=$(python3 "$HOME/.claude/scripts/memory_audit/verify.py" gate 2>&1)
GATE_EXIT=$?

if [ $GATE_EXIT -eq 2 ]; then
  python3 -c "
import json
result = json.loads('''$GATE_OUT''')
unchecked = result.get('unchecked', [])
cmds = '\n'.join(f\"  - {c['verify_cmd']}\" for c in unchecked[:10])
reason = f\"MEMORY AUDIT BLOCKED. {result['unchecked_count']}/{result['total']} claims unchecked. Run these:\n{cmds}\"
print(json.dumps({'decision': 'block', 'reason': reason}))
"
  exit 0
fi
exit 0
