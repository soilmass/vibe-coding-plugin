---
name: visual-design
description: >
  Color harmony, elevation systems, gradients, glassmorphism, visual hierarchy, spacing rhythm, surface depth — concrete design tokens and patterns for premium aesthetics
allowed-tools: Read, Grep, Glob
---

# Visual Design

## Purpose
Foundational visual design system for premium aesthetics. Covers color harmony, elevation, gradients,
glassmorphism, visual hierarchy, spacing rhythm, border radius, and surface depth. All concrete values,
no vague advice. The ONE skill for making websites look stunning.

## When to Use
- Establishing a color system with brand + accent + gray scales
- Setting up an elevation/shadow system
- Adding gradients, glassmorphism, or premium surface effects
- Fixing inconsistent spacing, radius, or visual hierarchy
- Making a site look polished, premium, or beautiful
- Reviewing visual design quality

## When NOT to Use
- Theme switching (light/dark toggle) → `dark-mode`
- Component library setup → `shadcn`
- Landing page layout patterns → `landing-patterns`
- Motion and animation → `animation`
- Responsive breakpoints → `responsive-design`

## Pattern

### 1. Color System — oklch 9-step scales

Generate a complete brand color scale from a single oklch hue. Define all colors in `@theme {}` — never hardcode classes.

```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  /* Brand scale — pick ONE hue (e.g., 270 = indigo) */
  --color-brand-50:  oklch(0.97 0.02 270);
  --color-brand-100: oklch(0.93 0.04 270);
  --color-brand-200: oklch(0.86 0.08 270);
  --color-brand-300: oklch(0.76 0.12 270);
  --color-brand-400: oklch(0.66 0.18 270);
  --color-brand-500: oklch(0.55 0.22 270);
  --color-brand-600: oklch(0.47 0.20 270);
  --color-brand-700: oklch(0.39 0.17 270);
  --color-brand-800: oklch(0.31 0.13 270);
  --color-brand-900: oklch(0.24 0.09 270);
  --color-brand-950: oklch(0.17 0.06 270);

  /* Accent — complementary (+180°) or analogous (±60°/±120°) */
  --color-accent-50:  oklch(0.97 0.02 150);
  --color-accent-100: oklch(0.93 0.04 150);
  --color-accent-200: oklch(0.86 0.08 150);
  --color-accent-300: oklch(0.76 0.12 150);
  --color-accent-400: oklch(0.66 0.16 150);
  --color-accent-500: oklch(0.55 0.20 150);
  --color-accent-600: oklch(0.47 0.17 150);
  --color-accent-700: oklch(0.39 0.14 150);
  --color-accent-800: oklch(0.31 0.10 150);
  --color-accent-900: oklch(0.24 0.07 150);
  --color-accent-950: oklch(0.17 0.04 150);

  /* Gray with subtle brand tint (chroma 0.01–0.02) */
  --color-gray-50:  oklch(0.98 0.01 270);
  --color-gray-100: oklch(0.96 0.01 270);
  --color-gray-200: oklch(0.90 0.01 270);
  --color-gray-300: oklch(0.83 0.01 270);
  --color-gray-400: oklch(0.70 0.01 270);
  --color-gray-500: oklch(0.55 0.01 270);
  --color-gray-600: oklch(0.44 0.01 270);
  --color-gray-700: oklch(0.37 0.02 270);
  --color-gray-800: oklch(0.27 0.02 270);
  --color-gray-900: oklch(0.20 0.02 270);
  --color-gray-950: oklch(0.13 0.02 270);
}
```

**Rules:**
- 60-30-10 rule: 60% neutral (gray scale), 30% brand, 10% accent
- Maximum 3 hues: brand + accent + gray (brand-tinted)
- Every color via `@theme {}` — never `bg-[#hex]` or `text-[rgb()]`
- Dark mode: same hues, flip lightness (50↔950, 100↔900, 200↔800, etc.)
- Accent choice: complementary (hue + 180°) for contrast, analogous (hue ± 60°) for harmony

### 2. Elevation System — 6-level shadows

```css
@theme {
  --shadow-xs:  0 1px 2px oklch(0 0 0 / 0.05);
  --shadow-sm:  0 1px 3px oklch(0 0 0 / 0.10), 0 1px 2px oklch(0 0 0 / 0.06);
  --shadow-md:  0 4px 6px oklch(0 0 0 / 0.10), 0 2px 4px oklch(0 0 0 / 0.06);
  --shadow-lg:  0 10px 15px oklch(0 0 0 / 0.10), 0 4px 6px oklch(0 0 0 / 0.05);
  --shadow-xl:  0 20px 25px oklch(0 0 0 / 0.10), 0 8px 10px oklch(0 0 0 / 0.04);
  --shadow-2xl: 0 25px 50px oklch(0 0 0 / 0.25);
}
```

