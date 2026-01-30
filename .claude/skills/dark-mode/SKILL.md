---
name: dark-mode
description: >
  Theme switching with next-themes, Tailwind v4 CSS variables, system preference detection, flash-free SSR
allowed-tools: Read, Grep, Glob
---

# Dark Mode

## Purpose
Theme switching patterns for Next.js 15 with `next-themes` and Tailwind v4. Covers dark/light/system
themes, CSS variable-based theming, flash-free SSR, and semantic color tokens. The ONE skill for
theme management.

## When to Use
- Adding dark mode toggle to an app
- Setting up theme-aware CSS variables with Tailwind v4
- Preventing flash of unstyled content (FOUC) on theme load
- Supporting system preference detection
- Building multi-theme support beyond light/dark

## When NOT to Use
- Tailwind utility styling → `tailwind-v4`
- Component theming → `shadcn`
- Accessibility color contrast → `accessibility`

## Pattern

### ThemeProvider setup
```tsx
// src/components/theme-provider.tsx
"use client";

import { ThemeProvider as NextThemesProvider } from "next-themes";

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return (
    <NextThemesProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      disableTransitionOnChange
    >
      {children}
    </NextThemesProvider>
  );
}
```

```tsx
// src/app/layout.tsx — wrap children, NOT the layout itself as "use client"
import { ThemeProvider } from "@/components/theme-provider";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
```

### Tailwind v4 dark mode variables
```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.145 0 0);
  --color-card: oklch(1 0 0);
  --color-card-foreground: oklch(0.145 0 0);
  --color-primary: oklch(0.205 0.064 270.94);
  --color-primary-foreground: oklch(0.985 0 0);
  --color-muted: oklch(0.96 0 0);
  --color-muted-foreground: oklch(0.556 0 0);
  --color-border: oklch(0.922 0 0);
}

.dark {
  --color-background: oklch(0.145 0 0);
  --color-foreground: oklch(0.985 0 0);
  --color-card: oklch(0.205 0 0);
  --color-card-foreground: oklch(0.985 0 0);
  --color-primary: oklch(0.922 0 0);
  --color-primary-foreground: oklch(0.205 0.064 270.94);
  --color-muted: oklch(0.269 0 0);
  --color-muted-foreground: oklch(0.708 0 0);
  --color-border: oklch(0.269 0 0);
}
```

### Theme toggle component
```tsx
"use client";

import { useTheme } from "next-themes";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Sun, Moon, Monitor } from "lucide-react";

export function ThemeToggle() {
  const { setTheme } = useTheme();

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon">
          <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          <span className="sr-only">Toggle theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme("light")}>
          <Sun className="mr-2 h-4 w-4" /> Light
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("dark")}>
          <Moon className="mr-2 h-4 w-4" /> Dark
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("system")}>
          <Monitor className="mr-2 h-4 w-4" /> System
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
```

### Multi-theme support with data-theme
```css
/* Extended themes beyond light/dark */
[data-theme="ocean"] {
  --color-background: oklch(0.15 0.03 230);
  --color-foreground: oklch(0.92 0.01 230);
  --color-primary: oklch(0.65 0.15 230);
}
```

```tsx
// ThemeProvider with custom themes
<NextThemesProvider
  attribute="data-theme"
  themes={["light", "dark", "ocean"]}
  defaultTheme="system"
  enableSystem
>
  {children}
</NextThemesProvider>
```

### Cookie-based persistence (prevent FOUC)
```tsx
// next-themes handles this automatically when using attribute="class"
// The script injected by next-themes reads the cookie/localStorage
// BEFORE React hydrates, preventing any flash.
//
// Key: add suppressHydrationWarning on <html> to avoid React mismatch warning
<html lang="en" suppressHydrationWarning>
```

## Anti-pattern

```tsx
// WRONG: detecting theme with useEffect (causes flash)
"use client";
import { useEffect, useState } from "react";

function ThemeDetector() {
  const [theme, setTheme] = useState("light");
  useEffect(() => {
    const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    setTheme(isDark ? "dark" : "light");
  }, []);
  // Flash of light theme on dark mode users!
}

// WRONG: hardcoded colors instead of semantic tokens
<div className="bg-white text-black dark:bg-gray-900 dark:text-white">
  {/* Every component needs dark: variants */}
</div>

// CORRECT: semantic tokens that auto-switch
<div className="bg-background text-foreground">
  {/* Automatically adapts to theme via CSS variables */}
</div>
```

