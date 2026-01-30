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

## Composes With
- `nextjs-routing` — parallel routes for split views, route groups for layout sharing
- `shadcn` — Sidebar, Sheet, Breadcrumb components
- `react-client-components` — interactive sidebar/header extracted as client components
- `state-management` — sidebar open/close state
- `responsive-design` — responsive sidebar and navigation patterns