**Rules:**
- Higher importance = higher elevation: page (none) → card (sm) → popover (lg) → dialog (xl) → toast (2xl)
- Colored shadows for brand elements: `shadow-[0_4px_14px_oklch(0.55_0.20_270_/_0.40)]`
- Dark mode: double shadow opacity OR replace with `border` + subtle glow
- Hover: increase one level (`shadow-sm` → `hover:shadow-md`)
- Active/pressed: decrease (`shadow-sm` → `active:shadow-xs`)

### 3. Gradient Patterns

```tsx
// Subtle background — 2-stop linear, 5% opacity shift
<div className="bg-gradient-to-b from-brand-50/50 to-background" />

// Hero mesh gradient — 3+ radial-gradient layers
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

// Gradient text
<h1 className="bg-gradient-to-r from-brand-400 to-accent-400 bg-clip-text text-transparent">
  Gradient Heading
</h1>

// Gradient border — wrapper technique
<div className="rounded-2xl bg-gradient-to-r from-brand-500 to-accent-500 p-px">
  <div className="rounded-[calc(1rem-1px)] bg-background p-6">
    Content with gradient border
  </div>
</div>

// Animated gradient
<div className="animate-gradient bg-gradient-to-r from-brand-500 via-accent-500 to-brand-500 bg-[length:200%_auto]" />
```

```css
/* globals.css */
@keyframes gradient {
  0% { background-position: 0% center; }
  100% { background-position: 200% center; }
}

@utility animate-gradient {
  animation: gradient 3s linear infinite;
}
```

**Rules:**
- Use oklch for smooth perceptual transitions (no muddy midpoints)
- Gradient text must have fallback color for older browsers
- Mesh gradients: 3+ radial-gradient layers at different positions/sizes
- Animated gradients: `background-size: 200%` + shift `background-position`

### 4. Glassmorphism

```tsx
// Glass card — dark mode
<div className="rounded-2xl border border-white/10 bg-white/5 p-6 shadow-xl backdrop-blur-xl">
  Glass card content
</div>

// Glass card — light mode
<div className="rounded-2xl border border-white/20 bg-white/80 p-6 shadow-xl backdrop-blur-xl">
  Glass card content
</div>

// Adaptive glass (both modes)
<div className="rounded-2xl border border-white/20 bg-white/80 p-6 shadow-xl backdrop-blur-xl dark:border-white/10 dark:bg-white/5">
  Adaptive glass card
</div>
```

**Rules:**
- `backdrop-blur-xl` (24px) + semi-transparent bg (white/5 dark, white/80 light)
- Border at 10–20% opacity for frosted edge
- Works best over gradient or image backgrounds
- Never use on solid color backgrounds — glass needs content behind it to blur

### 5. Visual Hierarchy Rules

```
Size progression (1.25 ratio):
  h1: 3rem (48px)     — page title
  h2: 2.25rem (36px)  — section title
  h3: 1.5rem (24px)   — card title
  body: 1rem (16px)   — paragraph
  caption: 0.875rem (14px) — labels, metadata

Weight system:
  800 — headlines, hero text
  600 — subheadlines, card titles
  500 — UI labels, buttons
  400 — body text, descriptions

Color opacity:
  foreground (100%) — primary content
  foreground/60     — secondary content (descriptions)
  foreground/40     — muted content (metadata, timestamps)

Spacing between sections:
  section gap: 6rem (96px)   — between page sections
  card gap: 1.5rem (24px)    — between cards in a grid
  element gap: 0.75rem (12px)— between elements within a card
  text gap: 0.25rem (4px)    — between heading and description
```

**Rules:**
- One focal point per viewport — the largest/boldest element draws the eye first
- Only one primary CTA per viewport section
- Use `text-muted-foreground` for secondary text, not arbitrary opacity
- Headings use `tracking-tight` for display sizes (2xl+)
- Body text max width ~65ch for readability (`max-w-prose` or `max-w-2xl`)

### 6. Spacing Rhythm

```
Base unit: 4px (0.25rem)
Scale: 4, 8, 12, 16, 24, 32, 48, 64, 96, 128

Inner padding:
  p-4  (16px) — cards, compact containers
  p-6  (24px) — standard sections, dialogs
  p-8  (32px) — heroes, spacious containers

Component gaps:
  gap-2 (8px)  — tight (pill groups, icon + text)
  gap-4 (16px) — default (card grids, form fields)
  gap-6 (24px) — loose (feature sections)

Section spacing:
  py-16 md:py-24 — between page sections
  py-24 md:py-32 — hero sections
```

**Rules:**
- Never use arbitrary values (`p-[13px]`) — snap to the 4px scale
- Consistent padding within context (all cards same padding)
- Section spacing > card spacing > element spacing > text spacing
- Use `space-y-*` or `gap-*`, not margin on individual elements

### 7. Border Radius Consistency

