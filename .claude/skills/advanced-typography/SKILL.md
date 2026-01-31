---
name: advanced-typography
description: >
  Variable font setup, fluid type scale with clamp(), text splitting, kinetic text animation, outlined/stroked text, text effects (glitch, scramble, typewriter), variable font weight animation
allowed-tools: Read, Grep, Glob
---

# Advanced Typography

## Purpose

Advanced typography patterns for Next.js 15 + React 19. Covers variable font setup (Inter axis controls), fluid type scale with `clamp()`, text splitting (SplitType), kinetic text animation, outlined/stroked text, text effects (glitch, scramble, typewriter), and variable font weight animation on hover. The ONE skill for typography that wins Awwwards.

## When to Use

- Setting up variable fonts with axis controls (`wght`, `opsz`)
- Creating fluid type scales with `clamp()` that adapt from mobile to ultrawide
- Adding text splitting for char-by-char or word-by-word animations
- Building kinetic text (text that moves, rotates, or transforms on scroll/hover)
- Creating outlined/stroked text effects with fill-on-hover
- Adding glitch, scramble, or typewriter text effects
- Animating `font-weight` on hover with variable fonts

## When NOT to Use

- Basic font sizing and hierarchy — use `visual-design`
- Font loading optimization and FOIT/FOUT — use `performance`
- i18n text rendering and bidirectional layout — use `i18n`
- Rich text editing (WYSIWYG, Markdown) — use `rich-text`

## Pattern

### 1. Variable Font Setup

Register Inter variable font in `src/app/layout.tsx`:

```tsx
import { Inter } from "next/font/google";
const inter = Inter({ subsets: ["latin"], display: "swap", variable: "--font-inter" });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>{children}</body>
    </html>
  );
}
```

Design tokens and axis utilities in `src/app/globals.css`:

```css
@import "tailwindcss";

@theme {
  --font-sans: var(--font-inter), ui-sans-serif, system-ui, sans-serif;
  --font-weight-thin: 100;
  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --font-weight-extrabold: 800;
  --font-weight-black: 900;
}

@utility font-optical-auto { font-variation-settings: "opsz" auto; }
@utility font-wght-850 { font-weight: 850; }
```

### 2. Fluid Type Scale with clamp()

Formula: `clamp(min, preferred, max)` where preferred uses `vi` for fluid interpolation.

```css
@theme {
  --text-xs: clamp(0.6875rem, 0.625rem + 0.25vi, 0.8125rem);
  --text-sm: clamp(0.8125rem, 0.75rem + 0.25vi, 0.9375rem);
  --text-base: clamp(1rem, 0.9rem + 0.4vi, 1.125rem);
  --text-lg: clamp(1.125rem, 0.95rem + 0.7vi, 1.375rem);
  --text-xl: clamp(1.25rem, 1rem + 1vi, 1.625rem);
  --text-2xl: clamp(1.5rem, 1.1rem + 1.6vi, 2rem);
  --text-3xl: clamp(1.875rem, 1.2rem + 2.7vi, 2.75rem);
  --text-4xl: clamp(2.25rem, 1.2rem + 4.2vi, 3.75rem);
  --text-5xl: clamp(3rem, 1.5rem + 6vi, 5rem);
  --text-6xl: clamp(3.75rem, 1.5rem + 9vi, 7rem);
}
```

### 3. Text Splitting

**Option A (recommended): GSAP SplitText** — now free (thanks to Webflow). Handles resize via `autoSplit`, accessible, and integrates natively with GSAP animations.

```bash
npm install gsap
```

```tsx
import { SplitText } from "gsap/SplitText";
import gsap from "gsap";
gsap.registerPlugin(SplitText);

// SplitText with autoSplit (re-splits on resize automatically)
const split = SplitText.create(".heading", {
  type: "chars,words,lines",
  autoSplit: true,
  onSplit(self) {
    // Create animations in callback so they target fresh elements after re-split
    gsap.from(self.chars, { opacity: 0, y: 20, stagger: 0.03 });
  },
});
```

**Option B: split-type** — lighter alternative if not using GSAP.

