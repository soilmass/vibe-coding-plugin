---
name: react-server-actions
description: >
  React 19 Server Actions — "use server" directive, Zod validation, auth checks, revalidation, error handling, FormData processing
allowed-tools: Read, Grep, Glob
---

# React Server Actions

## Purpose
Server Action patterns for React 19 and Next.js 15. Covers the `"use server"` directive,
validation, auth, and revalidation. The ONE skill for server-side mutations.

## When to Use
- Processing form submissions on the server
- Mutating database data from React components
- Implementing create/update/delete operations
- Triggering cache revalidation after mutations

## When NOT to Use
- Client-side form UI → `react-forms`
- Read-only data fetching → `nextjs-data`
- External API endpoints → `api-routes`

## Pattern

### Complete Server Action
```tsx
// src/actions/createPost.ts
"use server";

import { z } from "zod";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { revalidatePath } from "next/cache";

const CreatePostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
});

type ActionState = {
  success?: boolean;
  error?: Record<string, string[]>;
};

export async function createPost(
  prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  // 1. Auth check
  const session = await auth();
  if (!session?.user) {
    return { error: { _form: ["Unauthorized"] } };
  }

  // 2. Validate input
  const parsed = CreatePostSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
  });

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors };
  }

  // 3. Mutate database
  await db.post.create({
    data: { ...parsed.data, authorId: session.user.id },
  });

  // 4. Revalidate cache
  revalidatePath("/posts");
  return { success: true };
}
```

### Inline Server Action
```tsx
export default async function Page() {
  async function deletePost(formData: FormData) {
    "use server";
    const id = formData.get("id") as string;
    await db.post.delete({ where: { id } });
    revalidatePath("/posts");
  }

  return (
    <form action={deletePost}>
      <input type="hidden" name="id" value="123" />
      <button type="submit">Delete</button>
    </form>
  );
}
```

### Error classification pattern
```tsx
// src/lib/action-errors.ts
type ErrorCategory = "validation" | "auth" | "external" | "system";

export function classifyError(error: unknown): {
  category: ErrorCategory;
  message: string;
} {
  if (error instanceof z.ZodError) {
    return { category: "validation", message: "Invalid input" };
  }
  if (error instanceof AuthError) {
    return { category: "auth", message: "Authentication required" };
  }
  if (error instanceof FetchError || error instanceof TimeoutError) {
    return { category: "external", message: "Service temporarily unavailable" };
  }
  return { category: "system", message: "Something went wrong" };
}

// Usage in Server Action
export async function myAction(prevState: ActionState, formData: FormData) {
  try {
    // ... action logic
  } catch (error) {
    const { category, message } = classifyError(error);
    if (category === "system") logger.error(error); // Only log unexpected errors
    return { error: { _form: [message] } };
  }
}
```

### redirect/revalidate OUTSIDE try-catch
```tsx
"use server";

export async function updatePost(
  prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const session = await auth();
  if (!session?.user) return { error: { _form: ["Unauthorized"] } };

  const parsed = UpdatePostSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten().fieldErrors };

  try {
    await db.post.update({
      where: { id: parsed.data.id, authorId: session.user.id },
      data: parsed.data,
    });
  } catch (e) {
    return { error: { _form: ["Update failed"] } };
  }

  // redirect() throws NEXT_REDIRECT internally — if inside try-catch,
  // the catch block intercepts it and navigation breaks silently.
  // revalidateTag() throws NEXT_REVALIDATE — same issue.
  revalidateTag("posts");
  redirect("/posts");
}
```

## Anti-pattern

```tsx
// WRONG: no validation or auth in Server Action
"use server";

export async function updateUser(formData: FormData) {
  const name = formData.get("name") as string;
  // No auth check — anyone can call this!
  // No input validation — SQL injection risk!
  await db.user.update({
    where: { id: formData.get("id") as string },
    data: { name },
  });
}
```

Server Actions are public HTTP endpoints. Always validate input and check auth.

## Common Mistakes
- Skipping auth checks — Server Actions are publicly accessible endpoints
- No Zod validation — trusting FormData directly
- Using `redirect()` inside try-catch — it throws NEXT_REDIRECT
- Forgetting `revalidatePath`/`revalidateTag` — stale data after mutation
- Returning sensitive error details to client

## Checklist
- [ ] `"use server"` directive at top of file or function
- [ ] Auth check before any mutation
- [ ] Zod schema validates all FormData inputs
- [ ] `revalidatePath` or `revalidateTag` after mutation
- [ ] Error state returned, not thrown (for form error display)

## Composes With
- `react-forms` — forms provide the UI, actions process the data
- `prisma` — actions call Prisma for database mutations
- `caching` — actions trigger cache revalidation
