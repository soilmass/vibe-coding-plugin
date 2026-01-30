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

## Composes With
- `react-server-components` — server components are the default, client is the exception
- `react-forms` — forms combine client interactivity with server actions
- `shadcn` — shadcn components are client components with ref-as-prop