```
Scale (smallest to largest):
  rounded-sm   — buttons in tight spaces, tags
  rounded-md   — inputs, small buttons
  rounded-lg   — cards, standard containers
  rounded-xl   — modals, larger containers
  rounded-2xl  — hero cards, feature cards
  rounded-full — avatars, pills, circular buttons

Nesting rule: outer radius > inner radius
  outer: rounded-2xl + inner: rounded-xl
  outer: rounded-xl + inner: rounded-lg
  outer: rounded-lg + inner: rounded-md
```

**Rules:**
- Larger elements = larger radius
- Same-size elements in same context = same radius
- No arbitrary `rounded-[7px]` — use the scale
- Nested elements: outer radius must be larger than inner radius
- Interactive elements (buttons, inputs) typically `rounded-md` to `rounded-lg`

### 8. Surface & Depth

```tsx
// Card surface — light mode
<div className="rounded-lg border bg-card p-6 shadow-sm">Card</div>

// Card surface — dark mode (shadow replaced with border emphasis)
<div className="rounded-lg border bg-card p-6 shadow-sm dark:shadow-none dark:border-border/50">Card</div>

// Hover elevation lift
<div className="rounded-lg border bg-card p-6 shadow-sm transition-shadow hover:shadow-md">
  Hoverable card
</div>

// Active depression
<button className="shadow-sm transition-all active:shadow-xs active:translate-y-px">
  Press me
</button>

// Layered surfaces (page → card → inner)
<div className="bg-background">              {/* Layer 0: page */}
  <div className="rounded-xl bg-card p-6">   {/* Layer 1: card */}
    <div className="rounded-lg bg-muted p-4"> {/* Layer 2: inner surface */}
      Nested content
    </div>
  </div>
</div>

// Subtle noise texture for premium feel
<div className="relative">
  <div className="absolute inset-0 bg-[url('/noise.svg')] opacity-[0.02] pointer-events-none" />
  Content with subtle texture
</div>
```

**Rules:**
- Each layer slightly lighter (light mode) or slightly darker (dark mode) than parent
- Cards: `bg-card` + `shadow-sm` + `border` (light); `bg-card` + `border` (dark)
- No pure white cards on white background — always differentiate with shadow or border
- Hover: increase shadow one level
- Active/pressed: decrease shadow + `translate-y-px`

## Anti-pattern

```tsx
// WRONG: rainbow color scheme (too many hues)
<div className="bg-red-500 text-blue-300 border-green-400" />
// Max 3 hues: brand + accent + gray

// WRONG: shadows without system
<div className="shadow-[0_2px_8px_rgba(0,0,0,0.15)]" />
// Use shadow scale: shadow-xs through shadow-2xl

// WRONG: arbitrary spacing
<div className="p-[13px] mt-[7px] gap-[11px]" />
// Snap to 4px scale: p-3 mt-2 gap-3

// WRONG: same radius everywhere
<div className="rounded-lg"> {/* container */}
  <button className="rounded-lg" /> {/* same as parent */}
</div>
// Nested elements need smaller radius: outer rounded-lg → inner rounded-md

// WRONG: flat depth (no elevation differences)
<div className="bg-white">
  <div className="bg-white">Same background, no visual separation</div>
</div>
// Differentiate with shadow, border, or background shade

// WRONG: hardcoded colors
<div className="bg-[#6366f1] text-[#ffffff]" />
// Use @theme tokens: bg-brand-500 text-brand-foreground
```

## Common Mistakes
- Using pure gray without brand tint — grays should have subtle chroma matching brand hue
- Hardcoding hex/rgb colors instead of using `@theme` variables
- Same shadow on all elements regardless of importance level
- Mixing arbitrary spacing values — creates visual inconsistency
- Not adjusting shadows for dark mode — shadows become invisible on dark backgrounds
- Using glassmorphism on solid backgrounds — needs content behind to blur
- Gradients with RGB/hex causing muddy midpoints — use oklch

## Checklist
- [ ] Color scale: 9-step brand + accent + brand-tinted gray in `@theme {}`
- [ ] 60-30-10 color ratio: neutral (60%), brand (30%), accent (10%)
- [ ] Shadow scale: 6 levels (xs–2xl) with consistent elevation hierarchy
- [ ] Dark mode shadows adjusted (doubled opacity or border+glow replacement)
- [ ] No arbitrary spacing — all values snap to 4px base grid
- [ ] Border radius follows nesting rule (outer > inner)
- [ ] One focal point per viewport section
- [ ] Headings use `tracking-tight` at display sizes
- [ ] Body text max width `max-w-prose` or `max-w-2xl`
- [ ] All colors use semantic tokens or `@theme` variables, no hardcoded values

## Composes With
- `tailwind-v4` — design tokens defined in `@theme {}`
- `dark-mode` — dark mode color flips and shadow adjustments
- `shadcn` — shadcn component theming uses these tokens
- `landing-patterns` — landing page sections use these visual patterns
- `animation` — microinteractions enhance surfaces and elevation changes
