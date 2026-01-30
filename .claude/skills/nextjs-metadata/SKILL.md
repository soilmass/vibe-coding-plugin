---
name: nextjs-metadata
description: >
  Next.js 15 Metadata API — static/dynamic metadata, generateMetadata, generateViewport, OpenGraph, Twitter cards, sitemap.ts, robots.ts, JSON-LD
allowed-tools: Read, Grep, Glob
---

# Next.js Metadata

## Purpose
Next.js 15 Metadata API for SEO and social sharing. Covers static and dynamic metadata,
OpenGraph, structured data, and sitemaps. The ONE skill for head tags and SEO.

## When to Use
- Setting page titles, descriptions, and OpenGraph tags
- Generating dynamic metadata from database content
- Creating sitemaps and robots.txt
- Adding structured data (JSON-LD)

## When NOT to Use
- CSP security headers → `security`
- Middleware headers → `nextjs-middleware`
- Route-level data fetching → `nextjs-data`

## Pattern

### Static metadata
```tsx
// app/layout.tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: {
    template: "%s | My App",
    default: "My App",
  },
  description: "A Next.js 15 application",
  metadataBase: new URL("https://myapp.com"),
};
```

### Dynamic metadata with generateMetadata
```tsx
// app/blog/[slug]/page.tsx
import type { Metadata } from "next";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [post.coverImage],
    },
  };
}
```

### generateViewport (separate from metadata)
```tsx
import type { Viewport } from "next";

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#000000" },
  ],
  width: "device-width",
  initialScale: 1,
};
```

### sitemap.ts
```tsx
// app/sitemap.ts — see `seo-advanced` for full sitemap patterns
import type { MetadataRoute } from "next";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await db.post.findMany({ select: { slug: true, updatedAt: true } });
  return posts.map((post) => ({
    url: `https://myapp.com/blog/${post.slug}`,
    lastModified: post.updatedAt,
  }));
}
```

## Anti-pattern

```tsx
// WRONG: putting viewport config in metadata export
export const metadata: Metadata = {
  themeColor: "#000", // Moved to viewport in Next.js 15
  viewport: "width=device-width", // Also moved to viewport
};
```

In Next.js 15, viewport-related fields are in a separate `viewport` export.

## Common Mistakes
- Putting viewport config in metadata — use separate `viewport` export
- Not awaiting params in `generateMetadata` — they're Promises in Next.js 15
- Missing `metadataBase` — relative OpenGraph image URLs break
- Forgetting title template in root layout — inconsistent page titles
- Not setting `robots.txt` to block private routes

## Checklist
- [ ] Root layout has `metadata` with title template and description
- [ ] `viewport` exported separately from `metadata`
- [ ] Dynamic pages use `generateMetadata` with awaited params
- [ ] `metadataBase` set for proper OpenGraph URL resolution
- [ ] `sitemap.ts` and `robots.ts` exist for SEO

## Composes With
- `nextjs-routing` — metadata is tied to route segments
- `nextjs-data` — generateMetadata fetches data for dynamic pages
- `tailwind-v4` — theme colors reference CSS custom properties
- `i18n` — locale-aware metadata with alternates and hreflang
