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

### Form Animations

**Floating Label Input** — label starts as placeholder, floats up on focus/value:

```tsx
"use client";

import { useState, type InputHTMLAttributes } from "react";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";

type FloatingLabelInputProps = Omit<InputHTMLAttributes<HTMLInputElement>, "placeholder"> & {
  label: string;
  error?: string;
};

export function FloatingLabelInput({
  label,
  error,
  id,
  className,
  onFocus,
  onBlur,
  value,
  defaultValue,
  ...props
}: FloatingLabelInputProps) {
  const [isFocused, setIsFocused] = useState(false);
  const [hasValue, setHasValue] = useState(!!value || !!defaultValue);
  const isFloating = isFocused || hasValue;

  return (
    <div className="relative">
      <input
        id={id}
        value={value}
        defaultValue={defaultValue}
        placeholder=" "
        aria-invalid={!!error}
        aria-describedby={error ? `${id}-error` : undefined}
        className={cn(
          "peer w-full rounded-lg border border-zinc-300 bg-transparent px-4 pb-2 pt-6 text-sm outline-none transition-colors",
          "focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20",
          "dark:border-zinc-700 dark:focus:border-brand-400",
          error && "border-red-500 focus:border-red-500 focus:ring-red-500/20",
          className,
        )}
        onFocus={(e) => {
          setIsFocused(true);
          onFocus?.(e);
        }}
        onBlur={(e) => {
          setIsFocused(false);
          setHasValue(!!e.target.value);
          onBlur?.(e);
        }}
        onChange={(e) => {
          setHasValue(!!e.target.value);
          props.onChange?.(e);
        }}
        {...props}
      />
      <motion.label
        htmlFor={id}
        animate={{
          y: isFloating ? -12 : 0,
          scale: isFloating ? 0.75 : 1,
        }}
        transition={{ type: "spring", stiffness: 300, damping: 25 }}
        className={cn(
          "pointer-events-none absolute left-4 top-4 origin-left text-sm text-zinc-500",
          "dark:text-zinc-400",
          isFocused && "text-brand-500 dark:text-brand-400",
          error && "text-red-500",
        )}
      >
        {label}
      </motion.label>
      {error && (
        <p id={`${id}-error`} className="mt-1 text-xs text-red-500" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
```

CSS-only alternative using Tailwind `peer` utilities (no JS needed):

```tsx
export function FloatingLabelInputCSS({ label, id }: { label: string; id: string }) {
  return (
    <div className="relative">
      <input
        id={id}
        placeholder=" "
        className="peer w-full rounded-lg border border-zinc-300 bg-transparent px-4 pb-2 pt-6 text-sm outline-none focus:border-brand-500 dark:border-zinc-700"
      />
      <label
        htmlFor={id}
        className="pointer-events-none absolute left-4 top-4 origin-left text-sm text-zinc-500 transition-all duration-200 peer-focus:-translate-y-3 peer-focus:scale-75 peer-focus:text-brand-500 peer-[&:not(:placeholder-shown)]:-translate-y-3 peer-[&:not(:placeholder-shown)]:scale-75"
      >
        {label}
      </label>
    </div>
  );
}
```

**Animated Checkbox** — SVG checkmark draws on check with pathLength animation:

