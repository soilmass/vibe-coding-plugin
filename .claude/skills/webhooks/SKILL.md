---
name: webhooks
description: >
  Webhook receiving patterns — HMAC signature verification, idempotency table, retry safety, raw body parsing, async processing
allowed-tools: Read, Grep, Glob
---

# Webhooks

## Purpose
Generic webhook receiving patterns for Next.js 15. Covers signature verification, idempotency,
retry safety, and async processing via queue. The ONE skill for incoming webhooks.

## When to Use
- Receiving webhooks from Stripe, GitHub, Clerk, Resend
- Implementing HMAC signature verification
- Building idempotent webhook handlers
- Processing webhook payloads asynchronously

## When NOT to Use
- Outgoing HTTP requests → `api-routes`
- Payment-specific logic → `payments`
- Background job processing → `background-jobs`

## Pattern

### Route handler with signature verification
```tsx
// app/api/webhooks/stripe/route.ts
import { NextRequest, NextResponse } from "next/server";
import { headers } from "next/headers";
import Stripe from "stripe";
import { db } from "@/lib/db";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(request: NextRequest) {
  // 0. Enforce payload size limit (1MB)
  const contentLength = request.headers.get("content-length");
  if (contentLength && parseInt(contentLength) > 1_048_576) {
    return NextResponse.json({ error: "Payload too large" }, { status: 413 });
  }

  // 1. Get raw body BEFORE parsing JSON
  const body = await request.text();
  const headersList = await headers();
  const signature = headersList.get("stripe-signature")!;

  // 2. Verify signature
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch {
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  // 3. Idempotency check
  const existing = await db.webhookEvent.findUnique({
    where: { eventId: event.id },
  });
  if (existing) {
    return NextResponse.json({ received: true }); // Already processed
  }

  // 4. Store event for idempotency
  await db.webhookEvent.create({
    data: { eventId: event.id, type: event.type, payload: body },
  });

  // 5. Process (or queue for async processing)
  switch (event.type) {
    case "checkout.session.completed":
      // Handle payment success
      break;
  }

  return NextResponse.json({ received: true });
}
```

### Generic HMAC verification helper
```tsx
// lib/webhook-verify.ts
import "server-only";
import { createHmac, timingSafeEqual } from "crypto";

export function verifyHmacSignature(
  payload: string,
  signature: string,
  secret: string,
  algorithm = "sha256"
): boolean {
  const expected = createHmac(algorithm, secret)
    .update(payload)
    .digest("hex");
  return timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected)
  );
}
```

### Prisma idempotency model
```prisma
model WebhookEvent {
  id        String   @id @default(cuid())
  eventId   String   @unique
  type      String
  payload   String
  createdAt DateTime @default(now())

  @@index([eventId])
}
```

## Anti-pattern

```tsx
// WRONG: parsing JSON before verifying signature
export async function POST(request: NextRequest) {
  const data = await request.json(); // Signature verification needs raw body!
  // Can't verify signature anymore — raw body is consumed
}
```

Always read the raw body with `request.text()` first, then verify the signature,
then parse JSON. Consuming the body as JSON loses the raw bytes needed for HMAC.

## Common Mistakes
- Parsing JSON before signature verification — use `request.text()` first
- No idempotency — webhook retries cause duplicate processing
- Synchronous heavy processing — blocks response, causes timeout retries
- Using `JSON.parse` timing for signature comparison — use `timingSafeEqual`
- Missing webhook event model for deduplication

## Checklist
- [ ] Raw body read with `request.text()` before signature verification
- [ ] HMAC signature verified with timing-safe comparison
- [ ] Idempotency table prevents duplicate processing
- [ ] Heavy processing queued asynchronously
- [ ] Payload size limit enforced
- [ ] Webhook secret stored in environment variable

## Composes With
- `payments` — Stripe webhook handling for payment events
- `api-routes` — webhooks are route handlers with special requirements
- `security` — signature verification prevents spoofed events
- `background-jobs` — queue heavy webhook processing asynchronously
- `logging` — log webhook events for debugging and audit trails
