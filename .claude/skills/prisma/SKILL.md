---
name: prisma
description: >
  Prisma 7 ORM setup — schema design, migrations, TypedSQL, client extensions, singleton pattern, Next.js integration
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(npx prisma *)
---

# Prisma

## Purpose
Prisma ORM setup, schema design, and Next.js integration. Covers migrations, client singleton,
and query patterns. The ONE skill for database operations.

## Project State
- Has Prisma: !`[ -d "prisma" ] && echo "yes" || echo "no"`
- Schema exists: !`[ -f "prisma/schema.prisma" ] && echo "yes" || echo "no"`

## When to Use
- Setting up Prisma in a Next.js project
- Designing or modifying database schema
- Running migrations
- Writing type-safe database queries

## When NOT to Use
- Caching Prisma queries → `caching`
- Direct SQL queries → use Prisma TypedSQL
- Authentication schema → `auth` (creates user/session tables)

## Pattern

### Client singleton (prevent hot-reload connection exhaustion)
```tsx
// src/lib/db.ts
import "server-only";
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const db = globalForPrisma.prisma || new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = db;
```

### Schema example
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

### Migration workflow
```bash
npx prisma migrate dev --name init      # Development
npx prisma migrate deploy               # Production
npx prisma generate                     # Regenerate client
npx prisma db push                      # Prototype (no migration file)
```

### Connection pooling config (PgBouncer)
```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL") // For migrations (bypasses PgBouncer)
}
```
```tsx
// src/lib/db.ts — configure pool size
export const db = globalForPrisma.prisma || new PrismaClient({
  datasources: {
    db: { url: process.env.DATABASE_URL },
  },
  // Connection pool: default is (num_cpus * 2) + 1
  // For serverless, keep low (2-5) to avoid exhausting PgBouncer
});
```

### @@index strategy for filtered/sorted columns
```prisma
model Post {
  id        String   @id @default(cuid())
  title     String
  published Boolean  @default(false)
  authorId  String
  createdAt DateTime @default(now())
  author    User     @relation(fields: [authorId], references: [id])

  @@index([authorId])                   // Filter by author
  @@index([published, createdAt])       // Filter + sort combo
  @@index([authorId, published])        // Compound filter
}
```

### select vs include for performance
```tsx
// WRONG: include loads entire relation
const posts = await db.post.findMany({
  include: { author: true }, // Loads ALL author fields
});

// CORRECT: select only needed fields
const posts = await db.post.findMany({
  select: {
    id: true,
    title: true,
    author: { select: { name: true } }, // Only load name
  },
});
```

### Batch operations pattern
```tsx
// WRONG: N+1 — querying in a loop
for (const id of ids) {
  await db.post.update({ where: { id }, data: { published: true } });
}

// CORRECT: batch update
await db.post.updateMany({
  where: { id: { in: ids } },
  data: { published: true },
});

// CORRECT: transaction for related operations
await db.$transaction([
  db.post.deleteMany({ where: { authorId: userId } }),
  db.user.delete({ where: { id: userId } }),
]);
```

### Soft-delete pattern with Prisma Client Extension
```tsx
// Auto-filter soft-deleted records across all queries
const db = new PrismaClient().$extends({
  query: {
    $allModels: {
      async findMany({ args, query }) {
        args.where = { ...args.where, deletedAt: null };
        return query(args);
      },
      async findFirst({ args, query }) {
        args.where = { ...args.where, deletedAt: null };
        return query(args);
      },
    },
  },
});
```

```prisma
// Add deletedAt to soft-deletable models
model Post {
  id        String    @id @default(cuid())
  title     String
  deletedAt DateTime? // null = active, timestamp = soft-deleted

  @@index([deletedAt])
}
```

## Anti-pattern

```tsx
// WRONG: creating new PrismaClient per request
export async function GET() {
  const prisma = new PrismaClient(); // Connection pool exhausted!
  const users = await prisma.user.findMany();
  return NextResponse.json(users);
}

// WRONG: N+1 queries in loops
const users = await db.user.findMany();
for (const user of users) {
  const posts = await db.post.findMany({ where: { authorId: user.id } });
  // This runs N+1 queries — 1 for users + N for posts
}

// CORRECT: use include or separate findMany with `in` filter
const users = await db.user.findMany({ include: { posts: true } });
```

Every `new PrismaClient()` opens a new connection pool. In dev with hot reload,
this quickly exhausts database connections. Always use the singleton.

## Common Mistakes
- Creating PrismaClient per request — use singleton pattern
- Forgetting `server-only` import on db.ts — leaks to client bundle
- Not running `prisma generate` after schema changes
- Using `db push` in production — use `migrate deploy` instead
- Missing `@updatedAt` on timestamp fields
- N+1 queries in loops — use `include`, `in`, or batch operations
- Missing `@@index` on filtered/sorted columns — causes sequential scans
- Using `include` when `select` would be more efficient

## Checklist
- [ ] Singleton client in `src/lib/db.ts` with `server-only`
- [ ] Schema has proper relations and indexes
- [ ] Migrations committed to version control
- [ ] `prisma generate` runs after schema changes
- [ ] Environment variable `DATABASE_URL` configured
- [ ] `@@index` on columns used in `where` and `orderBy`
- [ ] `select` used instead of `include` when only specific fields needed
- [ ] Batch operations used instead of loops for bulk updates
- [ ] Connection pool sized for deployment target (serverless vs long-running)

## Composes With
- `caching` — wrap queries in `unstable_cache` for caching
- `auth` — Auth.js Prisma adapter creates user/session tables
- `scaffold` — Prisma setup follows initial project creation
- `payments` — billing models and subscription data stored in Prisma
- `logging` — log slow queries and database errors
- `performance` — query optimization affects page load times
- `multi-tenancy` — tenant-scoped Client Extensions
