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

### Parallel data fetching with Suspense

Kick off independent fetches simultaneously, then wrap each consumer in its own
Suspense boundary. This streams results as they resolve instead of waiting for
the slowest query.

```tsx
import { Suspense } from "react";

// Start ALL fetches at the top — no awaits yet
export default function Dashboard() {
  const revenuePromise = getRevenue();
  const ordersPromise = getRecentOrders();
  const metricsPromise = getMetrics();

  return (
    <div className="grid grid-cols-12 gap-6">
      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart dataPromise={revenuePromise} />
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <RecentOrders dataPromise={ordersPromise} />
      </Suspense>
      <Suspense fallback={<MetricsSkeleton />}>
        <MetricsPanel dataPromise={metricsPromise} />
      </Suspense>
    </div>
  );
}

// Each component awaits only its own data
async function RevenueChart({ dataPromise }: { dataPromise: Promise<Revenue> }) {
  const data = await dataPromise;
  return <Chart data={data} />;
}

async function RecentOrders({ dataPromise }: { dataPromise: Promise<Order[]> }) {
  const orders = await dataPromise;
  return <OrderTable rows={orders} />;
}

async function MetricsPanel({ dataPromise }: { dataPromise: Promise<Metrics> }) {
  const metrics = await dataPromise;
  return <KpiCards metrics={metrics} />;
}
```

When two fetches depend on each other, group them with `Promise.all()` inside a
single async component so they share one Suspense boundary:

```tsx
async function UserActivity({ userId }: { userId: string }) {
  const [profile, activity] = await Promise.all([
    getProfile(userId),
    getActivity(userId),
  ]);

  return (
    <Card>
      <UserHeader profile={profile} />
      <ActivityFeed items={activity} />
    </Card>
  );
}
```

### loading.tsx vs Suspense boundary

`loading.tsx` is syntactic sugar — Next.js wraps the route segment's `page.tsx`
in a `<Suspense>` with `loading.tsx` as the fallback. Understanding the nesting
rules helps you decide which to use.

**When to use `loading.tsx`:**
- Route-level loading state (covers the entire page content area)
- Simple pages with one main async operation
- When the layout should remain interactive while the page streams

**When to use explicit `<Suspense>`:**
- Multiple independent async sections that should stream separately
- Granular control over which parts show skeletons
- Nested loading states within a single page

**Nesting behavior:** `loading.tsx` only wraps the `page.tsx` of the same route
segment. Layouts are NOT covered — they render immediately. Nested route
segments each get their own `loading.tsx`.

```
app/
├── layout.tsx            ← Renders immediately (no Suspense)
├── loading.tsx           ← Wraps page.tsx below
├── page.tsx              ← Suspended by loading.tsx
└── settings/
    ├── loading.tsx       ← Wraps settings/page.tsx only
    └── page.tsx          ← Suspended by settings/loading.tsx
```

Combining both — use `loading.tsx` for the page shell, then explicit Suspense
boundaries for sections within the page:

```tsx
// app/dashboard/loading.tsx — shows while page.tsx streams
export default function Loading() {
  return <DashboardShell />;
}

// app/dashboard/page.tsx — page-level Suspense handled by loading.tsx,
// but inner sections get their own boundaries
export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <RecentOrders />
      </Suspense>
    </div>
  );
}
```

### Skeleton component pattern

Build reusable skeleton primitives with Tailwind `animate-pulse`, then compose
them to match the shape of real content. This avoids layout shift when data
arrives.

```tsx
// components/ui/skeleton.tsx
function Skeleton({ className }: { className?: string }) {
  return (
    <div className={cn("animate-pulse rounded-md bg-muted", className)} />
  );
}

export { Skeleton };
```

Compose skeletons to mirror actual component layouts:

