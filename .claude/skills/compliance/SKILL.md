---
name: compliance
description: >
  GDPR compliance — cookie consent, data export/deletion, audit logging, PII handling, data retention policies
allowed-tools: Read, Grep, Glob
---

# Compliance

## Purpose
GDPR and privacy compliance for Next.js 15. Covers cookie consent, data subject rights
(export/deletion), audit logging for mutations, PII handling in Prisma models, and
data retention policies with automated cleanup.

## When to Use
- Implementing cookie consent banner with category management
- Building GDPR data export (download user data as JSON/CSV)
- Implementing right-to-be-forgotten (soft delete → hard delete lifecycle)
- Adding audit logging for data mutations
- Classifying and protecting PII in database models
- Setting up data retention and auto-archival policies

## When NOT to Use
- Authentication and authorization → `auth`
- Security headers and CSP → `security`
- Basic structured logging → `logging`
- Payment data handling → `payments`

## Pattern

### Cookie consent banner
```tsx
// src/components/cookie-consent.tsx
"use client";
import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

type ConsentCategory = "necessary" | "analytics" | "marketing";

const CONSENT_KEY = "cookie-consent";

export function CookieConsent() {
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    const consent = localStorage.getItem(CONSENT_KEY);
    if (!consent) setShowBanner(true);
  }, []);

  function handleAccept(categories: ConsentCategory[]) {
    const consent = {
      categories,
      timestamp: new Date().toISOString(),
      version: "1.0",
    };
    localStorage.setItem(CONSENT_KEY, JSON.stringify(consent));
    setShowBanner(false);
    // Persist to DB for audit proof
    saveConsentToServer(consent);
  }

  if (!showBanner) return null;

  return (
    <Card className="fixed bottom-4 left-4 right-4 z-50 max-w-lg mx-auto">
      <CardContent className="p-4">
        <p className="text-sm mb-3">
          We use cookies to improve your experience. Choose your preferences.
        </p>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => handleAccept(["necessary"])}
          >
            Necessary only
          </Button>
          <Button
            size="sm"
            onClick={() => handleAccept(["necessary", "analytics", "marketing"])}
          >
            Accept all
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
```

### Consent Zod schema
```tsx
// src/types/consent.ts
import { z } from "zod";

export const ConsentSchema = z.object({
  categories: z.array(z.enum(["necessary", "analytics", "marketing"])),
  timestamp: z.string().datetime(),
  version: z.string(),
});

export type Consent = z.infer<typeof ConsentSchema>;
```

### Audit log Prisma model
```prisma
// prisma/schema.prisma (add to existing schema)
model AuditLog {
  id        String   @id @default(cuid())
  userId    String
  action    String   // "create" | "update" | "delete"
  entity    String   // "User" | "Order" | etc.
  entityId  String
  changes   Json?    // { field: { from, to } }
  ip        String?
  userAgent String?
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id])

  @@index([userId])
  @@index([entity, entityId])
  @@index([createdAt])
}
```

### Audit log helper
```tsx
// src/lib/audit.ts
import "server-only";
import { db } from "@/lib/db";
import { headers } from "next/headers";
import { auth } from "@/lib/auth";

export async function auditLog(params: {
  action: "create" | "update" | "delete";
  entity: string;
  entityId: string;
  changes?: Record<string, { from: unknown; to: unknown }>;
}) {
  const session = await auth();
  if (!session?.user?.id) return;

  const headerList = await headers();

  await db.auditLog.create({
    data: {
      userId: session.user.id,
      action: params.action,
      entity: params.entity,
      entityId: params.entityId,
      changes: params.changes ?? undefined,
      ip: headerList.get("x-forwarded-for"),
      userAgent: headerList.get("user-agent"),
    },
  });
}
```

### GDPR data export Server Action
```tsx
// src/actions/gdpr-export.ts
"use server";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";

export async function exportUserData() {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");

  const user = await db.user.findUnique({
    where: { id: session.user.id },
    include: {
      orders: true,
      auditLogs: { orderBy: { createdAt: "desc" }, take: 100 },
    },
  });

  // Strip internal fields
  const exportData = {
    profile: {
      name: user?.name,
      email: user?.email,
      createdAt: user?.createdAt,
    },
    orders: user?.orders.map((o) => ({
      id: o.id,
      total: o.total,
      createdAt: o.createdAt,
    })),
    activityLog: user?.auditLogs.map((l) => ({
      action: l.action,
      entity: l.entity,
      date: l.createdAt,
    })),
    exportedAt: new Date().toISOString(),
  };

  return exportData;
}
```

