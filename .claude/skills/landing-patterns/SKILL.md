---
name: landing-patterns
description: >
  Conversion-optimized landing page patterns — hero sections, bento grids, pricing tables, social proof, CTA sections, feature showcases
allowed-tools: Read, Grep, Glob
---

# Landing Patterns

## Purpose
Conversion-optimized landing page layouts that create wow factor. Covers hero sections, bento grids,
pricing tables, social proof, CTA sections, and feature showcases with full TSX examples. The ONE
skill for marketing page patterns.

## When to Use
- Building a landing page or marketing homepage
- Creating hero sections (centered, split, or visual-heavy)
- Adding pricing tables with tier comparison
- Building feature showcase sections
- Adding social proof (testimonials, logo clouds)
- Creating CTA sections

## When NOT to Use
- Visual design tokens (colors, shadows, spacing) → `visual-design`
- Animation and microinteractions → `animation`
- Component library primitives → `shadcn`
- SEO metadata → `seo-advanced`
- Responsive breakpoints → `responsive-design`

## Pattern

### 1. Centered Hero (Vercel/Linear style)

```tsx
import { Button } from "@/components/ui/button";

export function CenteredHero() {
  return (
    <section className="relative overflow-hidden">
      {/* Mesh gradient background */}
      <div
        className="absolute inset-0 -z-10"
        style={{
          background: `
            radial-gradient(ellipse 80% 50% at 50% -20%, oklch(0.55 0.22 270 / 0.3), transparent),
            radial-gradient(ellipse 60% 40% at 80% 50%, oklch(0.55 0.20 150 / 0.15), transparent),
            radial-gradient(ellipse 50% 60% at 20% 80%, oklch(0.60 0.18 270 / 0.1), transparent)
          `,
        }}
      />

      <div className="mx-auto max-w-4xl px-6 py-24 text-center md:py-32">
        {/* Pill badge */}
        <div className="mb-6 inline-flex items-center gap-2 rounded-full border bg-muted/50 px-4 py-1.5 text-sm">
          <span className="h-2 w-2 animate-pulse rounded-full bg-brand-500" />
          Now in public beta
        </div>

        {/* Heading with gradient keyword */}
        <h1 className="text-balance text-4xl font-extrabold tracking-tight sm:text-5xl md:text-6xl">
          Build faster with{" "}
          <span className="bg-gradient-to-r from-brand-400 to-accent-400 bg-clip-text text-transparent">
            intelligence
          </span>
        </h1>

        {/* Description */}
        <p className="mx-auto mt-6 max-w-2xl text-lg text-muted-foreground">
          Ship production-ready features in minutes, not days. Designed for teams
          that move fast and build with confidence.
        </p>

        {/* Dual CTAs */}
        <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
          <Button size="lg" className="bg-gradient-to-r from-brand-500 to-brand-600 shadow-lg shadow-brand-500/25">
            Get started free
          </Button>
          <Button size="lg" variant="ghost">
            See how it works &rarr;
          </Button>
        </div>

        {/* Social proof strip */}
        <div className="mt-16">
          <p className="mb-4 text-sm text-muted-foreground">Trusted by teams at</p>
          <div className="flex flex-wrap items-center justify-center gap-x-8 gap-y-4 opacity-60 grayscale">
            {/* Replace with actual logos */}
            {["Vercel", "Stripe", "Linear", "Notion", "Figma"].map((name) => (
              <span key={name} className="text-sm font-semibold tracking-wide">{name}</span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
```

### 2. Split Hero (SaaS style)

