#!/bin/bash
# SessionStart hook: inject audit state if sentinel active
SENTINEL="$HOME/.cache/memory-audit/active/sentinel"
[ ! -f "$SENTINEL" ] && exit 0

FILE=$(cat "$SENTINEL")
STATUS=$(python3 "$HOME/.claude/scripts/memory_audit/verify.py" status 2>/dev/null)
CLAIMS_JSON="$HOME/.cache/memory-audit/active/claims.json"

UNCHECKED=$(python3 -c "
import json, pathlib
claims = json.loads(pathlib.Path('$CLAIMS_JSON').read_text())
log = pathlib.Path('$HOME/.cache/memory-audit/active/bash.log').read_text() if pathlib.Path('$HOME/.cache/memory-audit/active/bash.log').exists() else ''
unchecked = [c for c in claims if not any(s in log for s in c['match_substrings'])]
for c in unchecked[:10]:
    print(f\"  - {c['type']}: {c['value']}\")
" 2>/dev/null)

cat <<EOF
## ACTIVE MEMORY AUDIT
File: $FILE
Status: $STATUS claims verified

Unchecked claims (run their verify_cmd):
$UNCHECKED

Required actions:
- Cannot Edit/Write the audited file until all claims verified (PreToolUse hook blocks)
- Cannot end turn until verify.py gate passes (Stop hook blocks)
- Run all three A/B/C options verbatim when presenting results

See: ~/.claude/scripts/memory_audit/PROCESS.md
EOF
exit 0
