---
name: observability
description: >
  OpenTelemetry tracing, health check endpoints, circuit breakers, graceful degradation for production Next.js 15
allowed-tools: Read, Grep, Glob
---

# Observability

## Purpose
Production observability for Next.js 15 with OpenTelemetry tracing, health/readiness endpoints,
circuit breakers, and graceful degradation. Extends the `logging` skill with distributed tracing
and resilience patterns.

## When to Use
- Setting up OpenTelemetry SDK with exporters (Vercel, Datadog, Grafana)
- Adding `/api/health` (liveness) and `/api/ready` (readiness) endpoints
- Implementing trace propagation across Server Components, Actions, and Prisma
- Adding circuit breakers for external service calls
- Configuring retry with exponential backoff

## When NOT to Use
- Basic structured logging → `logging`
- Error boundaries and error.tsx → `error-handling`
- Vercel Analytics / PostHog tracking → `analytics`
- Performance profiling and bundle analysis → `performance`

## Pattern

### OpenTelemetry SDK setup
```tsx
// src/lib/tracing.ts
import "server-only";
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
import { Resource } from "@opentelemetry/resources";
import { ATTR_SERVICE_NAME } from "@opentelemetry/semantic-conventions";

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME ?? "next-app",
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

### Instrumentation file
```tsx
// instrumentation.ts (root — Next.js auto-loads this)
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("./src/lib/tracing");
  }
}
```

### Health check endpoint (liveness)
```tsx
// src/app/api/health/route.ts
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({ status: "ok", timestamp: Date.now() });
}
```

### Readiness check endpoint
```tsx
// src/app/api/ready/route.ts
import { NextResponse } from "next/server";
import { db } from "@/lib/db";

let cachedStatus: { ok: boolean; checkedAt: number } | null = null;
const CACHE_TTL = 10_000; // 10 seconds

async function checkDependencies() {
  const now = Date.now();
  if (cachedStatus && now - cachedStatus.checkedAt < CACHE_TTL) {
    return cachedStatus.ok;
  }

  try {
    await db.$queryRaw`SELECT 1`;
    cachedStatus = { ok: true, checkedAt: now };
    return true;
  } catch {
    cachedStatus = { ok: false, checkedAt: now };
    return false;
  }
}

export async function GET() {
  const dbReady = await checkDependencies();

  if (!dbReady) {
    return NextResponse.json(
      { status: "not_ready", db: "down" },
      { status: 503 }
    );
  }

  return NextResponse.json({ status: "ready", db: "up" });
}
```

### Trace ID correlation with logger
```tsx
// In Server Actions or route handlers
import { trace, context } from "@opentelemetry/api";
import { logger } from "@/lib/logger";

export async function myAction(formData: FormData) {
  const span = trace.getActiveSpan();
  const traceId = span?.spanContext().traceId;
  const log = logger.child({ traceId });

  log.info("Action started");
  // ... business logic
  log.info("Action completed");
}
```

### Custom span instrumentation
```tsx
import { trace } from "@opentelemetry/api";
import { after } from "next/server";

const tracer = trace.getTracer("app");

export async function fetchExternalData(userId: string) {
  return tracer.startActiveSpan("fetchExternalData", async (span) => {
    span.setAttribute("user.id", userId);
    try {
      const data = await fetch("https://api.example.com/data", {
        signal: AbortSignal.timeout(5000),
      });
      span.setAttribute("http.status_code", data.status);
      return data.json();
    } catch (error) {
      span.recordException(error as Error);
      span.setAttribute("error.type", (error as Error).name);
      throw error;
    } finally {
      span.end();
    }
  });
}
```

### Custom metrics (counters, gauges, histograms)
```tsx
// src/lib/metrics.ts
import "server-only";
import { metrics } from "@opentelemetry/api";

const meter = metrics.getMeter("app");

export const httpRequestDuration = meter.createHistogram("http.request.duration", {
  description: "HTTP request duration in milliseconds",
  unit: "ms",
});

