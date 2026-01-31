---
name: data-tables
description: >
  TanStack Table (headless) with sorting, filtering, pagination, virtualization, shadcn Table rendering
allowed-tools: Read, Grep, Glob
---

# Data Tables

## Purpose
Data table patterns with TanStack Table (headless) and shadcn Table for rendering. Covers
server-side pagination, sorting, filtering, row selection, virtualization for large datasets,
and URL-synced state. The ONE skill for tabular data display.

## When to Use
- Building sortable, filterable data tables
- Implementing server-side pagination with URL state
- Displaying large datasets with virtualization
- Adding row selection and bulk actions
- Building admin dashboards with data grids

## When NOT to Use
- Simple static lists without sorting → plain `<table>` or list component
- Form input tables → `advanced-form-ux`
- Data fetching logic → `nextjs-data`

## Pattern

### Basic table with TanStack Table + shadcn
```tsx
"use client";

import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
  type ColumnDef,
  type SortingState,
} from "@tanstack/react-table";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useState } from "react";

type User = { id: string; name: string; email: string; role: string };

const columns: ColumnDef<User>[] = [
  { accessorKey: "name", header: "Name" },
  { accessorKey: "email", header: "Email" },
  { accessorKey: "role", header: "Role" },
];

export function UsersTable({ data }: { data: User[] }) {
  const [sorting, setSorting] = useState<SortingState>([]);

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    onSortingChange: setSorting,
    state: { sorting },
  });

  return (
    <Table>
      <TableHeader>
        {table.getHeaderGroups().map((hg) => (
          <TableRow key={hg.id}>
            {hg.headers.map((header) => (
              <TableHead
                key={header.id}
                onClick={header.column.getToggleSortingHandler()}
                className="cursor-pointer select-none"
              >
                {flexRender(header.column.columnDef.header, header.getContext())}
                {{ asc: " \u2191", desc: " \u2193" }[header.column.getIsSorted() as string] ?? ""}
              </TableHead>
            ))}
          </TableRow>
        ))}
      </TableHeader>
      <TableBody>
        {table.getRowModel().rows.map((row) => (
          <TableRow key={row.id}>
            {row.getVisibleCells().map((cell) => (
              <TableCell key={cell.id}>
                {flexRender(cell.column.columnDef.cell, cell.getContext())}
              </TableCell>
            ))}
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
```

### Server-side pagination with URL state (nuqs)
```tsx
"use client";

import { useQueryState, parseAsInteger } from "nuqs";

export function PaginatedTable({ totalPages }: { totalPages: number }) {
  const [page, setPage] = useQueryState("page", parseAsInteger.withDefault(1));
  const [perPage] = useQueryState("perPage", parseAsInteger.withDefault(20));

  return (
    <div className="flex items-center gap-2">
      <button onClick={() => setPage(Math.max(1, page - 1))} disabled={page <= 1}>
        Previous
      </button>
      <span>Page {page} of {totalPages}</span>
      <button onClick={() => setPage(Math.min(totalPages, page + 1))} disabled={page >= totalPages}>
        Next
      </button>
    </div>
  );
}
```

```tsx
// Server Component: read URL state and query database
export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; perPage?: string; sort?: string }>;
}) {
  const { page = "1", perPage = "20", sort = "name" } = await searchParams;

  const [users, total] = await Promise.all([
    db.user.findMany({
      skip: (Number(page) - 1) * Number(perPage),
      take: Number(perPage),
      orderBy: { [sort]: "asc" },
    }),
    db.user.count(),
  ]);

  const totalPages = Math.ceil(total / Number(perPage));

  return (
    <>
      <UsersTable data={users} />
      <PaginatedTable totalPages={totalPages} />
    </>
  );
}
```

### Server-side filtering
```tsx
// Server Component with search filter
export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; role?: string }>;
}) {
  const { q, role } = await searchParams;

  const users = await db.user.findMany({
    where: {
      ...(q && { name: { contains: q, mode: "insensitive" } }),
      ...(role && { role }),
    },
  });

  return <UsersTable data={users} />;
}
```

