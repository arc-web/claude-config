#!/usr/bin/env bash
# Stop hook: auto-commit + push changes in ~/.claude to arc-web/claude-config
# Only commits safe tracked paths - never secrets, sessions, settings, or plugins

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
GIT="/usr/bin/git"

cd "$CLAUDE_DIR"

# Not a git repo - skip silently
$GIT rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Check for uncommitted changes in safe paths only
SAFE_PATHS=(
  "CLAUDE.md"
  "RTK.md"
  "audit_directive.md"
  "hooks"
  "plans"
  "rules"
  "projects/-Users-home/memory"
)

DIRTY=$($GIT status --short "${SAFE_PATHS[@]}" 2>/dev/null | wc -l | tr -d ' ')

[ "$DIRTY" = "0" ] && exit 0

# Stage only safe paths
$GIT add "${SAFE_PATHS[@]}" 2>/dev/null || true

# Nothing staged after filtering
STAGED=$($GIT diff --cached --name-only | wc -l | tr -d ' ')
[ "$STAGED" = "0" ] && exit 0

# Build commit message from what changed
SUMMARY=$($GIT diff --cached --name-only | head -5 | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
[ "$($GIT diff --cached --name-only | wc -l | tr -d ' ')" -gt 5 ] && SUMMARY="$SUMMARY ..."

$GIT commit -m "auto: update ${SUMMARY}" \
  --author="Claude Code <noreply@anthropic.com>" \
  -q 2>/dev/null || exit 0

# Push via HTTPS with gh token
GH_BIN="/opt/homebrew/bin/gh"
[ -x "$GH_BIN" ] || exit 0

TOKEN=$("$GH_BIN" auth token 2>/dev/null) || exit 0
[ -z "$TOKEN" ] && exit 0

REMOTE_URL="https://x-access-token:${TOKEN}@github.com/arc-web/claude-config.git"
$GIT push "$REMOTE_URL" main -q 2>/dev/null || true

exit 0
