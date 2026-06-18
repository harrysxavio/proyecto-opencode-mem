# Install

Hay dos familias de comandos:

## Overlay real por runtime

```bash
pnpm codex:install:dry-run --target ~/.codex
pnpm codex:install --target ~/.codex
pnpm opencode:install:dry-run --target ~/.config/opencode
pnpm opencode:install --target ~/.config/opencode
```

Estos comandos implementan backup, metadata, doctor y rollback.

## Perfiles de staging del repositorio

```bash
pnpm install:dry-run --profile full
pnpm install:temp --profile full
```

El comando genérico sólo muestra/copia perfiles dentro del repositorio para pruebas. No activa OpenCode ni Codex. Para uso real elige un instalador de runtime.