#!/usr/bin/env bash
# Session Resume Hook — Lightweight state refresh
# Only checks dev server and git state (faster than full detection)

set -euo pipefail

ENV_FILE="${CLAUDE_ENV_FILE:-/dev/null}"

# Dev server status
DEV_PORT=""
if command -v lsof &>/dev/null; then
  DEV_PORT=$(lsof -ti:3000 2>/dev/null | head -1 || true)
fi
if [ -n "$DEV_PORT" ]; then
  echo "DEV_SERVER_RUNNING=true" >> "$ENV_FILE"
else
  echo "DEV_SERVER_RUNNING=false" >> "$ENV_FILE"
fi

# Git state
if [ -d ".git" ]; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  echo "GIT_BRANCH=$GIT_BRANCH" >> "$ENV_FILE"

  DIRTY=$(git status --porcelain 2>/dev/null | head -1)
  if [ -n "$DIRTY" ]; then
    echo "GIT_DIRTY=true" >> "$ENV_FILE"
  else
    echo "GIT_DIRTY=false" >> "$ENV_FILE"
  fi
fi

# Check if node_modules is fresh (in case npm install was run externally)
[ -d "node_modules" ] && echo "HAS_NODE_MODULES=true" >> "$ENV_FILE"

exit 0
