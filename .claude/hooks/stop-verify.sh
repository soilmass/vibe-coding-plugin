#!/usr/bin/env bash
# Stop Hook — Build verification before Claude stops
# Blocks if type errors exist, warns about lint errors and uncommitted changes

set -euo pipefail

EXIT_CODE=0

# 1. TypeScript check (blocks on error)
if [ -f "tsconfig.json" ] && command -v npx &>/dev/null; then
  echo "Running type check..." >&2
  if ! timeout 120 npx tsc --noEmit 2>&1; then
    echo "" >&2
    echo "BLOCKED: TypeScript errors must be fixed before stopping." >&2
    exit 1
  fi
fi

# 2. Lint check (warns but doesn't block)
if [ -f "node_modules/.bin/next" ] && command -v npx &>/dev/null; then
  echo "Running lint check..." >&2
  LINT_OUTPUT=$(npx next lint 2>&1) || {
    echo "" >&2
    echo "WARNING: Lint issues detected:" >&2
    echo "$LINT_OUTPUT" >&2
    echo "Consider fixing these before your next session." >&2
  }
fi

# 3. Check for .env.local in git staging area (would leak secrets)
if [ -d ".git" ]; then
  STAGED_ENV=$(git diff --cached --name-only 2>/dev/null | grep -E '^\.env\.local$|^\.env\.[^e]' || true)
  if [ -n "$STAGED_ENV" ]; then
    echo "" >&2
    echo "BLOCKED: .env file staged for commit — this would leak secrets:" >&2
    echo "$STAGED_ENV" >&2
    echo "Run: git reset HEAD $STAGED_ENV" >&2
    exit 1
  fi
fi

# 4. Merge conflict detection (blocks)
if [ -d ".git" ]; then
  CONFLICTS=$(git status --porcelain 2>/dev/null | grep -E '^(U.|.U|AA|DD) ' || true)
  if [ -n "$CONFLICTS" ]; then
    echo "" >&2
    echo "BLOCKED: Unresolved merge conflicts in:" >&2
    echo "$CONFLICTS" >&2
    echo "Resolve merge conflicts before stopping." >&2
    exit 1
  fi
fi

# 5. Prisma schema validation (warns)
if [ -f "prisma/schema.prisma" ] && command -v npx &>/dev/null; then
  if ! npx prisma validate 2>/dev/null; then
    echo "" >&2
    echo "WARNING: Invalid Prisma schema. Run 'npx prisma validate' to see errors." >&2
  fi
fi

# 6. Stale stashes warning
if [ -d ".git" ]; then
  STASH_COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  if [ "$STASH_COUNT" -gt 0 ]; then
    echo "" >&2
    echo "INFO: $STASH_COUNT stashed change(s) exist. Run 'git stash list' to review." >&2
  fi
fi

# 7. Git status check (reminder)
if [ -d ".git" ]; then
  UNCOMMITTED=$(git status --porcelain 2>/dev/null)
  if [ -n "$UNCOMMITTED" ]; then
    echo "" >&2
    echo "REMINDER: You have uncommitted changes:" >&2
    echo "$UNCOMMITTED" | head -10 >&2
    TOTAL=$(echo "$UNCOMMITTED" | wc -l | tr -d ' ')
    if [ "$TOTAL" -gt 10 ]; then
      echo "... and $((TOTAL - 10)) more files" >&2
    fi
    echo "Consider committing before ending your session." >&2
  fi
fi

exit $EXIT_CODE
