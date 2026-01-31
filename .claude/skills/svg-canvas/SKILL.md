---
name: svg-canvas
description: >
  SVG line drawing, SVG morphing with Flubber, blob shapes, canvas particle systems, SVG filter effects, generative art patterns, animated SVG gradients
allowed-tools: Read, Grep, Glob
---

# SVG & Canvas

## Purpose

SVG animation and Canvas rendering patterns for Next.js 15 + React 19. Covers SVG line drawing
(pathLength animation), SVG morphing (shape-to-shape with Flubber), blob shapes (feTurbulence +
feDisplacementMap), canvas particle systems (RAF loop), SVG filter effects, generative art patterns
(Perlin noise), and animated SVG gradients. The ONE skill for 2D graphics beyond CSS.

## When to Use

- SVG line drawing / path tracing animations
- Shape morphing between two SVG paths
- Organic blob / liquid shapes
- Canvas-based particle systems
- SVG filter effects (blur, displacement, glow)
- Generative art and procedural graphics
- Animated gradient backgrounds with SVG

## When NOT to Use

- 3D scenes or WebGL → `webgl-3d`
- CSS-only animations → `animation`
- Icon systems → `shadcn`
- Image optimization → `image-optimization`

## Pattern

### 1. SVG Line Drawing

Animate `stroke-dashoffset` with `pathLength="1"`. This normalizes the path so
`stroke-dasharray: 1` and animating offset from 1 to 0 draws the full path.

```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function LineDrawing({
  d, width = 400, height = 400,
  strokeColor = "currentColor", strokeWidth = 2, duration = 2,
  viewBox = "0 0 400 400",
}: {
  d: string; width?: number; height?: number;
  strokeColor?: string; strokeWidth?: number; duration?: number;
  viewBox?: string;
}) {
  return (
    <svg width={width} height={height} viewBox={viewBox} fill="none" className="overflow-visible">
      <motion.path
        d={d} stroke={strokeColor} strokeWidth={strokeWidth}
        strokeLinecap="round" strokeLinejoin="round" pathLength={1}
        style={{ strokeDasharray: 1, strokeDashoffset: 1 }}
        animate={{ strokeDashoffset: 0 }}
        transition={{ duration, ease: "easeInOut" }}
      />
    </svg>
  );
}

// Scroll-triggered variant
export function ScrollLineDrawing({ d, viewBox = "0 0 800 600" }: {
  d: string; viewBox?: string;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: containerRef, offset: ["start end", "end start"],
  });
  const dashOffset = useTransform(scrollYProgress, [0, 1], [1, 0]);

  return (
    <div ref={containerRef} className="relative h-[200vh]">
      <svg viewBox={viewBox} fill="none" className="sticky top-0 h-screen w-full"
        preserveAspectRatio="xMidYMid meet">
        <motion.path
          d={d} stroke="var(--color-foreground)" strokeWidth={2}
          strokeLinecap="round" pathLength={1}
          style={{ strokeDasharray: 1, strokeDashoffset: dashOffset }}
        />
      </svg>
    </div>
  );
}
```

### 2. SVG Morphing with Flubber

Install: `npm install flubber && npm install -D @types/flubber`

Flubber interpolates between SVG path `d` strings with different point counts.

```tsx
"use client";

import { interpolate } from "flubber";
import { motion, useMotionValue, useTransform, animate } from "motion/react";
import { useEffect, useState } from "react";

export function MorphShape({
  paths, width = 400, height = 400,
  fill = "var(--color-primary)", duration = 1.5,
  viewBox = "0 0 400 400",
}: {
  paths: string[]; width?: number; height?: number;
  fill?: string; duration?: number; viewBox?: string;
}) {
  const [pathIndex, setPathIndex] = useState(0);
  const progress = useMotionValue(0);

  const interpolator = interpolate(
    paths[pathIndex],
    paths[(pathIndex + 1) % paths.length],
    { maxSegmentLength: 10 }
  );
  const d = useTransform(progress, (v) => interpolator(v));

  useEffect(() => {
    const controls = animate(progress, 1, {
      duration, ease: "easeInOut",
      onComplete: () => {
        progress.set(0);
        setPathIndex((prev) => (prev + 1) % paths.length);
      },
    });
    return () => controls.stop();
  }, [pathIndex, paths.length, duration, progress]);

  return (
    <svg width={width} height={height} viewBox={viewBox}>
      <motion.path d={d} fill={fill} />
    </svg>
  );
}
```

