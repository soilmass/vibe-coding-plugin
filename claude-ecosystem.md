# Claude Code ecosystem: The complete best practices reference

Claude Code transforms from a simple AI assistant into a sophisticated development orchestration platform through its **extensibility systems** (Hooks, Skills, MCP), **multi-agent architecture** (Subagents, Task Tool), and **enterprise-grade security** (6-layer model, sandboxing, managed policies). This reference provides both conceptual frameworks and practical configurations for individual developers, teams, and CI/CD automation across all major subsystems.

The ecosystem operates on three key principles: **progressive disclosure** (load context only when needed), **permission-by-default** (explicit approval for actions), and **hierarchical configuration** (enterprise > project > user). Mastering these systems enables token-efficient, secure, and scalable AI-assisted development workflows.

---

## Hooks system delivers complete lifecycle control

The hooks system intercepts **10 lifecycle events**, enabling validation, automation, and custom logic at every stage of Claude's operation. Hooks execute via shell commands or LLM prompts, with JSON output controlling whether operations proceed, modify inputs, or halt entirely.

### All 10 lifecycle events with their capabilities

| Event | Description | Matchers | Blocking |
|-------|-------------|----------|----------|
| **PreToolUse** | Before tool execution, after parameters created | Tool names, regex, MCP patterns | Exit 2 or `permissionDecision: deny` |
| **PostToolUse** | After successful tool completion | Same as PreToolUse | JSON `decision: block` provides feedback |
| **PermissionRequest** | When permission dialog shown | Same as PreToolUse | Exit 2 or `behavior: deny` |
| **UserPromptSubmit** | When user submits prompt | None (always triggers) | Exit 2 or `decision: block` |
| **Notification** | On notifications | `permission_prompt`, `idle_prompt`, `auth_success` | N/A |
| **Stop** | When main agent finishes | None | Exit 2 or `decision: block` |
| **SubagentStop** | When subagent completes | None | Exit 2 or `decision: block` |
| **PreCompact** | Before compaction | `manual`, `auto` | N/A |
| **SessionStart** | At session start/resume | `startup`, `resume`, `clear`, `compact` | N/A |
| **SessionEnd** | When session ends | None | N/A (cleanup only) |

### Command hooks versus prompt hooks

**Command hooks** execute bash scripts with deterministic logic—ideal for file validation, regex checks, and environment verification. **Prompt hooks** query Haiku (~$0.0004 per call) for context-aware decisions—useful for semantic validation and complex approval logic.

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash|Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/hooks/validate.py",
        "timeout": 60
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Evaluate if Claude should stop: $ARGUMENTS. Check if all tasks complete.",
        "timeout": 30
      }]
    }]
  }
}
```

### Matcher patterns support regex and MCP tools

| Pattern | Example | Matches |
|---------|---------|---------|
| Exact | `"Write"` | Write tool only |
| Regex OR | `"Edit\|Write"` | Edit OR Write |
| Regex wildcard | `"Notebook.*"` | All Notebook tools |
| MCP server | `"mcp__memory__.*"` | All tools from memory server |
| MCP specific | `"mcp__github__create_issue"` | Specific MCP tool |

### Control flow JSON output fields

**Common fields** (all hooks): `continue` (false halts Claude), `stopReason`, `suppressOutput`, `systemMessage`

**PreToolUse decisions**:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "Explanation",
    "updatedInput": { "field": "modified_value" }
  }
}
```

**Exit codes**: 0 = success (JSON parsed), 2 = blocking error (stderr to Claude), other = non-blocking error

### Environment variables available in hooks

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROJECT_DIR` | Absolute path to project root |
| `CLAUDE_ENV_FILE` | File path for persisting env vars (SessionStart only) |
| `CLAUDE_CODE_REMOTE` | `"true"` if remote/web |
| `CLAUDE_PLUGIN_ROOT` | Plugin directory path |

**Hook input via stdin** includes `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`, `tool_name`, `tool_input`, and `tool_use_id`.

### Production hook configuration example

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate-bash.py"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "jq -r '.tool_input.file_path' | { read f; npx prettier --write \"$f\" 2>/dev/null; }"
      }]
    }],
    "SessionStart": [{
      "matcher": "startup",
      "hooks": [{
        "type": "command",
        "command": "echo \"Branch: $(git rev-parse --abbrev-ref HEAD)\""
      }]
    }]
  }
}
```

