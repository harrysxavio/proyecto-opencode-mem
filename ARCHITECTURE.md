# Architecture

La explicación técnica y operativa mantenida está en [`arquitectura.md`](arquitectura.md).

Resumen:

- `contracts/` define comportamiento portable;
- `skills/` contiene procedimientos lazy-loaded;
- `opencode/` y `codex/` contienen Managers e instaladores específicos;
- los instaladores sólo escriben dentro de un `--target`, respaldan antes de sobrescribir y soportan rollback;
- memoria, MCP, plugins, modelos y subagentes son capacidades del runtime o integraciones externas: este kit no las instala.

Para comenzar usa [`QUICKSTART_OPENCODE.md`](QUICKSTART_OPENCODE.md) o [`QUICKSTART_CODEX.md`](QUICKSTART_CODEX.md).