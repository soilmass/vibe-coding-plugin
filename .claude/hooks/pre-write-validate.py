#!/usr/bin/env python3
"""Pre-Write/Edit Validation Hook

Validates file writes before they happen:
1. Blocks "use client" on files that should be server components (layouts)
2. Scans for hardcoded secrets
3. Warns about unnecessary client components
"""

import json
import os
import re
import sys


def get_tool_input():
    """Read tool input from stdin (Claude Code passes hook input as JSON via stdin)."""
    try:
        hook_input = json.loads(sys.stdin.read())
        return hook_input.get("tool_input", {})
    except (json.JSONDecodeError, EOFError):
        return {}


def check_client_directive_on_layout(file_path: str, content: str) -> list[str]:
    """Check if 'use client' is being added to a layout file."""
    warnings = []
    basename = os.path.basename(file_path)

    if basename in ("layout.tsx", "layout.ts", "layout.jsx", "layout.js"):
        if '"use client"' in content or "'use client'" in content:
            warnings.append(
                f"BLOCKED: Adding 'use client' to {file_path}. "
                "Layouts should be Server Components. Extract interactive parts "
                "into a separate Client Component."
            )
    return warnings


def check_hardcoded_secrets(content: str) -> list[str]:
    """Scan for hardcoded secrets using regex patterns."""
    warnings = []
    patterns = [
        (r'sk-[a-zA-Z0-9]{20,}', "OpenAI/Stripe secret key"),
        (r'sk-ant-api03-[a-zA-Z0-9_-]+', "Anthropic API key"),
        (r'AKIA[0-9A-Z]{16}', "AWS Access Key ID"),
        (r'ghp_[a-zA-Z0-9]{36}', "GitHub Personal Access Token"),
        (r'gho_[a-zA-Z0-9]{36}', "GitHub OAuth Token"),
        (r'xoxb-[0-9a-zA-Z-]+', "Slack Bot Token"),
        (r'xoxp-[0-9a-zA-Z-]+', "Slack User Token"),
        (r'-----BEGIN (RSA |EC )?PRIVATE KEY-----', "Private Key"),
        (r'postgres(?:ql)?://[^:]+:[^@]+@', "Database connection string with password"),
        (r'eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+', "JWT token"),
        (r'(api_key|apiKey|API_KEY)\s*[:=]\s*["\'][^"\']+["\']', "Hardcoded API key"),
        (r'AIza[0-9A-Za-z_-]{35}', "Firebase API key"),
        (r'vercel_[a-zA-Z0-9_]{20,}', "Vercel token"),
        (r'sb-[a-zA-Z0-9_-]{20,}', "Supabase key"),
    ]

    for pattern, description in patterns:
        if re.search(pattern, content):
            warnings.append(
                f"BLOCKED: Hardcoded {description} detected. "
                "Use environment variables instead."
            )

    return warnings


def check_deprecated_patterns(file_path: str, content: str) -> list[str]:
    """Check for deprecated React/Next.js patterns."""
    warnings = []

    # Block useFormState (deprecated, must use useActionState)
    if re.search(r'\buseFormState\b', content):
        warnings.append(
            f"BLOCKED: useFormState is deprecated in {file_path}. "
            "Use useActionState from 'react' instead."
        )

    # Warn if forwardRef is used (React 19 ref-as-prop)
    if re.search(r'\bforwardRef\b', content):
        warnings.append(
            f"WARNING: forwardRef detected in {file_path}. "
            "React 19 supports ref as a regular prop — remove forwardRef wrapper."
        )

    # Block Pages Router patterns
    if re.search(r'\b(getServerSideProps|getStaticProps)\b', content):
        warnings.append(
            f"BLOCKED: Pages Router pattern detected in {file_path}. "
            "Use App Router data fetching (Server Components) instead of "
            "getServerSideProps/getStaticProps."
        )

    # Block redirect() inside try-catch (throws NEXT_REDIRECT, not a real error)
    if re.search(r'try\s*\{[^}]*\bredirect\s*\(', content, re.DOTALL):
        warnings.append(
            f"BLOCKED: redirect() used inside try-catch in {file_path}. "
            "redirect() throws NEXT_REDIRECT which gets caught. "
            "Call redirect() outside try-catch or in a finally block."
        )

    # Warn on cookies() or headers() called without await in Next.js 15
    if re.search(r'(?<!await\s)\b(cookies|headers)\s*\(\s*\)', content):
        if not re.search(r'await\s+(cookies|headers)\s*\(\s*\)', content):
            warnings.append(
                f"WARNING: cookies() or headers() may not be awaited in {file_path}. "
                "In Next.js 15, cookies() and headers() return Promises — await them."
            )

    # Warn if params destructured without await in page/layout files
    basename = os.path.basename(file_path)
    if basename in ("page.tsx", "page.ts", "layout.tsx", "layout.ts"):
        # Match destructuring params without await: { params }: { params: { ... } }
        # but not: { params }: { params: Promise<...> }
        if re.search(r'params\s*:\s*\{', content) and not re.search(r'params\s*:\s*Promise\s*<', content):
            if re.search(r'\bparams\b', content) and not re.search(r'await\s+params\b', content):
                warnings.append(
                    f"WARNING: params may not be awaited in {file_path}. "
                    "In Next.js 15, params is a Promise — type it as Promise<...> and await it."
                )

    return warnings


