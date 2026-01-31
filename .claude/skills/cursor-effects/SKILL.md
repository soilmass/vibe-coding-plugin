---
name: cursor-effects
description: >
  Custom cursor with spring physics, magnetic elements, cursor trail, spotlight cursor, cursor size states, blend mode cursor, touch device detection
allowed-tools: Read, Grep, Glob
---

# Cursor Effects

## Purpose

Custom cursor and pointer interaction patterns for Next.js 15 + React 19. Covers custom cursor with spring physics, magnetic elements (cursor pull), cursor trail, spotlight cursor (radial mask), cursor size states (hover/click), blend mode cursor (mix-blend-difference), and touch device detection/disable. No extra packages needed — uses Motion (`motion/react`). The ONE skill for cursor magic.

## When to Use

- Replacing the default cursor with a custom design
- Adding magnetic pull effect to buttons/links
- Creating cursor trails or particle effects
- Building spotlight/reveal effects that follow cursor
- Changing cursor appearance on hover over different elements
- Adding mix-blend-mode cursor for light/dark contrast
- Awwwards-level portfolio or marketing sites that demand premium interactions

## When NOT to Use

- Basic hover states (scale, color changes) — use `animation`
- Magnetic buttons without a custom cursor — use `animation`
- Tooltip positioning that follows cursor — use `shadcn`
- Drag and drop interactions — use `drag-drop`
- Mobile-first applications where touch is the primary input

## Pattern

### 1. Touch device detection hook

Build this first — every other pattern depends on it to disable on touch devices.

```tsx
// src/hooks/use-is-touch-device.ts
"use client";
import { useState, useEffect } from "react";

export function useIsTouchDevice() {
  const [isTouch, setIsTouch] = useState(false);

  useEffect(() => {
    const query = window.matchMedia("(pointer: coarse)");
    setIsTouch(query.matches || "ontouchstart" in window);

    function onChange(e: MediaQueryListEvent) {
      setIsTouch(e.matches);
    }
    query.addEventListener("change", onChange);
    return () => query.removeEventListener("change", onChange);
  }, []);

  return isTouch;
}
```

### 2. Custom cursor with spring physics

A smooth-follow cursor with inner dot and outer ring. Uses `useSpring` for the buttery feel.

```tsx
// src/components/custom-cursor.tsx
"use client";
import { useEffect } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

export function CustomCursor() {
  const isTouch = useIsTouchDevice();
  const cursorX = useMotionValue(0);
  const cursorY = useMotionValue(0);

  const springConfig = { damping: 25, stiffness: 200, mass: 0.5 };
  const x = useSpring(cursorX, springConfig);
  const y = useSpring(cursorY, springConfig);

  useEffect(() => {
    if (isTouch) return;

    function onMove(e: MouseEvent) {
      cursorX.set(e.clientX);
      cursorY.set(e.clientY);
    }
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, [isTouch, cursorX, cursorY]);

  if (isTouch) return null;

  return (
    <>
      {/* Hide default cursor via global style */}
      <style>{`body { cursor: none !important; }`}</style>

      {/* Outer ring */}
      <motion.div
        className="pointer-events-none fixed top-0 left-0 z-50 h-10 w-10 rounded-full border-2 border-white/80"
        style={{ x, y, translateX: "-50%", translateY: "-50%" }}
      />

      {/* Inner dot */}
      <motion.div
        className="pointer-events-none fixed top-0 left-0 z-50 h-2 w-2 rounded-full bg-white"
        style={{
          x: cursorX,
          y: cursorY,
          translateX: "-50%",
          translateY: "-50%",
        }}
      />
    </>
  );
}
```

### 3. Cursor context provider

Expose cursor state to the entire app so any component can change the cursor variant.

