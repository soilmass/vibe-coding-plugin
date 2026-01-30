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

### Gallery / carousel patterns
```tsx
// Image gallery grid
import Image from "next/image";

export function ImageGallery({ images }: { images: { src: string; alt: string }[] }) {
  return (
    <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-4">
      {images.map((img, i) => (
        <div key={i} className="group relative aspect-square cursor-pointer overflow-hidden rounded-lg">
          <Image
            src={img.src}
            alt={img.alt}
            fill
            sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
            className="object-cover transition-transform group-hover:scale-105"
          />
        </div>
      ))}
    </div>
  );
}
```

```tsx
// Lightbox pattern (dialog overlay for full-size image)
"use client";

import { useState } from "react";
import Image from "next/image";
import { Dialog, DialogContent } from "@/components/ui/dialog";

export function LightboxGallery({ images }: { images: { src: string; alt: string }[] }) {
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null);

  return (
    <>
      <div className="grid grid-cols-3 gap-2">
        {images.map((img, i) => (
          <button key={i} onClick={() => setSelectedIndex(i)} className="relative aspect-square overflow-hidden rounded">
            <Image src={img.src} alt={img.alt} fill sizes="33vw" className="object-cover" />
          </button>
        ))}
      </div>

      <Dialog open={selectedIndex !== null} onOpenChange={() => setSelectedIndex(null)}>
        <DialogContent className="max-w-4xl p-0">
          {selectedIndex !== null && (
            <div className="relative aspect-video">
              <Image
                src={images[selectedIndex].src}
                alt={images[selectedIndex].alt}
                fill
                sizes="90vw"
                className="object-contain"
                priority
              />
            </div>
          )}
          <div className="flex justify-between p-4">
            <button
              onClick={() => setSelectedIndex(Math.max(0, (selectedIndex ?? 0) - 1))}
              disabled={selectedIndex === 0}
            >
              Previous
            </button>
            <button
              onClick={() => setSelectedIndex(Math.min(images.length - 1, (selectedIndex ?? 0) + 1))}
              disabled={selectedIndex === images.length - 1}
            >
              Next
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}

// Carousel with keyboard navigation and touch swipe
// For production carousels, use embla-carousel-react (shadcn Carousel is built on it)
// npx shadcn@latest add carousel
```

## Composes With
- `performance` — images are the biggest LCP factor
- `nextjs-metadata` — OG images for social sharing
- `accessibility` — alt text is required for screen readers
- `file-uploads` — user-uploaded images need optimization too
- `responsive-design` — responsive image sizes and grid layouts
