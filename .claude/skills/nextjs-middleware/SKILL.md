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

### Chained middleware pattern

Compose multiple concerns (auth, i18n, rate-limiting) in a single `middleware.ts`.
Each handler returns a `NextResponse` or `null`. The first non-null response wins;
if all handlers pass, fall through to `NextResponse.next()`.

```tsx
// src/middleware.ts
import { NextRequest, NextResponse } from "next/server";

type MiddlewareHandler = (
  request: NextRequest
) => NextResponse | Response | null | Promise<NextResponse | Response | null>;

// --- Individual handlers ---

async function withAuth(request: NextRequest): Promise<NextResponse | null> {
  const token = request.cookies.get("session-token")?.value;

  const protectedPaths = ["/dashboard", "/settings", "/account"];
  const isProtected = protectedPaths.some((p) =>
    request.nextUrl.pathname.startsWith(p)
  );

  if (isProtected && !token) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("callbackUrl", request.nextUrl.pathname);
    return NextResponse.redirect(loginUrl);
  }

  return null; // pass to next handler
}

function withLocale(request: NextRequest): NextResponse | null {
  const pathname = request.nextUrl.pathname;
  const supportedLocales = ["en", "fr", "de", "ja"];
  const defaultLocale = "en";

  // Skip if path already has a locale prefix
  const hasLocale = supportedLocales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  );
  if (hasLocale) return null;

  // Detect locale from Accept-Language header
  const acceptLang = request.headers.get("accept-language") ?? "";
  const preferred = acceptLang
    .split(",")
    .map((l) => l.split(";")[0].trim().substring(0, 2))
    .find((code) => supportedLocales.includes(code));

  const locale = preferred ?? defaultLocale;

  // Rewrite to locale-prefixed path (URL stays clean)
  return NextResponse.rewrite(
    new URL(`/${locale}${pathname}`, request.url)
  );
}

function withRateLimit(request: NextRequest): NextResponse | null {
  // Edge-compatible rate limiting via headers (backed by upstream service)
  const clientIp = request.headers.get("x-forwarded-for") ?? "unknown";
  const rateKey = `rate:${clientIp}:${request.nextUrl.pathname}`;

  // Set a header so the downstream API route or edge function
  // can enforce rate limits (middleware itself is stateless on Edge)
  const response = NextResponse.next();
  response.headers.set("x-rate-key", rateKey);
  response.headers.set("x-client-ip", clientIp);

  return null; // don't short-circuit; let other handlers run
}

// --- Compose handlers ---

const handlers: MiddlewareHandler[] = [withAuth, withRateLimit, withLocale];

export async function middleware(request: NextRequest) {
  for (const handler of handlers) {
    const result = await handler(request);
    if (result) return result; // early return on redirect/rewrite
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/auth).*)"],
};
```

Key points for chained middleware:
- Order matters: auth first (reject early), then rate-limiting, then locale.
- Each handler returns `null` to pass or a `NextResponse` to short-circuit.
- Keep handlers pure functions — no shared mutable state.
- The entire chain still runs in a single Edge invocation.

### Geolocation-based routing

`NextRequest` exposes a `geo` property on platforms that support it (Vercel Edge).
Use it for country-based redirects, regional content, or compliance gates.

```tsx
// src/middleware.ts
import { NextRequest, NextResponse } from "next/server";

export function middleware(request: NextRequest) {
  const country = request.geo?.country ?? "US"; // fallback for local dev
  const pathname = request.nextUrl.pathname;

  // 1. Redirect EU visitors to GDPR-compliant version
  const euCountries = [
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE",
  ];

  if (
    euCountries.includes(country) &&
    pathname.startsWith("/pricing") &&
    !pathname.startsWith("/pricing/eu")
  ) {
    return NextResponse.redirect(
      new URL(`/pricing/eu${pathname.replace("/pricing", "")}`, request.url)
    );
  }

  // 2. Rewrite for country-specific content (URL stays the same)
  if (pathname === "/promotions") {
    return NextResponse.rewrite(
      new URL(`/promotions/${country.toLowerCase()}`, request.url)
    );
  }

  // 3. Set geo headers for downstream Server Components
  const response = NextResponse.next();
  response.headers.set("x-user-country", country);
  response.headers.set("x-user-city", request.geo?.city ?? "unknown");
  response.headers.set("x-user-region", request.geo?.region ?? "unknown");
  return response;
}

export const config = {
  matcher: ["/pricing/:path*", "/promotions"],
};
```

Reading geo headers in a Server Component:

```tsx
// src/app/promotions/page.tsx
import { headers } from "next/headers";

export default async function PromotionsPage() {
  const headersList = await headers();
  const country = headersList.get("x-user-country") ?? "US";
  const city = headersList.get("x-user-city") ?? "unknown";

  return (
    <section>
      <h1>Deals near {city}</h1>
      {/* render country-specific promotions */}
    </section>
  );
}
```

Notes on geolocation:
- `request.geo` is `undefined` in local dev — always provide a fallback.
- On Vercel, geo data is populated automatically. Self-hosted setups need
  a reverse proxy (nginx, Cloudflare) to inject geo headers.
- Use rewrites (not redirects) when the URL should stay the same.
- Narrow the `matcher` to only routes that need geo logic.

### Edge Runtime error handling

Middleware must never throw unhandled errors — a crash returns a 500 to every
matched route. Wrap logic in try/catch and always fall through to `NextResponse.next()`.

```tsx
// src/middleware.ts
import { NextRequest, NextResponse } from "next/server";

export async function middleware(request: NextRequest) {
  try {
    // Example: validate a JWT from an external auth service
    const token = request.cookies.get("auth-token")?.value;

    if (token) {
      const isValid = await verifyTokenAtEdge(token);
      if (!isValid) {
        // Clear invalid cookie and redirect to login
        const response = NextResponse.redirect(
          new URL("/login", request.url)
        );
        response.cookies.delete("auth-token");
        return response;
      }
    }

    return NextResponse.next();
  } catch (error: unknown) {
    // Log context for debugging — console.error works on Edge Runtime
    console.error("[middleware] Unhandled error:", {
      pathname: request.nextUrl.pathname,
      message: error instanceof Error ? error.message : "unknown",
    });

    // ALWAYS fall through — never let middleware crash the request
    return NextResponse.next();
  }
}

// Edge-compatible token verification (no Node.js crypto)
async function verifyTokenAtEdge(token: string): Promise<boolean> {
  try {
    const res = await fetch("https://auth.example.com/verify", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token }),
      signal: AbortSignal.timeout(3000), // 3s timeout
    });
    return res.ok;
  } catch {
    // Network failure or timeout — fail open to avoid blocking all users
    return true;
  }
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
```

Error handling principles for middleware:
- **Fail open vs. fail closed** — decide per feature. Auth checks may fail closed
  (redirect to login). Rate limits should fail open (let the request through).
- **Set timeouts on fetch calls** — `AbortSignal.timeout()` is supported on Edge.
  Without a timeout, a slow upstream can stall every request.
- **Structured logging** — log the pathname and error message. Avoid logging
  full request bodies or headers (PII risk).
- **No retry logic in middleware** — retries add latency to every matched request.
  Push retries to Server Actions or API routes instead.

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
