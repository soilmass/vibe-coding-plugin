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

### Email preview server
```bash
# package.json script
"email:dev": "email dev --dir emails --port 3001"
```

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
