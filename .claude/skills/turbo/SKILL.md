---
name: turbo
description: >
  Turborepo monorepo setup — workspace config, pipeline tasks, caching, shared packages, dev orchestration
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(npx turbo *)
---

# Turbo

## Purpose
Turborepo monorepo configuration and workspace management. Covers pipeline setup, caching
strategy, and shared package patterns. The ONE skill for monorepo orchestration.

## Project State
- Has turbo.json: !`[ -f "turbo.json" ] && echo "yes" || echo "no"`
- Workspaces: !`[ -f "package.json" ] && node -e "const p=require('./package.json'); console.log(p.workspaces?.join(', ') || 'none')" 2>/dev/null || echo "none"`

## When to Use
- Setting up a monorepo with multiple apps/packages
- Configuring build pipelines with task dependencies
- Optimizing CI with remote caching
- Sharing code between multiple Next.js apps

## When NOT to Use
- Single app project — overhead not justified
- Adding features to one app → use specific skills
- Deployment configuration → `deploy`

## Pattern

### turbo.json pipeline
```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "test": {
      "dependsOn": ["^build"]
    }
  }
}
```

### Monorepo structure
```
apps/
  web/           # Next.js app
  docs/          # Documentation site
packages/
  ui/            # Shared component library
  config/        # Shared config (tsconfig, eslint)
  db/            # Shared Prisma client
```

### Shared package package.json
```json
{
  "name": "@repo/ui",
  "exports": {
    ".": "./src/index.ts",
    "./*": "./src/*.tsx"
  },
  "devDependencies": {
    "@repo/config": "workspace:*"
  }
}
```

### Remote caching setup

Enable remote caching to share build artifacts across CI runs and team members.

**turbo.json with remote cache config:**
```json
{
  "$schema": "https://turbo.build/schema.json",
  "remoteCache": {
    "signature": true
  },
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"],
      "env": ["DATABASE_URL", "NEXT_PUBLIC_API_URL"]
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "test": {
      "dependsOn": ["^build"],
      "env": ["DATABASE_URL"]
    }
  }
}
```

The `env` key declares environment variables that affect task output. When a listed
variable changes, Turborepo invalidates the cache for that task. Always list variables
that influence build output — omitting them causes stale cache hits.

