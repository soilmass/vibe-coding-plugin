---
name: cms
description: >
  Headless CMS integration — Contentful/Sanity client, MDX rendering, Draft Mode preview, content caching
allowed-tools: Read, Grep, Glob
---

# CMS

## Purpose
Headless CMS integration for Next.js 15 with support for Contentful, Sanity, and MDX content.
Covers type-safe CMS clients, Server Component MDX rendering, Draft Mode for previews, image
optimization, and content caching with tag-based revalidation.

## When to Use
- Integrating Contentful or Sanity as headless CMS
- Rendering MDX content in Server Components
- Setting up content preview with Next.js Draft Mode
- Caching CMS content with webhook-triggered revalidation
- Building blog posts, landing pages, or documentation from CMS

## When NOT to Use
- Database-driven content → `prisma`
- Static markdown files without CMS → plain MDX
- API documentation → `api-documentation`
- SEO metadata → `nextjs-metadata`

## Pattern

### Contentful client setup
```tsx
// src/lib/contentful.ts
import "server-only";
import { createClient } from "contentful";

const client = createClient({
  space: process.env.CONTENTFUL_SPACE_ID!,
  accessToken: process.env.CONTENTFUL_ACCESS_TOKEN!,
});

const previewClient = createClient({
  space: process.env.CONTENTFUL_SPACE_ID!,
  accessToken: process.env.CONTENTFUL_PREVIEW_TOKEN!,
  host: "preview.contentful.com",
});

export function getClient(preview = false) {
  return preview ? previewClient : client;
}
```

### Sanity client setup
```tsx
// src/lib/sanity.ts
import "server-only";
import { createClient } from "@sanity/client";

export const sanityClient = createClient({
  projectId: process.env.SANITY_PROJECT_ID!,
  dataset: process.env.SANITY_DATASET ?? "production",
  apiVersion: "2024-01-01",
  useCdn: process.env.NODE_ENV === "production",
  token: process.env.SANITY_API_TOKEN, // Only for authenticated queries
});

export const previewClient = createClient({
  projectId: process.env.SANITY_PROJECT_ID!,
  dataset: process.env.SANITY_DATASET ?? "production",
  apiVersion: "2024-01-01",
  useCdn: false,
  token: process.env.SANITY_API_TOKEN,
  perspective: "previewDrafts",
});
```

### Type-safe content fetching
```tsx
// src/lib/content.ts
import "server-only";
import { z } from "zod";
import { getClient } from "@/lib/contentful";
import { cache } from "react";

const BlogPostSchema = z.object({
  title: z.string(),
  slug: z.string(),
  body: z.string(),
  publishedAt: z.string().datetime(),
  author: z.object({ name: z.string(), avatar: z.string().url().optional() }),
});

type BlogPost = z.infer<typeof BlogPostSchema>;

export const getBlogPosts = cache(async (preview = false): Promise<BlogPost[]> => {
  const client = getClient(preview);
  const entries = await client.getEntries({ content_type: "blogPost", order: ["-sys.createdAt"] });

  return entries.items.map((item) =>
    BlogPostSchema.parse({
      title: item.fields.title,
      slug: item.fields.slug,
      body: item.fields.body,
      publishedAt: item.sys.createdAt,
      author: item.fields.author,
    })
  );
});

export const getBlogPost = cache(async (slug: string, preview = false) => {
  const client = getClient(preview);
  const entries = await client.getEntries({
    content_type: "blogPost",
    "fields.slug": slug,
    limit: 1,
  });
  if (!entries.items[0]) return null;
  return BlogPostSchema.parse(entries.items[0].fields);
});
```

### MDX rendering in Server Components
```tsx
// src/components/mdx-content.tsx
import { MDXRemote } from "next-mdx-remote/rsc";
import { Callout } from "@/components/ui/callout";
import { CodeBlock } from "@/components/ui/code-block";

const components = {
  Callout,
  CodeBlock,
  img: (props: React.ComponentProps<"img">) => (
    <img {...props} className="rounded-lg" loading="lazy" />
  ),
};

export function MDXContent({ source }: { source: string }) {
  return <MDXRemote source={source} components={components} />;
}
```

