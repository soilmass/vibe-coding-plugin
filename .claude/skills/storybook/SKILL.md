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

## Composes With
- `shadcn` — stories for all shadcn components
- `tailwind-v4` — Tailwind styles in Storybook
- `accessibility` — per-component a11y audit
- `testing` — visual testing complements unit tests