```tsx
"use client";

import { useState } from "react";
import { motion, type Variants } from "motion/react";
import { cn } from "@/lib/utils";

type AnimatedCheckboxProps = {
  checked?: boolean;
  defaultChecked?: boolean;
  onCheckedChange?: (checked: boolean) => void;
  label: string;
  id?: string;
  disabled?: boolean;
};

const tickVariants: Variants = {
  unchecked: { pathLength: 0, opacity: 0 },
  checked: { pathLength: 1, opacity: 1 },
};

const boxVariants: Variants = {
  unchecked: { scale: 1, fill: "transparent" },
  checked: { scale: 1, fill: "currentColor" },
};

export function AnimatedCheckbox({
  checked: controlledChecked,
  defaultChecked = false,
  onCheckedChange,
  label,
  id,
  disabled = false,
}: AnimatedCheckboxProps) {
  const [internalChecked, setInternalChecked] = useState(defaultChecked);
  const isChecked = controlledChecked ?? internalChecked;

  function toggle() {
    if (disabled) return;
    const next = !isChecked;
    setInternalChecked(next);
    onCheckedChange?.(next);
  }

  return (
    <label
      htmlFor={id}
      className={cn(
        "inline-flex cursor-pointer items-center gap-3 select-none",
        disabled && "cursor-not-allowed opacity-50",
      )}
    >
      <input
        id={id}
        type="checkbox"
        checked={isChecked}
        onChange={toggle}
        disabled={disabled}
        className="sr-only"
        aria-label={label}
      />
      <motion.svg
        width="22"
        height="22"
        viewBox="0 0 22 22"
        initial={false}
        animate={isChecked ? "checked" : "unchecked"}
        className="text-brand-500"
      >
        <motion.rect
          x="1"
          y="1"
          width="20"
          height="20"
          rx="6"
          stroke="currentColor"
          strokeWidth="2"
          variants={boxVariants}
          transition={{ duration: 0.2 }}
          className={cn(
            isChecked ? "text-brand-500" : "text-zinc-400 dark:text-zinc-600",
          )}
        />
        <motion.path
          d="M6 11.5L9.5 15L16 7"
          fill="none"
          stroke="white"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          variants={tickVariants}
          transition={{ type: "spring", stiffness: 400, damping: 30, delay: 0.1 }}
        />
      </motion.svg>
      <span className="text-sm text-zinc-700 dark:text-zinc-300">{label}</span>
    </label>
  );
}
```

### Icon Transitions

**Menu to X Morph** — hamburger lines rotate/translate into an X using transforms (not `d` attribute animation, which Motion does not support):

```tsx
"use client";

import { motion, type Variants } from "motion/react";

type MenuIconProps = {
  isOpen: boolean;
  onToggle: () => void;
  size?: number;
  className?: string;
};

const topLine: Variants = {
  closed: { rotate: 0, y: 0 },
  open: { rotate: 45, y: 6 },
};

const middleLine: Variants = {
  closed: { opacity: 1 },
  open: { opacity: 0 },
};

const bottomLine: Variants = {
  closed: { rotate: 0, y: 0 },
  open: { rotate: -45, y: -6 },
};

const transition = { type: "spring", stiffness: 300, damping: 25 };

export function MenuIcon({ isOpen, onToggle, size = 24, className }: MenuIconProps) {
  const state = isOpen ? "open" : "closed";

  return (
    <button
      type="button"
      onClick={onToggle}
      aria-label={isOpen ? "Close menu" : "Open menu"}
      aria-expanded={isOpen}
      className={className}
    >
      <svg width={size} height={size} viewBox="0 0 24 24" className="stroke-current text-zinc-700 dark:text-zinc-300">
        <motion.line
          x1="4" y1="6" x2="20" y2="6"
          variants={topLine}
          animate={state}
          transition={transition}
          strokeWidth="2"
          strokeLinecap="round"
          style={{ transformOrigin: "center" }}
        />
        <motion.line
          x1="4" y1="12" x2="20" y2="12"
          variants={middleLine}
          animate={state}
          transition={{ duration: 0.15 }}
          strokeWidth="2"
          strokeLinecap="round"
        />
        <motion.line
          x1="4" y1="18" x2="20" y2="18"
          variants={bottomLine}
          animate={state}
          transition={transition}
          strokeWidth="2"
          strokeLinecap="round"
          style={{ transformOrigin: "center" }}
        />
      </svg>
    </button>
  );
}
```

**Play/Pause Crossfade** — opacity crossfade between play triangle and pause bars (Motion does not support animating the SVG `d` attribute directly):

