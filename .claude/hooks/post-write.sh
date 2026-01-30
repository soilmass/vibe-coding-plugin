#!/usr/bin/env bash
# Post-Write/Edit Hook
# Auto-formats with Prettier and runs tsc on TypeScript files

set -euo pipefail

HOOK_INPUT=$(cat)
FILE_PATH=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Warn if next.config changed — .next cache may be stale
if echo "$FILE_PATH" | grep -q "next.config"; then
  echo "next.config changed — .next cache may be stale. Consider running: rm -rf .next && npm run build" >&2
fi

# Only process TypeScript/JavaScript files
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    ;;
  *)
    exit 0
    ;;
esac

# Auto-format with Prettier (if available)
if command -v npx &>/dev/null && [ -f "node_modules/.bin/prettier" ]; then
  npx prettier --write "$FILE_PATH" 2>/dev/null || true
fi

# Auto-fix with ESLint (if available)
if command -v npx &>/dev/null && [ -f "node_modules/.bin/eslint" ]; then
  npx eslint --fix "$FILE_PATH" 2>/dev/null || true
fi

# Type-check TypeScript files
case "$FILE_PATH" in
  *.ts|*.tsx)
    if command -v npx &>/dev/null && [ -f "tsconfig.json" ]; then
      TSC_OUTPUT=$(timeout 30 npx tsc --noEmit 2>&1)
      TSC_EXIT=$?
      if [ $TSC_EXIT -ne 0 ]; then
        if [ $TSC_EXIT -eq 124 ]; then
          echo "tsc timed out (>30s) while checking $FILE_PATH." >&2
        else
          echo "TypeScript errors detected after writing $FILE_PATH:" >&2
          echo "$TSC_OUTPUT" >&2
          echo "" >&2
          echo "Please fix these type errors." >&2
        fi
      fi
    fi
    ;;
esac

exit 0