## Common Mistakes
- Using `useEffect` for theme detection — causes flash of wrong theme
- Hardcoding `bg-white`/`text-black` instead of `bg-background`/`text-foreground`
- Missing `suppressHydrationWarning` on `<html>` — React hydration mismatch
- Making the root layout `"use client"` for ThemeProvider — use a wrapper component
- Not using `disableTransitionOnChange` — elements flash during theme switch
- Forgetting to style charts, images, and third-party components for dark mode

## Checklist
- [ ] `next-themes` ThemeProvider wraps app (via client wrapper component)
- [ ] `suppressHydrationWarning` on `<html>` tag
- [ ] All colors use semantic tokens (`bg-background`, not `bg-white`)
- [ ] `.dark` class overrides CSS variables in globals.css
- [ ] Theme toggle uses shadcn DropdownMenu with light/dark/system
- [ ] No `useEffect` theme detection (use `next-themes` hook)
- [ ] Root layout is NOT `"use client"` — ThemeProvider is a separate client component

### Native dark mode integration
```tsx
// color-scheme: dark on <html> — fixes scrollbar, native inputs, system dialogs
<html lang="en" className="dark" style={{ colorScheme: "dark" }}>
  {/* Native scrollbars, checkboxes, selects adapt to dark mode */}
</html>

// Or set via CSS (preferred — avoids inline style)
// globals.css:
// .dark { color-scheme: dark; }

// <meta name="theme-color"> matching current theme
// Tints the browser chrome (address bar, status bar)
import { useTheme } from "next-themes";

export function ThemeMetaTag() {
  const { resolvedTheme } = useTheme();
  return (
    <meta
      name="theme-color"
      content={resolvedTheme === "dark" ? "#0a0a0a" : "#ffffff"}
    />
  );
}

// Native <select> on Windows dark mode — explicit colors needed
// Windows doesn't auto-adapt native select styling
<select className="bg-background text-foreground">
  <option>Option 1</option>
</select>
// Without explicit background-color and color, Windows dark mode
// renders white dropdown on dark page
```

### Premium Dark Mode Polish

#### Adaptive elevation — light uses shadows, dark uses borders + glow
```tsx
// Light: shadow-based depth. Dark: border + subtle glow instead.
export function AdaptiveCard({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-xl border bg-card p-6 shadow-sm dark:shadow-none dark:border-border/50">
      {children}
    </div>
  );
}

// Dark mode cards may use a subtle top-edge highlight
<div className="rounded-xl border bg-card p-6 dark:border-t-white/10" />
```

#### Glow effects for CTAs in dark mode
```tsx
// Primary buttons glow in dark mode
<button className="rounded-lg bg-brand-500 px-6 py-3 font-medium text-white shadow-md dark:shadow-lg dark:shadow-brand-500/25">
  Get started
</button>

// Gradient button with colored glow
<button className="rounded-lg bg-gradient-to-r from-brand-500 to-accent-500 px-6 py-3 font-medium text-white shadow-lg shadow-brand-500/20 dark:shadow-brand-500/40">
  Upgrade now
</button>
```

#### Gradient intensity shift — brighter in dark mode
```tsx
// Light: subtle gradient. Dark: more saturated and vivid.
<div className="bg-gradient-to-r from-brand-100 to-accent-100 dark:from-brand-800 dark:to-accent-800">
  Content adapts gradient intensity
</div>

// Hero mesh gradient — more visible in dark mode
<div
  className="absolute inset-0 -z-10 opacity-50 dark:opacity-80"
  style={{
    background: `
      radial-gradient(ellipse 80% 50% at 50% -20%, oklch(0.55 0.22 270 / 0.3), transparent),
      radial-gradient(ellipse 60% 40% at 80% 50%, oklch(0.55 0.20 150 / 0.15), transparent)
    `,
  }}
/>
```

#### Image dimming for dark mode
```tsx
// Reduce image brightness in dark mode to lower eye strain
<img
  src="/photo.jpg"
  alt="Description"
  className="rounded-lg dark:brightness-90"
/>

// Stronger dimming for hero images
<img
  src="/hero-photo.jpg"
  alt="Hero"
  className="rounded-lg dark:brightness-[0.85] dark:contrast-[1.1]"
/>
```

#### Separator styling — more subtle in dark mode
```tsx
// Separators become more subtle in dark mode
<hr className="border-border dark:border-border/50" />

// Dividers within cards
<div className="divide-y divide-border dark:divide-border/50">
  <div className="py-4">Row 1</div>
  <div className="py-4">Row 2</div>
</div>
```

## Composes With
- `tailwind-v4` — CSS variable theming in `@theme {}` and `.dark {}`
- `shadcn` — shadcn components use semantic color tokens
- `storybook` — test components in both themes
- `react-client-components` — ThemeProvider and toggle are client components
- `visual-design` — elevation and color systems adapt to dark mode