```tsx
// src/components/cursor-provider.tsx
"use client";
import {
  createContext,
  useContext,
  useState,
  useEffect,
  type ReactNode,
} from "react";
import { motion, useMotionValue, useSpring, AnimatePresence } from "motion/react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

type CursorVariant = "default" | "hover" | "click" | "text" | "hidden";

type CursorContextValue = {
  setCursorVariant: (variant: CursorVariant) => void;
};

const CursorContext = createContext<CursorContextValue>({
  setCursorVariant: () => {},
});

export function useCursor() {
  return useContext(CursorContext);
}

const variantStyles: Record<CursorVariant, { size: number; opacity: number }> = {
  default: { size: 40, opacity: 1 },
  hover: { size: 64, opacity: 0.6 },
  click: { size: 24, opacity: 1 },
  text: { size: 4, opacity: 1 },
  hidden: { size: 0, opacity: 0 },
};

export function CursorProvider({ children }: { children: ReactNode }) {
  const isTouch = useIsTouchDevice();
  const [variant, setVariant] = useState<CursorVariant>("default");

  const cursorX = useMotionValue(0);
  const cursorY = useMotionValue(0);
  const spring = { damping: 25, stiffness: 200, mass: 0.5 };
  const x = useSpring(cursorX, spring);
  const y = useSpring(cursorY, spring);

  useEffect(() => {
    if (isTouch) return;
    function onMove(e: MouseEvent) {
      cursorX.set(e.clientX);
      cursorY.set(e.clientY);
    }
    function onDown() { setVariant("click"); }
    function onUp() { setVariant("default"); }

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mousedown", onDown);
    window.addEventListener("mouseup", onUp);
    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mousedown", onDown);
      window.removeEventListener("mouseup", onUp);
    };
  }, [isTouch, cursorX, cursorY]);

  const { size, opacity } = variantStyles[variant];

  return (
    <CursorContext.Provider value={{ setCursorVariant: setVariant }}>
      {children}
      {!isTouch && (
        <>
          <style>{`body { cursor: none !important; }`}</style>
          <motion.div
            className="pointer-events-none fixed top-0 left-0 z-50 rounded-full border-2 border-white/80"
            animate={{ width: size, height: size, opacity }}
            transition={{ type: "spring", damping: 20, stiffness: 300 }}
            style={{ x, y, translateX: "-50%", translateY: "-50%" }}
          />
        </>
      )}
    </CursorContext.Provider>
  );
}
```

Usage in any component:

```tsx
"use client";
import { useCursor } from "@/components/cursor-provider";

export function NavLink({ href, label }: { href: string; label: string }) {
  const { setCursorVariant } = useCursor();

  return (
    <a
      href={href}
      onMouseEnter={() => setCursorVariant("hover")}
      onMouseLeave={() => setCursorVariant("default")}
    >
      {label}
    </a>
  );
}
```

### 4. Magnetic cursor (element pull)

Wraps any element so it translates toward the cursor when within a threshold radius.

```tsx
// src/components/magnetic-element.tsx
"use client";
import { useRef } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";

type MagneticElementProps = {
  children: React.ReactNode;
  strength?: number; // 0-1, default 0.3
  threshold?: number; // px radius, default 100
  className?: string;
};

export function MagneticElement({
  children,
  strength = 0.3,
  threshold = 100,
  className,
}: MagneticElementProps) {
  const ref = useRef<HTMLDivElement>(null);
  const offsetX = useMotionValue(0);
  const offsetY = useMotionValue(0);
  const springConfig = { damping: 15, stiffness: 150, mass: 0.1 };
  const x = useSpring(offsetX, springConfig);
  const y = useSpring(offsetY, springConfig);

  function handleMouseMove(e: React.MouseEvent) {
    const el = ref.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    const distX = e.clientX - centerX;
    const distY = e.clientY - centerY;
    const distance = Math.sqrt(distX * distX + distY * distY);

    if (distance < threshold) {
      offsetX.set(distX * strength);
      offsetY.set(distY * strength);
    }
  }

  function handleMouseLeave() {
    offsetX.set(0);
    offsetY.set(0);
  }

  return (
    <motion.div
      ref={ref}
      className={className}
      style={{ x, y }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
    >
      {children}
    </motion.div>
  );
}
```

Usage:

