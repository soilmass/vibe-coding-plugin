---
name: error-handling
description: >
  Next.js 15 App Router error boundaries — error.tsx, global-error.tsx, not-found.tsx, reset recovery, redirect/notFound throw semantics
allowed-tools: Read, Grep, Glob
---

# Error Handling

## Purpose
Error boundary patterns for Next.js 15 App Router. Covers `error.tsx`, `global-error.tsx`,
`not-found.tsx`, and recovery via `reset()`. The ONE skill for runtime error UI.

## When to Use
- Adding error boundaries to route segments
- Implementing 404 / not-found pages
- Handling runtime errors with recovery UI
- Debugging why `redirect()` or `notFound()` throws unexpectedly

## When NOT to Use
- Form validation errors → `react-forms`
- Server Action error responses → `react-server-actions`
- API route error responses → `api-routes`

## Pattern

### error.tsx (must be "use client")
```tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <p>{error.message}</p>
      <button onClick={() => reset()}>Try again</button>
    </div>
  );
}
```

### global-error.tsx (must include html/body)
```tsx
"use client";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body>
        <h2>Something went wrong</h2>
        <button onClick={() => reset()}>Try again</button>
      </body>
    </html>
  );
}
```

### not-found.tsx
```tsx
import Link from "next/link";

export default function NotFound() {
  return (
    <div>
      <h2>Not Found</h2>
      <Link href="/">Go home</Link>
    </div>
  );
}
```

### Suspense error recovery pattern
```tsx
"use client";
import { useTransition } from "react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const [isPending, startTransition] = useTransition();

  return (
    <div role="alert">
      <h2>Something went wrong</h2>
      <p>{error.digest ? `Error ID: ${error.digest}` : error.message}</p>
      <button
        onClick={() => startTransition(() => reset())}
        disabled={isPending}
      >
        {isPending ? "Retrying..." : "Try again"}
      </button>
    </div>
  );
}
```

### Retry with exponential backoff helper
```tsx
// src/lib/retry.ts
export async function withRetry<T>(
  fn: () => Promise<T>,
  options: { maxAttempts?: number; baseDelay?: number } = {},
): Promise<T> {
  const { maxAttempts = 3, baseDelay = 1000 } = options;
  let lastError: unknown;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt < maxAttempts - 1) {
        const delay = baseDelay * Math.pow(2, attempt); // 1s, 2s, 4s
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }
  throw lastError;
}

// Usage:
const data = await withRetry(() => fetch("https://api.example.com/data"));
```

### Async Server Component error handling
When an async Server Component throws, the nearest `error.tsx` boundary catches it.
`error.tsx` must be `"use client"`. Use `notFound()` to trigger `not-found.tsx` instead.

```tsx
// Async Server Component — throw triggers nearest error.tsx
export default async function PostPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const post = await db.post.findUnique({ where: { id } });

  if (!post) notFound(); // Triggers not-found.tsx (NOT error.tsx)

  return <article>{post.title}</article>;
  // If db.post.findUnique throws → nearest error.tsx catches it
}
```

## Anti-pattern

```tsx
// WRONG: wrapping redirect() in try-catch
async function loadPage(id: string) {
  try {
    const data = await getData(id);
    if (!data) redirect("/404"); // throws NEXT_REDIRECT — NOT a real error
  } catch (e) {
    // This catches the redirect throw, breaking navigation!
    console.error(e);
  }
}

// WRONG: catching redirect/revalidate in Server Actions
export async function updatePost(formData: FormData) {
  try {
    await db.post.update({ ... });
    revalidateTag("posts"); // throws NEXT_REVALIDATE internally
    redirect("/posts");     // throws NEXT_REDIRECT
  } catch (e) {
    // Catches BOTH the revalidate and redirect throws!
    // Move redirect() outside try-catch or re-throw non-errors
  }
}

// CORRECT: catch only specific errors, let framework throws propagate
export async function updatePost(formData: FormData) {
  try {
    await db.post.update({ ... });
  } catch (e) {
    return { error: "Update failed" };
  }
  revalidateTag("posts"); // Outside try-catch
  redirect("/posts");     // Outside try-catch
}
```

`redirect()` and `notFound()` work by throwing special errors. Wrapping them in
try-catch intercepts the throw and prevents Next.js from handling it.
`notFound()` throws `NEXT_NOT_FOUND` — same semantics.

## Common Mistakes
- Forgetting `"use client"` on `error.tsx` — it MUST be a Client Component
- Missing `global-error.tsx` — root layout errors have no boundary without it
- Wrapping `redirect()` in try-catch — it throws `NEXT_REDIRECT`, not a real error
- Wrapping `notFound()` in try-catch — same issue, throws `NEXT_NOT_FOUND`
- Not providing `reset()` button — users get stuck on error screens
- Catching `revalidateTag`/`redirect` in Server Action try-catch blocks
- Broad error catching — catch specific errors, not all errors

## Checklist
- [ ] `error.tsx` has `"use client"` directive
- [ ] `global-error.tsx` includes `<html>` and `<body>` tags
- [ ] `not-found.tsx` exists for custom 404 pages
- [ ] `redirect()` and `notFound()` are NOT inside try-catch
- [ ] Error UI provides `reset()` recovery action
- [ ] External API calls use retry with exponential backoff
- [ ] Error messages show `digest` ID (not stack traces) in production

