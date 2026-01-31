---
name: tailwind-v4
description: >
  Tailwind CSS v4 — CSS-first config with @theme, @import "tailwindcss", @utility directive, design tokens, Lightning CSS engine, no tailwind.config.js
allowed-tools: Read, Grep, Glob
---

# Tailwind CSS v4

## Purpose
Tailwind CSS v4 with CSS-first configuration. Covers `@theme` directive, design tokens,
custom utilities, and migration from v3 config files. The ONE skill for styling decisions.

## When to Use
- Setting up or customizing design tokens
- Creating custom utility classes
- Migrating from Tailwind v3 config file to v4 CSS-first
- Understanding new v4 syntax and features

## When NOT to Use
- Component library setup → `shadcn`
- Layout and routing → `nextjs-routing`
- Component architecture → `react-server-components`

## Pattern

### CSS-first configuration
```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  /* Colors */
  --color-brand: oklch(0.6 0.25 270);
  --color-surface: oklch(0.98 0 0);
  --color-surface-dark: oklch(0.15 0 0);

  /* Typography */
  --font-sans: "Inter", system-ui, sans-serif;
  --font-mono: "JetBrains Mono", monospace;

  /* Spacing scale extension */
  --spacing-18: 4.5rem;
  --spacing-88: 22rem;

  /* Border radius */
  --radius-lg: 0.75rem;
  --radius-md: 0.5rem;
  --radius-sm: 0.25rem;
}
```

### Custom utility with @utility
```css
@utility scrollbar-hidden {
  -ms-overflow-style: none;
  scrollbar-width: none;
  &::-webkit-scrollbar {
    display: none;
  }
}
```

### Using cn() for conditional classes
```tsx
import { cn } from "@/lib/utils";

function Button({ variant, className }: ButtonProps) {
  return (
    <button
      className={cn(
        "rounded-md px-4 py-2 font-medium",
        variant === "primary" && "bg-brand text-white",
        variant === "outline" && "border border-brand text-brand",
        className
      )}
    />
  );
}
```

### Dark mode
```css
@theme {
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.145 0 0);
}

/* Dark mode uses .dark class or media query */
.dark {
  --color-background: oklch(0.145 0 0);
  --color-foreground: oklch(0.985 0 0);
}
```

## Anti-pattern

```js
// WRONG: using tailwind.config.js (v3 pattern)
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: "#6366f1",
      },
    },
  },
  plugins: [],
};
// Tailwind v4 uses @theme{} in CSS — no config file needed
```

Tailwind v4 replaces JavaScript config files with CSS-first `@theme {}` blocks.

## Common Mistakes
- Creating `tailwind.config.js` — v4 uses CSS `@theme {}` instead
- Using `@tailwind base/components/utilities` — replaced by `@import "tailwindcss"`
- Using hex colors instead of oklch — oklch provides better perceptual uniformity
- Not using `cn()` for conditional classes — leads to class conflicts
- Forgetting `@utility` for custom utilities — raw CSS breaks with purging

## Checklist
- [ ] `@import "tailwindcss"` in globals.css (not `@tailwind` directives)
- [ ] Design tokens defined in `@theme {}` block
- [ ] Custom utilities use `@utility` directive
- [ ] `cn()` used for all conditional class merging
- [ ] No `tailwind.config.js` file in project

### Container queries
```css
/* Tailwind v4 container queries — component responds to parent size */
```

```tsx
// Wrap parent with @container, use @sm/@md/@lg on children
export function ResponsiveCard({ children }: { children: React.ReactNode }) {
  return (
    <div className="@container">
      <div className="flex flex-col @sm:flex-row @md:gap-6 gap-3">
        <div className="@sm:w-1/3">Image</div>
        <div className="@sm:w-2/3">{children}</div>
      </div>
    </div>
  );
}
```

### @starting-style for CSS entry animations
```css
/* CSS-only entry animations without JavaScript */
@utility fade-in {
  animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Dialog entry animation using @starting-style */
@utility dialog-animate {
  transition: opacity 0.2s, transform 0.2s;
  @starting-style {
    opacity: 0;
    transform: scale(0.95);
  }
}
```

