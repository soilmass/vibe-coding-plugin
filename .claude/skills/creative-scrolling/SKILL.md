---
name: creative-scrolling
description: >
  Lenis smooth scroll, GSAP ScrollTrigger, horizontal scroll sections, scroll snap, velocity-based effects, scroll progress indicators, scroll-linked animations
allowed-tools: Read, Grep, Glob
---

# Creative Scrolling

## Purpose
Scroll experience patterns for Next.js 15 + React 19. Covers Lenis smooth scroll, GSAP ScrollTrigger,
horizontal scroll sections, scroll snap, velocity-based effects, scroll progress indicators, and
scroll-linked SVG path animations. The ONE skill for premium scroll experiences.

## When to Use
- Adding smooth scroll with Lenis
- Building horizontal scroll sections
- Creating scroll-triggered animations with GSAP ScrollTrigger
- Implementing scroll snap sections
- Adding velocity-based effects (parallax, scale on speed)
- Building scroll progress indicators
- Creating scroll-linked SVG path animations
- Building Awwwards-level scroll narratives

## When NOT to Use
- Basic scroll reveal (fade in on scroll) → `animation`
- Page transitions between routes → `loading-transitions`
- Infinite scroll / virtual lists → `virtualization`
- Sticky headers → `layout-patterns`
- Simple CSS animations → `tailwind-v4`

## Pattern

### 1. Lenis smooth scroll setup

Install dependencies:
```bash
npm install lenis
```

Create a provider that wraps the app with smooth scrolling:
```tsx
"use client";

import { useEffect, useRef } from "react";
import Lenis from "lenis";

type SmoothScrollProps = {
  children: React.ReactNode;
  enabled?: boolean;
};

export function SmoothScroll({ children, enabled = true }: SmoothScrollProps) {
  const lenisRef = useRef<Lenis | null>(null);

  useEffect(() => {
    // Respect reduced motion preference
    const prefersReducedMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;

    if (!enabled || prefersReducedMotion) return;

    const lenis = new Lenis({
      duration: 1.2,
      easing: (t: number) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      orientation: "vertical",
      gestureOrientation: "vertical",
      smoothWheel: true,
      touchMultiplier: 2,
    });

    lenisRef.current = lenis;

    function raf(time: number) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }

    const frameId = requestAnimationFrame(raf);

    return () => {
      cancelAnimationFrame(frameId);
      lenis.destroy();
      lenisRef.current = null;
    };
  }, [enabled]);

  return <>{children}</>;
}
```

Integration with GSAP ScrollTrigger (bridge Lenis and GSAP):
```tsx
"use client";

import { useEffect, useRef } from "react";
import Lenis from "lenis";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

export function SmoothScrollWithGSAP({ children }: { children: React.ReactNode }) {
  const lenisRef = useRef<Lenis | null>(null);

  useEffect(() => {
    const prefersReducedMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;

    if (prefersReducedMotion) return;

    const lenis = new Lenis({
      duration: 1.2,
      easing: (t: number) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true,
    });

    lenisRef.current = lenis;

    // Bridge Lenis scroll events to GSAP ScrollTrigger
    lenis.on("scroll", () => ScrollTrigger.update());

    gsap.ticker.lagSmoothing(0);
    const rafCallback = (time: number) => lenis.raf(time * 1000);
    gsap.ticker.add(rafCallback);

    return () => {
      lenis.destroy();
      gsap.ticker.remove(rafCallback);
      ScrollTrigger.getAll().forEach((trigger) => trigger.kill());
      lenisRef.current = null;
    };
  }, []);

  return <>{children}</>;
}
```

### 2. Horizontal scroll section

