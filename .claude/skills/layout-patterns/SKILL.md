---
name: layout-patterns
description: >
  Dashboard shells, responsive sidebars, split views with parallel routes, sticky headers, navigation composition
allowed-tools: Read, Grep, Glob
---

# Layout Patterns

## Purpose
Layout composition patterns for Next.js 15 App Router. Covers dashboard shells, responsive
sidebars, split views with parallel routes, sticky headers, breadcrumbs, and mobile navigation.
The ONE skill for page layout architecture.

## When to Use
- Building dashboard layouts with sidebar navigation
- Creating responsive sidebar (sheet on mobile, fixed on desktop)
- Implementing split-view / master-detail layouts
- Adding sticky headers with scroll-aware behavior
- Building breadcrumb navigation from route segments
- Creating mobile bottom navigation bars

## When NOT to Use
- Route file conventions → `nextjs-routing`
- Component styling → `tailwind-v4`
- Data fetching in layouts → `nextjs-data`

## Pattern

### Dashboard layout with shadcn Sidebar
```tsx
// src/app/dashboard/layout.tsx
import { SidebarProvider, SidebarInset } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>
        <header className="sticky top-0 z-10 flex h-14 items-center gap-4 border-b bg-background px-6">
          {/* Breadcrumbs, search, user menu */}
        </header>
        <main className="flex-1 p-6">{children}</main>
      </SidebarInset>
    </SidebarProvider>
  );
}
```

### Responsive sidebar: Sheet on mobile, fixed on desktop
```tsx
"use client";

import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Menu } from "lucide-react";

export function ResponsiveSidebar({ children }: { children: React.ReactNode }) {
  return (
    <>
      {/* Mobile: Sheet overlay */}
      <Sheet>
        <SheetTrigger asChild className="md:hidden">
          <Button variant="ghost" size="icon">
            <Menu className="h-5 w-5" />
          </Button>
        </SheetTrigger>
        <SheetContent side="left" className="w-64 p-0">
          <nav className="flex flex-col gap-1 p-4">{children}</nav>
        </SheetContent>
      </Sheet>

      {/* Desktop: Fixed sidebar */}
      <aside className="hidden md:flex md:w-64 md:flex-col md:border-r">
        <nav className="flex flex-col gap-1 p-4">{children}</nav>
      </aside>
    </>
  );
}
```

### Split view with parallel routes (master-detail)
```
src/app/dashboard/
├── layout.tsx        # Renders {children} and {detail}
├── page.tsx          # Master list
├── @detail/
│   ├── default.tsx   # Empty state when nothing selected
│   └── [id]/
│       └── page.tsx  # Detail panel for selected item
```

```tsx
// src/app/dashboard/layout.tsx
export default function Layout({
  children,
  detail,
}: {
  children: React.ReactNode;
  detail: React.ReactNode;
}) {
  return (
    <div className="flex h-[calc(100vh-3.5rem)]">
      <div className="w-80 overflow-auto border-r">{children}</div>
      <div className="flex-1 overflow-auto">{detail}</div>
    </div>
  );
}
```

### Sticky header with scroll-aware shadow
```tsx
"use client";

import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";

export function StickyHeader({ children }: { children: React.ReactNode }) {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    function handleScroll() {
      setScrolled(window.scrollY > 0);
    }
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <header
      className={cn(
        "sticky top-0 z-50 flex h-14 items-center border-b bg-background px-6 transition-shadow",
        scrolled && "shadow-sm"
      )}
    >
      {children}
    </header>
  );
}
```

### Full-height layout
```tsx
// Root layout for full-height apps (dashboards, admin panels)
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full">
      <body className="flex h-full flex-col">
        {children}
      </body>
    </html>
  );
}

// Dashboard page using full height
export default function DashboardPage() {
  return (
    <div className="flex h-[calc(100vh-3.5rem)]">
      <aside className="w-64 overflow-auto border-r">Sidebar</aside>
      <main className="flex-1 overflow-auto p-6">Content</main>
    </div>
  );
}
```

### Breadcrumb navigation from route segments
```tsx
"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";

export function DynamicBreadcrumbs() {
  const pathname = usePathname();
  const segments = pathname.split("/").filter(Boolean);

  return (
    <Breadcrumb>
      <BreadcrumbList>
        <BreadcrumbItem>
          <BreadcrumbLink asChild><Link href="/">Home</Link></BreadcrumbLink>
        </BreadcrumbItem>
        {segments.map((segment, i) => {
          const href = `/${segments.slice(0, i + 1).join("/")}`;
          const isLast = i === segments.length - 1;

          return (
            <BreadcrumbItem key={href}>
              <BreadcrumbSeparator />
              {isLast ? (
                <BreadcrumbPage>{segment}</BreadcrumbPage>
              ) : (
                <BreadcrumbLink asChild><Link href={href}>{segment}</Link></BreadcrumbLink>
              )}
            </BreadcrumbItem>
          );
        })}
      </BreadcrumbList>
    </Breadcrumb>
  );
}
```