```tsx
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export function SplitHero() {
  return (
    <section className="px-6 py-24 md:py-32">
      <div className="mx-auto grid max-w-7xl items-center gap-12 lg:grid-cols-2">
        {/* Left — copy */}
        <div>
          <div className="mb-4 inline-flex items-center gap-2 rounded-full border bg-accent-50 px-3 py-1 text-sm font-medium text-accent-600 dark:bg-accent-950 dark:text-accent-400">
            New: AI-powered workflows
          </div>

          <h1 className="text-balance text-4xl font-extrabold tracking-tight sm:text-5xl">
            Your team's command center for shipping
          </h1>

          <p className="mt-6 max-w-lg text-lg text-muted-foreground">
            Plan, build, and ship software faster with an integrated platform
            designed for modern development teams.
          </p>

          {/* Email capture */}
          <form className="mt-8 flex max-w-md gap-3">
            <Input type="email" placeholder="Enter your email" className="flex-1" />
            <Button type="submit">Get started</Button>
          </form>

          <p className="mt-3 text-sm text-muted-foreground">
            Free for teams up to 5. No credit card required.
          </p>
        </div>

        {/* Right — screenshot */}
        <div className="relative">
          <div className="rounded-2xl border bg-white/5 p-2 shadow-2xl shadow-brand-500/10 backdrop-blur-sm rotate-1">
            <div className="aspect-[4/3] rounded-xl bg-gradient-to-br from-brand-100 to-accent-100 dark:from-brand-950 dark:to-accent-950" />
          </div>

          {/* Floating decoration */}
          <div className="absolute -bottom-4 -left-4 rounded-xl border bg-card p-3 shadow-lg animate-in slide-in-from-bottom-2">
            <div className="flex items-center gap-2 text-sm">
              <span className="h-2 w-2 rounded-full bg-green-500" />
              <span className="font-medium">Deployed to production</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
```

### 3. Bento Grid (Apple style)

```tsx
import { Zap, Shield, Globe, BarChart3, Layers, Lock } from "lucide-react";

const features = [
  {
    icon: Zap,
    title: "Lightning fast",
    description: "Edge-first architecture delivers sub-100ms responses worldwide.",
    span: "md:col-span-2",
    featured: true,
  },
  {
    icon: Shield,
    title: "Enterprise security",
    description: "SOC 2 compliant with end-to-end encryption.",
  },
  {
    icon: Globe,
    title: "Global CDN",
    description: "Automatically cached at 300+ edge locations.",
  },
  {
    icon: BarChart3,
    title: "Real-time analytics",
    description: "Monitor performance metrics as they happen.",
  },
  {
    icon: Layers,
    title: "Composable APIs",
    description: "Mix and match building blocks for any workflow.",
    span: "md:col-span-2",
  },
  {
    icon: Lock,
    title: "Access control",
    description: "Fine-grained permissions and team roles.",
  },
];

export function BentoGrid() {
  return (
    <section className="px-6 py-16 md:py-24">
      <div className="mx-auto max-w-7xl">
        <div className="mx-auto mb-12 max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Everything you need to ship
          </h2>
          <p className="mt-4 text-lg text-muted-foreground">
            A complete platform with all the features your team needs.
          </p>
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div
              key={feature.title}
              className={`group rounded-2xl border p-6 transition-all hover:border-brand-500/20 hover:shadow-lg ${
                feature.span ?? ""
              } ${
                feature.featured
                  ? "bg-gradient-to-br from-brand-50 to-accent-50 dark:from-brand-950/50 dark:to-accent-950/50"
                  : "bg-card"
              }`}
            >
              <div className="mb-4 inline-flex rounded-xl bg-brand-500/10 p-3">
                <feature.icon className="h-6 w-6 text-brand-500" />
              </div>
              <h3 className="text-lg font-semibold">{feature.title}</h3>
              <p className="mt-2 text-muted-foreground">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

### 4. Feature Showcase with Icons

```tsx
import { Sparkles, Gauge, Puzzle } from "lucide-react";

const features = [
  {
    icon: Sparkles,
    title: "AI-Powered",
    description: "Intelligent suggestions that learn from your team's patterns and preferences.",
  },
  {
    icon: Gauge,
    title: "Real-time Performance",
    description: "Monitor Core Web Vitals and performance metrics with zero configuration.",
  },
  {
    icon: Puzzle,
    title: "Extensible Platform",
    description: "Build custom integrations with our SDK and webhook system.",
  },
];

