---
name: vibe
description: >
  Natural language project orchestrator — classifies user intent, selects 1-3 skills by keyword matching, routes to action or reference skills
allowed-tools: Read, Grep, Glob
---

# Vibe

## Purpose
Natural language intent router that classifies user requests and selects the right skills.
Parses intent keywords, matches against skill triggers, and loads max 3 skills. The ONE
orchestrator for ambiguous or multi-concern requests.

## When to Use
- User gives a vague or multi-part request
- Intent spans multiple lifecycle layers
- Unclear whether to use action or reference skill
- User says "help me with..." or describes a goal, not a specific skill

## When NOT to Use
- User explicitly names a skill → load that skill directly
- User invokes `/flow` → use flow orchestrator
- Single clear intent matching one skill → load that skill

## Routing Rules

1. Parse user intent for keywords
2. Match against skill "When to Use" triggers below
3. Select max 3 skills (prefer one per lifecycle layer)
4. If intent = "create/build/add/scaffold/init" → prefer Action skills
5. If intent = "how/why/explain/show/what" → prefer Reference skills
6. If ambiguous → ask user to clarify

## Skill Registry

### Action Skills (user must invoke explicitly for side effects)
| Skill | Triggers |
|-------|----------|
| `scaffold` | create project, init, bootstrap, new app, start fresh |
| `turbo` | monorepo, workspaces, pipeline, multi-app |
| `prisma` | database, schema, migration, model, ORM |
| `auth` | login, authentication, session, OAuth, provider |
| `shadcn` | component, button, dialog, card, UI library |
| `testing` | test, vitest, playwright, coverage, spec |
| `deploy` | deploy, vercel, docker, production, CI/CD |
| `database-seeding` | seed, test data, faker, factories, sample data |

