---
name: responsive-design
description: >
  Container queries, mobile-first breakpoints, touch interactions, viewport-aware rendering
allowed-tools: Read, Grep, Glob
---

# Responsive Design

## Purpose
Responsive design patterns for Next.js 15 with Tailwind v4. Covers mobile-first breakpoints,
container queries, touch target sizing, responsive typography, and viewport-aware rendering.
The ONE skill for responsive layout decisions.

## When to Use
- Making layouts work across mobile, tablet, and desktop
- Using container queries for component-level responsiveness
- Ensuring touch targets meet accessibility minimums
- Implementing responsive typography and spacing
- Choosing between CSS and JS for responsive behavior

## When NOT to Use
- Dashboard layout composition → `layout-patterns`
- CSS utility classes → `tailwind-v4`
- Image responsiveness → `image-optimization`

## Pattern

### Mobile-first breakpoint strategy
```tsx
// Tailwind v4 mobile-first: base styles are mobile, add breakpoints for larger
export function ProductGrid({ products }: { products: Product[] }) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {products.map((p) => (
        <ProductCard key={p.id} product={p} />
      ))}
    </div>
  );
}

// Typography scales up with breakpoints
export function PageTitle({ children }: { children: React.ReactNode }) {
  return (
    <h1 className="text-2xl font-bold sm:text-3xl lg:text-4xl">
      {children}
    </h1>
  );
}
```

### Container queries with Tailwind v4
```tsx
// Component responds to its container size, not viewport
export function Card({ children }: { children: React.ReactNode }) {
  return (
    <div className="@container">
      <div className="flex flex-col @sm:flex-row @sm:items-center gap-4">
        <div className="h-20 w-20 rounded bg-muted @sm:h-16 @sm:w-16" />
        <div className="flex-1">{children}</div>
      </div>
    </div>
  );
}
```

```css
/* Container queries in Tailwind v4 CSS */
@utility card-responsive {
  @container (min-width: 400px) {
    display: grid;
    grid-template-columns: 200px 1fr;
  }
}
```

### Touch target sizing (WCAG 2.5.8)
```tsx
// Minimum 44x44px touch targets for interactive elements
export function ActionButton({ children }: { children: React.ReactNode }) {
  return (
    <button className="min-h-[44px] min-w-[44px] px-4 py-2 text-sm">
      {children}
    </button>
  );
}

// Icon buttons must also meet minimum size
export function IconButton({ icon: Icon, label }: { icon: React.ComponentType<{ className?: string }>; label: string }) {
  return (
    <button className="flex h-11 w-11 items-center justify-center rounded-md" aria-label={label}>
      <Icon className="h-5 w-5" />
    </button>
  );
}
```

### Responsive typography with clamp()
```css
/* app/globals.css */
@theme {
  --font-size-fluid-sm: clamp(0.875rem, 0.8rem + 0.25vw, 1rem);
  --font-size-fluid-base: clamp(1rem, 0.9rem + 0.5vw, 1.25rem);
  --font-size-fluid-lg: clamp(1.25rem, 1rem + 1vw, 2rem);
  --font-size-fluid-xl: clamp(1.5rem, 1rem + 2vw, 3rem);
}
```

```tsx
<h1 className="text-[length:var(--font-size-fluid-xl)] font-bold">
  Fluid heading
</h1>
```

### useMediaQuery hook for conditional rendering
```tsx
"use client";

import { useState, useEffect } from "react";

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(query);
    setMatches(media.matches);

    function listener(e: MediaQueryListEvent) {
      setMatches(e.matches);
    }
    media.addEventListener("change", listener);
    return () => media.removeEventListener("change", listener);
  }, [query]);

  return matches;
}

// Usage
function Navigation() {
  const isDesktop = useMediaQuery("(min-width: 768px)");
  return isDesktop ? <DesktopNav /> : <MobileNav />;
}
```

