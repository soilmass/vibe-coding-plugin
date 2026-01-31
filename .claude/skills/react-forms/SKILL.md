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

### HTML form best practices
```tsx
// autocomplete and meaningful name on all inputs
<input name="email" type="email" autoComplete="email" />
<input name="given-name" type="text" autoComplete="given-name" />
<input name="tel" type="tel" autoComplete="tel" inputMode="tel" />
<input name="postal-code" type="text" autoComplete="postal-code" inputMode="numeric" />

// Correct type and inputMode for mobile keyboards
<input type="email" inputMode="email" />    // @ key visible
<input type="url" inputMode="url" />        // .com key visible
<input type="number" inputMode="decimal" /> // Number pad

// NEVER block paste — breaks password managers
// WRONG:
<input onPaste={(e) => e.preventDefault()} /> // Hostile to users

// spellCheck={false} on non-prose inputs
<input type="email" spellCheck={false} />
<input name="username" spellCheck={false} />
<input name="code" spellCheck={false} />

// Labels must be clickable — htmlFor or wrapping
<label htmlFor="email">Email</label>
<input id="email" name="email" />
// OR
<label>
  Email
  <input name="email" />
</label>

// Submit button: enabled by default, spinner during request
// WRONG: disabled until form is valid (users can't tell why it's disabled)
// CORRECT: enabled → shows validation errors on submit → spinner during request
function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? <Spinner /> : "Save changes"}
    </button>
  );
}

// Inline errors next to fields + focus first error on submit
function focusFirstError(formRef: React.RefObject<HTMLFormElement>) {
  const firstInvalid = formRef.current?.querySelector("[aria-invalid='true']");
  if (firstInvalid instanceof HTMLElement) firstInvalid.focus();
}

// Placeholders: end with … and show example pattern
<input placeholder="name@example.com…" />
<input placeholder="Search products…" />

// Warn before navigation with unsaved changes
useEffect(() => {
  if (!isDirty) return;
  const handler = (e: BeforeUnloadEvent) => {
    e.preventDefault();
  };
  window.addEventListener("beforeunload", handler);
  return () => window.removeEventListener("beforeunload", handler);
}, [isDirty]);

// Checkboxes/radios: label + control share single hit target
<label className="flex items-center gap-2 cursor-pointer">
  <input type="checkbox" name="agree" />
  <span>I agree to the terms</span>
</label>
```

## Microinteractions & Visual Polish

Functional forms are table stakes. Award-winning forms feel alive — errors animate in, inputs respond to focus, and success states celebrate.

### Animated error messages
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";

function FieldError({ message }: { message?: string }) {
  return (
    <AnimatePresence mode="wait">
      {message && (
        <motion.p
          initial={{ opacity: 0, y: -8, height: 0 }}
          animate={{ opacity: 1, y: 0, height: "auto" }}
          exit={{ opacity: 0, y: -8, height: 0 }}
          transition={{ type: "spring", stiffness: 500, damping: 30 }}
          className="text-sm text-destructive"
          role="alert"
        >
          {message}
        </motion.p>
      )}
    </AnimatePresence>
  );
}
```

### Input focus ring animation
```tsx
"use client";

import { cn } from "@/lib/utils";

function AnimatedInput({
  ref,
  className,
  ...props
}: React.InputHTMLAttributes<HTMLInputElement> & { ref?: React.Ref<HTMLInputElement> }) {
  return (
    <input
      ref={ref}
      className={cn(
        "rounded-lg border bg-transparent px-4 py-2.5 text-sm",
        "ring-offset-background transition-all duration-200",
        "focus:outline-none focus:ring-2 focus:ring-primary/40 focus:ring-offset-2",
        "focus:border-primary focus:shadow-[0_0_0_3px_oklch(0.55_0.15_270/0.08)]",
        className
      )}
      {...props}
    />
  );
}
```

### Shake on invalid submission
```tsx
"use client";

import { motion } from "motion/react";
import { useActionState } from "react";

export function ShakeForm({ action }: { action: (prev: FormState, fd: FormData) => Promise<FormState> }) {
  const [state, formAction, isPending] = useActionState(action, {});
  const hasError = state.error && Object.keys(state.error).length > 0;

  return (
    <motion.form
      action={formAction}
      animate={hasError ? { x: [0, -8, 8, -4, 4, 0] } : {}}
      transition={{ duration: 0.4 }}
    >
      {/* fields */}
    </motion.form>
  );
}
```

### Submit button with loading spinner
```tsx
"use client";

