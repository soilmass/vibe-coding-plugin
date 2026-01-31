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

### Project directory structure
After scaffolding, the project tree should look like this:
```
my-app/
├── public/
│   ├── file.svg
│   ├── globe.svg
│   ├── next.svg
│   ├── vercel.svg
│   └── window.svg
├── src/
│   ├── app/
│   │   ├── fonts/
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── actions/              # Server Actions
│   ├── components/
│   │   └── ui/               # shadcn/ui components
│   ├── hooks/                # Client-side custom hooks
│   ├── lib/
│   │   ├── auth.ts           # Auth.js configuration
│   │   ├── db.ts             # Prisma client singleton
│   │   └── utils.ts          # cn() helper (created by shadcn init)
│   └── types/                # Shared TypeScript type definitions
├── .env.example
├── .gitignore
├── components.json           # shadcn/ui config (created by shadcn init)
├── next.config.ts
├── package.json
├── postcss.config.mjs
└── tsconfig.json
```

### Initial globals.css
Tailwind v4 uses CSS-first configuration. Replace the generated `globals.css` with:
```css
@import "tailwindcss";

@theme {
  --font-sans: "Inter", "system-ui", sans-serif;
  --font-mono: "JetBrains Mono", monospace;

  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.145 0 0);
  --color-primary: oklch(0.205 0.042 265.755);
  --color-primary-foreground: oklch(0.985 0 0);
  --color-muted: oklch(0.97 0 0);
  --color-muted-foreground: oklch(0.556 0 0);
  --color-border: oklch(0.922 0 0);
  --color-destructive: oklch(0.577 0.245 27.325);

  --radius-sm: 0.375rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
}

@layer base {
  *,
  *::before,
  *::after {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

### TypeScript configuration
Ensure `tsconfig.json` has these critical settings:
```json
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "preserve",
    "noEmit": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```
Key settings: `strict: true` (non-negotiable), `moduleResolution: "bundler"` (Next.js 15 requirement), `paths` alias `@/*` maps to `src/*`.

### Environment setup
Create `.env.example` as a template (never commit `.env.local`):
```bash
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/myapp?schema=public"

# Auth.js
NEXTAUTH_SECRET="generate-with-openssl-rand-base64-32"
NEXTAUTH_URL="http://localhost:3000"

# App
NEXT_PUBLIC_APP_URL="http://localhost:3000"
```
Then copy to local:
```bash
cp .env.example .env.local
```

### Post-scaffold checklist
Run these steps immediately after the initial scaffold:
```bash
# 1. Add Prisma
npx prisma init --datasource-provider postgresql

# 2. Add Auth.js
npm install next-auth@beta @auth/prisma-adapter

# 3. Add shadcn/ui base components
npx shadcn@latest add button input label card

# 4. Configure linting
npm install -D @typescript-eslint/parser @typescript-eslint/eslint-plugin

# 5. Verify .gitignore includes
# .env.local, .env*.local, node_modules, .next, prisma/*.db
```
After running these, verify the project compiles:
```bash
npx tsc --noEmit && echo "TypeScript OK"
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
