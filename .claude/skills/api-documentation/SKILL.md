---
name: api-documentation
description: >
  OpenAPI 3.1 from Zod schemas, Swagger UI, API versioning, TypeScript client SDK generation
allowed-tools: Read, Grep, Glob
---

# API Documentation

## Purpose
Auto-generated API documentation for Next.js 15 using Zod schemas as the single source of truth.
Generates OpenAPI 3.1 specs, serves Swagger UI, supports path-based versioning, and enables
TypeScript client SDK generation.

## When to Use
- Generating OpenAPI specs from existing Zod validation schemas
- Setting up Swagger UI at `/api/docs`
- Implementing API versioning (`/api/v1/`, `/api/v2/`)
- Generating TypeScript client SDKs from OpenAPI specs
- Documenting authentication requirements per endpoint

## When NOT to Use
- API route implementation → `api-routes`
- Server Action design → `react-server-actions`
- Auth flow implementation → `auth`
- Rate limiting → `rate-limiting`

## Pattern

### Zod to OpenAPI registry
```tsx
// src/lib/openapi.ts
import "server-only";
import {
  OpenAPIRegistry,
  OpenApiGeneratorV31,
} from "@asteasolutions/zod-to-openapi";
import { z } from "zod";

export const registry = new OpenAPIRegistry();

// Register schemas
export const UserSchema = registry.register(
  "User",
  z.object({
    id: z.string().cuid(),
    name: z.string(),
    email: z.string().email(),
    createdAt: z.string().datetime(),
  })
);

export const ErrorSchema = registry.register(
  "Error",
  z.object({
    error: z.string(),
    code: z.string().optional(),
  })
);
```

### Register API endpoints
```tsx
// src/lib/openapi.ts (continued)
registry.registerPath({
  method: "get",
  path: "/api/v1/users",
  description: "List all users with pagination",
  tags: ["Users"],
  request: {
    query: z.object({
      page: z.coerce.number().min(1).default(1),
      limit: z.coerce.number().min(1).max(100).default(20),
    }),
  },
  responses: {
    200: {
      description: "Paginated list of users",
      content: {
        "application/json": {
          schema: z.object({
            data: z.array(UserSchema),
            total: z.number(),
            page: z.number(),
          }),
        },
      },
    },
    401: {
      description: "Unauthorized",
      content: {
        "application/json": { schema: ErrorSchema },
      },
    },
  },
  security: [{ bearerAuth: [] }],
});
```

### Generate OpenAPI spec
```tsx
// src/app/api/docs/openapi.json/route.ts
import { OpenApiGeneratorV31 } from "@asteasolutions/zod-to-openapi";
import { registry } from "@/lib/openapi";

export async function GET() {
  const generator = new OpenApiGeneratorV31(registry.definitions);
  const spec = generator.generateDocument({
    openapi: "3.1.0",
    info: {
      title: "My API",
      version: "1.0.0",
      description: "API documentation auto-generated from Zod schemas",
    },
    servers: [{ url: process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000" }],
    security: [{ bearerAuth: [] }],
  });

  return Response.json(spec);
}
```

### Swagger UI page
```tsx
// src/app/api/docs/page.tsx
"use client";
import SwaggerUI from "swagger-ui-react";
import "swagger-ui-react/swagger-ui.css";

export default function ApiDocsPage() {
  return (
    <div className="min-h-screen">
      <SwaggerUI url="/api/docs/openapi.json" />
    </div>
  );
}
```

### API versioning via route groups
```
src/app/api/
├── v1/
│   └── users/
│       └── route.ts    # GET /api/v1/users
├── v2/
│   └── users/
│       └── route.ts    # GET /api/v2/users (new response shape)
└── docs/
    ├── page.tsx         # Swagger UI
    └── openapi.json/
        └── route.ts     # OpenAPI spec
```

### TypeScript client generation
```bash
# Generate types from OpenAPI spec
npx openapi-typescript http://localhost:3000/api/docs/openapi.json -o src/types/api.d.ts
```

```tsx
// src/lib/api-client.ts
import createClient from "openapi-fetch";
import type { paths } from "@/types/api";

export const api = createClient<paths>({
  baseUrl: process.env.NEXT_PUBLIC_APP_URL,
});

// Usage — fully type-safe
const { data, error } = await api.GET("/api/v1/users", {
  params: { query: { page: 1, limit: 20 } },
});
```

### Deprecation annotations
```tsx
registry.registerPath({
  method: "get",
  path: "/api/v1/users/{id}",
  deprecated: true,
  description: "Deprecated — use GET /api/v2/users/{id} instead. Sunset: 2025-06-01",
  // ...
});
```

## Anti-pattern

### Manually maintaining API docs
Never write OpenAPI specs by hand. Always generate from Zod schemas that are already
used for validation. Single source of truth prevents docs from drifting from reality.

### Versioning via query params
Don't use `?v=2` for API versioning. Use path-based versioning (`/api/v1/`, `/api/v2/`)
which is clearer, easier to route, and works with OpenAPI specs.

### No deprecation strategy
When introducing v2, mark v1 endpoints as deprecated with a sunset date. Clients need
migration time. Use the `deprecated: true` flag in OpenAPI.

## Common Mistakes
- Forgetting to register new endpoints in the OpenAPI registry
- Using `swagger-ui-react` without `"use client"` — it's a client component
- Not re-generating TypeScript types after schema changes
- Missing error response documentation — document 4xx/5xx shapes
- No auth documentation — each endpoint should specify its auth requirements

## Checklist
- [ ] Zod schemas registered with `@asteasolutions/zod-to-openapi`
- [ ] All public API routes have OpenAPI definitions
- [ ] Swagger UI accessible at `/api/docs`
- [ ] API versioning uses path-based strategy (`/v1/`)
- [ ] TypeScript client types auto-generated from spec
- [ ] Error responses documented with schemas
- [ ] Auth requirements specified per endpoint
- [ ] Deprecated endpoints marked with sunset dates

## Composes With
- `api-routes` — route handler implementation
- `react-server-actions` — Server Action documentation
- `typescript-patterns` — generated type-safe clients
- `security` — auth documentation in OpenAPI spec
