---
name: scaffold
description: >
  Scaffold a new Next.js 15 project with TypeScript, Tailwind v4, shadcn/ui, Prisma, Auth.js
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(npx *)
---

# Scaffold

## Purpose
Bootstrap a new Next.js 15 project with the full stack: TypeScript strict mode, Tailwind v4,
shadcn/ui, and optional Prisma + Auth.js. The ONE skill for project initialization.

## Project State
- Package manager: !`[ -f "bun.lockb" ] && echo "bun" || ([ -f "pnpm-lock.yaml" ] && echo "pnpm" || echo "npm")`
- Has package.json: !`[ -f "package.json" ] && echo "yes" || echo "no"`
- Has Next.js: !`[ -f "next.config.ts" ] && echo "yes" || echo "no"`

## When to Use
- Starting a brand-new project from scratch
- User says "create", "init", "bootstrap", "new project"
- Setting up the foundational file structure

## When NOT to Use
- Project already exists with `next.config.ts` → use specific skills
- Adding features to existing project → `shadcn`, `prisma`, `auth`
- Monorepo setup → `turbo`

## Pattern

### Full scaffold sequence
```bash
# 1. Create Next.js 15 project
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# 2. Install shadcn/ui
cd my-app && npx shadcn@latest init -d

# 3. Set up project structure
mkdir -p src/{actions,components/ui,hooks,lib,types}

# 4. Create utility files
# src/lib/utils.ts — cn() helper (created by shadcn init)
# src/lib/db.ts — Prisma client singleton
# src/lib/auth.ts — Auth.js configuration
```

### Minimal src/lib/db.ts
```tsx
import "server-only";
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const db = globalForPrisma.prisma || new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = db;
```

## Anti-pattern

```bash
# WRONG: using Pages Router flags
npx create-next-app my-app --no-app
# WRONG: skipping TypeScript
npx create-next-app my-app --js
# WRONG: using old tailwind config
# tailwind.config.js is replaced by CSS @theme{} in v4
```

Always use App Router + TypeScript + Tailwind. These are non-negotiable in this stack.

## Common Mistakes
- Forgetting `--src-dir` — puts app/ at root instead of src/app/
- Skipping `--import-alias "@/*"` — breaks path resolution
- Not running `shadcn init` before adding components
- Creating `tailwind.config.js` — Tailwind v4 uses CSS-first config
- Missing the `server-only` import on db.ts

## Checklist
- [ ] Next.js 15 with App Router and TypeScript
- [ ] Tailwind v4 with CSS-first configuration
- [ ] shadcn/ui initialized with default settings
- [ ] Directory structure: actions, components/ui, hooks, lib, types
- [ ] `src/lib/utils.ts` with `cn()` helper exists

## Composes With
- `prisma` — add database after scaffold
- `auth` — add authentication after scaffold
- `shadcn` — add UI components after scaffold
