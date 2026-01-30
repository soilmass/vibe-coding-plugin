---
name: database-seeding
description: >
  Prisma seed scripts and test data generation — @faker-js/faker, idempotent seeds with upsert, typed factories
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(npx prisma db seed *), Bash(npx tsx *)
---

# Database Seeding

## Purpose
Prisma seed scripts and test data generation. Covers `prisma/seed.ts` with `@faker-js/faker`,
idempotent seeds with upsert, and typed factories. The ONE skill for seed data management.

## Project State
- Has Prisma: !`test -d prisma && echo "yes" || echo "no"`
- Has Faker: !`grep -q "faker" package.json 2>/dev/null && echo "yes" || echo "no"`

## When to Use
- Setting up initial development data
- Creating seed scripts for new models
- Building typed factories for test data
- Resetting database to known state

## When NOT to Use
- Schema design or migrations → `prisma`
- Writing test assertions → `testing`
- Production data management → use Prisma migrations instead

## Pattern

### Seed script with factories
```tsx
// prisma/seed.ts
import { PrismaClient } from "@prisma/client";
import { faker } from "@faker-js/faker";

const prisma = new PrismaClient();

// Typed factory
function createUserData(overrides = {}) {
  return { email: faker.internet.email(), name: faker.person.fullName(), ...overrides };
}

async function main() {
  // Idempotent: upsert for known records
  const admin = await prisma.user.upsert({
    where: { email: "admin@example.com" },
    update: {},
    create: createUserData({ email: "admin@example.com", name: "Admin" }),
  });
  // Generate random records
  const users = await Promise.all(
    Array.from({ length: 10 }).map(() => prisma.user.create({ data: createUserData() }))
  );
  console.log(`Seeded: ${users.length + 1} users`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
```

### Package.json seed config
```json
{
  "prisma": {
    "seed": "npx tsx prisma/seed.ts"
  }
}
```

### Running seeds
```bash
# Run seed script
npx prisma db seed

# Reset and re-seed
npx prisma migrate reset
```

### Test-specific factory
```tsx
// src/lib/test-factories.ts
import { faker } from "@faker-js/faker";

export function buildUser(overrides = {}) {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    createdAt: new Date(),
    ...overrides,
  };
}

export function buildPost(overrides = {}) {
  return {
    id: faker.string.uuid(),
    title: faker.lorem.sentence(),
    content: faker.lorem.paragraphs(2),
    published: true,
    authorId: faker.string.uuid(),
    createdAt: new Date(),
    ...overrides,
  };
}
```

## Anti-pattern

```tsx
// WRONG: hardcoded test data without factories
async function seed() {
  await prisma.user.create({
    data: { email: "user1@test.com", name: "User 1" },
  });
  await prisma.user.create({
    data: { email: "user2@test.com", name: "User 2" },
  });
  // Tedious, not scalable, no variety
}

// WRONG: non-idempotent seeds (create duplicates on re-run)
await prisma.user.create({ data: { email: "admin@example.com" } });
// Crashes on second run: unique constraint violation!
```

## Common Mistakes
- Using `create` instead of `upsert` for known records (fails on re-run)
- Not adding `prisma.seed` config to `package.json`
- Hardcoding all test data instead of using Faker factories
- Forgetting `prisma.$disconnect()` and proper exit codes

## Checklist
- [ ] `prisma/seed.ts` exists with typed factories
- [ ] `package.json` has `prisma.seed` config
- [ ] Known records use `upsert` (idempotent)
- [ ] Factories use `@faker-js/faker` for variety
- [ ] Factory functions accept overrides for specific test cases
- [ ] Seed script disconnects Prisma client on completion
- [ ] Related records created in correct order (parent before child)

## Composes With
- `prisma` — seed scripts depend on Prisma schema
- `auth` — seed admin users with correct auth fields
- `testing` — test factories reuse seed patterns
