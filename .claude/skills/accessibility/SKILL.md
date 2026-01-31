---
name: accessibility
description: >
  WCAG 2.1 AA compliance patterns for React 19 — semantic HTML, ARIA attributes, keyboard navigation, focus management, color contrast
allowed-tools: Read, Grep, Glob
---

# Accessibility

## Purpose
WCAG 2.1 AA compliance patterns for React 19 + Next.js 15. Covers semantic HTML, ARIA attributes,
keyboard navigation, focus management, and screen reader support. The ONE skill for a11y decisions.

## When to Use
- Building interactive components (modals, dropdowns, tabs)
- Adding ARIA attributes to custom UI elements
- Implementing keyboard navigation
- Managing focus for dynamic content
- Auditing components for a11y compliance

## When NOT to Use
- Using shadcn/ui components (already accessible) → `shadcn`
- Form validation patterns → `react-forms`
- Full site audit → use `a11y-auditor` agent instead

## Pattern

### Semantic HTML over div soup
```tsx
// CORRECT: semantic elements
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/about">About</a></li>
    <li><a href="/contact" aria-current="page">Contact</a></li>
  </ul>
</nav>

// WRONG: div soup
<div className="nav">
  <div onClick={() => router.push("/about")}>About</div>
  <div onClick={() => router.push("/contact")}>Contact</div>
</div>
```

### Accessible modal — use native `<dialog>`
```tsx
"use client";
import { useEffect, useRef } from "react";

export function Modal({ open, onClose, children }: {
  open: boolean; onClose: () => void; children: React.ReactNode;
}) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    if (open) dialogRef.current?.showModal();
    else dialogRef.current?.close();
  }, [open]);
  return (
    <dialog ref={dialogRef} onClose={onClose} aria-labelledby="modal-title">
      <h2 id="modal-title">Title</h2>
      {children}
      <button onClick={onClose}>Close</button>
    </dialog>
  );
}
```

### Form errors with aria-describedby
```tsx
<input id="email" name="email" aria-invalid={!!error} aria-describedby={error ? "email-error" : undefined} />
{error && <p id="email-error" role="alert">{error}</p>}
```

### Skip link + loading state
```tsx
// layout.tsx: <a href="#main-content" className="sr-only focus:not-sr-only">Skip to content</a>
// SubmitButton: <button aria-busy={pending} disabled={pending}>Submit</button>
```

## Anti-pattern

```tsx
// WRONG: clickable div without keyboard support
<div onClick={handleClick} className="button">Click me</div>

// CORRECT: use native button element
<button onClick={handleClick}>Click me</button>

// If you MUST use a non-button: add role, tabIndex, onKeyDown, aria-label
```

## Common Mistakes
- Using `div` with `onClick` instead of `<button>` or `<a>`
- Missing `aria-label` on icon-only buttons
- Removing focus outlines without providing alternative focus indicators
- Not announcing dynamic content changes to screen readers
- Skipping heading levels (h1 → h3)
- Using `aria-hidden="true"` on interactive elements

## Checklist
- [ ] Interactive elements use native HTML (`<button>`, `<a>`, `<input>`)
- [ ] Icon-only buttons have `aria-label`
- [ ] Forms link errors to inputs with `aria-describedby`
- [ ] Invalid inputs have `aria-invalid`
- [ ] Modals trap focus and support Escape to close
- [ ] Skip link to main content exists
- [ ] Heading hierarchy is sequential (h1 → h2 → h3)
- [ ] Loading states announced with `aria-busy`
- [ ] Color is not the sole means of conveying information

### Focus & interaction states
```tsx
// focus-visible:ring-* on ALL interactive elements
<button className="focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2">
  Click me
</button>

// NEVER outline-none without focus replacement
// WRONG:
<button className="outline-none">No focus indicator!</button>
// CORRECT:
<button className="outline-none focus-visible:ring-2 focus-visible:ring-ring">
  Custom focus ring
</button>

// Prefer :focus-visible over :focus (avoids ring on mouse click)
// :focus — shows ring on click AND keyboard
// :focus-visible — shows ring on keyboard only (what users expect)

// :focus-within for compound controls
<div className="focus-within:ring-2 focus-within:ring-ring rounded-md">
  <input className="outline-none" />
  <button className="outline-none">Search</button>
</div>

// Decorative icons need aria-hidden
<button>
  <SearchIcon aria-hidden="true" />
  <span>Search</span>
</button>

// Icon-only buttons need aria-label
<button aria-label="Search">
  <SearchIcon aria-hidden="true" />
</button>

// aria-live for async updates (toasts, validation, loading)
<div aria-live="polite" aria-atomic="true">
  {validationMessage}
</div>

// scroll-margin-top for anchor targets with fixed headers
<h2 id="section-1" className="scroll-mt-20">Section 1</h2>
// Ensures anchor scroll doesn't hide content behind sticky header

// Contrast progression: rest → hover → active → focus (each more prominent)
// rest:     text-muted-foreground
// hover:    text-foreground
// active:   text-foreground font-medium
// focus:    text-foreground ring-2 ring-ring
```

### Premium Accessible Animations

