# Troubleshooting — Codex Runtime

## "CODEX DOCTOR FAIL — Missing AGENTS.md"

El overlay no se instaló o el target no es correcto.

```bash
pnpm codex:install:dry-run --target ~/.codex
pnpm codex:install --target ~/.codex
pnpm codex:doctor --target ~/.codex
```

## "AGENTS.md exceeds 32 KiB"

El Manager template se agrandó demasiado. Revisar si hay contenido duplicado o si los gates deberían separarse en archivos lazy-loaded.

## "AGENTS.md contains Windows absolute path"

El template tiene una ruta absoluta Windows. Editar `codex/manager.template.md` y reemplazar por rutas relativas o portables.

## "skill registry missing manager-router"

El registry de skills no incluye `manager-router`. Regenerar:

```bash
pnpm codex:registry
```

## "Codex overlay install failed: Refusing update-managed..."

Estás intentando instalar en el directorio de la aplicación OpenCode. Usa `~/.codex` o `~/.config/opencode` en su lugar.

```bash
pnpm codex:install --target ~/.codex
```

## Test falla después de mover archivos

Si moviste scripts o templates, los imports relativos pueden romperse:

```bash
pnpm test:codex
```

Si falla, revisar:
- imports de `repoRoot` apuntan a `../../scripts/manifest-utils.mjs` (desde `codex/`).
- overlayFiles en `install-overlay.mjs` tiene rutas correctas post-move.

## "node --test" no encuentra los tests

```bash
pnpm test:codex     # Tests específicos Codex
pnpm test:opencode  # Tests específicos OpenCode
pnpm test:all       # Todos los tests
```

## Rollback no funciona

Si no hay backup disponible (`.opencode-kit-backups/` vacío o no existe), el rollback no puede restaurar. En ese caso, reinstalar manualmente:

```bash
pnpm codex:install --target ~/.codex
```

## Error de permisos al instalar

El instalador necesita permisos de escritura en el target. En Windows, asegúrate de que el directorio no sea de solo lectura.