Install: `npm install split-type`

```tsx
// src/components/ui/split-text.tsx
"use client";
import { useEffect, useRef } from "react";
import SplitType from "split-type";
import { motion, useInView } from "motion/react";

type SplitTextProps = {
  children: string;
  className?: string;
  splitBy?: "chars" | "words" | "lines";
  stagger?: number;
  as?: "h1" | "h2" | "h3" | "p" | "span";
};

export function SplitText({ children, className, splitBy = "chars", stagger = 0.03, as: Tag = "p" }: SplitTextProps) {
  const containerRef = useRef<HTMLElement>(null);
  const isInView = useInView(containerRef, { once: true, margin: "-10%" });
  const splitRef = useRef<SplitType | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;
    splitRef.current = new SplitType(containerRef.current, { types: splitBy });
    return () => { splitRef.current?.revert(); }; // cleanup prevents DOM pollution
  }, [children, splitBy]);

  return (
    <Tag ref={containerRef as React.Ref<HTMLHeadingElement & HTMLParagraphElement>} className={className} aria-label={children}>
      {isInView && splitRef.current?.[splitBy]?.map((el, i) => (
        <motion.span key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, delay: i * stagger, ease: [0.25, 0.46, 0.45, 0.94] }}
          style={{ display: "inline-block" }} aria-hidden="true">
          {el.textContent === " " ? "\u00A0" : el.textContent}
        </motion.span>
      ))}
    </Tag>
  );
}
```

### 4. Kinetic Text Animation

**Char-by-char reveal on scroll:**

```tsx
// src/components/ui/kinetic-heading.tsx
"use client";
import { useRef } from "react";
import { motion, useInView } from "motion/react";

export function KineticHeading({ text, className }: { text: string; className?: string }) {
  const ref = useRef<HTMLHeadingElement>(null);
  const isInView = useInView(ref, { once: true, margin: "-15%" });
  const shouldReduce = typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  return (
    <h2 ref={ref} className={className} aria-label={text}>
      {text.split("").map((char, i) => (
        <motion.span key={i} initial={shouldReduce ? false : { opacity: 0, y: 40, rotateX: -90 }}
          animate={isInView ? { opacity: 1, y: 0, rotateX: 0 } : undefined}
          transition={{ duration: 0.5, delay: i * 0.04, ease: [0.22, 1, 0.36, 1] }}
          style={{ display: "inline-block", transformOrigin: "bottom" }} aria-hidden="true">
          {char === " " ? "\u00A0" : char}
        </motion.span>
      ))}
    </h2>
  );
}
```

**Rotating words** (cycling with AnimatePresence):

```tsx
// src/components/ui/rotating-words.tsx
"use client";
import { useState, useEffect } from "react";
import { AnimatePresence, motion } from "motion/react";
import { cn } from "@/lib/utils";

export function RotatingWords({ words, interval = 2500, className }: { words: string[]; interval?: number; className?: string }) {
  const [index, setIndex] = useState(0);
  useEffect(() => {
    const timer = setInterval(() => setIndex((p) => (p + 1) % words.length), interval);
    return () => clearInterval(timer);
  }, [words.length, interval]);

  return (
    <span className={cn("relative inline-block", className)}>
      <AnimatePresence mode="wait">
        <motion.span key={words[index]} initial={{ opacity: 0, y: 20, filter: "blur(4px)" }}
          animate={{ opacity: 1, y: 0, filter: "blur(0px)" }} exit={{ opacity: 0, y: -20, filter: "blur(4px)" }}
          transition={{ duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] }} className="inline-block">
          {words[index]}
        </motion.span>
      </AnimatePresence>
    </span>
  );
}
```

**Wave effect** (chars oscillating with staggered delay):