### Row selection with bulk actions
```tsx
"use client";

import { useState } from "react";
import { type RowSelectionState } from "@tanstack/react-table";
import { Checkbox } from "@/components/ui/checkbox";

// Add selection column
const selectionColumn: ColumnDef<User> = {
  id: "select",
  header: ({ table }) => (
    <Checkbox
      checked={table.getIsAllPageRowsSelected()}
      onCheckedChange={(v) => table.toggleAllPageRowsSelected(!!v)}
      aria-label="Select all"
    />
  ),
  cell: ({ row }) => (
    <Checkbox
      checked={row.getIsSelected()}
      onCheckedChange={(v) => row.toggleSelected(!!v)}
      aria-label="Select row"
    />
  ),
};

// Bulk action bar
export function BulkActions({
  selectedCount,
  onDelete,
}: {
  selectedCount: number;
  onDelete: () => void;
}) {
  if (selectedCount === 0) return null;

  return (
    <div className="flex items-center gap-2 rounded-lg bg-muted p-2">
      <span className="text-sm">{selectedCount} selected</span>
      <button onClick={onDelete} className="text-sm text-destructive">
        Delete selected
      </button>
    </div>
  );
}
```

### Virtualized table for large datasets
```tsx
"use client";

import { useVirtualizer } from "@tanstack/react-virtual";
import { useRef } from "react";

export function VirtualizedTable({ rows }: { rows: User[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: rows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 48,
    overscan: 10,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: "relative" }}>
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.key}
            style={{
              position: "absolute",
              top: 0,
              transform: `translateY(${virtualRow.start}px)`,
              height: `${virtualRow.size}px`,
              width: "100%",
            }}
          >
            {rows[virtualRow.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Anti-pattern

```tsx
// WRONG: client-side pagination of all data
const [page, setPage] = useState(1);
const displayed = allUsers.slice((page - 1) * 20, page * 20);
// Fetches ALL users, only shows 20 — wastes bandwidth

// CORRECT: server-side pagination — only fetch current page
const users = await db.user.findMany({
  skip: (page - 1) * 20,
  take: 20,
});

// WRONG: re-fetching everything on sort change
// Each sort triggers full data re-fetch instead of resorting existing data
// For small datasets (<500 rows), use client-side sorting instead
```

## Common Mistakes
- Client-side pagination of server data — fetch only what you display
- Missing `key` prop on table rows causing re-render issues
- Not URL-syncing pagination/sort state — lost on page refresh
- Using client-side sorting for large server datasets — use database ORDER BY
- Rendering 1000+ rows without virtualization — use TanStack Virtual

## Checklist
- [ ] TanStack Table with typed `ColumnDef` array
- [ ] shadcn Table components for rendering
- [ ] Server-side pagination for large datasets (URL state via `nuqs`)
- [ ] Sorting synced to URL searchParams
- [ ] Virtualization added for 500+ row tables
- [ ] Row selection with accessible checkboxes
- [ ] Empty state shown when no data matches filters

## Microinteractions & Visual Polish

Static tables feel like spreadsheets. Polished tables feel like apps — rows animate in, hover states lift, sorting feels physical, and empty states delight.

### Row stagger animation on load
```tsx
"use client";

import { motion } from "motion/react";

const rowVariants = {
  hidden: { opacity: 0, y: 8 },
  visible: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { delay: i * 0.03, type: "spring", stiffness: 400, damping: 25 },
  }),
};

export function AnimatedTableBody({ rows }: { rows: Row[] }) {
  return (
    <TableBody>
      {rows.map((row, i) => (
        <motion.tr
          key={row.id}
          custom={i}
          variants={rowVariants}
          initial="hidden"
          animate="visible"
          className="group transition-colors hover:bg-muted/50"
        >
          {row.getVisibleCells().map((cell) => (
            <TableCell key={cell.id}>
              {flexRender(cell.column.columnDef.cell, cell.getContext())}
            </TableCell>
          ))}
        </motion.tr>
      ))}
    </TableBody>
  );
}
```

### Hover row lift effect
```tsx
// Add to TableRow for subtle depth on hover
<TableRow
  className={cn(
    "transition-all duration-150",
    "hover:bg-muted/50 hover:shadow-[0_2px_8px_-2px_oklch(0_0_0/0.08)]",
    "hover:relative hover:z-10"
  )}
>
```

### Animated sort indicator
```tsx
"use client";

import { motion } from "motion/react";
import { ArrowUp } from "lucide-react";

