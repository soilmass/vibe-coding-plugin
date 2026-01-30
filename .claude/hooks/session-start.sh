#!/usr/bin/env bash
# Session Start Hook — Full project state detection
# Writes key-value pairs to CLAUDE_ENV_FILE for skills to reference

set -euo pipefail

ENV_FILE="${CLAUDE_ENV_FILE:-/dev/null}"

# Node.js / Package Manager
if [ -f "package.json" ]; then
  echo "HAS_PACKAGE_JSON=true" >> "$ENV_FILE"

  # Detect package manager
  if [ -f "bun.lockb" ]; then
    echo "PACKAGE_MANAGER=bun" >> "$ENV_FILE"
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "PACKAGE_MANAGER=pnpm" >> "$ENV_FILE"
  elif [ -f "yarn.lock" ]; then
    echo "PACKAGE_MANAGER=yarn" >> "$ENV_FILE"
  else
    echo "PACKAGE_MANAGER=npm" >> "$ENV_FILE"
  fi

  # Node modules installed?
  [ -d "node_modules" ] && echo "HAS_NODE_MODULES=true" >> "$ENV_FILE"
fi

# Next.js
if [ -f "next.config.ts" ] || [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
  echo "HAS_NEXT=true" >> "$ENV_FILE"

  # Next.js version
  if [ -f "node_modules/next/package.json" ]; then
    NEXT_VERSION=$(node -e "console.log(require('./node_modules/next/package.json').version)" 2>/dev/null || echo "unknown")
    echo "NEXT_VERSION=$NEXT_VERSION" >> "$ENV_FILE"
  fi

  # App Router or Pages Router
  if [ -d "src/app" ] || [ -d "app" ]; then
    echo "ROUTER_TYPE=app" >> "$ENV_FILE"
  elif [ -d "src/pages" ] || [ -d "pages" ]; then
    echo "ROUTER_TYPE=pages" >> "$ENV_FILE"
  fi
fi

# React version
if [ -f "node_modules/react/package.json" ]; then
  REACT_VERSION=$(node -e "console.log(require('./node_modules/react/package.json').version)" 2>/dev/null || echo "unknown")
  echo "REACT_VERSION=$REACT_VERSION" >> "$ENV_FILE"
fi

# TypeScript
[ -f "tsconfig.json" ] && echo "HAS_TYPESCRIPT=true" >> "$ENV_FILE"

# Prisma
if [ -d "prisma" ]; then
  echo "HAS_PRISMA=true" >> "$ENV_FILE"
  [ -f "prisma/schema.prisma" ] && echo "HAS_PRISMA_SCHEMA=true" >> "$ENV_FILE"
fi

# Auth
if [ -f "src/lib/auth.ts" ] || [ -f "src/auth.ts" ] || [ -f "auth.ts" ]; then
  echo "HAS_AUTH=true" >> "$ENV_FILE"
fi

# Tailwind
if [ -f "tailwind.config.ts" ] || [ -f "tailwind.config.js" ]; then
  echo "TAILWIND_VERSION=3" >> "$ENV_FILE"
elif grep -q '@import "tailwindcss"' src/app/globals.css app/globals.css styles/globals.css 2>/dev/null || grep -q "@import 'tailwindcss'" src/app/globals.css app/globals.css styles/globals.css 2>/dev/null; then
  echo "TAILWIND_VERSION=4" >> "$ENV_FILE"
fi

# shadcn/ui
[ -f "components.json" ] && echo "HAS_SHADCN=true" >> "$ENV_FILE"

# Turborepo
[ -f "turbo.json" ] && echo "HAS_TURBO=true" >> "$ENV_FILE"

# Testing
([ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]) && echo "HAS_VITEST=true" >> "$ENV_FILE"
([ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]) && echo "HAS_PLAYWRIGHT=true" >> "$ENV_FILE"

# Dev server detection
DEV_PORT=""
if command -v lsof &>/dev/null; then
  DEV_PORT=$(lsof -ti:3000 2>/dev/null | head -1 || true)
fi
[ -n "$DEV_PORT" ] && echo "DEV_SERVER_RUNNING=true" >> "$ENV_FILE"

# Git state
if [ -d ".git" ]; then
  echo "HAS_GIT=true" >> "$ENV_FILE"
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  echo "GIT_BRANCH=$GIT_BRANCH" >> "$ENV_FILE"

  DIRTY=$(git status --porcelain 2>/dev/null | head -1)
  [ -n "$DIRTY" ] && echo "GIT_DIRTY=true" >> "$ENV_FILE"
fi

# Zod
[ -f "package.json" ] && grep -q '"zod"' package.json && echo "HAS_ZOD=true" >> "$ENV_FILE"

# next-intl
[ -f "package.json" ] && grep -q '"next-intl"' package.json && echo "HAS_NEXT_INTL=true" >> "$ENV_FILE"

# nuqs
[ -f "package.json" ] && grep -q '"nuqs"' package.json && echo "HAS_NUQS=true" >> "$ENV_FILE"

# React Query
[ -f "package.json" ] && grep -q '"@tanstack/react-query"' package.json && echo "HAS_REACT_QUERY=true" >> "$ENV_FILE"

# ESLint
([ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ] || [ -f "eslint.config.mjs" ]) && echo "HAS_ESLINT=true" >> "$ENV_FILE"

# Prettier
([ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]) && echo "HAS_PRETTIER=true" >> "$ENV_FILE"

# Inngest (background jobs)
[ -f "package.json" ] && grep -q '"inngest"' package.json && echo "HAS_INNGEST=true" >> "$ENV_FILE"

# Resend (email)
[ -f "package.json" ] && grep -q '"resend"' package.json && echo "HAS_RESEND=true" >> "$ENV_FILE"

# Stripe (payments)
[ -f "package.json" ] && grep -q '"stripe"' package.json && echo "HAS_STRIPE=true" >> "$ENV_FILE"

# Uploadthing (file uploads)
[ -f "package.json" ] && grep -q '"uploadthing"' package.json && echo "HAS_UPLOADTHING=true" >> "$ENV_FILE"

# Drizzle ORM
[ -f "package.json" ] && grep -q '"drizzle-orm"' package.json && echo "HAS_DRIZZLE=true" >> "$ENV_FILE"

# SWR
[ -f "package.json" ] && grep -q '"swr"' package.json && echo "HAS_SWR=true" >> "$ENV_FILE"

# Sentry (error tracking)
[ -f "package.json" ] && grep -q '"@sentry/nextjs"' package.json && echo "HAS_SENTRY=true" >> "$ENV_FILE"

# Docker
([ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]) && echo "HAS_DOCKER=true" >> "$ENV_FILE"

# Upstash (rate limiting)
[ -f "package.json" ] && grep -q '"@upstash/ratelimit"\|"@upstash/redis"' package.json && echo "HAS_UPSTASH=true" >> "$ENV_FILE"

# PostHog (analytics)
[ -f "package.json" ] && grep -q '"posthog-js"\|"posthog-node"' package.json && echo "HAS_POSTHOG=true" >> "$ENV_FILE"

# Socket.io (real-time)
[ -f "package.json" ] && grep -q '"socket.io"' package.json && echo "HAS_SOCKETIO=true" >> "$ENV_FILE"
