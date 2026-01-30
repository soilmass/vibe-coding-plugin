---
name: background-jobs
description: >
  Background jobs — Inngest functions for event-driven tasks, scheduled cron, retries, step functions, Next.js API route integration
allowed-tools: Read, Grep, Glob
---

# Background Jobs

## Purpose
Background job patterns using Inngest for event-driven and scheduled tasks. Covers function
definitions, step functions, retries, cron schedules, and Next.js integration. The ONE skill
for work that happens outside the request-response cycle.

## When to Use
- Long-running tasks that shouldn't block Server Actions
- Scheduled/cron jobs (daily reports, cleanup)
- Event-driven workflows (user signup → send email → create records)
- Tasks that need automatic retries on failure

## When NOT to Use
- Simple mutations → `react-server-actions`
- Request-time data fetching → `nextjs-data`
- API endpoint logic → `api-routes`

## Pattern

### Inngest function definition
```tsx
// src/inngest/functions/send-welcome.ts
import { inngest } from "@/inngest/client";
import { sendWelcomeEmail } from "@/lib/email";

export const sendWelcome = inngest.createFunction(
  { id: "send-welcome-email", retries: 3 },
  { event: "user/created" },
  async ({ event, step }) => {
    await step.run("send-email", async () => {
      await sendWelcomeEmail(event.data.email, event.data.name);
    });

    await step.sleep("wait-1-day", "1d");

    await step.run("send-onboarding", async () => {
      await sendOnboardingEmail(event.data.email);
    });
  },
);
```

### Inngest client
```tsx
// src/inngest/client.ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "my-app" });
```

### Next.js API route integration
```tsx
// src/app/api/inngest/route.ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { sendWelcome } from "@/inngest/functions/send-welcome";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [sendWelcome],
});
```

### Triggering from Server Actions
```tsx
"use server";
import { inngest } from "@/inngest/client";

export async function createUser(formData: FormData) {
  const user = await db.user.create({ data: { ... } });

  // Fire-and-forget — doesn't block the response
  await inngest.send({
    name: "user/created",
    data: { email: user.email, name: user.name },
  });

  return { success: true };
}
```

### Scheduled cron job
```tsx
export const dailyCleanup = inngest.createFunction(
  { id: "daily-cleanup" },
  { cron: "0 3 * * *" }, // 3 AM daily
  async ({ step }) => {
    await step.run("cleanup-expired", async () => {
      await db.session.deleteMany({
        where: { expiresAt: { lt: new Date() } },
      });
    });
  },
);
```

## Anti-pattern

```tsx
// WRONG: long-running operation in Server Action (blocks response)
"use server";
export async function processOrder(orderId: string) {
  await generateInvoice(orderId);     // 5s
  await sendConfirmationEmail(orderId); // 2s
  await updateInventory(orderId);      // 3s
  // User waits 10+ seconds for response!
}

// CORRECT: fire event, process in background
"use server";
export async function processOrder(orderId: string) {
  await inngest.send({ name: "order/placed", data: { orderId } });
  return { success: true }; // Instant response
}
```

## Common Mistakes
- Running long tasks in Server Actions — blocks the HTTP response
- Not using step functions — entire function retries on failure
- Missing retry configuration — transient failures cause permanent loss
- Forgetting to register functions in the serve handler
- Not setting up the Inngest dev server for local development

## Checklist
- [ ] Inngest client in `src/inngest/client.ts`
- [ ] Functions in `src/inngest/functions/` directory
- [ ] API route at `src/app/api/inngest/route.ts`
- [ ] All functions registered in `serve()` call
- [ ] Step functions used for multi-step workflows
- [ ] Retry count configured per function
- [ ] Inngest dev server running locally (`npx inngest-cli dev`)

## Composes With
- `api-routes` — Inngest serve handler is a Next.js API route
- `prisma` — database operations inside step functions
- `deploy` — Inngest keys configured in production environment
