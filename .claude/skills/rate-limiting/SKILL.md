---
name: rate-limiting
description: >
  Rate limiting with Upstash Ratelimit — middleware integration, per-route limits, sliding window, Server Action protection
allowed-tools: Read, Grep, Glob
---

# Rate Limiting

## Purpose
Rate limiting patterns for Next.js 15 with Upstash Ratelimit. Covers middleware-level rate
limiting, per-route configuration, sliding window algorithms, and Server Action protection.
The ONE skill for abuse prevention.

## When to Use
- Adding rate limiting to API routes or Server Actions
- Protecting auth endpoints from brute force
- Implementing per-user or per-IP request quotas
- Setting up sliding window or fixed window limits

## When NOT to Use
- Middleware without rate limiting → `nextjs-middleware`
- General security hardening → `security`
- API route design → `api-routes`

## Pattern

### Upstash Ratelimit setup
```tsx
// src/lib/rate-limit.ts
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

// Sliding window: 10 requests per 10 seconds
export const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, "10 s"),
  analytics: true,
  prefix: "@upstash/ratelimit",
});

// Stricter limit for auth endpoints
export const authRatelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(5, "60 s"),
  analytics: true,
  prefix: "@upstash/ratelimit:auth",
});
```

### Middleware-level rate limiting
```tsx
// src/middleware.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { ratelimit, authRatelimit } from "@/lib/rate-limit";

export async function middleware(request: NextRequest) {
  const ip = (request.headers.get("x-forwarded-for") ?? "127.0.0.1").split(",")[0].trim();

  // Stricter rate limit for auth routes
  if (request.nextUrl.pathname.startsWith("/api/auth")) {
    const { success, limit, remaining } = await authRatelimit.limit(ip);
    if (!success) {
      return NextResponse.json(
        { error: "Too many requests" },
        {
          status: 429,
          headers: {
            "X-RateLimit-Limit": limit.toString(),
            "X-RateLimit-Remaining": remaining.toString(),
          },
        }
      );
    }
  }

  // General rate limit for API routes
  if (request.nextUrl.pathname.startsWith("/api")) {
    const { success } = await ratelimit.limit(ip);
    if (!success) {
      return NextResponse.json({ error: "Too many requests" }, { status: 429 });
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/api/:path*"],
};
```

### Server Action rate limiting
```tsx
// src/actions/createPost.ts
"use server";
import { auth } from "@/lib/auth";
import { ratelimit } from "@/lib/rate-limit";
import { headers } from "next/headers";

export async function createPost(prevState: ActionState, formData: FormData) {
  const session = await auth();
  if (!session) return { error: { _form: ["Unauthorized"] } };

  // Rate limit by user ID (authenticated) or IP (fallback)
  const identifier = session.user.id;
  const { success } = await ratelimit.limit(identifier);
  if (!success) {
    return { error: { _form: ["Too many requests. Please try again later."] } };
  }

  // ... rest of action logic
}
```

### User-tier aware limits (free vs pro)
```tsx
// src/lib/rate-limit.ts
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

export const rateLimits = {
  api: new Ratelimit({ redis, limiter: Ratelimit.slidingWindow(60, "60 s") }),
  auth: new Ratelimit({ redis, limiter: Ratelimit.slidingWindow(5, "60 s") }),
  upload: new Ratelimit({ redis, limiter: Ratelimit.slidingWindow(10, "60 s") }),
  webhook: new Ratelimit({ redis, limiter: Ratelimit.fixedWindow(100, "60 s") }),
  // Tier-aware limits
  free: new Ratelimit({ redis, limiter: Ratelimit.slidingWindow(20, "60 s") }),
  pro: new Ratelimit({ redis, limiter: Ratelimit.slidingWindow(100, "60 s") }),
} as const;

export function getRateLimiter(plan: "FREE" | "PRO") {
  return plan === "PRO" ? rateLimits.pro : rateLimits.free;
}
```

### Rate limit response headers (full set)
```tsx
// Include all standard rate limit headers in 429 responses
const { success, limit, remaining, reset } = await ratelimit.limit(identifier);
if (!success) {
  return NextResponse.json(
    { error: "Too many requests. Please try again later." },
    {
      status: 429,
      headers: {
        "X-RateLimit-Limit": limit.toString(),
        "X-RateLimit-Remaining": remaining.toString(),
        "X-RateLimit-Reset": reset.toString(), // Unix timestamp when limit resets
        "Retry-After": Math.ceil((reset - Date.now()) / 1000).toString(),
      },
    }
  );
}
```

## Anti-pattern

```tsx
// WRONG: rate limiting in individual route handlers (fragile, easy to miss)
export async function POST(req: Request) {
  // This gets duplicated in every route and is easy to forget
  const count = await redis.incr(`rate:${ip}`);
  if (count > 10) return new Response("Too many", { status: 429 });
}

// CORRECT: centralized in middleware or shared utility
// See middleware pattern above — applied once, covers all matching routes

// WRONG: no graceful degradation message
return new Response("", { status: 429 }); // Empty body — client gets no info
// Always include a message and Retry-After header so clients know when to retry
```

## Common Mistakes
- Rate limiting in individual handlers — centralize in middleware
- Using only IP-based limiting — use user ID for authenticated requests
- No rate limit on auth endpoints — auth is the #1 brute force target
- Missing `X-RateLimit-*` headers — clients need to know their quota
- Using fixed window only — sliding window prevents burst-then-wait abuse
- Not rate limiting Server Actions — they're API endpoints too
- No graceful degradation message — empty 429 bodies confuse API consumers
- Same limits for all user tiers — pro users should get higher quotas
- Trusting full x-forwarded-for string — split and take first IP

## Checklist
- [ ] Auth endpoints have stricter rate limits (5/min)
- [ ] API routes have general rate limits (60/min)
- [ ] Server Actions with mutations are rate limited
- [ ] Rate limit uses user ID (authenticated) or IP (anonymous)
- [ ] 429 responses include `X-RateLimit-*` and `Retry-After` headers
- [ ] `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN` in `.env.local`
- [ ] User-tier aware limits configured (free vs pro)
- [ ] 429 response body includes human-readable error message

## Composes With
- `nextjs-middleware` — rate limiting runs in middleware
- `security` — rate limiting is a core security measure
- `api-routes` — protect route handlers from abuse
- `logging` — log rate limit events for monitoring
