---
name: analytics
description: >
  Analytics and event tracking — Vercel Analytics, SpeedInsights, PostHog client/server tracking, custom events, privacy-compliant patterns
allowed-tools: Read, Grep, Glob
---

# Analytics

## Purpose
Analytics and event tracking for Next.js 15. Covers Vercel Analytics, SpeedInsights, PostHog
integration, and privacy-compliant tracking patterns. The ONE skill for product analytics.

## When to Use
- Adding page view and web vitals tracking
- Implementing custom event tracking (signups, purchases)
- Setting up PostHog for product analytics
- Server-side event tracking in Server Actions

## When NOT to Use
- Performance profiling → `performance`
- Error tracking → `logging`
- SEO metrics → `seo-advanced`

## Pattern

### Vercel Analytics + SpeedInsights
```tsx
// app/layout.tsx
import { Analytics } from "@vercel/analytics/react";
import { SpeedInsights } from "@vercel/speed-insights/next";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
```

### PostHog client provider
```tsx
// components/analytics/PostHogProvider.tsx
"use client";
import posthog from "posthog-js";
import { PostHogProvider as PHProvider } from "posthog-js/react";
import { useEffect } from "react";

export function PostHogProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
      api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST!,
      capture_pageview: true,
      capture_pageleave: true,
    });
  }, []);

  return <PHProvider client={posthog}>{children}</PHProvider>;
}
```

### Custom event hook
```tsx
// hooks/useTrack.ts
"use client";
import posthog from "posthog-js";

// Event naming convention: noun.verb (e.g., "checkout.completed")
export function useTrack() {
  return (event: string, properties?: Record<string, unknown>) => {
    posthog.capture(event, properties);
  };
}
```

### Server-side tracking in Server Actions
```tsx
"use server";
import { PostHog } from "posthog-node";

// Server-side: use non-public env vars
const posthog = new PostHog(process.env.POSTHOG_API_KEY!, {
  host: process.env.POSTHOG_HOST!,
});

export async function createOrder(formData: FormData) {
  const session = await auth();
  // ... create order logic

  posthog.capture({
    distinctId: session!.user.id,
    event: "order.created",
    properties: { amount: order.total },
  });

  await posthog.flush(); // Flush before response
}
```

### Event taxonomy

Use `noun.verb` naming for all events. Define a typed event map with discriminated unions to
catch typos at compile time and enforce consistent property shapes.

```ts
// lib/analytics/events.ts

type AnalyticsEvent =
  | { event: "user.signed_up"; properties: { method: "email" | "google" | "github" } }
  | { event: "user.logged_in"; properties: { method: "email" | "google" | "github" } }
  | { event: "user.deleted_account"; properties: { reason?: string } }
  | { event: "cart.item_added"; properties: { productId: string; price: number; quantity: number } }
  | { event: "cart.item_removed"; properties: { productId: string } }
  | { event: "checkout.started"; properties: { cartTotal: number; itemCount: number } }
  | { event: "checkout.completed"; properties: { orderId: string; total: number; currency: string } }
  | { event: "checkout.abandoned"; properties: { cartTotal: number; step: string } }
  | { event: "page.viewed"; properties: { path: string; referrer?: string } }
  | { event: "feature.used"; properties: { name: string; variant?: string } };

// Type-safe capture function — compile error on unknown events or wrong properties
export function trackEvent<E extends AnalyticsEvent["event"]>(
  event: E,
  properties: Extract<AnalyticsEvent, { event: E }>["properties"],
) {
  // Implementation swapped by environment (client vs server)
  if (typeof window !== "undefined") {
    const posthog = (await import("posthog-js")).default;
    posthog.capture(event, properties);
  }
}
```

Usage in a client component:

```tsx
"use client";
import { trackEvent } from "@/lib/analytics/events";

export function AddToCartButton({ productId, price }: { productId: string; price: number }) {
  return (
    <button
      onClick={() => {
        // Type-safe — wrong property names or types cause compile errors
        trackEvent("cart.item_added", { productId, price, quantity: 1 });
      }}
    >
      Add to Cart
    </button>
  );
}
```

Naming rules:
- **Nouns**: `user`, `cart`, `checkout`, `page`, `feature`, `subscription`, `invoice`
- **Verbs**: `signed_up`, `logged_in`, `created`, `completed`, `viewed`, `clicked`, `failed`
- Always lowercase, snake_case after the dot: `checkout.payment_failed`, not `Checkout.PaymentFailed`
- Prefix internal/debug events with `debug.` to filter them in dashboards

### Consent-gated tracking

Never fire analytics events before the user grants consent. Integrate with a consent
store that the cookie banner writes to.

```ts
// lib/analytics/consent.ts
import { create } from "zustand";

type ConsentCategory = "necessary" | "analytics" | "marketing";

type ConsentState = {
  categories: Record<ConsentCategory, boolean>;
  setConsent: (categories: Record<ConsentCategory, boolean>) => void;
  hasConsent: (category: ConsentCategory) => boolean;
};

export const useConsentStore = create<ConsentState>((set, get) => ({
  categories: { necessary: true, analytics: false, marketing: false },
  setConsent: (categories) => set({ categories }),
  hasConsent: (category) => get().categories[category],
}));
```