```tsx
<MagneticElement strength={0.25} threshold={120}>
  <button className="rounded-full bg-white px-6 py-3 text-black">
    Get Started
  </button>
</MagneticElement>
```

### 5. Cursor trail

An array of trailing dots that follow the cursor with staggered delay.

```tsx
// src/components/cursor-trail.tsx
"use client";
import { useEffect, useRef } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

type CursorTrailProps = {
  dotCount?: number; // max 8 for performance
};

function TrailDot({ index, sourceX, sourceY }: {
  index: number;
  sourceX: ReturnType<typeof useMotionValue<number>>;
  sourceY: ReturnType<typeof useMotionValue<number>>;
}) {
  const springConfig = { damping: 20 - index * 1.5, stiffness: 150 - index * 10, mass: 0.1 };
  const x = useSpring(sourceX, springConfig);
  const y = useSpring(sourceY, springConfig);
  const size = Math.max(4, 12 - index * 1.5);
  const opacity = 1 - index * 0.12;

  return (
    <motion.div
      className="pointer-events-none fixed top-0 left-0 z-50 rounded-full bg-white"
      style={{
        x,
        y,
        width: size,
        height: size,
        opacity,
        translateX: "-50%",
        translateY: "-50%",
      }}
    />
  );
}

export function CursorTrail({ dotCount = 6 }: CursorTrailProps) {
  const isTouch = useIsTouchDevice();
  const cursorX = useMotionValue(0);
  const cursorY = useMotionValue(0);

  useEffect(() => {
    if (isTouch) return;
    function onMove(e: MouseEvent) {
      cursorX.set(e.clientX);
      cursorY.set(e.clientY);
    }
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, [isTouch, cursorX, cursorY]);

  if (isTouch) return null;

  const count = Math.min(dotCount, 8);
  return (
    <>
      {Array.from({ length: count }, (_, i) => (
        <TrailDot key={i} index={i} sourceX={cursorX} sourceY={cursorY} />
      ))}
    </>
  );
}
```

### 6. Spotlight cursor (radial mask)

A dark overlay with a radial gradient hole that follows the cursor, revealing content.

```tsx
// src/components/spotlight-section.tsx
"use client";
import { useRef, type ReactNode } from "react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

type SpotlightSectionProps = {
  children: ReactNode;
  radius?: number;
  className?: string;
};

export function SpotlightSection({
  children,
  radius = 200,
  className,
}: SpotlightSectionProps) {
  const isTouch = useIsTouchDevice();
  const containerRef = useRef<HTMLDivElement>(null);
  const overlayRef = useRef<HTMLDivElement>(null);

  function handleMouseMove(e: React.MouseEvent) {
    const el = containerRef.current;
    const overlay = overlayRef.current;
    if (!el || !overlay) return;
    const rect = el.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    overlay.style.setProperty("--spot-x", `${x}px`);
    overlay.style.setProperty("--spot-y", `${y}px`);
  }

  return (
    <div
      ref={containerRef}
      className={`relative overflow-hidden ${className ?? ""}`}
      onMouseMove={handleMouseMove}
    >
      {children}

      {!isTouch && (
        <div
          ref={overlayRef}
          className="pointer-events-none absolute inset-0 z-10 bg-black/80 transition-[mask-image] duration-0"
          style={{
            maskImage: `radial-gradient(circle ${radius}px at var(--spot-x, 50%) var(--spot-y, 50%), transparent 0%, black 100%)`,
            WebkitMaskImage: `radial-gradient(circle ${radius}px at var(--spot-x, 50%) var(--spot-y, 50%), transparent 0%, black 100%)`,
          }}
        />
      )}
    </div>
  );
}
```

### 7. Cursor size states via data attributes

Use event delegation to detect `data-cursor` attributes and resize the cursor without prop drilling.