### 3. Blob Shapes

SVG `<feTurbulence>` + `<feDisplacementMap>` on a circle for organic morphing blobs.

```tsx
"use client";

import { useEffect, useRef } from "react";

export function BlobShape({
  size = 300, color = "var(--color-primary)",
  complexity = 3, speed = 0.002,
}: {
  size?: number; color?: string; complexity?: number; speed?: number;
}) {
  const turbulenceRef = useRef<SVGFETurbulenceElement>(null);
  const rafRef = useRef<number>(0);
  const filterId = `blob-filter-${size}`;

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let phase = 0;
    function tick() {
      phase += speed;
      turbulenceRef.current?.setAttribute(
        "baseFrequency", `${0.01 + Math.sin(phase) * 0.005}`
      );
      rafRef.current = requestAnimationFrame(tick);
    }
    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
  }, [speed]);

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <defs>
        <filter id={filterId}>
          <feTurbulence ref={turbulenceRef} type="fractalNoise"
            baseFrequency="0.01" numOctaves={complexity} seed={42} result="noise" />
          <feDisplacementMap in="SourceGraphic" in2="noise" scale={50}
            xChannelSelector="R" yChannelSelector="G" />
        </filter>
      </defs>
      <circle cx={size / 2} cy={size / 2} r={size / 3}
        fill={color} filter={`url(#${filterId})`} />
    </svg>
  );
}
```

CSS-only alternative: animate `border-radius` with multiple keyframes
(`60% 40% 30% 70% / 60% 30% 70% 40%` etc.) on an 8s infinite loop.

### 4. Canvas Particle System

Pre-allocated pool with mouse repulsion, `devicePixelRatio` support, and `ResizeObserver`.

```tsx
"use client";

import { useRef, useEffect, useCallback } from "react";

type Particle = {
  x: number; y: number; vx: number; vy: number;
  size: number; color: string; life: number; maxLife: number; active: boolean;
};

function createParticle(w: number, h: number, colors: string[]): Particle {
  const maxLife = 200 + Math.random() * 300;
  return {
    x: Math.random() * w, y: Math.random() * h,
    vx: (Math.random() - 0.5) * 1.5, vy: (Math.random() - 0.5) * 1.5,
    size: 1 + Math.random() * 3,
    color: colors[Math.floor(Math.random() * colors.length)],
    life: maxLife, maxLife, active: true,
  };
}

