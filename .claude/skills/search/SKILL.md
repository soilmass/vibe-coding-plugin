---
name: search
description: >
  Full-text search with Meilisearch — indexing, faceted search, typo tolerance, search analytics, Server Action integration
allowed-tools: Read, Grep, Glob
---

# Search

## Purpose
Full-text search for Next.js 15 using Meilisearch. Covers index management, search Server Actions
with ranking and faceted filtering, incremental indexing via background jobs, and search analytics.

## When to Use
- Adding full-text search to an application
- Building faceted search with filters and sorting
- Implementing search-as-you-type with shadcn Command
- Setting up search index synchronization with database
- Tracking search analytics (popular queries, no-results)

## When NOT to Use
- Simple database filtering → Prisma `where` clauses
- Static content search → `cmd+k` with client-side fuzzy match
- Autocomplete from a fixed list → shadcn Combobox
- Database full-text search (small scale) → PostgreSQL `tsvector`

## Pattern

### Meilisearch client setup
```tsx
// src/lib/search.ts
import "server-only";
import { MeiliSearch } from "meilisearch";

export const searchClient = new MeiliSearch({
  host: process.env.MEILISEARCH_HOST!,
  apiKey: process.env.MEILISEARCH_API_KEY!,
});

export const productsIndex = searchClient.index("products");
```

### Search index configuration
```tsx
// src/lib/search-setup.ts
import "server-only";
import { productsIndex } from "@/lib/search";

export async function configureSearchIndexes() {
  await productsIndex.updateSettings({
    searchableAttributes: ["name", "description", "category"],
    filterableAttributes: ["category", "price", "inStock"],
    sortableAttributes: ["price", "createdAt"],
    typoTolerance: {
      enabled: true,
      minWordSizeForTypos: { oneTypo: 4, twoTypos: 8 },
    },
    synonyms: {
      phone: ["mobile", "smartphone"],
      laptop: ["notebook", "computer"],
    },
  });
}
```

### Search Server Action
```tsx
// src/actions/search.ts
"use server";
import { z } from "zod";
import { productsIndex } from "@/lib/search";

const SearchSchema = z.object({
  query: z.string().min(1).max(200),
  category: z.string().optional(),
  page: z.coerce.number().min(1).default(1),
  sort: z.enum(["relevance", "price_asc", "price_desc"]).default("relevance"),
});

export async function searchProducts(formData: FormData) {
  const parsed = SearchSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { hits: [], totalHits: 0, error: "Invalid search" };

  const { query, category, page, sort } = parsed.data;
  const sortRules = sort === "price_asc" ? ["price:asc"]
    : sort === "price_desc" ? ["price:desc"]
    : undefined;

  const results = await productsIndex.search(query, {
    filter: category ? [`category = "${category}"`] : undefined,
    sort: sortRules,
    page,
    hitsPerPage: 20,
    attributesToHighlight: ["name", "description"],
  });

  return {
    hits: results.hits,
    totalHits: results.estimatedTotalHits,
    facets: results.facetDistribution,
    processingTimeMs: results.processingTimeMs,
  };
}
```

### Incremental indexing via background job
```tsx
// src/inngest/functions/search-index.ts
import { inngest } from "@/lib/inngest";
import { db } from "@/lib/db";
import { productsIndex } from "@/lib/search";

export const indexProduct = inngest.createFunction(
  { id: "search-index-product" },
  { event: "product/created" },
  async ({ event }) => {
    const product = await db.product.findUnique({
      where: { id: event.data.productId },
      select: { id: true, name: true, description: true, category: true, price: true, inStock: true },
    });

    if (product) {
      await productsIndex.addDocuments([product], { primaryKey: "id" });
    }
  }
);

export const removeFromIndex = inngest.createFunction(
  { id: "search-remove-product" },
  { event: "product/deleted" },
  async ({ event }) => {
    await productsIndex.deleteDocument(event.data.productId);
  }
);
```

### Search UI with shadcn Command
```tsx
// src/components/search/search-command.tsx
"use client";
import { useActionState } from "react";
import { Command, CommandInput, CommandList, CommandItem, CommandEmpty } from "@/components/ui/command";
import { searchProducts } from "@/actions/search";

export function SearchCommand() {
  const [state, formAction, isPending] = useActionState(
    async (_prev: unknown, formData: FormData) => searchProducts(formData),
    { hits: [], totalHits: 0 }
  );

  return (
    <Command>
      <form action={formAction}>
        <CommandInput name="query" placeholder="Search products..." />
      </form>
      <CommandList>
        {isPending && <CommandEmpty>Searching...</CommandEmpty>}
        {!isPending && state.hits.length === 0 && <CommandEmpty>No results.</CommandEmpty>}
        {state.hits.map((hit) => (
          <CommandItem key={hit.id} value={hit.name}>
            {hit.name}
          </CommandItem>
        ))}
      </CommandList>
    </Command>
  );
}
```

### Search analytics tracking
```tsx
// Track in Server Action for analytics
import { after } from "next/server";

export async function searchProducts(formData: FormData) {
  // ... search logic
  after(async () => {
    await db.searchLog.create({
      data: {
        query: parsed.data.query,
        totalHits: results.estimatedTotalHits,
        processingTimeMs: results.processingTimeMs,
      },
    });
  });
  // ... return results
}
```

### Meilisearch downtime fallback
```tsx
// Degrade to Prisma query when Meilisearch is unavailable
import { productsIndex } from "@/lib/search";
import { db } from "@/lib/db";

export async function searchWithFallback(query: string) {
  try {
    const results = await productsIndex.search(query, { hitsPerPage: 20 });
    return { hits: results.hits, source: "meilisearch" as const };
  } catch {
    // Fallback: basic Prisma full-text search
    const hits = await db.product.findMany({
      where: {
        OR: [
          { name: { contains: query, mode: "insensitive" } },
          { description: { contains: query, mode: "insensitive" } },
        ],
      },
      take: 20,
    });
    return { hits, source: "database" as const };
  }
}
```

## Anti-pattern

### Synchronous indexing in Server Actions
Don't index documents in the request path. Use background jobs (Inngest) for indexing
to keep Server Action response times fast. The search index can be eventually consistent.

### No index configuration
Default Meilisearch settings search all fields with equal weight. Always configure
`searchableAttributes` to control what's searchable and in what priority order.

## Common Mistakes
- Not setting `filterableAttributes` before using filters — Meilisearch requires explicit declaration
- Using Meilisearch admin API key in production — use a search-only key for read operations
- Re-indexing entire dataset on every change — use incremental indexing
- Not handling Meilisearch downtime — wrap search calls with fallback to database query
- Missing pagination — always set `hitsPerPage` and `page`

## Checklist
- [ ] Meilisearch client configured with env variables
- [ ] Search indexes created with proper settings
- [ ] Search Server Action with Zod validation
- [ ] Incremental indexing via background job on create/update/delete
- [ ] Faceted search UI with category filters
- [ ] Typo tolerance and synonyms configured
- [ ] Search analytics tracking (queries, no-results)
- [ ] Fallback behavior when search service is unavailable

## Composes With
- `prisma` — source of truth for indexable data
- `react-server-actions` — search Server Action pattern
- `shadcn` — Command palette for search UI
- `docker-dev` — Meilisearch in docker-compose
- `background-jobs` — incremental indexing with Inngest
- `analytics` — search query analytics
