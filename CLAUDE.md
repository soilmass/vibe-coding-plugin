# Project Architecture Rules

## Stack
- **Framework**: Next.js 15 (App Router)
- **UI**: React 19
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS v4 (CSS-first config)
- **Components**: shadcn/ui
- **Database**: Prisma 7 (PostgreSQL)
- **Auth**: Auth.js v5
- **Testing**: Vitest (unit) + Playwright (E2E)

## Component Model

### Default to Server Components
All components are Server Components unless they need interactivity. Only add `"use client"` when the component uses:
- Event handlers (onClick, onChange, onSubmit)
- React hooks (useState, useEffect, useRef, etc.)
- Browser APIs (window, document, localStorage)

### Use `useActionState`, NOT `useFormState`
`useFormState` is deprecated. Always use `useActionState` from `react` (not `react-dom`).

### Ref as Prop (No forwardRef)
React 19 supports ref as a regular prop. Do NOT use `forwardRef`.

```tsx
// CORRECT
function Input({ ref, ...props }: { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />;
}

// WRONG — don't use forwardRef
const Input = forwardRef<HTMLInputElement>((props, ref) => { ... });
```

## File Conventions (App Router)

```
src/
├── app/                  # Routes (page.tsx, layout.tsx, loading.tsx, error.tsx)
│   ├── (marketing)/      # Route groups — organize without affecting URL
│   ├── @modal/           # Parallel routes — simultaneous rendering slots
│   └── (.)photo/[id]/    # Intercepting routes — modal over current page
├── components/
│   ├── ui/               # shadcn/ui components
│   └── [feature]/        # Feature-specific components
├── lib/                  # Utilities (db.ts, auth.ts, utils.ts)
├── actions/              # Server Actions
├── types/                # TypeScript type definitions
└── hooks/                # Client-side custom hooks
```

## Data Fetching Rules

1. **Fetch in Server Components** — not in useEffect
2. **Use `React.cache()`** for request deduplication across components
3. **Use `Promise.all()`** for parallel independent fetches
4. **No `useEffect` for data loading** — this is a client-side waterfall anti-pattern
5. **Explicit caching** — `fetch()` is NOT cached by default in Next.js 15

## Styling Rules

1. **Tailwind v4** — use `@theme {}` for design tokens, NOT `tailwind.config.js`
2. **`cn()` helper** — always use for conditional class merging
3. **No CSS Modules** — use Tailwind utilities
4. **`@import "tailwindcss"`** — replaces `@tailwind` directives

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Components | PascalCase | `UserProfile.tsx` |
| Utilities | camelCase | `formatDate.ts` |
| Routes | kebab-case | `user-settings/page.tsx` |
| Server Actions | camelCase | `createTodo.ts` |
| Types | PascalCase | `UserProfile` |
| CSS variables | kebab-case | `--color-brand` |

## DO NOT

- Use Pages Router patterns (`getServerSideProps`, `getStaticProps`)
- Use `useFormState` (deprecated — use `useActionState`)
- Use `forwardRef` (use ref as prop)
- Use default exports for non-page components
- Put API keys or secrets in source code
- Use `useEffect` for data fetching
- Use `tailwind.config.js` (use `@theme {}` in CSS)
- Add `"use client"` to layout files
- Skip input validation in Server Actions
- Use `fetch()` without explicit caching strategy
- Destructure `params` or `searchParams` before awaiting (they're Promises in Next.js 15)
- Use `redirect()` inside try/catch (it throws `NEXT_REDIRECT`, not a real error)
- Use `any` type (use `unknown` + narrowing instead)
- Use `Image` without `width`/`height` or `fill` prop
- Commit `.env.local` or `.env*.local` files
- Use `cookies()` or `headers()` in client components
- Use `revalidatePath()` when `revalidateTag()` would be more precise
- Catch errors broadly in Server Actions — catch specific errors only
- Use `<form>` without explicit `action` prop (use Server Action binding)
- Forget `after()` for fire-and-forget telemetry/logging work
- Deploy without health check endpoints
- Store PII in application logs
- Track users before cookie consent

## Common Code Patterns

### Server Action Pattern

```tsx
"use server";
import { z } from "zod";
import { auth } from "@/lib/auth";
import { revalidatePath } from "next/cache";

const Schema = z.object({ /* ... */ });

type ActionState = {
  success?: boolean;
  error?: Record<string, string[]>;
};

export async function myAction(
  prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const session = await auth();
  if (!session) return { error: { _form: ["Unauthorized"] } };

  const parsed = Schema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten().fieldErrors };

  await db.model.create({ data: parsed.data });
  revalidatePath("/path");
  return { success: true };
}
```

### Client Form Pattern

```tsx
"use client";
import { useActionState, useOptimistic } from "react";
import { useFormStatus } from "react-dom";

function SubmitButton() {
  const { pending } = useFormStatus();
  return <button disabled={pending}>{pending ? "..." : "Submit"}</button>;
}

export function MyForm() {
  const [state, formAction, isPending] = useActionState(myAction, {});
  return (
    <form action={formAction}>
      {/* inputs */}
      <SubmitButton />
    </form>
  );
}
```

### Async Page Pattern (Next.js 15)

```tsx
export default async function Page({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params; // Must await!
  const data = await getData(id);
  return <div>{data.title}</div>;
}
```

### useTransition Pattern (non-form async)

```tsx
"use client";
import { useTransition } from "react";

export function SearchFilter({ onFilter }: { onFilter: (q: string) => Promise<void> }) {
  const [isPending, startTransition] = useTransition();
  return (
    <input
      onChange={(e) => startTransition(() => onFilter(e.target.value))}
      disabled={isPending}
    />
  );
}
```

### after() Hook Pattern (post-response work)

```tsx
import { after } from "next/server";

export async function POST(request: Request) {
  const data = await request.json();
  // Handle request...
  after(async () => {
    await analytics.track("api.called", { endpoint: "/api/foo" });
  });
  return Response.json({ success: true });
}
```

### revalidateTag Pattern (granular cache invalidation)

```tsx
// Fetching with tags
const data = await fetch(url, { next: { tags: ["posts"] } });

// Invalidating by tag (in Server Action)
import { revalidateTag } from "next/cache";
revalidateTag("posts"); // More granular than revalidatePath
```

### server-only Guard

```tsx
import "server-only"; // Throws build error if imported in client component
```
