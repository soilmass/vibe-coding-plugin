---
name: payments
description: >
  Payments with Stripe — Checkout sessions, webhooks, subscription lifecycle, Prisma billing models, idempotency
allowed-tools: Read, Grep, Glob
---

# Payments

## Purpose
Payment integration for Next.js 15 with Stripe. Covers Checkout sessions, webhook handling,
subscription lifecycle, Prisma billing models, and idempotency. The ONE skill for billing.

## When to Use
- Adding one-time or recurring payments
- Setting up Stripe Checkout
- Handling Stripe webhooks
- Modeling billing data in Prisma
- Managing subscription lifecycle (create, update, cancel)

## When NOT to Use
- API route design → `api-routes`
- Database schema design → `prisma`
- Auth and user management → `auth`
- General security → `security`

## Pattern

### Stripe client setup
```tsx
// src/lib/stripe.ts
import Stripe from "stripe";

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2024-12-18.acacia",
  typescript: true,
});
```

### Checkout session creation (Server Action)
```tsx
// src/actions/createCheckout.ts
"use server";
import { auth } from "@/lib/auth";
import { stripe } from "@/lib/stripe";
import { redirect } from "next/navigation";

export async function createCheckout(priceId: string) {
  const session = await auth();
  if (!session?.user) return { error: "Unauthorized" };

  const checkoutSession = await stripe.checkout.sessions.create({
    customer_email: session.user.email!,
    mode: "subscription",
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/billing?success=true`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/billing?canceled=true`,
    metadata: { userId: session.user.id },
  });

  if (!checkoutSession.url) {
    return { error: "Failed to create checkout session" };
  }
  redirect(checkoutSession.url);
}
```

### Webhook handler
```tsx
// src/app/api/webhooks/stripe/route.ts
import { headers } from "next/headers";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";
import type Stripe from "stripe";

export async function POST(request: Request) {
  const body = await request.text();
  const headersList = await headers();
  const signature = headersList.get("stripe-signature")!;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch {
    return new Response("Invalid signature", { status: 400 });
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session;
      await db.user.update({
        where: { id: session.metadata!.userId },
        data: {
          stripeCustomerId: session.customer as string,
          stripeSubscriptionId: session.subscription as string,
          plan: "PRO",
        },
      });
      break;
    }
    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription;
      await db.user.update({
        where: { stripeCustomerId: subscription.customer as string },
        data: { plan: "FREE", stripeSubscriptionId: null },
      });
      break;
    }
    case "invoice.payment_failed": {
      const invoice = event.data.object as Stripe.Invoice;
      await db.user.update({
        where: { stripeCustomerId: invoice.customer as string },
        data: { plan: "PAST_DUE" },
      });
      break;
    }
  }

  return Response.json({ received: true });
}
```

### Prisma billing model
```prisma
// prisma/schema.prisma
model User {
  id                   String  @id @default(cuid())
  email                String  @unique
  plan                 Plan    @default(FREE)
  stripeCustomerId     String? @unique
  stripeSubscriptionId String? @unique
  // ... other fields
}

enum Plan {
  FREE
  PRO
  PAST_DUE
}
```

### Customer portal (manage subscription)
```tsx
// src/actions/createPortalSession.ts
"use server";
import { auth } from "@/lib/auth";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";
import { redirect } from "next/navigation";

export async function createPortalSession() {
  const session = await auth();
  if (!session?.user) return { error: "Unauthorized" };

  const user = await db.user.findUnique({ where: { id: session.user.id } });
  if (!user?.stripeCustomerId) return { error: "No billing account" };

  const portalSession = await stripe.billingPortal.sessions.create({
    customer: user.stripeCustomerId,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/billing`,
  });

  redirect(portalSession.url);
}
```

### Subscription upgrade/downgrade
```tsx
// src/actions/changeSubscription.ts
"use server";
import { auth } from "@/lib/auth";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";

