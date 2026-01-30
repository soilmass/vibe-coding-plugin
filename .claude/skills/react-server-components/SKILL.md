---
name: react-server-components
description: >
  React 19 Server Components — async data fetching, zero client JS, serialization rules, composition with Client Components, server-only imports
allowed-tools: Read, Grep, Glob
---

# React Server Components

## Purpose
React 19 Server Component patterns for Next.js 15. Covers async components, serialization
boundaries, and composition with Client Components. The ONE skill for server-rendered React.

## When to Use
- Building components that fetch data directly
- Reducing client-side JavaScript bundle
- Understanding server/client component boundaries
- Passing server data to interactive components

## When NOT to Use
- Components needing interactivity → `react-client-components`
- Form handling → `react-forms`
- Data fetching strategy → `nextjs-data`

## Pattern

### Async Server Component
```tsx
// No "use client" — Server Component by default
import { db } from "@/lib/db";

export async function ProductList() {
  const products = await db.product.findMany();
  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>{p.name} — ${p.price}</li>
      ))}
    </ul>
  );
}
```

### Composition: Server → Client boundary
```tsx
// Server Component (parent)
import { db } from "@/lib/db";
import { ProductCard } from "./ProductCard"; // Client Component

export async function ProductSection() {
  const products = await db.product.findMany();
  return (
    <div>
      {products.map((p) => (
        <ProductCard key={p.id} name={p.name} price={p.price} />
      ))}
    </div>
  );
}
```

```tsx
// Client Component — only what NEEDS interactivity
"use client";

export function ProductCard({ name, price }: { name: string; price: number }) {
  const [saved, setSaved] = useState(false);
  return (
    <div>
      <h3>{name}</h3>
      <button onClick={() => setSaved(!saved)}>
        {saved ? "Saved" : "Save"}
      </button>
    </div>
  );
}
```

### Children pattern (Server Component inside Client Component)
```tsx
// Client Component wrapper
"use client";
export function Sidebar({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(true);
  return open ? <aside>{children}</aside> : null;
}

// Server Component passes server content as children
import { Sidebar } from "./Sidebar";
export async function Layout() {
  const nav = await getNavItems();
  return <Sidebar><NavList items={nav} /></Sidebar>;
}
```

## Anti-pattern

```tsx
// WRONG: adding "use client" just to use a library
"use client"; // Unnecessary! This has no interactivity
import { formatDate } from "date-fns";

export function PostDate({ date }: { date: Date }) {
  return <time>{formatDate(date, "PPP")}</time>;
}
// date-fns works fine in Server Components — no "use client" needed
```

Only add `"use client"` when you use hooks, event handlers, or browser APIs.

## Common Mistakes
- Adding `"use client"` unnecessarily — bloats client bundle
- Passing non-serializable props across the boundary (functions, classes)
- Importing server-only code in client components — use `server-only` package
- Not using the children pattern for server content in client wrappers
- Making entire pages client components when only one section needs interactivity

## Checklist
- [ ] Components are Server Components by default (no directive)
- [ ] `"use client"` only on components with hooks/handlers/browser APIs
- [ ] Props across server→client boundary are serializable (no functions)
- [ ] `import "server-only"` on sensitive server modules
- [ ] Children pattern used for server content inside client wrappers

## Composes With
- `react-client-components` — client components handle the interactive parts
- `nextjs-data` — data fetching happens in server components
- `caching` — cache strategies apply to server-side data fetching
- `state-management` — RSC decisions drive state architecture choices
