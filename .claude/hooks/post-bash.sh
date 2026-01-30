#!/usr/bin/env bash
# Post-Bash Hook
# Runs state checks after npm install or prisma migrate commands

set -euo pipefail

HOOK_INPUT=$(cat)
COMMAND=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

if [ -z "$COMMAND" ]; then
  exit 0
fi

# After npm install — regenerate Prisma client if schema exists
if echo "$COMMAND" | grep -qE '^npm (install|i|ci)\b'; then
  if [ -f "prisma/schema.prisma" ]; then
    echo "Regenerating Prisma client after install..." >&2
    npx prisma generate 2>/dev/null || true
  fi
fi

# After prisma migrate — remind about schema changes
if echo "$COMMAND" | grep -qE '^npx prisma migrate'; then
  echo "Migration applied. Remember to update Server Actions and types if schema changed." >&2
fi

# After prisma db push — regenerate client
if echo "$COMMAND" | grep -qE '^npx prisma db push'; then
  echo "Schema pushed. Regenerating Prisma client..." >&2
  npx prisma generate 2>/dev/null || true
fi

exit 0