import { useFormStatus } from "react-dom";
import { motion, AnimatePresence } from "motion/react";
import { Loader2, Check } from "lucide-react";
import { Button } from "@/components/ui/button";

function SubmitButton({ label = "Submit", success }: { label?: string; success?: boolean }) {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending} className="relative min-w-[120px]">
      <AnimatePresence mode="wait">
        {success ? (
          <motion.span
            key="success"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="flex items-center gap-2 text-green-50"
          >
            <Check className="h-4 w-4" /> Done
          </motion.span>
        ) : pending ? (
          <motion.span
            key="loading"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="flex items-center gap-2"
          >
            <Loader2 className="h-4 w-4 animate-spin" /> Saving…
          </motion.span>
        ) : (
          <motion.span
            key="idle"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
          >
            {label}
          </motion.span>
        )}
      </AnimatePresence>
    </Button>
  );
}
```

### Optimistic item with enter/exit animation
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";
import { useOptimistic } from "react";

export function AnimatedTodoList({
  todos,
  addTodo,
}: {
  todos: Todo[];
  addTodo: (formData: FormData) => Promise<void>;
}) {
  const [optimisticTodos, addOptimistic] = useOptimistic(
    todos,
    (state, newTitle: string) => [
      ...state,
      { id: `temp-${Date.now()}`, title: newTitle, completed: false },
    ]
  );

  return (
    <ul className="space-y-2">
      <AnimatePresence initial={false}>
        {optimisticTodos.map((todo) => (
          <motion.li
            key={todo.id}
            initial={{ opacity: 0, height: 0, y: -10 }}
            animate={{ opacity: 1, height: "auto", y: 0 }}
            exit={{ opacity: 0, height: 0, x: -20 }}
            transition={{ type: "spring", stiffness: 400, damping: 25 }}
            className={cn(
              "rounded-lg border p-3",
              todo.id.startsWith("temp") && "opacity-60"
            )}
          >
            {todo.title}
          </motion.li>
        ))}
      </AnimatePresence>
    </ul>
  );
}
```

### Floating label input
```tsx
"use client";

import { useState } from "react";
import { cn } from "@/lib/utils";

function FloatingInput({
  label,
  name,
  type = "text",
  ...props
}: {
  label: string;
  name: string;
  type?: string;
} & React.InputHTMLAttributes<HTMLInputElement>) {
  const [focused, setFocused] = useState(false);
  const [hasValue, setHasValue] = useState(false);
  const isActive = focused || hasValue;

  return (
    <div className="relative">
      <input
        name={name}
        type={type}
        className={cn(
          "peer w-full rounded-lg border bg-transparent px-4 pb-2 pt-5 text-sm",
          "transition-all duration-200",
          "focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
        )}
        onFocus={() => setFocused(true)}
        onBlur={(e) => {
          setFocused(false);
          setHasValue(e.target.value.length > 0);
        }}
        placeholder=" "
        {...props}
      />
      <label
        className={cn(
          "pointer-events-none absolute left-4 text-muted-foreground",
          "transition-all duration-200 ease-out",
          isActive
            ? "top-1.5 text-xs text-primary"
            : "top-3.5 text-sm"
        )}
      >
        {label}
      </label>
    </div>
  );
}
```

### Success celebration
```tsx
"use client";

import { motion } from "motion/react";

function SuccessState({ message }: { message: string }) {
  return (
    <motion.div
      initial={{ scale: 0.8, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      className="flex flex-col items-center gap-3 py-8"
    >
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: "spring", stiffness: 400, damping: 10, delay: 0.1 }}
        className="flex h-16 w-16 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/30"
      >
        <motion.svg
          viewBox="0 0 24 24"
          className="h-8 w-8 text-green-600 dark:text-green-400"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={{ duration: 0.4, delay: 0.2 }}
        >
          <motion.path
            d="M5 13l4 4L19 7"
            fill="none"
            stroke="currentColor"
            strokeWidth={2.5}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </motion.svg>
      </motion.div>
      <p className="text-lg font-medium">{message}</p>
    </motion.div>
  );
}
```

## Composes With
- `react-server-actions` — forms submit to server actions
- `shadcn` — shadcn Form component provides structure
- `error-handling` — form errors shown inline, not in error boundaries
- `logging` — track form submissions and validation failures
- `accessibility` — form inputs need proper ARIA, labels, and error announcements
- `advanced-form-ux` — multi-step wizards, auto-save, conditional fields extend basic forms
- `animation` — Motion library for error, enter/exit, and success animations
- `loading-transitions` — skeleton states and transition overlays during submission
