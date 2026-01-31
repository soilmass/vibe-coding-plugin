---
name: readme
description: >
  README authoring patterns — section order, badges, progressive disclosure, writing style, developer tool conventions
allowed-tools: Read, Grep, Glob
---

# README

## Purpose
Canonical patterns for writing high-quality README files for developer tools, libraries, and plugins. Covers section ordering, badge conventions, writing style, progressive disclosure, and common pitfalls. The ONE skill for making project documentation effective.

## When to Use
- Writing a README from scratch for a new project
- Restructuring an existing README that buries the value prop
- Adding badges, ToC, or visual hierarchy to a README
- Reviewing a README for completeness and clarity
- Ensuring README numbers match the actual project state

## When NOT to Use
- API reference documentation → `api-documentation`
- Component documentation → `storybook`
- Deployment documentation → `deploy`
- In-code comments and JSDoc → `typescript-patterns`
- SEO for public docs sites → `seo-advanced`

## Pattern

### 1. Canonical Section Order

Follow this order for developer tool READMEs. Skip sections that don't apply, but never reorder.

```
1. Title + Badges
2. One-paragraph value proposition (what it is, who it's for, why it matters)
3. Table of Contents (if > 5 sections)
4. Quick Start (3 steps max — clone, configure, run)
5. Stack / Requirements table
6. Features (organized by category with counts)
7. Feature highlights (spotlight 1-2 differentiators)
8. Configuration / API reference
9. Architecture / Project structure
10. Usage examples (concrete, copy-pasteable)
11. Contributing link
12. License
```

### 2. Badge Conventions

Use shields.io badges for at-a-glance project metadata. Place them directly under the title, one line.

```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/Skills-76-blueviolet)](/.claude/skills)
[![npm](https://img.shields.io/npm/v/package-name.svg)](https://npmjs.com/package/package-name)
```

Rules:
- Max 5 badges — more creates visual noise
- Order: license → version/size → count badges → CI status
- Use consistent color scheme (blue family or brand colors)
- Link each badge to the relevant resource
- Keep badges on one line (no line breaks between them)

### 3. Writing Style Rules

**Value proposition** — first paragraph, no heading. Answer: "What is this? Who is it for? What do I get?"

```markdown
# Project Name

A [what it is] for [who it's for]. [Key differentiator] — [concrete benefit].
```

**Feature descriptions** — lead with the benefit, not the implementation.

```markdown
<!-- GOOD -->
18 specialized auditor agents that catch issues before they reach production

<!-- BAD -->
Uses subagent architecture with token-budgeted prompt engineering
```

**Counts** — always include counts in headings when listing features. Readers scan for scale.

```markdown
## Skills (76)     ← good: signals breadth
## Skills          ← bad: no sense of scale
```

**Tables** — use for structured data (features, config options, agents). Use bullet lists for sequential items (steps, hooks).

### 4. Progressive Disclosure

Structure information from most-important to least-important within each section:

1. **Quick Start** comes before feature list — let people try it first
2. **Feature list** uses categories with inline counts, not a flat dump
3. **Detailed config** goes after the overview, not before
4. **Architecture/structure** is reference material — put it near the bottom
5. **License** is always last

For feature lists with 10+ items, group by category with subheadings:

```markdown
## Skills (76)

### Foundation (4)
`scaffold` · `turbo` · `env-validation` · `docker-dev`

### Infrastructure (16)
`prisma` · `auth` · `api-routes` · ...
```

### 5. Code Block Best Practices

```markdown
<!-- Always specify language for syntax highlighting -->
```bash        ← not just ```
git clone ...
```

<!-- Use comments to explain non-obvious steps -->
```bash
# Install dependencies (requires Node 18+)
npm install
```

<!-- Keep examples copy-pasteable — no $ prefix, no output mixing -->
```bash
npm install        ← good
$ npm install      ← bad ($ breaks copy-paste)
```
```

### 6. Visual Elements Guide

**Separator patterns** — use `·` (middle dot) for inline skill/feature lists, `→` for pipeline chains, `|` for table columns.

```markdown
`skill-a` · `skill-b` · `skill-c`          ← feature lists
env-validation → scaffold → prisma → auth   ← pipeline chains
```

**Highlight boxes** — use sparingly for truly important callouts:

```markdown
> **Note**: This plugin requires Claude Code v1.0+
```

**File trees** — use fenced code blocks with no language specifier for project structure:

```markdown
```
src/
  app/
  components/
  lib/
```
```

### 7. Developer Tool Specific Patterns

For CLIs, plugins, and developer tools:

- Show the **invocation syntax** early (how do I use this?)
- Include **concrete examples** with realistic values, not `foo`/`bar`
- List **prerequisites** in the Quick Start, not buried in a separate section
- Add a **Permissions/Security** section if the tool has access controls
- Link to **CONTRIBUTING.md** rather than inlining contribution guidelines

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Buried value prop | Reader doesn't know what the project does after 3 seconds | First paragraph under title, no heading |
| Wall of text | No visual hierarchy, readers bounce | Use headings, tables, badges, code blocks |
| No Quick Start | Reader can't try it without reading everything | 3-step Quick Start near the top |
| Vague features | "Powerful", "flexible", "comprehensive" say nothing | Concrete counts and specifics |
| Stale badges/counts | Numbers don't match reality | Single source of truth, verify before publish |
| Giant flat list | 50+ items in one bullet list | Group by category with counts |
| Implementation-first | Leads with architecture, not benefits | Lead with what users get, not how it works |
| No examples | Reader can't picture the workflow | Add usage examples section with real commands |

## Common Mistakes

1. **Forgetting to update counts** — README says 56 skills but project has 76. Always verify against the source of truth (e.g., `CLAUDE.md`, actual file count).
2. **Mixing prose and reference** — the README should be a guided tour, not a reference manual. Link to detailed docs instead.
3. **No Table of Contents** — any README with more than 5 sections needs a ToC for navigation.
4. **Inconsistent formatting** — mixing `*` and `-` for bullets, inconsistent heading levels, or tabs vs spaces.
5. **Dead links** — badge URLs, relative links to files that moved, or external links that rotted.

## Checklist

- [ ] Title + badges on first line (max 5 badges)
- [ ] Value proposition in first paragraph (no heading, answers what/who/why)
- [ ] Table of Contents present (if > 5 sections)
- [ ] Quick Start within first screenful (3 steps max)
- [ ] All counts match actual project state
- [ ] Features grouped by category with counts in headings
- [ ] Key differentiators highlighted (not buried in lists)
- [ ] All code blocks have language specifiers
- [ ] Examples are copy-pasteable (no `$` prefix)
- [ ] Tables used for structured data, bullets for sequential items
- [ ] No stale badges or dead links
- [ ] Contributing link present (not inlined guidelines)
- [ ] License section present as last item

## Composes With

- `deploy` — deployment instructions in Quick Start
- `testing` — test commands in usage examples
- `storybook` — link to component documentation
- `api-documentation` — link to API reference
- `visual-design` — README visual hierarchy mirrors design system principles
