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

## Composes With
- `react-client-components` — a11y attributes on interactive client components
- `shadcn` — shadcn/ui components are accessible by default
- `react-forms` — form error announcements and validation
- `storybook` — per-component a11y auditing
- `animation` — respect prefers-reduced-motion