### Active link highlighting
```tsx
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

export function NavLink({
  href,
  children,
}: {
  href: string;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const isActive = pathname === href || pathname.startsWith(`${href}/`);

  return (
    <Link
      href={href}
      className={cn(
        "flex items-center gap-2 rounded-md px-3 py-2 text-sm transition-colors",
        isActive
          ? "bg-primary/10 text-primary font-medium"
          : "text-muted-foreground hover:bg-muted hover:text-foreground"
      )}
      aria-current={isActive ? "page" : undefined}
    >
      {children}
    </Link>
  );
}
```

### Mobile bottom navigation bar
```tsx
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Search, Bell, User } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/", icon: Home, label: "Home" },
  { href: "/search", icon: Search, label: "Search" },
  { href: "/notifications", icon: Bell, label: "Alerts" },
  { href: "/profile", icon: User, label: "Profile" },
];

export function MobileNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 flex border-t bg-background md:hidden">
      {navItems.map(({ href, icon: Icon, label }) => (
        <Link
          key={href}
          href={href}
          className={cn(
            "flex flex-1 flex-col items-center gap-1 py-2 text-xs",
            pathname === href ? "text-primary" : "text-muted-foreground"
          )}
        >
          <Icon className="h-5 w-5" />
          {label}
        </Link>
      ))}
    </nav>
  );
}
```

### Masonry layout

Two approaches: CSS native masonry (experimental, progressive enhancement) and CSS columns fallback.

> **Browser support (Jan 2026):** `grid-template-rows: masonry` is Firefox-only behind a flag. Safari is pursuing a different spec (`display: grid-lanes` in Safari TP 234). Chrome has no support yet. **Use the columns fallback for production.** The CSS Grid approach is shown for progressive enhancement only.

**Approach 1: CSS native masonry (experimental — NOT production-ready)**

Uses `grid-template-rows: masonry` behind a `@supports` check. No JavaScript required.

```css
/* Add to your global CSS or a CSS module */
@supports (grid-template-rows: masonry) {
  .masonry-grid {
    display: grid;
    grid-template-rows: masonry;
  }
}
```

```tsx
// src/components/masonry-grid.tsx
type MasonryGridProps = {
  children: React.ReactNode;
  className?: string;
};

export function MasonryGrid({ children, className }: MasonryGridProps) {
  return (
    <div
      className={cn(
        "masonry-grid grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4",
        className
      )}
    >
      {children}
    </div>
  );
}
```

**Approach 2: CSS columns fallback**

Uses `columns` property for broad browser support. Limitation: items flow top-to-bottom
per column, not left-to-right across rows.

```tsx
// src/components/masonry-fallback.tsx
import { cn } from "@/lib/utils";

type MasonryFallbackProps = {
  children: React.ReactNode;
  className?: string;
};

export function MasonryFallback({ children, className }: MasonryFallbackProps) {
  return (
    <div className={cn("columns-2 gap-4 md:columns-3 lg:columns-4", className)}>
      {children}
    </div>
  );
}

// Each child should use break-inside-avoid to prevent splitting across columns
function MasonryItem({ children }: { children: React.ReactNode }) {
  return (
    <div className="mb-4 break-inside-avoid">
      {children}
    </div>
  );
}
```

**Combined: progressive enhancement with fallback**

```tsx
// src/components/masonry.tsx
import { cn } from "@/lib/utils";

type MasonryProps = {
  children: React.ReactNode;
  className?: string;
};

// Uses CSS masonry when supported, falls back to CSS columns.
// The .masonry-grid class is defined in global CSS with @supports.
export function Masonry({ children, className }: MasonryProps) {
  return (
    <div
      className={cn(
        // Fallback: CSS columns (works everywhere)
        "columns-2 gap-4 md:columns-3 lg:columns-4",
        // Enhancement: CSS grid masonry (applied via .masonry-grid @supports rule)
        "masonry-grid",
        className
      )}
    >
      {children}
    </div>
  );
}
```

### Broken grid / asymmetric layout

Asymmetric grid layouts create visual tension and editorial feel using CSS Grid
with varying `col-span` and `row-span` values.

