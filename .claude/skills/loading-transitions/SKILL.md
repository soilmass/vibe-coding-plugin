---
name: loading-transitions
description: >
  Preloader with progress counter, View Transitions API, route transition overlays, staggered reveal sequences, image load reveal, font load detection
allowed-tools: Read, Grep, Glob
---

# Loading & Transitions

## Purpose

Loading and page transition patterns for Next.js 15 + React 19. Covers preloader with progress counter, View Transitions API (`startViewTransition` + CSS), route transition overlays (`AnimatePresence` + pathname key), staggered reveal sequences, image load reveal, and font load detection. No extra packages -- uses Motion (`motion/react`). The ONE skill for first impressions and seamless navigation.

## When to Use

- Adding a branded preloader or splash screen
- Implementing page transition animations between routes
- Using the View Transitions API for smooth route changes
- Creating staggered reveal sequences on page load
- Adding image reveal effects on load complete
- Detecting font loading and preventing FOUT

## When NOT to Use

- Loading skeletons or Suspense boundaries -> use `react-suspense`
- Smooth scroll between sections -> use `creative-scrolling`
- Data loading states and streaming -> use `react-suspense`
- Basic fade in on scroll -> use `animation`

## Pattern

### 1. Preloader with Progress Counter

Branded loading screen with animated counter (0 to 100%). Tracks fonts, critical images, and enforces minimum display time. Skips on return visits via sessionStorage.

```tsx
// src/components/preloader.tsx
"use client";

import { useState, useEffect, useCallback } from "react";
import { AnimatePresence, motion } from "motion/react";

function useLoadingProgress() {
  const [progress, setProgress] = useState(0);
  const [complete, setComplete] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;

    let fontsReady = false;
    let imagesReady = false;
    let timerReady = false;

    function checkAllReady() {
      if (fontsReady && imagesReady && timerReady) {
        setProgress(100);
        setTimeout(() => setComplete(true), 400);
      }
    }

    // Track font loading
    document.fonts.ready.then(() => {
      fontsReady = true;
      setProgress((p) => Math.max(p, 40));
      checkAllReady();
    });

    // Track critical images
    const criticalImages = document.querySelectorAll<HTMLImageElement>(
      "img[data-critical]"
    );
    if (criticalImages.length === 0) {
      imagesReady = true;
      setProgress((p) => Math.max(p, 70));
    } else {
      let loaded = 0;
      criticalImages.forEach((img) => {
        if (img.complete) {
          loaded++;
        } else {
          img.addEventListener("load", () => {
            loaded++;
            setProgress((p) =>
              Math.max(p, 40 + (loaded / criticalImages.length) * 30)
            );
            if (loaded === criticalImages.length) {
              imagesReady = true;
              checkAllReady();
            }
          });
        }
      });
      if (loaded === criticalImages.length) {
        imagesReady = true;
      }
    }

    // Minimum display time (1.5s)
    const timer = setTimeout(() => {
      timerReady = true;
      setProgress((p) => Math.max(p, 90));
      checkAllReady();
    }, 1500);

    checkAllReady();

    return () => clearTimeout(timer);
  }, []);

  return { progress, complete };
}

export function Preloader({ children }: { children: React.ReactNode }) {
  const [showPreloader, setShowPreloader] = useState(true);
  const { progress, complete } = useLoadingProgress();

  useEffect(() => {
    // Skip preloader on repeat visits
    if (sessionStorage.getItem("has-visited")) {
      setShowPreloader(false);
      return;
    }
    if (complete) {
      sessionStorage.setItem("has-visited", "1");
    }
  }, [complete]);

  return (
    <>
      <AnimatePresence>
        {showPreloader && !complete && (
          <motion.div
            className="fixed inset-0 z-[9999] flex flex-col items-center justify-center bg-black"
            exit={{ clipPath: "inset(0 0 100% 0)" }}
            transition={{ duration: 0.8, ease: [0.76, 0, 0.24, 1] }}
          >
            {/* Brand logo or name */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="mb-8 text-2xl font-light tracking-widest text-white uppercase"
            >
              Loading
            </motion.div>

            {/* Progress counter */}
            <motion.span
              className="font-mono text-7xl font-bold tabular-nums text-white"
              key={Math.round(progress)}
            >
              {Math.round(progress)}
            </motion.span>

            {/* Progress bar */}
            <div className="mt-6 h-px w-48 overflow-hidden bg-white/20">
              <motion.div
                className="h-full bg-white"
                initial={{ width: "0%" }}
                animate={{ width: `${progress}%` }}
                transition={{ duration: 0.3, ease: "easeOut" }}
              />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
      {children}
    </>
  );
}
```

