---
name: auth
description: >
  Auth.js v5 setup — providers (GitHub, Google, Credentials), session handling, protected routes, middleware guards, Prisma adapter
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(npm install *)
---

# Auth

## Purpose
Auth.js v5 authentication setup for Next.js 15. Covers provider configuration, session access,
route protection, and Prisma adapter. The ONE skill for authentication.

## Project State
- Has Auth.js: !`[ -f "src/lib/auth.ts" ] && echo "yes" || echo "no"`
- Has Prisma adapter: !`grep -q "@auth/prisma-adapter" package.json 2>/dev/null && echo "yes" || echo "no"`

## When to Use
- Adding authentication to a Next.js project
- Configuring OAuth providers (GitHub, Google)
- Protecting routes with middleware
- Accessing session data in Server Components

## When NOT to Use
- Authorization logic (role checks) → `security`
- Login/signup form UI → `react-forms`
- API route auth headers → `api-routes`

## Pattern

### Auth.js configuration
```tsx
// src/lib/auth.ts
import NextAuth from "next-auth";
import GitHub from "next-auth/providers/github";
import Google from "next-auth/providers/google";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { db } from "@/lib/db";

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(db),
  providers: [GitHub, Google],
  callbacks: {
    session({ session, user }) {
      session.user.id = user.id;
      return session;
    },
  },
});
```

### Route handler
```tsx
// src/app/api/auth/[...nextauth]/route.ts
import { handlers } from "@/lib/auth";
export const { GET, POST } = handlers;
```

### Middleware protection
```tsx
// src/middleware.ts
import { auth } from "@/lib/auth";

export default auth((req) => {
  if (!req.auth && req.nextUrl.pathname !== "/login") {
    return Response.redirect(new URL("/login", req.url));
  }
});

export const config = {
  matcher: ["/((?!api/auth|_next/static|_next/image|favicon.ico).*)"],
};
```

### Session in Server Component
```tsx
import { auth } from "@/lib/auth";

export default async function Page() {
  const session = await auth();
  if (!session?.user) redirect("/login");
  return <div>Welcome, {session.user.name}</div>;
}
```

### TypeScript session type extension
```tsx
// src/types/next-auth.d.ts
import { DefaultSession } from "next-auth";

declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      role: string;
    } & DefaultSession["user"];
  }
}
```

## Anti-pattern

```tsx
// WRONG: checking auth in client component with useEffect
"use client";
function ProtectedPage() {
  const [user, setUser] = useState(null);
  useEffect(() => {
    fetch("/api/auth/session").then(r => r.json()).then(setUser);
    // Waterfall! Flash of unauthenticated content!
  }, []);
}
```

Use middleware for route protection and `auth()` in Server Components.
Client-side session checks cause waterfalls and flash of wrong content.

## Common Mistakes
- Not setting `AUTH_SECRET` environment variable
- Missing catch-all route `[...nextauth]/route.ts`
- Checking auth in `useEffect` instead of middleware/Server Components
- Forgetting to extend session type with user ID
- Not adding Prisma adapter tables to schema

## Checklist
- [ ] `AUTH_SECRET` set in environment variables
- [ ] Catch-all auth route handler exists
- [ ] Middleware protects authenticated routes
- [ ] Session callback includes user ID
- [ ] Prisma adapter schema includes User, Account, Session tables

## Composes With
- `prisma` — Prisma adapter stores users and sessions
- `security` — auth provides identity, security enforces authorization
- `nextjs-middleware` — middleware handles route protection
- `payments` — billing requires authenticated users
- `logging` — log authentication attempts and failures
