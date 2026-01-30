---
name: typescript-patterns
description: >
  TypeScript patterns for React 19 + Next.js 15 — typing hooks, async params, Server Action state, component props, discriminated unions, no any
allowed-tools: Read, Grep, Glob
---

# TypeScript Patterns

## Purpose
TypeScript patterns specific to React 19 and Next.js 15. Covers typing hooks, async params,
action state, and component props. The ONE skill for type-safe patterns.

## When to Use
- Typing component props and page params
- Creating type-safe Server Action state
- Typing custom hooks and context
- Resolving TypeScript errors in Next.js patterns

## When NOT to Use
- Prisma schema types → `prisma` (auto-generated)
- Zod schemas for validation → `react-server-actions`
- Generic TypeScript questions → not project-specific

## Pattern

### Async page params (Next.js 15)
```tsx
type PageProps = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ q?: string; page?: string }>;
};

export default async function Page({ params, searchParams }: PageProps) {
  const { id } = await params;
  const { q } = await searchParams;
  return <div>{id} — {q}</div>;
}
```

### Server Action state type
```tsx
type ActionState = {
  success?: boolean;
  error?: Record<string, string[]>;
  data?: { id: string };
};

// Usage with useActionState
const [state, formAction, isPending] = useActionState<ActionState, FormData>(
  myAction,
  {}
);
```

### Component props with ref (React 19)
```tsx
type InputProps = {
  label: string;
  error?: string;
  ref?: React.Ref<HTMLInputElement>;
} & Omit<React.ComponentProps<"input">, "ref">;

function Input({ label, error, ref, ...props }: InputProps) {
  return (
    <div>
      <label>{label}</label>
      <input ref={ref} {...props} />
      {error && <p>{error}</p>}
    </div>
  );
}
```

### Discriminated unions for component variants
```tsx
type ButtonProps =
  | { variant: "link"; href: string; onClick?: never }
  | { variant: "button"; onClick: () => void; href?: never }
  | { variant: "submit"; onClick?: never; href?: never };

function ActionButton(props: ButtonProps) {
  switch (props.variant) {
    case "link":
      return <a href={props.href}>Link</a>;
    case "button":
      return <button onClick={props.onClick}>Click</button>;
    case "submit":
      return <button type="submit">Submit</button>;
  }
}
```

### `as const` for type-safe constants
```tsx
// Derive union types from constant arrays
const ROLES = ["admin", "editor", "viewer"] as const;
type Role = (typeof ROLES)[number]; // "admin" | "editor" | "viewer"

// Type-safe config objects
const STATUS_MAP = {
  draft: { label: "Draft", color: "gray" },
  published: { label: "Published", color: "green" },
  archived: { label: "Archived", color: "red" },
} as const;

type Status = keyof typeof STATUS_MAP; // "draft" | "published" | "archived"

// Exhaustiveness check with never
function getStatusLabel(status: Status): string {
  switch (status) {
    case "draft": return STATUS_MAP.draft.label;
    case "published": return STATUS_MAP.published.label;
    case "archived": return STATUS_MAP.archived.label;
    default: {
      const _exhaustive: never = status;
      return _exhaustive;
    }
  }
}
```

## Anti-pattern

```tsx
// WRONG: using "any" type
function handleData(data: any) { // Never use "any"
  return data.value; // No type safety
}

// CORRECT: use "unknown" with narrowing
function handleData(data: unknown) {
  if (typeof data === "object" && data !== null && "value" in data) {
    return (data as { value: string }).value;
  }
  throw new Error("Invalid data");
}
```

`any` disables all type checking. Use `unknown` and narrow with type guards.

## Common Mistakes
- Using `any` instead of `unknown` — bypasses type safety
- Not awaiting Promise params — type says Promise, must await
- Using `React.FC` — unnecessary, doesn't support generics well
- Forgetting to type Server Action return state
- Using `as` casts instead of type guards — hides real type errors

## Checklist
- [ ] No `any` types — use `unknown` with type narrowing
- [ ] Page props type `params` and `searchParams` as Promises
- [ ] Server Action state has explicit type
- [ ] Component refs typed as `React.Ref<T>`, not using forwardRef
- [ ] Discriminated unions for variant props

## Composes With
- `react-forms` — typing useActionState and form state
- `react-server-actions` — typing action return types
- `nextjs-routing` — typing page params and searchParams
