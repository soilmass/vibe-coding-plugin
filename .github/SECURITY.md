# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | Yes                |
| < latest | No                |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

### How to Report

1. Email: Send details to the repository owner via the email listed in their GitHub profile
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours of report
- **Assessment**: Within 1 week
- **Fix timeline**: Depends on severity
  - Critical: Within 24 hours
  - High: Within 1 week
  - Medium: Within 2 weeks
  - Low: Next release cycle

### Scope

This policy covers:
- The Claude Code plugin system (skills, agents, hooks)
- GitHub Actions workflows
- Configuration files that affect security (settings.json, hook scripts)

### Out of Scope

- Dependencies managed by upstream maintainers (report to them directly)
- Issues in Claude Code CLI itself (report to Anthropic)
