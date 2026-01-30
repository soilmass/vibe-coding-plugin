---
name: api-routes
description: >
  Next.js 15 App Router route handlers — GET/POST/PUT/DELETE exports, NextRequest/NextResponse, async params, CORS, streaming responses
allowed-tools: Read, Grep, Glob
---

# API Routes

## Purpose
Next.js 15 App Router route handler patterns. Covers `route.ts` exports, request/response
handling, and when to use route handlers vs Server Actions. The ONE skill for HTTP API endpoints.

## When to Use
- Creating REST API endpoints for external consumers
- Handling webhooks from third-party services
- Streaming responses (SSE, file downloads)
- Building endpoints consumed by non-React clients

## When NOT to Use
- Form submissions from React components → `react-server-actions`
- Internal data fetching → `nextjs-data` with Server Components
- Authentication callbacks → `auth`

## Pattern

### Basic route handler
```tsx
// app/api/products/route.ts
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const query = searchParams.get("q");

  const products = await db.product.findMany({
    where: query ? { name: { contains: query } } : undefined,
  });

  return NextResponse.json(products);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const product = await db.product.create({ data: body });
  return NextResponse.json(product, { status: 201 });
}
```

### Dynamic route (params is a Promise in Next.js 15)
```tsx
// app/api/products/[id]/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params; // Must await!
  const product = await db.product.findUnique({ where: { id } });

  if (!product) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  return NextResponse.json(product);
}
```

### CORS headers
```tsx
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}
```

### Cursor-based pagination
```tsx
// app/api/posts/route.ts
export async function GET(request: NextRequest) {
  const cursor = request.nextUrl.searchParams.get("cursor");
  const limit = Math.min(Number(request.nextUrl.searchParams.get("limit") ?? 20), 100);

  const posts = await db.post.findMany({
    take: limit + 1, // Fetch one extra to check if more exist
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    orderBy: { createdAt: "desc" },
  });

  const hasMore = posts.length > limit;
  const data = hasMore ? posts.slice(0, -1) : posts;

  return NextResponse.json({
    data,
    nextCursor: hasMore ? data[data.length - 1].id : null,
  });
}
```

### Idempotency key pattern
```tsx
// app/api/orders/route.ts
export async function POST(request: NextRequest) {
  const idempotencyKey = request.headers.get("Idempotency-Key");
  if (!idempotencyKey) {
    return NextResponse.json({ error: "Idempotency-Key header required" }, { status: 400 });
  }

  const existing = await db.order.findUnique({ where: { idempotencyKey } });
  if (existing) return NextResponse.json(existing); // Return cached result

  const body = await request.json();
  const order = await db.order.create({
    data: { ...body, idempotencyKey },
  });
  return NextResponse.json(order, { status: 201 });
}
```

## Anti-pattern

```tsx
// WRONG: using route handlers for form mutations in React components
// app/api/create-todo/route.ts
export async function POST(req: NextRequest) {
  const data = await req.json();
  await db.todo.create({ data });
  return NextResponse.json({ ok: true });
}

// Client component calling the route handler
// This adds unnecessary network hop — use Server Actions instead

// WRONG: offset pagination on large tables
const posts = await db.post.findMany({
  skip: page * 20, // Gets slower as page increases — O(n) skip
  take: 20,
});
// Use cursor-based pagination instead (see pattern above)
```

For React form submissions, Server Actions eliminate the API layer entirely.
Route handlers are for external consumers, webhooks, and non-React clients.

## Common Mistakes
- Forgetting to `await params` — params is a Promise in Next.js 15
- Missing CORS `OPTIONS` handler — preflight requests fail silently
- Not returning proper status codes (201 for created, 204 for no content)
- Using route handlers for React form mutations — use Server Actions
- Forgetting to validate request body with Zod
- Offset pagination on large tables — use cursor-based pagination
- No idempotency key for create operations — retries cause duplicates

## Checklist
- [ ] Params are awaited before use
- [ ] Request body validated with Zod schema
- [ ] Proper HTTP status codes returned
- [ ] CORS headers set for cross-origin endpoints
- [ ] Error responses use consistent format
- [ ] Pagination uses cursor-based approach for large datasets
- [ ] Create operations support idempotency keys

## Composes With
- `react-server-actions` — use actions for React mutations, routes for external APIs
- `security` — validate auth, rate limit, sanitize inputs
- `typescript-patterns` — type request/response shapes
- `file-uploads` — route handlers for upload endpoints and presigned URLs
- `rate-limiting` — protect API routes from abuse with rate limits
- `payments` — webhook route handlers for payment provider callbacks
- `logging` — structured logging in route handlers
- `webhooks` — webhook signature verification and event handling