### Reference Skills (auto-loaded for knowledge)
| Skill | Triggers |
|-------|----------|
| `react-server-components` | server component, RSC, async component, zero JS |
| `react-client-components` | client component, "use client", hooks, interactivity |
| `react-server-actions` | server action, "use server", mutation, form processing |
| `react-forms` | form, useActionState, useFormStatus, useOptimistic, validation |
| `react-suspense` | suspense, loading, streaming, use() hook, skeleton |
| `nextjs-routing` | route, page, layout, params, parallel routes, slug |
| `nextjs-data` | data fetching, fetch, React.cache, Promise.all, dedup |
| `nextjs-middleware` | middleware, redirect, rewrite, edge, guard |
| `nextjs-metadata` | metadata, SEO, OpenGraph, sitemap, title, description |
| `caching` | cache, revalidate, stale data, unstable_cache, tags |
| `api-routes` | API route, route handler, GET, POST, webhook, REST |
| `error-handling` | error boundary, error.tsx, not-found, 404, reset |
| `security` | CSP, server-only, env validation, XSS, headers |
| `tailwind-v4` | tailwind, styling, @theme, CSS, design tokens, utility |
| `typescript-patterns` | types, typing, generics, discriminated union, unknown |
| `i18n` | internationalization, i18n, locale, translation, multi-language |
| `state-management` | state, URL state, nuqs, context, useOptimistic, global store |
| `accessibility` | accessibility, a11y, WCAG, ARIA, screen reader, keyboard nav |
| `performance` | performance, bundle size, dynamic import, lazy, optimization |
| `env-validation` | env vars, environment, process.env, .env, build-time validation |
| `email` | email, transactional, welcome email, Resend, React Email |
| `background-jobs` | background job, queue, cron, scheduled task, Inngest, async work |
| `seo-advanced` | JSON-LD, structured data, sitemap, robots.txt, OpenGraph image |
| `file-uploads` | upload, file upload, S3, R2, Uploadthing, presigned URL |
| `rate-limiting` | rate limit, throttle, quota, abuse, DDoS |
| `logging` | log, logging, monitoring, Sentry, error tracking, observability |
| `payments` | payment, Stripe, checkout, subscription, billing, pricing |
| `webhooks` | webhook, stripe webhook, github webhook, signature, idempotency |
| `analytics` | analytics, tracking, posthog, vercel analytics, events, metrics |
| `real-time` | real-time, live, SSE, websocket, streaming, notifications |
| `image-optimization` | images, next/image, blur placeholder, og image, responsive |
| `observability` | observability, tracing, health check, OpenTelemetry, circuit breaker |
| `feature-flags` | feature flag, toggle, LaunchDarkly, Edge Config, A/B test |
| `compliance` | GDPR, cookie consent, data export, PII, right to delete, privacy |
| `api-documentation` | OpenAPI, Swagger, API docs, spec, versioning |
| `docker-dev` | docker, container, compose, dev environment, Dockerfile |
| `edge-computing` | edge, edge runtime, geo, CDN, edge function |
| `search` | search, Meilisearch, Algolia, full-text, faceted search |
| `notifications` | notification, push, in-app, toast, alert |
| `multi-tenancy` | tenant, multi-tenant, workspace, organization, B2B |
| `cms` | CMS, headless, Contentful, Sanity, MDX, content |
| `secrets-management` | secrets, vault, env management, key rotation |
| `pwa` | PWA, service worker, offline, web app manifest, installable |
| `trpc` | tRPC, type-safe API, RPC, end-to-end types |
| `storybook` | Storybook, component docs, stories, visual docs |
| `visual-regression` | visual regression, screenshot test, pixel diff |
| `visual-design` | color harmony, elevation, shadow, gradient, glassmorphism, visual hierarchy, spacing rhythm, premium, polished, beautiful, stunning, aesthetic |
| `landing-patterns` | hero section, landing page, bento grid, pricing table, social proof, CTA, conversion, marketing, homepage, above the fold |
| `animation` | animation, motion, framer motion, transition, animate, page transition, microinteraction |
| `dark-mode` | dark mode, theme, light mode, theme switching, next-themes, color scheme |
| `data-tables` | table, data table, TanStack Table, sorting, filtering, pagination, virtualization |
| `advanced-form-ux` | wizard, multi-step form, auto-save, conditional fields, date picker, combobox |
| `charts` | chart, graph, visualization, recharts, tremor, bar chart, line chart, dashboard chart |
| `drag-drop` | drag and drop, sortable, kanban, reorder, dnd-kit, drag |
| `composition-patterns` | compound component, composition, context provider, boolean props, variant component, prop drilling |
| `layout-patterns` | dashboard layout, sidebar, split view, master-detail, sticky header, breadcrumb |
| `responsive-design` | responsive, mobile-first, container query, breakpoint, touch target, viewport |
| `rich-text` | rich text, editor, tiptap, WYSIWYG, content editor, markdown editor |
| `virtualization` | virtual list, infinite scroll, windowed, large list, scroll performance |

## Selection Examples

