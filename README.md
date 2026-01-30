# Vibe Coding Plugin

A comprehensive Claude Code plugin for building production-grade Next.js 15 + React 19 applications. Provides 56 skills, 16 specialized agents, 9 lifecycle hooks, and 17 CI/CD workflows out of the box.

## What This Is

This is a **Claude Code project configuration** (not a standalone app). Drop it into any Next.js project to get an opinionated, full-stack development environment powered by Claude Code's extensibility systems: skills for patterns and scaffolding, agents for auditing and review, hooks for validation and automation, and MCP servers for GitHub/Postgres/memory integration.

## Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 15 (App Router) |
| UI | React 19 + shadcn/ui |
| Language | TypeScript (strict) |
| Styling | Tailwind CSS v4 (CSS-first) |
| Database | Prisma 7 + PostgreSQL |
| Auth | Auth.js v5 |
| Testing | Vitest + Playwright |

## What's Included

### Skills (56)

Contextual knowledge and CLI automation across the full stack lifecycle:

- **Foundation** -- `scaffold`, `turbo`, `env-validation`, `docker-dev`
- **Infrastructure** -- `prisma`, `auth`, `api-routes`, `email`, `payments`, `webhooks`, `file-uploads`, `rate-limiting`, `logging`, `search`, `notifications`, `multi-tenancy`, `cms`, `background-jobs`, `secrets-management`, `database-seeding`
- **Architecture** -- `nextjs-routing`, `nextjs-middleware`, `nextjs-data`, `caching`, `i18n`, `edge-computing`, `trpc`
- **UI** -- `react-server-components`, `react-client-components`, `shadcn`, `tailwind-v4`, `storybook`
- **Interaction** -- `react-forms`, `react-server-actions`, `react-suspense`, `error-handling`, `state-management`
- **Polish** -- `nextjs-metadata`, `typescript-patterns`, `security`, `accessibility`, `seo-advanced`, `analytics`, `real-time`, `image-optimization`, `observability`, `compliance`, `feature-flags`, `api-documentation`, `pwa`
- **Quality** -- `testing`, `deploy`, `performance`, `visual-regression`
- **Orchestration** -- `vibe` (natural language router), `flow` (workflow pipelines)

Use reference skills for learning patterns, action skills for scaffolding, and orchestrators to chain multiple skills together.

### Agents (16)

Specialized auditors and reviewers that run as subagents:

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | React 19, Next.js 15, TypeScript, security, performance |
| `a11y-auditor` | WCAG 2.1 AA compliance |
| `perf-profiler` | Bundle size, data fetching, rendering |
| `api-security-auditor` | Server Action validation, auth, injection |
| `db-query-auditor` | N+1 queries, missing indexes, cascade risks |
| `type-safety-auditor` | No-any enforcement, Zod alignment |
| `error-handling-auditor` | Error boundaries, error.tsx coverage |
| `test-coverage-auditor` | Missing tests for critical flows |
| `bundle-auditor` | Client/server boundaries, tree-shaking |
| `seo-auditor` | Meta tags, structured data, sitemap |
| `dependency-auditor` | Security, licensing, bundle bloat |
| `observability-auditor` | Health endpoints, tracing, circuit breakers |
| `compliance-auditor` | GDPR, PII handling, audit logging |
| `tenancy-auditor` | Tenant isolation, cross-tenant leaks |
| `api-docs-auditor` | OpenAPI coverage, versioning |
| `migration-assistant` | Framework migration planning |

### Hooks (9)

Lifecycle automation that validates, formats, and guards your code:

- **SessionStart/Resume** -- Detects project state (versions, tools, git)
- **PreToolUse (Write/Edit)** -- Validates server/client boundaries, scans for secrets, blocks `.env.local` writes
- **PreToolUse (Bash)** -- Auto-allows safe commands, blocks dangerous ones
- **PostToolUse (Write/Edit)** -- Auto-formats with Prettier, runs `tsc`
- **PostToolUse (Bash)** -- Regenerates Prisma client after installs
- **Stop** -- Verifies TypeScript compiles, warns about uncommitted changes
- **SubagentStop** -- Evaluates subagent output quality
- **PreCompact** -- Preserves project context across compaction
- **SessionEnd** -- Saves session summary

### CI/CD Workflows (17)

GitHub Actions for automated quality gates: build checks, linting, testing, bundle size tracking, dependency audits, type coverage, migration testing, PR size checks, deploy previews, release automation, and more.

### MCP Servers (3)

- **GitHub** -- PR reviews, issues, CI checks
- **PostgreSQL** -- Read-only SQL for schema inspection
- **Memory** -- Persistent key-value store across sessions

## Quick Start

1. Clone this repo into your project root (or copy the files):

```bash
git clone https://github.com/soilmass/vibe-coding-plugin.git
```

2. Copy `.env.example` and fill in your values:

```bash
cp .env.example .env.local
```

3. Open Claude Code in your project directory. The plugin activates automatically via `CLAUDE.md` and `.claude/settings.json`.

4. Try the orchestrator:

```
> /vibe scaffold a new SaaS app with auth and payments
```

Or use individual skills:

```
> /scaffold
> /auth
> /prisma
```

## Workflow Pipelines

The `flow` skill chains multiple skills into predefined pipelines:

```
> /flow build       # scaffold + prisma + auth + deploy
> /flow feature     # routing + forms + actions + testing
> /flow harden      # security + rate-limiting + error-handling
> /flow full-audit  # runs all 15 auditor agents
> /flow ship        # build + test + deploy
```

29 pipelines available including `b2b-saas`, `gdpr`, `api-first`, `perf-audit`, `bundle-optimize`, and more.

## Project Structure

```
.claude/
  agents/          # 16 auditor/reviewer agent definitions
  hooks/           # 9 lifecycle hook scripts (bash + python)
  skills/          # 56 skill directories
  settings.json    # Permissions, hooks config, sandbox rules
  CLAUDE.md        # Operational context for Claude
.github/
  workflows/       # 17 CI/CD workflow definitions
  ISSUE_TEMPLATE/  # Bug report and feature request templates
  CONTRIBUTING.md
  SECURITY.md
CLAUDE.md            # Architecture rules and code patterns
claude-ecosystem.md  # Complete reference for Claude Code extensibility
.mcp.json            # MCP server configuration
.env.example         # Required environment variables
```

## Permissions Model

The plugin uses a three-tier permission system defined in `.claude/settings.json`:

- **Allow** -- Read operations, dev commands, linting, testing, Prisma generation
- **Ask** -- Package installs, git mutations, Docker, deployments
- **Deny** -- Destructive operations (`rm -rf`, `sudo`, `.env` access, DB drops)

Sandbox mode is enabled by default with auto-allow for bash commands that pass validation.

## License

MIT
