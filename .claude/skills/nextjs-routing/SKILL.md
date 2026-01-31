---
name: nextjs-routing
description: >
  Next.js 15 App Router routing — file conventions, async params/searchParams, parallel routes, intercepting routes, route groups, next/form
allowed-tools: Read, Grep, Glob
---

# Next.js Routing

## Purpose
Next.js 15 App Router file-based routing. Covers route conventions, async params,
parallel/intercepting routes, and route groups. The ONE skill for URL-to-component mapping.

## When to Use
- Creating new pages or route segments
- Setting up layouts, loading, and error boundaries
- Using parallel routes or intercepting routes
- Accessing route params or search params

## When NOT to Use
- Middleware-level redirects → `nextjs-middleware`
- API endpoints → `api-routes`
- Data fetching within routes → `nextjs-data`

## Pattern

### File conventions
```
src/app/
├── page.tsx              # / route
├── layout.tsx            # Root layout (required)
├── loading.tsx           # Loading UI (Suspense boundary)
├── error.tsx             # Error boundary ("use client")
├── not-found.tsx         # 404 page
├── dashboard/
│   ├── page.tsx          # /dashboard
│   ├── layout.tsx        # Dashboard layout
│   └── settings/
│       └── page.tsx      # /dashboard/settings
├── blog/
│   └── [slug]/
│       └── page.tsx      # /blog/:slug (dynamic)
├── shop/
│   └── [...slug]/
│       └── page.tsx      # /shop/* (catch-all)
└── (marketing)/          # Route group (no URL segment)
    ├── layout.tsx
    └── about/page.tsx    # /about
```

### Async params (Next.js 15 — params is a Promise)
```tsx
export default async function Page({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params; // Must await!
  return <div>{slug}</div>;
}
```

### Async searchParams
```tsx
export default async function Page({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams; // Must await!
  return <div>Search: {q}</div>;
}
```

### Parallel routes
```
src/app/dashboard/
├── layout.tsx            # Renders {children}, {analytics}, {team}
├── page.tsx              # Default children
├── @analytics/
│   └── page.tsx          # analytics slot
└── @team/
    └── page.tsx          # team slot
```

## Anti-pattern

```tsx
// WRONG: destructuring params without awaiting
export default async function Page({
  params: { slug },
}: {
  params: { slug: string }; // Not a Promise — breaks in Next.js 15!
}) {
  return <div>{slug}</div>;
}
```

In Next.js 15, `params` and `searchParams` are Promises. Destructuring
before awaiting causes runtime errors.

## Common Mistakes
- Destructuring params/searchParams before awaiting — they're Promises
- Adding `"use client"` to layout files — layouts should be Server Components
- Forgetting `loading.tsx` — no Suspense boundary for slow pages
- Not using route groups `()` for shared layouts without URL segments
- Missing `not-found.tsx` — default 404 is unstyled

## Checklist
- [ ] `params` and `searchParams` are awaited before use
- [ ] Root `layout.tsx` exists with `<html>` and `<body>`
- [ ] Route groups used for organizational layout sharing
- [ ] `loading.tsx` provides Suspense boundaries
- [ ] Dynamic routes use `[param]` naming convention

### Intercepting routes for modals
```
src/app/
├── feed/
│   └── page.tsx              # Feed page with photo grid
├── photo/[id]/
│   └── page.tsx              # Full photo page (direct navigation)
└── @modal/
    └── (.)photo/[id]/
        └── page.tsx          # Photo modal overlay (intercepted navigation)
```

The `(.)` prefix intercepts the route at the same level. When clicking a photo link
from the feed, the modal renders as an overlay. When navigating directly to `/photo/123`,
the full page renders instead.

```tsx
// src/app/layout.tsx
export default function Layout({
  children,
  modal,
}: {
  children: React.ReactNode;
  modal: React.ReactNode;
}) {
  return (
    <>
      {children}
      {modal}
    </>
  );
}

// src/app/@modal/(.)photo/[id]/page.tsx
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { useRouter } from "next/navigation";

export default function PhotoModal({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter();
  const { id } = await params;

  return (
    <Dialog open onOpenChange={() => router.back()}>
      <DialogContent>
        <PhotoDetail id={id} />
      </DialogContent>
    </Dialog>
  );
}
```

Interception conventions:
- `(.)` — same level
- `(..)` — one level up
- `(..)(..)` — two levels up
- `(...)` — from root

### Route Transition & Navigation Polish

#### Page transition wrapper
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { usePathname } from "next/navigation";

export function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -8 }}
        transition={{ duration: 0.2, ease: [0.25, 0.46, 0.45, 0.94] }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}

// Usage in layout.tsx:
// <PageTransition>{children}</PageTransition>
```

#### Animated intercepted modal
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { useRouter } from "next/navigation";

export function InterceptedModal({ children }: { children: React.ReactNode }) {
  const router = useRouter();

  return (
    <>
      {/* Backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={() => router.back()}
        className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
      />
      {/* Modal */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 20 }}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
        className="fixed inset-4 z-50 mx-auto my-auto max-h-[85vh] max-w-2xl overflow-auto rounded-2xl bg-card shadow-2xl"
      >
        {children}
      </motion.div>
    </>
  );
}
```

#### Slim route progress bar
```tsx
"use client";
import { motion } from "motion/react";
import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";

export function RouteProgress() {
  const pathname = usePathname();
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    const timer = setTimeout(() => setLoading(false), 500);
    return () => clearTimeout(timer);
  }, [pathname]);

  if (!loading) return null;

  return (
    <motion.div
      className="fixed inset-x-0 top-0 z-[100] h-0.5 bg-primary"
      initial={{ scaleX: 0, transformOrigin: "left" }}
      animate={{ scaleX: 0.8 }}
      exit={{ scaleX: 1, opacity: 0 }}
      transition={{ duration: 0.5, ease: "easeOut" }}
    />
  );
}
```

## Composes With
- `error-handling` — error.tsx is a routing convention
- `react-suspense` — loading.tsx creates Suspense boundaries
- `nextjs-middleware` — middleware runs before route resolution
- `i18n` — locale-aware routing with `[locale]` segments
- `state-management` — URL state syncs with route params via nuqs
- `layout-patterns` — parallel routes for split views
- `animation` — page transitions, modal entrance/exit, progress bar
- `loading-transitions` — route transition overlays