| User Request | Selected Skills |
|-------------|-----------------|
| "Add a blog page with data from Prisma" | `nextjs-routing`, `nextjs-data`, `prisma` |
| "Create a form to add todos" | `react-forms`, `react-server-actions` |
| "Set up auth with GitHub login" | `auth` |
| "Why is my data stale?" | `caching`, `nextjs-data` |
| "Make my app faster" | `caching`, `react-suspense`, `react-server-components` |
| "Add error handling" | `error-handling` |
| "Start a new project" | `scaffold` |
| "Add translations" | `i18n`, `nextjs-middleware` |
| "Where should I store this state?" | `state-management` |
| "Is my app accessible?" | `accessibility` |
| "Optimize my bundle" | `performance`, `react-server-components` |
| "Generate test data" | `database-seeding`, `prisma` |
| "Validate my env vars at build time" | `env-validation` |
| "Send a welcome email" | `email`, `react-server-actions` |
| "Run this in the background" | `background-jobs` |
| "Add structured data for SEO" | `seo-advanced`, `nextjs-metadata` |
| "Add file uploads" | `file-uploads` |
| "Add rate limiting to my API" | `rate-limiting`, `nextjs-middleware` |
| "Set up logging and error tracking" | `logging`, `error-handling` |
| "Add Stripe payments" | `payments`, `prisma` |
| "Handle Stripe webhooks" | `webhooks`, `payments` |
| "Add analytics tracking" | `analytics` |
| "Add live notifications" | `real-time`, `react-client-components` |
| "Optimize my images" | `image-optimization`, `performance` |
| "Set up multi-tenant SaaS" | `multi-tenancy`, `auth`, `prisma` |
| "Add feature flags" | `feature-flags` |
| "Make my app GDPR compliant" | `compliance`, `security` |
| "Generate API docs" | `api-documentation`, `api-routes` |
| "Add search" | `search`, `prisma` |
| "Add push notifications" | `notifications`, `real-time` |
| "Dockerize my dev environment" | `docker-dev` |
| "Set up Storybook" | `storybook`, `shadcn` |
| "Add animations to my page transitions" | `animation`, `nextjs-routing` |
| "Build a data table with sorting and filtering" | `data-tables`, `shadcn` |
| "Add dark mode to my app" | `dark-mode`, `tailwind-v4` |
| "Create a multi-step onboarding wizard" | `advanced-form-ux`, `react-forms` |
| "Add a dashboard with charts" | `charts`, `layout-patterns` |
| "Make my kanban board draggable" | `drag-drop`, `react-server-actions` |
| "Add a command palette" | `shadcn` |
| "Show a toast after form submission" | `shadcn`, `react-forms` |
| "Make my app work on mobile" | `responsive-design`, `layout-patterns` |
| "Add a rich text editor" | `rich-text`, `file-uploads` |
| "Handle a large list with infinite scroll" | `virtualization`, `nextjs-data` |
| "Add a code block with syntax highlighting" | `cms` |
| "Refactor this component to avoid boolean props" | `composition-patterns`, `react-client-components` |
| "Create a compound component" | `composition-patterns`, `state-management` |
| "Make my site look premium" | `visual-design`, `animation`, `dark-mode` |
| "Create a stunning landing page" | `landing-patterns`, `visual-design`, `animation` |
| "Add a hero section" | `landing-patterns`, `visual-design` |
| "Polish the visual design" | `visual-design`, `shadcn`, `dark-mode` |
| "Add glassmorphic cards" | `visual-design`, `shadcn` |
| "Build a pricing page" | `landing-patterns`, `visual-design` |

## Pattern

### Routing a multi-concern request
```
User: "Add a blog with auth and SEO"

1. Parse keywords: "blog" → routing/data, "auth" → auth, "SEO" → metadata
2. Classify intent: "Add" → action/build
3. Select skills (max 3, one per layer):
   - Architecture: nextjs-routing (blog pages)
   - Infrastructure: auth (authentication)
   - Polish: nextjs-metadata (SEO)
4. Load skills sequentially, unload when done
```

### Routing a knowledge request
```
User: "Why is my data stale after mutation?"

1. Parse keywords: "data stale" → caching, "mutation" → server actions
2. Classify intent: "Why" → reference/explain
3. Select skills (max 2):
   - Architecture: caching (staleness, revalidation)
   - Interaction: react-server-actions (mutation patterns)
4. Load reference content, no side effects
```

## Anti-pattern

Loading more than 3 skills at once. This overloads context and reduces quality.
If a request genuinely spans 4+ concerns, break it into sequential steps.

## Common Mistakes
- Loading more than 3 skills at once — reduces quality, overloads context
- Selecting action skills for "how/why" questions — use reference skills instead
- Not checking project state before routing to action skills (e.g., scaffolding an existing project)
- Routing to a single generic skill when the request spans multiple layers
- Confusing flow pipelines with vibe routing — vibe selects 1-3 skills, flow runs full pipelines

## Checklist
- [ ] Parsed user intent for keywords
- [ ] Matched against skill triggers (When to Use)
- [ ] Selected max 3 skills (one per lifecycle layer preferred)
- [ ] Action skills selected only for create/build/add/scaffold intent
- [ ] Reference skills selected for how/why/explain/show intent
- [ ] Ambiguous intent clarified with user before selecting

## Composes With
- `flow` — for predefined multi-step pipelines
- All 67 other skills — vibe routes TO them