A pinned container that translates panels horizontally as the user scrolls vertically:
```tsx
"use client";

import { useRef, useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { useGSAP } from "@gsap/react";

gsap.registerPlugin(ScrollTrigger);

type HorizontalScrollProps = {
  children: React.ReactNode;
  panelCount: number;
};

export function HorizontalScroll({ children, panelCount }: HorizontalScrollProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const trackRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      if (!containerRef.current || !trackRef.current) return;

      const panels = trackRef.current.children;
      const totalWidth = (panelCount - 1) * 100;

      gsap.to(trackRef.current, {
        xPercent: -(panelCount - 1) * 100,
        ease: "none",
        scrollTrigger: {
          trigger: containerRef.current,
          pin: true,
          scrub: 1,
          snap: 1 / (panelCount - 1),
          end: () => `+=${containerRef.current!.offsetWidth * (panelCount - 1)}`,
          invalidateOnRefresh: true,
        },
      });
    },
    { scope: containerRef, dependencies: [panelCount] }
  );

  return (
    <section ref={containerRef} className="relative overflow-hidden">
      <div
        ref={trackRef}
        className="flex h-screen"
        style={{ width: `${panelCount * 100}vw` }}
        role="region"
        aria-label="Horizontal scroll section"
      >
        {children}
      </div>
      {/* Keyboard navigation alternative */}
      <nav
        className="absolute bottom-8 left-1/2 z-10 flex -translate-x-1/2 gap-2"
        aria-label="Section navigation"
      >
        {Array.from({ length: panelCount }).map((_, i) => (
          <button
            key={i}
            className="h-3 w-3 rounded-full bg-white/50 transition-colors hover:bg-white"
            onClick={() => {
              const target = (trackRef.current?.children[i] as HTMLElement) ?? null;
              target?.scrollIntoView({ behavior: "smooth", inline: "start" });
            }}
            aria-label={`Go to section ${i + 1}`}
          />
        ))}
      </nav>
    </section>
  );
}

// Usage:
// <HorizontalScroll panelCount={4}>
//   <div className="flex h-screen w-screen items-center justify-center bg-slate-900">
//     <h2 className="text-6xl font-bold text-white">Panel 1</h2>
//   </div>
//   <div className="flex h-screen w-screen items-center justify-center bg-indigo-900">
//     <h2 className="text-6xl font-bold text-white">Panel 2</h2>
//   </div>
//   ...
// </HorizontalScroll>
```

### 3. GSAP ScrollTrigger integration

Use `@gsap/react` with the `useGSAP` hook for proper React cleanup:
```bash
npm install gsap @gsap/react
```

> **GSAP is now 100% free** (including ScrollTrigger, SplitText, MorphSVG, and all bonus plugins) thanks to Webflow. Use GSAP v3.13+. No trial packages or memberships needed.

Scrub-based parallax reveal:
```tsx
"use client";

import { useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { useGSAP } from "@gsap/react";

gsap.registerPlugin(ScrollTrigger);

type ScrollTriggeredRevealProps = {
  children: React.ReactNode;
  className?: string;
};

export function ScrollTriggeredReveal({
  children,
  className,
}: ScrollTriggeredRevealProps) {
  const containerRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      const prefersReducedMotion = window.matchMedia(
        "(prefers-reduced-motion: reduce)"
      ).matches;

      if (prefersReducedMotion) return;

      gsap.from(containerRef.current, {
        y: 100,
        opacity: 0,
        scrollTrigger: {
          trigger: containerRef.current,
          start: "top 85%",
          end: "top 25%",
          scrub: 1,
          toggleActions: "play none none reverse",
        },
      });
    },
    { scope: containerRef }
  );

  return (
    <div ref={containerRef} className={className}>
      {children}
    </div>
  );
}
```

Pinned timeline with multiple tweens:
```tsx
"use client";

import { useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { useGSAP } from "@gsap/react";

gsap.registerPlugin(ScrollTrigger);

export function PinnedTimeline() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const headingRef = useRef<HTMLHeadingElement>(null);
  const bodyRef = useRef<HTMLParagraphElement>(null);
  const imageRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: sectionRef.current,
          start: "top top",
          end: "+=200%",
          pin: true,
          scrub: 1,
          anticipatePin: 1,
        },
      });

      tl.from(headingRef.current, {
        y: 60,
        opacity: 0,
        duration: 0.5,
      })
        .from(
          bodyRef.current,
          {
            y: 40,
            opacity: 0,
            duration: 0.5,
          },
          "-=0.2"
        )
        .from(
          imageRef.current,
          {
            scale: 0.8,
            opacity: 0,
            duration: 0.8,
          },
          "-=0.3"
        )
        .to(
          sectionRef.current,
          {
            backgroundColor: "#0f172a",
            duration: 0.5,
          },
          "+=0.2"
        );
    },
    { scope: sectionRef }
  );

  return (
    <section
      ref={sectionRef}
      className="flex h-screen items-center justify-center bg-white transition-colors"
    >
      <div className="max-w-3xl text-center">
        <h2
          ref={headingRef}
          className="text-5xl font-bold will-change-transform"
        >
          Scroll-Driven Story
        </h2>
        <p
          ref={bodyRef}
          className="mt-6 text-xl text-muted-foreground will-change-transform"
        >
          Each element reveals as you scroll through this pinned section.
        </p>
        <div
          ref={imageRef}
          className="mx-auto mt-10 h-64 w-full rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 will-change-transform"
        />
      </div>
    </section>
  );
}
```