```tsx
// src/components/asymmetric-grid.tsx
import { cn } from "@/lib/utils";

type GridItem = {
  id: string;
  title: string;
  description: string;
  imageUrl: string;
  span: string; // Tailwind grid span classes
};

const gridItems: GridItem[] = [
  {
    id: "hero",
    title: "Featured Story",
    description: "The main highlight spanning a large area.",
    imageUrl: "/images/hero.jpg",
    span: "col-span-12 md:col-span-7 md:row-span-2",
  },
  {
    id: "secondary",
    title: "Secondary",
    description: "A supporting piece beside the hero.",
    imageUrl: "/images/secondary.jpg",
    span: "col-span-12 md:col-span-5",
  },
  {
    id: "tertiary",
    title: "Tertiary",
    description: "Fills remaining space in the top row.",
    imageUrl: "/images/tertiary.jpg",
    span: "col-span-12 md:col-span-5",
  },
  {
    id: "offset",
    title: "Offset Piece",
    description: "Intentionally misaligned for visual tension.",
    imageUrl: "/images/offset.jpg",
    span: "col-span-12 md:col-span-4 md:col-start-2",
  },
  {
    id: "overlap",
    title: "Overlapping Element",
    description: "Pulls up into the row above with negative margin.",
    imageUrl: "/images/overlap.jpg",
    span: "col-span-12 md:col-span-6 md:col-start-6",
  },
];

export function AsymmetricGrid() {
  return (
    <section className="mx-auto max-w-7xl px-4">
      <div className="grid grid-cols-12 gap-4 md:gap-6">
        {gridItems.map((item) => (
          <article
            key={item.id}
            className={cn(
              "group overflow-hidden rounded-lg bg-muted",
              item.span,
              // Overlap effect: pull upward on desktop for visual tension
              item.id === "overlap" && "md:-mt-12 relative z-10"
            )}
          >
            <img
              src={item.imageUrl}
              alt={item.title}
              className="h-48 w-full object-cover md:h-full"
              width={800}
              height={600}
            />
            <div className="p-4">
              <h3 className="text-lg font-semibold">{item.title}</h3>
              <p className="mt-1 text-sm text-muted-foreground">
                {item.description}
              </p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
```

Key techniques:
- **12-column grid** gives fine-grained control over asymmetric spans
- **`col-start-*`** offsets items to create intentional misalignment
- **`-mt-12 relative z-10`** pulls elements upward to overlap the row above
- **Responsive**: items stack to full-width `col-span-12` on mobile, asymmetric on `md:` and up

### Overlapping elements

Techniques for layered and overlapping layouts using pure CSS.

**1. Negative margin overlap (card fan)**

Cards that overlap horizontally, each with increasing z-index.

```tsx
// src/components/overlapping-cards.tsx
import { cn } from "@/lib/utils";

type CardData = {
  id: string;
  title: string;
  color: string;
};

const cards: CardData[] = [
  { id: "1", title: "Design", color: "bg-blue-500" },
  { id: "2", title: "Develop", color: "bg-purple-500" },
  { id: "3", title: "Deploy", color: "bg-green-500" },
];

export function OverlappingCards() {
  return (
    <div className="flex items-center justify-center py-12">
      {cards.map((card, index) => (
        <div
          key={card.id}
          className={cn(
            "flex h-48 w-36 flex-col items-center justify-center rounded-xl text-white shadow-lg",
            "transition-transform hover:-translate-y-2",
            card.color,
            // First card has no negative margin; subsequent cards overlap leftward
            index > 0 && "md:-ml-8"
          )}
          // Dynamic z-index — inline style needed for variable count
          style={{ zIndex: index + 1 }}
        >
          <span className="text-lg font-bold">{card.title}</span>
        </div>
      ))}
    </div>
  );
}
```

**2. Offset card stack**

Cards stacked with slight offset and rotation for a fanned effect.

```tsx
// src/components/card-stack.tsx
import { cn } from "@/lib/utils";

type StackItem = {
  id: string;
  title: string;
  offset: string;   // Tailwind translate + rotate classes
  zIndex: string;    // Tailwind z-index class
};

const stackItems: StackItem[] = [
  {
    id: "back",
    title: "Third",
    offset: "translate-x-4 translate-y-4 -rotate-6",
    zIndex: "z-0",
  },
  {
    id: "middle",
    title: "Second",
    offset: "translate-x-2 translate-y-2 -rotate-3",
    zIndex: "z-10",
  },
  {
    id: "front",
    title: "First",
    offset: "translate-x-0 translate-y-0 rotate-0",
    zIndex: "z-20",
  },
];

export function CardStack() {
  return (
    <div className="relative mx-auto h-72 w-64">
      {stackItems.map((item) => (
        <div
          key={item.id}
          className={cn(
            "absolute inset-0 rounded-xl border bg-background p-6 shadow-md",
            "transition-transform duration-300 hover:rotate-0 hover:translate-x-0 hover:translate-y-0",
            item.offset,
            item.zIndex
          )}
        >
          <h3 className="text-lg font-semibold">{item.title}</h3>
          <p className="mt-2 text-sm text-muted-foreground">
            Card content goes here.
          </p>
        </div>
      ))}
    </div>
  );
}
```