---

## Subagents enable parallel execution with critical constraints

Claude Code's subagent architecture transforms single-threaded assistance into **multi-agent orchestration**. Each subagent operates in an **isolated context window** (~200K tokens), with the critical constraint that **subagents cannot spawn other subagents**—one level of delegation only.

### Built-in agents serve specialized purposes

| Agent | Model | Tools | Use Case |
|-------|-------|-------|----------|
| **Explore** | Haiku | Read-only (Glob, Grep, Read, limited Bash) | Fast codebase exploration |
| **Plan** | Sonnet | Read, Glob, Grep, Bash | Research during plan mode |
| **General-purpose** | Sonnet | All tools | Complex multi-step tasks |

### Parallel execution caps at 10 concurrent tasks

Tasks execute in **batches of 10**—Claude queues additional tasks but waits for the entire batch to complete before starting the next. This batch behavior means you cannot dynamically pull from the queue as individual tasks finish.

### Token overhead costs approximately 20K per subagent

Each Task invocation incurs **~10K-20K tokens** before any user work begins. Active multi-agent sessions consume **3-4x more tokens** than single-threaded operations. For tasks under 30 seconds, staying in the main thread is 10x cheaper.

### Custom agent configuration in `.claude/agents/`

```markdown
---
name: code-reviewer
description: Expert code review. MUST BE USED after code changes.
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: default
skills: security-audit
---

You are a senior code reviewer ensuring high standards.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code simplicity and readability
- No exposed secrets or API keys
- Proper error handling
```

### Task tool invocation pattern

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="description">Short task description</parameter>
  <parameter name="prompt">Detailed instructions for the sub-agent</parameter>
  <parameter name="run_in_background">true</parameter>
</invoke>
```

### Context isolation requires explicit information passing

Subagents start with **zero context from the parent**—all necessary information must be passed via the prompt parameter. Results route through the main thread; subagents cannot directly share memory.

**Decision framework**: Use Task tool for one-off parallel work; use custom subagents for repeated specialized work requiring domain expertise.

---

## Skills system enables progressive context loading

Skills provide **reusable AI capabilities** with a three-level progressive disclosure system that reduces token consumption by **98%** when skills are present but not used.

### Directory structure and SKILL.md specification

```
skill-name/
├── SKILL.md              # Required - instructions with YAML frontmatter
├── scripts/              # Optional - executable code
├── references/           # Optional - documentation loaded on demand
└── assets/               # Optional - templates, binary files
```

### Complete frontmatter fields

```yaml
---
name: pdf-processing                    # Required: max 64 chars, lowercase + hyphens
description: >                          # Required: max 1024 chars
  Extract text from PDFs. Use when working with PDF files.
license: Apache-2.0                     # Optional
compatibility: Requires Python 3.9+     # Optional: max 500 chars
metadata:                               # Optional: arbitrary key-value
  author: my-org
  version: "2.0"
