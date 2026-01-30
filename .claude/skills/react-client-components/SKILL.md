---
name: react-client-components
description: >
  React 19 Client Components — "use client" boundary, hooks, event handlers, ref-as-prop, browser APIs, when to choose client over server
allowed-tools: Read, Grep, Glob
---

# React Client Components

## Purpose
React 19 Client Component patterns. Covers the `"use client"` boundary, hooks, event handlers,
and ref-as-prop. The ONE skill for interactive browser-side React.

## When to Use
- Components with `useState`, `useEffect`, or custom hooks
- Components with onClick, onChange, onSubmit handlers
- Components using browser APIs (window, document, localStorage)
- Components using third-party libraries that need browser context

## When NOT to Use
- Components that only display data → `react-server-components`
- Form submission logic → `react-forms`
- Data fetching → `nextjs-data`

## Pattern

### Basic client component
```tsx
"use client";

import { useState } from "react";

export function Counter() {
  const [count, setCount] = useState(0);
  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

### Ref as prop (React 19 — no forwardRef)
```tsx
"use client";

// CORRECT: ref is a regular prop in React 19
function Input({ ref, ...props }: { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />;
}

// Usage
function Form() {
  const inputRef = useRef<HTMLInputElement>(null);
  return <Input ref={inputRef} placeholder="Type here" />;
}
```

### Custom hook
```tsx
// src/hooks/useMediaQuery.ts
"use client";

import { useState, useEffect } from "react";

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(query);
    setMatches(media.matches);
    const listener = (e: MediaQueryListEvent) => setMatches(e.matches);
    media.addEventListener("change", listener);
    return () => media.removeEventListener("change", listener);
  }, [query]);

  return matches;
}
```

## Anti-pattern

```tsx
// WRONG: using forwardRef (deprecated in React 19)
import { forwardRef } from "react";

const Input = forwardRef<HTMLInputElement, InputProps>((props, ref) => {
  return <input ref={ref} {...props} />;
});
Input.displayName = "Input"; // Also unnecessary boilerplate
```

React 19 passes ref as a regular prop. `forwardRef` is unnecessary and adds complexity.

## Common Mistakes
- Using `forwardRef` — React 19 supports ref as a regular prop
- Adding `"use client"` to components that don't need it
- Using `useEffect` for data fetching — fetch in Server Components
- Not extracting interactive parts into small client components
- Using `window` without checking if it's available (SSR)

## Checklist
- [ ] `"use client"` only on components that truly need it
- [ ] `ref` as a regular prop, not `forwardRef`
- [ ] No data fetching in `useEffect` — use Server Components
- [ ] Browser API usage guarded against SSR
- [ ] Custom hooks in `src/hooks/` with `"use client"`

### Re-render optimization rules
```tsx
"use client";

// 1. Defer reads — don't subscribe to state only used in callbacks
// WRONG: component re-renders on every count change
function Counter({ count, onIncrement }: { count: number; onIncrement: () => void }) {
  return <button onClick={() => onIncrement()}>+</button>; // Never displays count!
}
// CORRECT: don't pass count if you don't render it

// 2. Extract expensive work into memoized child components
function ParentWithFrequentUpdates() {
  const [filter, setFilter] = useState("");
  return (
    <>
      <input value={filter} onChange={(e) => setFilter(e.target.value)} />
      <ExpensiveList />  {/* Extract so it doesn't re-render on every keystroke */}
    </>
  );
}

// 3. Hoist default non-primitive props outside component
const DEFAULT_OPTIONS = { sort: "name", order: "asc" } as const;
function DataGrid({ options = DEFAULT_OPTIONS }: { options?: SortOptions }) {
  // Stable reference — no re-renders from recreated default
}

// 4. Derive state during render, not in useEffect
// WRONG:
const [fullName, setFullName] = useState("");
useEffect(() => setFullName(`${first} ${last}`), [first, last]);
// CORRECT:
const fullName = `${first} ${last}`; // Derived during render

// 5. Functional setState for stable callbacks
const increment = useCallback(() => {
  setCount((c) => c + 1); // No dependency on count
}, []); // Stable forever

// 6. Lazy state initialization
const [data] = useState(() => expensiveComputation()); // Function runs once

// 7. Don't useMemo for simple primitives
const total = items.length; // No useMemo needed — primitives are cheap

// 8. Move effect logic to event handlers when possible
// WRONG: useEffect to track form submission
// CORRECT: handle in the onSubmit handler directly

// 9. useTransition for non-urgent updates
const [isPending, startTransition] = useTransition();
function handleFilter(value: string) {
  startTransition(() => setFilter(value)); // Non-urgent, doesn't block input
}

// 10. useRef for transient values that don't need re-renders
const latestValue = useRef(value);
latestValue.current = value; // Update without re-render
```

### Client-side data patterns
```tsx
"use client";

// SWR for automatic request deduplication
import useSWR from "swr";

export function UserAvatar({ userId }: { userId: string }) {
  const { data } = useSWR(`/api/users/${userId}`, fetcher);
  // Multiple components with same key = ONE request
  return <img src={data?.avatar} alt={data?.name} />;
}

// Passive event listeners for scroll/touch (better perf)
useEffect(() => {
  const handler = (e: Event) => { /* handle scroll */ };
  window.addEventListener("scroll", handler, { passive: true });
  return () => window.removeEventListener("scroll", handler);
}, []);

// Deduplicate global event listeners — attach once
// Use a custom hook or context to share a single listener
```

## Composes With
- `react-server-components` — server components are the default, client is the exception
- `react-forms` — forms combine client interactivity with server actions
- `shadcn` — shadcn components are client components with ref-as-prop
- `composition-patterns` — compound component patterns for complex client UIs
- `state-management` — state decisions affect re-render optimization