export function ParticleCanvas({
  count = 150, colors = ["#6366f1", "#8b5cf6", "#a78bfa", "#c4b5fd"],
  className, mouseRepelRadius = 100, mouseRepelForce = 5,
}: {
  count?: number; colors?: string[]; className?: string;
  mouseRepelRadius?: number; mouseRepelForce?: number;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const mouseRef = useRef({ x: -1000, y: -1000 });
  const poolRef = useRef<Particle[]>([]);
  const rafRef = useRef<number>(0);

  const handleMouseMove = useCallback((e: MouseEvent) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    mouseRef.current = {
      x: (e.clientX - rect.left) * dpr,
      y: (e.clientY - rect.top) * dpr,
    };
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const dpr = window.devicePixelRatio || 1;

    function resize() {
      if (!canvas) return;
      const rect = canvas.getBoundingClientRect();
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
    }
    const observer = new ResizeObserver(resize);
    observer.observe(canvas);
    resize();

    poolRef.current = Array.from({ length: count }, () =>
      createParticle(canvas.width, canvas.height, colors)
    );

    function resetParticle(p: Particle) {
      if (!canvas) return;
      p.x = Math.random() * canvas.width;
      p.y = Math.random() * canvas.height;
      p.vx = (Math.random() - 0.5) * 1.5;
      p.vy = (Math.random() - 0.5) * 1.5;
      p.life = p.maxLife;
      p.active = true;
    }

    function tick() {
      if (!canvas || !ctx) return;
      const w = canvas.width, h = canvas.height;
      ctx.clearRect(0, 0, w / dpr, h / dpr);
      const { x: mx, y: my } = mouseRef.current;

      for (const p of poolRef.current) {
        if (!p.active) { resetParticle(p); continue; }
        const dx = p.x - mx, dy = p.y - my;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < mouseRepelRadius && dist > 0) {
          const force = (1 - dist / mouseRepelRadius) * mouseRepelForce;
          p.vx += (dx / dist) * force;
          p.vy += (dy / dist) * force;
        }
        p.vx *= 0.98; p.vy *= 0.98;
        p.x += p.vx; p.y += p.vy; p.life -= 1;
        if (p.x < 0) p.x = w; if (p.x > w) p.x = 0;
        if (p.y < 0) p.y = h; if (p.y > h) p.y = 0;
        if (p.life <= 0) { p.active = false; continue; }

        ctx.globalAlpha = p.life / p.maxLife;
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x / dpr, p.y / dpr, p.size, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.globalAlpha = 1;
      rafRef.current = requestAnimationFrame(tick);
    }

    if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      rafRef.current = requestAnimationFrame(tick);
    }
    window.addEventListener("mousemove", handleMouseMove);
    return () => {
      cancelAnimationFrame(rafRef.current);
      observer.disconnect();
      window.removeEventListener("mousemove", handleMouseMove);
    };
  }, [count, colors, mouseRepelRadius, mouseRepelForce, handleMouseMove]);

  return (
    <canvas ref={canvasRef}
      className={className ?? "absolute inset-0 h-full w-full"} aria-hidden="true" />
  );
}
```

### 5. SVG Filter Effects

Render shared filters once in the layout via `<SVGFilters />`. Reference with `filter: url(#id)`.

```tsx
"use client";

export function SVGFilters() {
  return (
    <svg className="pointer-events-none fixed h-0 w-0" aria-hidden="true">
      <defs>
        {/* Glow */}
        <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="blur" />
          <feColorMatrix in="blur" type="matrix"
            values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 18 -7" result="glow" />
          <feComposite in="SourceGraphic" in2="glow" operator="over" />
        </filter>
        {/* Distortion */}
        <filter id="distort">
          <feTurbulence type="fractalNoise" baseFrequency="0.015"
            numOctaves={3} seed={2} result="noise" />
          <feDisplacementMap in="SourceGraphic" in2="noise" scale={20}
            xChannelSelector="R" yChannelSelector="G" />
        </filter>
        {/* Outline / dilate */}
        <filter id="outline">
          <feMorphology in="SourceAlpha" operator="dilate" radius="2" result="dilated" />
          <feFlood floodColor="var(--color-primary)" result="color" />
          <feComposite in="color" in2="dilated" operator="in" result="outline" />
          <feComposite in="SourceGraphic" in2="outline" operator="over" />
        </filter>
        {/* Animated hue rotate */}
        <filter id="color-shift">
          <feColorMatrix type="hueRotate" values="0">
            <animate attributeName="values" from="0" to="360" dur="8s"
              repeatCount="indefinite" />
          </feColorMatrix>
        </filter>
      </defs>
    </svg>
  );
}

// Usage: <span style={{ filter: "url(#glow)", willChange: "filter" }}>Glow text</span>
```

### 6. Generative Art (Perlin Noise)

For production use the `simplex-noise` npm package. Minimal inline noise shown here.

```tsx
"use client";

import { useRef, useEffect } from "react";

function noise2D(x: number, y: number, seed: number): number {
  const n = Math.sin(seed + x * 12.9898 + y * 78.233) * 43758.5453;
  return n - Math.floor(n);
}

function smoothNoise(x: number, y: number, seed: number): number {
  const ix = Math.floor(x), iy = Math.floor(y);
  const fx = x - ix, fy = y - iy;
  const sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy);
  const n00 = noise2D(ix, iy, seed), n10 = noise2D(ix + 1, iy, seed);
  const n01 = noise2D(ix, iy + 1, seed), n11 = noise2D(ix + 1, iy + 1, seed);
  return (n00 * (1 - sx) + n10 * sx) * (1 - sy) + (n01 * (1 - sx) + n11 * sx) * sy;
}
// Note: This is interpolated hash noise, not true Perlin/Simplex. For production, use the `simplex-noise` npm package.

export function GenerativeBackground({
  seed = 42, scale = 0.008, speed = 0.5,
  colorA = "#6366f1", colorB = "#ec4899", className,
}: {
  seed?: number; scale?: number; speed?: number;
  colorA?: string; colorB?: string; className?: string;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rafRef = useRef<number>(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const dpr = window.devicePixelRatio || 1;
    let time = 0;

    function resize() {
      if (!canvas) return;
      const rect = canvas.getBoundingClientRect();
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
    }
    const observer = new ResizeObserver(resize);
    observer.observe(canvas);
    resize();

    function hexToRgb(hex: string) {
      const v = parseInt(hex.slice(1), 16);
      return [(v >> 16) & 255, (v >> 8) & 255, v & 255] as const;
    }
    const rgbA = hexToRgb(colorA), rgbB = hexToRgb(colorB);

    function tick() {
      if (!canvas || !ctx) return;
      const w = canvas.width, h = canvas.height;
      const imageData = ctx.createImageData(w, h);
      const data = imageData.data;
      const step = 4; // sample every 4th pixel for perf

      for (let y = 0; y < h; y += step) {
        for (let x = 0; x < w; x += step) {
          const n = smoothNoise(x * scale, y * scale + time, seed);
          const r = Math.floor(rgbA[0] + (rgbB[0] - rgbA[0]) * n);
          const g = Math.floor(rgbA[1] + (rgbB[1] - rgbA[1]) * n);
          const b = Math.floor(rgbA[2] + (rgbB[2] - rgbA[2]) * n);
          for (let dy = 0; dy < step && y + dy < h; dy++) {
            for (let dx = 0; dx < step && x + dx < w; dx++) {
              const idx = ((y + dy) * w + (x + dx)) * 4;
              data[idx] = r; data[idx + 1] = g; data[idx + 2] = b; data[idx + 3] = 255;
            }
          }
        }
      }
      ctx.putImageData(imageData, 0, 0);
      time += speed * 0.01;
      rafRef.current = requestAnimationFrame(tick);
    }

    const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (prefersReduced) { tick(); cancelAnimationFrame(rafRef.current); }
    else { rafRef.current = requestAnimationFrame(tick); }

    return () => { cancelAnimationFrame(rafRef.current); observer.disconnect(); };
  }, [seed, scale, speed, colorA, colorB]);

  return (
    <canvas ref={canvasRef}
      className={className ?? "absolute inset-0 h-full w-full"} aria-hidden="true" />
  );
}
```

### 7. Animated SVG Gradients

#### SMIL-animated gradient (no JS)

```tsx
export function AnimatedGradientBg({ className }: { className?: string }) {
  return (
    <svg className={className ?? "absolute inset-0 h-full w-full"}
      preserveAspectRatio="none" aria-hidden="true">
      <defs>
        <linearGradient id="animated-grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#6366f1">
            <animate attributeName="stop-color" values="#6366f1;#ec4899;#6366f1"
              dur="6s" repeatCount="indefinite" />
          </stop>
          <stop offset="50%" stopColor="#8b5cf6">
            <animate attributeName="stop-color" values="#8b5cf6;#06b6d4;#8b5cf6"
              dur="6s" repeatCount="indefinite" />
            <animate attributeName="offset" values="0.3;0.7;0.3"
              dur="8s" repeatCount="indefinite" />
          </stop>
          <stop offset="100%" stopColor="#ec4899">
            <animate attributeName="stop-color" values="#ec4899;#6366f1;#ec4899"
              dur="6s" repeatCount="indefinite" />
          </stop>
        </linearGradient>
      </defs>
      <rect width="100%" height="100%" fill="url(#animated-grad)" />
    </svg>
  );
}
```

#### Mesh gradient (overlapping radial gradients with Motion)

```tsx
"use client";

import { motion } from "motion/react";

const defaultOrbs = [
  { cx: "30%", cy: "30%", r: "50%", color: "#6366f1" },
  { cx: "70%", cy: "20%", r: "45%", color: "#ec4899" },
  { cx: "50%", cy: "70%", r: "55%", color: "#06b6d4" },
  { cx: "20%", cy: "60%", r: "40%", color: "#8b5cf6" },
];

export function MeshGradient({
  orbs = defaultOrbs, className,
}: {
  orbs?: { cx: string; cy: string; r: string; color: string }[];
  className?: string;
}) {
  return (
    <div className={className ?? "absolute inset-0 overflow-hidden"} aria-hidden="true">
      <svg className="h-full w-full" preserveAspectRatio="none">
        <defs>
          {orbs.map((orb, i) => (
            <radialGradient key={i} id={`mesh-orb-${i}`} cx={orb.cx} cy={orb.cy} r={orb.r}>
              <stop offset="0%" stopColor={orb.color} stopOpacity={0.8} />
              <stop offset="100%" stopColor={orb.color} stopOpacity={0} />
            </radialGradient>
          ))}
        </defs>
        {orbs.map((_, i) => (
          <motion.rect key={i} width="100%" height="100%" fill={`url(#mesh-orb-${i})`}
            animate={{ x: [0, 20, -10, 0], y: [0, -15, 10, 0] }}
            transition={{ duration: 10 + i * 2, repeat: Infinity, ease: "easeInOut" }}
          />
        ))}
      </svg>
    </div>
  );
}
```

## Anti-pattern

### WRONG: SVG filters on many elements

```tsx
// BAD: filter per list item tanks perf — GPU compositing per element
{items.map((item) => (
  <div key={item.id} style={{ filter: "url(#glow)" }}>{item.name}</div>
))}
// FIX: apply filter to a single container or limit to 1-2 hero elements
```

### WRONG: Canvas without RAF cleanup

```tsx
// BAD: RAF keeps running after unmount (memory leak)
useEffect(() => {
  function loop() { draw(); requestAnimationFrame(loop); }
  requestAnimationFrame(loop);
}, []);
// FIX: store RAF id in useRef, cancelAnimationFrame in cleanup
```

### WRONG: Inline SVG filters duplicated per instance

```tsx
// BAD: each GlowCard creates its own <filter id="glow"> — N duplicates
function GlowCard() {
  return <svg><defs><filter id="glow">...</filter></defs></svg>;
}
// FIX: render <SVGFilters /> once in layout, reference by url(#id)
```

### WRONG: Canvas particles without object pooling

```tsx
// BAD: new Particle() every frame causes GC pauses
function tick() {
  particles = particles.filter((p) => p.life > 0);
  while (particles.length < MAX) particles.push(new Particle());
}
// FIX: pre-allocate fixed pool, reset dead particles in place
```

## Common Mistakes

1. **Not cleaning up RAF on unmount** — store id in `useRef`, call `cancelAnimationFrame` in cleanup.
2. **SVG filters on too many elements** — triggers GPU compositing per element. Limit to 1-3 hero elements.
3. **Canvas ignoring devicePixelRatio** — blurry on retina. Multiply canvas dimensions by `dpr`.
4. **Missing `will-change: filter`** — add on filtered elements, remove after animation to free GPU memory.
5. **No `preserveAspectRatio` on responsive SVGs** — use `xMidYMid meet` (contain) or `slice` (cover).
6. **Not pooling particles** — pre-allocate fixed array, reset in place instead of create/destroy.
7. **Morphing incompatible paths** — use Flubber `maxSegmentLength` to normalize point counts.
8. **Forgetting `prefers-reduced-motion`** — check `matchMedia`, stop or render single static frame.

## Checklist

- [ ] All canvas RAF loops cleaned up on unmount
- [ ] Canvas accounts for `devicePixelRatio` (sharp on retina)
- [ ] SVG filters in shared `<defs>`, not duplicated per element
- [ ] Particle systems use object pooling (no per-frame allocation)
- [ ] `prefers-reduced-motion` disables continuous animations
- [ ] Canvas resize handled via `ResizeObserver`
- [ ] SVG `viewBox` set for responsive scaling
- [ ] All components marked `"use client"`
- [ ] SVG `preserveAspectRatio` set on responsive containers
- [ ] `will-change: filter` added (and removed after animation)
- [ ] `aria-hidden="true"` on decorative SVG/canvas elements
- [ ] Flubber `maxSegmentLength` configured for smooth morphs

## Advanced Patterns

### Mouse-reactive particle physics

Particles with attraction/repulsion forces that respond to cursor position — the signature Awwwards interactive background.

```tsx
"use client";

