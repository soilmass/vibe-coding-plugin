---
name: virtualization
description: >
  TanStack Virtual for long lists, infinite scroll with Intersection Observer, windowed rendering
allowed-tools: Read, Grep, Glob
---

# Virtualization

## Purpose
Virtualization patterns for rendering large datasets efficiently. Covers TanStack Virtual for
windowed rendering, infinite scroll with Intersection Observer and cursor-based pagination,
and scroll-to-top navigation. The ONE skill for large list performance.

## When to Use
- Rendering lists with 500+ items
- Building infinite scroll feeds
- Optimizing data table rendering for large datasets
- Adding virtualized grids (2D virtualization)
- Implementing scroll-based lazy loading

## When NOT to Use
- Small lists (<500 items) → render normally
- Server-side pagination (no scroll) → `data-tables`
- Image lazy loading → `image-optimization`

## Pattern

### Basic virtualized list (fixed height)
```tsx
"use client";

import { useVirtualizer } from "@tanstack/react-virtual";
import { useRef } from "react";

type Item = { id: string; title: string };

export function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 48, // Fixed row height
    overscan: 5,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div
        style={{ height: `${virtualizer.getTotalSize()}px`, position: "relative" }}
      >
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.key}
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              width: "100%",
              height: `${virtualRow.size}px`,
              transform: `translateY(${virtualRow.start}px)`,
            }}
            className="flex items-center border-b px-4"
          >
            {items[virtualRow.index].title}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Variable-height virtualized list
```tsx
"use client";

import { useVirtualizer } from "@tanstack/react-virtual";
import { useRef } from "react";

export function VariableHeightList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 80, // Estimated — measured dynamically
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: "relative" }}>
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.key}
            ref={virtualizer.measureElement}
            data-index={virtualRow.index}
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              width: "100%",
              transform: `translateY(${virtualRow.start}px)`,
            }}
            className="border-b p-4"
          >
            <h3 className="font-medium">{items[virtualRow.index].title}</h3>
            <p className="text-sm text-muted-foreground">
              {items[virtualRow.index].description}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Infinite scroll with Intersection Observer + cursor pagination
```tsx
"use client";

import { useRef, useCallback, useState, useTransition } from "react";
import { loadMoreItems } from "@/actions/loadMoreItems";

type Item = { id: string; title: string };

export function InfiniteScrollList({ initialItems, initialCursor }: {
  initialItems: Item[];
  initialCursor: string | null;
}) {
  const [items, setItems] = useState(initialItems);
  const [cursor, setCursor] = useState(initialCursor);
  const [isPending, startTransition] = useTransition();
  const observerRef = useRef<IntersectionObserver | null>(null);

  const lastItemRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (isPending || !cursor) return;
      if (observerRef.current) observerRef.current.disconnect();

      observerRef.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && cursor) {
          startTransition(async () => {
            const { items: newItems, nextCursor } = await loadMoreItems(cursor);
            setItems((prev) => [...prev, ...newItems]);
            setCursor(nextCursor);
          });
        }
      });

      if (node) observerRef.current.observe(node);
    },
    [isPending, cursor, startTransition]
  );

  return (
    <div className="space-y-2">
      {items.map((item, i) => (
        <div
          key={item.id}
          ref={i === items.length - 1 ? lastItemRef : undefined}
          className="rounded-lg border p-4"
        >
          {item.title}
        </div>
      ))}
      {isPending && (
        <div className="flex justify-center py-4">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      )}
      {!cursor && (
        <p className="py-4 text-center text-sm text-muted-foreground">
          No more items
        </p>
      )}
    </div>
  );
}
```

### Server Action for cursor-based pagination
```tsx
"use server";

import { db } from "@/lib/db";

export async function loadMoreItems(cursor: string) {
  const items = await db.item.findMany({
    take: 20,
    skip: 1, // Skip the cursor
    cursor: { id: cursor },
    orderBy: { createdAt: "desc" },
  });

  const nextCursor = items.length === 20 ? items[items.length - 1].id : null;

  return { items, nextCursor };
}
```

### Scroll-to-top button
```tsx
"use client";

import { useState, useEffect } from "react";
import { ArrowUp } from "lucide-react";
import { Button } from "@/components/ui/button";

export function ScrollToTop() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    function handleScroll() {
      setVisible(window.scrollY > 500);
    }
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  if (!visible) return null;

  return (
    <Button
      variant="outline"
      size="icon"
      className="fixed bottom-6 right-6 z-50 rounded-full shadow-lg"
      onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
      aria-label="Scroll to top"
    >
      <ArrowUp className="h-4 w-4" />
    </Button>
  );
}
```

### Virtualized grid (2D)
```tsx
"use client";

import { useVirtualizer } from "@tanstack/react-virtual";
import { useRef } from "react";

export function VirtualGrid({
  items,
  columns = 3,
}: {
  items: Item[];
  columns?: number;
}) {
  const parentRef = useRef<HTMLDivElement>(null);
  const rowCount = Math.ceil(items.length / columns);

  const rowVirtualizer = useVirtualizer({
    count: rowCount,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 200,
    overscan: 3,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: `${rowVirtualizer.getTotalSize()}px`, position: "relative" }}>
        {rowVirtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.key}
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              width: "100%",
              height: `${virtualRow.size}px`,
              transform: `translateY(${virtualRow.start}px)`,
            }}
            className="grid gap-4"
            style-grid-template-columns={`repeat(${columns}, 1fr)`}
          >
            {Array.from({ length: columns }).map((_, colIndex) => {
              const itemIndex = virtualRow.index * columns + colIndex;
              const item = items[itemIndex];
              if (!item) return <div key={colIndex} />;
              return (
                <div key={item.id} className="rounded-lg border p-4">
                  {item.title}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Anti-pattern

```tsx
// WRONG: rendering 1000+ DOM nodes without virtualization
{items.map((item) => <Card key={item.id} {...item} />)}
// 1000+ DOM nodes causes jank, high memory usage, slow initial render

// WRONG: offset pagination for infinite scroll
const items = await db.item.findMany({
  skip: page * 20, // Gets slower as page increases
  take: 20,
});
// CORRECT: cursor-based pagination (consistent performance)
const items = await db.item.findMany({
  cursor: { id: lastItemId },
  take: 20,
});
```

## Common Mistakes
- Rendering 1000+ items without virtualization — use TanStack Virtual
- Using offset pagination for infinite scroll — cursor pagination is O(1)
- Missing `overscan` prop — visible gaps during fast scrolling
- Not using `measureElement` for variable-height items — layout breaks
- Forgetting loading indicator at scroll boundary — users think list ended

## Checklist
- [ ] Lists with 500+ items use `@tanstack/react-virtual`
- [ ] Infinite scroll uses cursor-based pagination (not offset)
- [ ] Intersection Observer triggers next page load
- [ ] Loading spinner shown at scroll boundary
- [ ] "No more items" indicator when all data loaded
- [ ] Scroll-to-top button for long lists
- [ ] `overscan` set to prevent visible gaps during scrolling

## Composes With
- `react-client-components` — virtualization requires "use client"
- `data-tables` — virtualized rows for large table datasets
- `nextjs-data` — server-side data loading for initial items
- `performance` — virtualization is a key performance optimization
- `react-suspense` — Suspense boundary around initial list load
