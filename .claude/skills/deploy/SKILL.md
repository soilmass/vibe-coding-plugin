---
name: deploy
description: >
  Deployment — Vercel deployment, Docker standalone, environment management, preview deployments, CI/CD configuration
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(npx vercel *)
---

# Deploy

## Purpose
Deployment configuration for Next.js 15. Covers Vercel, Docker standalone, environment
management, and CI/CD. The ONE skill for getting to production.

## Project State
- Has Vercel config: !`[ -f "vercel.json" ] && echo "yes" || echo "no"`
- Has Dockerfile: !`[ -f "Dockerfile" ] && echo "yes" || echo "no"`
- Output mode: !`grep -o '"output":\s*"[^"]*"' next.config.ts 2>/dev/null || echo "default"`

## When to Use
- Deploying to Vercel or self-hosting with Docker
- Configuring environment variables for production
- Setting up preview deployments
- Configuring CI/CD pipelines

## When NOT to Use
- Local development setup → `scaffold`
- Build pipeline configuration → `turbo`
- Database migrations in production → `prisma`

## Pattern

### Vercel deployment
```bash
# First deployment (links project)
npx vercel

# Production deployment
npx vercel --prod

# Set environment variables
npx vercel env add DATABASE_URL production
npx vercel env add AUTH_SECRET production
```

### Docker standalone output
```tsx
// next.config.ts
const config = {
  output: "standalone",
};
export default config;
```

### Dockerfile for standalone
```dockerfile
FROM node:20-alpine AS base

FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["node", "server.js"]
```

### Environment variable management
```bash
# .env.local (development — never committed)
DATABASE_URL="postgresql://..."
AUTH_SECRET="dev-secret-at-least-32-chars-long"

# .env.example (committed — documents required vars)
DATABASE_URL=""
AUTH_SECRET=""
```

### GitHub Actions CI/CD
```yaml
# .github/workflows/ci.yml
name: CI
on: [push]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: "npm"
      - run: npm ci
      - run: npm run lint
      - run: npm run test
      - run: npm run build
```

For Vercel auto-deploy, connect the GitHub repo in the Vercel dashboard.
The workflow above validates every push; Vercel handles the actual deployment on merge to `main`.

### Docker standalone build
```dockerfile
# Multi-stage build — minimal production image
FROM node:20-alpine AS base

FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
```

Requires `output: "standalone"` in `next.config.ts`. The final image contains only the
minimal server — no `node_modules` or source files.

### Health check endpoint
```tsx
// src/app/api/health/route.ts
import { db } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    await db.$queryRaw`SELECT 1`;
    return Response.json({ status: "healthy", timestamp: new Date().toISOString() });
  } catch {
    return Response.json({ status: "unhealthy" }, { status: 503 });
  }
}
```

Use this for Kubernetes liveness/readiness probes, Vercel health checks, or Docker
`HEALTHCHECK` instructions. Keep the query minimal — `SELECT 1` is enough.

### Preview deployments
```jsonc
// vercel.json — configure preview behavior
{
  "github": {
    "autoAlias": true,
    "silent": true
  }
}
```

Every PR gets a unique preview URL (`<project>-<hash>.vercel.app`).
Use preview URLs for:
- QA review before merging
- Stakeholder sign-off
- E2E tests against a real deployment

```bash
# Fetch the latest preview URL from Vercel CLI
npx vercel ls --meta githubPrId=<PR_NUMBER>
```

Set preview-specific environment variables in the Vercel dashboard under
**Settings → Environment Variables → Preview**.

## Anti-pattern

```bash
# WRONG: committing .env.local with secrets
git add .env.local  # NEVER commit secrets!

# WRONG: hardcoding env values in next.config.ts
const config = {
  env: {
    DATABASE_URL: "postgresql://user:pass@localhost/db", // Exposed in bundle!
  },
};
```

Never commit secrets. Never hardcode environment variables in config files.

## Common Mistakes
- Committing `.env.local` with secrets — add to `.gitignore`
- Not setting `output: "standalone"` for Docker — builds are too large
- Missing environment variables in production — app crashes on start
- Not running `prisma migrate deploy` in production build
- Forgetting to set `AUTH_SECRET` in production environment

## Checklist
- [ ] `.env.local` in `.gitignore`
- [ ] `.env.example` documents all required variables
- [ ] Production environment variables set in hosting platform
- [ ] `output: "standalone"` for Docker deployments
- [ ] Database migrations run before deployment

## Composes With
- `testing` — tests pass before deployment
- `prisma` — migrations run during deployment
- `security` — env validation catches missing variables at startup
- `caching` — cache headers and CDN configuration for production
- `background-jobs` — ensure job workers deploy alongside the app
- `email` — verify email service credentials in production environment
- `logging` — production observability and error tracking setup
- `observability` — health endpoints for Kubernetes/Vercel probes
