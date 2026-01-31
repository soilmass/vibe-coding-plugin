---
name: testing
description: >
  Testing with Vitest and Playwright — unit tests, component tests, Server Action tests, E2E flows, coverage configuration
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(npx vitest *), Bash(npx playwright *)
---

# Testing

## Purpose
Testing patterns with Vitest (unit/integration) and Playwright (E2E). Covers component testing,
Server Action testing, and E2E flows. The ONE skill for test quality.

## Project State
- Has Vitest: !`grep -q "vitest" package.json 2>/dev/null && echo "yes" || echo "no"`
- Has Playwright: !`grep -q "playwright" package.json 2>/dev/null && echo "yes" || echo "no"`

## When to Use
- Writing unit tests for utilities and Server Actions
- Testing React components with Vitest
- Writing E2E tests with Playwright
- Setting up test infrastructure

## When NOT to Use
- Type checking → `typescript-patterns` (tsc handles this)
- Security audits → `security`
- Performance testing → use Lighthouse or custom profiling

## Pattern

### Vitest unit test for Server Action
```tsx
// __tests__/actions/createPost.test.ts
import { describe, it, expect, vi } from "vitest";
import { createPost } from "@/actions/createPost";

vi.mock("@/lib/auth", () => ({
  auth: vi.fn(() => ({ user: { id: "user-1" } })),
}));

vi.mock("@/lib/db", () => ({
  db: { post: { create: vi.fn(() => ({ id: "post-1" })) } },
}));

describe("createPost", () => {
  it("creates a post with valid data", async () => {
    const formData = new FormData();
    formData.set("title", "Test Post");
    formData.set("content", "Content here");

    const result = await createPost({}, formData);
    expect(result.success).toBe(true);
  });

  it("rejects empty title", async () => {
    const formData = new FormData();
    formData.set("title", "");
    formData.set("content", "Content");

    const result = await createPost({}, formData);
    expect(result.error?.title).toBeDefined();
  });
});
```

### Playwright E2E test
```tsx
// e2e/auth.spec.ts
import { test, expect } from "@playwright/test";

test("login flow", async ({ page }) => {
  await page.goto("/login");
  await page.fill("[name=email]", "test@example.com");
  await page.fill("[name=password]", "password");
  await page.click("button[type=submit]");
  await expect(page).toHaveURL("/dashboard");
  await expect(page.getByText("Welcome")).toBeVisible();
});
```

### Vitest config
```tsx
// vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    setupFiles: ["./vitest.setup.ts"],
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
});
```

### Integration test for Server Components with Prisma mock
```tsx
// __tests__/integration/posts.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { db } from "@/lib/db";

vi.mock("@/lib/db", () => ({
  db: {
    post: {
      findMany: vi.fn(),
      create: vi.fn(),
      delete: vi.fn(),
    },
    $transaction: vi.fn(async (fn) => fn(db)),
  },
}));

describe("Post queries", () => {
  afterEach(() => {
    vi.restoreAllMocks(); // Clean up mocks between tests
  });

  it("fetches published posts with author", async () => {
    const mockPosts = [{ id: "1", title: "Test", author: { name: "Alice" } }];
    vi.mocked(db.post.findMany).mockResolvedValue(mockPosts);

    const posts = await db.post.findMany({
      where: { published: true },
      include: { author: { select: { name: true } } },
    });
    expect(posts).toHaveLength(1);
    expect(posts[0].author.name).toBe("Alice");
  });
});
```

### Testing error boundaries
```tsx
// __tests__/components/ErrorBoundary.test.tsx
import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import Error from "@/app/error";

describe("Error boundary", () => {
  it("renders error message and reset button", () => {
    const reset = vi.fn();
    const error = new Error("Something broke") as Error & { digest?: string };

    render(<Error error={error} reset={reset} />);
    expect(screen.getByText(/something went wrong/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /try again/i }));
    expect(reset).toHaveBeenCalledOnce();
  });
});
```

## Anti-pattern

```tsx
// WRONG: testing implementation details
it("calls setState with correct value", () => {
  const spy = vi.spyOn(React, "useState");
  render(<Counter />);
  // Testing implementation, not behavior!
});

// CORRECT: test behavior
it("increments count on click", () => {
  render(<Counter />);
  fireEvent.click(screen.getByText("Count: 0"));
  expect(screen.getByText("Count: 1")).toBeInTheDocument();
});

// WRONG: mocking too much — testing mocks, not code
vi.mock("@/lib/utils", () => ({ cn: vi.fn(() => "mocked") }));
vi.mock("@/components/ui/button", () => ({ Button: () => <button /> }));
// You're testing a hollow shell — nothing real executes

// WRONG: no test cleanup — database state leaks between tests
it("creates a user", async () => {
  await db.user.create({ data: { email: "test@test.com" } });
  // Never cleaned up! Next test may find this user unexpectedly.
});

// WRONG: brittle selectors in E2E tests
await page.click("div.flex.items-center > button:nth-child(3)");
// Breaks on any layout change

// CORRECT: use accessible selectors
await page.click("button[aria-label='Delete post']");
await page.getByRole("button", { name: "Submit" }).click();
```

Test what the user sees and does, not internal implementation.

## Common Mistakes
- Testing implementation details instead of behavior
- Not mocking auth/db in Server Action tests
- Missing `@` path alias in Vitest config
- Not using `waitFor` for async component updates
- Skipping E2E tests for critical user flows
- Mocking too much — you end up testing mocks, not real code
- No test data cleanup — state leaks between tests cause flaky failures
- Brittle CSS selectors in E2E — use accessible roles and labels instead
- Not testing error states — only testing the happy path

## Checklist
- [ ] Server Actions tested with mocked auth and db
- [ ] Component tests use behavior-based assertions
- [ ] E2E tests cover critical user flows (auth, CRUD)
- [ ] Vitest config has path aliases matching tsconfig
- [ ] CI runs both unit and E2E tests
- [ ] Error boundaries have tests for render and reset
- [ ] Tests clean up after themselves (`afterEach` / `afterAll`)
- [ ] E2E selectors use roles/labels, not CSS structure
- [ ] Integration tests mock at the boundary (db), not internals

## Composes With
- `react-server-actions` — test action validation and auth checks
- `react-forms` — test form submission behavior
- `deploy` — CI pipeline runs tests before deployment
- `turbo` — run tests across workspaces with Turborepo caching
- `logging` — test that actions log expected events
- `error-handling` — test error boundary rendering and recovery
- `database-seeding` — test factories reuse seed patterns for fixtures
- `storybook` — visual testing complements unit and E2E tests
- `feature-flags` — test behavior under different flag states
