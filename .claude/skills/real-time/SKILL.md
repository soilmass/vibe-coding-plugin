---
name: real-time
description: >
  Real-time patterns — Server-Sent Events (SSE), WebSocket via Pusher/Ably, polling fallback, progress streaming for long tasks
allowed-tools: Read, Grep, Glob
---

# Real-Time

## Purpose
Real-time communication patterns for Next.js 15. Covers SSE with route handlers, WebSocket
via hosted services, and polling fallback. The ONE skill for live updates.

## When to Use
- Streaming progress for long-running tasks
- Live notifications or chat features
- Real-time dashboards or feeds
- Server-to-client push updates

## When NOT to Use
- Static data fetching → `nextjs-data`
- Form submissions → `react-server-actions`
- Periodic data refresh → `caching` with revalidation

## Pattern

### Server-Sent Events (SSE) route handler
```tsx
// app/api/events/route.ts
import { NextRequest } from "next/server";

export async function GET(request: NextRequest) {
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    async start(controller) {
      const send = (data: unknown) => {
        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify(data)}\n\n`)
        );
      };

      // Send initial connection event
      send({ type: "connected" });

      // Example: stream progress
      for (let i = 0; i <= 100; i += 10) {
        send({ type: "progress", value: i });
        await new Promise((r) => setTimeout(r, 500));
      }

      send({ type: "complete" });
      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
    },
  });
}
```

### EventSource client component
```tsx
"use client";
import { useEffect, useState } from "react";

export function ProgressStream({ taskId }: { taskId: string }) {
  const [progress, setProgress] = useState(0);
  const [status, setStatus] = useState<"connecting" | "streaming" | "done">("connecting");

  useEffect(() => {
    const source = new EventSource(`/api/events?taskId=${taskId}`);

    source.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === "progress") {
        setProgress(data.value);
        setStatus("streaming");
      }
      if (data.type === "complete") {
        setStatus("done");
        source.close();
      }
    };

    source.onerror = () => {
      // Reconnect with backoff
      source.close();
      setTimeout(() => setStatus("connecting"), 3000);
    };

    return () => source.close();
  }, [taskId]);

  return <progress value={progress} max={100} />;
}
```

### Pusher (WebSocket) integration
```tsx
// lib/pusher.ts (server)
import "server-only";
import Pusher from "pusher";

export const pusher = new Pusher({
  appId: process.env.PUSHER_APP_ID!,
  key: process.env.NEXT_PUBLIC_PUSHER_KEY!,
  secret: process.env.PUSHER_SECRET!,
  cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER!,
  useTLS: true,
});

// Trigger from Server Action
export async function notifyUser(userId: string, event: string, data: unknown) {
  await pusher.trigger(`user-${userId}`, event, data);
}
```

### SSE auth strategy
```tsx
// EventSource does NOT support custom headers.
// Workaround: pass a short-lived token via URL query parameter.
// ⚠️ Security: use a dedicated SSE token, not the session token.

// Server: generate SSE token
export async function generateSseToken(userId: string) {
  const token = crypto.randomUUID();
  await redis.set(`sse:${token}`, userId, { ex: 60 }); // 60s expiry
  return token;
}

// Server: validate in SSE route
export async function GET(request: NextRequest) {
  const token = request.nextUrl.searchParams.get("token");
  if (!token) return new Response("Unauthorized", { status: 401 });

  const userId = await redis.get(`sse:${token}`);
  if (!userId) return new Response("Unauthorized", { status: 401 });

  await redis.del(`sse:${token}`); // Single use
  // ... create SSE stream scoped to userId
}

// Client: fetch token then connect
const token = await getSseToken(); // Server Action
const source = new EventSource(`/api/events?token=${token}`);
```

## Anti-pattern

```tsx
// WRONG: WebSockets on Vercel Edge (not supported)
import { WebSocketServer } from "ws";
const wss = new WebSocketServer({ port: 8080 }); // Fails on serverless!

// WRONG: aggressive polling without backoff
setInterval(() => fetch("/api/status"), 100); // 10 req/sec = abuse
```

Vercel and similar serverless platforms don't support raw WebSocket servers.
Use hosted services (Pusher, Ably) or SSE instead. Always use exponential
backoff for polling.

## Common Mistakes
- Using raw WebSockets on serverless platforms — use SSE or Pusher
- No reconnection logic for EventSource — connections drop
- Aggressive polling without backoff — wastes resources
- Not closing EventSource on component unmount — memory leak
- Missing `Cache-Control: no-cache` on SSE responses

## Checklist
- [ ] SSE route handler sets proper headers (text/event-stream, no-cache)
- [ ] EventSource cleaned up on unmount
- [ ] Reconnection with exponential backoff on errors
- [ ] WebSocket via hosted service (Pusher/Ably) not raw `ws`
- [ ] Polling uses reasonable interval with backoff

### Premium Real-Time UI Patterns

#### Animated progress stream
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { CheckCircle, Loader2 } from "lucide-react";
import { useEffect, useState } from "react";

type Step = { label: string; status: "pending" | "active" | "done" };

export function StreamProgress({ taskId }: { taskId: string }) {
  const [steps, setSteps] = useState<Step[]>([]);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const source = new EventSource(`/api/events?taskId=${taskId}`);
    source.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === "progress") setProgress(data.value);
      if (data.type === "steps") setSteps(data.steps);
      if (data.type === "complete") source.close();
    };
    return () => source.close();
  }, [taskId]);

  return (
    <div className="space-y-4">
      {/* Animated progress bar */}
      <div className="h-2 overflow-hidden rounded-full bg-muted">
        <motion.div
          className="h-full rounded-full bg-gradient-to-r from-primary to-primary/70"
          animate={{ width: `${progress}%` }}
          transition={{ type: "spring", stiffness: 100, damping: 20 }}
        />
      </div>

      {/* Step list */}
      <div className="space-y-2">
        {steps.map((step, i) => (
          <motion.div
            key={step.label}
            initial={{ opacity: 0, x: -12 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.08, type: "spring", stiffness: 300, damping: 25 }}
            className="flex items-center gap-3"
          >
            <AnimatePresence mode="wait">
              {step.status === "done" ? (
                <motion.div key="done" initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ type: "spring", stiffness: 400, damping: 15 }}>
                  <CheckCircle className="h-5 w-5 text-green-500" />
                </motion.div>
              ) : step.status === "active" ? (
                <motion.div key="active" animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1, ease: "linear" }}>
                  <Loader2 className="h-5 w-5 text-primary" />
                </motion.div>
              ) : (
                <div className="h-5 w-5 rounded-full border-2 border-muted" />
              )}
            </AnimatePresence>
            <span className={step.status === "done" ? "text-sm text-muted-foreground line-through" : "text-sm font-medium"}>
              {step.label}
            </span>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
```