```tsx
// src/components/data-cursor.tsx
"use client";
import { useEffect, useState } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

const sizeMap: Record<string, number> = {
  default: 40,
  large: 80,
  text: 4,
  small: 16,
  dot: 8,
};

export function DataCursor() {
  const isTouch = useIsTouchDevice();
  const [cursorType, setCursorType] = useState("default");
  const cursorX = useMotionValue(0);
  const cursorY = useMotionValue(0);
  const spring = { damping: 25, stiffness: 200, mass: 0.5 };
  const x = useSpring(cursorX, spring);
  const y = useSpring(cursorY, spring);

  useEffect(() => {
    if (isTouch) return;

    function onMove(e: MouseEvent) {
      cursorX.set(e.clientX);
      cursorY.set(e.clientY);
    }

    function onOver(e: MouseEvent) {
      const target = (e.target as HTMLElement).closest("[data-cursor]");
      if (target) {
        setCursorType(target.getAttribute("data-cursor") ?? "default");
      } else {
        setCursorType("default");
      }
    }

    window.addEventListener("mousemove", onMove);
    document.addEventListener("mouseover", onOver);
    return () => {
      window.removeEventListener("mousemove", onMove);
      document.removeEventListener("mouseover", onOver);
    };
  }, [isTouch, cursorX, cursorY]);

  if (isTouch) return null;

  const size = sizeMap[cursorType] ?? 40;

  return (
    <>
      <style>{`body { cursor: none !important; }`}</style>
      <motion.div
        className="pointer-events-none fixed top-0 left-0 z-50 rounded-full border-2 border-white"
        animate={{ width: size, height: size }}
        transition={{ type: "spring", damping: 20, stiffness: 300 }}
        style={{ x, y, translateX: "-50%", translateY: "-50%" }}
      />
    </>
  );
}
```

Markup usage — no imports needed:

```tsx
<button data-cursor="large">Hover me</button>
<p data-cursor="text">Read this paragraph</p>
<div data-cursor="dot">Subtle area</div>
```

### 8. Blend mode cursor

The classic Awwwards white circle that inverts over content using `mix-blend-difference`.

```tsx
// src/components/blend-cursor.tsx
"use client";
import { useEffect } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

export function BlendCursor({ size = 48 }: { size?: number }) {
  const isTouch = useIsTouchDevice();
  const cursorX = useMotionValue(0);
  const cursorY = useMotionValue(0);
  const spring = { damping: 25, stiffness: 200, mass: 0.5 };
  const x = useSpring(cursorX, spring);
  const y = useSpring(cursorY, spring);

  useEffect(() => {
    if (isTouch) return;
    function onMove(e: MouseEvent) {
      cursorX.set(e.clientX);
      cursorY.set(e.clientY);
    }
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, [isTouch, cursorX, cursorY]);

  if (isTouch) return null;

  return (
    <>
      <style>{`body { cursor: none !important; }`}</style>
      <motion.div
        className="pointer-events-none fixed top-0 left-0 z-50 rounded-full bg-white"
        style={{
          x,
          y,
          width: size,
          height: size,
          translateX: "-50%",
          translateY: "-50%",
          mixBlendMode: "difference",
        }}
      />
    </>
  );
}
```

The `mix-blend-difference` mode inverts colors: white cursor appears black over white backgrounds and white over dark backgrounds. Works only when the cursor sits over opaque content — transparent backgrounds produce no visible effect.

### 9. Reduced motion support

Wrap any cursor component to respect `prefers-reduced-motion`.

```tsx
// src/hooks/use-reduced-motion.ts
"use client";
import { useState, useEffect } from "react";

export function useReducedMotion() {
  const [reduced, setReduced] = useState(false);

  useEffect(() => {
    const query = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReduced(query.matches);
    function onChange(e: MediaQueryListEvent) { setReduced(e.matches); }
    query.addEventListener("change", onChange);
    return () => query.removeEventListener("change", onChange);
  }, []);

  return reduced;
}
```

Usage inside any cursor component:

```tsx
const reducedMotion = useReducedMotion();
if (reducedMotion || isTouch) return null;
```

When reduced motion is active: disable trail, disable magnetic pull, use instant follow (no spring) or hide custom cursor entirely.

