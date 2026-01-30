#!/usr/bin/env python3
"""Pre-Bash Validation Hook

Auto-allows safe commands, blocks dangerous ones.
"""

import json
import os
import re
import sys

# Commands that are always safe (auto-allow)
SAFE_PATTERNS = [
    r'^npm run\b',
    r'^npm test\b',
    r'^npx next\b',
    r'^npx tsc\b',
    r'^npx prisma generate\b',
    r'^npx prisma migrate dev\b',
    r'^npx prisma format\b',
    r'^npx prisma studio\b',
    r'^npx prisma db push\b',
    r'^npx shadcn@latest\b',
    r'^npx shadcn\b',
    r'^npx vitest\b',
    r'^npx playwright\b',
    r'^npx prettier\b',
    r'^npx turbo\b',
    r'^npx create-next-app\b',
    r'^npx tsx\b',
    r'^npx next lint\b',
    r'^npm run seed\b',
    r'^npm outdated\b',
    r'^npm ls\b',
    r'^npx next info\b',
    r'^npx playwright install\b',
    r'^node\b',
    r'^git status\b',
    r'^git log\b',
    r'^git diff\b',
    r'^git branch\b',
    r'^git show\b',
    r'^git stash list\b',
    r'^git stash pop\b',
    r'^git stash apply\b',
    r'^git push --force-with-lease\b',
    r'^git remote -v\b',
    r'^ls\b',
    r'^pwd\b',
    r'^which\b',
    r'^echo\b',
    r'^cat\b',
    r'^head\b',
    r'^tail\b',
    r'^wc\b',
    r'^tree\b',
]

# Commands that should be blocked
BLOCKED_PATTERNS = [
    (r'\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\b', "Blocked: recursive force deletion"),
    (r'\bsudo\b', "Blocked: sudo commands not allowed"),
    (r'\bnpm publish\b', "Blocked: publishing packages not allowed"),
    (r'\bcurl\b.*\|\s*(ba)?sh', "Blocked: piping curl to shell"),
    (r'\bwget\b.*\|\s*(ba)?sh', "Blocked: piping wget to shell"),
    (r'\bchmod\s+777\b', "Blocked: setting world-writable permissions"),
    (r'\bgit\s+push\s+.*--force\b', "Blocked: force push — use --force-with-lease instead"),
    (r'\bgit\s+push\s+.*-f\b', "Blocked: force push — use --force-with-lease instead"),
    (r'\bgit\s+reset\s+--hard\b', "Blocked: hard reset — this destroys uncommitted work"),
    (r'\bgit\s+clean\s+-f', "Blocked: git clean — this permanently deletes untracked files"),
    (r'\bnpx\s+prisma\s+migrate\s+reset\b', "Blocked: prisma migrate reset — this drops and recreates the database"),
    (r'\bnpx\s+prisma\s+migrate\s+resolve\b', "Blocked: prisma migrate resolve — dangerous in production, can corrupt migration history"),
    (r'\bnpx\s+prisma\s+db\s+drop\b', "Blocked: prisma db drop — this drops the database"),
    (r'\bdd\s+if=', "Blocked: dd can destroy disk data"),
    (r'\bmkfs\b', "Blocked: filesystem format command"),
]

# Commands that should trigger a warning but not block
WARNING_PATTERNS = [
    (r'\bgit\s+commit\b.*--amend\b', "Warning: git commit --amend rewrites history — risky if already pushed"),
    (r'\bnpx\s+prisma\s+migrate\s+dev\b(?!.*--name)', "Warning: prisma migrate dev without --name — unnamed migrations are confusing"),
    (r'\bnpm\s+update\b', "Warning: npm update can change many packages at once — review changes before bulk updating"),
    (r'\brm\s+-rf\s+\.next\b', "Warning: rm -rf .next — deleting build cache. Run `npm run build` to regenerate."),
]


def main():
    try:
        hook_input = json.loads(sys.stdin.read())
        data = hook_input.get("tool_input", {})
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    command = data.get("command", "").strip()
    if not command:
        sys.exit(0)

    # Check blocked patterns first
    for pattern, message in BLOCKED_PATTERNS:
        if re.search(pattern, command):
            print(message, file=sys.stderr)
            sys.exit(2)

    # Check warning patterns (allow but warn)
    for pattern, message in WARNING_PATTERNS:
        if re.search(pattern, command):
            print(message, file=sys.stderr)

    # Check if command matches safe patterns
    for pattern in SAFE_PATTERNS:
        if re.search(pattern, command):
            sys.exit(0)

    # For unmatched commands, allow but don't auto-approve
    # (Claude Code's permission system will prompt the user)
    sys.exit(0)


if __name__ == "__main__":
    main()
