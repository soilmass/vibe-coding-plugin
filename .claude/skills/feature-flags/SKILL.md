---
name: feature-flags
description: >
  Feature flags with Vercel Edge Config, LaunchDarkly SDK, A/B testing with PostHog, gradual rollouts
allowed-tools: Read, Grep, Glob
---

# Feature Flags

## Purpose
Feature flag management for Next.js 15 with Vercel Edge Config for zero-latency reads,
LaunchDarkly server SDK for complex targeting, and PostHog integration for A/B testing.
Enables gradual rollouts and safe feature deployment.

## When to Use
- Implementing feature toggles for gradual rollout
- A/B testing with variant assignment
- Route-level feature gating in middleware
- Percentage-based or user-segment targeting
- Managing feature lifecycle (create → test → rollout → cleanup)

## When NOT to Use
- Environment-specific config → `env-validation`
- Auth-based access control → `auth`
- Per-tenant configuration → `multi-tenancy`
- Runtime app settings UI → custom admin panel

## Pattern

### Vercel Edge Config (zero-latency flags)
```tsx
// src/lib/feature-flags.ts
import "server-only";
import { get } from "@vercel/edge-config";
import { z } from "zod";

const FlagSchema = z.object({
  newDashboard: z.boolean().default(false),
  checkoutVersion: z.enum(["v1", "v2", "v3"]).default("v1"),
  maxUploadSize: z.number().default(10),
});

type Flags = z.infer<typeof FlagSchema>;

export async function getFlag<K extends keyof Flags>(key: K): Promise<Flags[K]> {
  const value = await get(key);
  const parsed = FlagSchema.shape[key].safeParse(value);
  return parsed.success ? (parsed.data as Flags[K]) : FlagSchema.shape[key].parse(undefined);
}

export async function getAllFlags(): Promise<Flags> {
  const raw = await get("flags");
  return FlagSchema.parse(raw ?? {});
}
```

### Server Component conditional rendering
```tsx
// src/app/dashboard/page.tsx
import { getFlag } from "@/lib/feature-flags";

export default async function DashboardPage() {
  const useNewDashboard = await getFlag("newDashboard");

  if (useNewDashboard) {
    return <NewDashboard />;
  }
  return <LegacyDashboard />;
}
```

### Middleware route gating
```tsx
// src/middleware.ts
import { get } from "@vercel/edge-config";
import { NextResponse, type NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith("/beta")) {
    const betaEnabled = await get("betaEnabled");
    if (!betaEnabled) {
      return NextResponse.redirect(new URL("/", request.url));
    }
  }
  return NextResponse.next();
}
```

### LaunchDarkly server SDK
```tsx
// src/lib/launchdarkly.ts
import "server-only";
import * as ld from "@launchdarkly/node-server-sdk";

let client: ld.LDClient;

export async function getLDClient() {
  if (!client) {
    client = ld.init(process.env.LAUNCHDARKLY_SDK_KEY!);
    await client.waitForInitialization({ timeout: 5 });
  }
  return client;
}

export async function getVariation<T>(
  flagKey: string,
  userId: string,
  defaultValue: T
): Promise<T> {
  const ldClient = await getLDClient();
  return ldClient.variation(flagKey, { key: userId }, defaultValue);
}
```

### A/B test variant with PostHog
```tsx
// src/lib/ab-test.ts
import "server-only";
import { cookies } from "next/headers";

export async function getVariant(
  experimentId: string,
  variants: string[]
): Promise<string> {
  const cookieStore = await cookies();
  const existing = cookieStore.get(`exp_${experimentId}`)?.value;
  if (existing && variants.includes(existing)) return existing;

  // Deterministic assignment based on visitor ID
  const visitorId = cookieStore.get("visitor_id")?.value ?? crypto.randomUUID();
  const hash = await hashString(`${experimentId}:${visitorId}`);
  const index = hash % variants.length;
  return variants[index];
}

async function hashString(input: string): Promise<number> {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return new DataView(hashBuffer).getUint32(0);
}
```

### Gradual rollout (percentage-based)
```tsx
export async function isEnabledForUser(
  flagKey: string,
  userId: string,
  percentage: number
): Promise<boolean> {
  const hash = await hashString(`${flagKey}:${userId}`);
  return (hash % 100) < percentage;
}
```

### Flag cleanup checklist
```markdown
When removing a flag:
1. Set flag to 100% enabled for all users
2. Wait one release cycle to confirm stability
3. Remove all conditional code paths (keep only the enabled path)
4. Remove the flag from Edge Config / LaunchDarkly
5. Remove the flag from the Zod schema
6. Update tests to remove flag-dependent branches
```

## Anti-pattern

### Feature flags in client components
Reading flags in Client Components leaks flag state to the browser. Always read flags
in Server Components or middleware, then pass the resolved value as props.

### No flag cleanup process
Stale flags accumulate as tech debt. Track flag creation dates and set cleanup
reminders. Each flag should have an owner and expiration.

### Boolean-only flags
Use string enums for multi-variant experiments (`"v1" | "v2" | "v3"`) instead of
boolean flags that limit you to on/off.

## Common Mistakes
- Calling `get()` in Client Components — Edge Config is server-only
- Not awaiting `cookies()` in Next.js 15 — it returns a Promise
- Inconsistent variant assignment — use deterministic hashing, not `Math.random()`
- Missing default values — always provide fallbacks for when flag service is down
- Testing only the enabled path — test both flag states

## Checklist
- [ ] Flag definitions use Zod schema with defaults
- [ ] Flags read in Server Components, not Client Components
- [ ] Middleware handles route-level feature gating
- [ ] A/B test variants use deterministic assignment
- [ ] Flag cleanup process documented
- [ ] Tests cover both flag states

## Composes With
- `nextjs-middleware` — route-level feature gating
- `analytics` — A/B test result tracking with PostHog
- `react-server-components` — conditional rendering based on flags
- `testing` — test both flag states
- `edge-computing` — Edge Config for zero-latency reads