```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";

type PlayPauseIconProps = {
  isPlaying: boolean;
  onToggle: () => void;
  size?: number;
  className?: string;
};

export function PlayPauseIcon({ isPlaying, onToggle, size = 24, className }: PlayPauseIconProps) {
  return (
    <button
      type="button"
      onClick={onToggle}
      aria-label={isPlaying ? "Pause" : "Play"}
      className={className}
    >
      <svg width={size} height={size} viewBox="0 0 24 24" className="text-zinc-700 dark:text-zinc-300">
        <AnimatePresence mode="wait">
          {isPlaying ? (
            <motion.g
              key="pause"
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.8 }}
              transition={{ duration: 0.15 }}
              style={{ transformOrigin: "center" }}
            >
              <rect x="6" y="4" width="4" height="16" rx="1" fill="currentColor" />
              <rect x="14" y="4" width="4" height="16" rx="1" fill="currentColor" />
            </motion.g>
          ) : (
            <motion.g
              key="play"
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.8 }}
              transition={{ duration: 0.15 }}
              style={{ transformOrigin: "center" }}
            >
              <path d="M6 4l14 8l-14 8z" fill="currentColor" />
            </motion.g>
          )}
        </AnimatePresence>
      </svg>
    </button>
  );
}
```

### Toggle Morphs

**iOS-style Animated Toggle** — pill toggle with spring-physics knob:

```tsx
"use client";

import { useState } from "react";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";

type AnimatedToggleProps = {
  checked?: boolean;
  defaultChecked?: boolean;
  onCheckedChange?: (checked: boolean) => void;
  label: string;
  disabled?: boolean;
};

export function AnimatedToggle({
  checked: controlledChecked,
  defaultChecked = false,
  onCheckedChange,
  label,
  disabled = false,
}: AnimatedToggleProps) {
  const [internalChecked, setInternalChecked] = useState(defaultChecked);
  const isChecked = controlledChecked ?? internalChecked;

  function toggle() {
    if (disabled) return;
    const next = !isChecked;
    setInternalChecked(next);
    onCheckedChange?.(next);
  }

  return (
    <label
      className={cn(
        "inline-flex cursor-pointer items-center gap-3 select-none",
        disabled && "cursor-not-allowed opacity-50",
      )}
    >
      <button
        type="button"
        role="switch"
        aria-checked={isChecked}
        aria-label={label}
        disabled={disabled}
        onClick={toggle}
        className={cn(
          "relative h-8 w-14 rounded-full p-1 transition-colors duration-200",
          isChecked
            ? "bg-green-500 dark:bg-green-600"
            : "bg-zinc-300 dark:bg-zinc-600",
        )}
      >
        <motion.div
          layout
          transition={{ type: "spring", stiffness: 500, damping: 30 }}
          className={cn(
            "size-6 rounded-full bg-white shadow-md",
            isChecked && "ml-auto",
          )}
        />
      </button>
      <span className="text-sm text-zinc-700 dark:text-zinc-300">{label}</span>
    </label>
  );
}
```

### Ripple Effects

**Material Click Ripple** — expanding circle from click position that fades out:

```tsx
"use client";

import { useState, useCallback, type MouseEvent, type ReactNode } from "react";
import { motion, AnimatePresence } from "motion/react";
import { cn } from "@/lib/utils";

type RippleItem = {
  id: number;
  x: number;
  y: number;
  size: number;
};

function useRipple() {
  const [ripples, setRipples] = useState<RippleItem[]>([]);

  const addRipple = useCallback((e: MouseEvent<HTMLElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height) * 2;
    const x = e.clientX - rect.left - size / 2;
    const y = e.clientY - rect.top - size / 2;

    setRipples((prev) => [...prev, { id: Date.now(), x, y, size }]);
  }, []);

  const removeRipple = useCallback((id: number) => {
    setRipples((prev) => prev.filter((r) => r.id !== id));
  }, []);

  return { ripples, addRipple, removeRipple };
}

type RippleContainerProps = {
  children: ReactNode;
  className?: string;
  color?: string;
};

export function RippleContainer({
  children,
  className,
  color = "rgba(255, 255, 255, 0.35)",
}: RippleContainerProps) {
  const { ripples, addRipple, removeRipple } = useRipple();

  return (
    <div
      className={cn("relative overflow-hidden", className)}
      onMouseDown={addRipple}
    >
      {children}
      <AnimatePresence>
        {ripples.map((ripple) => (
          <motion.span
            key={ripple.id}
            initial={{ scale: 0, opacity: 1 }}
            animate={{ scale: 1, opacity: 0 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.6, ease: "easeOut" }}
            onAnimationComplete={() => removeRipple(ripple.id)}
            className="pointer-events-none absolute rounded-full"
            style={{
              left: ripple.x,
              top: ripple.y,
              width: ripple.size,
              height: ripple.size,
              backgroundColor: color,
            }}
          />
        ))}
      </AnimatePresence>
    </div>
  );
}

// Usage: wrap any button or card
// <RippleContainer className="inline-flex">
//   <button className="rounded-lg bg-brand-500 px-6 py-3 text-white">
//     Click me
//   </button>
// </RippleContainer>
```

