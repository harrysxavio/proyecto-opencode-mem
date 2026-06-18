# Destinos de instalación

## Destinos soportados por los instaladores

| Runtime | Target recomendado | Comando |
|---|---|---|
| Codex | `~/.codex` | `pnpm codex:install --target ~/.codex` |
| OpenCode | `~/.config/opencode` | `pnpm opencode:install --target ~/.config/opencode` |

En Windows, `~` representa el home del usuario; también puedes usar `$HOME` en PowerShell.

## Regla de seguridad

La instalación real requiere `--target`. El script sólo escribe dentro de esa ruta, crea backup y metadata de rollback. Nunca apuntes al directorio donde está instalado el ejecutable de la aplicación.

## Targets personalizados

Los scripts aceptan otro directorio para pruebas o configuración aislada:

```bash
pnpm opencode:install:dry-run --target ./tmp/opencode-config
pnpm codex:install:dry-run --target ./tmp/codex-config
```

Que un directorio acepte los archivos no significa que otro editor (Cursor, VS Code u otro cliente) los descubra. Esos destinos no están validados por este proyecto y requieren adaptación/documentación del producto correspondiente.

## Configuración por proyecto

Puedes usar un target dentro de un proyecto sólo si el runtime que utilizas documenta que carga ese directorio. El kit no modifica automáticamente configuración del proyecto ni variables de entorno.

## Verificación

Usa el mismo target para instalar, diagnosticar y revertir:

```bash
pnpm opencode:doctor --target ~/.config/opencode
pnpm opencode:rollback:dry-run --target ~/.config/opencode
```