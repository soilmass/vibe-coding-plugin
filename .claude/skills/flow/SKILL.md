---
name: flow
description: >
  Workflow pipeline orchestrator — chains skills in predefined sequences for 32 pipelines including build, feature, harden, ship, audit, refactor, i18n, a11y, migration, seo, full-audit, observe, full-feature, resilience, gdpr, api-first, b2b-saas, content-site, search-notify, mobile-first, design-system, perf-audit, bundle-optimize, docs-sprint, ui-polish, landing-polish, and interactive-feature workflows
allowed-tools: Read, Grep, Glob
---

# Flow

## Purpose
Workflow pipeline orchestrator that chains skills in predefined sequences. Runs multi-step
development workflows end-to-end. The ONE orchestrator for structured multi-skill pipelines.

## When to Use
- User wants a full build pipeline (env-validation → scaffold → prisma → seeding → auth → shadcn)
- Building a complete feature (routing → components → forms → actions)
- Hardening an app (security → a11y → perf → errors → caching → testing)
- Shipping to production (testing → deploy)
- Running an audit (typescript → security → caching)
- Adding i18n (i18n → routing → middleware → metadata)
- Accessibility pass (accessibility → shadcn → forms → testing)
- Database migration workflow (prisma → database-seeding → testing)
- SEO optimization (nextjs-metadata → seo-advanced → i18n → performance)
- Full audit (up to 17 auditor agents, 2 conditional)
- Observability stack (logging → analytics → error-handling → performance)
- Full feature with observability (routing → components → forms → actions → logging → testing)
- Resilience setup (observability → error-handling → logging → testing)
- GDPR compliance (compliance → prisma → security → logging → testing)
- API-first development (api-routes → api-documentation → typescript-patterns → security → testing)
- B2B SaaS setup (multi-tenancy → feature-flags → compliance → auth → payments → testing)
- Content site (cms → nextjs-metadata → seo-advanced → edge-computing → image-optimization → performance)
- Search with notifications (search → notifications → real-time → analytics → testing)
- Mobile-first PWA (pwa → notifications → image-optimization → accessibility → performance → testing)
- Design system (storybook → shadcn → visual-regression → accessibility → tailwind-v4)

## When NOT to Use
- Single skill task → invoke that skill directly
- Ambiguous intent → `vibe` (classifies first, then routes)
- Custom workflow not matching a pipeline → chain skills manually

## Pipelines