```tsx
// src/components/ui/wave-text.tsx
"use client";
import { motion } from "motion/react";

export function WaveText({ text, className }: { text: string; className?: string }) {
  return (
    <span className={className} aria-label={text}>
      {text.split("").map((char, i) => (
        <motion.span key={i} animate={{ y: [0, -8, 0] }}
          transition={{ duration: 1.2, delay: i * 0.06, repeat: Infinity, repeatDelay: 2, ease: "easeInOut" }}
          style={{ display: "inline-block" }} aria-hidden="true">
          {char === " " ? "\u00A0" : char}
        </motion.span>
      ))}
    </span>
  );
}
```

### 5. Outlined / Stroked Text

Tailwind v4 utilities:

```css
@utility text-outline {
  -webkit-text-fill-color: transparent;
  -webkit-text-stroke: 2px currentColor;
}
@utility text-outline-thick {
  -webkit-text-fill-color: transparent;
  -webkit-text-stroke: 4px currentColor;
}
@utility hover-fill {
  transition: -webkit-text-fill-color 0.3s ease;
  &:hover { -webkit-text-fill-color: currentColor; }
}
```

SVG fallback for gradient stroke (broader browser support):

```tsx
// src/components/ui/gradient-stroke-text.tsx
export function GradientStrokeText({ text, className }: { text: string; className?: string }) {
  return (
    <svg viewBox="0 0 800 120" className={cn("w-full", className)}>
      <defs>
        <linearGradient id="stroke-grad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="oklch(0.7 0.25 330)" />
          <stop offset="50%" stopColor="oklch(0.7 0.25 270)" />
          <stop offset="100%" stopColor="oklch(0.7 0.25 210)" />
        </linearGradient>
      </defs>
      <text x="50%" y="50%" dominantBaseline="middle" textAnchor="middle" fill="none"
        stroke="url(#stroke-grad)" strokeWidth="2" fontSize="80" fontWeight="900" fontFamily="var(--font-sans)">
        {text}
      </text>
    </svg>
  );
}
```

### 6. Text Effects

**Glitch effect** — CSS `clip-path` + pseudo-elements (hover-triggered only):

```css
@utility text-glitch {
  position: relative;
  &::before, &::after { content: attr(data-text); position: absolute; inset: 0; }
  &::before {
    color: oklch(0.7 0.25 25); clip-path: inset(0 0 60% 0);
    animation: glitch-top 2s steps(1) infinite;
  }
  &::after {
    color: oklch(0.7 0.25 250); clip-path: inset(40% 0 0 0);
    animation: glitch-bottom 2s steps(1) infinite;
  }
}
@keyframes glitch-top {
  0%, 100% { transform: translate(0); } 20% { transform: translate(-3px, -2px); }
  40% { transform: translate(3px, 2px); } 60% { transform: translate(-2px, 1px); }
}
@keyframes glitch-bottom {
  0%, 100% { transform: translate(0); } 20% { transform: translate(3px, 2px); }
  40% { transform: translate(-3px, -1px); } 60% { transform: translate(2px, -2px); }
}
```

```tsx
export function GlitchText({ text, className }: { text: string; className?: string }) {
  return <span className={cn("hover:text-glitch", className)} data-text={text}>{text}</span>;
}
```

**Scramble effect** — randomize characters before revealing:

```tsx
// src/components/ui/scramble-text.tsx
"use client";
import { useState, useEffect, useRef, useCallback } from "react";
import { useInView } from "motion/react";
import { cn } from "@/lib/utils";

const CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%";

export function ScrambleText({ text, className, speed = 30, trigger = "inView" }: {
  text: string; className?: string; speed?: number; trigger?: "mount" | "hover" | "inView";
}) {
  const [displayed, setDisplayed] = useState(trigger === "mount" ? "" : text);
  const ref = useRef<HTMLSpanElement>(null);
  const isInView = useInView(ref, { once: true });

  const scramble = useCallback(() => {
    let iteration = 0;
    const interval = setInterval(() => {
      setDisplayed(text.split("").map((char, i) => {
        if (i < iteration) return char;
        return char === " " ? " " : CHARS[Math.floor(Math.random() * CHARS.length)];
      }).join(""));
      iteration += 1 / 3;
      if (iteration >= text.length) { clearInterval(interval); setDisplayed(text); }
    }, speed);
    return () => clearInterval(interval);
  }, [text, speed]);

  useEffect(() => {
    if (trigger === "mount") return scramble();
    if (trigger === "inView" && isInView) return scramble();
  }, [trigger, isInView, scramble]);

  return (
    <span ref={ref} className={cn("font-mono", className)}
      onMouseEnter={() => trigger === "hover" && scramble()} aria-label={text}>
      <span aria-hidden="true">{displayed}</span>
    </span>
  );
}
```

