# Codex Overlay Installer

`codex/scripts/install-overlay.mjs` instala el overlay dentro de un target de usuario explícito.

| Origen lógico | Destino |
|---|---|
| `codex/manager.template.md` | `<target>/AGENTS.md` |
| 18 `skills/*/SKILL.md` | `<target>/skills/opencode-runtime-kit/*/SKILL.md` |
| Registro generado desde frontmatter | `<target>/.atl/skill-registry.md` |
| Recibo | `<target>/.opencode-kit/last-install.json` |

## Seguridad

- `--target` es obligatorio para escritura real.
- Dry-run no escribe.
- Cada destino previo se respalda.
- Rollback valida rutas y restaura usando el recibo.
- No se instalan Codex, memoria, conectores ni servicios externos.

```bash
pnpm codex:install:dry-run --target ~/.codex
pnpm codex:install --target ~/.codex
pnpm codex:doctor --target ~/.codex
pnpm codex:rollback:dry-run --target ~/.codex
pnpm codex:rollback --target ~/.codex
```