Wrap the analytics provider so it only initializes after consent:

```tsx
// components/analytics/ConsentGatedAnalytics.tsx
"use client";
import posthog from "posthog-js";
import { PostHogProvider } from "posthog-js/react";
import { useEffect, useState } from "react";
import { useConsentStore } from "@/lib/analytics/consent";

export function ConsentGatedAnalytics({ children }: { children: React.ReactNode }) {
  const hasConsent = useConsentStore((s) => s.hasConsent);
  const [initialized, setInitialized] = useState(false);

  useEffect(() => {
    if (hasConsent("analytics") && !initialized) {
      posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
        api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST!,
        capture_pageview: true,
        persistence: "localStorage+cookie",
        opt_out_capturing_by_default: false,
      });
      setInitialized(true);
    }

    if (!hasConsent("analytics") && initialized) {
      posthog.opt_out_capturing();
    }
  }, [hasConsent, initialized]);

  if (!initialized) return <>{children}</>;
  return <PostHogProvider client={posthog}>{children}</PostHogProvider>;
}
```

Guard individual tracking calls as well for defense-in-depth:

```ts
// lib/analytics/track.ts
import posthog from "posthog-js";
import { useConsentStore } from "@/lib/analytics/consent";

export function safeCapture(event: string, properties?: Record<string, unknown>) {
  if (useConsentStore.getState().hasConsent("analytics")) {
    posthog.capture(event, properties);
  }
}
```

### Server-side tracking with after()

Use the Next.js `after()` hook to fire server-side analytics without blocking the
response. This is preferred over `await posthog.flush()` for non-critical tracking.

```tsx
// actions/checkout.ts
"use server";
import { after } from "next/server";
import { PostHog } from "posthog-node";
import { auth } from "@/lib/auth";
import { revalidateTag } from "next/cache";

const posthog = new PostHog(process.env.POSTHOG_API_KEY!, {
  host: process.env.POSTHOG_HOST!,
  flushAt: 1,        // Flush immediately in serverless
  flushInterval: 0,  // No batching delay
});

export async function completeCheckout(formData: FormData) {
  const session = await auth();
  if (!session) throw new Error("Unauthorized");

  const order = await db.order.create({ /* ... */ });

  revalidateTag("orders");

  // Fire-and-forget: runs AFTER the response is sent to the client
  after(async () => {
    posthog.capture({
      distinctId: session.user.id,
      event: "checkout.completed",
      properties: {
        orderId: order.id,
        total: order.total,
        currency: order.currency,
        itemCount: order.items.length,
      },
    });
    await posthog.flush();
  });

  return { success: true, orderId: order.id };
}
```

Use `after()` in Route Handlers too:

```tsx
// app/api/webhooks/stripe/route.ts
import { after } from "next/server";
import { PostHog } from "posthog-node";

const posthog = new PostHog(process.env.POSTHOG_API_KEY!, {
  host: process.env.POSTHOG_HOST!,
});

export async function POST(request: Request) {
  const event = await verifyStripeWebhook(request);

  // Process webhook synchronously
  await handleStripeEvent(event);

  // Track asynchronously — does not delay the 200 response to Stripe
  after(async () => {
    posthog.capture({
      distinctId: event.data.object.customer as string,
      event: "subscription.renewed",
      properties: {
        plan: event.data.object.plan.id,
        amount: event.data.object.amount_paid,
      },
    });
    await posthog.flush();
  });

  return Response.json({ received: true });
}
```

When to use `after()` vs `await flush()`:
- **`after()`** — default choice. Non-blocking, runs after response. Best for analytics, logging, notifications.
- **`await flush()`** — only when the event MUST be confirmed sent before the response (e.g., billing audit trail where data loss is unacceptable).

## Anti-pattern

```tsx
// WRONG: tracking PII without consent
posthog.capture("form.submitted", {
  email: user.email,       // PII — needs consent!
  creditCard: card.last4,  // Never track financial data
});

// WRONG: blocking render on analytics init
const analytics = await initAnalytics(); // Blocks first paint!
```

Never track PII without user consent. Never block rendering on analytics initialization.
Use event naming conventions (noun.verb) for consistent analytics data.

## Common Mistakes
- Tracking PII without consent — violates GDPR/CCPA
- Blocking render on analytics initialization — degrades performance
- No event naming convention — inconsistent data makes analysis hard
- Client-only tracking — misses server-side events (webhooks, cron)
- Not flushing server-side PostHog — events lost on serverless

## Checklist
- [ ] Analytics provider in root layout (non-blocking)
- [ ] Event naming follows noun.verb convention
- [ ] No PII tracked without explicit consent
- [ ] Server-side events flush before response ends
- [ ] PostHog environment variables configured

## Composes With
- `performance` — SpeedInsights tracks web vitals alongside analytics
- `react-client-components` — tracking hooks run in client components
- `react-server-actions` — server-side event capture in mutations
- `security` — privacy-compliant tracking respects user consent
