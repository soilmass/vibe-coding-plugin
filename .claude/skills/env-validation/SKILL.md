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

### Client vs server env separation
```tsx
// src/env.ts — explicit client/server boundary
import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

export const env = createEnv({
  // Server-only vars — never shipped to the browser bundle
  server: {
    DATABASE_URL: z.string().url(),
    AUTH_SECRET: z.string().min(32),
    STRIPE_SECRET_KEY: z.string().startsWith("sk_"),
    RESEND_API_KEY: z.string().startsWith("re_"),
    CRON_SECRET: z.string().min(16),
  },
  // Client vars — must use NEXT_PUBLIC_ prefix, safe for browser
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url(),
    NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: z.string().startsWith("pk_"),
    NEXT_PUBLIC_POSTHOG_KEY: z.string().min(1),
  },
  // Explicit mapping — required by @t3-oss/env-nextjs
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    AUTH_SECRET: process.env.AUTH_SECRET,
    STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY,
    RESEND_API_KEY: process.env.RESEND_API_KEY,
    CRON_SECRET: process.env.CRON_SECRET,
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
    NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY,
    NEXT_PUBLIC_POSTHOG_KEY: process.env.NEXT_PUBLIC_POSTHOG_KEY,
  },
});
```

Accessing `env.STRIPE_SECRET_KEY` in a Client Component causes a build error — the `server`
property guarantees server-only access. The `client` property only allows `NEXT_PUBLIC_` prefixed vars.

### Custom Zod refinements
```tsx
// src/env.ts — advanced validation with Zod refinements
import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

// Reusable Zod schemas for common env var patterns
const portSchema = z.coerce
  .number()
  .int()
  .min(1)
  .max(65535);

const booleanStringSchema = z
  .enum(["true", "false"])
  .transform((val) => val === "true");

const postgresUrlSchema = z
  .string()
  .refine((url) => url.startsWith("postgres://") || url.startsWith("postgresql://"), {
    message: "DATABASE_URL must start with postgres:// or postgresql://",
  });

export const env = createEnv({
  server: {
    DATABASE_URL: postgresUrlSchema,
    PORT: portSchema.default(3000),
    ENABLE_ANALYTICS: booleanStringSchema.default("false"),
    LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
    SMTP_PORT: portSchema.default(587),
    API_TIMEOUT_MS: z.coerce.number().int().min(100).max(30000).default(5000),
  },
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url(),
  },
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    PORT: process.env.PORT,
    ENABLE_ANALYTICS: process.env.ENABLE_ANALYTICS,
    LOG_LEVEL: process.env.LOG_LEVEL,
    SMTP_PORT: process.env.SMTP_PORT,
    API_TIMEOUT_MS: process.env.API_TIMEOUT_MS,
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  },
});
```

Use `z.coerce.number()` for numeric env vars (they are always strings in `process.env`).
Use `.default()` for optional vars with sensible fallbacks. Use `.refine()` for custom rules.

### .env.example sync script
```tsx
// scripts/check-env.ts — verify .env.example matches env schema
import { readFileSync } from "fs";
import { resolve } from "path";

const envExamplePath = resolve(process.cwd(), ".env.example");
const envSchemaPath = resolve(process.cwd(), "src/env.ts");

// Parse .env.example keys
const exampleContent = readFileSync(envExamplePath, "utf-8");
const exampleKeys = exampleContent
  .split("\n")
  .filter((line) => line.trim() && !line.startsWith("#"))
  .map((line) => line.split("=")[0].trim());

// Parse schema keys from runtimeEnv block
const schemaContent = readFileSync(envSchemaPath, "utf-8");
const runtimeEnvMatch = schemaContent.match(/runtimeEnv:\s*\{([^}]+)\}/s);
if (!runtimeEnvMatch) {
  console.error("Could not find runtimeEnv block in env schema");
  process.exit(1);
}
const schemaKeys = runtimeEnvMatch[1]
  .split("\n")
  .map((line) => line.trim().split(":")[0].trim())
  .filter(Boolean);

// Find mismatches
const missingFromExample = schemaKeys.filter((k) => !exampleKeys.includes(k));
const extraInExample = exampleKeys.filter((k) => !schemaKeys.includes(k));

if (missingFromExample.length > 0) {
  console.error("Missing from .env.example:", missingFromExample.join(", "));
}
if (extraInExample.length > 0) {
  console.warn("Extra in .env.example (not in schema):", extraInExample.join(", "));
}
if (missingFromExample.length > 0) {
  process.exit(1);
}
console.log(".env.example is in sync with env schema");
```

Add the check script to `package.json`:
```json
{
  "scripts": {
    "env:check": "tsx scripts/check-env.ts",
    "prebuild": "npm run env:check"
  }
}
```

This ensures `.env.example` stays in sync with the Zod schema. Running `prebuild` catches
missing documentation before deployment.

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
