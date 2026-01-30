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
