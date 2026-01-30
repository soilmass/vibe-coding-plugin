---
name: react-suspense
description: >
  React 19 Suspense — use() hook, Suspense boundaries, streaming SSR, loading.tsx conventions, error boundaries, skeleton patterns
allowed-tools: Read, Grep, Glob
---

# React Suspense

## Purpose
React 19 Suspense patterns for streaming and loading states. Covers the `use()` hook,
Suspense boundaries, and `loading.tsx` conventions. The ONE skill for async UI boundaries.

## When to Use
- Adding loading states to async Server Components
- Streaming slow data without blocking the page
- Using the `use()` hook to unwrap promises in client components
- Implementing skeleton loading patterns

## When NOT to Use
- Error states → `error-handling`
- Data fetching logic → `nextjs-data`
- Form pending states → `react-forms` (useFormStatus)

## Pattern

### Suspense boundary with async component
```tsx
import { Suspense } from "react";

export default function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<CardSkeleton />}>
        <RevenueChart />
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <RecentOrders />
      </Suspense>
    </div>
  );
}

async function RevenueChart() {
  const data = await getRevenue(); // Streams when ready
  return <Chart data={data} />;
}
```

### loading.tsx (automatic Suspense boundary)
```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return (
    <div className="animate-pulse space-y-4">
      <div className="h-8 w-48 rounded bg-muted" />
      <div className="h-64 rounded bg-muted" />
    </div>
  );
}
```

### use() hook for promises in Client Components
```tsx
"use client";

import { use } from "react";

function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise); // Suspends until resolved
  return <div>{user.name}</div>;
}

// Parent passes the promise
export default async function Page() {
  const userPromise = getUser(); // Don't await — pass promise!
  return (
    <Suspense fallback={<Skeleton />}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

### Nested Suspense for progressive loading
```tsx
export default function Page() {
  return (
    <Suspense fallback={<PageSkeleton />}>
      <Header />
      <Suspense fallback={<ContentSkeleton />}>
        <MainContent />
        <Suspense fallback={<SidebarSkeleton />}>
          <Sidebar />
        </Suspense>
      </Suspense>
    </Suspense>
  );
}
```

## Anti-pattern

```tsx
// WRONG: awaiting then passing data instead of passing promise
export default async function Page() {
  const user = await getUser();     // Blocks entire page!
  const posts = await getPosts();   // Sequential waterfall!

  return (
    <div>
      <UserCard user={user} />
      <PostList posts={posts} />
    </div>
  );
}
```

Pass promises to Suspense-wrapped components instead of awaiting at the top.
This enables streaming — each section loads independently.

## Common Mistakes
- Awaiting everything at page level — blocks streaming
- Missing Suspense boundary around async components — no loading state
- Using `loading.tsx` AND explicit Suspense — double loading UI
- Not providing meaningful skeletons — users see blank screens
- Forgetting that `use()` must be in a Suspense boundary

## Checklist
- [ ] Each slow async component wrapped in its own Suspense boundary
- [ ] `loading.tsx` exists for route-level loading states
- [ ] Skeletons match the shape of the loaded content
- [ ] `use()` hook called inside Suspense boundaries
- [ ] Independent data fetches stream in parallel, not sequentially

## Composes With
- `nextjs-data` — data fetching creates the promises Suspense manages
- `error-handling` — error boundaries catch failures after Suspense
- `nextjs-routing` — loading.tsx is a route file convention