import { useRef, useEffect, useCallback } from "react";

type PhysicsParticle = {
  x: number; y: number; ox: number; oy: number;
  vx: number; vy: number; size: number; color: string;
};

export function InteractiveParticles({
  count = 200,
  colors = ["#6366f1", "#8b5cf6", "#a78bfa"],
  attractForce = 0.02,
  returnForce = 0.05,
  friction = 0.92,
  interactionRadius = 150,
  className,
}: {
  count?: number;
  colors?: string[];
  attractForce?: number;
  returnForce?: number;
  friction?: number;
  interactionRadius?: number;
  className?: string;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const mouseRef = useRef({ x: -1000, y: -1000, active: false });

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const dpr = window.devicePixelRatio || 1;

    function resize() {
      if (!canvas) return;
      const rect = canvas.getBoundingClientRect();
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
    }
    const observer = new ResizeObserver(resize);
    observer.observe(canvas);
    resize();

    // Initialize particles at random positions
    const particles: PhysicsParticle[] = Array.from({ length: count }, () => {
      const x = Math.random() * canvas.width;
      const y = Math.random() * canvas.height;
      return {
        x, y, ox: x, oy: y,
        vx: 0, vy: 0,
        size: 1 + Math.random() * 2.5,
        color: colors[Math.floor(Math.random() * colors.length)],
      };
    });

    function tick() {
      if (!canvas || !ctx) return;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const { x: mx, y: my, active } = mouseRef.current;

      for (const p of particles) {
        if (active) {
          const dx = mx * dpr - p.x;
          const dy = my * dpr - p.y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < interactionRadius * dpr) {
            // Repel from cursor
            const force = (1 - dist / (interactionRadius * dpr)) * attractForce;
            p.vx -= (dx / dist) * force * 10;
            p.vy -= (dy / dist) * force * 10;
          }
        }

        // Return to origin
        p.vx += (p.ox - p.x) * returnForce;
        p.vy += (p.oy - p.y) * returnForce;
        p.vx *= friction;
        p.vy *= friction;
        p.x += p.vx;
        p.y += p.vy;

        ctx.globalAlpha = 0.8;
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x / dpr, p.y / dpr, p.size, 0, Math.PI * 2);
        ctx.fill();
      }

      // Draw connections between nearby particles
      ctx.globalAlpha = 0.1;
      ctx.strokeStyle = colors[0];
      ctx.lineWidth = 0.5;
      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 80 * dpr) {
            ctx.beginPath();
            ctx.moveTo(particles[i].x / dpr, particles[i].y / dpr);
            ctx.lineTo(particles[j].x / dpr, particles[j].y / dpr);
            ctx.stroke();
          }
        }
      }

      ctx.globalAlpha = 1;
      requestAnimationFrame(tick);
    }

    function onMove(e: MouseEvent) {
      const rect = canvas!.getBoundingClientRect();
      mouseRef.current = { x: e.clientX - rect.left, y: e.clientY - rect.top, active: true };
    }
    function onLeave() { mouseRef.current.active = false; }

    canvas.addEventListener("mousemove", onMove);
    canvas.addEventListener("mouseleave", onLeave);
    const raf = requestAnimationFrame(tick);

    return () => {
      cancelAnimationFrame(raf);
      observer.disconnect();
      canvas.removeEventListener("mousemove", onMove);
      canvas.removeEventListener("mouseleave", onLeave);
    };
  }, [count, colors, attractForce, returnForce, friction, interactionRadius]);

  return (
    <canvas
      ref={canvasRef}
      className={className ?? "absolute inset-0 h-full w-full"}
      aria-hidden="true"
    />
  );
}
```

### Canvas image pixel effect (RGB shift on hover)

Read image pixels and displace them on cursor proximity — a premium image reveal effect.

```tsx
"use client";

