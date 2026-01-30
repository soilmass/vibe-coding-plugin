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

## Composes With
- `shadcn` — shadcn theme tokens live in `@theme {}`
- `react-client-components` — className applied in client components
- `nextjs-metadata` — theme colors referenced in metadata
