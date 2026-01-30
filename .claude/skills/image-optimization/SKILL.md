---
name: image-optimization
description: >
  Image optimization — next/image deep dive, responsive sizes, blur placeholders, remote image config, OG image generation, LCP priority
allowed-tools: Read, Grep, Glob
---

# Image Optimization

## Purpose
Image optimization patterns for Next.js 15. Covers `next/image` best practices, responsive
`sizes`, blur placeholders, OG image generation, and LCP optimization. The ONE skill for images.

## When to Use
- Adding images to pages with proper optimization
- Generating Open Graph images dynamically
- Optimizing Largest Contentful Paint (LCP)
- Configuring remote image domains

## When NOT to Use
- File uploads → `file-uploads`
- SEO metadata (non-image) → `nextjs-metadata`
- General performance → `performance`

## Pattern

### Responsive image with sizes
```tsx
import Image from "next/image";

export function HeroImage() {
  return (
    <Image
      src="/hero.jpg"
      alt="Product showcase"
      width={1200}
      height={630}
      sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 1200px"
      priority // LCP image — skip lazy loading
    />
  );
}
```

### Fill mode for unknown dimensions
```tsx
export function Avatar({ src, name }: { src: string; name: string }) {
  return (
    <div className="relative h-10 w-10">
      <Image
        src={src}
        alt={`${name}'s avatar`}
        fill
        className="rounded-full object-cover"
        sizes="40px"
      />
    </div>
  );
}
```

### Blur placeholder with plaiceholder
```tsx
import { getPlaiceholder } from "plaiceholder";
import Image from "next/image";

export async function BlurImage({ src }: { src: string }) {
  const buffer = await fetch(src).then((r) => r.arrayBuffer());
  const { base64 } = await getPlaiceholder(Buffer.from(buffer));

  return (
    <Image
      src={src}
      alt="Product photo"
      width={800}
      height={600}
      placeholder="blur"
      blurDataURL={base64}
    />
  );
}
```

### Remote image configuration
```tsx
// next.config.ts
const config = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "**.example.com",
      },
      {
        protocol: "https",
        hostname: "images.unsplash.com",
      },
    ],
  },
};
export default config;
```

### OG image generation
```tsx
// app/api/og/route.tsx
import { ImageResponse } from "next/og";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const title = searchParams.get("title") ?? "Default Title";

  return new ImageResponse(
    (<div style={{ display: "flex", fontSize: 60, background: "white",
        width: "100%", height: "100%", alignItems: "center", justifyContent: "center" }}>
      {title}
    </div>),
    { width: 1200, height: 630 }
  );
}
```

## Anti-pattern

```tsx
// WRONG: using <img> instead of next/image
<img src="/photo.jpg" />  // No optimization, no lazy loading, no srcset

// WRONG: missing alt attribute
<Image src="/hero.jpg" width={800} height={600} />  // Accessibility violation

// WRONG: unoptimized in production
<Image src="/photo.jpg" alt="Photo" unoptimized />  // Skips all optimization
```

## Common Mistakes
- Using `<img>` instead of `next/image` — no optimization
- Missing `alt` attribute — accessibility violation
- Missing `priority` on LCP images — slower first paint
- Missing `sizes` on responsive images — downloads oversized images
- Not configuring `remotePatterns` for external images

## Checklist
- [ ] All images use `next/image` with meaningful `alt` text
- [ ] LCP images have `priority` prop
- [ ] Responsive images have `sizes` prop
- [ ] Remote image domains configured in `next.config.ts`

## Composes With
- `performance` — images are the biggest LCP factor
- `nextjs-metadata` — OG images for social sharing
- `accessibility` — alt text is required for screen readers
- `file-uploads` — user-uploaded images need optimization too
