# Vibe Coding Plugin — Operational Context

## Architecture

This project uses a comprehensive Claude Code plugin with 56 skills, 16 agents, and 9 hooks.

### Skills (56 total)

**Reference Skills** (46 — teach patterns, auto-loaded for "how/why" questions):
- `react-server-components`, `react-client-components`, `react-server-actions`, `react-forms`, `react-suspense`
- `nextjs-routing`, `nextjs-data`, `nextjs-middleware`, `nextjs-metadata`
- `tailwind-v4`, `typescript-patterns`
- `error-handling`, `caching`, `api-routes`, `security`
- `i18n`, `state-management`, `accessibility`, `performance`
- `env-validation`, `email`, `background-jobs`, `seo-advanced`
- `file-uploads`, `rate-limiting`, `logging`, `payments`
- `webhooks`, `analytics`, `real-time`, `image-optimization`
- `observability`, `feature-flags`, `compliance`, `api-documentation`
- `edge-computing`, `secrets-management`
- `search`, `notifications`, `multi-tenancy`, `cms`
- `docker-dev`, `pwa`, `trpc`, `storybook`, `visual-regression`

**Action Skills** (8 — run CLIs, user-triggered for "build/create" tasks):
- `scaffold`, `shadcn`, `prisma`, `auth`, `turbo`, `testing`, `deploy`, `database-seeding`

**Orchestrators** (2 — chain skills together):
- `vibe` — natural language intent router (classifies intent, selects 1-3 skills)
- `flow` — workflow pipelines (build, feature, harden, ship, audit, refactor, i18n, a11y, migration, seo, full-audit, observe, full-feature, security-full, db-health, deps-check, type-check, test-gaps, resilience, gdpr, api-first, b2b-saas, content-site, search-notify, mobile-first, design-system, perf-audit, bundle-optimize, docs-sprint)

### Lifecycle Layers
| Layer | Skills |
|-------|--------|
| Foundation | `scaffold`, `turbo`, `env-validation`, `docker-dev` |
| Infrastructure | `prisma`, `auth`, `api-routes`, `database-seeding`, `email`, `background-jobs`, `file-uploads`, `rate-limiting`, `logging`, `payments`, `webhooks`, `secrets-management`, `search`, `notifications`, `multi-tenancy`, `cms` |
| Architecture | `nextjs-routing`, `nextjs-middleware`, `nextjs-data`, `caching`, `i18n`, `edge-computing`, `trpc` |
| UI | `react-server-components`, `react-client-components`, `shadcn`, `tailwind-v4`, `storybook` |
| Interaction | `react-forms`, `react-server-actions`, `react-suspense`, `error-handling`, `state-management` |
| Polish | `nextjs-metadata`, `typescript-patterns`, `security`, `accessibility`, `seo-advanced`, `analytics`, `real-time`, `image-optimization`, `observability`, `compliance`, `feature-flags`, `api-documentation`, `pwa` |
| Quality | `testing`, `deploy`, `performance`, `visual-regression` |
| Orchestration | `vibe`, `flow` |

### Skill Activation Rules
- **Max 3 skills active simultaneously** to avoid context overload
- Use **reference skills** for understanding patterns
- Use **action skills** for building/creating
- Always **check project state** before scaffolding

### Agents (16)
- `code-reviewer` — React 19, Next.js 15, TypeScript, security, performance review (~20K tokens)
- `a11y-auditor` — WCAG 2.1 AA accessibility audit (~15K tokens)
- `perf-profiler` — Bundle, data fetching, rendering analysis (~20K tokens)
- `migration-assistant` — Framework migration planning (~15K tokens)
- `dependency-auditor` — npm security, licensing, outdated deps, bundle bloat (~10K tokens)
- `seo-auditor` — Meta tags, structured data, sitemap, robots, content SEO (~10K tokens)
- `bundle-auditor` — Route sizes, client/server boundaries, heavy deps, tree-shaking (~10K tokens)
- `api-security-auditor` — Server Action input validation, auth checks, injection prevention (~10K tokens)
- `type-safety-auditor` — No-any enforcement, type narrowing, Zod alignment (~8K tokens)
- `error-handling-auditor` — Error boundaries, Server Action try-catch, error.tsx coverage (~8K tokens)
- `db-query-auditor` — N+1 queries, missing indexes, cascade risks, raw SQL injection (~10K tokens)
- `test-coverage-auditor` — Missing tests for actions, critical flows, error paths (~10K tokens)
- `observability-auditor` — Health endpoints, tracing, timeouts, circuit breakers (~12K tokens)
- `compliance-auditor` — GDPR consent, PII handling, audit logging, data retention (~10K tokens)
- `tenancy-auditor` — Tenant isolation, cross-tenant leaks, query scoping (~10K tokens)
- `api-docs-auditor` — OpenAPI coverage, versioning, documentation completeness (~8K tokens)

Use agents judiciously due to token cost.

### Agent Activation Rules
- **Max 2 agents in parallel** unless user requests more
- `full-audit` pipeline runs up to 15 auditor agents (2 skip based on project state)
- `migration-assistant` is a planning tool, not included in audit pipelines

### Hooks
- **SessionStart** — detects project state (versions, tools, git)
- **PreToolUse (Write/Edit)** — validates server/client boundaries, scans for secrets, blocks .env.local writes, blocks console.log in Server Actions
- **PreToolUse (Bash)** — auto-allows safe commands, blocks dangerous ones
- **PostToolUse (Write/Edit)** — auto-formats with Prettier, runs tsc, warns on next.config changes
- **PostToolUse (Bash)** — regenerates Prisma client after install, reminds about schema changes
- **Stop** — verifies TypeScript compiles, warns about lint errors and uncommitted changes
- **SubagentStop** — evaluates subagent output for actionability and checklist adherence
- **PreCompact** — preserves project context across context compaction
- **SessionEnd** — saves session summary to `.claude/state/last-session.md`

### MCP Servers
- `github` — PR reviews, issues, CI checks
- `postgres` — read-only SQL for schema inspection
- `memory` — persistent key-value store across sessions
