# Install

Phase 0 is not a real installer. It supports dry-run and temp installation only.

## Dry-run

```bash
pnpm install:dry-run -- --profile full
```

This prints planned components and files.

## Temp install

```bash
pnpm install:temp
```

This copies selected files into `tests/tmp/install-temp` only.

## Real install

Real installation is intentionally out of scope for Phase 0.
