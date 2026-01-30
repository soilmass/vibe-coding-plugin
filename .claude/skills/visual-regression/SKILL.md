---
name: visual-regression
description: >
  Screenshot diff testing — Playwright snapshots, baseline management, responsive breakpoints, CI artifact upload
allowed-tools: Read, Grep, Glob
---

# Visual Regression

## Purpose
Visual regression testing for Next.js 15 using Playwright screenshot comparisons. Covers
baseline management, responsive breakpoint testing, animation handling, and CI integration
with GitHub Actions artifact upload.

## When to Use
- Preventing unintended visual changes in UI components
- Testing responsive layouts across breakpoints
- Visual diff review in pull requests
- Component-level screenshot testing with Storybook
- Verifying design system consistency

## When NOT to Use
- Functional E2E testing → `testing` (Playwright)
- Unit testing → `testing` (Vitest)
- Component development → `storybook`
- Performance testing → `performance`

## Pattern

### Playwright visual test
```tsx
// tests/visual/homepage.spec.ts
import { test, expect } from "@playwright/test";

test("homepage visual regression", async ({ page }) => {
  await page.goto("/");
  await page.waitForLoadState("networkidle");

  await expect(page).toHaveScreenshot("homepage.png", {
    maxDiffPixelRatio: 0.01,
  });
});
```

### Responsive breakpoint testing
```tsx
// tests/visual/responsive.spec.ts
import { test, expect } from "@playwright/test";

const breakpoints = [
  { name: "mobile", width: 375, height: 812 },
  { name: "tablet", width: 768, height: 1024 },
  { name: "desktop", width: 1440, height: 900 },
];

for (const bp of breakpoints) {
  test(`dashboard at ${bp.name}`, async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: bp.width, height: bp.height },
    });
    const page = await context.newPage();
    await page.goto("/dashboard");
    await page.waitForLoadState("networkidle");

    await expect(page).toHaveScreenshot(`dashboard-${bp.name}.png`, {
      maxDiffPixelRatio: 0.01,
    });

    await context.close();
  });
}
```

### Animation and font handling
```tsx
// tests/visual/utils.ts
import type { Page } from "@playwright/test";

export async function prepareForScreenshot(page: Page) {
  // Disable animations
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation-duration: 0s !important;
        animation-delay: 0s !important;
        transition-duration: 0s !important;
        transition-delay: 0s !important;
      }
    `,
  });

  // Wait for fonts
  await page.evaluate(() => document.fonts.ready);

  // Wait for images
  await page.waitForFunction(() => {
    const images = Array.from(document.querySelectorAll("img"));
    return images.every((img) => img.complete);
  });
}
```

### Component-level snapshot
```tsx
// tests/visual/components.spec.ts
import { test, expect } from "@playwright/test";
import { prepareForScreenshot } from "./utils";

test("button variants", async ({ page }) => {
  await page.goto("/storybook-iframe?id=ui-button--default");
  await prepareForScreenshot(page);

  const button = page.locator("button").first();
  await expect(button).toHaveScreenshot("button-default.png");
});
```

### Playwright config for visual tests
```tsx
// playwright.config.ts (add to existing)
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "tests",
  snapshotDir: "tests/__snapshots__",
  snapshotPathTemplate: "{snapshotDir}/{testFilePath}/{arg}{ext}",
  updateSnapshots: "missing",
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01,
      animations: "disabled",
    },
  },
  projects: [
    { name: "chromium", use: { browserName: "chromium" } },
  ],
});
```

### Update baselines
```bash
# Generate new baselines
npx playwright test --update-snapshots

# Review changed screenshots
npx playwright show-report
```

### CI integration with artifact upload
```yaml
# .github/workflows/visual-regression.yml
name: Visual Regression
on: pull_request

jobs:
  visual:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test tests/visual/
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: visual-diff
          path: test-results/
          retention-days: 7
```

## Anti-pattern

### Screenshot testing in every environment
Visual tests are flaky across OS/browser combinations due to font rendering differences.
Pin to a single browser (Chromium) and OS (Linux in CI) for deterministic results.

### Testing dynamic content
Don't screenshot pages with timestamps, random data, or live API responses. Use mocked
data and frozen timestamps for reproducible snapshots.

## Common Mistakes
- Not disabling animations — causes flaky diffs
- Missing font loading wait — text renders differently
- Baselines committed from wrong OS — diffs in CI
- No `maxDiffPixelRatio` threshold — single-pixel changes fail
- Not uploading artifacts on failure — can't review diffs

## Checklist
- [ ] Playwright configured for visual testing
- [ ] Baselines stored in `tests/__snapshots__`
- [ ] Responsive breakpoint tests (mobile, tablet, desktop)
- [ ] Animations disabled before screenshots
- [ ] Font loading awaited before capture
- [ ] CI uploads diff artifacts on failure
- [ ] `maxDiffPixelRatio` threshold set
- [ ] Baselines generated on CI environment (Linux)

## Composes With
- `testing` — extends Playwright E2E with visual assertions
- `shadcn` — visual regression for design system components
- `storybook` — component-level visual snapshots
- `deploy` — CI pipeline runs visual checks before merge