## Anti-pattern

```tsx
// WRONG: Custom cursor without touch device check — breaks mobile
export function BadCursor() {
  // No touch detection — renders invisible cursor on phones
  return <motion.div className="fixed ..." />;
}
```

```tsx
// WRONG: cursor: none without a visible custom cursor
useEffect(() => {
  document.body.style.cursor = "none"; // User cannot see cursor at all
}, []);
```

```tsx
// WRONG: Magnetic pull too strong — button becomes unusable
<MagneticElement strength={0.9} threshold={300}>
  {/* Element snaps to cursor, impossible to click accurately */}
  <button>Submit</button>
</MagneticElement>
```

```tsx
// WRONG: Trail with too many elements — causes jank
<CursorTrail dotCount={30} /> {/* 30 DOM elements updating every frame */}
```

```tsx
// WRONG: No reduced-motion fallback
export function SpotlightNoA11y() {
  // Ignores prefers-reduced-motion entirely
  return <SpotlightSection>{/* ... */}</SpotlightSection>;
}
```

```tsx
// WRONG: Missing pointer-events-none — cursor blocks all clicks
<motion.div
  className="fixed z-50 rounded-full bg-white"
  // Forgot pointer-events-none — nothing on the page is clickable
/>
```

## Common Mistakes

1. **Not disabling on touch devices** — Custom cursor renders invisibly on mobile/tablet. Always gate with `useIsTouchDevice()`.

2. **Forgetting `pointer-events: none`** — The cursor div sits on top of everything. Without `pointer-events-none`, users cannot click anything.

3. **Magnetic strength too high** — Values above 0.4 make elements jump aggressively. Keep `strength` at 0.2-0.3 for usability.

4. **Too many trail elements** — Each trail dot is a DOM node updating on every mouse move. Cap at 8 dots maximum.

5. **Using `position: absolute` instead of `fixed`** — Absolute positioning makes the cursor scroll with the page. Always use `fixed`.

6. **Low z-index** — Cursor hidden behind modals or overlays. Use `z-50` at minimum, or `z-[9999]` if the site uses high z-index values.

7. **Blend mode on transparent backgrounds** — `mix-blend-difference` produces no visible effect over `transparent` or `rgba(0,0,0,0)`. Ensure content areas have opaque backgrounds.

8. **No error boundary fallback** — If the cursor component throws, the real cursor is hidden via `cursor: none` but no replacement is visible. Wrap in an error boundary that restores the default cursor.

9. **SSR mismatch** — `useMotionValue` and window listeners cause hydration mismatches. Ensure all cursor components are client-only with `"use client"` and use `useEffect` for window access.

10. **Forgetting cleanup** — Event listeners on `window` and `document` must be removed in the useEffect cleanup function to prevent memory leaks.

## Checklist

- [ ] Custom cursor disabled on touch devices via `useIsTouchDevice`
- [ ] Cursor element has `pointer-events-none` and `fixed` positioning
- [ ] Spring physics for smooth follow (not instant snap)
- [ ] Magnetic pull strength <= 0.3 (0 = no pull, 1 = full snap)
- [ ] Cursor trail limited to <= 8 elements
- [ ] `prefers-reduced-motion` disables trail and magnetic effects
- [ ] Cursor z-index above all content (`z-50` or higher)
- [ ] Fallback to default cursor if custom cursor component errors
- [ ] All cursor components marked `"use client"`
- [ ] Event listeners cleaned up in useEffect return
- [ ] No SSR hydration mismatches (window access in useEffect only)
- [ ] Blend mode cursor used only over opaque backgrounds

## Advanced Patterns

### Cursor text follower

A label that orbits the cursor — common on Awwwards portfolio sites.

