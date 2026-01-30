---
name: nextjs-middleware
description: >
  Next.js 15 Middleware — route matchers, redirects, rewrites, auth guards, headers, Edge Runtime constraints, cookies
allowed-tools: Read, Grep, Glob
---

# Next.js Middleware

## Purpose
Next.js 15 middleware for request interception. Covers matchers, redirects, rewrites,
auth guards, and Edge Runtime constraints. The ONE skill for pre-route-resolution logic.

## When to Use
- Redirecting unauthenticated users to login
- Adding headers to responses (CORS, security)
- A/B testing with URL rewrites
- Geolocation-based routing

## When NOT to Use
- Data fetching → `nextjs-data`
- API endpoint logic → `api-routes`
- Authentication configuration → `auth`

## Pattern

### Basic middleware with matcher
```tsx
// src/middleware.ts (must be at src/ root, not in app/)
import { NextRequest, NextResponse } from "next/server";

export function middleware(request: NextRequest) {
  // Add custom header
  const response = NextResponse.next();
  response.headers.set("x-pathname", request.nextUrl.pathname);
  return response;
}

export const config = {
  matcher: [
    // Match all routes except static files and API auth
    "/((?!_next/static|_next/image|favicon.ico|api/auth).*)",
  ],
};
```

### Auth guard middleware
```tsx
import { auth } from "@/lib/auth";

export default auth((req) => {
  const isLoggedIn = !!req.auth;
  const isOnDashboard = req.nextUrl.pathname.startsWith("/dashboard");

  if (isOnDashboard && !isLoggedIn) {
    return Response.redirect(new URL("/login", req.url));
  }
});
```

### Redirect and rewrite
```tsx
export function middleware(request: NextRequest) {
  // Redirect
  if (request.nextUrl.pathname === "/old-page") {
    return NextResponse.redirect(new URL("/new-page", request.url));
  }

  // Rewrite (URL stays the same, content changes)
  if (request.nextUrl.pathname === "/beta") {
    return NextResponse.rewrite(new URL("/beta-feature", request.url));
  }
}
```

## Anti-pattern

```tsx
// WRONG: heavy computation in middleware (runs on Edge Runtime)
import { db } from "@/lib/db"; // Prisma doesn't work on Edge!

export async function middleware(request: NextRequest) {
  const user = await db.user.findUnique({ ... }); // FAILS on Edge
}
```

Middleware runs on Edge Runtime with limited APIs. No Node.js-specific modules,
no Prisma, no file system access. Keep middleware lightweight.

## Common Mistakes
- Placing middleware in wrong location — must be `src/middleware.ts`
- Using Node.js APIs — middleware runs on Edge Runtime
- Importing Prisma or heavy libraries — not available on Edge
- Not setting matcher — middleware runs on ALL routes including static files
- Forgetting to return `NextResponse.next()` — blocks the request

## Checklist
- [ ] Middleware file at `src/middleware.ts` (not in app/)
- [ ] Matcher excludes static files and assets
- [ ] No Node.js-specific imports (Prisma, fs, etc.)
- [ ] Returns `NextResponse.next()` for pass-through
- [ ] Auth redirects use `Response.redirect()` with full URL

## Composes With
- `auth` — Auth.js provides the middleware auth wrapper
- `security` — middleware adds security headers
- `nextjs-routing` — middleware runs before route resolution
- `i18n` — locale detection and routing in middleware