| Pipeline | Chain | Description |
|----------|-------|-------------|
| `build` | `env-validation` → `scaffold` → `prisma` → `database-seeding` → `auth` → `logging` → `shadcn` | Full project setup from zero |
| `feature` | `nextjs-routing` → `react-server-components` → `react-forms` → `react-server-actions` | Complete feature with UI and data |
| `harden` | `security` → `secrets-management` → `rate-limiting` → `accessibility` → `performance` → `observability` → `error-handling` → `caching` → `testing` | Production readiness hardening |
| `ship` | `testing` → `performance` → `deploy` | Test, verify perf, deploy |
| `audit` | `typescript-patterns` → `security` → `caching` | Code quality and security review |
| `refactor` | `react-server-components` → `react-client-components` → `caching` | Optimize component architecture |
| `i18n` | `i18n` → `nextjs-routing` → `nextjs-middleware` → `nextjs-metadata` | Full internationalization setup |
| `a11y` | `accessibility` → `shadcn` → `react-forms` → `testing` | Accessibility compliance pass |
| `migration` | `prisma` → `database-seeding` → `testing` | Database migration with seed and verify |
| `seo` | `nextjs-metadata` → `seo-advanced` → `i18n` → `performance` | Full SEO optimization pass |
| `full-audit` | `code-reviewer` → `api-security-auditor` → `a11y-auditor` → `ux-auditor` → `design-auditor` → `perf-profiler` → `seo-auditor` → `bundle-auditor` → `db-query-auditor` → `dependency-auditor` → `error-handling-auditor` → `test-coverage-auditor` → `type-safety-auditor` → `observability-auditor` → `compliance-auditor` → `tenancy-auditor` → `api-docs-auditor` | All-agent comprehensive audit |
| `observe` | `logging` → `analytics` → `error-handling` → `performance` | Observability stack setup |
| `full-feature` | `nextjs-routing` → `react-server-components` → `react-forms` → `react-server-actions` → `logging` → `testing` | Complete feature with observability |
| `security-full` | `security` → `api-security-auditor` → `rate-limiting` → `logging` | Security depth with agent review |
| `db-health` | `prisma` → `db-query-auditor` → `testing` | Database optimization audit |
| `deps-check` | `dependency-auditor` | npm security, licensing, bloat |
| `type-check` | `typescript-patterns` → `type-safety-auditor` | No-any enforcement pass |
| `test-gaps` | `test-coverage-auditor` → `testing` | Missing test detection + fix |
| `resilience` | `observability` → `error-handling` → `logging` → `testing` | Health checks, tracing, circuit breakers, graceful degradation |
| `gdpr` | `compliance` → `prisma` → `security` → `logging` → `testing` | GDPR-compliant data handling with audit trails |
| `api-first` | `api-routes` → `trpc` → `api-documentation` → `typescript-patterns` → `security` → `testing` | API-first product with auto-generated docs and type-safe clients |
| `b2b-saas` | `multi-tenancy` → `feature-flags` → `compliance` → `auth` → `payments` → `testing` | Full B2B SaaS with tenant isolation, billing, compliance |
| `content-site` | `cms` → `nextjs-metadata` → `seo-advanced` → `edge-computing` → `image-optimization` → `performance` | Marketing site or blog with CMS, SEO, edge delivery |
| `search-notify` | `search` → `notifications` → `real-time` → `analytics` → `testing` | Search-heavy app with notifications and real-time updates |
| `mobile-first` | `pwa` → `notifications` → `image-optimization` → `accessibility` → `performance` → `testing` | Mobile-first app with offline support and native-like experience |
| `design-system` | `visual-design` → `storybook` → `shadcn` → `visual-regression` → `accessibility` → `tailwind-v4` | Design system with visual documentation and regression testing |
| `perf-audit` | `perf-profiler` → `bundle-auditor` → `performance` | Performance and bundle audit with optimization |
| `bundle-optimize` | `bundle-auditor` → `react-server-components` → `react-client-components` → `performance` | Client/server boundary optimization |
| `docs-sprint` | `api-documentation` → `storybook` → `testing` | API docs, component docs, and test generation |
| `ui-polish` | `visual-design` → `composition-patterns` → `dark-mode` → `animation` → `responsive-design` → `layout-patterns` → `accessibility` | Visual polish pass for functionally complete apps |
| `landing-polish` | `landing-patterns` → `visual-design` → `animation` → `seo-advanced` → `image-optimization` → `performance` | Marketing site with visual polish and SEO |
| `interactive-feature` | `nextjs-routing` → `react-server-components` → `react-forms` → `advanced-form-ux` → `react-server-actions` → `animation` → `testing` | Extended feature pipeline with rich interactivity |

## Execution Rules

1. Load skills sequentially — each step depends on the previous
2. Max 3 skills active at any point — unload completed skills
3. Check project state before each step — skip if already done
4. Stop on errors — don't continue pipeline if a step fails
5. Report progress — tell user which step is active

## Pipeline Details

### build
```
1. env-validation — set up @t3-oss/env-nextjs with Zod schema
   Skip if: src/env.ts exists
2. scaffold — create Next.js 15 project structure
   Skip if: next.config.ts exists
3. prisma — set up database schema and client
   Skip if: prisma/ directory exists
4. database-seeding — create seed scripts and factories
   Skip if: prisma/seed.ts exists
5. auth — configure Auth.js with providers
   Skip if: src/lib/auth.ts exists
6. logging — set up structured logging with Pino
   Skip if: src/lib/logger.ts exists
7. shadcn — initialize component library
   Skip if: components.json exists
```

