---
name: animation
description: >
  Motion library (Framer Motion), CSS transitions, page transitions, microinteractions, prefers-reduced-motion
allowed-tools: Read, Grep, Glob
---

# Animation

## Purpose
Motion and animation patterns for Next.js 15 + React 19. Covers Motion (formerly Framer Motion),
CSS transitions with Tailwind v4, page transitions, and microinteractions. The ONE skill for
animation decisions.

## When to Use
- Adding enter/exit animations to components
- Building page transitions between routes
- Creating microinteractions (hover, press, shimmer)
- Implementing shared element transitions
- Adding loading/skeleton animations

## When NOT to Use
- Loading skeletons without animation → `performance`
- CSS utility styling → `tailwind-v4`
- Accessibility motion preferences (audit) → `accessibility`

## Pattern

### Motion setup (React 19 compatible)
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react"; // NOT "framer-motion"

export function FadeIn({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3, ease: "easeOut" }}
    >
      {children}
    </motion.div>
  );
}
```

### AnimatePresence for enter/exit
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";
import { useState } from "react";

export function TogglePanel() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      <button onClick={() => setIsOpen(!isOpen)}>Toggle</button>
      <AnimatePresence>
        {isOpen && (
          <motion.div
            key="panel"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
          >
            Panel content
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
```

### Shared element transitions with layoutId
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";

