---
name: storybook
description: >
  Storybook 8 for Next.js 15 — component stories, shadcn integration, a11y addon, dark mode, Chromatic CI
allowed-tools: Read, Grep, Glob
---

# Storybook

## Purpose
Component documentation and visual testing with Storybook 8 for Next.js 15. Covers story
creation for shadcn components, accessibility addon integration, dark mode toggling,
and Chromatic visual regression CI.

## When to Use
- Documenting component library and design system
- Developing components in isolation
- Visual testing with Chromatic
- Accessibility auditing per component
- Creating MDX documentation pages for design patterns

## When NOT to Use
- E2E testing → `testing` (Playwright)
- Unit testing logic → `testing` (Vitest)
- Screenshot diff testing → `visual-regression`
- Production deployment → `deploy`

## Pattern

### Storybook initialization
```bash
npx storybook@latest init --type nextjs
```

### Component story
```tsx
// src/components/ui/button.stories.tsx
import type { Meta, StoryObj } from "@storybook/react";
import { Button } from "./button";

const meta = {
  title: "UI/Button",
  component: Button,
  tags: ["autodocs"],
  argTypes: {
    variant: {
      control: "select",
      options: ["default", "destructive", "outline", "secondary", "ghost", "link"],
    },
    size: {
      control: "select",
      options: ["default", "sm", "lg", "icon"],
    },
  },
} satisfies Meta<typeof Button>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: { children: "Button", variant: "default" },
};

export const Destructive: Story = {
  args: { children: "Delete", variant: "destructive" },
};

export const Loading: Story = {
  args: { children: "Loading...", disabled: true },
};
```

### Storybook configuration for Next.js 15
```tsx
// .storybook/main.ts
import type { StorybookConfig } from "@storybook/nextjs";

const config: StorybookConfig = {
  stories: ["../src/**/*.stories.@(ts|tsx)"],
  addons: [
    "@storybook/addon-essentials",
    "@storybook/addon-a11y",
    "@storybook/addon-themes",
  ],
  framework: {
    name: "@storybook/nextjs",
    options: { nextConfigPath: "../next.config.ts" },
  },
};

export default config;
```

### Dark mode and theme toggle
```tsx
// .storybook/preview.ts
import type { Preview } from "@storybook/react";
import { withThemeByClassName } from "@storybook/addon-themes";
import "../src/app/globals.css";

const preview: Preview = {
  decorators: [
    withThemeByClassName({
      themes: { light: "", dark: "dark" },
      defaultTheme: "light",
    }),
  ],
};

export default preview;
```

### A11y addon configuration
```tsx
// .storybook/main.ts (addon already included above)
// Accessibility violations shown in the A11y panel for each story
// Runs axe-core checks automatically
```

### Mock providers decorator
```tsx
// .storybook/decorators/auth-decorator.tsx
import type { Decorator } from "@storybook/react";

export const withAuth: Decorator = (Story, context) => {
  const mockSession = context.parameters.session ?? {
    user: { id: "1", name: "Test User", email: "test@example.com" },
  };

  return (
    <SessionProvider session={mockSession}>
      <Story />
    </SessionProvider>
  );
};
```

### Chromatic CI integration
```yaml
# .github/workflows/chromatic.yml
name: Chromatic
on: push
jobs:
  chromatic:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - uses: chromaui/action@latest
        with:
          projectToken: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}
```

### Package.json scripts
```json
{
  "scripts": {
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build"
  }
}
```

## Anti-pattern

### Stories without controls
Stories without interactive controls are just screenshots. Always add `argTypes` so
designers and developers can explore component variations interactively.

### Skipping a11y addon
Every component story should pass accessibility checks. Install `@storybook/addon-a11y`
and fix violations before they reach production.

## Common Mistakes
- Missing `globals.css` import in preview — Tailwind styles not applied
- Not using `tags: ["autodocs"]` — no auto-generated docs
- Storybook build failing with Server Components — mock or skip server-only imports
- No theme decorator — dark mode not testable
- Importing server-only code — use mocks for auth/db

## Checklist
- [ ] Storybook 8 initialized with `@storybook/nextjs`
- [ ] Stories for all shared UI components
- [ ] `@storybook/addon-a11y` installed and active
- [ ] Dark mode toggle via theme decorator
- [ ] `globals.css` imported in preview
- [ ] Mock providers for auth context
- [ ] Chromatic CI for visual regression
- [ ] `tags: ["autodocs"]` for auto-generated docs

### Design System Documentation Patterns