### Empty state patterns
```tsx
// Zero-data UI with icon, description, and CTA
import { FileQuestion } from "lucide-react";
import { Button } from "@/components/ui/button";

export function EmptyState({
  icon: Icon = FileQuestion,
  title,
  description,
  action,
}: {
  icon?: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
  action?: { label: string; href: string };
}) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <Icon className="h-12 w-12 text-muted-foreground/50" />
      <h3 className="mt-4 text-lg font-semibold">{title}</h3>
      <p className="mt-2 text-sm text-muted-foreground">{description}</p>
      {action && (
        <Button asChild className="mt-4">
          <a href={action.href}>{action.label}</a>
        </Button>
      )}
    </div>
  );
}

// Conditional rendering when query returns empty
export default async function ProjectsPage() {
  const projects = await db.project.findMany({ where: { userId } });

  if (projects.length === 0) {
    return (
      <EmptyState
        title="No projects yet"
        description="Get started by creating your first project."
        action={{ label: "Create project", href: "/projects/new" }}
      />
    );
  }

  return <ProjectList projects={projects} />;
}
```

### Error recovery UX
```tsx
"use client";

import { useTransition } from "react";
import { Button } from "@/components/ui/button";
import { AlertCircle, RefreshCw, Home, Mail } from "lucide-react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const [isPending, startTransition] = useTransition();

  return (
    <div className="flex flex-col items-center justify-center py-16 text-center" role="alert">
      <AlertCircle className="h-12 w-12 text-destructive" />
      <h2 className="mt-4 text-lg font-semibold">Something went wrong</h2>
      <p className="mt-2 max-w-md text-sm text-muted-foreground">
        {error.digest
          ? `An unexpected error occurred. Reference: ${error.digest}`
          : error.message}
      </p>

      <div className="mt-6 flex gap-3">
        <Button
          onClick={() => startTransition(() => reset())}
          disabled={isPending}
        >
          <RefreshCw className="mr-2 h-4 w-4" />
          {isPending ? "Retrying..." : "Try again"}
        </Button>
        <Button variant="outline" asChild>
          <a href="/"><Home className="mr-2 h-4 w-4" /> Go home</a>
        </Button>
        <Button variant="ghost" asChild>
          <a href="mailto:support@example.com"><Mail className="mr-2 h-4 w-4" /> Contact support</a>
        </Button>
      </div>
    </div>
  );
}

// 401/403 redirect pattern
export default async function ProtectedPage() {
  const session = await auth();
  if (!session) redirect("/login?callbackUrl=/protected");
  if (session.user.role !== "admin") {
    return (
      <div className="py-16 text-center">
        <h2 className="text-lg font-semibold">Access Denied</h2>
        <p className="mt-2 text-muted-foreground">
          You don't have permission to view this page.
        </p>
        <Button asChild className="mt-4">
          <a href="/dashboard">Return to dashboard</a>
        </Button>
      </div>
    );
  }
  return <AdminPanel />;
}
```

### Error UX copy rules
```tsx
// Error messages include fix/next step, not just the problem
// WRONG:
<p>Invalid email</p>
// CORRECT:
<p>Enter a valid email like name@example.com</p>

// WRONG:
<p>Password too short</p>
// CORRECT:
<p>Password must be at least 8 characters</p>

// WRONG:
<p>Upload failed</p>
// CORRECT:
<p>Upload failed. Check your connection and try again.</p>

// Specific button labels — not generic
// WRONG:
<button>Submit</button>
<button>Continue</button>
<button>OK</button>

// CORRECT:
<button>Save API Key</button>
<button>Create Project</button>
<button>Confirm Deletion</button>

// Destructive actions need confirmation or undo — never immediate
// Option 1: Confirmation modal
<AlertDialog>
  <AlertDialogTrigger asChild>
    <Button variant="destructive">Delete Project</Button>
  </AlertDialogTrigger>
  <AlertDialogContent>
    <AlertDialogTitle>Delete "My Project"?</AlertDialogTitle>
    <AlertDialogDescription>
      This action cannot be undone. All data will be permanently deleted.
    </AlertDialogDescription>
    <AlertDialogAction onClick={handleDelete}>Delete Project</AlertDialogAction>
    <AlertDialogCancel>Cancel</AlertDialogCancel>
  </AlertDialogContent>
</AlertDialog>

// Option 2: Undo window (better UX for reversible actions)
function handleDelete(id: string) {
  const item = optimisticallyRemove(id);
  toast("Item deleted", {
    action: { label: "Undo", onClick: () => restore(item) },
    duration: 5000,
  });
  // Actually delete after undo window expires
  setTimeout(() => permanentlyDelete(id), 5000);
}
```

## Composes With
- `nextjs-routing` — error files are route segment conventions
- `react-suspense` — Suspense boundaries handle loading, error boundaries handle failures
- `security` — error messages should not leak sensitive details
- `logging` — errors should be logged for debugging and monitoring
- `shadcn` — Button, icons for error recovery UI