#### Connection status indicator
```tsx
"use client";
import { motion } from "motion/react";

export function ConnectionDot({ status }: { status: "connected" | "connecting" | "disconnected" }) {
  const colors = {
    connected: "bg-green-500",
    connecting: "bg-amber-500",
    disconnected: "bg-red-500",
  };

  return (
    <div className="flex items-center gap-2">
      <span className="relative flex h-2.5 w-2.5">
        {status === "connected" && (
          <motion.span
            className="absolute inline-flex h-full w-full rounded-full bg-green-400"
            animate={{ scale: [1, 1.5, 1], opacity: [0.75, 0, 0.75] }}
            transition={{ repeat: Infinity, duration: 2, ease: "easeInOut" }}
          />
        )}
        {status === "connecting" && (
          <motion.span
            className="absolute inline-flex h-full w-full rounded-full bg-amber-400"
            animate={{ opacity: [1, 0.3, 1] }}
            transition={{ repeat: Infinity, duration: 1 }}
          />
        )}
        <span className={`relative inline-flex h-2.5 w-2.5 rounded-full ${colors[status]}`} />
      </span>
      <span className="text-xs text-muted-foreground capitalize">{status}</span>
    </div>
  );
}
```

#### Live data pulse effect
```tsx
"use client";
import { motion, useMotionValue, useTransform, animate } from "motion/react";
import { useEffect } from "react";

export function LiveCounter({ value, label }: { value: number; label: string }) {
  const motionValue = useMotionValue(0);
  const rounded = useTransform(motionValue, (v) => Math.round(v).toLocaleString());

  useEffect(() => {
    animate(motionValue, value, { type: "spring", stiffness: 100, damping: 20 });
  }, [value, motionValue]);

  return (
    <div className="relative flex flex-col items-center">
      {/* Pulse ring on update */}
      <motion.div
        key={value}
        initial={{ scale: 0.8, opacity: 0.6 }}
        animate={{ scale: 1.6, opacity: 0 }}
        transition={{ duration: 0.6 }}
        className="absolute inset-0 rounded-xl border-2 border-primary"
      />
      <motion.span className="text-3xl font-bold tabular-nums">{rounded}</motion.span>
      <span className="text-xs text-muted-foreground">{label}</span>
    </div>
  );
}
```

#### Reconnection toast with backoff
```tsx
"use client";
import { toast } from "sonner";

export function handleReconnection(attempt: number, maxAttempts = 5) {
  const delay = Math.min(1000 * 2 ** attempt, 30000); // Exponential backoff, max 30s

  if (attempt >= maxAttempts) {
    toast.error("Connection lost", {
      description: "Unable to reconnect. Please refresh the page.",
      duration: Infinity,
      action: { label: "Refresh", onClick: () => window.location.reload() },
    });
    return;
  }

  toast.loading(`Reconnecting in ${delay / 1000}s...`, {
    id: "reconnect",
    duration: delay,
  });
}
```

#### Streaming text with typewriter
```tsx
"use client";
import { motion } from "motion/react";
import { useEffect, useState } from "react";

export function StreamingText({ text }: { text: string }) {
  const [displayed, setDisplayed] = useState("");

  useEffect(() => {
    setDisplayed("");
    let i = 0;
    const interval = setInterval(() => {
      if (i < text.length) {
        setDisplayed(text.slice(0, i + 1));
        i++;
      } else {
        clearInterval(interval);
      }
    }, 20);
    return () => clearInterval(interval);
  }, [text]);

  return (
    <p className="text-sm">
      {displayed}
      <motion.span
        animate={{ opacity: [1, 0] }}
        transition={{ repeat: Infinity, duration: 0.8 }}
        className="inline-block h-4 w-0.5 bg-foreground align-middle"
      />
    </p>
  );
}
```

## Composes With
- `api-routes` — SSE endpoints are route handlers
- `react-client-components` — EventSource runs in client components
- `performance` — avoid aggressive polling that wastes bandwidth
- `state-management` — real-time data updates client state
- `logging` — log connection lifecycle events
- `error-handling` — handle connection failures and reconnection
- `rate-limiting` — throttle connection attempts and message rates
- `animation` — progress streams, connection status, live data pulses
- `notifications` — real-time notification delivery