### feature
```
1. nextjs-routing — create route files (page.tsx, layout.tsx)
2. react-server-components — build data-fetching components
3. react-forms — add interactive form UI
4. react-server-actions — implement mutation logic
```

### harden
```
1. security — CSP headers, server-only, env validation
2. secrets-management — secret rotation, env hardening, CI/CD injection
   Skip if: secrets already managed via Doppler/Infisical
3. rate-limiting — protect API routes and Server Actions from abuse
4. accessibility — WCAG 2.1 AA compliance, semantic HTML, ARIA
5. performance — bundle analysis, dynamic imports, image optimization
6. observability — health checks, tracing, circuit breakers
   Skip if: instrumentation.ts exists
7. error-handling — error.tsx, global-error.tsx, not-found.tsx
8. caching — explicit cache strategies, revalidation tags
9. testing — unit tests for actions, E2E for critical flows
```

### ship
```
1. testing — run vitest and playwright suites
   Abort if: tests fail
2. performance — verify bundle sizes and Web Vitals
3. deploy — push to Vercel or build Docker image
```

### audit
```
1. typescript-patterns — check for any, missing types
2. security — check for server-only, CSP, env validation
3. caching — check for explicit cache strategies
```

### refactor
```
1. react-server-components — identify unnecessary "use client"
2. react-client-components — extract minimal interactive parts
3. caching — add caching to server-side data fetching
```

### i18n
```
1. i18n — set up next-intl, [locale] segments, translation files
2. nextjs-routing — configure locale-aware routing
3. nextjs-middleware — add locale detection middleware
4. nextjs-metadata — locale-aware metadata and SEO
```

### a11y
```
1. accessibility — audit and fix semantic HTML, ARIA, keyboard nav
2. shadcn — ensure UI components meet a11y standards
3. react-forms — fix form error announcements, aria-describedby
4. testing — add accessibility tests (axe-core integration)
```

### migration
```
1. prisma — run schema migrations
   Abort if: migration fails
2. database-seeding — seed or update test data
3. testing — verify data integrity with tests
```

### seo
```
1. nextjs-metadata — set up base metadata, title templates, viewport
2. seo-advanced — add JSON-LD, dynamic sitemap, robots.txt, OG images
3. i18n — add hreflang and locale-specific metadata
   Skip if: no i18n configured
4. performance — verify metadata doesn't impact load times
```

### full-audit
```
Note: This is an agent pipeline — each step runs an agent, not a skill.
1. code-reviewer — React 19, Next.js 15, TypeScript, security review
2. api-security-auditor — Server Action input validation, auth, injection
3. a11y-auditor — WCAG 2.1 AA accessibility audit
4. ux-auditor — loading states, empty states, dark mode, touch, feedback, responsive, focus
5. design-auditor — color consistency, elevation, visual hierarchy, spacing, microinteractions
6. perf-profiler — Bundle, data fetching, rendering analysis
7. seo-auditor — Metadata, structured data, sitemap
8. bundle-auditor — Route sizes, client/server boundaries
9. db-query-auditor — N+1 queries, missing indexes, cascade risks
10. dependency-auditor — npm security, licensing, outdated deps
11. error-handling-auditor — Error boundaries, try-catch, error.tsx coverage
12. test-coverage-auditor — Missing tests for actions, critical flows
13. type-safety-auditor — No-any enforcement, type narrowing
14. observability-auditor — Health endpoints, tracing, timeouts, circuit breakers
15. compliance-auditor — GDPR consent, PII handling, audit logging, data retention
16. tenancy-auditor — Tenant isolation, cross-tenant leaks, query scoping
    Skip if: no Tenant model in schema
17. api-docs-auditor — OpenAPI coverage, versioning, documentation completeness
    Skip if: no OpenAPI/Swagger setup detected
```

### observe
```
1. logging — set up structured logging with Pino/Sentry
   Skip if: src/lib/logger.ts exists
2. analytics — add Vercel Analytics, PostHog tracking
3. error-handling — add error.tsx, global-error.tsx boundaries
4. performance — verify observability doesn't impact load times
```

