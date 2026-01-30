---
name: nextjs-data
description: >
  Next.js 15 data fetching — Server Component async, React.cache deduplication, parallel fetches, no default caching, streaming with Suspense
allowed-tools: Read, Grep, Glob
---

# Next.js Data Fetching

## Purpose
Data fetching patterns for Next.js 15 Server Components. Covers async components, request
deduplication, parallel fetching, and streaming. The ONE skill for getting data to components.

## When to Use
- Fetching data in Server Components
- Deduplicating requests across component tree
- Parallelizing independent data fetches
- Streaming data with Suspense boundaries

## When NOT to Use
- Cache configuration → `caching`
- Form submissions and mutations → `react-server-actions`
- Client-side data (SWR/React Query) → `react-client-components`

## Pattern

### Async Server Component
```tsx
export default async function ProductPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const product = await getProduct(id);
  return <div>{product.name}</div>;
}
```

### Parallel independent fetches
```tsx
export default async function Dashboard() {
  const [user, posts, analytics] = await Promise.all([
    getUser(),
    getPosts(),
    getAnalytics(),
  ]);
  return (
    <div>
      <UserCard user={user} />
      <PostList posts={posts} />
      <Analytics data={analytics} />
    </div>
  );
}
```

### Request deduplication with React.cache
```tsx
import { cache } from "react";
import { db } from "@/lib/db";

export const getUser = cache(async (id: string) => {
  return db.user.findUnique({ where: { id } });
});

// Called in layout AND page — only ONE database query executes
```

### React.cache for fetch deduplication
```tsx
import { cache } from "react";

// Wrap fetch functions — called in layout AND page, only ONE request executes
export const getProduct = cache(async (id: string) => {
  const res = await fetch(`https://api.example.com/products/${id}`, {
    next: { tags: [`product-${id}`] },
  });
  if (!res.ok) throw new Error("Failed to fetch product");
  return res.json() as Promise<Product>;
});
```

### Streaming with Suspense
```tsx
import { Suspense } from "react";

export default function Page() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<Skeleton />}>
        <SlowComponent />
      </Suspense>
    </div>
  );
}

async function SlowComponent() {
  const data = await getSlowData(); // Streams when ready
  return <div>{data.value}</div>;
}
```

## Anti-pattern

```tsx
// WRONG: fetching data in useEffect (client-side waterfall)
"use client";
function ProductPage({ id }: { id: string }) {
  const [product, setProduct] = useState(null);
  useEffect(() => {
    fetch(`/api/products/${id}`)
      .then(r => r.json())
      .then(setProduct);
  }, [id]);
  // Waterfall: render → mount → fetch → render again
}
```

Fetch in Server Components. No loading spinners, no waterfalls, no client-side
state management for server data.

## Common Mistakes
- Using `useEffect` for data fetching — causes client-side waterfalls
- Sequential fetches when they could be parallel — use `Promise.all()`
- Not using `React.cache()` — same query runs multiple times per request
- Forgetting Suspense boundaries — entire page blocks on slowest fetch
- Not awaiting params before using them in queries

## Checklist
- [ ] Data fetched in Server Components, not useEffect
- [ ] Independent fetches parallelized with `Promise.all()`
- [ ] `React.cache()` wraps shared data functions
- [ ] Suspense boundaries around slow-loading sections
- [ ] No `fetch()` without explicit cache strategy

## Composes With
- `caching` — caching strategy applied to data fetches
- `react-server-components` — Server Components are where data fetching happens
- `react-suspense` — Suspense enables streaming for slow data
- `performance` — data fetching patterns directly impact load times
- `logging` — track fetch duration and failures
- `error-handling` — handle fetch failures with error boundaries