**3. Image with overlapping text box**

A hero image with a text block that overlaps it. Stacked on mobile, overlapping
on desktop.

```tsx
// src/components/overlapping-hero.tsx
import { cn } from "@/lib/utils";

type OverlappingHeroProps = {
  imageUrl: string;
  title: string;
  description: string;
  className?: string;
};

export function OverlappingHero({
  imageUrl,
  title,
  description,
  className,
}: OverlappingHeroProps) {
  return (
    <section className={cn("mx-auto max-w-5xl px-4", className)}>
      <div className="relative">
        {/* Image container */}
        <div className="overflow-hidden rounded-xl md:w-3/4">
          <img
            src={imageUrl}
            alt=""
            className="h-64 w-full object-cover md:h-96"
            width={1200}
            height={600}
          />
        </div>

        {/* Overlapping text box */}
        <div
          className={cn(
            "rounded-xl border bg-background p-6 shadow-lg",
            // Mobile: stacked below the image
            "mt-4",
            // Desktop: overlap the image with negative margin and absolute positioning
            "md:absolute md:-bottom-8 md:right-0 md:mt-0 md:w-1/2"
          )}
        >
          <h2 className="text-2xl font-bold tracking-tight">{title}</h2>
          <p className="mt-2 text-muted-foreground">{description}</p>
        </div>
      </div>
    </section>
  );
}
```

All overlapping patterns are Server Components (no `"use client"` needed) since they rely
entirely on CSS for positioning. They are responsive by default: stacked on mobile,
overlapping on `md:` breakpoint and above.

## Anti-pattern

```tsx
// WRONG: nested scroll containers
<div className="h-screen overflow-auto">
  <div className="overflow-auto"> {/* Nested scroll — confusing UX */}
    <div className="overflow-auto"> {/* Even worse */}
    </div>
  </div>
</div>

// WRONG: layout as client component
"use client"; // Don't make layouts client components
export default function Layout({ children }) { ... }
// Layouts should be Server Components — use client wrapper for interactive parts
```

## Common Mistakes
- Making layout files `"use client"` — keep layouts as Server Components
- Nested scroll containers — users can't tell which scrolls
- Missing `overflow-auto` on flex children — content overflows instead of scrolling
- Not using `h-[calc(100vh-headerHeight)]` for full-height panels
- Missing `default.tsx` in parallel route slots — causes 404 on direct navigation

## Checklist
- [ ] Layouts are Server Components (interactive parts extracted to client components)
- [ ] Sidebar collapses to Sheet on mobile
- [ ] Full-height layout uses `h-screen` + `overflow-auto` on scroll containers
- [ ] Active nav link uses `aria-current="page"`
- [ ] Breadcrumbs generated from route segments
- [ ] Parallel routes have `default.tsx` for fallback
- [ ] Only one scroll container per visible area

## Microinteractions & Visual Polish

Static layouts feel like admin templates. Premium layouts have headers that respond to scroll, sidebars that spring open, sections that reveal on viewport entry, and navigation with animated indicators.

### Header with hide/show on scroll direction
```tsx
"use client";

import { useEffect, useState, useRef } from "react";
import { cn } from "@/lib/utils";

export function SmartHeader({ children }: { children: React.ReactNode }) {
  const [hidden, setHidden] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const lastScroll = useRef(0);

  useEffect(() => {
    function handleScroll() {
      const current = window.scrollY;
      setHidden(current > 64 && current > lastScroll.current);
      setScrolled(current > 0);
      lastScroll.current = current;
    }
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <header
      className={cn(
        "sticky top-0 z-50 flex h-14 items-center border-b bg-background/80 px-6 backdrop-blur-lg",
        "transition-all duration-300 ease-out",
        hidden && "-translate-y-full",
        scrolled && "shadow-sm"
      )}
    >
      {children}
    </header>
  );
}
```

