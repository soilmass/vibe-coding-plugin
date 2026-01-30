#!/usr/bin/env bash
# Pre-Compact Hook — Preserve project context before context compaction
# Injects architecture summary into systemMessage

set -euo pipefail

echo "=== PROJECT CONTEXT (preserved across compaction) ===" >&2

# Stack info
echo "Stack: Next.js 15, React 19, TypeScript, Tailwind v4, shadcn/ui" >&2

# Package info
if [ -f "package.json" ]; then
  echo "Project: $(node -e "console.log(require('./package.json').name || 'unnamed')" 2>/dev/null || echo 'unknown')" >&2
fi

# Route structure
if [ -d "src/app" ]; then
  echo "Routes:" >&2
  find src/app \( -name "page.tsx" -o -name "page.ts" \) 2>/dev/null | sort | head -20 | while read -r route; do
    echo "  $route" >&2
  done
fi

# Prisma models
if [ -f "prisma/schema.prisma" ]; then
  echo "DB Models:" >&2
  grep "^model " prisma/schema.prisma 2>/dev/null | while read -r line; do
    echo "  $line" >&2
  done
fi

# Auth status
if [ -f "src/lib/auth.ts" ] || [ -f "src/auth.ts" ]; then
  echo "Auth: Auth.js v5 configured" >&2
fi

# Tailwind version
if [ -f "tailwind.config.ts" ] || [ -f "tailwind.config.js" ]; then
  echo "Tailwind: v3" >&2
elif grep -q '@import "tailwindcss"' src/app/globals.css app/globals.css styles/globals.css 2>/dev/null; then
  echo "Tailwind: v4" >&2
fi

# Testing setup
([ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]) && echo "Testing: Vitest" >&2
([ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]) && echo "Testing: Playwright (E2E)" >&2

# Middleware
{ [ -f "src/middleware.ts" ] || [ -f "middleware.ts" ]; } && echo "Middleware: present" >&2

# Active git branch
if [ -d ".git" ]; then
  echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')" >&2
fi

# Last session context
if [ -f ".claude/state/last-session.md" ]; then
  echo "Previous session context:" >&2
  head -20 .claude/state/last-session.md >&2
fi

echo "=== END PROJECT CONTEXT ===" >&2
