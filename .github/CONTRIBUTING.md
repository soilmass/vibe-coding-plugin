# Contributing

## Skill Development Guide

### Skill Template (8 Sections)

Every skill follows this structure:

1. **YAML Frontmatter** — `name`, `description`, `allowed-tools`, optional `disable-model-invocation`
2. **Purpose** — What this skill does (2-3 sentences, "The ONE skill for...")
3. **When to Use / When NOT to Use** — Clear routing guidance
4. **Pattern** — Code examples showing the correct approach
5. **Anti-pattern** — Code examples showing what NOT to do
6. **Common Mistakes** — Bullet list of frequent errors
7. **Checklist** — Markdown checkbox list for verification
8. **Composes With** — Skills this one works alongside

### Rules

- **Max 150 lines** per SKILL.md
- **Reference skills**: teach patterns, no side effects
  - Set `allowed-tools: Read, Grep, Glob`
- **Action skills**: run CLIs, require user invocation
  - Set `disable-model-invocation: true`
  - Add specific CLI tools to `allowed-tools`
- YAML frontmatter must include `name` and `description`
- Use fenced code blocks with language tags
- Keep descriptions in `>` block scalar format

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Skill directory | kebab-case | `env-validation/` |
| Skill file | Always `SKILL.md` | `SKILL.md` |
| Skill name | kebab-case | `background-jobs` |

### Testing Checklist

Before submitting a new skill:

- [ ] Follows 8-section template
- [ ] Under 150 lines
- [ ] Valid YAML frontmatter
- [ ] Code examples compile (check with `npx tsc --noEmit`)
- [ ] "When NOT to Use" references exist as skills
- [ ] "Composes With" references are bidirectional
- [ ] No duplicate content with existing skills

## Agent Development

### Structure

Agents use markdown with these sections:
- Configuration (model, tools, max turns)
- Purpose
- Checklist
- Output Format
- Sample Output
- Instructions

### Rules

- Use `sonnet` model for cost efficiency
- Keep max turns reasonable (10-15)
- Include concrete sample output
- Checklist items must be actionable and verifiable

## Hooks

### Adding a New Hook

1. Create script in `.claude/hooks/`
2. Register in `.claude/settings.json` under appropriate event
3. Use exit code 0 (pass), 1 (block with message), 2 (block)
4. Write messages to stderr (stdout is for data)

## Pull Requests

- One skill/agent/hook per PR
- Include the reason for the addition
- Update `.claude/CLAUDE.md` counts and lists
- Update orchestrators (vibe/flow) if applicable
