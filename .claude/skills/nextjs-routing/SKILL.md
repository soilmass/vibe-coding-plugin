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

## Composes With
- `error-handling` — error.tsx is a routing convention
- `react-suspense` — loading.tsx creates Suspense boundaries
- `nextjs-middleware` — middleware runs before route resolution
- `i18n` — locale-aware routing with `[locale]` segments
- `state-management` — URL state syncs with route params via nuqs
- `layout-patterns` — parallel routes for split views