import { useRef, useEffect } from "react";

export function PixelDistortImage({
  src,
  width,
  height,
  distortRadius = 80,
  distortStrength = 15,
  className,
}: {
  src: string;
  width: number;
  height: number;
  distortRadius?: number;
  distortStrength?: number;
  className?: string;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const mouseRef = useRef({ x: -1000, y: -1000 });
  const imageDataRef = useRef<ImageData | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    canvas.width = width;
    canvas.height = height;

    const img = new Image();
    img.crossOrigin = "anonymous";
    img.onload = () => {
      ctx.drawImage(img, 0, 0, width, height);
      imageDataRef.current = ctx.getImageData(0, 0, width, height);
    };
    img.src = src;

    function onMove(e: MouseEvent) {
      const rect = canvas!.getBoundingClientRect();
      mouseRef.current = {
        x: (e.clientX - rect.left) * (width / rect.width),
        y: (e.clientY - rect.top) * (height / rect.height),
      };
    }

    function tick() {
      if (!ctx || !canvas || !imageDataRef.current) {
        requestAnimationFrame(tick);
        return;
      }
      const original = imageDataRef.current;
      const output = ctx.createImageData(width, height);
      const { x: mx, y: my } = mouseRef.current;

      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const idx = (y * width + x) * 4;
          const dx = x - mx;
          const dy = y - my;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < distortRadius) {
            const force = (1 - dist / distortRadius) * distortStrength;
            // RGB channel separation
            const rIdx = (y * width + Math.min(width - 1, Math.max(0, Math.round(x + force)))) * 4;
            const bIdx = (y * width + Math.min(width - 1, Math.max(0, Math.round(x - force)))) * 4;
            output.data[idx] = original.data[rIdx];       // R shifted right
            output.data[idx + 1] = original.data[idx + 1]; // G stays
            output.data[idx + 2] = original.data[bIdx + 2]; // B shifted left
            output.data[idx + 3] = 255;
          } else {
            output.data[idx] = original.data[idx];
            output.data[idx + 1] = original.data[idx + 1];
            output.data[idx + 2] = original.data[idx + 2];
            output.data[idx + 3] = original.data[idx + 3];
          }
        }
      }
      ctx.putImageData(output, 0, 0);
      requestAnimationFrame(tick);
    }

    canvas.addEventListener("mousemove", onMove);
    requestAnimationFrame(tick);

    return () => { canvas.removeEventListener("mousemove", onMove); };
  }, [src, width, height, distortRadius, distortStrength]);

  return <canvas ref={canvasRef} className={className} aria-hidden="true" />;
}
```

### Animated SVG clip-path reveal

Content revealed through an animated SVG clip-path — a premium scroll-triggered effect.

```tsx
"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function ClipPathReveal({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "center center"],
  });

  const clipProgress = useTransform(scrollYProgress, [0, 1], [0, 100]);

  return (
    <div ref={ref} className={className}>
      <motion.div
        style={{
          clipPath: useTransform(clipProgress, (v) =>
            `circle(${v}% at 50% 50%)`
          ),
        }}
      >
        {children}
      </motion.div>
    </div>
  );
}

// Alternatively: horizontal wipe
export function WipeReveal({ children }: { children: React.ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "center center"],
  });

  return (
    <div ref={ref}>
      <motion.div
        style={{
          clipPath: useTransform(scrollYProgress, [0, 1], [
            "inset(0 100% 0 0)",
            "inset(0 0% 0 0)",
          ]),
        }}
      >
        {children}
      </motion.div>
    </div>
  );
}
```

## Composes With

- `animation` -- coordinating SVG/Canvas with Motion animations
- `visual-design` -- gradients and visual effects
- `webgl-3d` -- when 2D is not enough, upgrade path to 3D
- `loading-transitions` -- SVG-based loading animations
- `creative-scrolling` -- scroll-linked SVG path drawing
- `landing-patterns` -- hero section visual effects
- `dark-mode` -- CSS variable colors work across SVG and Canvas
- `performance` -- profiling canvas render loops and SVG filter cost
- `cursor-effects` -- mouse-reactive particle systems and image distortion
