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
