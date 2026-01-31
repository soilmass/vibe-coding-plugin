---
name: email
description: >
  Transactional email — React Email components + Resend/SendGrid transport, template composition, preview server, email patterns
allowed-tools: Read, Grep, Glob
---

# Email

## Purpose
Transactional email patterns using React Email for templates and Resend for delivery.
Covers component-based email templates, preview server, and sending patterns. The ONE
skill for sending emails from your app.

## When to Use
- Sending transactional emails (welcome, reset password, notifications)
- Building email templates with React components
- Setting up email preview and testing
- Integrating email sending in Server Actions

## When NOT to Use
- Marketing email campaigns → use dedicated email marketing tools
- Authentication flows → `auth` (handles magic links)
- Background email queues → `background-jobs`

## Pattern

### React Email template
```tsx
// emails/welcome.tsx
import { Html, Head, Body, Container, Text, Button, Hr } from "@react-email/components";

interface WelcomeEmailProps {
  name: string;
  loginUrl: string;
}

export function WelcomeEmail({ name, loginUrl }: WelcomeEmailProps) {
  return (
    <Html>
      <Head />
      <Body style={{ fontFamily: "sans-serif", padding: "20px" }}>
        <Container>
          <Text>Welcome, {name}!</Text>
          <Text>Your account has been created successfully.</Text>
          <Hr />
          <Button href={loginUrl} style={{ background: "#000", color: "#fff", padding: "12px 20px" }}>
            Sign In
          </Button>
        </Container>
      </Body>
    </Html>
  );
}
```

### Sending with Resend
```tsx
// src/lib/email.ts
import { Resend } from "resend";
import { env } from "@/env";

export const resend = new Resend(env.RESEND_API_KEY);

// src/actions/invite.ts
"use server";
import { resend } from "@/lib/email";
import { WelcomeEmail } from "@/emails/welcome";

export async function sendWelcome(email: string, name: string) {
  await resend.emails.send({
    from: "App <noreply@myapp.com>",
    to: email,
    subject: "Welcome to MyApp",
    react: WelcomeEmail({ name, loginUrl: "https://myapp.com/login" }),
  });
}
```

### Email template composition
```tsx
// emails/_components/email-layout.tsx
import { Html, Head, Body, Container, Img, Text, Hr, Section } from "@react-email/components";

interface EmailLayoutProps {
  preview?: string;
  children: React.ReactNode;
}

export function EmailLayout({ preview, children }: EmailLayoutProps) {
  return (
    <Html>
      <Head />
      <Body style={{ fontFamily: "sans-serif", background: "#f6f6f6", padding: "20px" }}>
        <Container style={{ background: "#fff", borderRadius: "8px", padding: "32px" }}>
          <Section>
            <Img src="https://myapp.com/logo.png" width={120} height={40} alt="MyApp" />
          </Section>
          <Hr style={{ margin: "20px 0" }} />
          {children}
          <Hr style={{ margin: "20px 0" }} />
          <Text style={{ fontSize: "12px", color: "#999" }}>
            MyApp Inc. · 123 Main St · You received this because you have an account.
          </Text>
        </Container>
      </Body>
    </Html>
  );
}

// emails/welcome.tsx — uses shared layout
import { Text, Button } from "@react-email/components";
import { EmailLayout } from "./_components/email-layout";

interface WelcomeEmailProps {
  name: string;
  loginUrl: string;
}

export function WelcomeEmail({ name, loginUrl }: WelcomeEmailProps) {
  return (
    <EmailLayout preview={`Welcome, ${name}!`}>
      <Text>Hi {name},</Text>
      <Text>Your account has been created. Click below to get started.</Text>
      <Button href={loginUrl} style={{ background: "#000", color: "#fff", padding: "12px 20px" }}>
        Sign In
      </Button>
    </EmailLayout>
  );
}

// emails/password-reset.tsx — another template using the same layout
import { Text, Button } from "@react-email/components";
import { EmailLayout } from "./_components/email-layout";

interface PasswordResetEmailProps {
  resetUrl: string;
  expiresInMinutes: number;
}

export function PasswordResetEmail({ resetUrl, expiresInMinutes }: PasswordResetEmailProps) {
  return (
    <EmailLayout preview="Reset your password">
      <Text>You requested a password reset.</Text>
      <Text>This link expires in {expiresInMinutes} minutes.</Text>
      <Button href={resetUrl} style={{ background: "#000", color: "#fff", padding: "12px 20px" }}>
        Reset Password
      </Button>
      <Text style={{ fontSize: "13px", color: "#666" }}>
        If you didn&apos;t request this, ignore this email.
      </Text>
    </EmailLayout>
  );
}
```

### Error handling and retry
```tsx
// src/lib/email.ts
import { Resend } from "resend";
import { env } from "@/env";
import { logger } from "@/lib/logger";

export const resend = new Resend(env.RESEND_API_KEY);

export async function sendEmail(params: Parameters<typeof resend.emails.send>[0]) {
  try {
    const { data, error } = await resend.emails.send(params);
    if (error) {
      logger.error("Email send failed", { error, to: params.to });
      throw new Error(error.message);
    }
    return data;
  } catch (err) {
    logger.error("Email transport error", { err, to: params.to });
    throw err;
  }
}

// src/inngest/functions/send-email.ts — retry with exponential backoff
import { inngest } from "@/lib/inngest";
import { sendEmail } from "@/lib/email";
import { WelcomeEmail } from "@/emails/welcome";

export const sendWelcomeEmail = inngest.createFunction(
  {
    id: "send-welcome-email",
    retries: 3, // retries with exponential backoff by default
  },
  { event: "user/created" },
  async ({ event, step }) => {
    await step.run("send-email", async () => {
      await sendEmail({
        from: "App <noreply@myapp.com>",
        to: event.data.email,
        subject: "Welcome to MyApp",
        react: WelcomeEmail({ name: event.data.name, loginUrl: "https://myapp.com/login" }),
      });
    });
  },
);
```

### Email preview server
```bash
# Install React Email CLI
npm i -D react-email

# Add script to package.json
"email:dev": "email dev --dir emails --port 3001"

# Run preview — opens browser at localhost:3001 with live reload
npm run email:dev
```
Preview renders each file in `emails/` as a navigable route. Props use the
component's default values or an exported `PreviewProps` object.

## Anti-pattern

```tsx
// WRONG: string concatenation HTML (XSS risk, no preview, no type safety)
const html = `<h1>Welcome ${name}</h1><a href="${url}">Login</a>`;
await sendEmail({ html });

// WRONG: sending email in component render (side effect in RSC)
export default async function Page() {
  await sendWelcomeEmail(user.email); // Fires on every render!
  return <div>Welcome</div>;
}
```

Use React Email components for type-safe, previewable templates. Send emails
only from Server Actions or API routes, never from component render.

## Common Mistakes
- String concatenation for HTML emails — no type safety, XSS risk
- Sending email during page render — fires on every request
- Not using preview server — can't see email before sending
- Hardcoding `from` address — use env var or constant
- Missing error handling on send — emails silently fail

## Checklist
- [ ] React Email templates in `emails/` directory
- [ ] Resend client initialized with validated env var
- [ ] Email sending only in Server Actions or API routes
- [ ] Preview server configured for development
- [ ] Error handling around email sends
- [ ] `from` address uses verified domain

## Composes With
- `react-server-actions` — emails sent from Server Actions
- `auth` — password reset and verification emails
- `deploy` — email API keys set in production environment
- `rate-limiting` — prevent email sending abuse