### 4. Scroll snap sections

Pure CSS scroll snap — no JavaScript needed, so this can be a Server Component:
```tsx
type SnapSectionsProps = {
  children: React.ReactNode;
};

export function SnapSections({ children }: SnapSectionsProps) {
  return (
    <div
      className="h-screen snap-y snap-mandatory overflow-y-auto overscroll-y-contain"
      role="region"
      aria-label="Snap scroll sections"
    >
      {children}
    </div>
  );
}

type SnapPanelProps = {
  children: React.ReactNode;
  className?: string;
};

export function SnapPanel({ children, className }: SnapPanelProps) {
  return (
    <section
      className={cn(
        "flex h-screen snap-start snap-always items-center justify-center",
        className
      )}
    >
      {children}
    </section>
  );
}

// Usage (Server Component — no "use client" needed):
// import { cn } from "@/lib/utils";
//
// <SnapSections>
//   <SnapPanel className="bg-slate-950 text-white">
//     <h1 className="text-7xl font-bold">Section 1</h1>
//   </SnapPanel>
//   <SnapPanel className="bg-indigo-950 text-white">
//     <h1 className="text-7xl font-bold">Section 2</h1>
//   </SnapPanel>
//   <SnapPanel className="bg-purple-950 text-white">
//     <h1 className="text-7xl font-bold">Section 3</h1>
//   </SnapPanel>
// </SnapSections>
```

### 5. Velocity-based effects

Track scroll velocity to create dynamic skew and scale effects:
```tsx
"use client";

import { useRef } from "react";
import { motion, useScroll, useVelocity, useTransform, useSpring } from "motion/react";

type VelocityTextProps = {
  children: React.ReactNode;
  className?: string;
};

export function VelocityText({ children, className }: VelocityTextProps) {
  const ref = useRef<HTMLDivElement>(null);

  const { scrollY } = useScroll();
  const scrollVelocity = useVelocity(scrollY);

  // Clamp velocity to a reasonable range for skew
  const skewX = useTransform(scrollVelocity, [-3000, 0, 3000], [-8, 0, 8]);
  const smoothSkew = useSpring(skewX, { stiffness: 200, damping: 30 });

  // Scale text slightly based on velocity
  const scale = useTransform(
    scrollVelocity,
    [-3000, 0, 3000],
    [0.95, 1, 0.95]
  );
  const smoothScale = useSpring(scale, { stiffness: 200, damping: 30 });

  return (
    <motion.div
      ref={ref}
      style={{
        skewX: smoothSkew,
        scale: smoothScale,
        willChange: "transform",
      }}
      className={className}
    >
      {children}
    </motion.div>
  );
}
```

Velocity-based image distortion:
```tsx
"use client";

import { useRef } from "react";
import {
  motion,
  useScroll,
  useVelocity,
  useTransform,
  useSpring,
} from "motion/react";

type VelocityImageProps = {
  src: string;
  alt: string;
  className?: string;
};

export function VelocityImage({ src, alt, className }: VelocityImageProps) {
  const ref = useRef<HTMLDivElement>(null);

  const { scrollY } = useScroll();
  const velocity = useVelocity(scrollY);

  // Vertical stretch based on scroll speed
  const scaleY = useTransform(velocity, [-2000, 0, 2000], [1.1, 1, 1.1]);
  const smoothScaleY = useSpring(scaleY, { stiffness: 300, damping: 40 });

  // Slight blur on fast scroll
  const blur = useTransform(velocity, [-2000, 0, 2000], [2, 0, 2]);
  const smoothBlur = useSpring(blur, { stiffness: 300, damping: 40 });

  return (
    <motion.div
      ref={ref}
      className={cn("overflow-hidden", className)}
      style={{
        scaleY: smoothScaleY,
        willChange: "transform",
      }}
    >
      <motion.img
        src={src}
        alt={alt}
        className="h-full w-full object-cover"
        style={{
          filter: useTransform(smoothBlur, (v) => `blur(${v}px)`),
        }}
      />
    </motion.div>
  );
}
```