### full-feature
```
1. nextjs-routing — create route files (page.tsx, layout.tsx)
2. react-server-components — build data-fetching components
3. react-forms — add interactive form UI
4. react-server-actions — implement mutation logic
5. logging — add structured logging for the feature
6. testing — unit tests for actions, integration for API
```

### security-full
```
Note: Mixed pipeline — skills and agents.
1. security — CSP headers, server-only, env validation, CORS
2. api-security-auditor — Server Action input validation, auth, injection (agent)
3. rate-limiting — protect API routes and Server Actions from abuse
4. logging — audit trails and security event logging
```

### db-health
```
Note: Mixed pipeline — skill and agent.
1. prisma — review schema, indexes, connection pooling
2. db-query-auditor — N+1 queries, missing indexes, cascade risks (agent)
3. testing — verify data integrity with tests
```

### deps-check
```
Note: Agent-only pipeline.
1. dependency-auditor — npm security, licensing, outdated deps, bundle bloat (agent)
```

### type-check
```
Note: Mixed pipeline — skill and agent.
1. typescript-patterns — check for any, missing types, proper patterns
2. type-safety-auditor — no-any enforcement, type narrowing, Zod alignment (agent)
```

### test-gaps
```
Note: Mixed pipeline — agent and skill.
1. test-coverage-auditor — detect missing tests for actions, critical flows (agent)
2. testing — write missing unit and E2E tests based on audit findings
```

### resilience
```
1. observability — OpenTelemetry tracing, health/readiness endpoints
   Skip if: instrumentation.ts exists
2. error-handling — error.tsx, global-error.tsx, circuit breaker fallbacks
3. logging — structured logging with trace ID correlation
   Skip if: src/lib/logger.ts exists
4. testing — test health endpoints, circuit breaker behavior, error paths
```

### gdpr
```
1. compliance — cookie consent, audit logging, PII classification
2. prisma — soft-delete fields, AuditLog model, data retention fields
3. security — data protection headers, CORS for export endpoints
4. logging — PII masking, audit trail logging
5. testing — test data export, deletion lifecycle, consent flows
```

### api-first
```
1. api-routes — implement route handlers with Zod validation
2. trpc — optional tRPC router for type-safe API layer
   Skip if: no tRPC configured
3. api-documentation — OpenAPI spec from Zod, Swagger UI, versioning
4. typescript-patterns — generate type-safe client SDK
5. security — auth documentation, rate limiting per endpoint
6. testing — API contract tests, versioning regression tests
```

### b2b-saas
```
1. multi-tenancy — tenant model, Prisma extension, subdomain routing
2. feature-flags — per-tenant feature configuration
   Skip if: no Edge Config or LaunchDarkly
3. compliance — GDPR for multi-tenant data, per-tenant audit logs
4. auth — tenant-scoped auth, role-based access within tenant
5. payments — per-tenant billing with Stripe
   Skip if: no Stripe configured
6. testing — tenant isolation tests, cross-tenant leak tests
```

### content-site
```
1. cms — headless CMS client, MDX rendering, Draft Mode
2. nextjs-metadata — dynamic metadata from CMS fields
3. seo-advanced — JSON-LD, sitemap, OG images from CMS
4. edge-computing — edge delivery, geo personalization
   Skip if: not deploying to Vercel
5. image-optimization — CMS image optimization via next/image
6. performance — verify content delivery speed, Core Web Vitals
```

### search-notify
```
1. search — Meilisearch setup, indexing, faceted search UI
2. notifications — in-app notifications for search alerts, new results
3. real-time — live search result updates via SSE/Pusher
4. analytics — search analytics, popular queries, no-results tracking
5. testing — search accuracy tests, notification delivery tests
```

### mobile-first
```
1. pwa — Web App Manifest, service worker, offline fallback
2. notifications — push notifications via service worker
3. image-optimization — responsive images, lazy loading
4. accessibility — touch targets, mobile screen reader support
5. performance — mobile performance budget, Core Web Vitals
6. testing — offline mode tests, responsive visual tests
```

