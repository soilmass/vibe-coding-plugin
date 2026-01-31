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

### Premium Content UI Patterns

#### Animated copy button with feedback
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { Check, Copy } from "lucide-react";
import { useState } from "react";

export function AnimatedCopyButton({ code }: { code: string }) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <motion.button
      onClick={handleCopy}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      className="absolute right-2 top-2 flex h-8 w-8 items-center justify-center rounded-lg bg-white/10 backdrop-blur-sm transition-colors hover:bg-white/20"
    >
      <AnimatePresence mode="wait">
        {copied ? (
          <motion.div key="check" initial={{ scale: 0 }} animate={{ scale: 1 }} exit={{ scale: 0 }} transition={{ type: "spring", stiffness: 400, damping: 15 }}>
            <Check className="h-4 w-4 text-green-400" />
          </motion.div>
        ) : (
          <motion.div key="copy" initial={{ scale: 0 }} animate={{ scale: 1 }} exit={{ scale: 0 }}>
            <Copy className="h-4 w-4 text-zinc-400" />
          </motion.div>
        )}
      </AnimatePresence>
    </motion.button>
  );
}
```

#### Article content reveal on scroll
```tsx
"use client";
import { motion, useInView } from "motion/react";
import { useRef } from "react";

export function ContentSection({ children }: { children: React.ReactNode }) {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-60px" });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 20 }}
      animate={inView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
      transition={{ type: "spring", stiffness: 200, damping: 25 }}
    >
      {children}
    </motion.div>
  );
}
```

#### Reading progress bar
```tsx
"use client";
import { motion, useScroll, useSpring } from "motion/react";

export function ReadingProgress() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 });

  return (
    <motion.div
      className="fixed inset-x-0 top-0 z-50 h-0.5 origin-left bg-primary"
      style={{ scaleX }}
    />
  );
}
```

#### Code block with hover glow
```css
/* Premium code block styling */
[data-rehype-pretty-code-figure] pre {
  position: relative;
  overflow-x: auto;
  border-radius: var(--radius-xl);
  border: 1px solid var(--color-border);
  transition: border-color 0.2s, box-shadow 0.3s;
}

[data-rehype-pretty-code-figure] pre:hover {
  border-color: oklch(0.55 0.22 270 / 0.3);
  box-shadow: 0 0 20px oklch(0.55 0.22 270 / 0.06);
}

/* Line highlight with smooth transition */
[data-highlighted-line] {
  background-color: oklch(0.55 0.22 270 / 0.08);
  border-left: 2px solid oklch(0.55 0.22 270 / 0.5);
  transition: background-color 0.2s;
}
```

#### Blog post hero entrance
```tsx
"use client";
import { motion } from "motion/react";

export function ArticleHero({ title, excerpt, author, date }: {
  title: string;
  excerpt?: string;
  author: { name: string; avatar?: string };
  date: string;
}) {
  return (
    <header className="mx-auto max-w-2xl space-y-6 pb-8">
      <motion.h1
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 200, damping: 25 }}
        className="text-4xl font-bold tracking-tight"
      >
        {title}
      </motion.h1>
      {excerpt && (
        <motion.p
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ type: "spring", stiffness: 200, damping: 25, delay: 0.1 }}
          className="text-lg text-muted-foreground"
        >
          {excerpt}
        </motion.p>
      )}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="flex items-center gap-3"
      >
        {author.avatar && (
          <img src={author.avatar} alt="" className="h-8 w-8 rounded-full" />
        )}
        <div className="text-sm">
          <span className="font-medium">{author.name}</span>
          <span className="mx-2 text-muted-foreground">·</span>
          <time className="text-muted-foreground">{date}</time>
        </div>
      </motion.div>
    </header>
  );
}
```

#### Draft mode indicator
```tsx
"use client";
import { motion } from "motion/react";
import { Eye } from "lucide-react";

export function DraftBanner() {
  return (
    <motion.div
      initial={{ y: -40 }}
      animate={{ y: 0 }}
      transition={{ type: "spring", stiffness: 300, damping: 25 }}
      className="fixed inset-x-0 top-0 z-50 flex items-center justify-center gap-2 bg-amber-500 py-1.5 text-sm font-medium text-white"
    >
      <Eye className="h-4 w-4" />
      Draft Preview Mode
      <a href="/api/draft/disable" className="ml-2 rounded bg-white/20 px-2 py-0.5 text-xs hover:bg-white/30">
        Exit
      </a>
    </motion.div>
  );
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
- `animation` — content reveals, copy feedback, reading progress
- `creative-scrolling` — scroll-linked content animations
- `advanced-typography` — article typography hierarchy