### Nav link with animated underline
```tsx
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";

export function AnimatedNavLink({ href, children }: { href: string; children: React.ReactNode }) {
  const pathname = usePathname();
  const isActive = pathname === href || pathname.startsWith(`${href}/`);

  return (
    <Link
      href={href}
      className={cn(
        "relative flex items-center gap-2 px-3 py-2 text-sm transition-colors",
        isActive ? "text-primary font-medium" : "text-muted-foreground hover:text-foreground"
      )}
      aria-current={isActive ? "page" : undefined}
    >
      {children}
      {isActive && (
        <motion.div
          layoutId="nav-indicator"
          className="absolute inset-x-1 -bottom-px h-0.5 rounded-full bg-primary"
          transition={{ type: "spring", stiffness: 350, damping: 30 }}
        />
      )}
    </Link>
  );
}
```

### Section reveal on viewport entry
```tsx
"use client";

import { motion, useInView } from "motion/react";
import { useRef } from "react";

export function RevealSection({
  children,
  className,
  delay = 0,
}: {
  children: React.ReactNode;
  className?: string;
  delay?: number;
}) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-10% 0px" });

  return (
    <motion.section
      ref={ref}
      initial={{ opacity: 0, y: 30 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{
        delay,
        type: "spring",
        stiffness: 200,
        damping: 25,
      }}
      className={className}
    >
      {children}
    </motion.section>
  );
}
```

### Sidebar with spring open/close
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";

export function AnimatedSidebar({
  open,
  children,
}: {
  open: boolean;
  children: React.ReactNode;
}) {
  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-40 bg-black/40 backdrop-blur-sm md:hidden"
          />
          {/* Panel */}
          <motion.aside
            initial={{ x: -280 }}
            animate={{ x: 0 }}
            exit={{ x: -280 }}
            transition={{ type: "spring", stiffness: 300, damping: 28 }}
            className="fixed inset-y-0 left-0 z-50 w-64 border-r bg-background md:hidden"
          >
            <nav className="flex flex-col gap-1 p-4">{children}</nav>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
}
```

### Mobile bottom nav with active indicator
```tsx
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion } from "motion/react";
import { Home, Search, Bell, User } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/", icon: Home, label: "Home" },
  { href: "/search", icon: Search, label: "Search" },
  { href: "/notifications", icon: Bell, label: "Alerts" },
  { href: "/profile", icon: User, label: "Profile" },
];

export function AnimatedMobileNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 flex border-t bg-background/80 pb-safe backdrop-blur-lg md:hidden">
      {navItems.map(({ href, icon: Icon, label }) => {
        const isActive = pathname === href;
        return (
          <Link
            key={href}
            href={href}
            className="relative flex flex-1 flex-col items-center gap-0.5 py-2 text-xs"
          >
            {isActive && (
              <motion.div
                layoutId="mobile-nav-pill"
                className="absolute -top-px h-0.5 w-8 rounded-full bg-primary"
                transition={{ type: "spring", stiffness: 400, damping: 30 }}
              />
            )}
            <Icon className={cn(
              "h-5 w-5 transition-colors",
              isActive ? "text-primary" : "text-muted-foreground"
            )} />
            <span className={cn(
              "transition-colors",
              isActive ? "text-primary font-medium" : "text-muted-foreground"
            )}>
              {label}
            </span>
          </Link>
        );
      })}
    </nav>
  );
}
```

### Parallax hero section
```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function ParallaxHero({
  imageUrl,
  children,
}: {
  imageUrl: string;
  children: React.ReactNode;
}) {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start start", "end start"],
  });

  const y = useTransform(scrollYProgress, [0, 1], [0, 150]);
  const opacity = useTransform(scrollYProgress, [0, 0.8], [1, 0]);

  return (
    <section ref={ref} className="relative h-[80vh] overflow-hidden">
      <motion.img
        src={imageUrl}
        alt=""
        style={{ y }}
        className="absolute inset-0 h-[110%] w-full object-cover"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-background via-background/30 to-transparent" />
      <motion.div
        style={{ opacity }}
        className="relative flex h-full items-end pb-16 px-6"
      >
        {children}
      </motion.div>
    </section>
  );
}
```

## Composes With
- `nextjs-routing` — parallel routes for split views, route groups for layout sharing
- `shadcn` — Sidebar, Sheet, Breadcrumb components
- `react-client-components` — interactive sidebar/header extracted as client components
- `state-management` — sidebar open/close state
- `responsive-design` — responsive sidebar and navigation patterns
- `animation` — Motion library for header, sidebar, nav indicator, section reveals
- `creative-scrolling` — parallax and scroll-triggered layout effects