def check_async_client_components(file_path: str, content: str) -> list[str]:
    """Block async functions in 'use client' files."""
    warnings = []
    if '"use client"' not in content and "'use client'" not in content:
        return warnings

    if re.search(r'\basync\s+function\b', content) or re.search(r'\basync\s*\(', content):
        warnings.append(
            f"BLOCKED: Async function in 'use client' file {file_path}. "
            "Only Server Components can be async. Remove async or remove 'use client'."
        )
    return warnings


def check_server_only_in_client(file_path: str, content: str) -> list[str]:
    """Warn on server-only imports in client components."""
    warnings = []
    if '"use client"' not in content and "'use client'" not in content:
        return warnings

    server_only_patterns = [
        (r'from\s+["\']server-only["\']', "server-only module"),
        (r'from\s+["\']@/lib/db["\']', "database client (db)"),
        (r'from\s+["\']@/lib/auth["\']', "auth module (server-only)"),
    ]
    for pattern, description in server_only_patterns:
        if re.search(pattern, content):
            warnings.append(
                f"WARNING: Importing {description} in 'use client' file {file_path}. "
                "This import is server-only and will fail in the browser."
            )
    return warnings


def check_missing_use_server(file_path: str, content: str) -> list[str]:
    """Warn if file in src/actions/ lacks 'use server' directive."""
    warnings = []
    if "/actions/" not in file_path:
        return warnings
    if not file_path.endswith((".ts", ".tsx")):
        return warnings

    if '"use server"' not in content and "'use server'" not in content:
        warnings.append(
            f"WARNING: File in actions/ directory without 'use server' directive: {file_path}. "
            "Server Action files must have \"use server\" at the top."
        )
    return warnings


def check_img_and_link_patterns(file_path: str, content: str) -> list[str]:
    """Check for <img> instead of next/image, missing alt, console.log, and <a> for internal links."""
    warnings = []

    # Only check tsx/jsx files
    if not file_path.endswith((".tsx", ".jsx")):
        return warnings

    # Warn on <img> tag instead of next/image
    if re.search(r'<img\s', content):
        warnings.append(
            f"WARNING: <img> tag detected in {file_path}. "
            "Use next/image (<Image>) for automatic optimization, lazy loading, and srcset."
        )

    # Warn on <Image without alt= prop
    if re.search(r'<Image\b', content) and not re.search(r'<Image\b[^>]*\balt\s*=', content, re.DOTALL):
        warnings.append(
            f"WARNING: <Image> without alt prop in {file_path}. "
            "All images must have alt text for accessibility."
        )

    # Warn on <a href="/..."> for internal links (should use next/link)
    if re.search(r'<a\s[^>]*href\s*=\s*["\']/', content):
        warnings.append(
            f"WARNING: <a href=\"/...\"> detected in {file_path}. "
            "Use next/link (<Link>) for internal navigation to enable client-side transitions."
        )

    return warnings


def check_console_log(file_path: str, content: str) -> list[str]:
    """Warn on console.log in non-test production code. Block in Server Actions."""
    warnings = []

    # Skip test files
    if any(p in file_path for p in [".test.", ".spec.", "__tests__", "e2e/"]):
        return warnings

    if re.search(r'\bconsole\.log\(', content):
        # Elevate to BLOCKED for Server Actions (actions directory)
        if "/actions/" in file_path:
            warnings.append(
                f"BLOCKED: console.log() detected in Server Action {file_path}. "
                "Server Actions must use structured logger (import from @/lib/logger). "
                "console.log has no structure, levels, or correlation."
            )
        else:
            warnings.append(
                f"WARNING: console.log() detected in {file_path}. "
                "Remove console.log before committing — use a proper logger for production."
            )

    return warnings


def check_useeffect_data_fetching(file_path: str, content: str) -> list[str]:
    """Warn on useEffect containing fetch or await (data fetching anti-pattern)."""
    warnings = []
    if re.search(r'useEffect\s*\([^)]*\b(fetch\s*\(|await\s)', content, re.DOTALL):
        warnings.append(
            f"WARNING: useEffect appears to fetch data in {file_path}. "
            "Data fetching in useEffect causes client-side waterfalls. "
            "Fetch data in Server Components instead."
        )
    return warnings


