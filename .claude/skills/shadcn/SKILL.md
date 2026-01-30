---
name: shadcn
description: >
  shadcn/ui component library — CLI installation, composition patterns, theming with Tailwind v4, React 19 ref-as-prop compatibility
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(npx shadcn *)
---

# shadcn/ui

## Purpose
shadcn/ui component installation and composition. Covers CLI usage, theming, and React 19
compatibility. The ONE skill for pre-built UI components.

## Project State
- Has shadcn: !`[ -f "components.json" ] && echo "yes" || echo "no"`
- UI components: !`ls src/components/ui/ 2>/dev/null | head -10 || echo "none"`

## When to Use
- Adding pre-built UI components (Button, Dialog, Form, etc.)
- Customizing shadcn component themes
- Composing complex UI from shadcn primitives
- Setting up the component library for the first time

## When NOT to Use
- Custom components without shadcn base → `react-client-components`
- Styling without components → `tailwind-v4`
- Form logic → `react-forms`

## Pattern

### CLI installation
```bash
# Initialize shadcn (first time)
npx shadcn@latest init -d

# Add specific components
npx shadcn@latest add button card dialog form input

# Add multiple at once
npx shadcn@latest add button card dialog
```

### Component composition
```tsx
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export function ProductCard({ name, price }: { name: string; price: number }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{name}</CardTitle>
        <CardDescription>${price}</CardDescription>
      </CardHeader>
      <CardContent>
        <Button>Add to cart</Button>
      </CardContent>
    </Card>
  );
}
```

### Theming with Tailwind v4
```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.145 0 0);
  --color-primary: oklch(0.205 0.064 270.94);
  --color-primary-foreground: oklch(0.985 0 0);
  --radius-lg: 0.5rem;
  --radius-md: calc(var(--radius-lg) - 2px);
  --radius-sm: calc(var(--radius-lg) - 4px);
}
```

## Anti-pattern

```tsx
// WRONG: reimplementing what shadcn already provides
"use client";
function MyButton({ children, ...props }) {
  return (
    <button
      className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
      {...props}
    >
      {children}
    </button>
  );
}
// Use shadcn Button with variant props instead
```

shadcn provides accessible, themed, variant-aware components. Don't rebuild them.

## Common Mistakes
- Not running `shadcn init` before adding components
- Editing shadcn components instead of wrapping/composing them
- Using `tailwind.config.js` — shadcn v2 uses Tailwind v4 CSS-first config
- Forgetting to install required dependencies (some components need Radix)
- Not using `cn()` utility for conditional class merging

## Checklist
- [ ] `components.json` exists from `shadcn init`
- [ ] Components installed via CLI, not copy-pasted
- [ ] Theme variables in CSS `@theme {}`, not tailwind.config.js
- [ ] `cn()` used for all conditional className merging
- [ ] Components composed via wrapping, not direct modification

## Composes With
- `tailwind-v4` — theming via CSS custom properties
- `react-forms` — shadcn Form component wraps react-hook-form
- `react-client-components` — shadcn components are client components
