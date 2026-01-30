---
name: performance
description: >
  Next.js 15 + React 19 performance optimization — dynamic imports, image optimization, bundle analysis, streaming, loading skeletons
allowed-tools: Read, Grep, Glob
---

# Performance

## Purpose
Performance optimization patterns for Next.js 15 + React 19. Covers dynamic imports, image
optimization, bundle analysis, Server Component streaming, and loading skeletons. The ONE skill
for performance decisions.

## When to Use
- Optimizing bundle size (route too large)
- Adding dynamic imports for heavy components
- Implementing loading skeletons with `loading.tsx`
- Optimizing images with `next/image`
- Analyzing client/server boundary for minimal JS

## When NOT to Use
- Cache strategy decisions → `caching`
- Data fetching patterns → `nextjs-data`
- Full performance audit → use `perf-profiler` agent instead

## Pattern

### Dynamic imports for heavy client components
```tsx
import dynamic from "next/dynamic";

const Chart = dynamic(() => import("@/components/Chart"), {
  loading: () => <div className="h-64 animate-pulse bg-muted rounded" />,
  ssr: false, // Only if component uses browser APIs
});

export default function Dashboard() {
  return <Chart data={data} />;
}
```

### Streaming with Suspense boundaries
```tsx
import { Suspense } from "react";

export default function Page() {
  return (
    <div>
      <h1>Dashboard</h1>
      {/* Fast content renders immediately */}
      <StaticHeader />

      {/* Slow content streams in */}
      <Suspense fallback={<CardSkeleton />}>
        <SlowDataCard />
      </Suspense>

      {/* Independent sections stream independently */}
      <Suspense fallback={<TableSkeleton />}>
        <SlowDataTable />
      </Suspense>
    </div>
  );
}
```

### Loading skeletons with loading.tsx
```tsx
// src/app/dashboard/loading.tsx
export default function Loading() {
  return (
    <div className="space-y-4">
      <div className="h-8 w-48 animate-pulse bg-muted rounded" />
      <div className="grid grid-cols-3 gap-4">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-32 animate-pulse bg-muted rounded" />
        ))}
      </div>
    </div>
  );
}
```

### Image optimization
```tsx
import Image from "next/image";
// Remote: <Image src="..." alt="..." width={800} height={600} />
// Fill:   <Image src="..." alt="..." fill sizes="100vw" className="object-cover" />
// Above the fold: add priority prop
// Always use next/font for fonts (not external CSS links)
```

### Minimize client bundle
```tsx
// WRONG: importing heavy library in shared component
"use client";
import { format } from "date-fns"; // Entire library ships to client

// CORRECT: use in Server Component or dynamic import
// Option 1: Server Component (no client JS)
import { format } from "date-fns";
export default function DateDisplay({ date }: { date: Date }) {
  return <time>{format(date, "PPP")}</time>; // Zero client JS
}

// Option 2: pass formatted string from Server to Client Component
```

### Web Vitals monitoring
```tsx
// src/app/layout.tsx — report Web Vitals to analytics
import { SpeedInsights } from "@vercel/speed-insights/next";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        {children}
        <SpeedInsights /> {/* Tracks CLS, LCP, FID automatically */}
      </body>
    </html>
  );
}
```

### generateStaticParams for ISR/PPR
```tsx
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await db.post.findMany({ select: { slug: true } });
  return posts.map((post) => ({ slug: post.slug }));
}

export const revalidate = 3600; // ISR: revalidate every hour
```

### dynamic() import with ssr: false for browser-only components
```tsx
import dynamic from "next/dynamic";

// Use ssr: false ONLY for components that access browser APIs (canvas, WebGL, etc.)
const MapView = dynamic(() => import("@/components/MapView"), {
  ssr: false,
  loading: () => <div className="h-96 animate-pulse bg-muted rounded" />,
});
```

## Anti-pattern

```tsx
// WRONG: single Suspense around entire page (no progressive loading)
<Suspense fallback={<FullPageSpinner />}>
  <EntirePage />
</Suspense>

// CORRECT: granular Suspense boundaries
<>
  <Header />  {/* Instant */}
  <Suspense fallback={<SidebarSkeleton />}>
    <Sidebar />  {/* Streams when ready */}
  </Suspense>
  <Suspense fallback={<ContentSkeleton />}>
    <Content />  {/* Streams independently */}
  </Suspense>
</>

// WRONG: premature optimization
// Don't optimize before measuring. Profile first, optimize second.
// Use React Profiler, Lighthouse, or Vercel Speed Insights to identify
// actual bottlenecks before adding complexity.
```

## Common Mistakes
- Single Suspense around entire page (blocks progressive loading)
- Not using `priority` on above-the-fold images
- Importing heavy libraries in Client Components (ships to browser)
- Missing `sizes` prop on responsive images (over-fetches)
- Using `<img>` instead of `next/image` (no optimization)
- Premature optimization — profile first, optimize second
- Not using `generateStaticParams` for known dynamic routes

## Checklist
- [ ] Heavy client components use `dynamic()` imports
- [ ] Granular `<Suspense>` boundaries for independent data sections
- [ ] `loading.tsx` exists for dynamic routes
- [ ] Images use `next/image` with correct `width`/`height` or `fill`
- [ ] Above-the-fold images have `priority`
- [ ] Fonts loaded via `next/font` (not external CSS links)
- [ ] Heavy libraries kept in Server Components or dynamically imported
- [ ] Build output shows routes under 200KB First Load JS
- [ ] Web Vitals monitored (CLS < 0.1, LCP < 2.5s, FID < 100ms)
- [ ] Known dynamic routes use `generateStaticParams` for pregeneration

## Composes With
- `react-suspense` — Suspense boundaries for streaming
- `caching` — cache strategies affect load times
- `nextjs-data` — data fetching patterns affect TTFB
- `logging` — performance metrics logging