**Typewriter effect** — one char at a time with blinking cursor:

```tsx
// src/components/ui/typewriter-text.tsx
"use client";
import { useState, useEffect, useRef } from "react";
import { useInView } from "motion/react";

export function TypewriterText({ text, className, speed = 50, delay = 0, cursor = true }: {
  text: string; className?: string; speed?: number; delay?: number; cursor?: boolean;
}) {
  const [count, setCount] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  const isInView = useInView(ref, { once: true });

  useEffect(() => {
    if (!isInView) return;
    const timeout = setTimeout(() => {
      const interval = setInterval(() => {
        setCount((p) => { if (p >= text.length) { clearInterval(interval); return p; } return p + 1; });
      }, speed);
      return () => clearInterval(interval);
    }, delay);
    return () => clearTimeout(timeout);
  }, [isInView, text.length, speed, delay]);

  return (
    <span ref={ref} className={className} aria-label={text}>
      <span aria-hidden="true">
        {text.slice(0, count)}
        {cursor && <span className="animate-blink ml-0.5 inline-block w-[2px] h-[1em] bg-current align-text-bottom" />}
      </span>
    </span>
  );
}
```

```css
@utility animate-blink { animation: blink 1s step-end infinite; }
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }
```

### 7. Variable Font Weight Animation

CSS-only weight animation:

```css
@utility weight-animate {
  transition: font-variation-settings 0.4s ease;
  font-variation-settings: "wght" 400;
  &:hover { font-variation-settings: "wght" 900; }
}
```

Motion-powered weight hover:

```tsx
// src/components/ui/weight-hover.tsx
"use client";
import { motion } from "motion/react";

export function WeightHover({ children, className, from = 400, to = 900 }: {
  children: React.ReactNode; className?: string; from?: number; to?: number;
}) {
  return (
    <motion.span className={className} initial={{ fontVariationSettings: `"wght" ${from}` }}
      whileHover={{ fontVariationSettings: `"wght" ${to}` }}
      transition={{ duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] }}>
      {children}
    </motion.span>
  );
}
```

Proximity weight (weight changes based on mouse distance to each character):

```tsx
// src/components/ui/proximity-weight.tsx
"use client";
import { useRef, useState, useCallback } from "react";

export function ProximityWeight({ text, className, minWeight = 100, maxWeight = 900, radius = 120 }: {
  text: string; className?: string; minWeight?: number; maxWeight?: number; radius?: number;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [weights, setWeights] = useState<number[]>(new Array(text.length).fill(minWeight));

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!containerRef.current) return;
    const spans = containerRef.current.querySelectorAll("span[data-char]");
    setWeights(Array.from(spans).map((span) => {
      const rect = span.getBoundingClientRect();
      const distance = Math.abs(e.clientX - (rect.left + rect.width / 2));
      return Math.round(minWeight + Math.max(0, 1 - distance / radius) * (maxWeight - minWeight));
    }));
  }, [minWeight, maxWeight, radius]);

  return (
    <div ref={containerRef} className={className} onMouseMove={handleMouseMove}
      onMouseLeave={() => setWeights(new Array(text.length).fill(minWeight))} aria-label={text}>
      {text.split("").map((char, i) => (
        <span key={i} data-char aria-hidden="true" style={{
          display: "inline-block", fontVariationSettings: `"wght" ${weights[i]}`,
          transition: "font-variation-settings 0.15s ease-out",
        }}>{char === " " ? "\u00A0" : char}</span>
      ))}
    </div>
  );
}
```

### 8. Gradient Text

Static gradient:

```tsx
export function GradientText({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <span className={cn("bg-gradient-to-r from-purple-500 via-pink-500 to-orange-500 bg-clip-text text-transparent", className)}>
      {children}
    </span>
  );
}
```

Animated gradient with oklch for smooth transitions:

```css
@utility text-gradient-animate {
  background: linear-gradient(90deg, oklch(0.7 0.25 330), oklch(0.7 0.25 270), oklch(0.7 0.25 210), oklch(0.7 0.25 330));
  background-size: 300% 100%;
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: gradient-shift 4s linear infinite;
}
@keyframes gradient-shift { 0% { background-position: 0% 50%; } 100% { background-position: 300% 50%; } }
```

## Anti-pattern

```tsx
// WRONG: Fixed px font sizes (not fluid)
<h1 style={{ fontSize: "72px" }}>Heading</h1>
// CORRECT: Fluid clamp() from @theme
<h1 className="text-6xl">Heading</h1>

// WRONG: text-stroke without fallback color
<span className="text-outline">Text</span>
// CORRECT: Always set a fallback color
<span className="text-outline text-white">Text</span>

// WRONG: SplitType without cleanup
useEffect(() => { new SplitType(ref.current, { types: "chars" }); }, []);
// CORRECT: Revert on unmount
useEffect(() => {
  const split = new SplitType(ref.current, { types: "chars" });
  return () => split.revert();
}, []);

// WRONG: Animating font-weight on non-variable font (snaps, no interpolation)
<span className="font-['Arial'] transition-all hover:font-bold">Text</span>
// CORRECT: Only animate weight on variable fonts
<span className="font-sans weight-animate">Text</span>

// WRONG: Kinetic text without prefers-reduced-motion check
<motion.span animate={{ y: [0, -10, 0] }} transition={{ repeat: Infinity }}>{char}</motion.span>
// CORRECT: Respect reduced motion
const shouldReduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
<motion.span animate={shouldReduce ? undefined : { y: [0, -10, 0] }}>{char}</motion.span>
```

## Common Mistakes

1. **Not cleaning up SplitType on unmount.** SplitType mutates the DOM by wrapping characters in `<span>` elements. Without `split.revert()` in cleanup, re-renders cause DOM pollution and duplicated characters.

2. **Using `font-weight` transitions on non-variable fonts.** Non-variable fonts have discrete weight steps (400, 700). Transitions snap instead of interpolating. Only variable fonts with a `wght` axis animate smoothly.

3. **Fluid type too small on mobile or too large on ultrawide.** Always set reasonable `clamp()` min/max bounds. Test at 320px and 2560px widths.

4. **Text splitting breaking screen readers.** Split `<span>` elements get read individually. Add `aria-label` on the parent with full text and `aria-hidden="true"` on each span.

5. **Forgetting `text-fill-color: transparent` with `-webkit-text-stroke`.** Without transparent fill, the stroke is hidden behind the solid fill color.

6. **Glitch effect running continuously.** Permanent glitch harms readability. Trigger on hover or scroll only.

## Checklist

- [ ] Variable font loaded with `next/font/google` and proper config
- [ ] Fluid type scale uses `clamp()` with reasonable min/max bounds
- [ ] Text splitting includes `aria-label` on parent for accessibility
- [ ] All split character spans have `aria-hidden="true"`
- [ ] Kinetic text respects `prefers-reduced-motion: reduce`
- [ ] Outlined text has fallback color for browsers without `-webkit-text-stroke`
- [ ] Text effects (glitch, scramble, typewriter) are `"use client"` components
- [ ] SplitType instances cleaned up with `revert()` on unmount
- [ ] All font sizes defined in `@theme {}` as design tokens
- [ ] Gradient text uses `-webkit-background-clip` alongside `background-clip`
- [ ] Font weight animations only applied to variable fonts with `wght` axis

## Advanced Patterns

### Scroll-driven variable font animation

Font weight, width, or slant changes as the user scrolls — text transforms as you read.