export async function changeSubscription(newPriceId: string) {
  const session = await auth();
  if (!session?.user) return { error: "Unauthorized" };

  const user = await db.user.findUnique({ where: { id: session.user.id } });
  if (!user?.stripeSubscriptionId) return { error: "No active subscription" };

  const subscription = await stripe.subscriptions.retrieve(user.stripeSubscriptionId);
  await stripe.subscriptions.update(user.stripeSubscriptionId, {
    items: [{ id: subscription.items.data[0].id, price: newPriceId }],
    proration_behavior: "create_prorations", // Charge/credit difference
  });

  return { success: true };
}
```

### Failed payment recovery (webhook handler addition)
```tsx
// Add to webhook switch statement:
case "invoice.payment_failed": {
  const invoice = event.data.object as Stripe.Invoice;
  const attemptCount = invoice.attempt_count;

  await db.user.update({
    where: { stripeCustomerId: invoice.customer as string },
    data: { plan: "PAST_DUE" },
  });

  // After 3 failed attempts, downgrade to FREE
  if (attemptCount >= 3) {
    await db.user.update({
      where: { stripeCustomerId: invoice.customer as string },
      data: { plan: "FREE", stripeSubscriptionId: null },
    });
  }
  break;
}
```

### Refund handling
```tsx
// src/actions/refundPayment.ts
"use server";
export async function refundPayment(paymentIntentId: string) {
  const session = await auth();
  if (!session?.user) return { error: "Unauthorized" };

  // Always refund via Stripe API — never modify amounts manually
  const refund = await stripe.refunds.create({
    payment_intent: paymentIntentId,
    reason: "requested_by_customer",
  });

  return { success: true, refundId: refund.id };
}
```

## Anti-pattern

```tsx
// WRONG: client-side price calculation (never trust the client)
"use client";
const total = items.reduce((sum, item) => sum + item.price, 0);
await fetch("/api/charge", { body: JSON.stringify({ amount: total }) });
// Attacker can modify `total` in DevTools!

// WRONG: no webhook signature verification
export async function POST(request: Request) {
  const body = await request.json(); // No signature check!
  await db.user.update({ data: { plan: "PRO" } }); // Anyone can call this
}

// WRONG: race condition in subscription updates
// Two concurrent webhook events can overwrite each other
// Always use Stripe's subscription object as source of truth,
// not your local database state. Check event.created timestamp.

// CORRECT: always verify webhook signatures, calculate prices server-side
```

## Common Mistakes
- Calculating prices client-side — always use Stripe Price IDs server-side
- Skipping webhook signature verification — anyone can POST to your endpoint
- Not handling `invoice.payment_failed` — users stay on paid plan after failure
- Missing idempotency — webhook retries can duplicate operations
- Hardcoding prices — use Stripe Dashboard to manage prices, reference by ID
- Not using `metadata` — lose the link between Stripe and your database
- Race conditions in subscription updates — use Stripe object as source of truth
- No recovery flow for failed payments — users stuck in limbo state

## Checklist
- [ ] Prices defined in Stripe Dashboard, referenced by Price ID
- [ ] Webhook endpoint verifies `stripe-signature` header
- [ ] All webhook event types handled (completed, deleted, failed)
- [ ] Prisma model has `stripeCustomerId` and `stripeSubscriptionId`
- [ ] Customer portal configured for self-service subscription management
- [ ] `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PUBLISHABLE_KEY` in `.env.local`
- [ ] Subscription upgrades/downgrades use `proration_behavior`
- [ ] Failed payment recovery flow handles multiple retry attempts
- [ ] Webhook handler is idempotent (safe to replay events)

## Composes With
- `api-routes` — webhook route handler
- `prisma` — billing model and subscription state
- `auth` — verify user before creating checkout sessions
- `security` — webhook signature verification, server-side pricing
- `logging` — log payment events and subscription changes