### 6. Scroll progress indicator

Top bar progress indicator:
```tsx
"use client";

import { motion, useScroll, useSpring } from "motion/react";

export function ScrollProgressBar() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, {
    stiffness: 100,
    damping: 30,
    restDelta: 0.001,
  });

  return (
    <motion.div
      className="fixed left-0 right-0 top-0 z-50 h-1 origin-left bg-primary"
      style={{ scaleX }}
      role="progressbar"
      aria-label="Page scroll progress"
    />
  );
}
```

Circular progress indicator:
```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";

type CircularProgressProps = {
  size?: number;
  strokeWidth?: number;
  className?: string;
};

export function CircularProgress({
  size = 48,
  strokeWidth = 3,
  className,
}: CircularProgressProps) {
  const { scrollYProgress } = useScroll();

  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;

  const strokeDashoffset = useTransform(
    scrollYProgress,
    [0, 1],
    [circumference, 0]
  );

  return (
    <div
      className={cn("fixed bottom-8 right-8 z-50", className)}
      role="progressbar"
      aria-label="Page scroll progress"
    >
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        {/* Background circle */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="currentColor"
          strokeWidth={strokeWidth}
          className="text-muted-foreground/20"
        />
        {/* Progress circle */}
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="currentColor"
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          className="text-primary"
          style={{
            strokeDasharray: circumference,
            strokeDashoffset,
            rotate: "-90deg",
            transformOrigin: "center",
          }}
        />
      </svg>
    </div>
  );
}
```

### 7. Scroll-linked SVG path

Draw an SVG path as the user scrolls through a section:
```tsx
"use client";

import { useRef } from "react";
import { motion, useScroll, useTransform } from "motion/react";

type ScrollLinkedPathProps = {
  path: string;
  viewBox: string;
  className?: string;
  strokeColor?: string;
  strokeWidth?: number;
};

export function ScrollLinkedPath({
  path,
  viewBox,
  className,
  strokeColor = "currentColor",
  strokeWidth = 2,
}: ScrollLinkedPathProps) {
  const containerRef = useRef<HTMLDivElement>(null);

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"],
  });

  const pathLength = useTransform(scrollYProgress, [0.1, 0.9], [0, 1]);

  return (
    <div ref={containerRef} className={cn("relative", className)}>
      <svg
        viewBox={viewBox}
        fill="none"
        className="h-full w-full"
        aria-hidden="true"
      >
        {/* Ghost path (background) */}
        <path
          d={path}
          stroke={strokeColor}
          strokeWidth={strokeWidth}
          strokeOpacity={0.15}
        />
        {/* Animated path */}
        <motion.path
          d={path}
          stroke={strokeColor}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          style={{
            pathLength,
            willChange: "stroke-dashoffset",
          }}
        />
      </svg>
    </div>
  );
}

// Usage:
// <ScrollLinkedPath
//   path="M 10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80"
//   viewBox="0 0 200 160"
//   className="h-[600px]"
//   strokeColor="hsl(var(--primary))"
//   strokeWidth={3}
// />
```

### 8. Parallax layers

