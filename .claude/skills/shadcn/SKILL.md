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

### Command palette (cmdk)
```bash
npx shadcn@latest add command
```

```tsx
"use client";

import { useEffect, useState } from "react";
import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import { useRouter } from "next/navigation";

export function CommandPalette() {
  const [open, setOpen] = useState(false);
  const router = useRouter();

  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        setOpen((prev) => !prev);
      }
    }
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, []);

  return (
    <CommandDialog open={open} onOpenChange={setOpen}>
      <CommandInput placeholder="Type a command or search..." />
      <CommandList>
        <CommandEmpty>No results found.</CommandEmpty>
        <CommandGroup heading="Pages">
          <CommandItem onSelect={() => { router.push("/dashboard"); setOpen(false); }}>
            Dashboard
          </CommandItem>
          <CommandItem onSelect={() => { router.push("/settings"); setOpen(false); }}>
            Settings
          </CommandItem>
        </CommandGroup>
        <CommandGroup heading="Actions">
          <CommandItem onSelect={() => { /* action */ setOpen(false); }}>
            Create new project
          </CommandItem>
        </CommandGroup>
      </CommandList>
    </CommandDialog>
  );
}
```

### Dialog / Sheet / Drawer patterns
```tsx
// Confirmation dialog with AlertDialog
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel,
  AlertDialogContent, AlertDialogDescription, AlertDialogFooter,
  AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

export function DeleteConfirmation({ onConfirm }: { onConfirm: () => void }) {
  return (
    <AlertDialog>
      <AlertDialogTrigger asChild>
        <Button variant="destructive">Delete</Button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Are you sure?</AlertDialogTitle>
          <AlertDialogDescription>This action cannot be undone.</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={onConfirm}>Delete</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}

// Sheet as mobile navigation
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";

export function MobileNav() {
  return (
    <Sheet>
      <SheetTrigger asChild><Button variant="ghost" size="icon"><Menu /></Button></SheetTrigger>
      <SheetContent side="left">
        <nav>{/* nav links */}</nav>
      </SheetContent>
    </Sheet>
  );
}

// Drawer bottom sheet (mobile-friendly)
import { Drawer, DrawerContent, DrawerTrigger } from "@/components/ui/drawer";

export function MobileDrawer() {
  return (
    <Drawer>
      <DrawerTrigger asChild><Button>Open</Button></DrawerTrigger>
      <DrawerContent>
        <div className="p-4">{/* content */}</div>
      </DrawerContent>
    </Drawer>
  );
}
```

### Sonner toast
```bash
npx shadcn@latest add sonner
```

```tsx
// Add Toaster to root layout
import { Toaster } from "@/components/ui/sonner";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html><body>{children}<Toaster /></body></html>
  );
}

// Use toast anywhere
import { toast } from "sonner";

// After Server Action
toast.success("Changes saved");
toast.error("Something went wrong");
toast("Item deleted", {
  action: { label: "Undo", onClick: () => undoDelete() },
});
```

### Icon strategy (Lucide React)
```tsx
// Lucide is the default icon library with shadcn
import { Search, Settings, ChevronDown } from "lucide-react";

// Icons are tree-shaken — only imported icons are bundled
// Consistent sizing: use className for size
<Search className="h-4 w-4" />
<Settings className="h-5 w-5" />

// Custom icon wrapper for consistency
export function Icon({
  icon: IconComponent,
  size = "sm",
}: {
  icon: React.ComponentType<{ className?: string }>;
  size?: "sm" | "md" | "lg";
}) {
  const sizeClasses = { sm: "h-4 w-4", md: "h-5 w-5", lg: "h-6 w-6" };
  return <IconComponent className={sizeClasses[size]} />;
}
```

### Premium Component Variants

#### GlassCard
```tsx
import { cn } from "@/lib/utils";

export function GlassCard({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-white/20 bg-white/80 p-6 shadow-xl backdrop-blur-xl",
        "dark:border-white/10 dark:bg-white/5",
        className
      )}
    >
      {children}
    </div>
  );
}
```