allowed-tools: Read Bash               # Optional: pre-approved tools
context: fork                          # Optional: 'inline' (default) or 'fork'
disable-model-invocation: true         # Optional: user-only invocation
agent: Explore                         # Optional: subagent for fork context
---
```

### Progressive disclosure minimizes token usage

| Level | Content | Token Cost | When Loaded |
|-------|---------|------------|-------------|
| **Level 1** | Metadata only | ~30-100 tokens | Always at startup |
| **Level 2** | Full SKILL.md body | <5,000 tokens | When skill activated |
| **Level 3** | Referenced files | Unlimited | Only when required |

### Token efficiency best practices

Keep SKILL.md under **500 lines**; split longer content into reference files. Execute scripts rather than reading them into context—only output consumes tokens. Bundle comprehensive resources freely; no penalty until accessed.

---

## MCP integration connects external tools and services

The Model Context Protocol enables Claude Code to interact with **external services** through standardized tool interfaces. Configuration supports three scopes with clear precedence rules.

### Configuration file formats and scopes

| Scope | Location | Precedence |
|-------|----------|------------|
| **Enterprise** | `/Library/Application Support/ClaudeCode/managed-mcp.json` (macOS) | Highest |
| **Local** | `~/.claude.json` under project path | High |
| **Project** | `.mcp.json` in project root | Medium |
| **User** | `~/.claude.json` (mcpServers field) | Lower |

### Transport types for different deployment scenarios

**STDIO** (recommended for local): Zero network overhead, runs as child process
```json
{
  "mcpServers": {
    "airtable": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "airtable-mcp-server"],
      "env": { "AIRTABLE_API_KEY": "${AIRTABLE_API_KEY}" }
    }
  }
}
```

**HTTP** (recommended for remote): Modern standard with streaming support
```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${TOKEN}" }
    }
  }
}
```

### Tool naming follows mcp__servername__toolname convention

Permission rules use this format: `mcp__github` approves all GitHub tools; `mcp__github__get_issue` approves only the specific tool.

### MCP tool search reduces context consumption by 85%

Auto-enabled when MCP tool descriptions exceed **10% of context window**. Tools marked with `defer_loading: true` are discovered dynamically. Requires Sonnet 4+ or Opus 4+.

---

## Slash commands provide 35+ built-in operations

### Essential built-in commands

| Command | Purpose |
|---------|---------|
| `/compact` | Manually compact conversation with optional focus |
| `/context` | Visualize context usage as colored grid |
| `/cost` | Show token usage statistics |
| `/memory` | Edit CLAUDE.md memory files |
| `/mcp` | Manage MCP server connections |
| `/permissions` | View or update permission rules |
| `/rewind` | Rewind conversation and/or code |
| `/review` | Request code review |
| `/doctor` | Check installation health |

### Custom command format in `.claude/commands/`

```yaml
---
description: Review a PR with security focus
argument-hint: [pr-number]
allowed-tools: Bash(git *), Read, Grep
model: claude-sonnet-4-5-20250929
disable-model-invocation: false
---

## Context
- PR diff: !`gh pr diff $1`
- Current branch: !`git branch --show-current`

## Task
Review PR #$1 for security vulnerabilities.
Focus on OWASP Top 10 issues.
```

**Variables**: `$ARGUMENTS` (all args), `$1`, `$2` (positional), `!command` (bash execution), `@filename` (file reference)

---

## Six-layer security architecture protects against threats

Claude Code implements defense-in-depth with **six complementary security layers**:

1. **Permission-based architecture**: Read-only by default, explicit approval for actions
2. **OS-level sandboxing**: Seatbelt (macOS), bubblewrap (Linux/WSL2)
3. **Write access restrictions**: Confined to project directory
4. **Command blocklist**: curl, wget blocked by default
5. **Enterprise policy enforcement**: Managed settings override all others
6. **Prompt injection safeguards**: Context-aware detection, isolated WebFetch

### Permission modes control approval behavior

| Mode | Behavior |
|------|----------|
| `default` | Prompts for permission on first use |
| `plan` | Analyze and plan, cannot execute |
| `acceptEdits` | Auto-approves file edits |
| `bypassPermissions` | Skips all prompts (DANGEROUS) |

### Permission rules use allow/ask/deny with pattern matching

```json
{
  "permissions": {
    "allow": ["Bash(npm run lint)", "Bash(npm run test:*)"],
    "ask": ["Bash(git push:*)"],
    "deny": ["WebFetch", "Bash(curl:*)", "Read(./.env)", "Read(./secrets/**)"]
  }
}
```

**Critical**: Bash patterns use **prefix matching, NOT regex**. `Bash(npm run test:*)` matches commands starting with `npm run test`. File patterns use **gitignore syntax**.

### Sandbox configuration schema

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["git", "docker"],
    "allowUnsandboxedCommands": false,
    "network": {
      "allowUnixSockets": ["~/.ssh/agent-socket"],
      "allowLocalBinding": true
    }
  }
}
```

---

## Settings hierarchy determines configuration precedence

### File locations from highest to lowest priority

1. **Enterprise managed**: `/Library/Application Support/ClaudeCode/managed-settings.json` (macOS)
2. **CLI flags**: Session-specific overrides
3. **Local project**: `.claude/settings.local.json` (gitignored)
4. **Shared project**: `.claude/settings.json` (version-controlled)
5. **User global**: `~/.claude/settings.json`

### Key environment variables across categories

**Authentication**:
- `ANTHROPIC_API_KEY` - Direct API access
- `CLAUDE_CODE_USE_BEDROCK=1` - Enable AWS Bedrock
- `CLAUDE_CODE_USE_VERTEX=1` - Enable Google Vertex AI
- `CLAUDE_CODE_USE_FOUNDRY=1` - Enable Microsoft Foundry

