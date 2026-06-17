# Testing

Use Node core test runner and pnpm scripts.

```bash
pnpm doctor
pnpm validate
pnpm sanitize:check
pnpm test
pnpm test:all
pnpm install:dry-run -- --profile full
pnpm install:temp
```

## Coverage goals

- Manifest validity.
- Required profile existence.
- Boundary checks for gentle-ai and Ponytail.
- SDD template markers.
- Engram template safety.
- Sanitizer dirty and clean fixtures.
- Dry-run and temp install behavior.