function SortIcon({ direction }: { direction: false | "asc" | "desc" }) {
  if (!direction) return null;

  return (
    <motion.span
      initial={{ opacity: 0, scale: 0.5 }}
      animate={{ opacity: 1, scale: 1 }}
      className="ml-1 inline-flex"
    >
      <motion.span
        animate={{ rotate: direction === "desc" ? 180 : 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 20 }}
      >
        <ArrowUp className="h-3.5 w-3.5" />
      </motion.span>
    </motion.span>
  );
}

// Usage in header
<TableHead
  onClick={header.column.getToggleSortingHandler()}
  className="cursor-pointer select-none transition-colors hover:text-foreground"
>
  <span className="flex items-center">
    {flexRender(header.column.columnDef.header, header.getContext())}
    <SortIcon direction={header.column.getIsSorted()} />
  </span>
</TableHead>
```

### Loading skeleton during pagination
```tsx
"use client";

function TableSkeleton({ columns, rows = 10 }: { columns: number; rows?: number }) {
  return (
    <TableBody>
      {Array.from({ length: rows }).map((_, i) => (
        <TableRow key={i}>
          {Array.from({ length: columns }).map((_, j) => (
            <TableCell key={j}>
              <div
                className="h-4 animate-pulse rounded bg-muted"
                style={{
                  width: `${60 + Math.random() * 30}%`,
                  animationDelay: `${i * 50 + j * 100}ms`,
                }}
              />
            </TableCell>
          ))}
        </TableRow>
      ))}
    </TableBody>
  );
}
```

### Animated bulk action bar
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";

export function BulkActionBar({
  selectedCount,
  onDelete,
  onExport,
}: {
  selectedCount: number;
  onDelete: () => void;
  onExport: () => void;
}) {
  return (
    <AnimatePresence>
      {selectedCount > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 10, height: 0 }}
          animate={{ opacity: 1, y: 0, height: "auto" }}
          exit={{ opacity: 0, y: 10, height: 0 }}
          transition={{ type: "spring", stiffness: 400, damping: 25 }}
          className="flex items-center gap-3 rounded-lg border bg-primary/5 px-4 py-2"
        >
          <span className="text-sm font-medium">{selectedCount} selected</span>
          <div className="flex gap-2">
            <Button size="sm" variant="outline" onClick={onExport}>Export</Button>
            <Button size="sm" variant="destructive" onClick={onDelete}>Delete</Button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

### Animated empty state
```tsx
"use client";

import { motion } from "motion/react";
import { SearchX } from "lucide-react";

function EmptyState({ query }: { query?: string }) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ type: "spring", stiffness: 300, damping: 25 }}
      className="flex flex-col items-center justify-center py-16 text-center"
    >
      <motion.div
        initial={{ y: 10 }}
        animate={{ y: [0, -4, 0] }}
        transition={{ repeat: Infinity, duration: 3, ease: "easeInOut" }}
      >
        <SearchX className="h-12 w-12 text-muted-foreground/40" />
      </motion.div>
      <h3 className="mt-4 text-lg font-semibold">No results found</h3>
      {query && (
        <p className="mt-1 text-sm text-muted-foreground">
          No items match &ldquo;{query}&rdquo;. Try a different search.
        </p>
      )}
    </motion.div>
  );
}
```

### Row expand/collapse animation
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";

function ExpandableRow({ row, children }: { row: Row; children: React.ReactNode }) {
  const isExpanded = row.getIsExpanded();

  return (
    <>
      <TableRow
        onClick={() => row.toggleExpanded()}
        className="cursor-pointer transition-colors hover:bg-muted/50"
      >
        {row.getVisibleCells().map((cell) => (
          <TableCell key={cell.id}>
            {flexRender(cell.column.columnDef.cell, cell.getContext())}
          </TableCell>
        ))}
      </TableRow>
      <AnimatePresence>
        {isExpanded && (
          <motion.tr
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ type: "spring", stiffness: 300, damping: 25 }}
          >
            <td colSpan={row.getVisibleCells().length} className="p-4 bg-muted/30">
              {children}
            </td>
          </motion.tr>
        )}
      </AnimatePresence>
    </>
  );
}
```

## Composes With
- `shadcn` — Table, Checkbox, Button components for rendering
- `react-client-components` — table interactivity needs "use client"
- `state-management` — URL state with nuqs for pagination/sort
- `nextjs-data` — server-side data fetching for table data
- `react-suspense` — Suspense boundary around table loading
- `virtualization` — virtualized rows for 500+ row tables
- `animation` — Motion library for row stagger, sort indicators, expand/collapse
- `loading-transitions` — skeleton states during data fetching
