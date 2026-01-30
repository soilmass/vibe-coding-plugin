---
name: env-validation
description: >
  Environment variable validation — @t3-oss/env-nextjs + Zod schema, build-time validation, .env.example sync, runtime crash prevention
allowed-tools: Read, Grep, Glob
---

# Environment Validation

## Purpose
Build-time environment variable validation using `@t3-oss/env-nextjs` and Zod. Catches missing
or malformed env vars at build time instead of runtime. The ONE skill for environment safety.

## When to Use
- Setting up env var validation for a new project
- Adding new environment variables
- Debugging "undefined" env var errors in production
- Syncing `.env.example` with actual requirements

## When NOT to Use
- Deployment configuration → `deploy`
- Security headers and CSP → `security`
- Secret management in CI/CD → `deploy`

## Pattern

### Env schema with @t3-oss/env-nextjs
```tsx
// src/env.ts
import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().url(),
    AUTH_SECRET: z.string().min(32),
    RESEND_API_KEY: z.string().startsWith("re_"),
  },
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url(),
  },
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    AUTH_SECRET: process.env.AUTH_SECRET,
    RESEND_API_KEY: process.env.RESEND_API_KEY,
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  },
});
```

### Usage in code
```tsx
// Server Component or Server Action
import { env } from "@/env";

const db = new PrismaClient({
  datasourceUrl: env.DATABASE_URL, // Type-safe, validated
});
```

### .env.example sync
```bash
# .env.example — committed to git, documents all required vars
DATABASE_URL=""
AUTH_SECRET=""
RESEND_API_KEY=""
NEXT_PUBLIC_APP_URL=""
```

## Anti-pattern

```tsx
// WRONG: non-null assertion — crashes at runtime if missing
const apiKey = process.env.API_KEY!;

// WRONG: no validation — silently undefined
const dbUrl = process.env.DATABASE_URL;
if (!dbUrl) throw new Error("Missing DATABASE_URL"); // Manual, error-prone

// CORRECT: validated at build time
import { env } from "@/env";
const dbUrl = env.DATABASE_URL; // Never undefined
```

Never use `process.env.X!` with non-null assertion. It compiles but crashes at runtime.

## Common Mistakes
- Using `process.env` directly without validation — undefined at runtime
- Non-null assertion `!` on env vars — hides missing variables
- Client vars without `NEXT_PUBLIC_` prefix — undefined in browser
- Not updating `.env.example` when adding new variables
- Putting server secrets in `client` schema — exposed in browser bundle

## Checklist
- [ ] `@t3-oss/env-nextjs` and `zod` installed
- [ ] `src/env.ts` defines all env vars with Zod schemas
- [ ] Server vs client vars properly separated
- [ ] `.env.example` matches env schema
- [ ] All `process.env` access goes through `env` import
- [ ] Build fails if env vars are missing (not runtime crash)

## Composes With
- `deploy` — env vars must be set in hosting platform
- `security` — validates secrets exist without exposing them
- `scaffold` — env validation is part of project setup
