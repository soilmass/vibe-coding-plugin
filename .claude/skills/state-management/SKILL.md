---
name: state-management
description: >
  State management patterns for React 19 + Next.js 15 — URL state with nuqs, React Context for UI, useOptimistic for mutations, server-first approach
allowed-tools: Read, Grep, Glob
---

# State Management

## Purpose
State management patterns for React 19 + Next.js 15. Covers URL state with `nuqs`, React Context
for UI state, `useOptimistic` for mutations, and server-first architecture. The ONE skill for
choosing where state lives.

## When to Use
- Deciding where to store state (server vs client vs URL)
- Managing UI state (modals, tabs, filters)
- Optimistic updates for mutations
- Sharing state between components without prop drilling
- Syncing state with URL search params

## When NOT to Use
- Server-side data fetching → `nextjs-data`
- Form state management → `react-forms`
- Cache invalidation → `caching`

## Pattern

### Decision tree: where does state belong?
```
Is it data from the database?
  → YES → Server Component (fetch in RSC, no client state)

Is it shareable via URL (filters, search, pagination)?
  → YES → URL state with `nuqs`

Is it UI-only (modal open, sidebar collapsed)?
  → YES → React Context or useState (local)

Is it an optimistic mutation?
  → YES → useOptimistic
```

### URL state with nuqs
```tsx
"use client";
import { useQueryState, parseAsInteger } from "nuqs";

export function ProductFilters() {
  const [category, setCategory] = useQueryState("category");
  const [page, setPage] = useQueryState("page", parseAsInteger.withDefault(1));

  return (
    <div>
      <select
        value={category ?? ""}
        onChange={(e) => setCategory(e.target.value || null)}
      >
        <option value="">All</option>
        <option value="electronics">Electronics</option>
      </select>
      <button onClick={() => setPage((p) => p + 1)}>Next page</button>
    </div>
  );
}
```

### React Context for UI state
```tsx
"use client";
import { createContext, useContext, useState } from "react";

const SidebarContext = createContext<{ open: boolean; toggle: () => void } | null>(null);

export function SidebarProvider({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  return (
    <SidebarContext value={{ open, toggle: () => setOpen((o) => !o) }}>
      {children}
    </SidebarContext>
  );
}

export const useSidebar = () => {
  const ctx = useContext(SidebarContext);
  if (!ctx) throw new Error("useSidebar must be used within SidebarProvider");
  return ctx;
};
```

### Optimistic mutations with useOptimistic
```tsx
"use client";
import { useOptimistic } from "react";
import { toggleTodo } from "@/actions/toggleTodo";

export function TodoItem({ todo }: { todo: Todo }) {
  const [optimistic, setOptimistic] = useOptimistic(todo);

  return (
    <form
      action={async () => {
        setOptimistic({ ...todo, completed: !todo.completed });
        await toggleTodo(todo.id);
      }}
    >
      <button>{optimistic.completed ? "Undo" : "Done"}</button>
    </form>
  );
}
```

### Context split (separate state/dispatch to prevent re-renders)
```tsx
"use client";
import { createContext, useContext, useReducer } from "react";

type State = { count: number };
type Action = { type: "increment" } | { type: "decrement" };

const StateContext = createContext<State | null>(null);
const DispatchContext = createContext<React.Dispatch<Action> | null>(null);

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case "increment": return { count: state.count + 1 };
    case "decrement": return { count: state.count - 1 };
  }
}

export function CounterProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(reducer, { count: 0 });
  return (
    <StateContext value={state}>
      <DispatchContext value={dispatch}>{children}</DispatchContext>
    </StateContext>
  );
}

// Components that only dispatch won't re-render when state changes
export const useCounterState = () => useContext(StateContext)!;
export const useCounterDispatch = () => useContext(DispatchContext)!;
```

## Anti-pattern

```tsx
// WRONG: Redux/Zustand for server data
"use client";
import { useStore } from "@/store";
export function UserProfile() {
  const user = useStore((s) => s.user);
  useEffect(() => { fetchUser().then(setUser); }, []);
  // This data belongs in a Server Component!
}

// CORRECT: fetch in Server Component, no global store needed
export default async function UserProfile() {
  const user = await getUser();
  return <div>{user.name}</div>;
}
```

## Common Mistakes
- Using Redux/Zustand for data that belongs in Server Components
- Storing server data in client-side global stores
- Not using URL state for shareable UI state (filters, pagination)
- Using `useEffect` to sync state when `useOptimistic` fits better
- Creating Context providers for state used in only one component

## Checklist
- [ ] Server data fetched in Server Components (not client stores)
- [ ] Shareable UI state stored in URL with `nuqs`
- [ ] Local UI state in `useState` or Context (not global stores)
- [ ] Mutations use `useOptimistic` for instant feedback
- [ ] Context providers placed at the lowest necessary level
- [ ] No `useEffect` for data fetching (Server Components instead)

## Composes With
- `react-server-components` — server-first data fetching replaces client stores
- `react-forms` — form state with `useActionState`
- `nextjs-routing` — URL state syncs with route params
