---
name: secrets-management
description: >
  Secret rotation, env validation hardening, team secret sharing with Doppler/Infisical, CI/CD injection
allowed-tools: Read, Grep, Glob
---

# Secrets Management

## Purpose
Secure secrets lifecycle management for Next.js 15. Covers secret rotation strategies,
`@t3-oss/env-nextjs` hardening, team secret sharing with Doppler or Infisical, CI/CD secret
injection, and `.env.local` safety practices.

## When to Use
- Hardening environment variable validation beyond basic `env-validation`
- Setting up secret rotation with zero-downtime swap
- Configuring team secret sharing (Doppler/Infisical)
- Securing CI/CD secret injection (GitHub Actions → Vercel)
- Auditing secret access and preventing leaks

## When NOT to Use
- Basic env validation setup → `env-validation`
- API key authentication → `security`
- OAuth provider configuration → `auth`
- Deployment configuration → `deploy`

## Pattern

### Hardened env validation
```tsx
// src/env.ts
import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().url().startsWith("postgresql://"),
    AUTH_SECRET: z.string().min(32, "AUTH_SECRET must be at least 32 characters"),
    STRIPE_SECRET_KEY: z.string().startsWith("sk_"),
    RESEND_API_KEY: z.string().startsWith("re_"),
    // Rotation support: accept both current and next key
    API_KEY_CURRENT: z.string().min(32),
    API_KEY_NEXT: z.string().min(32).optional(),
  },
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url(),
  },
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    AUTH_SECRET: process.env.AUTH_SECRET,
    STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY,
    RESEND_API_KEY: process.env.RESEND_API_KEY,
    API_KEY_CURRENT: process.env.API_KEY_CURRENT,
    API_KEY_NEXT: process.env.API_KEY_NEXT,
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  },
});
```

### Secret rotation (zero-downtime)
```tsx
// src/lib/api-key.ts
import "server-only";
import { env } from "@/env";

export function validateApiKey(key: string): boolean {
  // Accept both current and next key during rotation window
  if (key === env.API_KEY_CURRENT) return true;
  if (env.API_KEY_NEXT && key === env.API_KEY_NEXT) return true;
  return false;
}

// Rotation steps:
// 1. Set API_KEY_NEXT to new value
// 2. Deploy — both keys accepted
// 3. Update all clients to use new key
// 4. Move API_KEY_NEXT to API_KEY_CURRENT
// 5. Remove API_KEY_NEXT
// 6. Deploy — only new key accepted
```

### Doppler integration
```bash
# Install Doppler CLI
brew install dopplerhq/cli/doppler

# Login and setup
doppler login
doppler setup

# Run with injected secrets
doppler run -- npm run dev

# Sync to Vercel
doppler secrets download --no-file --format env | vercel env pull
```

### CI/CD secret injection (GitHub Actions)
```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install Vercel CLI
        run: npm i -g vercel

      - name: Deploy
        run: vercel --prod --token=${{ secrets.VERCEL_TOKEN }}
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          AUTH_SECRET: ${{ secrets.AUTH_SECRET }}
```

### Pre-commit hook for .env safety
```bash
# .husky/pre-commit
#!/usr/bin/env sh
# Prevent committing .env files with secrets
if git diff --cached --name-only | grep -E '\.env\.local|\.env\.production'; then
  echo "ERROR: Attempting to commit .env file with secrets"
  exit 1
fi
```

### Secret access auditing
```tsx
// src/lib/secret-audit.ts
import "server-only";
import { logger } from "@/lib/logger";
import { headers } from "next/headers";

export async function auditSecretAccess(secretName: string) {
  const headerList = await headers();
  logger.info({
    msg: "Secret accessed",
    secret: secretName,
    ip: headerList.get("x-forwarded-for"),
    timestamp: new Date().toISOString(),
  });
}
```

## Anti-pattern

### Secrets in source code
Never hardcode secrets, even in development. Use `.env.local` (gitignored) and
`@t3-oss/env-nextjs` for validation. Pre-commit hooks prevent accidental commits.

### No rotation strategy
Secrets that never rotate are ticking time bombs. Plan rotation from the start with
dual-key acceptance windows for zero-downtime swaps.

## Common Mistakes
- `.env.local` not in `.gitignore` — secrets committed to repo
- Using `process.env` directly — bypasses validation
- No minimum length on AUTH_SECRET — weak secrets accepted
- Secrets in GitHub Actions logs — use `::add-mask::` for dynamic values
- Sharing secrets via Slack/email — use Doppler or 1Password

## Checklist
- [ ] All secrets validated with specific Zod patterns
- [ ] `.env.local` in `.gitignore` with pre-commit hook
- [ ] Secret rotation strategy documented
- [ ] Dual-key support for zero-downtime rotation
- [ ] CI/CD uses secret injection (not committed files)
- [ ] Team uses Doppler/Infisical for secret sharing
- [ ] Secret access logged for audit trail

## Composes With
- `env-validation` — foundation for env variable validation
- `deploy` — CI/CD secret injection patterns
- `security` — secret protection and access control
- `logging` — secret access audit logging