Multiple layers moving at different speeds for depth:
```tsx
"use client";

import { useRef } from "react";
import { motion, useScroll, useTransform } from "motion/react";

type ParallaxLayerProps = {
  children: React.ReactNode;
  speed: number;
  className?: string;
};

function ParallaxLayer({ children, speed, className }: ParallaxLayerProps) {
  const ref = useRef<HTMLDivElement>(null);

  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });

  const y = useTransform(scrollYProgress, [0, 1], [speed * -100, speed * 100]);

  return (
    <motion.div
      ref={ref}
      style={{ y, willChange: "transform" }}
      className={cn("absolute inset-0", className)}
    >
      {children}
    </motion.div>
  );
}

export function ParallaxHero() {
  return (
    <section className="relative h-[150vh] overflow-hidden">
      {/* Background — slowest */}
      <ParallaxLayer speed={0.2} className="z-0">
        <div className="h-full w-full bg-gradient-to-b from-indigo-950 via-slate-900 to-black" />
      </ParallaxLayer>

      {/* Midground — medium speed */}
      <ParallaxLayer speed={0.5} className="z-10">
        <div className="flex h-full items-center justify-center">
          <div className="h-96 w-96 rounded-full bg-purple-500/20 blur-3xl" />
        </div>
      </ParallaxLayer>

      {/* Foreground — fastest */}
      <ParallaxLayer speed={0.8} className="z-20">
        <div className="flex h-full items-center justify-center">
          <h1 className="text-8xl font-bold tracking-tight text-white">
            Parallax
          </h1>
        </div>
      </ParallaxLayer>

      {/* Static overlay (no parallax) */}
      <div className="pointer-events-none absolute inset-0 z-30 bg-gradient-to-t from-black/60 to-transparent" />
    </section>
  );
}
```

## Anti-pattern

### WRONG: Smooth scroll without reduced motion check
```tsx
"use client";
// BAD: No prefers-reduced-motion check
export function SmoothScroll({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const lenis = new Lenis(); // Forces smooth scroll on everyone
    // ...
  }, []);
  return <>{children}</>;
}
```

### WRONG: ScrollTrigger without cleanup (memory leak)
```tsx
"use client";
// BAD: No cleanup — ScrollTrigger instances persist across renders
export function BadTrigger() {
  useEffect(() => {
    gsap.to(".box", {
      scrollTrigger: {
        trigger: ".box",
        scrub: true,
      },
      x: 200,
    });
    // Missing: return () => { ScrollTrigger.getAll().forEach(t => t.kill()); }
  }, []);
  return <div className="box" />;
}
// FIX: Use useGSAP from @gsap/react which handles cleanup automatically,
// or wrap in gsap.context() and revert on unmount.
```

### WRONG: Horizontal scroll without keyboard/a11y alternative
```tsx
"use client";
// BAD: No way to navigate without mouse/trackpad scroll
export function InaccessibleHorizontalScroll({ children }: { children: React.ReactNode }) {
  // Only scrollTrigger-based, no buttons, no keyboard nav
  return (
    <div className="flex overflow-hidden">
      {children}
    </div>
  );
}
// FIX: Add navigation buttons with aria-labels, or keyboard event handlers.
```

### WRONG: scroll-snap on body (breaks mobile browsers)
```tsx
// BAD: Applying snap directly to body or html
// This causes erratic behavior on iOS Safari and some Android browsers
<body className="snap-y snap-mandatory overflow-y-auto">
  <section className="snap-start h-screen" />
</body>

// FIX: Use a wrapper div inside body instead
<body>
  <div className="h-screen snap-y snap-mandatory overflow-y-auto">
    <section className="snap-start h-screen" />
  </div>
</body>
```

### WRONG: Heavy GSAP animations without GPU hints
```tsx
"use client";
// BAD: Animating layout-triggering properties without GPU acceleration
gsap.to(element, {
  width: "100%",    // Triggers layout
  height: "500px",  // Triggers layout
  left: "50px",     // Triggers layout
  top: "100px",     // Triggers layout
});

// FIX: Use transform and opacity only (GPU-composited)
gsap.to(element, {
  xPercent: 50,     // transform: translateX
  y: 100,           // transform: translateY
  scale: 1.2,       // transform: scale
  opacity: 0.8,     // opacity
});
```

## Common Mistakes

1. **Not cleaning up Lenis and ScrollTrigger instances on unmount** — causes memory leaks and
   ghost scroll listeners. Always use `useGSAP` or `gsap.context()` for GSAP, and call
   `lenis.destroy()` in the cleanup function.

2. **Using smooth scroll without `prefers-reduced-motion` check** — violates WCAG 2.1
   Success Criterion 2.3.3. Always check `window.matchMedia("(prefers-reduced-motion: reduce)")`
   before initializing Lenis or scroll-driven animations.

