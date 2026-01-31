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

### Premium OpenGraph Image Design

#### OG image with brand design system
```tsx
// app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from "next/og";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function Image({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await getPost(slug);

  return new ImageResponse(
    (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          width: "100%",
          height: "100%",
          padding: "60px",
          // Dark background with subtle gradient
          background: "linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #0a0a0a 100%)",
          color: "#fafafa",
          fontFamily: "system-ui, sans-serif",
        }}
      >
        {/* Top — category tag */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
          }}
        >
          <div
            style={{
              width: "8px",
              height: "8px",
              borderRadius: "50%",
              backgroundColor: "#6366f1",
            }}
          />
          <span style={{ fontSize: "18px", color: "#a1a1aa", textTransform: "uppercase", letterSpacing: "2px" }}>
            {post.category}
          </span>
        </div>

        {/* Center — title with size hierarchy */}
        <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
          <h1
            style={{
              fontSize: post.title.length > 60 ? "42px" : "56px",
              fontWeight: 700,
              lineHeight: 1.15,
              letterSpacing: "-0.02em",
              maxWidth: "80%",
            }}
          >
            {post.title}
          </h1>
          {post.excerpt && (
            <p style={{ fontSize: "20px", color: "#a1a1aa", maxWidth: "70%", lineHeight: 1.5 }}>
              {post.excerpt.slice(0, 120)}
            </p>
          )}
        </div>

        {/* Bottom — author + branding */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            {post.author.avatar && (
              <img
                src={post.author.avatar}
                width={40}
                height={40}
                style={{ borderRadius: "50%" }}
              />
            )}
            <span style={{ fontSize: "16px", color: "#d4d4d8" }}>{post.author.name}</span>
          </div>
          <span style={{ fontSize: "16px", color: "#71717a" }}>myapp.com</span>
        </div>

        {/* Decorative gradient blob */}
        <div
          style={{
            position: "absolute",
            top: "-100px",
            right: "-100px",
            width: "400px",
            height: "400px",
            borderRadius: "50%",
            background: "radial-gradient(circle, oklch(0.5 0.2 270 / 0.15), transparent 70%)",
          }}
        />
      </div>
    ),
    { ...size }
  );
}
```

#### OG image design rules
```
1. Dark backgrounds (10-15% lightness) — more share-friendly than white
2. Title font-size: 42-56px depending on length (auto-scale)
3. Max 2 font weights: bold for title, regular for meta
4. Brand color as accent (dot, line, gradient) — not background
5. Author avatar adds social proof
6. Consistent padding: 60px on all sides
7. Decorative gradient blobs for depth (subtle, 10-15% opacity)
8. Always include domain name for attribution
9. Category label uppercase with letter-spacing for hierarchy
10. Limit text to title + 1 line excerpt — OG images are thumbnails
```

## Composes With
- `nextjs-metadata` — basic metadata complements advanced SEO
- `nextjs-routing` — sitemap reflects all public routes
- `i18n` — hreflang tags and locale-specific sitemaps
- `visual-design` — OG image color palette and typography hierarchy
- `advanced-typography` — font sizing and weight hierarchy in OG images
