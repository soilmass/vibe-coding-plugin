---
name: caching
description: >
  Next.js 15 caching layers — Request Memoization, Data Cache, Full Route Cache, Router Cache, revalidation strategies, unstable_cache for Prisma
allowed-tools: Read, Grep, Glob
---

# Caching

## Purpose
Next.js 15 cache architecture and revalidation strategies. Covers the four cache layers,
explicit cache control, and tag-based revalidation. The ONE skill for cache decisions.

## When to Use
- Deciding whether to cache fetch requests
- Configuring revalidation (time-based or on-demand)
- Understanding why stale data appears
- Caching Prisma queries with `unstable_cache`

## When NOT to Use
- Data fetching patterns → `nextjs-data`
- Server-side rendering strategy → `react-server-components`
- CDN/edge deployment caching → `deploy`

## Pattern

### Explicit fetch caching (NOT cached by default in Next.js 15)
```tsx
// Cached with revalidation
const data = await fetch("https://api.example.com/data", {
  next: { revalidate: 3600, tags: ["products"] },
});

// Force cache (static)
const staticData = await fetch("https://api.example.com/static", {
  cache: "force-cache",
});

// Never cache (dynamic)
const liveData = await fetch("https://api.example.com/live", {
  cache: "no-store",
});
```

### Tag-based revalidation in Server Actions
```tsx
"use server";
import { revalidateTag } from "next/cache";

export async function updateProduct() {
  await db.product.update({ /* ... */ });
  revalidateTag("products"); // Precise invalidation
}
```

### Caching Prisma queries with unstable_cache
```tsx
import { unstable_cache } from "next/cache";
import { db } from "@/lib/db";

const getProducts = unstable_cache(
  async () => db.product.findMany(),
  ["products"],
  { revalidate: 3600, tags: ["products"] }
);
```

### Request Memoization with React.cache
```tsx
import { cache } from "react";
import { db } from "@/lib/db";

export const getUser = cache(async (id: string) => {
  return db.user.findUnique({ where: { id } });
});
```

### revalidateTag() for granular invalidation
```tsx
// Fetch with tags for precise invalidation
const posts = await fetch("/api/posts", {
  next: { tags: ["posts", `user-${userId}-posts`] },
});

// Invalidate only this user's posts, not all posts
import { revalidateTag } from "next/cache";
revalidateTag(`user-${userId}-posts`);
```

### ISR with revalidate segment config
```tsx
// app/blog/[slug]/page.tsx
export const revalidate = 3600; // Revalidate at most every hour

// Pre-generate known slugs at build time
export async function generateStaticParams() {
  const posts = await db.post.findMany({ select: { slug: true } });
  return posts.map((post) => ({ slug: post.slug }));
}
```

### Cache hierarchy (edge → server → database)
```
Request → Edge Cache (CDN, fastest)
       → Server Cache (unstable_cache / fetch cache)
       → Database (slowest, always fresh)

Use tags to invalidate at the right layer:
- revalidateTag() clears server cache
- CDN cache respects Cache-Control headers
```

### revalidateTag vs revalidatePath decision matrix

| Scenario | Use | Why |
|----------|-----|-----|
| Single resource updated | `revalidateTag("post-123")` | Only invalidates caches tagged with this ID |
| Category/list changed | `revalidateTag("posts")` | All fetch calls tagged "posts" refetch |
| Layout/shared data changed | `revalidatePath("/dashboard")` | Invalidates all data for that route segment |
| Nuclear option | `revalidatePath("/", "layout")` | Invalidates everything — avoid |

## Anti-pattern

```tsx
// WRONG: assuming fetch is cached by default (Next.js 14 behavior)
const data = await fetch("https://api.example.com/data");
// In Next.js 15, this is equivalent to cache: "no-store"
// Data re-fetched on EVERY request — no caching!

// WRONG: cache stampede — many requests hit origin when cache expires
// If 1000 users request the same data when cache expires, all 1000
// hit the database simultaneously.
// Use stale-while-revalidate or background revalidation to avoid this.

// WRONG: revalidatePath("/") to invalidate everything
revalidatePath("/"); // Nuclear option — clears all cached data
// Use revalidateTag("specific-tag") for surgical invalidation
```

Next.js 15 changed the default: `fetch()` is NOT cached. You must explicitly
opt in with `cache: "force-cache"` or `next: { revalidate: N }`.

## Common Mistakes
- Assuming fetch is cached by default — it's NOT in Next.js 15
- Using `revalidatePath("/")` when `revalidateTag("tag")` is more precise
- Not adding `tags` to fetches — makes on-demand revalidation impossible
- Forgetting `React.cache()` for Prisma calls used in multiple components
- Setting revalidation too low — causes unnecessary server load
- Cache stampede — all requests hit origin simultaneously when cache expires

## Checklist
- [ ] Every `fetch()` has explicit cache strategy
- [ ] Cacheable data uses `tags` for on-demand revalidation
- [ ] Prisma queries wrapped in `unstable_cache` where appropriate
- [ ] `React.cache()` used for request-level deduplication
- [ ] Server Actions call `revalidateTag`/`revalidatePath` after mutations
- [ ] `revalidateTag()` preferred over `revalidatePath()` for precision
- [ ] Static pages use `generateStaticParams` + `revalidate` segment config

## Composes With
- `nextjs-data` — caching is applied to data fetching patterns
- `react-server-actions` — actions trigger revalidation
- `prisma` — Prisma queries need `unstable_cache` wrapper
- `performance` — cache strategies directly impact load times
