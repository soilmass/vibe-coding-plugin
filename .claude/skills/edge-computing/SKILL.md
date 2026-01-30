---
name: edge-computing
description: >
  Vercel Edge Functions, Edge Config, Upstash KV, geo-based personalization, Edge Runtime patterns
allowed-tools: Read, Grep, Glob
---

# Edge Computing

## Purpose
Edge computing patterns for Next.js 15 using Vercel Edge Functions, Edge Config,
and Upstash Redis. Covers geo-based personalization, edge-compatible auth, streaming
responses, and Edge vs Node.js runtime decisions.

## When to Use
- Route handlers that need global low-latency (`runtime = "edge"`)
- Zero-latency config reads with Vercel Edge Config
- Geo-based content personalization in middleware
- Edge-compatible KV storage with Upstash Redis
- A/B testing at the edge without origin requests

## When NOT to Use
- Database queries with Prisma → Node.js runtime (Prisma needs Node.js drivers)
- File system access → Node.js runtime
- Heavy computation → Node.js serverless functions
- Server Actions (always Node.js) → `react-server-actions`

## Pattern

### Edge Runtime route handler
```tsx
// src/app/api/geo/route.ts
export const runtime = "edge";

export async function GET(request: Request) {
  // Vercel provides geo data on the request
  const country = request.headers.get("x-vercel-ip-country") ?? "US";
  const city = request.headers.get("x-vercel-ip-city") ?? "Unknown";

  return Response.json({ country, city });
}
```

### Vercel Edge Config
```tsx
// src/lib/edge-config.ts
import { createClient } from "@vercel/edge-config";

export const edgeConfig = createClient(process.env.EDGE_CONFIG);

// Read config (< 1ms at the edge)
export async function getRedirects() {
  return edgeConfig.get<Record<string, string>>("redirects");
}
```

### Upstash Redis at the edge
```tsx
// src/lib/redis.ts
import { Redis } from "@upstash/redis";

export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

// Works in Edge Runtime (uses HTTP, not TCP)
export async function getCachedValue<T>(key: string): Promise<T | null> {
  return redis.get<T>(key);
}
```

### Geo-based personalization in middleware
```tsx
// src/middleware.ts
import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const country = request.geo?.country ?? "US";
  const response = NextResponse.next();

  // Set header for Server Components to read
  response.headers.set("x-user-country", country);

  // Redirect to localized version
  if (country === "DE" && !request.nextUrl.pathname.startsWith("/de")) {
    return NextResponse.redirect(new URL(`/de${request.nextUrl.pathname}`, request.url));
  }

  return response;
}
```

### Edge-compatible JWT verification
```tsx
// src/lib/edge-auth.ts
// Can't use Node.js crypto at the edge — use Web Crypto API
export async function verifyJWT(token: string, secret: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const [headerB64, payloadB64, signatureB64] = token.split(".");

  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"]
  );

  const signature = Uint8Array.from(atob(signatureB64.replace(/-/g, "+").replace(/_/g, "/")), (c) => c.charCodeAt(0));
  const data = encoder.encode(`${headerB64}.${payloadB64}`);

  return crypto.subtle.verify("HMAC", key, signature, data);
}
```

### Streaming response from edge
```tsx
// src/app/api/stream/route.ts
export const runtime = "edge";

export async function GET() {
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      for (const chunk of ["Hello", " ", "from", " ", "the", " ", "edge"]) {
        controller.enqueue(encoder.encode(chunk));
        await new Promise((r) => setTimeout(r, 100));
      }
      controller.close();
    },
  });

  return new Response(stream, {
    headers: { "content-type": "text/plain" },
  });
}
```

### When to use Edge vs Node.js
```
Edge Runtime:                    Node.js Runtime:
✓ Global low-latency            ✓ Prisma / database queries
✓ Simple redirects/rewrites     ✓ File system access
✓ Geo personalization           ✓ Heavy computation
✓ A/B testing                   ✓ Server Actions
✓ Auth token verification       ✓ npm packages requiring Node APIs
✓ KV reads (Upstash)            ✓ Background jobs (Inngest)
✗ 1MB bundle size limit         ✓ No bundle size limit
✗ No Node.js APIs               ✓ Full Node.js API access
```

### Edge Runtime limitations
```
NOT available in Edge Runtime:
✗ fs (file system)              — no reading/writing files
✗ Prisma Client                 — requires Node.js TCP drivers
✗ child_process                 — no spawning subprocesses
✗ crypto (Node.js module)       — use Web Crypto API instead
✗ dns, net, tls                 — no TCP/UDP networking
✗ Stream (Node.js)              — use Web Streams API instead
✗ Buffer (limited)              — use Uint8Array
✗ 30s execution timeout         — keep handlers fast
✗ 1MB bundle size limit         — minimize dependencies
✗ node_modules with native addons (bcrypt, sharp, etc.)
```

## Anti-pattern

### Using Edge Runtime with Prisma
Prisma Client requires Node.js TCP drivers. Edge Functions can't use Prisma directly.
Use Prisma in Node.js serverless functions and cache results in Upstash for edge reads.

### Large bundles in Edge Functions
Edge Functions have a 1MB size limit. Keep dependencies minimal. Don't import heavy
libraries — use lightweight alternatives designed for the edge.

### Blocking edge with long computation
Edge Functions should respond quickly. Offload heavy work to Node.js serverless
functions or background jobs. The edge is for routing decisions and fast reads.

## Common Mistakes
- Importing Node.js-only packages in edge routes — causes build errors
- Not testing edge routes locally — `next dev` emulates edge differently
- Assuming `request.geo` is always available — only on Vercel, not locally
- Using `process.env` in edge without `NEXT_PUBLIC_` prefix for client reads
- Forgetting Edge Config connection string in `EDGE_CONFIG` env var

## Checklist
- [ ] Edge routes use `export const runtime = "edge"`
- [ ] Edge Config connected for zero-latency reads
- [ ] Upstash Redis used for edge-compatible KV
- [ ] Geo-based personalization in middleware
- [ ] No Prisma imports in edge routes
- [ ] Bundle size under 1MB for edge functions
- [ ] Fallback for missing geo data (local dev)

## Composes With
- `nextjs-middleware` — edge middleware patterns
- `feature-flags` — Edge Config for instant flag reads
- `caching` — Upstash Redis as edge cache layer
- `deploy` — Vercel Edge Function deployment
- `rate-limiting` — Upstash rate limiter at the edge
