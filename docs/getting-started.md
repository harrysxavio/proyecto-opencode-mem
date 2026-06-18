# Guía de inicio

La instalación soportada está documentada en:

- [`../QUICKSTART_OPENCODE.md`](../QUICKSTART_OPENCODE.md)
- [`../QUICKSTART_CODEX.md`](../QUICKSTART_CODEX.md)

## Requisitos

Git, Node.js 20+, `pnpm` y al menos uno de los runtimes ya instalado y autenticado.

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
corepack enable
pnpm install
pnpm test:all
```

## Instalación real

```bash
# Codex
pnpm codex:install:dry-run --target ~/.codex
pnpm codex:install --target ~/.codex
pnpm codex:doctor --target ~/.codex

# OpenCode
pnpm opencode:install:dry-run --target ~/.config/opencode
pnpm opencode:install --target ~/.config/opencode
pnpm opencode:doctor --target ~/.config/opencode
```

Los perfiles de `opencode-kit.manifest.json` se usan para inventario y staging temporal, no para activar el overlay global.

El kit no instala runtimes, memoria, plugins, MCP, modelos ni credenciales. Lee [`../arquitectura.md`](../arquitectura.md) antes de habilitar integraciones externas.