### 2. View Transitions API

Custom hook wrapping `document.startViewTransition()` with feature detection. Integrates with Next.js router for route changes.

> **Browser support (Jan 2026):** Same-document (SPA) view transitions are Baseline Available in Chrome, Safari, and Firefox 144+. However, Firefox lacks **view transition types**, which React 19's `<ViewTransition>` component requires. Cross-document (MPA) transitions work in Chrome 126+ and Safari, but not Firefox. Always include feature detection.

```tsx
// src/hooks/use-view-transition.ts
"use client";

import { useCallback } from "react";
import { useRouter } from "next/navigation";
import { startTransition } from "react";

type ViewTransitionCallback = () => void | Promise<void>;

export function useViewTransition() {
  const router = useRouter();

  const startViewTransition = useCallback(
    (callback: ViewTransitionCallback) => {
      if (
        typeof document !== "undefined" &&
        "startViewTransition" in document
      ) {
        document.startViewTransition(() => {
          return new Promise<void>((resolve) => {
            startTransition(async () => {
              await callback();
              resolve();
            });
          });
        });
      } else {
        // Fallback: run without transition
        startTransition(() => {
          callback();
        });
      }
    },
    []
  );

  const navigateWithTransition = useCallback(
    (href: string) => {
      startViewTransition(() => {
        router.push(href);
      });
    },
    [router, startViewTransition]
  );

  return { startViewTransition, navigateWithTransition };
}
```

CSS pseudo-elements for transition control:

```css
/* src/app/globals.css */
@import "tailwindcss";

/* Cross-fade (default) */
::view-transition-old(root) {
  animation: fade-out 0.3s ease-in-out;
}
::view-transition-new(root) {
  animation: fade-in 0.3s ease-in-out;
}

/* Slide transition */
::view-transition-old(slide-content) {
  animation: slide-out-left 0.4s cubic-bezier(0.76, 0, 0.24, 1);
}
::view-transition-new(slide-content) {
  animation: slide-in-right 0.4s cubic-bezier(0.76, 0, 0.24, 1);
}

/* Morph transition for shared elements */
::view-transition-old(hero-image) {
  animation: none;
  mix-blend-mode: normal;
  isolation: auto;
}
::view-transition-new(hero-image) {
  animation: none;
  mix-blend-mode: normal;
  isolation: auto;
}

@keyframes fade-out {
  to { opacity: 0; }
}
@keyframes fade-in {
  from { opacity: 0; }
}
@keyframes slide-out-left {
  to { transform: translateX(-100%); }
}
@keyframes slide-in-right {
  from { transform: translateX(100%); }
}
```

Assign view transition names to elements:

```tsx
// In a Server or Client Component
<div style={{ viewTransitionName: "hero-image" }}>
  <Image src={hero} alt="" fill />
</div>

<main style={{ viewTransitionName: "slide-content" }}>
  {children}
</main>
```

### 3. Route Transition Overlay

App-wide page transitions using AnimatePresence keyed on pathname.

