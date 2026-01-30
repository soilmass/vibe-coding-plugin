---
name: i18n
description: >
  Next.js 15 internationalization with next-intl — locale routing, useTranslations, server-side getTranslations, middleware locale detection
allowed-tools: Read, Grep, Glob
---

# i18n

## Purpose
Next.js 15 internationalization with `next-intl`. Covers `[locale]` route segments, translation
hooks, server-side translations, and middleware locale detection. The ONE skill for i18n decisions.

## When to Use
- Adding multi-language support to Next.js 15 app
- Setting up `[locale]` route segments
- Using `useTranslations` or `getTranslations`
- Configuring middleware for locale detection
- Managing translation JSON files

## When NOT to Use
- Routing without i18n → `nextjs-routing`
- Middleware without locale logic → `nextjs-middleware`
- SEO/metadata per locale → `nextjs-metadata` (composes with this skill)

## Pattern

### Route structure with `[locale]` segment
```
src/app/
├── [locale]/
│   ├── layout.tsx        # Locale-aware layout
│   ├── page.tsx          # Home page
│   └── about/page.tsx    # About page
├── i18n/
│   ├── request.ts        # next-intl request config
│   └── routing.ts        # Locale routing config
└── messages/
    ├── en.json           # English translations
    └── es.json           # Spanish translations
```

### Locale routing config
```tsx
// src/i18n/routing.ts
import { defineRouting } from "next-intl/routing";

export const routing = defineRouting({
  locales: ["en", "es", "fr"],
  defaultLocale: "en",
});
```

### Middleware locale detection
```tsx
// src/middleware.ts
import createMiddleware from "next-intl/middleware";
import { routing } from "@/i18n/routing";

export default createMiddleware(routing);

export const config = {
  matcher: ["/((?!api|_next|.*\\..*).*)"],
};
```

### Server Component with getTranslations
```tsx
// src/app/[locale]/page.tsx
import { getTranslations } from "next-intl/server";

export default async function Page({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "Home" });

  return <h1>{t("title")}</h1>;
}
```

### Client Component with useTranslations
```tsx
"use client";
import { useTranslations } from "next-intl";

export function SearchBar() {
  const t = useTranslations("Search");
  return <input placeholder={t("placeholder")} />;
}
```

### Locale-aware metadata
```tsx
import { getTranslations } from "next-intl/server";
import type { Metadata } from "next";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "Metadata" });
  return { title: t("title"), description: t("description") };
}
```

## Anti-pattern

```tsx
// WRONG: client-side locale detection with useEffect (causes flash)
"use client";
export function LocaleSwitcher() {
  const [locale, setLocale] = useState("en");
  useEffect(() => {
    setLocale(navigator.language.slice(0, 2));
  }, []);
  // Flash of wrong language on SSR!
}

// CORRECT: detect in middleware, read from params
import { useLocale } from "next-intl";
export function LocaleSwitcher() {
  const locale = useLocale(); // Already resolved by middleware
}
```

## Common Mistakes
- Detecting locale client-side with `useEffect` — causes flash of wrong language
- Forgetting to `await params` in `[locale]` pages (Next.js 15 Promise params)
- Not wrapping `next-intl/middleware` matcher to exclude API routes
- Hardcoding strings instead of using translation keys
- Missing `messages` directory or forgetting to load locale messages in layout

## Checklist
- [ ] `[locale]` route segment wraps all localized pages
- [ ] Middleware detects and redirects to correct locale
- [ ] Server Components use `getTranslations` (not `useTranslations`)
- [ ] Client Components use `useTranslations` with `"use client"`
- [ ] Translation JSON files exist for all supported locales
- [ ] `generateMetadata` uses locale-aware translations
- [ ] `params` is awaited before accessing `locale`

## Composes With
- `nextjs-routing` — `[locale]` is a route segment
- `nextjs-middleware` — locale detection runs in middleware
- `nextjs-metadata` — metadata varies by locale
- `seo-advanced` — hreflang tags and locale-specific structured data
