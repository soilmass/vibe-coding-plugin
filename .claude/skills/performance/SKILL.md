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

### Animation performance
```tsx
// Use transform and opacity — GPU-accelerated, no layout reflow
// GOOD: transform, opacity, filter
<motion.div animate={{ scale: 1.05, opacity: 0.8 }} />

// BAD: width, height, top, left — triggers layout
<motion.div animate={{ width: 300, height: 200 }} />

// will-change hint for complex animations
<div className="will-change-transform">
  {/* Browser pre-allocates compositor layer */}
</div>

// content-visibility: auto for off-screen content
<section className="content-visibility-auto contain-intrinsic-size-[0_500px]">
  {/* Skips rendering until scrolled into view */}
</section>
```

```css
/* CSS content-visibility for large pages */
@utility content-visibility-auto {
  content-visibility: auto;
  contain-intrinsic-size: auto 500px;
}
```

### Bundle optimization
```tsx
// Import directly from modules — avoid barrel files
// WRONG: pulls in entire library through index re-exports
import { Button } from "./components";           // barrel file
import { format } from "date-fns";               // entire library

// CORRECT: import from specific module
import { Button } from "./components/Button";
import { format } from "date-fns/format";

// Defer third-party scripts until after hydration
import Script from "next/script";
<Script src="https://analytics.example.com/script.js" strategy="afterInteractive" />

// Conditional module loading — import only when feature is activated
async function handleExport() {
  const { exportToPDF } = await import("@/lib/pdf-export");
  await exportToPDF(data);
}

// Preload on hover/focus for perceived speed
import { useRouter } from "next/navigation";
function NavLink({ href, children }: { href: string; children: React.ReactNode }) {
  const router = useRouter();
  return (
    <a
      href={href}
      onMouseEnter={() => router.prefetch(href)}
      onFocus={() => router.prefetch(href)}
    >
      {children}
    </a>
  );
}
```

### Rendering optimization
```tsx
// Hoist static JSX outside component function
const EMPTY_STATE = (
  <div className="py-12 text-center text-muted-foreground">
    No items found
  </div>
);

function ItemList({ items }: { items: Item[] }) {
  if (items.length === 0) return EMPTY_STATE; // No re-creation
  return <ul>{items.map(/* ... */)}</ul>;
}

// Animate <div> wrapper around SVG, not <svg> directly (GPU acceleration)
<motion.div animate={{ scale: 1.1 }}>
  <svg>{/* ... */}</svg>
</motion.div>

// Conditional rendering: ternary not && (avoids rendering 0 or "")
// WRONG: renders "0" to the DOM
{count && <Badge>{count}</Badge>}
// CORRECT:
{count > 0 ? <Badge>{count}</Badge> : null}

// content-visibility: auto for off-screen sections
<section className="[content-visibility:auto] [contain-intrinsic-size:auto_500px]">
  {/* Browser skips rendering until scrolled into view */}
</section>

// Inline <script> for client-only data (prevents hydration flicker)
// Use for non-sensitive config that client needs immediately
```

### JS micro-optimizations (hot paths only)
```tsx
// Set/Map for O(1) lookups instead of array.includes()
const selectedIds = new Set(items.map((i) => i.id));
const isSelected = selectedIds.has(targetId); // O(1) vs O(n)

// Cache property access in tight loops
function processItems(items: Item[]) {
  const len = items.length;
  for (let i = 0; i < len; i++) {
    // ...
  }
}

// Combine .filter().map() into single reduce or loop
// WRONG: iterates twice
const result = items.filter((i) => i.active).map((i) => i.name);
// CORRECT: single pass
const result = items.reduce<string[]>((acc, i) => {
  if (i.active) acc.push(i.name);
  return acc;
}, []);

// Check .length before expensive comparison
if (items.length > 0 && items.some((i) => expensiveCheck(i))) { /* ... */ }

// Early exit from functions
function processData(data: Data | null) {
  if (!data) return;
  if (!data.items.length) return;
  // ... expensive processing
}

// Hoist RegExp creation outside loops
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
function validateEmails(emails: string[]) {
  return emails.filter((e) => EMAIL_RE.test(e));
}

// toSorted() for immutable sorting (no mutation)
const sorted = items.toSorted((a, b) => a.name.localeCompare(b.name));
```