### design-system
```
1. visual-design — color system, elevation scale, spacing rhythm, visual hierarchy
   Skip if: @theme has brand color scale
2. storybook — Storybook 8 setup, component stories, autodocs
3. shadcn — stories for all shadcn components with controls
4. visual-regression — Playwright screenshot tests for components
5. accessibility — per-component a11y audit via Storybook addon
6. tailwind-v4 — design tokens in @theme, CSS-first config
```

### perf-audit
```
Note: Mixed pipeline — agent and skills.
1. perf-profiler — bundle, data fetching, rendering analysis (agent)
2. bundle-auditor — route sizes, client/server boundaries (agent)
3. performance — apply optimization recommendations
```

### bundle-optimize
```
1. bundle-auditor — identify heavy routes and deps (agent)
2. react-server-components — move components to server where possible
3. react-client-components — extract minimal client boundaries
4. performance — dynamic imports, lazy loading, tree-shaking
```

### docs-sprint
```
1. api-documentation — OpenAPI spec, Swagger UI, versioning
2. storybook — component stories and visual docs
3. testing — documentation-driven test generation
```

### ui-polish
```
Visual polish pass for functionally complete apps.
1. visual-design — establish color system, elevation, spacing rhythm, visual hierarchy
   Skip if: @theme has brand color scale
2. composition-patterns — refactor boolean-prop components into compound/variant patterns
   Skip if: no components with 3+ boolean mode props
3. dark-mode — set up theme switching with next-themes
   Skip if: ThemeProvider already configured
4. animation — add page transitions, microinteractions
5. responsive-design — mobile-first audit, container queries, touch targets
6. layout-patterns — dashboard shell, sidebar, breadcrumbs
   Skip if: layout already implemented
7. accessibility — final a11y audit on polished UI
```

### landing-polish
```
Marketing site with visual polish and SEO.
1. landing-patterns — hero sections, bento grid, pricing, CTA
2. visual-design — color system, elevation, gradients, glassmorphism
   Skip if: @theme has brand color scale
3. animation — scroll reveals, stagger entry, hover effects
4. seo-advanced — JSON-LD, sitemap, OpenGraph images
5. image-optimization — responsive images, blur placeholders
6. performance — Core Web Vitals, bundle analysis
```

### interactive-feature
```
Extended feature pipeline with rich interactivity.
1. nextjs-routing — create route files (page.tsx, layout.tsx)
2. react-server-components — build data-fetching components
3. react-forms — add interactive form UI
4. advanced-form-ux — add wizard, auto-save, date pickers
   Skip if: simple form (no multi-step or advanced inputs)
5. react-server-actions — implement mutation logic
6. animation — add transitions and feedback animations
7. testing — unit tests for actions, E2E for flows
```

## Pattern

### Invoking a pipeline
```
User: "Set up a new project with database and auth"
→ Flow selects: build pipeline
→ Runs: env-validation → scaffold → prisma → database-seeding → auth → shadcn

User: "Make my app production-ready"
→ Flow selects: harden pipeline
→ Runs: security → accessibility → performance → error-handling → caching → testing

User: "Ship it"
→ Flow selects: ship pipeline
→ Runs: testing → deploy
```

## Anti-pattern

Running all pipeline steps without checking project state. Each step should
verify prerequisites and skip if already completed. Don't re-scaffold a project
that already exists.

## Common Mistakes
- Running `build` on existing project — check state first
- Skipping `testing` in `ship` — always test before deploy
- Running `harden` before `build` — no app to harden yet

## Checklist
- [ ] Pipeline matches user intent (build/feature/harden/ship/audit)
- [ ] Project state checked before each step (skip if already done)
- [ ] Skills loaded sequentially — max 3 active at once
- [ ] Errors stop the pipeline (don't continue on failure)
- [ ] Progress reported to user at each step
- [ ] Conditional steps evaluated (skip conditions checked)

## Composes With
- `vibe` — vibe classifies intent, flow runs the pipeline
- All 69 skills — flow chains them in sequence