**CI environment variables (GitHub Actions):**
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
      TURBO_TEAM: ${{ vars.TURBO_TEAM }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: "npm"
      - run: npm ci
      - run: npx turbo run build lint test
```

Generate the token and link your repo:
```bash
npx turbo login
npx turbo link
```

For self-hosted remote caching (without Vercel), set a custom API endpoint:
```bash
# .env (CI only — never commit)
TURBO_API="https://cache.internal.example.com"
TURBO_TOKEN="your-server-token"
TURBO_TEAM="my-team"
```

### Workspace dependency graph

Turborepo builds a directed acyclic graph (DAG) from `dependencies` and
`devDependencies` across workspace `package.json` files. Use `--filter` to
run tasks for specific packages and their dependents.

**Filter by package name:**
```bash
# Build only the web app and its workspace dependencies
npx turbo run build --filter=@repo/web

# Build everything the web app depends on, but NOT web itself
npx turbo run build --filter=@repo/web^...

# Build web and everything that depends on web
npx turbo run build --filter=...@repo/web
```

**Filter by directory:**
```bash
# Run lint in all packages under apps/
npx turbo run lint --filter="./apps/*"

# Run tests only in packages/
npx turbo run test --filter="./packages/*"
```

**Filter by git diff (CI optimization):**
```bash
# Only build packages that changed since main
npx turbo run build --filter="...[origin/main]"

# Only test packages affected by changes in the last commit
npx turbo run test --filter="...[HEAD^1]"
```

**Visualize the dependency graph:**
```bash
npx turbo run build --graph=graph.html
```

This outputs an HTML file showing the task execution order. Use it to debug
why a package rebuilds unexpectedly or to verify dependency topology.

**Per-package task overrides in turbo.json:**
```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "test": {
      "dependsOn": ["^build"]
    }
  },
  "ui": "tui"
}
```

Per-workspace configuration lives in each package's own `turbo.json`:
```json
// apps/web/turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "extends": ["//"],
  "tasks": {
    "build": {
      "outputs": [".next/**"],
      "env": ["NEXT_PUBLIC_API_URL", "DATABASE_URL"]
    }
  }
}
```

The `"extends": ["//"]` inherits from the root `turbo.json`. Override only the
tasks that differ for that workspace — everything else is inherited.

### Shared packages pattern

Shared packages eliminate code duplication across apps. Each package has its own
`package.json`, `tsconfig.json`, and entry point.

**UI package — `packages/ui/package.json`:**
```json
{
  "name": "@repo/ui",
  "version": "0.0.0",
  "private": true,
  "exports": {
    ".": "./src/index.ts",
    "./button": "./src/button.tsx",
    "./card": "./src/card.tsx",
    "./globals.css": "./src/globals.css"
  },
  "scripts": {
    "lint": "eslint .",
    "build": "tsc --project tsconfig.build.json"
  },
  "devDependencies": {
    "@repo/config": "workspace:*",
    "typescript": "^5.7.0"
  },
  "peerDependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

Use `peerDependencies` for `react` and `react-dom` so consumers provide their
own copy — avoids duplicate React instances that break hooks.

**UI package entry point — `packages/ui/src/index.ts`:**
```typescript
export { Button } from "./button";
export { Card, CardHeader, CardContent, CardFooter } from "./card";
export { cn } from "./utils";
```

**Shared TypeScript config — `packages/config/tsconfig/base.json`:**
```json
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "incremental": true,
    "declaration": true,
    "declarationMap": true
  },
  "exclude": ["node_modules", "dist"]
}
```

**App consuming shared packages — `apps/web/tsconfig.json`:**
```json
{
  "extends": "@repo/config/tsconfig/base.json",
  "compilerOptions": {
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "src/**/*.ts", "src/**/*.tsx"],
  "exclude": ["node_modules"]
}
```

**Shared database package — `packages/db/package.json`:**
```json
{
  "name": "@repo/db",
  "version": "0.0.0",
  "private": true,
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "build": "tsc",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev"
  },
  "dependencies": {
    "@prisma/client": "^6.0.0"
  },
  "devDependencies": {
    "prisma": "^6.0.0",
    "@repo/config": "workspace:*"
  }
}
```

**Database package entry — `packages/db/src/index.ts`:**
```typescript
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const db = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}

export type { PrismaClient } from "@prisma/client";
export * from "@prisma/client";
```

**Root `package.json` workspace config:**
```json
{
  "name": "monorepo",
  "private": true,
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "lint": "turbo run lint",
    "test": "turbo run test"
  },
  "devDependencies": {
    "turbo": "^2.0.0"
  }
}
```

**Consuming shared packages in an app:**
```typescript
// apps/web/src/app/page.tsx (Server Component)
import { Button, Card, CardHeader, CardContent } from "@repo/ui";
import { db } from "@repo/db";

export default async function Page() {
  const posts = await db.post.findMany({ take: 10 });

  return (
    <Card>
      <CardHeader>Recent Posts</CardHeader>
      <CardContent>
        {posts.map((post) => (
          <div key={post.id}>{post.title}</div>
        ))}
      </CardContent>
      <Button>Load More</Button>
    </Card>
  );
}
```

## Anti-pattern

```json
// WRONG: caching dev server
{
  "tasks": {
    "dev": {
      "outputs": [".next/**"]
      // dev is persistent and should NOT be cached
    }
  }
}
```

Dev servers are long-running processes. Setting outputs on them causes
Turborepo to incorrectly cache and replay dev server output.

## Common Mistakes
- Caching `dev` task — persistent tasks must have `"cache": false`
- Missing `^build` in dependsOn — packages build before apps that depend on them
- Not using `workspace:*` for internal dependencies
- Forgetting `outputs` array — Turborepo can't cache without knowing what to store
- Not setting up remote caching for CI — misses the biggest perf win

## Checklist
- [ ] `turbo.json` has correct task dependencies with `^` prefix
- [ ] `dev` task has `"cache": false` and `"persistent": true`
- [ ] Build outputs specified for cacheable tasks
- [ ] Internal packages use `workspace:*` protocol
- [ ] Root `package.json` has `workspaces` field

## Composes With
- `scaffold` — scaffold creates the initial app that turbo wraps
- `deploy` — deployment pipelines use turbo build outputs
- `testing` — turbo orchestrates test runs across packages
