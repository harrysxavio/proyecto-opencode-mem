# Troubleshooting

## pnpm unavailable

Run:

```bash
corepack enable
```

If that fails, document the blocker. Do not silently switch package managers.

## Sanitizer fails

Read the reported file and pattern. Replace private values with placeholders or move synthetic dirty samples under `tests/fixtures/dirty/`.

## install-temp fails

Remove `tests/tmp` and rerun. Temp install must never write to a real home or OpenCode config path.