```tsx
// components/skeletons/card-skeleton.tsx
import { Skeleton } from "@/components/ui/skeleton";

function CardSkeleton() {
  return (
    <div className="rounded-xl border bg-card p-6 shadow-sm">
      <Skeleton className="mb-4 h-5 w-32" />
      <Skeleton className="mb-2 h-4 w-full" />
      <Skeleton className="mb-2 h-4 w-3/4" />
      <Skeleton className="h-4 w-1/2" />
    </div>
  );
}

function TableSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className="rounded-xl border bg-card shadow-sm">
      {/* Header */}
      <div className="flex gap-4 border-b p-4">
        <Skeleton className="h-4 w-24" />
        <Skeleton className="h-4 w-32" />
        <Skeleton className="h-4 w-20" />
        <Skeleton className="h-4 w-28" />
      </div>
      {/* Rows */}
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex gap-4 border-b p-4 last:border-0">
          <Skeleton className="h-4 w-24" />
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-4 w-20" />
          <Skeleton className="h-4 w-28" />
        </div>
      ))}
    </div>
  );
}

function ChartSkeleton() {
  return (
    <div className="rounded-xl border bg-card p-6 shadow-sm">
      <Skeleton className="mb-6 h-5 w-40" />
      <div className="flex items-end gap-2">
        {Array.from({ length: 12 }).map((_, i) => (
          <Skeleton
            key={i}
            className="w-full"
            style={{ height: `${Math.random() * 120 + 40}px` }}
          />
        ))}
      </div>
    </div>
  );
}

export { CardSkeleton, TableSkeleton, ChartSkeleton };
```

Key rules for skeletons:
- Match the **exact dimensions** of the real content to prevent layout shift
- Use `rounded-md` / `rounded-xl` to match the component's border radius
- Keep the same padding, gaps, and grid structure as the loaded state
- Prefer fixed `h-*` and `w-*` over percentage widths for predictable sizing

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

### Premium Skeleton & Loading Patterns

#### Gradient shimmer skeleton
```tsx
// Enhanced skeleton with sliding gradient instead of basic pulse
function ShimmerSkeleton({ className }: { className?: string }) {
  return (
    <div className={cn("relative overflow-hidden rounded-md bg-muted", className)}>
      <div className="absolute inset-0 -translate-x-full animate-[shimmer_1.5s_infinite] bg-gradient-to-r from-transparent via-white/10 to-transparent" />
    </div>
  );
}
```

```css
/* globals.css */
@keyframes shimmer {
  to { transform: translateX(100%); }
}
```

#### Staggered skeleton with depth
```tsx
// Skeleton rows appear with stagger + decreasing opacity for depth
function StaggeredTableSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className="rounded-xl border bg-card shadow-sm">
      <div className="flex gap-4 border-b p-4">
        {[24, 32, 20, 28].map((w, i) => (
          <ShimmerSkeleton key={i} className={`h-4 w-${w}`} />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, i) => (
        <div
          key={i}
          className="flex gap-4 border-b p-4 last:border-0"
          style={{ opacity: 1 - i * 0.1 }} // Fade out further rows
        >
          {[24, 32, 20, 28].map((w, j) => (
            <ShimmerSkeleton key={j} className={`h-4 w-${w}`} />
          ))}
        </div>
      ))}
    </div>
  );
}
```

#### Skeleton-to-content crossfade
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { Suspense, useState, useEffect } from "react";

// Wraps Suspense children with fade animation when content resolves
export function SmoothSuspense({
  fallback,
  children,
}: {
  fallback: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <Suspense
      fallback={
        <motion.div exit={{ opacity: 0 }} transition={{ duration: 0.15 }}>
          {fallback}
        </motion.div>
      }
    >
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.2 }}
      >
        {children}
      </motion.div>
    </Suspense>
  );
}
```

#### Dashboard skeleton with visual hierarchy
```tsx
// loading.tsx — matches dashboard layout structure
export default function DashboardLoading() {
  return (
    <div className="space-y-6">
      {/* Page title */}
      <ShimmerSkeleton className="h-8 w-48" />

      {/* KPI cards row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="rounded-xl border bg-card p-6">
            <ShimmerSkeleton className="mb-3 h-3 w-20" />
            <ShimmerSkeleton className="h-7 w-24" />
          </div>
        ))}
      </div>

      {/* Chart + table row */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-7">
        <div className="rounded-xl border bg-card p-6 lg:col-span-4">
          <ShimmerSkeleton className="mb-6 h-5 w-32" />
          <div className="flex items-end gap-2">
            {Array.from({ length: 12 }).map((_, i) => (
              <ShimmerSkeleton
                key={i}
                className="w-full"
                style={{ height: `${40 + Math.sin(i) * 40 + 40}px` }}
              />
            ))}
          </div>
        </div>
        <div className="lg:col-span-3">
          <StaggeredTableSkeleton rows={5} />
        </div>
      </div>
    </div>
  );
}
```

## Composes With
- `nextjs-data` — data fetching creates the promises Suspense manages
- `error-handling` — error boundaries catch failures after Suspense
- `nextjs-routing` — loading.tsx is a route file convention
- `performance` — skeleton-to-content crossfade for perceived speed
- `animation` — shimmer effects, staggered reveals
- `loading-transitions` — route-level transition overlays complement Suspense
