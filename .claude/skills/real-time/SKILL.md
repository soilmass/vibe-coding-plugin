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

## Composes With
- `api-routes` — SSE endpoints are route handlers
- `react-client-components` — EventSource runs in client components
- `performance` — avoid aggressive polling that wastes bandwidth
- `state-management` — real-time data updates client state
- `logging` — log connection lifecycle events
- `error-handling` — handle connection failures and reconnection