export function CardList({
  items,
  selectedId,
  onSelect,
}: {
  items: { id: string; title: string }[];
  selectedId: string | null;
  onSelect: (id: string | null) => void;
}) {
  return (
    <>
      {items.map((item) => (
        <motion.div
          key={item.id}
          layoutId={item.id}
          onClick={() => onSelect(item.id)}
          className="cursor-pointer rounded-lg bg-card p-4"
        >
          <h3>{item.title}</h3>
        </motion.div>
      ))}

      <AnimatePresence>
        {selectedId && (
          <motion.div
            layoutId={selectedId}
            className="fixed inset-0 z-50 flex items-center justify-center"
          >
            <div className="rounded-xl bg-card p-8 shadow-xl">
              <h2>{items.find((i) => i.id === selectedId)?.title}</h2>
              <button onClick={() => onSelect(null)}>Close</button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
```

### CSS-only animations with Tailwind v4
```tsx
// No "use client" needed — pure CSS animations work in Server Components

export function SkeletonCard() {
  return (
    <div className="animate-pulse space-y-3">
      <div className="h-40 rounded-lg bg-muted" />
      <div className="h-4 w-3/4 rounded bg-muted" />
      <div className="h-4 w-1/2 rounded bg-muted" />
    </div>
  );
}

// Hover microinteraction
export function HoverCard({ children }: { children: React.ReactNode }) {
  return (
    <div className="transition-transform duration-200 hover:scale-[1.02] hover:shadow-lg">
      {children}
    </div>
  );
}
```

### CSS entry animations with @starting-style (Tailwind v4)
```css
/* app/globals.css */
@utility fade-in {
  animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

### Page transition with usePathname
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";
import { usePathname } from "next/navigation";

export function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        exit={{ opacity: 0, x: -20 }}
        transition={{ duration: 0.2 }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

### Respecting prefers-reduced-motion
```tsx
"use client";

import { useReducedMotion } from "motion/react";
import { motion } from "motion/react";

export function AnimatedButton({ children }: { children: React.ReactNode }) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.button
      whileHover={shouldReduceMotion ? {} : { scale: 1.05 }}
      whileTap={shouldReduceMotion ? {} : { scale: 0.95 }}
      transition={{ type: "spring", stiffness: 400, damping: 17 }}
    >
      {children}
    </motion.button>
  );
}
```

### Microinteractions
```tsx
// Button press feedback
<motion.button
  whileTap={{ scale: 0.97 }}
  transition={{ duration: 0.1 }}
>
  Click me
</motion.button>

// Hover scale on cards
<motion.div whileHover={{ scale: 1.02 }} transition={{ duration: 0.2 }}>
  <Card />
</motion.div>

// Skeleton shimmer (CSS-only)
<div className="animate-pulse bg-gradient-to-r from-muted via-muted/50 to-muted bg-[length:200%_100%]" />
```

## Anti-pattern

```tsx
// WRONG: animating width/height (triggers layout reflow)
<motion.div animate={{ width: isOpen ? 300 : 0 }} />

// CORRECT: use transform and opacity (GPU-accelerated)
<motion.div
  animate={{ scaleX: isOpen ? 1 : 0, opacity: isOpen ? 1 : 0 }}
  style={{ transformOrigin: "left" }}
/>

// WRONG: animations in Server Components
export default function Page() {
  return <motion.div animate={{ opacity: 1 }} />; // Error! motion needs "use client"
}

// WRONG: importing framer-motion (old package name)
import { motion } from "framer-motion"; // Use "motion/react" for React 19
```

## Common Mistakes
- Importing from `"framer-motion"` instead of `"motion/react"` (React 19 compatibility)
- Using `motion` components in Server Components — they require `"use client"`
- Animating layout properties (width, height) instead of transforms (scale, translate)
- Not wrapping exit animations in `<AnimatePresence>`
- Ignoring `prefers-reduced-motion` — always provide reduced motion alternative
- Adding heavy animation libraries for simple transitions — use CSS `transition-*` instead

## Checklist
- [ ] Import from `"motion/react"` (not `"framer-motion"`)
- [ ] All animated components have `"use client"` directive
- [ ] Exit animations wrapped in `<AnimatePresence>`
- [ ] `prefers-reduced-motion` respected via `useReducedMotion` or CSS media query
- [ ] Animations use `transform`/`opacity` (not `width`/`height`)
- [ ] Simple animations use CSS `transition-*` or `animate-*` instead of JS library

### Animation quality rules
```css
/* NEVER transition: all — list properties explicitly */
/* WRONG: */
.card { transition: all 200ms; }
/* CORRECT: */
.card { transition: transform 200ms, opacity 200ms, box-shadow 200ms; }
```

```tsx
// Set correct transform-origin for scale/rotate
<motion.div
  animate={{ scale: isOpen ? 1 : 0.95 }}
  style={{ transformOrigin: "top left" }} // Expands from anchor point
/>

// SVG transforms: apply to <g> wrapper, not <svg> or individual paths
<svg viewBox="0 0 24 24">
  <g style={{ transformBox: "fill-box", transformOrigin: "center" }}>
    <motion.path animate={{ rotate: 90 }} d="..." />
  </g>
</svg>

// Animations must be interruptible — respond to user input mid-animation
<motion.div
  animate={{ x: isOpen ? 0 : -300 }}
  transition={{ type: "spring", stiffness: 300, damping: 30 }}
  // Spring animations are naturally interruptible — user can toggle mid-animation
/>
// Avoid duration-based animations for interactive elements (not interruptible)
```

### Premium Microinteractions & Scroll Animations

#### Stagger children on mount
```tsx
"use client";

import { motion } from "motion/react";

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.1 },
  },
};

const item = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 },
};

export function StaggerList({ children }: { children: React.ReactNode[] }) {
  return (
    <motion.ul variants={container} initial="hidden" animate="show">
      {children.map((child, i) => (
        <motion.li key={i} variants={item}>
          {child}
        </motion.li>
      ))}
    </motion.ul>
  );
}
```

#### Scroll-triggered reveal
```tsx
"use client";

import { motion, useInView } from "motion/react";
import { useRef } from "react";

export function ScrollReveal({ children }: { children: React.ReactNode }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 40 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 40 }}
      transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}
```

#### Card tilt on hover
```tsx
"use client";

import { motion, useMotionValue, useSpring, useTransform } from "motion/react";

export function TiltCard({ children }: { children: React.ReactNode }) {
  const x = useMotionValue(0.5);
  const y = useMotionValue(0.5);

  const rotateX = useSpring(useTransform(y, [0, 1], [8, -8]), { stiffness: 300, damping: 30 });
  const rotateY = useSpring(useTransform(x, [0, 1], [-8, 8]), { stiffness: 300, damping: 30 });

  function handleMouseMove(e: React.MouseEvent<HTMLDivElement>) {
    const rect = e.currentTarget.getBoundingClientRect();
    x.set((e.clientX - rect.left) / rect.width);
    y.set((e.clientY - rect.top) / rect.height);
  }

  function handleMouseLeave() {
    x.set(0.5);
    y.set(0.5);
  }

  return (
    <motion.div
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      style={{ rotateX, rotateY, transformPerspective: 800 }}
      className="rounded-2xl border bg-card p-6"
    >
      {children}
    </motion.div>
  );
}
```

#### Button shine effect (CSS-only)
```css
/* globals.css */
@keyframes shine {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

@utility btn-shine {
  position: relative;
  overflow: hidden;
  &::after {
    content: "";
    position: absolute;
    inset: 0;
    background: linear-gradient(90deg, transparent, white/20, transparent);
    transform: translateX(-100%);
  }
  &:hover::after {
    animation: shine 0.6s ease-out;
  }
}
```

#### Magnetic button
```tsx
"use client";

import { motion, useMotionValue, useSpring } from "motion/react";

export function MagneticButton({ children }: { children: React.ReactNode }) {
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const springX = useSpring(x, { stiffness: 200, damping: 20 });
  const springY = useSpring(y, { stiffness: 200, damping: 20 });

  function handleMouseMove(e: React.MouseEvent<HTMLButtonElement>) {
    const rect = e.currentTarget.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    x.set((e.clientX - centerX) * 0.3);
    y.set((e.clientY - centerY) * 0.3);
  }

  function handleMouseLeave() {
    x.set(0);
    y.set(0);
  }

  return (
    <motion.button
      style={{ x: springX, y: springY }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      className="rounded-lg bg-brand-500 px-6 py-3 font-medium text-white"
    >
      {children}
    </motion.button>
  );
}
```

#### Number counter on scroll
```tsx
"use client";

import { motion, useInView, useMotionValue, useTransform, animate } from "motion/react";
import { useRef, useEffect } from "react";

export function Counter({ target, label }: { target: number; label: string }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });
  const count = useMotionValue(0);
  const rounded = useTransform(count, (v) => Math.round(v));

  useEffect(() => {
    if (isInView) {
      animate(count, target, { duration: 1.5, ease: [0.22, 1, 0.36, 1] });
    }
  }, [isInView, count, target]);

  return (
    <div ref={ref} className="text-center">
      <motion.span className="text-4xl font-bold tabular-nums">{rounded}</motion.span>
      <p className="mt-1 text-sm text-muted-foreground">{label}</p>
    </div>
  );
}
```

#### Parallax section
```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function ParallaxSection({ children }: { children: React.ReactNode }) {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });
  const y = useTransform(scrollYProgress, [0, 1], ["-10%", "10%"]);

  return (
    <section ref={ref} className="relative overflow-hidden py-24">
      <motion.div style={{ y }} className="absolute inset-0 -z-10">
        <div className="h-full w-full bg-gradient-to-b from-brand-50 to-transparent dark:from-brand-950/30" />
      </motion.div>
      {children}
    </section>
  );
}
```

## Composes With
- `react-client-components` — animations require client components
- `tailwind-v4` — CSS-only animations via utility classes
- `accessibility` — motion must respect reduced motion preferences
- `performance` — animation performance with GPU-accelerated properties
- `shadcn` — animate shadcn components with Motion
- `visual-design` — elevation changes and surface interactions
- `landing-patterns` — hero animations, scroll reveals, stagger entry
