#!/usr/bin/env bash
# Session End Hook — Save session state and clean up

set -euo pipefail

STATE_DIR=".claude/state"
mkdir -p "$STATE_DIR"

# Write session summary
{
  echo "# Last Session Summary"
  echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""

  # Git state
  if [ -d ".git" ]; then
    echo "## Git State"
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo ""
    echo "### Recent commits"
    git log --oneline -5 2>/dev/null || echo "No commits"
    echo ""

    UNCOMMITTED=$(git status --porcelain 2>/dev/null)
    if [ -n "$UNCOMMITTED" ]; then
      echo "### Uncommitted changes"
      echo "\`\`\`"
      echo "$UNCOMMITTED"
      echo "\`\`\`"
      echo ""
    fi
  fi

  # Build state
  if [ -f "tsconfig.json" ]; then
    echo "## Build State"
    if timeout 30 npx tsc --noEmit 2>/dev/null; then
      echo "TypeScript: PASS"
    else
      echo "TypeScript: FAIL (has errors)"
    fi
    echo ""
  fi

  # Dev server
  DEV_PORT=""
  if command -v lsof &>/dev/null; then
    DEV_PORT=$(lsof -ti:3000 2>/dev/null | head -1 || true)
  fi
  if [ -n "$DEV_PORT" ]; then
    echo "Dev server: Running on port 3000"
  else
    echo "Dev server: Not running"
  fi

} > "$STATE_DIR/last-session.md" 2>/dev/null || true

# Clean up temp files
find /tmp -name "claude-*" -mmin +60 -delete 2>/dev/null || true

exit 0