```tsx
"use client";

import { useEffect, useRef } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

export function CursorLabel({ text = "View" }: { text?: string }) {
  const isTouch = useIsTouchDevice();
  const [visible, setVisible] = useState(false);
  const cursorX = useMotionValue(0);
  const cursorY = useMotionValue(0);
  const spring = { damping: 20, stiffness: 150, mass: 0.5 };
  const x = useSpring(cursorX, spring);
  const y = useSpring(cursorY, spring);

  useEffect(() => {
    if (isTouch) return;
    function onMove(e: MouseEvent) {
      cursorX.set(e.clientX);
      cursorY.set(e.clientY);
    }
    function onOver(e: MouseEvent) {
      const target = (e.target as HTMLElement).closest("[data-cursor-label]");
      setVisible(!!target);
    }
    window.addEventListener("mousemove", onMove);
    document.addEventListener("mouseover", onOver);
    return () => {
      window.removeEventListener("mousemove", onMove);
      document.removeEventListener("mouseover", onOver);
    };
  }, [isTouch, cursorX, cursorY]);

  if (isTouch) return null;

  return (
    <motion.div
      className="pointer-events-none fixed top-0 left-0 z-50 flex h-20 w-20 items-center justify-center rounded-full bg-primary text-xs font-medium text-primary-foreground"
      style={{ x, y, translateX: "-50%", translateY: "-50%" }}
      animate={{
        scale: visible ? 1 : 0,
        opacity: visible ? 1 : 0,
      }}
      transition={{ type: "spring", stiffness: 300, damping: 20 }}
    >
      {text}
    </motion.div>
  );
}

// Usage: <div data-cursor-label>Hover me for label</div>
```

### Canvas-based cursor trail (GPU performance)

For high-performance trails, use Canvas instead of DOM elements — handles 60fps even with many particles.

```tsx
"use client";

import { useRef, useEffect } from "react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

export function CanvasCursorTrail({
  color = "rgba(255,255,255,0.6)",
  particleCount = 20,
  fadeSpeed = 0.03,
}: {
  color?: string;
  particleCount?: number;
  fadeSpeed?: number;
}) {
  const isTouch = useIsTouchDevice();
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (isTouch) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    canvas.width = window.innerWidth * dpr;
    canvas.height = window.innerHeight * dpr;
    ctx.scale(dpr, dpr);

    const particles: { x: number; y: number; alpha: number; size: number }[] = [];

    function onMove(e: MouseEvent) {
      particles.push({
        x: e.clientX,
        y: e.clientY,
        alpha: 1,
        size: 3 + Math.random() * 4,
      });
      if (particles.length > particleCount) particles.shift();
    }

    function tick() {
      if (!ctx || !canvas) return;
      ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);

      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.alpha -= fadeSpeed;
        if (p.alpha <= 0) { particles.splice(i, 1); continue; }

        ctx.globalAlpha = p.alpha;
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size * p.alpha, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.globalAlpha = 1;
      requestAnimationFrame(tick);
    }

    window.addEventListener("mousemove", onMove);
    const raf = requestAnimationFrame(tick);

    function onResize() {
      if (!canvas) return;
      canvas.width = window.innerWidth * dpr;
      canvas.height = window.innerHeight * dpr;
      ctx?.scale(dpr, dpr);
    }
    window.addEventListener("resize", onResize);

    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("resize", onResize);
      cancelAnimationFrame(raf);
    };
  }, [isTouch, color, particleCount, fadeSpeed]);

  if (isTouch) return null;

  return (
    <canvas
      ref={canvasRef}
      className="pointer-events-none fixed inset-0 z-50"
      aria-hidden="true"
    />
  );
}
```

### Cursor-reactive text distortion

Text characters displace when the cursor approaches — a signature Awwwards effect.