```tsx
// src/components/page-transition.tsx
"use client";

import { usePathname } from "next/navigation";
import { AnimatePresence, motion } from "motion/react";

type TransitionVariant = "curtain" | "fade" | "clip";

const variants = {
  curtain: {
    initial: { scaleX: 1 },
    animate: { scaleX: 0 },
    exit: { scaleX: 1 },
  },
  fade: {
    initial: { opacity: 1 },
    animate: { opacity: 0 },
    exit: { opacity: 1 },
  },
  clip: {
    initial: { clipPath: "circle(150% at 50% 50%)" },
    animate: { clipPath: "circle(0% at 50% 50%)" },
    exit: { clipPath: "circle(150% at 50% 50%)" },
  },
};

export function PageTransition({
  children,
  variant = "curtain",
}: {
  children: React.ReactNode;
  variant?: TransitionVariant;
}) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.div key={pathname}>
        {children}

        {/* Overlay that animates on route change */}
        <motion.div
          className="fixed inset-0 z-50 origin-left bg-black"
          initial={variants[variant].initial}
          animate={variants[variant].animate}
          exit={variants[variant].exit}
          transition={{
            duration: 0.6,
            ease: [0.76, 0, 0.24, 1],
          }}
          style={{ pointerEvents: "none" }}
        />
      </motion.div>
    </AnimatePresence>
  );
}
```

Usage in layout:

> **Critical:** In Next.js App Router, `AnimatePresence` exit animations do NOT work when placed in `layout.tsx` because the layout tree hard-unmounts on route change. Use `template.tsx` instead of `layout.tsx` for route transition wrappers, or use the View Transitions API approach from Section 2.

```tsx
// src/app/layout.tsx (Server Component — no "use client")
import { PageTransition } from "@/components/page-transition";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <PageTransition variant="curtain">{children}</PageTransition>
      </body>
    </html>
  );
}
```

### 4. Staggered Reveal Sequences

Orchestrate multiple elements appearing in a timed sequence on mount.

```tsx
// src/components/reveal-sequence.tsx
"use client";

import { motion } from "motion/react";
import type { Variants } from "motion/react";

const containerVariants: Variants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.12,
      delayChildren: 0.1,
    },
  },
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 30, filter: "blur(10px)" },
  visible: {
    opacity: 1,
    y: 0,
    filter: "blur(0px)",
    transition: {
      duration: 0.6,
      ease: [0.22, 1, 0.36, 1],
    },
  },
};

export function RevealSequence({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className={className}
    >
      {children}
    </motion.div>
  );
}

export function RevealItem({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <motion.div variants={itemVariants} className={className}>
      {children}
    </motion.div>
  );
}
```

Hero reveal example:

```tsx
// src/components/hero.tsx
"use client";

import { RevealSequence, RevealItem } from "@/components/reveal-sequence";

export function Hero() {
  return (
    <RevealSequence className="flex min-h-screen flex-col items-center justify-center">
      {/* Background reveals first */}
      <RevealItem>
        <div className="absolute inset-0 bg-gradient-to-b from-black to-neutral-950" />
      </RevealItem>

      {/* Heading */}
      <RevealItem>
        <h1 className="relative text-6xl font-bold tracking-tight text-white md:text-8xl">
          Your Brand
        </h1>
      </RevealItem>

      {/* Subheading */}
      <RevealItem>
        <p className="relative mt-4 max-w-md text-center text-lg text-white/60">
          A description that fades in after the heading
        </p>
      </RevealItem>

      {/* CTA button */}
      <RevealItem>
        <button className="relative mt-8 rounded-full bg-white px-8 py-3 text-sm font-medium text-black transition-colors hover:bg-white/90">
          Get Started
        </button>
      </RevealItem>
    </RevealSequence>
  );
}
```

### 5. Image Load Reveal

Placeholder shown until `<img onLoad>` fires. Supports blur-up, clip-path, and scale reveal.