### Draft Mode preview
```tsx
// src/app/api/draft/route.ts
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const secret = searchParams.get("secret");
  const slug = searchParams.get("slug");

  if (secret !== process.env.CONTENTFUL_PREVIEW_SECRET) {
    return new Response("Invalid secret", { status: 401 });
  }

  const draft = await draftMode();
  draft.enable();
  redirect(`/blog/${slug}`);
}
```

### Blog page with draft support
```tsx
// src/app/blog/[slug]/page.tsx
import { draftMode } from "next/headers";
import { getBlogPost } from "@/lib/content";
import { MDXContent } from "@/components/mdx-content";
import { notFound } from "next/navigation";

export default async function BlogPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const { isEnabled: preview } = await draftMode();
  const post = await getBlogPost(slug, preview);

  if (!post) notFound();

  return (
    <article className="prose dark:prose-invert max-w-2xl mx-auto">
      <h1>{post.title}</h1>
      <MDXContent source={post.body} />
    </article>
  );
}
```

### CMS webhook revalidation
```tsx
// src/app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const secret = request.headers.get("x-webhook-secret");
  if (secret !== process.env.REVALIDATION_SECRET) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  revalidateTag("cms-content");
  return NextResponse.json({ revalidated: true });
}
```

### Static generation for CMS pages
```tsx
// src/app/blog/[slug]/page.tsx (add)
export async function generateStaticParams() {
  const posts = await getBlogPosts();
  return posts.map((post) => ({ slug: post.slug }));
}
```

## Anti-pattern

### Fetching CMS data in Client Components
CMS data should be fetched in Server Components. Client-side fetching exposes API keys,
adds latency, and bypasses caching. Pass rendered content as props to Client Components
when interactivity is needed.

### No cache invalidation strategy
Without webhook-based revalidation, content updates require a full redeploy. Always set
up CMS webhooks that call your revalidation endpoint.

## Common Mistakes
- Contentful Preview API in production — only use for Draft Mode
- Not validating CMS data with Zod — CMS schemas can change
- Missing `generateStaticParams` — pages not pre-rendered
- `next-mdx-remote` v4 in Server Components — use `/rsc` import
- No fallback for missing CMS entries — use `notFound()`

## Checklist
- [ ] CMS client configured with type-safe queries
- [ ] Content validated with Zod schemas
- [ ] MDX rendering with custom components
- [ ] Draft Mode for content preview
- [ ] Webhook endpoint for cache revalidation
- [ ] `generateStaticParams` for static generation
- [ ] CMS images through `next/image` loader

### Code syntax highlighting
```tsx
// Shiki integration for code blocks in MDX/CMS content
// Install: npm install shiki rehype-pretty-code

// rehype-pretty-code with MDX
import { MDXRemote } from "next-mdx-remote/rsc";
import rehypePrettyCode from "rehype-pretty-code";

const options = {
  theme: "github-dark",
  keepBackground: true,
};

export function MDXContent({ source }: { source: string }) {
  return (
    <MDXRemote
      source={source}
      options={{ mdxOptions: { rehypePlugins: [[rehypePrettyCode, options]] } }}
    />
  );
}
```

```tsx
// Copy-to-clipboard button for code blocks
"use client";

import { useState } from "react";
import { Check, Copy } from "lucide-react";
import { Button } from "@/components/ui/button";

export function CopyButton({ code }: { code: string }) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <Button variant="ghost" size="icon" onClick={handleCopy} className="absolute top-2 right-2">
      {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
    </Button>
  );
}
```

```css
/* Line highlighting with rehype-pretty-code */
/* Add data-highlighted-line attribute to highlight specific lines */
code[data-line-numbers] {
  counter-reset: line;
}

code[data-line-numbers] > [data-line]::before {
  counter-increment: line;
  content: counter(line);
  display: inline-block;
  width: 1rem;
  margin-right: 1rem;
  text-align: right;
  color: gray;
}

[data-highlighted-line] {
  background-color: rgba(200, 200, 255, 0.1);
}
```

## Composes With
- `nextjs-data` — caching strategies for CMS content
- `nextjs-metadata` — dynamic metadata from CMS fields
- `caching` — tag-based revalidation on CMS webhook
- `image-optimization` — CMS image optimization via next/image
- `react-server-components` — server-side MDX rendering
- `seo-advanced` — CMS content SEO
- `dark-mode` — code block themes adapt to light/dark mode
