---
name: multi-tenancy
description: >
  Multi-tenant architecture — row-level isolation, subdomain routing, Prisma Client Extension, tenant context propagation
allowed-tools: Read, Grep, Glob
---

# Multi-Tenancy

## Purpose
Multi-tenant architecture for Next.js 15 SaaS applications. Covers row-level isolation with
Prisma Client Extensions, subdomain-based tenant routing, tenant context propagation through
Server Components and Actions, and cross-tenant data prevention.

## When to Use
- Building a B2B SaaS with organization/workspace isolation
- Implementing subdomain-based tenant routing (`acme.app.com`)
- Auto-injecting tenant filters on every Prisma query
- Setting up tenant onboarding flows (create org → invite → seed)
- Preventing cross-tenant data leaks

## When NOT to Use
- Single-tenant application → no tenancy needed
- User-level permissions within a tenant → `auth`
- Feature toggling per tenant → `feature-flags`
- API key management → `security`

## Pattern

### Tenant Prisma model
```prisma
model Tenant {
  id        String   @id @default(cuid())
  name      String
  slug      String   @unique // Used for subdomain: slug.app.com
  plan      String   @default("free")
  createdAt DateTime @default(now())

  users    TenantUser[]
  projects Project[]
}

model TenantUser {
  id       String @id @default(cuid())
  tenantId String
  userId   String
  role     String @default("member") // "owner" | "admin" | "member"

  tenant Tenant @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([tenantId, userId])
  @@index([userId])
}

model Project {
  id       String @id @default(cuid())
  tenantId String
  name     String
  // ... other fields

  tenant Tenant @relation(fields: [tenantId], references: [id], onDelete: Cascade)

  @@index([tenantId])
}
```

### Prisma Client Extension for tenant isolation
```tsx
// src/lib/db-tenant.ts
import "server-only";
import { PrismaClient, Prisma } from "@prisma/client";

const basePrisma = new PrismaClient();

export function getTenantDb(tenantId: string) {
  return basePrisma.$extends({
    query: {
      $allModels: {
        async findMany({ args, query }) {
          args.where = { ...args.where, tenantId };
          return query(args);
        },
        async findFirst({ args, query }) {
          args.where = { ...args.where, tenantId };
          return query(args);
        },
        async create({ args, query }) {
          args.data = { ...args.data, tenantId } as typeof args.data;
          return query(args);
        },
        async update({ args, query }) {
          args.where = { ...args.where, tenantId } as typeof args.where;
          return query(args);
        },
        async delete({ args, query }) {
          args.where = { ...args.where, tenantId } as typeof args.where;
          return query(args);
        },
        async deleteMany({ args, query }) {
          args.where = { ...args.where, tenantId };
          return query(args);
        },
        async updateMany({ args, query }) {
          args.where = { ...args.where, tenantId };
          return query(args);
        },
      },
    },
  });
}
```

### Tenant resolution middleware
```tsx
// src/middleware.ts
import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const hostname = request.headers.get("host") ?? "";
  const subdomain = hostname.split(".")[0];

  // Skip for main domain and API routes
  if (subdomain === "www" || subdomain === "app" || hostname === "localhost:3000") {
    return NextResponse.next();
  }

  const response = NextResponse.next();
  response.headers.set("x-tenant-slug", subdomain);
  return response;
}
```

### Tenant context in Server Components
```tsx
// src/lib/tenant.ts
import "server-only";
import { headers } from "next/headers";
import { cache } from "react";
import { db } from "@/lib/db";

export const getTenant = cache(async () => {
  const headerList = await headers();
  const slug = headerList.get("x-tenant-slug");
  if (!slug) return null;

  return db.tenant.findUnique({ where: { slug } });
});

export const requireTenant = cache(async () => {
  const tenant = await getTenant();
  if (!tenant) throw new Error("Tenant not found");
  return tenant;
});
```

### Tenant-scoped Server Action
```tsx
// src/actions/projects.ts
"use server";
import { auth } from "@/lib/auth";
import { requireTenant } from "@/lib/tenant";
import { getTenantDb } from "@/lib/db-tenant";
import { z } from "zod";

const CreateProjectSchema = z.object({
  name: z.string().min(1).max(100),
});

export async function createProject(prevState: unknown, formData: FormData) {
  const session = await auth();
  if (!session?.user?.id) return { error: "Unauthorized" };

  const tenant = await requireTenant();
  const tenantDb = getTenantDb(tenant.id);

  const parsed = CreateProjectSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: "Invalid input" };

  await tenantDb.project.create({
    data: { name: parsed.data.name },
    // tenantId auto-injected by extension
  });

  return { success: true };
}
```

### Tenant onboarding flow
```tsx
// src/actions/onboarding.ts
"use server";
import { db } from "@/lib/db";
import { auth } from "@/lib/auth";

export async function createTenant(prevState: unknown, formData: FormData) {
  const session = await auth();
  if (!session?.user?.id) return { error: "Unauthorized" };

  const name = formData.get("name") as string;
  const slug = formData.get("slug") as string;

  const tenant = await db.$transaction(async (tx) => {
    const newTenant = await tx.tenant.create({
      data: { name, slug },
    });

    await tx.tenantUser.create({
      data: {
        tenantId: newTenant.id,
        userId: session.user!.id,
        role: "owner",
      },
    });

    return newTenant;
  });

  return { success: true, tenantId: tenant.id };
}
```

### Cross-tenant cache isolation
```tsx
// Always namespace cache keys with tenant ID
import { unstable_cache } from "next/cache";
import { requireTenant } from "@/lib/tenant";

export async function getTenantProjects() {
  const tenant = await requireTenant();

  return unstable_cache(
    async () => {
      const tenantDb = getTenantDb(tenant.id);
      return tenantDb.project.findMany();
    },
    [`projects-${tenant.id}`],
    { tags: [`tenant-${tenant.id}-projects`] }
  )();
}
```

## Anti-pattern

### Queries without tenant filter
Every Prisma query on tenant-scoped data MUST include `tenantId`. A single unscoped
query is a data leak vulnerability. Use Prisma Client Extensions to auto-inject the filter.

### Trusting client-sent tenant ID
Never accept `tenantId` from request body or query params. Resolve it from the
subdomain in middleware or from the authenticated session. Client-sent IDs enable
tenant impersonation.

## Common Mistakes
- Missing `tenantId` index on scoped tables — slow queries
- Not using `$transaction` for tenant onboarding — partial state on failure
- Cache keys without tenant namespace — cross-tenant cache pollution
- Forgetting to scope `deleteMany`/`updateMany` — bulk operations bypass per-record filters if not handled in the Client Extension; always add explicit handlers for these methods
- File uploads without tenant directory — shared storage leaks data

## Checklist
- [ ] Tenant model with slug for subdomain routing
- [ ] TenantUser join table with roles
- [ ] All scoped tables have `tenantId` with `@@index`
- [ ] Prisma Client Extension auto-injects tenant filter
- [ ] Middleware resolves tenant from subdomain
- [ ] `getTenant()` / `requireTenant()` cached with `React.cache()`
- [ ] Server Actions validate tenant context
- [ ] Cache keys namespaced by tenant ID
- [ ] Tenant onboarding uses `$transaction`

## Composes With
- `prisma` — tenant schema design and Client Extensions
- `nextjs-middleware` — subdomain tenant resolution
- `auth` — user-tenant role verification
- `security` — cross-tenant data leak prevention
- `feature-flags` — per-tenant feature configuration