```tsx
// src/components/reveal-image.tsx
"use client";

import { useState } from "react";
import { motion } from "motion/react";
import Image, { type ImageProps } from "next/image";
import { cn } from "@/lib/utils";

type RevealType = "blur" | "clip" | "scale";

export function RevealImage({
  revealType = "blur",
  className,
  ...props
}: ImageProps & { revealType?: RevealType }) {
  const [loaded, setLoaded] = useState(false);

  const revealVariants = {
    blur: {
      hidden: { filter: "blur(20px)", opacity: 0.6 },
      visible: { filter: "blur(0px)", opacity: 1 },
    },
    clip: {
      hidden: { clipPath: "circle(0% at 50% 50%)" },
      visible: { clipPath: "circle(75% at 50% 50%)" },
    },
    scale: {
      hidden: { scale: 1.2, opacity: 0 },
      visible: { scale: 1, opacity: 1 },
    },
  };

  return (
    <div className={cn("relative overflow-hidden", className)}>
      {/* Placeholder background */}
      <div
        className="absolute inset-0 bg-neutral-200 dark:bg-neutral-800"
        aria-hidden
      />

      <motion.div
        initial="hidden"
        animate={loaded ? "visible" : "hidden"}
        variants={revealVariants[revealType]}
        transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
      >
        <Image
          {...props}
          onLoad={() => setLoaded(true)}
          className="relative"
        />
      </motion.div>
    </div>
  );
}
```

### 6. Font Load Detection

Hook using `document.fonts.ready` with a timeout fallback. Prevents FOUT by hiding text until fonts are ready.

```tsx
// src/hooks/use-fonts-ready.ts
"use client";

import { useState, useEffect } from "react";

export function useFontsReady(timeoutMs = 3000) {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;

    // Timeout fallback: show content with system font after 3s
    const timeout = setTimeout(() => {
      if (!cancelled) setReady(true);
    }, timeoutMs);

    document.fonts.ready.then(() => {
      if (!cancelled) {
        setReady(true);
        clearTimeout(timeout);
      }
    });

    return () => {
      cancelled = true;
      clearTimeout(timeout);
    };
  }, [timeoutMs]);

  return ready;
}
```

Usage preventing FOUT:

```tsx
// src/components/font-ready-text.tsx
"use client";

import { motion } from "motion/react";
import { useFontsReady } from "@/hooks/use-fonts-ready";

export function FontReadyText({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  const fontsReady = useFontsReady();

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: fontsReady ? 1 : 0 }}
      transition={{ duration: 0.4, ease: "easeOut" }}
      className={className}
    >
      {children}
    </motion.div>
  );
}
```

### 7. Exit Animations

Coordinated exit-enter patterns with AnimatePresence and shared layout animations.

```tsx
// src/components/animated-outlet.tsx
"use client";

import { usePathname } from "next/navigation";
import { AnimatePresence, motion } from "motion/react";

export function AnimatedOutlet({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.main
        key={pathname}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -20 }}
        transition={{
          duration: 0.3,
          ease: [0.22, 1, 0.36, 1],
        }}
      >
        {children}
      </motion.main>
    </AnimatePresence>
  );
}
```

Shared layout animation across routes using `layoutId`:

```tsx
// src/components/shared-card.tsx
"use client";

import { motion } from "motion/react";
import Link from "next/link";

export function SharedCard({
  id,
  title,
  image,
}: {
  id: string;
  title: string;
  image: string;
}) {
  return (
    <Link href={`/work/${id}`}>
      <motion.div layoutId={`card-${id}`} className="overflow-hidden rounded-2xl">
        <motion.img
          layoutId={`image-${id}`}
          src={image}
          alt={title}
          className="aspect-video w-full object-cover"
        />
        <motion.h3 layoutId={`title-${id}`} className="mt-3 text-lg font-medium">
          {title}
        </motion.h3>
      </motion.div>
    </Link>
  );
}
```

### 8. Progressive Enhancement

All transitions degrade gracefully. Content is server-rendered and visible without JS. Respect `prefers-reduced-motion`.

```css
/* src/app/globals.css */
@media (prefers-reduced-motion: reduce) {
  ::view-transition-old(root),
  ::view-transition-new(root) {
    animation: none !important;
  }

  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Motion helper for reduced motion:

```tsx
// src/lib/motion-config.tsx
"use client";

import { LazyMotion, domAnimation, MotionConfig } from "motion/react";