3. **Horizontal scroll sections with no keyboard navigation alternative** — screen readers
   and keyboard users cannot access horizontally scrolled content. Add navigation buttons
   with proper `aria-label` attributes.

4. **ScrollTrigger animations that don't reverse on scroll up** — use `toggleActions: "play none none reverse"` or `scrub` mode so animations respond to both scroll directions.

5. **Not using `gsap.context()` for React cleanup** — leads to stale references and
   animation conflicts on re-renders. The `useGSAP` hook from `@gsap/react` handles
   this automatically.

6. **Mixing Lenis with native scroll-snap** — Lenis overrides the browser's native scroll
   behavior, which conflicts with CSS `scroll-snap-type`. Use one or the other, not both.

7. **Forgetting `will-change: transform` on animated elements** — without GPU hints, complex
   scroll animations cause paint jank. Add `will-change-transform` (Tailwind class) or
   `style={{ willChange: "transform" }}` to animated elements. Remove it after animation
   completes to free GPU memory.

8. **Using `useEffect` instead of `useGSAP`** — `useEffect` does not integrate with GSAP's
   internal cleanup. Always prefer `useGSAP` from `@gsap/react` for scroll-triggered
   animations in React components.

9. **Scroll progress indicators without `position: fixed`** — the progress bar must stay
   visible during scroll. Use `fixed` positioning with an appropriate `z-index` (50+).

10. **Not testing on mobile** — iOS Safari handles scroll differently than Chrome. Always
    test smooth scroll, scroll snap, and horizontal scroll on real iOS and Android devices.

## Checklist

- [ ] Lenis initialized with `prefers-reduced-motion` check
- [ ] All ScrollTrigger instances cleaned up on unmount via `gsap.context()` or `useGSAP`
- [ ] Horizontal scroll sections have keyboard navigation alternative
- [ ] Scroll-linked animations use `transform`/`opacity` only (GPU-accelerated)
- [ ] Velocity effects clamped to reasonable range (prevent extreme values)
- [ ] Scroll progress uses `position: fixed` with correct z-index
- [ ] All scroll components marked `"use client"` (scroll APIs need browser)
- [ ] Mobile tested — no janky scroll on iOS Safari and Android Chrome
- [ ] `will-change: transform` applied to animated elements, removed when idle
- [ ] No mixing of Lenis smooth scroll and native CSS scroll-snap
- [ ] SVG path animations use `aria-hidden="true"` (decorative)
- [ ] Parallax layers have proper z-index stacking

## Advanced Patterns

### Image sequence on scroll (Apple-style)

Play a canvas image sequence frame-by-frame as the user scrolls — the signature Apple product page technique.

```tsx
"use client";

import { useRef, useEffect } from "react";
import { useScroll, useTransform, useMotionValueEvent } from "motion/react";

export function ScrollImageSequence({
  frameCount,
  getFrameUrl,
  width = 1920,
  height = 1080,
}: {
  frameCount: number;
  getFrameUrl: (index: number) => string;
  width?: number;
  height?: number;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const imagesRef = useRef<HTMLImageElement[]>([]);
  const currentFrameRef = useRef(0);

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  });

  // Preload all frames
  useEffect(() => {
    const images: HTMLImageElement[] = [];
    for (let i = 0; i < frameCount; i++) {
      const img = new Image();
      img.src = getFrameUrl(i);
      images.push(img);
    }
    imagesRef.current = images;

    // Draw first frame when loaded
    images[0].onload = () => {
      const ctx = canvasRef.current?.getContext("2d");
      if (ctx) ctx.drawImage(images[0], 0, 0, width, height);
    };
  }, [frameCount, getFrameUrl, width, height]);

  useMotionValueEvent(scrollYProgress, "change", (progress) => {
    const frameIndex = Math.min(
      frameCount - 1,
      Math.floor(progress * frameCount)
    );
    if (frameIndex === currentFrameRef.current) return;
    currentFrameRef.current = frameIndex;

    const ctx = canvasRef.current?.getContext("2d");
    const img = imagesRef.current[frameIndex];
    if (ctx && img?.complete) {
      ctx.drawImage(img, 0, 0, width, height);
    }
  });

  return (
    <div ref={containerRef} className="relative h-[500vh]">
      <div className="sticky top-0 flex h-screen items-center justify-center">
        <canvas
          ref={canvasRef}
          width={width}
          height={height}
          className="max-h-screen w-full object-contain"
          aria-hidden="true"
        />
      </div>
    </div>
  );
}

// Usage:
// <ScrollImageSequence
//   frameCount={120}
//   getFrameUrl={(i) => `/frames/product-${String(i).padStart(4, "0")}.webp`}
// />
```