### Progress Rings

**Circular SVG Progress Ring** — animated ring with determinate and indeterminate modes:

```tsx
"use client";

import { motion } from "motion/react";
import { cn } from "@/lib/utils";

type ProgressRingProps = {
  value?: number; // 0-100, omit for indeterminate
  size?: number;
  strokeWidth?: number;
  className?: string;
  trackColor?: string;
  ringColor?: string;
  label?: string;
};

export function ProgressRing({
  value,
  size = 80,
  strokeWidth = 6,
  className,
  trackColor = "text-zinc-200 dark:text-zinc-700",
  ringColor = "text-brand-500",
  label,
}: ProgressRingProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const center = size / 2;
  const isDeterminate = value !== undefined;
  const clampedValue = isDeterminate ? Math.min(100, Math.max(0, value)) : 0;

  return (
    <div
      role="progressbar"
      aria-valuenow={isDeterminate ? clampedValue : undefined}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-label={label ?? (isDeterminate ? `${clampedValue}% complete` : "Loading")}
      className={cn("relative inline-flex items-center justify-center", className)}
    >
      <svg width={size} height={size} className="-rotate-90">
        {/* Track */}
        <circle
          cx={center}
          cy={center}
          r={radius}
          fill="none"
          stroke="currentColor"
          strokeWidth={strokeWidth}
          className={trackColor}
        />
        {/* Progress arc */}
        {isDeterminate ? (
          <motion.circle
            cx={center}
            cy={center}
            r={radius}
            fill="none"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            strokeLinecap="round"
            strokeDasharray={circumference}
            initial={{ strokeDashoffset: circumference }}
            animate={{ strokeDashoffset: circumference - (clampedValue / 100) * circumference }}
            transition={{ type: "spring", stiffness: 100, damping: 20 }}
            className={ringColor}
          />
        ) : (
          <motion.circle
            cx={center}
            cy={center}
            r={radius}
            fill="none"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            strokeLinecap="round"
            strokeDasharray={`${circumference * 0.25} ${circumference * 0.75}`}
            animate={{ rotate: 360 }}
            transition={{ repeat: Infinity, duration: 1.2, ease: "linear" }}
            style={{ transformOrigin: "center" }}
            className={ringColor}
          />
        )}
      </svg>
      {/* Center label */}
      {isDeterminate && (
        <motion.span
          key={clampedValue}
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          className="absolute text-sm font-semibold text-zinc-700 dark:text-zinc-300"
        >
          {clampedValue}%
        </motion.span>
      )}
    </div>
  );
}

// Determinate: <ProgressRing value={75} />
// Indeterminate: <ProgressRing />
```

## Advanced Patterns

### GSAP timeline orchestration

For complex multi-step sequences that Motion can't easily express — GSAP timelines give frame-level control.

```tsx
"use client";

import { useRef } from "react";
import { useGSAP } from "@gsap/react";
import gsap from "gsap";

export function HeroRevealSequence() {
  const containerRef = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    const tl = gsap.timeline({ defaults: { ease: "power3.out" } });

    tl.from("[data-anim='bg']", { scaleY: 0, duration: 0.8, transformOrigin: "bottom" })
      .from("[data-anim='heading'] span", { y: 100, opacity: 0, duration: 0.6, stagger: 0.05 }, "-=0.3")
      .from("[data-anim='subtitle']", { y: 30, opacity: 0, duration: 0.5 }, "-=0.2")
      .from("[data-anim='cta']", { scale: 0.8, opacity: 0, duration: 0.4 }, "-=0.1");
  }, { scope: containerRef });

  return (
    <div ref={containerRef} className="relative flex min-h-screen items-center justify-center">
      <div data-anim="bg" className="absolute inset-0 bg-primary/5" />
      <div className="relative text-center">
        <h1 data-anim="heading" className="text-6xl font-bold">
          {"Build faster".split("").map((char, i) => (
            <span key={i} className="inline-block">{char === " " ? "\u00A0" : char}</span>
          ))}
        </h1>
        <p data-anim="subtitle" className="mt-4 text-xl text-muted-foreground">
          Ship products in record time
        </p>
        <button data-anim="cta" className="mt-8 rounded-full bg-primary px-8 py-3 text-primary-foreground">
          Get Started
        </button>
      </div>
    </div>
  );
}
```

