#!/bin/bash
# Statusline: show audit state if sentinel active, else passthrough
SENTINEL="$HOME/.cache/memory-audit/active/sentinel"
if [ -f "$SENTINEL" ]; then
  FILE=$(basename "$(cat "$SENTINEL")")
  STATUS=$(python3 "$HOME/.claude/scripts/memory_audit/verify.py" status 2>/dev/null)
  echo "[AUDIT: $FILE | $STATUS]"
else
  # passthrough caveman statusline if it exists
  CAVEMAN="$HOME/.claude/plugins/cache/caveman/caveman/84cc3c14fa1e/hooks/caveman-statusline.sh"
  [ -x "$CAVEMAN" ] && bash "$CAVEMAN" || echo ""
fi
