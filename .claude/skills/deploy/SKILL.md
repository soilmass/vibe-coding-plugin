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