### @tailwindcss/typography for prose content
```css
/* Install: npm install @tailwindcss/typography */
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

```tsx
// Use prose classes for rich text / markdown / CMS content
export function Article({ html }: { html: string }) {
  return (
    <article
      className="prose dark:prose-invert max-w-2xl mx-auto"
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}

// prose modifiers
// prose-sm / prose-lg — size variants
// prose-invert — dark mode
// max-w-prose — optimal reading width (~65ch)
```

### Typography rules
```tsx
// Use real ellipsis character, not three dots
<span>Loading…</span>   // CORRECT: … (U+2026)
<span>Loading...</span>  // WRONG: three periods

// Curly quotes for displayed text
<p>"Hello," she said.</p>   // CORRECT: " " (U+201C, U+201D)
// Straight quotes are fine in code and attributes

// Non-breaking spaces for units and shortcuts
<span>10&nbsp;MB</span>     // Prevents "10" and "MB" splitting across lines
<kbd>⌘&nbsp;K</kbd>         // Keeps shortcut together

// tabular-nums for number columns — digits align vertically
<td className="font-[font-variant-numeric:tabular-nums]">1,234.56</td>
// Or use Tailwind: tabular-nums (if configured)
<td className="tabular-nums">$1,234.56</td>

// text-wrap: balance on headings (prevents widows)
<h1 className="text-balance">This Heading Will Not Have a Single Orphaned Word</h1>

// text-wrap: pretty on body paragraphs
<p className="text-pretty">Long paragraph text gets better line breaks.</p>
```

### Content handling
```tsx
// Truncation utilities
<p className="truncate">Single line that truncates with ellipsis…</p>
<p className="line-clamp-3">Multi-line text clamped to 3 lines…</p>
<p className="break-words">Longwithoutspaceswordthatbreaksinsteadofoverflowing</p>

// min-w-0 on flex children to allow text truncation/shrinking
<div className="flex gap-4">
  <div className="min-w-0 flex-1">  {/* Without min-w-0, truncate won't work */}
    <p className="truncate">{longUserGeneratedText}</p>
  </div>
  <button className="shrink-0">Action</button>
</div>

// Anticipate user-generated content lengths
// Short: empty state ("No description")
// Average: normal display
// Very long: truncate with "Show more" or line-clamp
{description.length > 200 ? (
  <ExpandableText text={description} maxLength={200} />
) : (
  <p>{description}</p>
)}
```

### Premium Design Token System

Complete `@theme` block with all visual design tokens for a polished, production-quality design system.

```css
/* app/globals.css — full premium token system */
@import "tailwindcss";

@theme {
  /* === Brand Color Scale (oklch, 9-step) === */
  /* Pick ONE hue for brand. Example: 270 (indigo) */
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

  /* === Accent Scale (complementary or analogous hue) === */
  --color-accent-400: oklch(0.66 0.16 150);
  --color-accent-500: oklch(0.55 0.20 150);
  --color-accent-600: oklch(0.47 0.17 150);

  /* === Gray with Brand Tint (chroma 0.01–0.02) === */
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

  /* === Elevation (6-level shadow scale) === */
  --shadow-xs:  0 1px 2px oklch(0 0 0 / 0.05);
  --shadow-sm:  0 1px 3px oklch(0 0 0 / 0.10), 0 1px 2px oklch(0 0 0 / 0.06);
  --shadow-md:  0 4px 6px oklch(0 0 0 / 0.10), 0 2px 4px oklch(0 0 0 / 0.06);
  --shadow-lg:  0 10px 15px oklch(0 0 0 / 0.10), 0 4px 6px oklch(0 0 0 / 0.05);
  --shadow-xl:  0 20px 25px oklch(0 0 0 / 0.10), 0 8px 10px oklch(0 0 0 / 0.04);
  --shadow-2xl: 0 25px 50px oklch(0 0 0 / 0.25);

  /* === Border Radius === */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-2xl: 1rem;
  --radius-full: 9999px;

  /* === Font Stack === */
  --font-sans: "Inter Variable", "Inter", system-ui, sans-serif;
  --font-display: "Cal Sans", "Inter Variable", system-ui, sans-serif;
  --font-mono: "JetBrains Mono", "Fira Code", monospace;

  /* === Transition Tokens === */
  --ease-spring: cubic-bezier(0.22, 1, 0.36, 1);
  --ease-bounce: cubic-bezier(0.34, 1.56, 0.64, 1);
  --duration-fast: 150ms;
  --duration-normal: 200ms;
  --duration-slow: 300ms;

  /* === Gradient Tokens === */
  --gradient-brand: linear-gradient(to right, var(--color-brand-500), var(--color-brand-600));
  --gradient-accent: linear-gradient(to right, var(--color-brand-400), var(--color-accent-400));
}
```

```css
/* Custom gradient mesh utility */
@utility gradient-mesh {
  background:
    radial-gradient(ellipse 80% 50% at 50% -20%, oklch(0.55 0.22 270 / 0.3), transparent),
    radial-gradient(ellipse 60% 40% at 80% 50%, oklch(0.55 0.20 150 / 0.15), transparent),
    radial-gradient(ellipse 50% 60% at 20% 80%, oklch(0.60 0.18 270 / 0.1), transparent);
}
```

**Rules:**
- All colors in oklch for perceptually uniform scales
- Gray scale always has subtle brand tint (chroma 0.01–0.02 at brand hue)
- Use `--font-display` for hero/marketing headings, `--font-sans` for UI
- Transition tokens ensure consistent animation feel across all components
- Gradient tokens composable via CSS custom properties

### Premium Animation & Interaction Utilities

#### Microinteraction @utility patterns
```css
/* Hover lift — card hover feedback */
@utility hover-lift {
  transition: transform 0.2s var(--ease-spring), box-shadow 0.2s;
  &:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-lg);
  }
  &:active {
    transform: translateY(0);
    box-shadow: var(--shadow-sm);
  }
}