export function MotionProvider({ children }: { children: React.ReactNode }) {
  return (
    <LazyMotion features={domAnimation}>
      <MotionConfig reducedMotion="user">{children}</MotionConfig>
    </LazyMotion>
  );
}
```

Server-rendered content stays visible without JS:

```tsx
// Content is rendered by the server and visible immediately.
// Client-side motion components enhance with transitions after hydration.
// The key pattern: never hide content behind JS-only gates.
export default async function Page() {
  const data = await getData();
  return (
    <main>
      {/* This content is visible even with JS disabled */}
      <h1>{data.title}</h1>
      <p>{data.description}</p>
    </main>
  );
}
```

## Anti-pattern

```tsx
// WRONG: Preloader blocks content for too long (no max time, no skip)
function BadPreloader() {
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    // Waits indefinitely for ALL images, could take 10+ seconds
    Promise.all(
      Array.from(document.images).map(
        (img) => new Promise((r) => (img.onload = r))
      )
    ).then(() => setLoading(false));
  }, []);
  if (loading) return <div>Loading...</div>;
  return <main>Content</main>;
}

// WRONG: View Transitions API without feature detection
function navigate(href: string) {
  // Crashes in Firefox/Safari where API is not supported
  document.startViewTransition(() => {
    router.push(href);
  });
}

// WRONG: AnimatePresence without key prop — exit animation never fires
function BadTransition({ children }: { children: React.ReactNode }) {
  return (
    <AnimatePresence mode="wait">
      {/* Missing key={pathname} means AnimatePresence cannot track exits */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}

// WRONG: Image reveal without placeholder — causes CLS
function BadImageReveal({ src }: { src: string }) {
  const [loaded, setLoaded] = useState(false);
  return (
    // No width/height, no placeholder, content shifts when image loads
    <img
      src={src}
      onLoad={() => setLoaded(true)}
      style={{ opacity: loaded ? 1 : 0 }}
    />
  );
}

// WRONG: Font detection without timeout — text hidden forever if font fails
function BadFontWait({ children }: { children: React.ReactNode }) {
  const [ready, setReady] = useState(false);
  useEffect(() => {
    document.fonts.ready.then(() => setReady(true));
    // No timeout fallback! If font CDN is down, text stays invisible
  }, []);
  return <div style={{ visibility: ready ? "visible" : "hidden" }}>{children}</div>;
}
```

## Common Mistakes

1. **Preloader runs every page visit** -- Use `sessionStorage.getItem("has-visited")` to skip the preloader on subsequent navigations within the same session.

2. **View Transitions API without feature detection** -- Always check `"startViewTransition" in document` before calling it. Firefox and older Safari versions do not support it.

3. **Route transitions that block navigation** -- Keep total transition duration under 600ms. Users should never feel stuck waiting for an animation to complete before seeing content.

4. **Stagger sequences that take too long** -- With `staggerChildren: 0.12` and 5 items, total reveal is ~0.7s plus individual duration. Keep total under 1.5s or users lose attention.

5. **Image reveal without defined dimensions** -- Always provide `width` and `height` (or `fill` with sized parent) to prevent Cumulative Layout Shift when the image loads.

6. **Font load detection without timeout** -- If the font CDN is unreachable, `document.fonts.ready` may never resolve for that font face. Always include a timeout (3s is standard) that shows content with the fallback font.

7. **Exit animations on unmounted components** -- AnimatePresence must wrap the conditional element directly. If the parent unmounts first, the exit animation is lost. Place AnimatePresence as high as possible in the tree.

8. **Ignoring prefers-reduced-motion** -- Always wrap Motion components with `<MotionConfig reducedMotion="user">` or add CSS media query overrides. Some users experience motion sickness.

## Checklist

- [ ] Preloader skipped on repeat visits (sessionStorage check)
- [ ] View Transitions API has feature detection and fallback
- [ ] Route transitions use `mode="wait"` with AnimatePresence
- [ ] AnimatePresence children have a unique `key` prop
- [ ] Staggered reveals complete within 1.5s total
- [ ] Image reveals have placeholder with correct dimensions
- [ ] Font detection has 3s timeout fallback
- [ ] `prefers-reduced-motion` disables all transition animations
- [ ] Content accessible without JavaScript (progressive enhancement)
- [ ] Transition duration under 600ms for route changes
- [ ] No layout shift during image or font loading

## Advanced Patterns

### Morphing shape page transition

SVG shape morphs from one form to another as an overlay between routes — a signature cinematic effect.

```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";
import { usePathname } from "next/navigation";

export function MorphTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.div key={pathname}>
        {/* Entry overlay */}
        <motion.div
          className="fixed inset-0 z-50 bg-primary"
          initial={{ clipPath: "circle(0% at 50% 50%)" }}
          animate={{ clipPath: "circle(150% at 50% 50%)" }}
          exit={{ clipPath: "circle(0% at 50% 50%)" }}
          transition={{ duration: 0.8, ease: [0.76, 0, 0.24, 1] }}
        />
        {/* Page content */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1, transition: { delay: 0.3 } }}
          exit={{ opacity: 0 }}
        >
          {children}
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
```

### Curtain reveal transition

Two panels slide apart like curtains to reveal the next page.

```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";
import { usePathname } from "next/navigation";

export function CurtainTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.div key={pathname}>
        {/* Left curtain */}
        <motion.div
          className="fixed inset-y-0 left-0 z-50 w-1/2 bg-foreground"
          initial={{ x: 0 }}
          animate={{ x: "-100%", transition: { delay: 0.2, duration: 0.6, ease: [0.76, 0, 0.24, 1] } }}
          exit={{ x: 0, transition: { duration: 0.4, ease: [0.76, 0, 0.24, 1] } }}
        />
        {/* Right curtain */}
        <motion.div
          className="fixed inset-y-0 right-0 z-50 w-1/2 bg-foreground"
          initial={{ x: 0 }}
          animate={{ x: "100%", transition: { delay: 0.2, duration: 0.6, ease: [0.76, 0, 0.24, 1] } }}
          exit={{ x: 0, transition: { duration: 0.4, ease: [0.76, 0, 0.24, 1] } }}
        />
        {/* Content */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0, transition: { delay: 0.5, duration: 0.4 } }}
          exit={{ opacity: 0, transition: { duration: 0.2 } }}
        >
          {children}
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
```

### Stagger text reveal on route entry

Page title characters animate in with stagger on each route change.

```tsx
"use client";

