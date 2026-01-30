## Summary

<!-- Brief description of what this PR does -->

## Changes

-

## Checklist

### Code Quality
- [ ] TypeScript compiles without errors (`npx tsc --noEmit`)
- [ ] ESLint passes (`npm run lint`)
- [ ] No `any` types introduced
- [ ] Server Actions validate input with Zod
- [ ] Server Actions check authentication and authorization

### Testing
- [ ] Unit tests added/updated for changed code
- [ ] E2E tests added for new user flows
- [ ] All tests pass (`npm run test`)

### Accessibility
- [ ] Interactive elements use semantic HTML (`<button>`, `<a>`)
- [ ] Form errors linked to inputs with `aria-describedby`
- [ ] New images have meaningful `alt` text

### Security
- [ ] No hardcoded secrets or API keys
- [ ] No `dangerouslySetInnerHTML` without sanitization
- [ ] Environment variables used for sensitive config

### Next.js 15 / React 19
- [ ] `params` and `searchParams` typed as `Promise` and awaited
- [ ] `fetch()` calls have explicit caching strategy
- [ ] Uses `useActionState` (not deprecated `useFormState`)
- [ ] Uses ref-as-prop (not `forwardRef`)

## Screenshots

<!-- If applicable, add screenshots or recordings -->

## Related Issues

<!-- Link related issues: Fixes #123, Closes #456 -->