**Model configuration**:
- `ANTHROPIC_MODEL` - Override default model
- `CLAUDE_CODE_SUBAGENT_MODEL` - Model for subagents

**Network**:
- `HTTPS_PROXY` - HTTPS proxy server
- `NODE_EXTRA_CA_CERTS` - Custom CA certificates

**mTLS**:
- `CLAUDE_CODE_CLIENT_CERT` - Client certificate path
- `CLAUDE_CODE_CLIENT_KEY` - Client private key path

**Feature flags**:
- `DISABLE_TELEMETRY=1` - Disable analytics
- `DISABLE_AUTOUPDATER=1` - Disable auto-updates
- `MAX_THINKING_TOKENS` - Extended thinking budget

---

## SDK interfaces provide programmatic control

### TypeScript SDK: `@anthropic-ai/claude-agent-sdk`

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Find and fix bugs in auth.py",
  options: {
    model: "opus",
    allowedTools: ["Read", "Edit", "Bash"],
    permissionMode: "acceptEdits",
    maxTurns: 10,
    outputFormat: { type: "json_schema", schema: mySchema }
  }
})) {
  if (message.type === "result") {
    console.log("Cost: $", message.total_cost_usd);
  }
}
```

### Python SDK: `claude-agent-sdk`

```python
from claude_agent_sdk import query, ClaudeAgentOptions

options = ClaudeAgentOptions(
    system_prompt="You are an expert Python developer",
    permission_mode='acceptEdits',
    allowed_tools=["Read", "Edit", "Bash"],
    max_turns=10
)

async for message in query(prompt="Create a web server", options=options):
    print(message)
```

### Output formats for different use cases

| Format | Use Case |
|--------|----------|
| `text` | Human-readable, interactive use |
| `json` | Scripting, automation, structured parsing |
| `stream-json` | Real-time processing, large responses |

---

## CLI reference covers 40+ flags

### Essential flags for automation

| Flag | Description |
|------|-------------|
| `-p, --print` | Non-interactive print mode |
| `-c, --continue` | Continue most recent conversation |
| `-r, --resume <id>` | Resume specific session |
| `--output-format` | Output format (text, json, stream-json) |
| `--allowedTools` | Tools allowed without prompting |
| `--disallowedTools` | Tools to block |
| `--permission-mode` | Permission mode |
| `--model` | Set model |
| `--max-turns` | Limit agentic turns |
| `--append-system-prompt` | Append to default prompt |
| `--mcp-config` | Load MCP servers from JSON |
| `--json-schema` | JSON Schema for structured output |
| `--dangerously-skip-permissions` | Skip all prompts (use carefully) |

### System prompt flag comparison

| Flag | Behavior |
|------|----------|
| `--system-prompt` | **Replaces** entire default prompt |
| `--append-system-prompt` | **Appends** to default prompt |

---

## Context management optimizes token efficiency

### CLAUDE.md hierarchy loads context automatically

```
Enterprise: /Library/Application Support/ClaudeCode/CLAUDE.md  (highest)
Project:    ./.claude/CLAUDE.md or ./CLAUDE.md
User:       ~/.claude/CLAUDE.md
Local:      ./CLAUDE.local.md (gitignored, lowest)
```

### Context windows by plan

| Configuration | Window Size |
|---------------|-------------|
| Standard (paid) | 200K tokens |
| Enterprise | 500K tokens |
| API direct | Up to 1M tokens |

### Compaction strategies

**Automatic**: Triggers at ~75-95% utilization
**Manual**: `/compact [instructions]` with optional focus

```bash
/compact only keep the names of websites reviewed
/compact preserve the coding patterns established
```

### Checkpointing system enables safe rollback

Captures code state **before each edit**. Access via `/rewind` or `Esc + Esc`. Rewind options: conversation only, code only, or both.

---

## CI/CD automation integrates with GitHub Actions

### Official action: `anthropics/claude-code-action@v1`

```yaml
name: Claude Code Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: "/review"
          claude_args: "--max-turns 5"
```

### Headless scripting with session persistence

```bash
# Capture session ID for multi-turn
session_id=$(claude -p "Start review" --output-format json | jq -r '.session_id')