import { motion } from "motion/react";

export function StaggerTitle({ text }: { text: string }) {
  return (
    <h1 className="text-5xl font-bold" aria-label={text}>
      {text.split("").map((char, i) => (
        <motion.span
          key={`${char}-${i}`}
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{
            delay: 0.3 + i * 0.03,
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
    </h1>
  );
}
```

### Branded loading bar with eased progress

A thin top bar with custom easing that feels faster than linear — the signature SaaS loading indicator.

```tsx
"use client";

import { motion, useNProgress } from "motion/react";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

export function TopLoadingBar() {
  const pathname = usePathname();
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    setLoading(true);
    setProgress(0);

    // Simulate fast start, slow middle, snap to complete
    const t1 = setTimeout(() => setProgress(30), 50);
    const t2 = setTimeout(() => setProgress(60), 200);
    const t3 = setTimeout(() => setProgress(80), 500);
    const t4 = setTimeout(() => {
      setProgress(100);
      setTimeout(() => setLoading(false), 200);
    }, 800);

    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); clearTimeout(t4); };
  }, [pathname]);

  if (!loading) return null;

  return (
    <motion.div
      className="fixed top-0 left-0 z-[100] h-0.5 bg-primary"
      initial={{ width: "0%" }}
      animate={{ width: `${progress}%` }}
      transition={{ ease: [0.65, 0, 0.35, 1] }}
    />
  );
}
```

## Composes With

- `animation` -- Motion library patterns, spring physics, variants
- `nextjs-routing` -- Route-aware transitions using pathname
- `performance` -- Preloader that tracks real loading progress
- `creative-scrolling` -- Coordinating scroll triggers with page transitions
- `react-suspense` -- Suspense boundaries for data loading states
- `sound-design` -- audio cues on transition start/complete
- `advanced-typography` -- stagger text reveals on route entry
