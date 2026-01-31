# Vibe Coding Plugin

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/Skills-77-blueviolet)](/.claude/skills)
[![Agents](https://img.shields.io/badge/Agents-18-orange)](/.claude/agents)
[![Hooks](https://img.shields.io/badge/Hooks-10-green)](/.claude/hooks)

A production-grade Claude Code plugin for Next.js 15 + React 19. Drop it into any project to get 77 skills for patterns and scaffolding, 18 specialized auditor agents, 10 lifecycle hooks for validation and automation, 33 workflow pipelines, and MCP integrations for GitHub, Postgres, and persistent memory — all wired together and ready to use.

## Table of Contents

- [Quick Start](#quick-start)
- [Stack](#stack)
- [Skills (77)](#skills-77)
- [Visual Stunner Suite](#visual-stunner-suite)
- [Agents (18)](#agents-18)
- [Hooks (10)](#hooks-10)
- [Pipelines (33)](#pipelines-33)
- [MCP Servers](#mcp-servers)
- [Project Structure](#project-structure)
- [Permissions Model](#permissions-model)
- [Usage Examples](#usage-examples)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

1. **Clone** into your project root:

```bash
git clone https://github.com/soilmass/vibe-coding-plugin.git
```

2. **Configure** environment variables:

```bash
cp .env.example .env.local
```

3. **Open Claude Code** in your project directory — the plugin activates automatically via `CLAUDE.md` and `.claude/settings.json`.

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

## Skills (77)

Contextual knowledge and CLI automation across the full stack lifecycle. Reference skills teach patterns (auto-loaded for "how/why" questions), action skills run CLIs (user-triggered for "build/create" tasks), and orchestrators chain skills together.

### Foundation (4)

`scaffold` · `turbo` · `env-validation` · `docker-dev`

### Infrastructure (16)

`prisma` · `auth` · `api-routes` · `database-seeding` · `email` · `background-jobs` · `file-uploads` · `rate-limiting` · `logging` · `payments` · `webhooks` · `secrets-management` · `search` · `notifications` · `multi-tenancy` · `cms`

### Architecture (9)

`nextjs-routing` · `nextjs-middleware` · `nextjs-data` · `caching` · `i18n` · `edge-computing` · `trpc` · `layout-patterns` · `composition-patterns`

### UI (17)

`react-server-components` · `react-client-components` · `shadcn` · `tailwind-v4` · `storybook` · `visual-design` · `landing-patterns` · `animation` · `dark-mode` · `charts` · `creative-scrolling` · `advanced-typography` · `cursor-effects` · `webgl-3d` · `svg-canvas` · `loading-transitions` · `sound-design`

### Interaction (9)

`react-forms` · `react-server-actions` · `react-suspense` · `error-handling` · `state-management` · `data-tables` · `advanced-form-ux` · `drag-drop` · `rich-text`

### Polish (15)

`nextjs-metadata` · `typescript-patterns` · `security` · `accessibility` · `seo-advanced` · `analytics` · `real-time` · `image-optimization` · `observability` · `compliance` · `feature-flags` · `api-documentation` · `pwa` · `responsive-design` · `virtualization`

### Quality (5)

`testing` · `deploy` · `performance` · `visual-regression` · `readme`

### Orchestration (2)

`vibe` — natural language intent router (classifies intent, selects 1–3 skills)
`flow` — workflow pipelines (chains skills into 33 predefined sequences)

## Visual Stunner Suite

Seven creative skills for building Awwwards-level interfaces:

| Skill | What It Does |
|-------|-------------|
| `creative-scrolling` | Lenis smooth scroll, GSAP ScrollTrigger, horizontal sections, scroll-linked animations |
| `advanced-typography` | Variable fonts, fluid type scale, kinetic text, text splitting, glitch/scramble effects |
| `cursor-effects` | Custom cursor with spring physics, magnetic elements, cursor trail, spotlight, blend modes |
| `webgl-3d` | React Three Fiber, GLTF models, custom shaders, particle systems, post-processing |
| `svg-canvas` | SVG line drawing, morphing, blob shapes, canvas particles, generative art, filter effects |
| `loading-transitions` | Preloaders, View Transitions API, route overlays, staggered reveals, font load detection |
| `sound-design` | Howler.js audio, interaction sounds, ambient audio, spatial sound, mute toggle |

Chain them all with `/flow ui-premium` for a complete premium UI pass.

## Agents (18)

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
| `ux-auditor` | Loading states, empty states, dark mode, touch targets, responsive |
| `design-auditor` | Color consistency, elevation, hierarchy, spacing, microinteractions |

Run all 17 auditor agents at once with `/flow full-audit`.

## Hooks (10)

Lifecycle automation that validates, formats, and guards your code:

- **SessionStart** — Detects project state (versions, tools, git)
- **SessionResume** — Lightweight refresh on session resume (dev server status, git state)
- **PreToolUse (Write/Edit)** — Validates server/client boundaries, scans for secrets, blocks `.env.local` writes, blocks `console.log` in Server Actions
- **PreToolUse (Bash)** — Auto-allows safe commands, blocks dangerous ones
- **PostToolUse (Write/Edit)** — Auto-formats with Prettier, runs `tsc`, warns on `next.config` changes
- **PostToolUse (Bash)** — Regenerates Prisma client after installs, reminds about schema changes
- **Stop** — Verifies TypeScript compiles, warns about lint errors and uncommitted changes
- **SubagentStop** — Evaluates subagent output for actionability and checklist adherence
- **PreCompact** — Preserves project context across context compaction
- **SessionEnd** — Saves session summary to `.claude/state/last-session.md`

## Pipelines (33)

The `flow` skill chains multiple skills into predefined pipelines. Run any pipeline with `/flow <name>`.

### Core Workflows

| Pipeline | Chain | Description |
|----------|-------|-------------|
| `build` | env-validation → scaffold → prisma → database-seeding → auth → logging → shadcn | Full project setup from zero |
| `feature` | nextjs-routing → react-server-components → react-forms → react-server-actions | Complete feature with UI and data |
| `full-feature` | nextjs-routing → react-server-components → react-forms → react-server-actions → logging → testing | Feature with observability |
| `interactive-feature` | nextjs-routing → react-server-components → react-forms → advanced-form-ux → react-server-actions → animation → testing | Feature with rich interactivity |
| `ship` | testing → performance → deploy | Test, verify perf, deploy |

### Code Quality

| Pipeline | Chain | Description |
|----------|-------|-------------|
| `audit` | typescript-patterns → security → caching | Code quality and security review |
| `full-audit` | All 17 auditor agents | Comprehensive project audit |
| `refactor` | react-server-components → react-client-components → caching | Optimize component architecture |
| `type-check` | typescript-patterns → type-safety-auditor | No-any enforcement pass |
| `test-gaps` | test-coverage-auditor → testing | Missing test detection + fix |
| `deps-check` | dependency-auditor | npm security, licensing, bloat |

### Security & Compliance

| Pipeline | Chain | Description |
|----------|-------|-------------|
| `harden` | security → secrets-management → rate-limiting → accessibility → performance → observability → error-handling → caching → testing | Production readiness |
| `security-full` | security → api-security-auditor → rate-limiting → logging | Security depth with agent review |
| `gdpr` | compliance → prisma → security → logging → testing | GDPR-compliant data handling |
| `resilience` | observability → error-handling → logging → testing | Health checks, tracing, circuit breakers |

### Infrastructure

| Pipeline | Chain | Description |
|----------|-------|-------------|
| `migration` | prisma → database-seeding → testing | Database migration with seed and verify |
| `db-health` | prisma → db-query-auditor → testing | Database optimization audit |
| `observe` | logging → analytics → error-handling → performance | Observability stack setup |
| `api-first` | api-routes → trpc → api-documentation → typescript-patterns → security → testing | API-first with auto-generated docs |

### SEO & Content

| Pipeline | Chain | Description |
|----------|-------|-------------|
| `seo` | nextjs-metadata → seo-advanced → i18n → performance | Full SEO optimization pass |
| `content-site` | cms → nextjs-metadata → seo-advanced → edge-computing → image-optimization → performance | Marketing site with CMS and SEO |
| `docs-sprint` | api-documentation → storybook → testing | API docs, component docs, tests |

### UI & Design

| Pipeline | Chain | Description |
|----------|-------|-------------|
| `ui-polish` | visual-design → cursor-effects → composition-patterns → dark-mode → animation → responsive-design → layout-patterns → accessibility | Visual polish pass |
| `landing-polish` | landing-patterns → visual-design → creative-scrolling → advanced-typography → animation → seo-advanced → image-optimization → performance | Marketing site with visual polish |
| `ui-premium` | visual-design → cursor-effects → creative-scrolling → advanced-typography → svg-canvas → webgl-3d → loading-transitions → sound-design → animation → dark-mode | Awwwards-level premium UI |
| `design-system` | visual-design → storybook → shadcn → visual-regression → accessibility → tailwind-v4 | Design system with regression testing |
| `bundle-optimize` | bundle-auditor → react-server-components → react-client-components → performance | Client/server boundary optimization |
| `perf-audit` | perf-profiler → bundle-auditor → performance | Performance and bundle audit |

### Domain-Specific

| Pipeline | Chain | Description |
|----------|-------|-------------|
| `i18n` | i18n → nextjs-routing → nextjs-middleware → nextjs-metadata | Full internationalization setup |
| `a11y` | accessibility → shadcn → react-forms → testing | Accessibility compliance pass |
| `b2b-saas` | multi-tenancy → feature-flags → compliance → auth → payments → testing | B2B SaaS with tenant isolation |
| `search-notify` | search → notifications → real-time → analytics → testing | Search with notifications |
| `mobile-first` | pwa → notifications → image-optimization → accessibility → performance → testing | Mobile-first PWA |

## MCP Servers

- **GitHub** — PR reviews, issues, CI checks
- **PostgreSQL** — Read-only SQL for schema inspection
- **Memory** — Persistent key-value store across sessions

## Project Structure

```
.claude/
  agents/          # 18 auditor/reviewer agent definitions
  hooks/           # 10 lifecycle hook scripts (bash + python)
  skills/          # 77 skill directories
  settings.json    # Permissions, hooks config, sandbox rules
  CLAUDE.md        # Operational context for Claude
.github/
  workflows/       # CI/CD workflow definitions
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

- **Allow** — Read operations, dev commands, linting, testing, Prisma generation
- **Ask** — Package installs, git mutations, Docker, deployments
- **Deny** — Destructive operations (`rm -rf`, `sudo`, `.env` access, DB drops)

Sandbox mode is enabled by default with auto-allow for bash commands that pass validation.

## Usage Examples

```bash
# Natural language — let the orchestrator pick skills
/vibe scaffold a new SaaS app with auth and payments

# Individual skills
/scaffold
/auth
/prisma

# Workflow pipelines
/flow build          # Full project setup
/flow feature        # Complete feature pipeline
/flow harden         # Production readiness
/flow full-audit     # Run all 17 auditor agents
/flow ui-premium     # Awwwards-level UI pass
/flow b2b-saas       # Multi-tenant SaaS setup
```

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines.

## License

MIT