### Hover state gating
```css
/* Only apply hover effects on devices that support hover */
@media (hover: hover) {
  .card:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-lg);
  }
}
/* Touch devices skip hover entirely — no sticky hover bugs */
```

### Perceived Performance & Visual Speed

#### Skeleton-to-content crossfade
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";

// Smooth transition from skeleton to real content
export function SkeletonCrossfade({ loading, skeleton, children }: {
  loading: boolean;
  skeleton: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <AnimatePresence mode="wait">
      {loading ? (
        <motion.div
          key="skeleton"
          exit={{ opacity: 0 }}
          transition={{ duration: 0.15 }}
        >
          {skeleton}
        </motion.div>
      ) : (
        <motion.div
          key="content"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.2 }}
        >
          {children}
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

#### Premium skeleton with gradient shimmer
```tsx
// Skeleton that matches content hierarchy — not just gray boxes
export function CardSkeleton() {
  return (
    <div className="rounded-xl border bg-card p-6">
      <div className="relative overflow-hidden">
        {/* Title */}
        <div className="mb-4 h-6 w-2/3 rounded-md bg-muted" />
        {/* Description lines */}
        <div className="mb-2 h-4 w-full rounded bg-muted" />
        <div className="mb-2 h-4 w-5/6 rounded bg-muted" />
        <div className="h-4 w-3/4 rounded bg-muted" />
        {/* Shimmer overlay */}
        <div className="absolute inset-0 -translate-x-full animate-[shimmer_1.5s_infinite] bg-gradient-to-r from-transparent via-white/10 to-transparent" />
      </div>
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

#### Optimistic button — instant visual feedback
```tsx
"use client";
import { motion } from "motion/react";

// Button changes state BEFORE server responds
export function OptimisticButton({ onClick, children }: {
  onClick: () => Promise<void>;
  children: React.ReactNode;
}) {
  const [state, setState] = useState<"idle" | "loading" | "done">("idle");

  async function handleClick() {
    setState("loading");
    try {
      await onClick();
      setState("done");
      setTimeout(() => setState("idle"), 1500);
    } catch {
      setState("idle");
    }
  }

  return (
    <motion.button
      onClick={handleClick}
      whileTap={{ scale: 0.97 }}
      className="relative overflow-hidden rounded-lg bg-primary px-4 py-2 text-primary-foreground"
    >
      <AnimatePresence mode="wait">
        {state === "idle" && (
          <motion.span key="idle" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            {children}
          </motion.span>
        )}
        {state === "loading" && (
          <motion.span key="loading" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <Loader2 className="h-4 w-4 animate-spin" />
          </motion.span>
        )}
        {state === "done" && (
          <motion.span key="done" initial={{ opacity: 0, scale: 0.5 }} animate={{ opacity: 1, scale: 1 }}>
            <Check className="h-4 w-4" />
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  );
}
```

#### Progressive content reveal
```tsx
"use client";
import { motion } from "motion/react";

// Content sections fade in as they stream from server
export function ProgressiveReveal({ children, index }: {
  children: React.ReactNode; index: number;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{
        duration: 0.3,
        delay: index * 0.05,
        ease: [0.25, 0.46, 0.45, 0.94], // ease-out-quad
      }}
    >
      {children}
    </motion.div>
  );
}
```

#### Preload on hover for perceived instant navigation
```tsx
"use client";
import { useRouter } from "next/navigation";
import { useCallback } from "react";

// Prefetch route AND preload data on hover intent
export function SmartLink({ href, children, ...props }: React.AnchorHTMLAttributes<HTMLAnchorElement> & { href: string }) {
  const router = useRouter();
  const handleHover = useCallback(() => router.prefetch(href), [href, router]);

  return (
    <a
      href={href}
      onMouseEnter={handleHover}
      onFocus={handleHover}
      onClick={(e) => { e.preventDefault(); router.push(href); }}
      {...props}
    >
      {children}
    </a>
  );
}
```

## Composes With
- `react-suspense` — Suspense boundaries for streaming
- `caching` — cache strategies affect load times
- `nextjs-data` — data fetching patterns affect TTFB
- `logging` — performance metrics logging
- `animation` — animation performance with GPU-accelerated properties
- `react-client-components` — re-render optimization affects client performance
- `image-optimization` — images are the biggest LCP factor
- `virtualization` — virtualized lists reduce DOM size for large datasets
- `loading-transitions` — route transitions mask navigation latency
- `visual-design` — skeleton design matching content visual hierarchy
