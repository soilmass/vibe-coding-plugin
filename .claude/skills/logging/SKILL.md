---
name: logging
description: >
  Structured logging with Pino — request ID propagation, error tracking with Sentry, log levels, server-side only
allowed-tools: Read, Grep, Glob
---

# Logging

## Purpose
Structured logging for Next.js 15 with Pino. Covers request ID propagation, error tracking
with Sentry, log levels, and Vercel Analytics integration. The ONE skill for observability.

## When to Use
- Setting up structured logging (replacing `console.log`)
- Integrating error tracking with Sentry
- Adding request ID propagation across server components
- Configuring log levels for different environments

## When NOT to Use
- Error boundaries and error.tsx → `error-handling`
- Deployment and hosting config → `deploy`
- API route design → `api-routes`

## Pattern

### Pino logger setup
```tsx
// src/lib/logger.ts
import pino from "pino";

export const logger = pino({
  level: process.env.LOG_LEVEL ?? (process.env.NODE_ENV === "production" ? "info" : "debug"),
  transport:
    process.env.NODE_ENV !== "production"
      ? { target: "pino-pretty", options: { colorize: true } }
      : undefined,
  base: {
    env: process.env.NODE_ENV,
    revision: process.env.VERCEL_GIT_COMMIT_SHA,
  },
});
```

### Request ID propagation
```tsx
// src/middleware.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { randomUUID } from "crypto";

export function middleware(request: NextRequest) {
  const requestId = request.headers.get("x-request-id") ?? randomUUID();
  const response = NextResponse.next();
  response.headers.set("x-request-id", requestId);
  return response;
}
```

### Logging in Server Actions
```tsx
// src/actions/createPost.ts
"use server";
import { logger } from "@/lib/logger";
import { headers } from "next/headers";

export async function createPost(prevState: ActionState, formData: FormData) {
  const headersList = await headers();
  const requestId = headersList.get("x-request-id");
  const log = logger.child({ requestId, action: "createPost" });

  const session = await auth();
  if (!session) {
    log.warn("Unauthorized action attempt");
    return { error: { _form: ["Unauthorized"] } };
  }

  try {
    const post = await db.post.create({ data: parsed.data });
    log.info({ postId: post.id }, "Post created");
    return { success: true };
  } catch (error) {
    log.error({ error }, "Failed to create post");
    return { error: { _form: ["Failed to create post"] } };
  }
}
```

### Sentry error tracking
```tsx
// sentry.server.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: process.env.NODE_ENV === "production" ? 0.1 : 1.0,
  environment: process.env.NODE_ENV,
});
```

```tsx
// src/app/global-error.tsx
"use client";
import * as Sentry from "@sentry/nextjs";
import { useEffect } from "react";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html>
      <body>
        <h2>Something went wrong!</h2>
        <button onClick={reset}>Try again</button>
      </body>
    </html>
  );
}
```

### Logging in API routes
```tsx
// src/app/api/webhooks/route.ts
import { logger } from "@/lib/logger";

export async function POST(request: Request) {
  const log = logger.child({ route: "webhooks" });

  try {
    const body = await request.json();
    log.info({ event: body.type }, "Webhook received");
    // ... process webhook
    return Response.json({ received: true });
  } catch (error) {
    log.error({ error }, "Webhook processing failed");
    return Response.json({ error: "Processing failed" }, { status: 500 });
  }
}
```

### Correlation ID pattern (trace requests across services)
```tsx
// src/lib/logger.ts — add correlation ID to all child loggers
export function createRequestLogger(requestId: string, context: Record<string, unknown> = {}) {
  return logger.child({ requestId, ...context });
}

// Usage in Server Action:
const log = createRequestLogger(requestId, { action: "createPost", userId: session.user.id });
// All logs from this request share the same requestId for correlation
```

### Log sampling for high-volume routes
```tsx
// src/lib/logger.ts
export function sampledLog(log: pino.Logger, rate: number = 0.1) {
  return {
    info: (obj: object, msg: string) => {
      if (Math.random() < rate) log.info(obj, msg);
    },
    // Always log errors and warns at full rate
    error: log.error.bind(log),
    warn: log.warn.bind(log),
  };
}

// Usage: only log 10% of health check requests
const slog = sampledLog(log, 0.1);
slog.info({ path: "/api/health" }, "Health check");
```

### Structured JSON logging for production
```tsx
// Pino outputs JSON by default in production (no transport configured).
// Example output:
// {"level":30,"time":1706000000,"requestId":"abc-123","action":"createPost","msg":"Post created"}
// This JSON format is compatible with log aggregation tools (DataDog, Grafana, etc.)

// Log retention policy note:
// - Development: stdout only (no retention)
// - Production: ship to log aggregation with 30-day retention minimum
// - Errors: retain 90+ days for debugging and compliance
```

## Anti-pattern

```tsx
// WRONG: console.log in production (no structure, no levels, no correlation)
export async function createPost(formData: FormData) {
  console.log("creating post...");       // No structure
  console.log("user:", session.user);    // May leak PII
  console.log("error:", error);          // No level, no context
}

// WRONG: logging sensitive data
log.info({ password: formData.get("password") }, "Login attempt");
log.info({ creditCard: data.card }, "Payment processed");

// WRONG: logging noise without sampling
// Logging every single health check, static asset, or favicon request
// floods logs and makes finding real issues harder. Sample high-volume routes.

// CORRECT: structured, leveled, no sensitive data
log.info({ userId: session.user.id }, "Post created");
log.error({ error: error.message, postId }, "Post creation failed");
```

## Common Mistakes
- Using `console.log` in production — no structure, levels, or correlation
- Logging sensitive data (passwords, tokens, PII) — sanitize all log output
- Logging on the client side — logs are visible in browser DevTools
- Not propagating request IDs — can't trace requests across components
- Setting `tracesSampleRate: 1.0` in production — too expensive, use 0.1
- Not using child loggers — lose context about which action/route logged
- Logging everything without sampling — noise drowns out real issues

## Checklist
- [ ] Pino logger configured with environment-based log levels
- [ ] Request IDs propagated via middleware headers
- [ ] Server Actions use child loggers with context
- [ ] Sentry initialized for error tracking in production
- [ ] No sensitive data in log output
- [ ] `console.log` replaced with structured logger in all server code
- [ ] `SENTRY_DSN` in `.env.local` for error tracking
- [ ] High-volume routes use log sampling
- [ ] Log retention policy defined (30-day min, 90-day for errors)

## Composes With
- `error-handling` — log errors before returning error states
- `deploy` — configure log aggregation in production
- `api-routes` — structured logging in route handlers
- `prisma` — log slow queries and database errors
- `auth` — log authentication attempts and failures
- `payments` — log payment events and subscription changes
- `background-jobs` — logging in async handlers
