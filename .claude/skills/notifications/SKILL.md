---
name: notifications
description: >
  Push notifications, in-app notification center, preference management, email digests, real-time delivery
allowed-tools: Read, Grep, Glob
---

# Notifications

## Purpose
Multi-channel notification system for Next.js 15. Covers Web Push API, in-app notification
center with shadcn, per-user notification preferences, email digest batching, and real-time
delivery via SSE or Pusher.

## When to Use
- Adding push notifications with service worker
- Building an in-app notification center (bell icon with dropdown)
- Managing per-user notification preferences (email/push/in-app per event)
- Setting up email digest batching (daily/weekly summaries)
- Real-time notification delivery

## When NOT to Use
- Email sending infrastructure → `email`
- Real-time data synchronization → `real-time`
- Background job scheduling → `background-jobs`
- Toast/snackbar UI feedback → shadcn Toast component

## Pattern

### Notification Prisma models
```prisma
model Notification {
  id        String   @id @default(cuid())
  userId    String
  type      String   // "mention" | "comment" | "invite" | etc.
  title     String
  body      String
  link      String?
  read      Boolean  @default(false)
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, read])
  @@index([createdAt])
}

model NotificationPreference {
  id      String @id @default(cuid())
  userId  String
  type    String // notification event type
  email   Boolean @default(true)
  push    Boolean @default(true)
  inApp   Boolean @default(true)

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, type])
}

model PushSubscription {
  id        String   @id @default(cuid())
  userId    String
  endpoint  String   @unique
  p256dh    String
  auth      String
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}
```

### Send notification helper
```tsx
// src/lib/notifications.ts
import "server-only";
import { db } from "@/lib/db";
import webpush from "web-push";

webpush.setVapidDetails(
  "mailto:support@example.com",
  process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY!,
  process.env.VAPID_PRIVATE_KEY!
);

export async function sendNotification(params: {
  userId: string;
  type: string;
  title: string;
  body: string;
  link?: string;
}) {
  // Check user preferences
  const pref = await db.notificationPreference.findUnique({
    where: { userId_type: { userId: params.userId, type: params.type } },
  });

  // In-app notification (always created unless explicitly disabled)
  if (pref?.inApp !== false) {
    await db.notification.create({ data: params });
  }

  // Push notification
  if (pref?.push !== false) {
    const subscriptions = await db.pushSubscription.findMany({
      where: { userId: params.userId },
    });
    for (const sub of subscriptions) {
      await webpush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
        JSON.stringify({ title: params.title, body: params.body, url: params.link })
      ).catch(() => {
        // Remove invalid subscription
        db.pushSubscription.delete({ where: { id: sub.id } });
      });
    }
  }

  // Email (queue via background job for batching)
  if (pref?.email !== false) {
    // await inngest.send({ name: "notification/email", data: params });
  }
}
```

### In-app notification center
```tsx
// src/components/notifications/notification-center.tsx
"use client";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Button } from "@/components/ui/button";
import { Bell } from "lucide-react";

type Notification = {
  id: string;
  title: string;
  body: string;
  read: boolean;
  createdAt: string;
  link?: string;
};

export function NotificationCenter({
  notifications,
  unreadCount,
}: {
  notifications: Notification[];
  unreadCount: number;
}) {
  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 h-4 w-4 rounded-full bg-red-500 text-[10px] text-white flex items-center justify-center">
              {unreadCount > 9 ? "9+" : unreadCount}
            </span>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-80 p-0">
        <ScrollArea className="h-80">
          {notifications.map((n) => (
            <div key={n.id} className={`p-3 border-b ${n.read ? "" : "bg-muted/50"}`}>
              <p className="text-sm font-medium">{n.title}</p>
              <p className="text-xs text-muted-foreground">{n.body}</p>
            </div>
          ))}
        </ScrollArea>
      </PopoverContent>
    </Popover>
  );
}
```

### Mark as read Server Action
```tsx
// src/actions/notifications.ts
"use server";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { revalidateTag } from "next/cache";

export async function markAsRead(notificationId: string) {
  const session = await auth();
  if (!session?.user?.id) return;

  await db.notification.update({
    where: { id: notificationId, userId: session.user.id },
    data: { read: true },
  });

  revalidateTag("notifications");
}

export async function markAllAsRead() {
  const session = await auth();
  if (!session?.user?.id) return;

  await db.notification.updateMany({
    where: { userId: session.user.id, read: false },
    data: { read: true },
  });

  revalidateTag("notifications");
}
```

### Push subscription registration
```tsx
// src/components/notifications/push-opt-in.tsx
"use client";

export function PushOptIn() {
  async function subscribe() {
    const registration = await navigator.serviceWorker.register("/sw.js");
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY,
    });

    await fetch("/api/push/subscribe", {
      method: "POST",
      body: JSON.stringify(subscription),
      headers: { "Content-Type": "application/json" },
    });
  }

  return <button onClick={subscribe}>Enable push notifications</button>;
}
```

### Email digest batching
```tsx
// src/inngest/functions/email-digest.ts
import { inngest } from "@/lib/inngest";
import { db } from "@/lib/db";

export const sendDailyDigest = inngest.createFunction(
  { id: "notification-daily-digest" },
  { cron: "0 9 * * *" }, // Daily at 9 AM
  async () => {
    const usersWithUnread = await db.notification.groupBy({
      by: ["userId"],
      where: { read: false, createdAt: { gte: new Date(Date.now() - 86400000) } },
      _count: true,
    });

    for (const { userId, _count } of usersWithUnread) {
      // Send digest email with unread count and summary
      // await sendEmail({ to: user.email, subject: `You have ${_count} new notifications` });
    }
  }
);
```

## Anti-pattern

### Sending push notifications synchronously
Don't send push notifications in the Server Action request path. Queue them via
background jobs. Push delivery can be slow and shouldn't block the user.

### No preference management
Sending all notification types to all channels without user control leads to
notification fatigue and unsubscribes. Always provide per-event, per-channel preferences.

## Common Mistakes
- Not handling expired push subscriptions — delete on 410 response
- Missing service worker for push — notifications won't show
- No unread count invalidation after marking as read
- Sending email for every notification — batch into digests
- Missing VAPID keys — push subscription will fail

## Checklist
- [ ] Notification model with userId, type, read status
- [ ] NotificationPreference model for per-event channel control
- [ ] Push subscription management (subscribe/unsubscribe)
- [ ] In-app notification center with unread badge
- [ ] Mark as read / mark all as read actions
- [ ] Email digest batching via cron job
- [ ] Push delivery via background job
- [ ] Invalid subscription cleanup

## Composes With
- `background-jobs` — async notification delivery with Inngest
- `prisma` — notification and preference models
- `shadcn` — notification center UI components
- `react-client-components` — interactive notification bell
- `email` — email notification channel
- `real-time` — live notification delivery via SSE/Pusher
- `pwa` — service worker for push notification delivery