export function FeatureShowcase() {
  return (
    <section className="px-6 py-16 md:py-24">
      <div className="mx-auto max-w-7xl">
        <div className="grid gap-8 md:grid-cols-3">
          {features.map((feature) => (
            <div key={feature.title} className="text-center md:text-left">
              <div className="mx-auto mb-4 inline-flex rounded-xl bg-brand-500/10 p-3 md:mx-0">
                <feature.icon className="h-6 w-6 text-brand-500" />
              </div>
              <h3 className="text-lg font-semibold">{feature.title}</h3>
              <p className="mt-2 text-muted-foreground">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

### 5. Social Proof Section

```tsx
import { Star } from "lucide-react";

// Logo cloud
export function LogoCloud({ logos }: { logos: { name: string; src: string }[] }) {
  return (
    <section className="px-6 py-12">
      <div className="mx-auto max-w-5xl">
        <p className="mb-8 text-center text-sm text-muted-foreground">
          Trusted by industry leaders
        </p>
        <div className="grid grid-cols-3 items-center gap-8 md:grid-cols-6">
          {logos.map((logo) => (
            <img
              key={logo.name}
              src={logo.src}
              alt={logo.name}
              className="h-8 w-auto object-contain grayscale transition-all hover:grayscale-0"
            />
          ))}
        </div>
      </div>
    </section>
  );
}

// Testimonial card
export function TestimonialCard({
  quote,
  name,
  title,
  company,
  avatarUrl,
}: {
  quote: string;
  name: string;
  title: string;
  company: string;
  avatarUrl: string;
}) {
  return (
    <div className="rounded-2xl border bg-card p-6">
      <div className="mb-4 flex gap-1">
        {Array.from({ length: 5 }).map((_, i) => (
          <Star key={i} className="h-4 w-4 fill-amber-400 text-amber-400" />
        ))}
      </div>
      <blockquote className="text-foreground">&ldquo;{quote}&rdquo;</blockquote>
      <div className="mt-4 flex items-center gap-3">
        <img src={avatarUrl} alt={name} className="h-10 w-10 rounded-full" />
        <div>
          <p className="text-sm font-semibold">{name}</p>
          <p className="text-sm text-muted-foreground">{title}, {company}</p>
        </div>
      </div>
    </div>
  );
}
```

### 6. Pricing Table (3-tier)

```tsx
import { Check, X } from "lucide-react";
import { Button } from "@/components/ui/button";

const tiers = [
  {
    name: "Starter",
    price: "$0",
    description: "For individuals and small projects.",
    features: [
      { text: "Up to 3 projects", included: true },
      { text: "Basic analytics", included: true },
      { text: "Community support", included: true },
      { text: "Custom domains", included: false },
      { text: "Team collaboration", included: false },
    ],
    cta: "Get started",
    highlighted: false,
  },
  {
    name: "Pro",
    price: "$29",
    period: "/month",
    description: "For growing teams that need more power.",
    features: [
      { text: "Unlimited projects", included: true },
      { text: "Advanced analytics", included: true },
      { text: "Priority support", included: true },
      { text: "Custom domains", included: true },
      { text: "Team collaboration", included: true },
    ],
    cta: "Start free trial",
    highlighted: true,
  },
  {
    name: "Enterprise",
    price: "Custom",
    description: "For organizations with advanced needs.",
    features: [
      { text: "Everything in Pro", included: true },
      { text: "SSO & SAML", included: true },
      { text: "Dedicated support", included: true },
      { text: "SLA guarantee", included: true },
      { text: "Custom integrations", included: true },
    ],
    cta: "Contact sales",
    highlighted: false,
  },
];

export function PricingTable() {
  return (
    <section className="px-6 py-16 md:py-24">
      <div className="mx-auto max-w-7xl">
        <div className="mx-auto mb-12 max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Simple, transparent pricing
          </h2>
          <p className="mt-4 text-lg text-muted-foreground">
            Choose the plan that fits your team. Upgrade or downgrade anytime.
          </p>
        </div>

        <div className="grid gap-8 md:grid-cols-3">
          {tiers.map((tier) => (
            <div
              key={tier.name}
              className={`relative rounded-2xl border p-8 ${
                tier.highlighted
                  ? "border-brand-500 shadow-lg shadow-brand-500/10"
                  : "bg-card"
              }`}
            >
              {tier.highlighted && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-brand-500 px-3 py-1 text-xs font-semibold text-white">
                  Most Popular
                </div>
              )}

              <h3 className="text-lg font-semibold">{tier.name}</h3>
              <div className="mt-4 flex items-baseline gap-1">
                <span className="text-4xl font-bold tracking-tight">{tier.price}</span>
                {tier.period && (
                  <span className="text-muted-foreground">{tier.period}</span>
                )}
              </div>
              <p className="mt-2 text-sm text-muted-foreground">{tier.description}</p>

              <ul className="mt-8 space-y-3">
                {tier.features.map((feature) => (
                  <li key={feature.text} className="flex items-center gap-3 text-sm">
                    {feature.included ? (
                      <Check className="h-4 w-4 text-brand-500" />
                    ) : (
                      <X className="h-4 w-4 text-muted-foreground/40" />
                    )}
                    <span className={feature.included ? "" : "text-muted-foreground"}>
                      {feature.text}
                    </span>
                  </li>
                ))}
              </ul>

              <Button
                className={`mt-8 w-full ${
                  tier.highlighted
                    ? "bg-gradient-to-r from-brand-500 to-brand-600 shadow-lg shadow-brand-500/25"
                    : ""
                }`}
                variant={tier.highlighted ? "default" : "outline"}
              >
                {tier.cta}
              </Button>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

### 7. CTA Section

```tsx
import { Button } from "@/components/ui/button";

export function CTASection() {
  return (
    <section className="px-6 py-16 md:py-24">
      <div className="relative mx-auto max-w-4xl overflow-hidden rounded-3xl bg-brand-600 px-8 py-16 text-center dark:bg-brand-500">
        {/* Grid pattern overlay */}
        <div
          className="absolute inset-0 opacity-10"
          style={{
            backgroundImage:
              "linear-gradient(to right, white 1px, transparent 1px), linear-gradient(to bottom, white 1px, transparent 1px)",
            backgroundSize: "40px 40px",
          }}
        />

        <div className="relative">
          <h2 className="text-balance text-3xl font-bold tracking-tight text-white sm:text-4xl">
            Ready to ship faster?
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-lg text-white/80">
            Join thousands of developers building better software with our platform.
          </p>

          <div className="mt-8 flex flex-col items-center justify-center gap-4 sm:flex-row">
            <Button size="lg" className="bg-white text-brand-600 shadow-lg hover:bg-white/90">
              Start building free
            </Button>
            <Button
              size="lg"
              variant="ghost"
              className="text-white hover:bg-white/10 hover:text-white"
            >
              Talk to sales &rarr;
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
```

## Anti-pattern

```tsx
// WRONG: hero without CTA
<section>
  <h1>Welcome to our product</h1>
  <p>Description text...</p>
  {/* No button — users don't know what to do */}
</section>

// WRONG: pricing without highlighted tier
<div className="grid grid-cols-3">
  {tiers.map((tier) => (
    <div className="border p-6">{/* All look the same */}</div>
  ))}
</div>
// Always highlight the recommended tier

// WRONG: testimonials without faces/names
<blockquote>"Great product!"</blockquote>
// Include avatar, name, title, company

// WRONG: CTA section same visual weight as content
<section className="py-8 bg-background">
  <h2>Get started</h2>
</section>
// CTA needs contrast: different background, more padding, larger text

// WRONG: hero without social proof
<section>
  <h1>Title</h1>
  <p>Description</p>
  <Button>CTA</Button>
  {/* No trust signals — add logo cloud or testimonials */}
</section>
```

## Common Mistakes
- Hero without any CTA — always include primary + secondary action
- Pricing tiers all look the same — highlight the recommended plan
- Testimonials without attribution — include face, name, title, company
- CTA sections that blend into content — use contrasting background
- Feature grids without icons — visual anchors improve scanability
- Missing social proof — add logo cloud, testimonial, or metric
- Too many CTAs competing — one primary CTA per section

## Checklist
- [ ] Hero section has gradient/mesh background, not flat color
- [ ] Hero has pill badge or status indicator above heading
- [ ] Heading uses `text-balance` and gradient text on keyword
- [ ] Dual CTAs: primary (gradient/solid) + secondary (ghost/outline)
- [ ] Social proof present (logo cloud, testimonials, or metrics)
- [ ] Pricing table has highlighted tier with "Most Popular" badge
- [ ] Feature cards have icon containers with brand-tinted background
- [ ] CTA section has contrasting background (brand color or gradient)
- [ ] Sections spaced with `py-16 md:py-24`
- [ ] All sections centered with `max-w-7xl mx-auto`

## Advanced Patterns

### Infinite marquee / ticker

Auto-scrolling text or logos that loop infinitely — a staple of modern marketing pages.

```tsx
import { cn } from "@/lib/utils";

export function Marquee({
  children,
  speed = 30,
  reverse = false,
  className,
}: {
  children: React.ReactNode;
  speed?: number;
  reverse?: boolean;
  className?: string;
}) {
  return (
    <div className={cn("flex overflow-hidden [mask-image:linear-gradient(to_right,transparent,white_10%,white_90%,transparent)]", className)}>
      <div
        className={cn(
          "flex shrink-0 items-center gap-8",
          reverse ? "animate-[marquee_var(--duration)_linear_infinite_reverse]" : "animate-[marquee_var(--duration)_linear_infinite]"
        )}
        style={{ "--duration": `${speed}s` } as React.CSSProperties}
      >
        {children}
        {/* Duplicate for seamless loop */}
        {children}
      </div>
    </div>
  );
}

// Add to globals.css:
// @keyframes marquee { from { transform: translateX(0); } to { transform: translateX(-50%); } }

// Usage:
// <Marquee speed={25}>
//   {logos.map((logo) => <img key={logo.alt} src={logo.src} alt={logo.alt} className="h-8" />)}
// </Marquee>
```

### Interactive demo section

A draggable/interactive preview of the product embedded in the landing page.

```tsx
"use client";

import { useState } from "react";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";

export function InteractiveDemo() {
  const [activeTab, setActiveTab] = useState(0);
  const tabs = ["Dashboard", "Analytics", "Settings"];

  return (
    <section className="mx-auto max-w-5xl px-4 py-24">
      <div className="text-center">
        <h2 className="text-3xl font-bold md:text-4xl">See it in action</h2>
        <p className="mt-3 text-muted-foreground">Click around — this is a real preview.</p>
      </div>

      <div className="mt-12 overflow-hidden rounded-2xl border shadow-2xl shadow-primary/5">
        {/* Tab bar */}
        <div className="flex border-b bg-muted/30">
          {tabs.map((tab, i) => (
            <button
              key={tab}
              onClick={() => setActiveTab(i)}
              className={cn(
                "relative px-6 py-3 text-sm font-medium transition-colors",
                activeTab === i ? "text-foreground" : "text-muted-foreground hover:text-foreground"
              )}
            >
              {tab}
              {activeTab === i && (
                <motion.div
                  layoutId="demo-tab-indicator"
                  className="absolute inset-x-0 -bottom-px h-0.5 bg-primary"
                  transition={{ type: "spring", stiffness: 400, damping: 30 }}
                />
              )}
            </button>
          ))}
        </div>

        {/* Demo content */}
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
          className="aspect-video bg-background p-8"
        >
          <div className="grid h-full grid-cols-3 gap-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="rounded-lg bg-muted animate-pulse" style={{ animationDelay: `${i * 100}ms` }} />
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
```

### Video hero with gradient overlay

Background video with blend mode and gradient overlay for a cinematic hero.

```tsx
export function VideoHero({
  videoSrc,
  children,
}: {
  videoSrc: string;
  children: React.ReactNode;
}) {
  return (
    <section className="relative flex min-h-screen items-center justify-center overflow-hidden">
      <video
        autoPlay
        muted
        loop
        playsInline
        className="absolute inset-0 h-full w-full object-cover"
      >
        <source src={videoSrc} type="video/mp4" />
      </video>

      {/* Gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-background via-background/60 to-background/20" />

      {/* Content */}
      <div className="relative z-10 mx-auto max-w-4xl px-4 text-center">
        {children}
      </div>
    </section>
  );
}
```

### Scroll-triggered section reveals

Every section fades in and slides up as it enters the viewport.

```tsx
"use client";

import { motion, useInView } from "motion/react";
import { useRef } from "react";

export function RevealOnScroll({
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
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 40 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{
        delay,
        duration: 0.6,
        ease: [0.21, 0.47, 0.32, 0.98],
      }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

// Usage: wrap every landing section
// <RevealOnScroll><HeroSection /></RevealOnScroll>
// <RevealOnScroll delay={0.1}><FeaturesGrid /></RevealOnScroll>
// <RevealOnScroll delay={0.2}><PricingTable /></RevealOnScroll>
```

## Composes With
- `visual-design` — color system, elevation, gradients used in all patterns
- `animation` — scroll-triggered reveals, stagger entry, hover effects
- `responsive-design` — mobile-first grid layouts
- `shadcn` — Button, Input, Card components used in patterns
- `seo-advanced` — structured data and metadata for marketing pages
- `creative-scrolling` — scroll-driven reveals and parallax for landing sections
- `advanced-typography` — hero headings with kinetic text and variable fonts
- `cursor-effects` — premium cursor interactions on marketing pages
- `sound-design` — ambient audio and interaction sounds for immersive landings