export const activeConnections = meter.createUpDownCounter("db.connections.active", {
  description: "Number of active database connections",
});

export const ordersCreated = meter.createCounter("orders.created", {
  description: "Total number of orders created",
});

// Usage in Server Action
export async function createOrder(formData: FormData) {
  const start = Date.now();
  try {
    // ... order logic
    ordersCreated.add(1, { plan: "pro" });
  } finally {
    httpRequestDuration.record(Date.now() - start, { route: "/api/orders" });
  }
}
```

### Circuit breaker pattern
```tsx
// src/lib/circuit-breaker.ts
import CircuitBreaker from "opossum";
import { logger } from "@/lib/logger";

export function createBreaker<T>(
  fn: (...args: unknown[]) => Promise<T>,
  options?: Partial<CircuitBreaker.Options>
) {
  const breaker = new CircuitBreaker(fn, {
    timeout: 5000,
    errorThresholdPercentage: 50,
    resetTimeout: 30000,
    ...options,
  });

  breaker.on("open", () => logger.warn("Circuit breaker opened"));
  breaker.on("halfOpen", () => logger.info("Circuit breaker half-open"));
  breaker.on("close", () => logger.info("Circuit breaker closed"));

  return breaker;
}
```

### Retry with exponential backoff
```tsx
// src/lib/retry.ts
import pRetry from "p-retry";

export async function withRetry<T>(
  fn: () => Promise<T>,
  options?: { retries?: number; label?: string }
) {
  return pRetry(fn, {
    retries: options?.retries ?? 3,
    onFailedAttempt: (error) => {
      logger.warn({
        msg: `Retry attempt ${error.attemptNumber} for ${options?.label}`,
        retriesLeft: error.retriesLeft,
      });
    },
  });
}
```

### Graceful degradation
```tsx
// Fallback when external service is unavailable
const paymentBreaker = createBreaker(processPayment);

export async function checkout(orderId: string) {
  try {
    return await paymentBreaker.fire(orderId);
  } catch {
    // Fallback: queue for retry instead of failing
    await queuePaymentRetry(orderId);
    return { status: "queued", message: "Payment will be processed shortly" };
  }
}
```

## Anti-pattern

### Tracing everything
Don't add spans to every function — high cardinality kills performance.
Trace boundaries: HTTP handlers, Server Actions, database queries, external APIs.
Internal utility functions don't need individual spans.

### Health check hitting DB on every request
Cache health status with a TTL. Kubernetes probes hit health endpoints frequently —
an uncached check creates unnecessary database load.

### No timeout on external calls
Always use `AbortSignal.timeout()` or set explicit timeouts. Hanging requests
consume server resources and eventually cascade into failures.

## Common Mistakes
- Forgetting `instrumentation.ts` — Next.js won't auto-load tracing without it
- Tracing in Edge Runtime — OpenTelemetry Node SDK doesn't work in Edge
- Not setting `OTEL_EXPORTER_OTLP_ENDPOINT` — traces go nowhere
- Health check returning 200 when DB is down — defeats the purpose
- No fallback for circuit breaker — open circuit throws instead of degrading gracefully

## Checklist
- [ ] `instrumentation.ts` exists at project root
- [ ] OpenTelemetry SDK configured with OTLP exporter
- [ ] `/api/health` returns liveness status
- [ ] `/api/ready` checks database and returns readiness
- [ ] External API calls have `AbortSignal.timeout()`
- [ ] Circuit breaker wraps non-critical external services
- [ ] Trace IDs correlate with Pino logger
- [ ] `after()` used for non-blocking span export where needed

## Composes With
- `logging` — trace ID correlation with Pino structured logs
- `prisma` — trace database queries via auto-instrumentation
- `api-routes` — instrument route handlers with spans
- `deploy` — health endpoints for Kubernetes/Vercel probes
- `error-handling` — error spans with attributes
- `performance` — tracing identifies slow paths
