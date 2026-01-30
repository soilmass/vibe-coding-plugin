---
name: seo-advanced
description: >
  Advanced SEO — JSON-LD structured data, dynamic sitemap.ts, robots.ts, OpenGraph image generation with opengraph-image.tsx
allowed-tools: Read, Grep, Glob
---

# Advanced SEO

## Purpose
Advanced SEO patterns beyond basic metadata. Covers JSON-LD structured data, dynamic sitemaps,
robots.txt configuration, and OpenGraph image generation. The ONE skill for SEO beyond meta tags.

## When to Use
- Adding structured data (JSON-LD) for rich search results
- Generating dynamic sitemaps from database content
- Configuring robots.txt and creating dynamic OpenGraph images

## When NOT to Use
- Basic page titles and descriptions → `nextjs-metadata`
- Route-level meta tags → `nextjs-metadata`
- Security headers → `security`

## Pattern

### JSON-LD structured data
```tsx
// src/components/JsonLd.tsx
export function JsonLd({ data }: { data: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}

// Usage in page
export default async function ProductPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const product = await getProduct(id);

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: product.name,
    description: product.description,
    image: product.image,
    offers: {
      "@type": "Offer",
      price: product.price,
      priceCurrency: "USD",
      availability: "https://schema.org/InStock",
    },
  };

  return (
    <>
      <JsonLd data={jsonLd} />
      <div>{product.name}</div>
    </>
  );
}
```

### Dynamic sitemap.ts
```tsx
// app/sitemap.ts
import type { MetadataRoute } from "next";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await db.post.findMany({ select: { slug: true, updatedAt: true } });
  return [
    { url: "https://myapp.com", lastModified: new Date(), priority: 1 },
    ...posts.map((post) => ({
      url: `https://myapp.com/blog/${post.slug}`,
      lastModified: post.updatedAt,
      changeFrequency: "weekly" as const,
      priority: 0.8,
    })),
  ];
}
```

### robots.ts
```tsx
// app/robots.ts
import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: ["/api/", "/dashboard/"] }],
    sitemap: "https://myapp.com/sitemap.xml",
  };
}
```

### OpenGraph image generation
```tsx
// app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from "next/og";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function Image({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await getPost(slug);
  return new ImageResponse(
    <div style={{ display: "flex", fontSize: 48, background: "#000", color: "#fff",
      width: "100%", height: "100%", alignItems: "center", justifyContent: "center" }}>
      {post.title}
    </div>,
    { ...size },
  );
}
```

## Anti-pattern

```tsx
// WRONG: hardcoded sitemap URLs (breaks when pages are added/removed)
export default function sitemap() {
  return [
    { url: "https://myapp.com/blog/post-1" },
    { url: "https://myapp.com/blog/post-2" }, // Must manually update!
  ];
}
```

Generate sitemaps dynamically from your database. Build JSON-LD from typed objects.

## Common Mistakes
- Hardcoding sitemap URLs — generate from database instead
- Missing `metadataBase` — relative URLs in sitemap break
- JSON-LD without `@context` — search engines ignore it
- Not disallowing private routes in robots.txt

## Checklist
- [ ] `sitemap.ts` generates URLs from database
- [ ] `robots.ts` blocks private routes (`/api/`, `/dashboard/`)
- [ ] JSON-LD structured data on key pages (products, articles, org)
- [ ] OpenGraph images generated dynamically for content pages
- [ ] `metadataBase` set in root layout
- [ ] Canonical URLs set for duplicate content prevention

## Composes With
- `nextjs-metadata` — basic metadata complements advanced SEO
- `nextjs-routing` — sitemap reflects all public routes
- `i18n` — hreflang tags and locale-specific sitemaps