#### Animated focus ring with spring physics
```tsx
/* Focus ring that expands with a spring feel — CSS only */
.focus-ring {
  @apply outline-none transition-all duration-200;
}
.focus-ring:focus-visible {
  @apply ring-2 ring-primary ring-offset-2 ring-offset-background;
  /* Animated expansion via box-shadow transition */
  box-shadow:
    0 0 0 2px var(--color-background),
    0 0 0 4px var(--color-primary),
    0 0 12px 0 oklch(0.55 0.2 270 / 0.15);
  transition: box-shadow 200ms cubic-bezier(0.34, 1.56, 0.64, 1);
}
```

```tsx
// Reusable focusRing utility class
import { cn } from "@/lib/utils";

export function focusRing(className?: string) {
  return cn(
    "outline-none",
    "focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
    "focus-visible:[box-shadow:0_0_0_2px_var(--color-background),0_0_0_4px_var(--color-primary),0_0_12px_0_oklch(0.55_0.2_270/0.15)]",
    "transition-[box-shadow] duration-200",
    className
  );
}

// Usage
<button className={focusRing("rounded-lg px-4 py-2")}>Click me</button>
```

#### prefers-reduced-motion as universal animation gate
```tsx
"use client";
import { useReducedMotion } from "motion/react";

// Hook that provides safe animation values
export function useAccessibleMotion() {
  const prefersReduced = useReducedMotion();

  return {
    // Fade only (no movement) for reduced motion
    enter: prefersReduced
      ? { initial: { opacity: 0 }, animate: { opacity: 1 }, transition: { duration: 0.15 } }
      : { initial: { opacity: 0, y: 12 }, animate: { opacity: 1, y: 0 }, transition: { type: "spring", stiffness: 300, damping: 25 } },

    // Instant for reduced motion
    spring: prefersReduced
      ? { type: "tween" as const, duration: 0.01 }
      : { type: "spring" as const, stiffness: 300, damping: 25 },

    // No layout animations for reduced motion
    layout: !prefersReduced,
  };
}
```

```css
/* CSS fallback for non-React contexts */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

#### Animated aria-live region for status updates
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";

// Announces to screen readers AND animates visually
export function LiveStatus({ message, type = "polite" }: {
  message: string | null;
  type?: "polite" | "assertive";
}) {
  return (
    <div aria-live={type} aria-atomic="true" className="relative">
      <AnimatePresence mode="wait">
        {message && (
          <motion.p
            key={message}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.2 }}
            className="text-sm text-muted-foreground"
          >
            {message}
          </motion.p>
        )}
      </AnimatePresence>
    </div>
  );
}
```

#### Touch feedback with visual ripple
```tsx
"use client";
import { useState, useCallback } from "react";

// Accessible ripple — visible feedback for both mouse and keyboard
export function RippleButton({ children, onClick, ...props }: React.ButtonHTMLAttributes<HTMLButtonElement>) {
  const [ripples, setRipples] = useState<{ x: number; y: number; id: number }[]>([]);

  const handleInteraction = useCallback((e: React.MouseEvent | React.KeyboardEvent) => {
    if ("key" in e && e.key !== "Enter" && e.key !== " ") return;

    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const x = "clientX" in e ? e.clientX - rect.left : rect.width / 2;
    const y = "clientY" in e ? e.clientY - rect.top : rect.height / 2;
    const id = Date.now();

    setRipples((r) => [...r, { x, y, id }]);
    setTimeout(() => setRipples((r) => r.filter((ri) => ri.id !== id)), 600);
  }, []);

  return (
    <button
      onClick={(e) => { handleInteraction(e); onClick?.(e); }}
      onKeyDown={handleInteraction}
      className="relative overflow-hidden rounded-lg bg-primary px-4 py-2 text-primary-foreground"
      {...props}
    >
      {ripples.map((r) => (
        <span
          key={r.id}
          className="absolute rounded-full bg-white/25 animate-[ripple_600ms_ease-out]"
          style={{ left: r.x - 10, top: r.y - 10, width: 20, height: 20 }}
        />
      ))}
      {children}
    </button>
  );
}
```

```css
@keyframes ripple {
  to { transform: scale(8); opacity: 0; }
}
```

#### Focus-within glow for input groups
```tsx
// Compound input with grouped focus indication
<div className={cn(
  "flex items-center rounded-lg border bg-background px-3",
  "transition-all duration-200",
  "focus-within:ring-2 focus-within:ring-primary/20 focus-within:border-primary/50",
  "focus-within:shadow-[0_0_0_4px_oklch(0.55_0.2_270/0.08)]"
)}>
  <SearchIcon className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
  <input
    type="search"
    placeholder="Search..."
    className="flex-1 bg-transparent py-2 px-2 outline-none text-sm"
    aria-label="Search"
  />
  <kbd className="text-xs text-muted-foreground">/</kbd>
</div>
```

## Composes With
- `react-client-components` — a11y attributes on interactive client components
- `shadcn` — shadcn/ui components are accessible by default
- `react-forms` — form error announcements and validation
- `storybook` — per-component a11y auditing
- `animation` — respect prefers-reduced-motion, accessible motion hook
- `visual-design` — focus ring styling, contrast progression
- `responsive-design` — touch target sizing on mobile