#### GradientButton
```tsx
import { cn } from "@/lib/utils";
import { Button, type ButtonProps } from "@/components/ui/button";

export function GradientButton({ className, children, ...props }: ButtonProps) {
  return (
    <Button
      className={cn(
        "bg-gradient-to-r from-brand-500 to-brand-600 text-white shadow-lg shadow-brand-500/25",
        "hover:from-brand-600 hover:to-brand-700 hover:shadow-brand-500/30",
        "active:shadow-brand-500/20",
        className
      )}
      {...props}
    >
      {children}
    </Button>
  );
}
```

#### StatCard
```tsx
import { cn } from "@/lib/utils";
import { ArrowUp, ArrowDown } from "lucide-react";

export function StatCard({
  label,
  value,
  change,
  trend,
}: {
  label: string;
  value: string;
  change: string;
  trend: "up" | "down";
}) {
  return (
    <div className="rounded-xl border bg-card p-6">
      <p className="text-sm text-muted-foreground">{label}</p>
      <p className="mt-2 text-3xl font-bold tabular-nums tracking-tight">{value}</p>
      <div className="mt-2 flex items-center gap-1 text-sm">
        {trend === "up" ? (
          <ArrowUp className="h-4 w-4 text-green-500" />
        ) : (
          <ArrowDown className="h-4 w-4 text-red-500" />
        )}
        <span className={cn(trend === "up" ? "text-green-600 dark:text-green-400" : "text-red-600 dark:text-red-400")}>
          {change}
        </span>
      </div>
    </div>
  );
}
```

#### FeatureCard
```tsx
import { cn } from "@/lib/utils";
import type { LucideIcon } from "lucide-react";

export function FeatureCard({
  icon: Icon,
  title,
  description,
  className,
}: {
  icon: LucideIcon;
  title: string;
  description: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "group rounded-2xl border bg-card p-6 transition-all",
        "hover:border-brand-500/20 hover:shadow-lg",
        className
      )}
    >
      <div className="mb-4 inline-flex rounded-xl bg-brand-500/10 p-3">
        <Icon className="h-6 w-6 text-brand-500" />
      </div>
      <h3 className="text-lg font-semibold">{title}</h3>
      <p className="mt-2 text-muted-foreground">{description}</p>
    </div>
  );
}
```

#### AvatarGroup
```tsx
import { cn } from "@/lib/utils";

export function AvatarGroup({
  avatars,
  max = 4,
}: {
  avatars: { src: string; alt: string }[];
  max?: number;
}) {
  const visible = avatars.slice(0, max);
  const overflow = avatars.length - max;

  return (
    <div className="flex -space-x-3">
      {visible.map((avatar, i) => (
        <img
          key={i}
          src={avatar.src}
          alt={avatar.alt}
          className="h-10 w-10 rounded-full ring-2 ring-background"
        />
      ))}
      {overflow > 0 && (
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-muted ring-2 ring-background">
          <span className="text-xs font-medium">+{overflow}</span>
        </div>
      )}
    </div>
  );
}
```

## Microinteractions & Visual Polish

Default shadcn components look clean. Premium shadcn components feel alive — dialogs spring in, cards stagger on load, buttons have depth, and toasts slide with physics.

### Dialog with spring animation
```tsx
"use client";

import { motion, AnimatePresence } from "motion/react";
import {
  Dialog,
  DialogContent,
  DialogOverlay,
  DialogPortal,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";

export function AnimatedDialog({
  open,
  onOpenChange,
  children,
  title,
  description,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  children: React.ReactNode;
  title: string;
  description?: string;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <AnimatePresence>
        {open && (
          <DialogPortal forceMount>
            <DialogOverlay asChild>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm"
              />
            </DialogOverlay>
            <DialogContent asChild forceMount>
              <motion.div
                initial={{ opacity: 0, scale: 0.95, y: 10 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.97, y: 5 }}
                transition={{ type: "spring", stiffness: 350, damping: 25 }}
                className="fixed left-1/2 top-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2 rounded-xl border bg-background p-6 shadow-2xl"
              >
                <DialogTitle>{title}</DialogTitle>
                {description && <DialogDescription>{description}</DialogDescription>}
                {children}
              </motion.div>
            </DialogContent>
          </DialogPortal>
        )}
      </AnimatePresence>
    </Dialog>
  );
}
```