def check_default_export_non_page(file_path: str, content: str) -> list[str]:
    """Warn if non-page/layout files use default exports."""
    warnings = []
    basename = os.path.basename(file_path)
    # Allow default exports in page, layout, loading, error, not-found, global-error, template, route files
    allowed_defaults = (
        "page.tsx", "page.ts", "page.jsx", "page.js",
        "layout.tsx", "layout.ts", "layout.jsx", "layout.js",
        "loading.tsx", "loading.ts", "error.tsx", "error.ts",
        "not-found.tsx", "not-found.ts", "global-error.tsx", "global-error.ts",
        "template.tsx", "template.ts", "route.tsx", "route.ts",
        "default.tsx", "default.ts",
    )
    if basename in allowed_defaults:
        return warnings

    # Only check component files (not configs, utils, etc.)
    if "/components/" not in file_path and "/hooks/" not in file_path:
        return warnings

    if re.search(r'^export\s+default\b', content, re.MULTILINE):
        warnings.append(
            f"WARNING: Default export in non-page file {file_path}. "
            "Components should use named exports for better refactoring and tree-shaking."
        )
    return warnings


def check_unnecessary_client(file_path: str, content: str) -> list[str]:
    """Warn if a file is marked as client but doesn't need to be."""
    warnings = []

    if '"use client"' not in content and "'use client'" not in content:
        return warnings

    # Check if the file actually uses client-side features
    client_indicators = [
        r'\buseState\b',
        r'\buseEffect\b',
        r'\buseRef\b',
        r'\buseReducer\b',
        r'\buseCallback\b',
        r'\buseMemo\b',
        r'\buseContext\b',
        r'\buseActionState\b',
        r'\buseFormStatus\b',
        r'\buseOptimistic\b',
        r'\bonClick\b',
        r'\bonChange\b',
        r'\bonSubmit\b',
        r'\bonKeyDown\b',
        r'\bonFocus\b',
        r'\bonBlur\b',
        r'\bwindow\b',
        r'\bdocument\b',
        r'\blocalStorage\b',
        r'\bsessionStorage\b',
        r'\bnavigator\b',
        r'\bcreateContext\b',
    ]

    has_client_feature = any(re.search(p, content) for p in client_indicators)

    if not has_client_feature:
        warnings.append(
            f"WARNING: {file_path} is marked 'use client' but doesn't appear to use "
            "any client-side features (hooks, event handlers, browser APIs). "
            "Consider removing 'use client' to keep it as a Server Component."
        )

    return warnings


def check_env_local_files(file_path: str) -> list[str]:
    """Block writes to .env.*.local files."""
    warnings = []
    BLOCKED_FILES = {'.env.local', '.env.development.local', '.env.test.local', '.env.production.local'}
    if os.path.basename(file_path) in BLOCKED_FILES:
        warnings.append(
            "BLOCKED: Cannot write to .env.local files — add secrets manually"
        )
    return warnings


def main():
    tool_input = get_tool_input()
    file_path = tool_input.get("file_path", "")
    content = tool_input.get("content", "") or tool_input.get("new_string", "")
    old_string = tool_input.get("old_string", "")

    if not file_path:
        sys.exit(0)

    # Block .env.local files before any other checks
    env_warnings = check_env_local_files(file_path)
    if env_warnings:
        for w in env_warnings:
            print(w, file=sys.stderr)
        sys.exit(2)

    if not content and not old_string:
        sys.exit(0)

    # Only check TypeScript/JavaScript files
    if not file_path.endswith((".ts", ".tsx", ".js", ".jsx")):
        sys.exit(0)

    all_warnings = []

    all_warnings.extend(check_client_directive_on_layout(file_path, content))
    all_warnings.extend(check_hardcoded_secrets(content))
    if old_string:
        all_warnings.extend(check_hardcoded_secrets(old_string))
    all_warnings.extend(check_deprecated_patterns(file_path, content))
    all_warnings.extend(check_async_client_components(file_path, content))
    all_warnings.extend(check_server_only_in_client(file_path, content))
    all_warnings.extend(check_missing_use_server(file_path, content))
    all_warnings.extend(check_img_and_link_patterns(file_path, content))
    all_warnings.extend(check_console_log(file_path, content))
    all_warnings.extend(check_useeffect_data_fetching(file_path, content))
    all_warnings.extend(check_default_export_non_page(file_path, content))
    all_warnings.extend(check_unnecessary_client(file_path, content))

    blocked = [w for w in all_warnings if w.startswith("BLOCKED")]
    warnings = [w for w in all_warnings if w.startswith("WARNING")]

    if blocked:
        # Output as system message and exit with error to block the write
        for b in blocked:
            print(b, file=sys.stderr)
        sys.exit(2)

    if warnings:
        # Output warnings but allow the write
        for w in warnings:
            print(w, file=sys.stderr)

    sys.exit(0)


if __name__ == "__main__":
    main()
