---
name: security
description: >
  Next.js 15 application security — CSP headers, server-only imports, env validation with Zod, CSRF protection, input sanitization, rate limiting
allowed-tools: Read, Grep, Glob
---

# Security

## Purpose
Application security hardening for Next.js 15. Covers CSP headers, server-only boundaries,
environment validation, and input sanitization. The ONE skill for defense-in-depth patterns.

## When to Use
- Adding Content Security Policy headers
- Protecting server-only code from client bundles
- Validating environment variables at startup
- Implementing rate limiting on API routes

## When NOT to Use
- Authentication/authorization setup → `auth`
- Form input validation → `react-forms`
- Server Action input validation → `react-server-actions`

## Pattern

### server-only guard
```tsx
// lib/db.ts
import "server-only"; // Throws build error if imported in client component
import { PrismaClient } from "@prisma/client";

export const db = new PrismaClient();
```

### Environment validation with Zod
```tsx
// lib/env.ts
import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  AUTH_SECRET: z.string().min(32),
  NEXT_PUBLIC_APP_URL: z.string().url(),
});

export const env = envSchema.parse(process.env);
```

### CSP headers via next.config.ts
```tsx
// next.config.ts
const config = {
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          {
            key: "Content-Security-Policy",
            // DEVELOPMENT ONLY — 'unsafe-inline' and 'unsafe-eval' disable CSP protection
            // For production, use nonce-based CSP via middleware (see below)
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
              "style-src 'self' 'unsafe-inline'",
              "img-src 'self' data: https:",
            ].join("; "),
          },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
        ],
      },
    ];
  },
};
export default config;
```

### Server Action authorization check
```tsx
"use server";
import { auth } from "@/lib/auth";

export async function deletePost(id: string) {
  const session = await auth();
  if (!session?.user) throw new Error("Unauthorized");

  const post = await db.post.findUnique({ where: { id } });
  if (post?.authorId !== session.user.id) throw new Error("Forbidden");

  await db.post.delete({ where: { id } });
}
```

### CORS configuration for API routes
```tsx
// src/lib/cors.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const ALLOWED_ORIGINS = [
  process.env.NEXT_PUBLIC_APP_URL,
  "https://your-other-domain.com",
].filter(Boolean);

export function corsHeaders(request: NextRequest) {
  const origin = request.headers.get("origin") ?? "";
  const isAllowed = ALLOWED_ORIGINS.includes(origin);

  return {
    "Access-Control-Allow-Origin": isAllowed ? origin : "",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Max-Age": "86400",
  };
}
```

### CSP middleware pattern (dynamic nonces)
```tsx
// src/middleware.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const csp = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    `style-src 'self' 'nonce-${nonce}'`,
    `img-src 'self' data: https:`,
    `font-src 'self'`,
    `frame-ancestors 'none'`,
    `base-uri 'self'`,
    `form-action 'self'`,
  ].join("; ");

  const response = NextResponse.next();
  response.headers.set("Content-Security-Policy", csp);
  response.headers.set("x-nonce", nonce);
  return response;
}
```

### server-only import guard (import in any sensitive module)
```tsx
// Any server-only module — fails at build time if bundled for client
import "server-only";
```

### Dependency vulnerability scanning checklist
```bash
# Run periodically and in CI
npm audit                        # Check for known vulnerabilities
npm audit --fix                  # Auto-fix compatible updates
npx npm-check-updates -u         # Check for major updates
```

## Anti-pattern

```tsx
// WRONG: trusting client-side validation alone
"use client";
function CreatePost() {
  const handleSubmit = (data: FormData) => {
    if (data.get("title")?.toString().length > 100) return; // Client-only check
    createPost(data); // Server Action with NO server-side validation!
  };
}

// WRONG: wildcard CORS (allows any origin to call your API)
headers: { "Access-Control-Allow-Origin": "*" }
// Use explicit allowed origins instead

// WRONG: CSRF vulnerability — no origin check on Server Actions
// Server Actions in Next.js 15 have built-in CSRF protection via
// the __next_action header, but custom API routes do NOT.
// Always verify Origin header on custom POST endpoints.
```

Client-side validation is UX. Server-side validation is security.
Always validate on the server — client checks can be bypassed.

## Common Mistakes
- Missing `import "server-only"` on sensitive modules (db, auth helpers)
- No env validation — crashes at runtime instead of startup
- Forgetting CSP headers — allows XSS vectors
- Trusting client-side validation without server-side checks
- Exposing error stack traces in production error responses
- Wildcard CORS (`*`) on authenticated endpoints — use explicit origins
- No CSRF protection on custom API POST routes — verify Origin header
- Not running `npm audit` in CI — known vulnerabilities go undetected

## Checklist
- [ ] `import "server-only"` on all sensitive server modules
- [ ] Environment variables validated with Zod schema at startup
- [ ] CSP and security headers configured in `next.config.ts` or middleware
- [ ] All Server Actions check authentication and authorization
- [ ] Error responses never leak stack traces or internal details
- [ ] CORS configured with explicit allowed origins (no wildcard on auth routes)
- [ ] CSP does NOT use unsafe-inline/unsafe-eval in production
- [ ] Permissions-Policy header configured
- [ ] `npm audit` runs in CI pipeline
- [ ] Dependencies reviewed for known vulnerabilities periodically

## Composes With
- `auth` — authentication provides identity, security enforces authorization
- `error-handling` — error boundaries must not leak sensitive info
- `api-routes` — route handlers need auth checks and rate limiting
- `rate-limiting` — rate limiting is DDoS defense at the application layer
- `logging` — audit trails and security event logging