```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function ScrollFontWeight({ text }: { text: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });

  const fontWeight = useTransform(scrollYProgress, [0, 0.5, 1], [100, 900, 100]);

  return (
    <div ref={ref} className="py-32">
      <motion.h2
        style={{
          fontWeight,
          fontFamily: "'Inter Variable', sans-serif",
          fontVariationSettings: useTransform(fontWeight, (w) => `'wght' ${w}`),
        }}
        className="text-6xl md:text-8xl"
      >
        {text}
      </motion.h2>
    </div>
  );
}
```

### Text mask reveal on scroll

Text is clipped and progressively revealed with a gradient mask as the user scrolls.

```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function TextMaskReveal({ text }: { text: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start 80%", "start 30%"],
  });

  const maskPosition = useTransform(scrollYProgress, [0, 1], ["100%", "0%"]);

  return (
    <div ref={ref} className="py-24">
      <motion.p
        style={{
          backgroundImage: "linear-gradient(to right, var(--color-foreground) 50%, transparent 50%)",
          backgroundSize: "200% 100%",
          backgroundPositionX: maskPosition,
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          backgroundClip: "text",
        }}
        className="text-4xl font-bold md:text-6xl"
      >
        {text}
      </motion.p>
    </div>
  );
}
```

### Per-word scroll opacity

Each word in a paragraph fades in as scroll reaches its position — a reading-speed-aware reveal.

```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function WordByWordReveal({ text }: { text: string }) {
  const ref = useRef<HTMLParagraphElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start 80%", "end 40%"],
  });

  const words = text.split(" ");

  return (
    <p ref={ref} className="text-3xl leading-relaxed" aria-label={text}>
      {words.map((word, i) => {
        const start = i / words.length;
        const end = start + 1 / words.length;
        return (
          <Word key={i} word={word} range={[start, end]} progress={scrollYProgress} />
        );
      })}
    </p>
  );
}

function Word({
  word,
  range,
  progress,
}: {
  word: string;
  range: [number, number];
  progress: ReturnType<typeof useScroll>["scrollYProgress"];
}) {
  const opacity = useTransform(progress, range, [0.15, 1]);

  return (
    <motion.span
      style={{ opacity }}
      className="mr-[0.25em] inline-block"
      aria-hidden="true"
    >
      {word}
    </motion.span>
  );
}
```

### Circular text (rotating badge)

Text arranged in a circle that rotates continuously — a common Awwwards decorative element.

```tsx
export function CircularText({
  text,
  size = 120,
  className,
}: {
  text: string;
  size?: number;
  className?: string;
}) {
  const chars = text.split("");
  const angleStep = 360 / chars.length;

  return (
    <div
      className={`animate-[spin_12s_linear_infinite] ${className}`}
      style={{ width: size, height: size }}
      aria-label={text}
    >
      <svg viewBox={`0 0 ${size} ${size}`} className="h-full w-full">
        {chars.map((char, i) => {
          const angle = i * angleStep;
          const rad = (angle * Math.PI) / 180;
          const r = size / 2 - 10;
          const x = size / 2 + r * Math.cos(rad - Math.PI / 2);
          const y = size / 2 + r * Math.sin(rad - Math.PI / 2);

          return (
            <text
              key={i}
              x={x}
              y={y}
              textAnchor="middle"
              dominantBaseline="central"
              transform={`rotate(${angle}, ${x}, ${y})`}
              className="fill-current text-[10px] font-bold uppercase tracking-widest"
              aria-hidden="true"
            >
              {char}
            </text>
          );
        })}
      </svg>
    </div>
  );
}
```

## Composes With

- `tailwind-v4` — font design tokens in `@theme {}`, custom `@utility` classes
- `animation` — Motion integration for text reveal, kinetic, and hover effects
- `responsive-design` — fluid type scale adapts seamlessly across viewports
- `landing-patterns` — hero headings, section titles, and display typography
- `visual-design` — type hierarchy, weight system, and spacing rhythm
- `accessibility` — `aria-label`, `aria-hidden`, and `prefers-reduced-motion` for split/animated text
- `creative-scrolling` — scroll-driven font weight and text reveals
- `loading-transitions` — stagger text reveals on route entry