```tsx
"use client";

import { useRef, useEffect, useState } from "react";

export function CursorDistortText({
  text,
  className,
  radius = 100,
  strength = 20,
}: {
  text: string;
  className?: string;
  radius?: number;
  strength?: number;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const charsRef = useRef<HTMLSpanElement[]>([]);
  const mouseRef = useRef({ x: -1000, y: -1000 });

  useEffect(() => {
    let raf: number;

    function onMove(e: MouseEvent) {
      mouseRef.current = { x: e.clientX, y: e.clientY };
    }

    function tick() {
      const { x: mx, y: my } = mouseRef.current;
      for (const char of charsRef.current) {
        if (!char) continue;
        const rect = char.getBoundingClientRect();
        const cx = rect.left + rect.width / 2;
        const cy = rect.top + rect.height / 2;
        const dx = cx - mx;
        const dy = cy - my;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < radius) {
          const force = (1 - dist / radius) * strength;
          const ax = (dx / dist) * force;
          const ay = (dy / dist) * force;
          char.style.transform = `translate(${ax}px, ${ay}px)`;
        } else {
          char.style.transform = "translate(0, 0)";
        }
      }
      raf = requestAnimationFrame(tick);
    }

    window.addEventListener("mousemove", onMove);
    raf = requestAnimationFrame(tick);

    return () => {
      window.removeEventListener("mousemove", onMove);
      cancelAnimationFrame(raf);
    };
  }, [radius, strength]);

  return (
    <div ref={containerRef} className={className} aria-label={text}>
      {text.split("").map((char, i) => (
        <span
          key={i}
          ref={(el) => { if (el) charsRef.current[i] = el; }}
          className="inline-block transition-transform duration-100 ease-out"
          aria-hidden="true"
        >
          {char === " " ? "\u00A0" : char}
        </span>
      ))}
    </div>
  );
}
```

### Cursor with color sampling

Cursor that adapts its color based on the underlying DOM element — always visible regardless of background.

```tsx
"use client";

import { useEffect, useRef, useState } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";
import { useIsTouchDevice } from "@/hooks/use-is-touch-device";

export function AdaptiveCursor() {
  const isTouch = useIsTouchDevice();
  const [cursorColor, setCursorColor] = useState("white");
  const cursorX = useMotionValue(0);
  const cursorY = useMotionValue(0);
  const spring = { damping: 25, stiffness: 200, mass: 0.5 };
  const x = useSpring(cursorX, spring);
  const y = useSpring(cursorY, spring);
  const sampleInterval = useRef<ReturnType<typeof setInterval>>();

  useEffect(() => {
    if (isTouch) return;

    function onMove(e: MouseEvent) {
      cursorX.set(e.clientX);
      cursorY.set(e.clientY);
    }

    // Sample element color under cursor periodically (not every frame)
    sampleInterval.current = setInterval(() => {
      const cx = cursorX.get();
      const cy = cursorY.get();
      const el = document.elementFromPoint(cx, cy);
      if (!el) return;
      const bg = getComputedStyle(el).backgroundColor;
      // Parse RGB and compute luminance
      const match = bg.match(/\d+/g);
      if (match && match.length >= 3) {
        const [r, g, b] = match.map(Number);
        const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        setCursorColor(luminance > 0.5 ? "black" : "white");
      }
    }, 100); // Sample at 10fps, not 60fps

    window.addEventListener("mousemove", onMove);
    return () => {
      window.removeEventListener("mousemove", onMove);
      clearInterval(sampleInterval.current);
    };
  }, [isTouch, cursorX, cursorY]);

  if (isTouch) return null;

  return (
    <>
      <style>{`body { cursor: none !important; }`}</style>
      <motion.div
        className="pointer-events-none fixed top-0 left-0 z-50 h-10 w-10 rounded-full border-2"
        style={{
          x, y,
          translateX: "-50%",
          translateY: "-50%",
          borderColor: cursorColor,
          transition: "border-color 0.15s ease",
        }}
      />
    </>
  );
}
```

## Composes With

- `animation` — spring physics, Motion values, keyframe sequences
- `accessibility` — reduced motion preference, touch device support
- `performance` — RAF-based updates, minimal DOM element count
- `landing-patterns` — premium cursor effects for marketing and portfolio pages
- `dark-mode` — blend mode cursor adapts automatically to theme changes
- `responsive-design` — touch detection disables cursor effects on mobile breakpoints
- `sound-design` — sound triggered on cursor state changes
- `svg-canvas` — canvas-based trail for GPU performance