# Continue in subsequent steps
claude -p --resume "$session_id" "Check security issues"
claude -p --resume "$session_id" "Generate summary"
```

### Output parsing for validation

```bash
result=$(claude -p "Check for bugs" --output-format json)
bugs=$(echo $result | jq '.result')
cost=$(echo $result | jq '.total_cost_usd')

# Conditional logic
if claude -p "Does code have security issues? Answer YES or NO" | grep -q "YES"; then
    exit 1
fi
```

---

## Enterprise deployment requires managed configuration

### Authentication methods by provider

| Provider | Configuration |
|----------|---------------|
| **Anthropic API** | `ANTHROPIC_API_KEY` |
| **AWS Bedrock** | `CLAUDE_CODE_USE_BEDROCK=1` + AWS credentials |
| **Google Vertex AI** | `CLAUDE_CODE_USE_VERTEX=1` + GCP credentials |
| **Microsoft Foundry** | `CLAUDE_CODE_USE_FOUNDRY=1` + Azure credentials |

### Managed settings locations by platform

| Platform | Path |
|----------|------|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux/WSL | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

### Enterprise security configuration

```json
{
  "permissions": {
    "deny": ["Bash(rm -rf *)", "Bash(*sudo*)", "Write(.env*)"],
    "allow": ["Read(*)", "Bash(npm test)", "Bash(git *)"],
    "disableBypassPermissionsMode": "disable"
  },
  "allowedMcpServers": [{ "serverName": "github" }],
  "deniedMcpServers": [{ "serverName": "filesystem" }]
}
```

### Network configuration for corporate environments

```bash
# Proxy configuration
export HTTPS_PROXY='https://proxy.corp.com:8080'

# LLM gateway
export ANTHROPIC_BEDROCK_BASE_URL='https://gateway.corp.com/bedrock'
export CLAUDE_CODE_SKIP_BEDROCK_AUTH=1

# mTLS
export CLAUDE_CODE_CLIENT_CERT=/path/to/cert.pem
export CLAUDE_CODE_CLIENT_KEY=/path/to/key.pem
```

---

## Best practices and anti-patterns

### Token optimization strategies

- **Use progressive disclosure**: Keep SKILL.md under 500 lines
- **Execute scripts, don't read them**: Only output consumes tokens
- **Limit subagent spawning**: ~20K overhead per invocation
- **Compact at logical breakpoints**: Don't wait for auto-compact
- **Disable unused MCP servers**: Reduces context consumption

### Security best practices

- **Start restrictive**: Begin with minimal permissions, expand as needed
- **Use deny rules first**: Block sensitive files before allowing operations
- **Prefer WebFetch over Bash curl**: URL filtering is more controllable
- **Enable sandboxing**: Run `/sandbox` to activate OS-level protection
- **Deploy managed settings**: Enterprise policies cannot be overridden

### Anti-patterns to avoid

- ❌ **Token explosion**: Spawning 50 Tasks to read 3 files
- ❌ **Nested agent attempts**: Designing workflows requiring multi-level delegation
- ❌ **Context starvation**: Not providing enough context in subagent prompts
- ❌ **Unquoted variables in hooks**: Use `"$VAR"` not `$VAR`
- ❌ **Vague skill descriptions**: "Helps with files" won't trigger correctly
- ❌ **Broad bash patterns**: Understand prefix matching limitations

---

## Conclusion

The Claude Code ecosystem provides **unprecedented extensibility** through its hooks, skills, and MCP systems while maintaining **enterprise-grade security** via its six-layer protection model. The key insight for maximum utilization: treat Claude Code not as a simple assistant but as an **orchestration platform** where the main session coordinates specialized subagents, external tools, and automated workflows.

For individual developers, focus on **CLAUDE.md configuration**, **custom slash commands**, and **strategic compaction**. For teams, invest in **shared skills**, **project-level settings**, and **MCP integrations** checked into source control. For CI/CD, leverage the **GitHub Action**, **headless scripting with JSON output**, and **session persistence** for multi-turn automation.

The subagent constraint (no nested spawning) and token overhead (~20K per subagent) mean orchestration should remain at **one level of delegation** with the main session as conductor. Progressive disclosure in skills achieves 98% token reduction when capabilities are available but inactive—bundle comprehensive resources freely.