#### Design token showcase stories
```tsx
// src/stories/design-tokens.stories.tsx
import type { Meta, StoryObj } from "@storybook/react";

function ColorPalette() {
  const colors = [
    { name: "Primary", var: "--color-primary", fg: "--color-primary-foreground" },
    { name: "Secondary", var: "--color-secondary", fg: "--color-secondary-foreground" },
    { name: "Muted", var: "--color-muted", fg: "--color-muted-foreground" },
    { name: "Accent", var: "--color-accent", fg: "--color-accent-foreground" },
    { name: "Destructive", var: "--color-destructive", fg: "--color-destructive-foreground" },
  ];

  return (
    <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
      {colors.map((c) => (
        <div key={c.name} className="space-y-2">
          <div
            className="h-20 rounded-xl border"
            style={{ backgroundColor: `var(${c.var})` }}
          />
          <p className="text-sm font-medium">{c.name}</p>
          <code className="text-xs text-muted-foreground">{c.var}</code>
        </div>
      ))}
    </div>
  );
}

const meta: Meta = { title: "Design System/Colors", component: ColorPalette };
export default meta;
export const Palette: StoryObj = {};
```

#### Interaction states story
```tsx
// Shows all visual states: rest, hover, active, focus, disabled, loading
import type { Meta, StoryObj } from "@storybook/react";
import { Button } from "@/components/ui/button";

function ButtonStates() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="mb-3 text-sm font-medium text-muted-foreground">Visual States</h3>
        <div className="flex flex-wrap gap-3">
          <Button>Rest</Button>
          <Button className="bg-primary/90">Hover</Button>
          <Button className="scale-[0.98]">Active</Button>
          <Button className="ring-2 ring-ring ring-offset-2">Focus</Button>
          <Button disabled>Disabled</Button>
          <Button disabled>
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            Loading
          </Button>
        </div>
      </div>
      <div>
        <h3 className="mb-3 text-sm font-medium text-muted-foreground">All Variants</h3>
        <div className="flex flex-wrap gap-3">
          {(["default", "secondary", "destructive", "outline", "ghost", "link"] as const).map((v) => (
            <Button key={v} variant={v}>{v}</Button>
          ))}
        </div>
      </div>
    </div>
  );
}

const meta: Meta = { title: "Design System/Button States", component: ButtonStates };
export default meta;
export const States: StoryObj = {};
```

#### Responsive variant stories
```tsx
// src/components/ui/card.stories.tsx
import type { Meta, StoryObj } from "@storybook/react";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

const meta = {
  title: "UI/Card",
  component: Card,
  parameters: {
    // Test at multiple viewports
    chromatic: { viewports: [375, 768, 1280] },
  },
} satisfies Meta<typeof Card>;

export default meta;

export const Responsive: StoryObj = {
  render: () => (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {[1, 2, 3].map((i) => (
        <Card key={i}>
          <CardHeader>
            <CardTitle>Card {i}</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">Content adapts to grid width</p>
          </CardContent>
        </Card>
      ))}
    </div>
  ),
};
```

#### Animation timing stories with controls
```tsx
// src/stories/animation-profiles.stories.tsx
import type { Meta, StoryObj } from "@storybook/react";
import { motion } from "motion/react";
import { useState } from "react";

function AnimationDemo({ stiffness, damping }: { stiffness: number; damping: number }) {
  const [key, setKey] = useState(0);
  return (
    <div className="space-y-4">
      <button onClick={() => setKey((k) => k + 1)} className="text-sm underline">
        Replay
      </button>
      <motion.div
        key={key}
        initial={{ opacity: 0, y: 20, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: "spring", stiffness, damping }}
        className="h-32 w-32 rounded-xl bg-primary"
      />
      <code className="text-xs text-muted-foreground">
        stiffness: {stiffness}, damping: {damping}
      </code>
    </div>
  );
}

const meta: Meta<typeof AnimationDemo> = {
  title: "Design System/Animation",
  component: AnimationDemo,
  argTypes: {
    stiffness: { control: { type: "range", min: 100, max: 600, step: 10 } },
    damping: { control: { type: "range", min: 10, max: 50, step: 1 } },
  },
};

export default meta;

export const Subtle: StoryObj<typeof AnimationDemo> = { args: { stiffness: 400, damping: 30 } };
export const Expressive: StoryObj<typeof AnimationDemo> = { args: { stiffness: 250, damping: 18 } };
export const Snappy: StoryObj<typeof AnimationDemo> = { args: { stiffness: 500, damping: 35 } };
```

#### Spacing and typography scale story
```tsx
function SpacingScale() {
  const sizes = [1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24];
  return (
    <div className="space-y-6">
      <h3 className="text-sm font-medium text-muted-foreground">Spacing Scale</h3>
      {sizes.map((s) => (
        <div key={s} className="flex items-center gap-4">
          <code className="w-12 text-xs text-muted-foreground">{s}</code>
          <div className="h-4 rounded bg-primary" style={{ width: `${s * 4}px` }} />
          <span className="text-xs text-muted-foreground">{s * 4}px</span>
        </div>
      ))}
    </div>
  );
}
```

## Composes With
- `shadcn` — stories for all shadcn components
- `tailwind-v4` — Tailwind styles in Storybook
- `accessibility` — per-component a11y audit
- `testing` — visual testing complements unit tests
- `dark-mode` — test components in both light and dark themes
- `visual-design` — design token documentation and color palette stories
- `animation` — animation timing stories with interactive controls
- `visual-regression` — Chromatic snapshots from Storybook stories