### Responsive grid patterns
```tsx
// Auto-fit grid: cards fill available space
<div className="grid grid-cols-[repeat(auto-fit,minmax(280px,1fr))] gap-4">
  {items.map((item) => <Card key={item.id} {...item} />)}
</div>

// Responsive spacing
<section className="px-4 py-8 sm:px-6 lg:px-8 lg:py-12">
  {children}
</section>

// Stack → row pattern
<div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
  <h2>Title</h2>
  <Button>Action</Button>
</div>
```

### Viewport units for mobile browser chrome
```tsx
// dvh accounts for mobile browser chrome (address bar, toolbar)
<div className="h-dvh"> {/* NOT h-screen — h-screen ignores mobile chrome */}
  <main className="flex-1 overflow-auto">...</main>
</div>
```

### Pointer-type detection
```css
/* Larger touch targets on touch devices */
@media (pointer: coarse) {
  .interactive {
    min-height: 44px;
    min-width: 44px;
  }
}

/* Precise hover effects only for mouse devices */
@media (hover: hover) and (pointer: fine) {
  .card:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-lg);
  }
}
```

## Anti-pattern

```tsx
// WRONG: hiding content instead of restructuring
<div className="hidden md:block">Desktop content</div>
<div className="md:hidden">Mobile content</div>
// Renders BOTH, doubles DOM — use responsive CSS to restructure instead

// WRONG: using window.innerWidth for responsive behavior
"use client";
const isMobile = window.innerWidth < 768; // SSR crash, no reactivity
// CORRECT: use CSS media queries or useMediaQuery hook

// WRONG: fixed px values for spacing
<div className="p-[32px]"> {/* Doesn't scale */}
// CORRECT: use responsive spacing
<div className="p-4 sm:p-6 lg:p-8">
```

## Common Mistakes
- Using `hidden md:block` instead of restructuring layout — doubles DOM content
- Using `window.innerWidth` directly — crashes SSR, not reactive
- Using `h-screen` instead of `h-dvh` — ignores mobile browser chrome
- Fixed pixel spacing that doesn't scale across breakpoints
- Touch targets smaller than 44x44px — fails WCAG 2.5.8
- Hover effects without `@media (hover: hover)` — broken on touch devices

## Checklist
- [ ] Mobile-first breakpoint strategy (`sm:` → `md:` → `lg:`)
- [ ] Touch targets minimum 44x44px (use `min-h-[44px] min-w-[44px]`)
- [ ] Container queries (`@container`) for component-level responsiveness
- [ ] `h-dvh` instead of `h-screen` for full-height on mobile
- [ ] Hover effects gated with `@media (hover: hover)`
- [ ] Responsive typography with `clamp()` or breakpoint variants
- [ ] Test at 375px (mobile), 768px (tablet), 1280px (desktop)

### Device-specific patterns
```css
/* Safe area insets for notch/island devices */
.full-bleed-footer {
  padding-bottom: env(safe-area-inset-bottom, 0);
  padding-left: env(safe-area-inset-left, 0);
  padding-right: env(safe-area-inset-right, 0);
}
```

```tsx
// touch-action: manipulation — prevents 300ms tap delay
<button className="touch-action-manipulation">
  Instant tap response
</button>

// -webkit-tap-highlight-color — set intentionally
// transparent: clean look, or themed: visual feedback
<a className="[-webkit-tap-highlight-color:transparent]" href="/page">
  Link
</a>

// overscroll-behavior: contain — prevent scroll chaining in modals/drawers
<div className="overflow-y-auto overscroll-contain h-full">
  {/* Scrolling inside modal doesn't scroll the page behind it */}
</div>

// During drag operations:
// 1. Disable text selection
// 2. Add inert to dragged elements
<div
  className={cn(isDragging && "select-none")}
  // inert prevents interaction with the element being dragged
  {...(isDragging ? { inert: "" } : {})}
>
  Draggable item
</div>
```