### SVG path morphing

Smooth transitions between SVG shapes — for icons, logos, or decorative elements.

```tsx
"use client";

import { motion, useMotionValue, useTransform, animate } from "motion/react";
import { useEffect, useState } from "react";
import { interpolate } from "flubber";

const shapes = [
  "M50,10 L90,90 L10,90 Z",           // Triangle
  "M10,10 L90,10 L90,90 L10,90 Z",     // Square
  "M50,5 A45,45 0 1,1 50,95 A45,45 0 1,1 50,5 Z", // Circle
];

export function MorphingIcon() {
  const [index, setIndex] = useState(0);
  const progress = useMotionValue(0);

  const interpolator = interpolate(
    shapes[index],
    shapes[(index + 1) % shapes.length],
    { maxSegmentLength: 10 }
  );
  const d = useTransform(progress, (v) => interpolator(v));

  useEffect(() => {
    const controls = animate(progress, 1, {
      duration: 1.5,
      ease: "easeInOut",
      onComplete: () => {
        progress.set(0);
        setIndex((prev) => (prev + 1) % shapes.length);
      },
    });
    return () => controls.stop();
  }, [index, progress]);

  return (
    <svg viewBox="0 0 100 100" className="h-24 w-24">
      <motion.path d={d} fill="var(--color-primary)" />
    </svg>
  );
}
```

### Page transition with shared layout

Smooth transition between pages where a card expands into the full page — the layoutId technique.

```tsx
"use client";

import { motion } from "motion/react";
import Link from "next/link";

// In the list page
export function ProjectCard({ id, title, image }: { id: string; title: string; image: string }) {
  return (
    <Link href={`/projects/${id}`}>
      <motion.div layoutId={`project-${id}`} className="overflow-hidden rounded-xl">
        <motion.img layoutId={`project-img-${id}`} src={image} alt="" className="aspect-video w-full object-cover" />
        <motion.h3 layoutId={`project-title-${id}`} className="p-4 text-lg font-semibold">
          {title}
        </motion.h3>
      </motion.div>
    </Link>
  );
}

// In the detail page
export function ProjectHero({ id, title, image }: { id: string; title: string; image: string }) {
  return (
    <motion.div layoutId={`project-${id}`} className="w-full">
      <motion.img layoutId={`project-img-${id}`} src={image} alt="" className="h-[60vh] w-full object-cover" />
      <motion.h1 layoutId={`project-title-${id}`} className="mt-8 text-4xl font-bold">
        {title}
      </motion.h1>
    </motion.div>
  );
}
```

### Text character stagger (reusable)

A reusable component that splits text into characters and staggers them in.

```tsx
"use client";

import { motion } from "motion/react";

export function StaggerText({
  text,
  className,
  staggerDelay = 0.03,
  initialDelay = 0,
}: {
  text: string;
  className?: string;
  staggerDelay?: number;
  initialDelay?: number;
}) {
  return (
    <span className={className} aria-label={text}>
      {text.split("").map((char, i) => (
        <motion.span
          key={i}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{
            delay: initialDelay + i * staggerDelay,
            type: "spring",
            stiffness: 200,
            damping: 20,
          }}
          className="inline-block"
          aria-hidden="true"
        >
          {char === " " ? "\u00A0" : char}
        </motion.span>
      ))}
    </span>
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
- `creative-scrolling` — GSAP ScrollTrigger for scroll-driven animations
- `svg-canvas` — SVG morphing and canvas particle animations
- `loading-transitions` — page transition orchestration