### Scroll-driven clip-path reveal

Content is masked and gradually revealed via `clip-path` as the user scrolls — a cinematic reveal effect.

```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function ScrollClipReveal({
  children,
  shape = "circle",
}: {
  children: React.ReactNode;
  shape?: "circle" | "inset" | "polygon";
}) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "center center"],
  });

  const clipPath = useTransform(scrollYProgress, [0, 1], (() => {
    switch (shape) {
      case "circle":
        return ["circle(0% at 50% 50%)", "circle(75% at 50% 50%)"];
      case "inset":
        return ["inset(40% 40% 40% 40%)", "inset(0% 0% 0% 0%)"];
      case "polygon":
        return [
          "polygon(50% 50%, 50% 50%, 50% 50%, 50% 50%)",
          "polygon(0% 0%, 100% 0%, 100% 100%, 0% 100%)",
        ];
    }
  })());

  return (
    <div ref={ref} className="min-h-screen">
      <motion.div style={{ clipPath }} className="sticky top-0">
        {children}
      </motion.div>
    </div>
  );
}
```

### Scroll-pinned 3D camera movement

Combine GSAP ScrollTrigger with R3F to move a 3D camera based on scroll position.

```tsx
"use client";

import { Canvas, useThree, useFrame } from "@react-three/fiber";
import { useRef, useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import * as THREE from "three";

gsap.registerPlugin(ScrollTrigger);

function ScrollCamera({ containerRef }: { containerRef: React.RefObject<HTMLDivElement> }) {
  const { camera } = useThree();
  const progress = useRef({ value: 0 });

  useEffect(() => {
    const trigger = ScrollTrigger.create({
      trigger: containerRef.current,
      start: "top top",
      end: "bottom bottom",
      scrub: 1,
      onUpdate: (self) => {
        progress.current.value = self.progress;
      },
    });
    return () => trigger.kill();
  }, [containerRef]);

  useFrame(() => {
    const t = progress.current.value;
    // Camera path: spiral inward
    camera.position.x = Math.cos(t * Math.PI * 2) * (5 - t * 3);
    camera.position.z = Math.sin(t * Math.PI * 2) * (5 - t * 3);
    camera.position.y = 2 + t * 3;
    camera.lookAt(0, 0, 0);
  });

  return null;
}

export function ScrollScene() {
  const containerRef = useRef<HTMLDivElement>(null);

  return (
    <div ref={containerRef} className="relative h-[400vh]">
      <div className="sticky top-0 h-screen">
        <Canvas>
          <ambientLight intensity={0.5} />
          <directionalLight position={[5, 5, 5]} />
          <mesh>
            <boxGeometry args={[1, 1, 1]} />
            <meshStandardMaterial color="#6366f1" />
          </mesh>
          <ScrollCamera containerRef={containerRef} />
        </Canvas>
      </div>
    </div>
  );
}
```

## Composes With

- `animation` — scroll-triggered Motion animations, enter/exit transitions within scroll sections
- `performance` — GPU-accelerated transforms, `will-change` management, dynamic imports for GSAP
- `accessibility` — `prefers-reduced-motion` checks, keyboard alternatives for scroll sections
- `landing-patterns` — scroll experiences for marketing and portfolio pages
- `loading-transitions` — coordinating scroll position with page transitions
- `responsive-design` — adapting scroll effects for mobile viewports
- `visual-design` — visual polish for scroll-driven narratives
- `webgl-3d` — scroll-driven 3D camera and scene transitions
- `svg-canvas` — scroll-linked SVG path drawing and canvas image sequences
- `sound-design` — scroll-position-based audio pitch and triggers