### GDPR data deletion (soft delete → hard delete)
```tsx
// src/actions/gdpr-delete.ts
"use server";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { auditLog } from "@/lib/audit";

export async function requestAccountDeletion() {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");

  // Step 1: Soft delete — mark for deletion
  await db.user.update({
    where: { id: session.user.id },
    data: {
      deletedAt: new Date(),
      email: `deleted-${session.user.id}@redacted.local`,
      name: "Deleted User",
    },
  });

  await auditLog({
    action: "delete",
    entity: "User",
    entityId: session.user.id,
    changes: { status: { from: "active", to: "pending_deletion" } },
  });

  // Step 2: Schedule hard delete via Inngest (30-day grace period)
  // await inngest.send({ name: "user/hard-delete", data: { userId: session.user.id } });
}
```

### Data retention auto-cleanup
```tsx
// src/inngest/functions/data-retention.ts
import { inngest } from "@/lib/inngest";
import { db } from "@/lib/db";

export const cleanupOldData = inngest.createFunction(
  { id: "data-retention-cleanup" },
  { cron: "0 3 * * 0" }, // Weekly at 3 AM
  async () => {
    const retentionDays = 90;
    const cutoff = new Date(Date.now() - retentionDays * 86400000);

    // Hard delete users past grace period
    await db.user.deleteMany({
      where: {
        deletedAt: { not: null, lt: cutoff },
      },
    });

    // Archive old audit logs
    await db.auditLog.deleteMany({
      where: {
        createdAt: { lt: new Date(Date.now() - 365 * 86400000) },
      },
    });
  }
);
```

### PII classification annotations
```prisma
// In schema.prisma — annotate PII fields with comments
model User {
  id        String   @id @default(cuid())
  email     String   @unique /// @pii
  name      String?  /// @pii
  phone     String?  /// @pii
  address   String?  /// @pii
  deletedAt DateTime?
  createdAt DateTime @default(now())
}
```

### Privacy-first analytics check
```tsx
// src/lib/analytics-consent.ts
"use client";

export function hasAnalyticsConsent(): boolean {
  if (typeof window === "undefined") return false;
  try {
    const consent = JSON.parse(localStorage.getItem("cookie-consent") ?? "{}");
    return consent.categories?.includes("analytics") ?? false;
  } catch {
    return false;
  }
}

// Usage: only track if consent given
export function trackEvent(event: string, props?: Record<string, unknown>) {
  if (!hasAnalyticsConsent()) return;
  // posthog.capture(event, props);
}
```

### Consent withdrawal Server Action
```tsx
// src/actions/withdraw-consent.ts
"use server";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { auditLog } from "@/lib/audit";
import { revalidatePath } from "next/cache";

export async function withdrawConsent(
  prevState: unknown,
  formData: FormData
) {
  const session = await auth();
  if (!session?.user?.id) return { error: "Unauthorized" };

  const category = formData.get("category") as string;

  await db.consent.update({
    where: { userId: session.user.id },
    data: {
      [category]: false,
      updatedAt: new Date(),
    },
  });

  await auditLog({
    action: "update",
    entity: "Consent",
    entityId: session.user.id,
    changes: { [category]: { from: true, to: false } },
  });

  revalidatePath("/settings/privacy");
  return { success: true };
}
```

## Anti-pattern

### Hard-deleting without audit trail
Never permanently delete user data immediately. Use soft delete first (set `deletedAt`),
maintain an audit log of the deletion request, then schedule hard delete after a grace
period (typically 30 days for GDPR compliance).

### Storing PII in logs
Never log email addresses, names, phone numbers, or addresses. Mask sensitive fields
before they reach the logger: `email: maskEmail(user.email)`.

### Consent in cookies only
Cookie-only consent storage is insufficient for compliance. Persist consent records in
the database with timestamp and version for audit proof.

## Common Mistakes
- Not checking consent before loading analytics scripts — see `analytics` skill for consent-checking patterns
- Missing `deletedAt` field on User model for soft deletes
- Audit log without indexes — queries become slow
- No data retention policy — data accumulates indefinitely
- Forgetting to redact PII from exported audit logs

## Checklist
- [ ] Cookie consent banner with category selection
- [ ] Consent persisted in database (not cookies only)
- [ ] PII fields annotated in Prisma schema
- [ ] Data export endpoint returns user's data
- [ ] Data deletion uses soft-delete → hard-delete lifecycle
- [ ] Audit log records all mutations on sensitive data
- [ ] Analytics tracking is consent-gated
- [ ] Data retention cron job configured
- [ ] Sensitive data masked in logs

## Composes With
- `prisma` — audit log model, soft delete fields, PII annotations
- `security` — data protection headers, CSP
- `analytics` — consent-gated tracking
- `logging` — PII masking in structured logs
- `auth` — user identity for audit trails
- `background-jobs` — scheduled data cleanup with Inngest