### Card grid with stagger
```tsx
"use client";

import { motion } from "motion/react";

const container = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.06 },
  },
};

const item = {
  hidden: { opacity: 0, y: 16 },
  show: {
    opacity: 1,
    y: 0,
    transition: { type: "spring", stiffness: 300, damping: 24 },
  },
};

export function StaggeredCardGrid({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      variants={container}
      initial="hidden"
      animate="show"
      className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3"
    >
      {children}
    </motion.div>
  );
}

// Wrap each card child
export function StaggeredCard({ children }: { children: React.ReactNode }) {
  return <motion.div variants={item}>{children}</motion.div>;
}
```

### Button with ripple effect
```tsx
"use client";

import { useState, type MouseEvent } from "react";
import { Button, type ButtonProps } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function RippleButton({ className, children, ...props }: ButtonProps) {
  const [ripples, setRipples] = useState<{ x: number; y: number; id: number }[]>([]);

  function handleClick(e: MouseEvent<HTMLButtonElement>) {
    const rect = e.currentTarget.getBoundingClientRect();
    const ripple = {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top,
      id: Date.now(),
    };
    setRipples((prev) => [...prev, ripple]);
    setTimeout(() => setRipples((prev) => prev.filter((r) => r.id !== ripple.id)), 600);
    props.onClick?.(e);
  }

  return (
    <Button
      className={cn("relative overflow-hidden", className)}
      onClick={handleClick}
      {...props}
    >
      {children}
      {ripples.map((ripple) => (
        <span
          key={ripple.id}
          className="absolute animate-[ripple_0.6s_ease-out] rounded-full bg-white/25"
          style={{
            left: ripple.x - 50,
            top: ripple.y - 50,
            width: 100,
            height: 100,
          }}
        />
      ))}
    </Button>
  );
}

// Add to globals.css:
// @keyframes ripple { from { transform: scale(0); opacity: 1; } to { transform: scale(3); opacity: 0; } }
```

### Card with hover lift and glow
```tsx
import { cn } from "@/lib/utils";
import { Card } from "@/components/ui/card";

export function HoverCard({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <Card
      className={cn(
        "transition-all duration-300 ease-out",
        "hover:-translate-y-1 hover:shadow-xl",
        "hover:shadow-primary/5 hover:border-primary/20",
        className
      )}
    >
      {children}
    </Card>
  );
}
```

### Sheet/Drawer with custom spring
```tsx
"use client";

// Vaul drawer already has spring physics — configure for premium feel
import { Drawer, DrawerContent, DrawerTrigger } from "@/components/ui/drawer";

export function PremiumDrawer({ children, trigger }: { children: React.ReactNode; trigger: React.ReactNode }) {
  return (
    <Drawer
      shouldScaleBackground
      // Vaul spring config for buttery feel
    >
      <DrawerTrigger asChild>{trigger}</DrawerTrigger>
      <DrawerContent className="max-h-[85vh]">
        <div className="mx-auto mt-4 h-1.5 w-12 rounded-full bg-muted" />
        <div className="p-4">{children}</div>
      </DrawerContent>
    </Drawer>
  );
}
```

### Toast with entrance animation
```tsx
// Sonner already animates, but enhance with custom styling
import { Toaster } from "@/components/ui/sonner";

// In root layout — configure for premium feel
<Toaster
  position="bottom-right"
  toastOptions={{
    classNames: {
      toast: "rounded-xl border shadow-lg backdrop-blur-sm bg-background/95",
      title: "font-semibold",
      description: "text-muted-foreground",
      actionButton: "bg-primary text-primary-foreground",
    },
  }}
/>
```

## Composes With
- `tailwind-v4` — theming via CSS custom properties
- `react-forms` — shadcn Form component wraps react-hook-form
- `react-client-components` — shadcn components are client components
- `dark-mode` — shadcn uses semantic color tokens that auto-switch
- `visual-design` — color harmony, elevation, spacing tokens
- `landing-patterns` — premium variants used in marketing pages
- `animation` — Motion library for dialog/card/stagger animations
