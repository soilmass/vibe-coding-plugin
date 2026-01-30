---
name: trpc
description: >
  tRPC end-to-end type-safe API — router setup, React Query client, server-side calls, auth middleware, subscriptions
allowed-tools: Read, Grep, Glob
---

# tRPC

## Purpose
End-to-end type-safe API layer for Next.js 15 using tRPC. Covers router setup with Zod
validation, `@trpc/react-query` client for Client Components, server-side calls in Server
Components, auth middleware, batching, and the Server Actions vs tRPC decision matrix.

## When to Use
- Building type-safe API between client and server (full-stack)
- Client Components needing data fetching with React Query
- Complex query/mutation patterns with input validation
- Real-time subscriptions
- Replacing REST API routes with type-safe RPC

## When NOT to Use
- Form submissions → `react-server-actions` (Server Actions are simpler)
- Simple data display in Server Components → direct Prisma calls
- Public API consumed by third parties → `api-routes` with OpenAPI
- One-off mutations → Server Actions

## Pattern

### tRPC router setup
```tsx
// src/server/trpc.ts
import { initTRPC, TRPCError } from "@trpc/server";
import { z } from "zod";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";

const t = initTRPC.context<{ userId: string | null }>().create();

export const router = t.router;
export const publicProcedure = t.procedure;

export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  return next({ ctx: { userId: ctx.userId } });
});
```

### App router
```tsx
// src/server/routers/app.ts
import { router, publicProcedure, protectedProcedure } from "@/server/trpc";
import { z } from "zod";
import { db } from "@/lib/db";

export const appRouter = router({
  user: router({
    me: protectedProcedure.query(async ({ ctx }) => {
      return db.user.findUnique({ where: { id: ctx.userId } });
    }),

    update: protectedProcedure
      .input(z.object({ name: z.string().min(1) }))
      .mutation(async ({ ctx, input }) => {
        return db.user.update({
          where: { id: ctx.userId },
          data: { name: input.name },
        });
      }),
  }),

  posts: router({
    list: publicProcedure
      .input(z.object({ limit: z.number().min(1).max(50).default(20) }))
      .query(async ({ input }) => {
        return db.post.findMany({ take: input.limit, orderBy: { createdAt: "desc" } });
      }),
  }),
});

export type AppRouter = typeof appRouter;
```

### Next.js route handler
```tsx
// src/app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from "@trpc/server/adapters/fetch";
import { appRouter } from "@/server/routers/app";
import { auth } from "@/lib/auth";

const handler = async (request: Request) => {
  const session = await auth();

  return fetchRequestHandler({
    endpoint: "/api/trpc",
    req: request,
    router: appRouter,
    createContext: () => ({
      userId: session?.user?.id ?? null,
    }),
  });
};

export { handler as GET, handler as POST };
```

### React Query client provider
```tsx
// src/components/providers/trpc-provider.tsx
"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { httpBatchLink } from "@trpc/client";
import { createTRPCReact } from "@trpc/react-query";
import { useState } from "react";
import type { AppRouter } from "@/server/routers/app";

export const trpc = createTRPCReact<AppRouter>();

export function TRPCProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());
  const [trpcClient] = useState(() =>
    trpc.createClient({
      links: [httpBatchLink({ url: "/api/trpc" })],
    })
  );

  return (
    <trpc.Provider client={trpcClient} queryClient={queryClient}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </trpc.Provider>
  );
}
```

### Client Component usage
```tsx
// src/components/posts/post-list.tsx
"use client";
import { trpc } from "@/components/providers/trpc-provider";

export function PostList() {
  const { data, isLoading } = trpc.posts.list.useQuery({ limit: 10 });

  if (isLoading) return <div>Loading...</div>;

  return (
    <ul>
      {data?.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  );
}
```

### Server-side tRPC calls (no HTTP)
```tsx
// src/app/posts/page.tsx (Server Component)
import { appRouter } from "@/server/routers/app";
import { auth } from "@/lib/auth";

export default async function PostsPage() {
  const session = await auth();
  const caller = appRouter.createCaller({
    userId: session?.user?.id ?? null,
  });

  // Direct call — no HTTP overhead
  const posts = await caller.posts.list({ limit: 20 });

  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  );
}
```

### tRPC vs Server Actions decision matrix
```
Use tRPC when:                   Use Server Actions when:
- React Query caching needed     - Form submissions
- Optimistic updates in lists    - Simple mutations
- Complex query patterns         - Progressive enhancement needed
- Real-time subscriptions        - No client-side state management
- Batch multiple requests        - Streaming responses with useActionState
```

## Anti-pattern

### Using tRPC for form submissions
Server Actions handle forms better with progressive enhancement (works without JS).
Use tRPC for data fetching and complex mutations that benefit from React Query caching.

### Importing server router in client code
Never import the router directly in Client Components. Use the `trpc` hook which
communicates via HTTP. Direct imports leak server code to the client bundle.

## Common Mistakes
- Missing `TRPCProvider` wrapper in layout — queries fail silently
- Importing `appRouter` in Client Components — bundle size explosion
- Not using `createCaller` in Server Components — unnecessary HTTP roundtrip
- Forgetting `httpBatchLink` — each query makes a separate request
- No error handling on mutations — use `onError` callback

## Checklist
- [ ] tRPC router with public and protected procedures
- [ ] Route handler at `/api/trpc/[trpc]`
- [ ] React Query provider with tRPC client
- [ ] Server-side calls use `createCaller` (no HTTP)
- [ ] Client Components use `trpc.*.useQuery/useMutation`
- [ ] Auth context passed to `createContext`
- [ ] Batch link configured for request batching
- [ ] Input validated with Zod on every procedure

## Composes With
- `api-routes` — tRPC route handler setup
- `prisma` — database queries in procedures
- `typescript-patterns` — end-to-end type inference
- `react-client-components` — React Query hooks in client
- `security` — auth middleware on procedures
