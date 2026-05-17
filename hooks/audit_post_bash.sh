#!/bin/bash
# PostToolUse hook (Bash): log every bash call + output to audit bash.log
SENTINEL="${MEMORY_AUDIT_CACHE:-$HOME/.cache/memory-audit/active}/sentinel"
[ ! -f "$SENTINEL" ] && exit 0

LOG="${MEMORY_AUDIT_CACHE:-$HOME/.cache/memory-audit/active}/bash.log"
INPUT=$(cat)

python3 - <<PYEOF >> "$LOG" 2>/dev/null
import json, sys
data = json.loads('''$INPUT''')
cmd = data.get('tool_input', {}).get('command', '')
out = data.get('tool_response', {}).get('stdout', '') if isinstance(data.get('tool_response'), dict) else str(data.get('tool_response', ''))
err = data.get('tool_response', {}).get('stderr', '') if isinstance(data.get('tool_response'), dict) else ''
print('=== CMD ===')
print(cmd)
print('=== STDOUT ===')
print(out)
print('=== STDERR ===')
print(err)
print()
PYEOF
exit 0
