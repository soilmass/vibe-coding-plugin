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

### SWR deduplication
```tsx
"use client";
import useSWR from "swr";

// Multiple components using the same key = ONE network request
// SWR deduplicates automatically by cache key
function UserAvatar() {
  const { data } = useSWR("/api/user", fetcher);
  return <img src={data?.avatar} />;
}

function UserName() {
  const { data } = useSWR("/api/user", fetcher); // Same key — no extra request
  return <span>{data?.name}</span>;
}
```

### localStorage schema versioning
```tsx
"use client";

const STORAGE_VERSION = 2;
const STORAGE_KEY = "app-preferences";

type Preferences = { theme: string; sidebarOpen: boolean };

function loadPreferences(): Preferences {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return { theme: "system", sidebarOpen: true };

  const parsed = JSON.parse(raw);
  if (parsed._version !== STORAGE_VERSION) {
    // Migration: reset to defaults on version bump
    localStorage.removeItem(STORAGE_KEY);
    return { theme: "system", sidebarOpen: true };
  }
  return parsed.data;
}

function savePreferences(prefs: Preferences) {
  localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify({ _version: STORAGE_VERSION, data: prefs })
  );
}
```

Minimize what you store — only persist what can't be derived. Version the schema so
old data doesn't crash the app after updates.

### Deep-link all stateful UI
```tsx
// If it uses useState, consider URL sync via nuqs
// Filters, pagination, modal open state, active tabs — all deep-linkable
"use client";
import { useQueryState, parseAsInteger, parseAsBoolean } from "nuqs";

export function ProductPage() {
  const [tab, setTab] = useQueryState("tab", { defaultValue: "details" });
  const [page, setPage] = useQueryState("page", parseAsInteger.withDefault(1));
  const [showFilters, setShowFilters] = useQueryState("filters", parseAsBoolean.withDefault(false));

  // URL: /products?tab=reviews&page=2&filters=true
  // Users can share, bookmark, and use browser back/forward
}
```

Rule: if a piece of UI state would be useful in a shared link, put it in the URL.

### State Change Visual Feedback

#### Animated filter results transition
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { useQueryState } from "nuqs";

// Results animate when filters change
export function FilteredResults({ items, filterKey }: {
  items: Item[];
  filterKey: string; // Changes when filters update
}) {
  return (
    <AnimatePresence mode="popLayout">
      {items.map((item) => (
        <motion.div
          key={item.id}
          layout
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.95 }}
          transition={{ type: "spring", stiffness: 400, damping: 30 }}
        >
          <ItemCard item={item} />
        </motion.div>
      ))}
    </AnimatePresence>
  );
}
```

#### Optimistic update with rollback animation
```tsx
"use client";
import { useOptimistic, useTransition } from "react";
import { motion, AnimatePresence } from "motion/react";
import { toast } from "sonner";

export function OptimisticTodo({ todo, toggleAction }: {
  todo: Todo;
  toggleAction: (id: string) => Promise<void>;
}) {
  const [optimistic, setOptimistic] = useOptimistic(todo);
  const [, startTransition] = useTransition();

  return (
    <motion.div
      layout
      className="flex items-center gap-3 rounded-lg border p-3"
      animate={{
        opacity: optimistic.completed ? 0.6 : 1,
        scale: optimistic.completed ? 0.98 : 1,
      }}
      transition={{ type: "spring", stiffness: 400, damping: 30 }}
    >
      <form
        action={() => {
          startTransition(async () => {
            setOptimistic({ ...todo, completed: !todo.completed });
            try {
              await toggleAction(todo.id);
            } catch {
              // Rollback happens automatically — useOptimistic resets
              toast.error("Failed to update");
            }
          });
        }}
      >
        <button
          className={cn(
            "h-5 w-5 rounded-full border-2 transition-colors",
            optimistic.completed && "border-primary bg-primary"
          )}
        >
          <AnimatePresence>
            {optimistic.completed && (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                exit={{ scale: 0 }}
                transition={{ type: "spring", stiffness: 500, damping: 25 }}
              >
                <Check className="h-3 w-3 text-primary-foreground" />
              </motion.div>
            )}
          </AnimatePresence>
        </button>
      </form>
      <span className={cn(optimistic.completed && "line-through text-muted-foreground")}>
        {todo.title}
      </span>
    </motion.div>
  );
}
```

#### Tab state with animated indicator
```tsx
"use client";
import { useQueryState } from "nuqs";
import { motion } from "motion/react";

export function AnimatedTabs({ tabs }: { tabs: { value: string; label: string }[] }) {
  const [activeTab, setActiveTab] = useQueryState("tab", { defaultValue: tabs[0].value });

  return (
    <div className="flex gap-1 border-b" role="tablist">
      {tabs.map((tab) => (
        <button
          key={tab.value}
          role="tab"
          aria-selected={activeTab === tab.value}
          onClick={() => setActiveTab(tab.value)}
          className="relative px-4 py-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
        >
          {activeTab === tab.value && (
            <motion.div
              layoutId="active-tab"
              className="absolute inset-x-0 -bottom-px h-0.5 bg-primary"
              transition={{ type: "spring", stiffness: 500, damping: 35 }}
            />
          )}
          {tab.label}
        </button>
      ))}
    </div>
  );
}
```

## Composes With
- `react-server-components` — server-first data fetching replaces client stores
- `react-forms` — form state with `useActionState`
- `nextjs-routing` — URL state syncs with route params
- `composition-patterns` — context patterns for shared component state
- `animation` — filter transitions, optimistic update animations, tab indicators
