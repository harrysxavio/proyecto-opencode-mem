# Codex Overlay Installer

## Qué hace

`codex/scripts/install-overlay.mjs` copia los componentes del Runtime Kit al directorio de configuración de Codex (`~/.codex` por defecto).

## Componentes que instala

| Origen | Destino |
|--------|---------|
| `codex/manager.template.md` | `<target>/AGENTS.md` |
| `skills/*/SKILL.md` | `<target>/skills/opencode-runtime-kit/*/SKILL.md` |
| `.atl/skill-registry.md` | `<target>/.atl/skill-registry.md` |
| Metadatos de instalación | `<target>/.opencode-kit/last-install.json` |

## Safety

1. **Nunca escribe en el directorio de la app**: valida que el target NO sea el directorio de instalación de OpenCode (`AppData/Local/Programs/OpenCode`).
2. **Backup automático**: antes de escribir, respalda los archivos existentes en `<target>/.opencode-kit-backups/<timestamp>/`.
3. **Dry-run primero**: siempre usa `--dry-run` para inspeccionar antes de instalar.
4. **Rollback**: `pnpm codex:rollback` restaura los backups.

## Flags

```
--target <path>   Directorio destino (default: ~/.codex)
--dry-run         Solo mostrar plan, no escribir
```

## Proceso

1. Valida target (no es directorio de la app).
2. Crea backup de archivos existentes.
3. Copia overlay files.
4. Escribe metadatos de instalación para rollback.

## Rollback

```bash
pnpm codex:rollback --target ~/.codex
```

Usa el último backup para restaurar. Si no hay backup disponible, reporta error.