/* Press scale — button press feedback */
@utility press-scale {
  transition: transform 0.15s var(--ease-spring);
  &:active {
    transform: scale(0.97);
  }
}

/* Focus glow — accessible focus ring with brand glow */
@utility focus-glow {
  &:focus-visible {
    outline: 2px solid var(--color-brand-500);
    outline-offset: 2px;
    box-shadow: 0 0 0 4px oklch(0.55 0.22 270 / 0.15);
  }
}
```

#### Skeleton & loading utilities
```css
/* Shimmer skeleton */
@utility skeleton {
  position: relative;
  overflow: hidden;
  background: var(--color-gray-100);
  border-radius: var(--radius-md);
  &::after {
    content: "";
    position: absolute;
    inset: 0;
    background: linear-gradient(90deg, transparent, oklch(1 0 0 / 0.4), transparent);
    animation: shimmer 1.5s infinite;
  }
}

.dark .skeleton {
  background: var(--color-gray-800);
  &::after {
    background: linear-gradient(90deg, transparent, oklch(1 0 0 / 0.05), transparent);
  }
}

@keyframes shimmer {
  from { transform: translateX(-100%); }
  to { transform: translateX(100%); }
}

/* Pulse dot (connection status, notifications) */
@utility pulse-dot {
  position: relative;
  &::before {
    content: "";
    position: absolute;
    inset: 0;
    border-radius: 9999px;
    background: inherit;
    animation: pulse-ring 2s ease-in-out infinite;
  }
}

@keyframes pulse-ring {
  0%, 100% { transform: scale(1); opacity: 0.75; }
  50% { transform: scale(1.8); opacity: 0; }
}
```

#### Entry animation utilities
```css
/* Staggered fade-in for lists */
@utility stagger-in {
  animation: fadeSlideIn 0.3s var(--ease-spring) both;
  animation-delay: calc(var(--stagger-index, 0) * 50ms);
}

@keyframes fadeSlideIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Scale-in for modals/dialogs */
@utility scale-in {
  animation: scaleIn 0.2s var(--ease-spring);
}

@keyframes scaleIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

/* Slide-in from edge */
@utility slide-in-right {
  animation: slideInRight 0.3s var(--ease-spring);
}

@keyframes slideInRight {
  from { opacity: 0; transform: translateX(16px); }
  to { opacity: 1; transform: translateX(0); }
}
```

#### Reduced motion safety
```css
/* Global reduced-motion override — all custom animations respect preference */
@media (prefers-reduced-motion: reduce) {
  .hover-lift,
  .press-scale,
  .stagger-in,
  .scale-in,
  .slide-in-right {
    animation: none !important;
    transition: none !important;
    transform: none !important;
  }

  .skeleton::after {
    animation: none;
  }
}
```

#### Interactive gradient border
```css
/* Gradient border on hover — cards, inputs */
@utility gradient-border {
  position: relative;
  border: 1px solid var(--color-border);
  transition: border-color 0.2s;
  &::before {
    content: "";
    position: absolute;
    inset: -1px;
    border-radius: inherit;
    padding: 1px;
    background: var(--gradient-accent);
    mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
    mask-composite: exclude;
    opacity: 0;
    transition: opacity 0.3s;
    pointer-events: none;
  }
  &:hover::before {
    opacity: 1;
  }
}
```

**Rules:**
- All `@utility` classes get purged correctly by Tailwind v4 — safe for production
- Always pair animation utilities with `prefers-reduced-motion` override
- Use `--ease-spring` token for consistent feel across all microinteractions
- `--stagger-index` CSS variable set via `style={{ "--stagger-index": i }}` in JSX
- Gradient border uses `mask-composite: exclude` for clean border effect

## Composes With
- `visual-design` — color harmony, elevation, and spacing systems
- `shadcn` — shadcn theme tokens live in `@theme {}`
- `react-client-components` — className applied in client components
- `nextjs-metadata` — theme colors referenced in metadata
- `responsive-design` — container queries for component-level responsiveness
- `dark-mode` — CSS variable theming with `.dark` class
- `animation` — JS animation complements CSS @utility animations
- `loading-transitions` — skeleton and shimmer utilities
