---
name: react-forms
description: >
  React 19 forms — useActionState, useFormStatus, useOptimistic, Zod validation, Server Action integration, progressive enhancement
allowed-tools: Read, Grep, Glob
---

# React Forms

## Purpose
React 19 form patterns with Server Action integration. Covers `useActionState`, `useFormStatus`,
`useOptimistic`, and Zod validation. The ONE skill for form handling.

## When to Use
- Building forms that submit to Server Actions
- Adding optimistic updates to form submissions
- Implementing form validation with Zod
- Showing pending/loading states during submission

## When NOT to Use
- Server Action implementation → `react-server-actions`
- API endpoint form processing → `api-routes`
- Component styling → `shadcn`

## Pattern

### useActionState (replaces deprecated useFormState)
```tsx
"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { createTodo } from "@/actions/createTodo";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? "Creating..." : "Create"}
    </button>
  );
}

export function TodoForm() {
  const [state, formAction, isPending] = useActionState(createTodo, {});

  return (
    <form action={formAction}>
      <input name="title" required />
      {state.error?.title && <p className="text-red-500">{state.error.title}</p>}
      <SubmitButton />
    </form>
  );
}
```

### useOptimistic
```tsx
"use client";

import { useOptimistic } from "react";

export function TodoList({
  todos,
  addTodo,
}: {
  todos: Todo[];
  addTodo: (formData: FormData) => Promise<void>;
}) {
  const [optimisticTodos, addOptimistic] = useOptimistic(
    todos,
    (state, newTodo: string) => [
      ...state,
      { id: "temp", title: newTodo, completed: false },
    ]
  );

  return (
    <>
      <ul>
        {optimisticTodos.map((t) => (
          <li key={t.id}>{t.title}</li>
        ))}
      </ul>
      <form
        action={async (formData) => {
          addOptimistic(formData.get("title") as string);
          await addTodo(formData);
        }}
      >
        <input name="title" />
        <button type="submit">Add</button>
      </form>
    </>
  );
}
```

### Async field validation (debounced server check)
```tsx
"use client";
import { useTransition, useState } from "react";
import { checkUsernameAvailable } from "@/actions/checkUsername";

export function UsernameField() {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value;
    if (value.length < 3) return;

    startTransition(async () => {
      const available = await checkUsernameAvailable(value);
      setError(available ? null : "Username already taken");
    });
  }

  return (
    <div>
      <input name="username" onChange={handleChange} />
      {isPending && <span className="text-muted-foreground text-sm">Checking...</span>}
      {error && <p className="text-red-500 text-sm">{error}</p>}
    </div>
  );
}
```

### Zod validation → per-field error display
```tsx
// Server Action: Zod validation returns fieldErrors
"use server";
import { z } from "zod";

const CreateTodoSchema = z.object({
  title: z.string().min(1, "Title is required").max(100, "Title too long"),
  description: z.string().max(500, "Description too long").optional(),
});

type FormState = {
  success?: boolean;
  error?: Record<string, string[]>;
};

export async function createTodo(
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  const parsed = CreateTodoSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten().fieldErrors };

  await db.todo.create({ data: parsed.data });
  revalidatePath("/todos");
  return { success: true };
}
```

```tsx
// Client form: per-field errors with aria attributes
"use client";
import { useActionState } from "react";
import { createTodo } from "@/actions/createTodo";

export function TodoForm() {
  const [state, formAction, isPending] = useActionState(createTodo, {});

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="title">Title</label>
        <input
          id="title"
          name="title"
          aria-invalid={!!state.error?.title}
          aria-describedby={state.error?.title ? "title-error" : undefined}
        />
        {state.error?.title && (
          <p id="title-error" className="text-red-500 text-sm">
            {state.error.title[0]}
          </p>
        )}
      </div>
      <button type="submit" disabled={isPending}>
        {isPending ? "Creating..." : "Create"}
      </button>
    </form>
  );
}
```

## Anti-pattern

```tsx
// WRONG: using useFormState (deprecated in React 19)
import { useFormState } from "react-dom"; // DEPRECATED!

function MyForm() {
  const [state, formAction] = useFormState(myAction, {});
  // Use useActionState from "react" instead
}
```

`useFormState` is deprecated. Use `useActionState` from `"react"` (not `"react-dom"`).

## Common Mistakes
- Using `useFormState` instead of `useActionState` — deprecated
- Importing `useActionState` from `"react-dom"` — it's in `"react"`
- Putting `useFormStatus` in the same component as `<form>` — must be a child
- Not providing initial state to `useActionState` — second argument required
- Missing Zod validation in the Server Action — see `react-server-actions` for validation patterns

## Checklist
- [ ] `useActionState` from `"react"` (not `useFormState`)
- [ ] `useFormStatus` in a child component of `<form>`, not sibling
- [ ] Initial state provided as second argument to `useActionState`
- [ ] Server Action validates with Zod (client validation is UX only)
- [ ] Optimistic updates via `useOptimistic` where appropriate

## Composes With
- `react-server-actions` — forms submit to server actions
- `shadcn` — shadcn Form component provides structure
- `error-handling` — form errors shown inline, not in error boundaries
- `logging` — track form submissions and validation failures