### Microinteractions & Responsive Motion

#### Animated layout transitions on breakpoint changes
```tsx
"use client";
import { motion } from "motion/react";

// Cards animate to new positions when grid columns change
export function ResponsiveCardGrid({ items }: { items: Item[] }) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {items.map((item) => (
        <motion.div
          key={item.id}
          layout // Animate position changes when grid reflows
          transition={{ type: "spring", stiffness: 300, damping: 30 }}
          className="rounded-xl border bg-card p-6"
        >
          {item.title}
        </motion.div>
      ))}
    </div>
  );
}
```

#### Touch feedback — scale on press for mobile
```tsx
"use client";
import { motion } from "motion/react";

// Visual "press" feedback replaces hover on touch devices
export function TouchCard({ children, onClick }: {
  children: React.ReactNode;
  onClick: () => void;
}) {
  return (
    <motion.button
      onClick={onClick}
      whileTap={{ scale: 0.97 }}
      whileHover={{ scale: 1.02 }} // Desktop only (CSS gates hover)
      transition={{ type: "spring", stiffness: 400, damping: 25 }}
      className="w-full rounded-xl border bg-card p-6 text-left"
    >
      {children}
    </motion.button>
  );
}
```

#### Responsive animation timing — reduce on mobile
```tsx
"use client";
import { useMediaQuery } from "@/hooks/useMediaQuery";

// Slower, simpler animations on mobile for performance
export function useResponsiveMotion() {
  const isMobile = useMediaQuery("(max-width: 640px)");
  const prefersReduced = useMediaQuery("(prefers-reduced-motion: reduce)");

  if (prefersReduced) return { duration: 0, stiffness: 999, damping: 99 };
  if (isMobile) return { duration: 0.2, stiffness: 400, damping: 30 };
  return { duration: 0.4, stiffness: 300, damping: 25 };
}
```

#### Responsive modular spacing scale
```css
/* app/globals.css — spacing scales up with viewport */
@theme {
  /* Base unit grows: 4px mobile → 6px desktop */
  --spacing-section: clamp(3rem, 2rem + 4vw, 6rem);
  --spacing-card: clamp(1rem, 0.75rem + 1vw, 1.5rem);
  --spacing-stack: clamp(0.75rem, 0.5rem + 0.75vw, 1.25rem);
}
```

```tsx
// Sections breathe more on larger screens
<section className="py-[length:var(--spacing-section)]">
  <div className="space-y-[length:var(--spacing-stack)]">
    {children}
  </div>
</section>
```

#### Scroll-to-top with responsive placement
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";

export function ScrollToTopResponsive({ visible }: { visible: boolean }) {
  return (
    <AnimatePresence>
      {visible && (
        <motion.button
          initial={{ opacity: 0, scale: 0.8, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.8, y: 20 }}
          transition={{ type: "spring", stiffness: 300, damping: 25 }}
          onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
          className={cn(
            "fixed z-50 rounded-full bg-primary p-3 text-primary-foreground shadow-lg",
            // Mobile: center bottom, Desktop: bottom-right
            "bottom-6 left-1/2 -translate-x-1/2 sm:left-auto sm:right-6 sm:translate-x-0"
          )}
          aria-label="Scroll to top"
        >
          <ArrowUp className="h-5 w-5" />
        </motion.button>
      )}
    </AnimatePresence>
  );
}
```

## Composes With
- `tailwind-v4` — breakpoint utilities, container queries, responsive classes
- `accessibility` — touch target sizing, focus indicators
- `performance` — responsive images, conditional loading
- `image-optimization` — responsive image `sizes` attribute
- `layout-patterns` — responsive sidebar, mobile navigation
- `visual-design` — spacing rhythm and hierarchy adapt across breakpoints
- `animation` — responsive motion timing, layout animations on reflow
- `advanced-typography` — fluid type scale with clamp()
