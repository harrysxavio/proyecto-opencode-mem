# Agent Templates

| Archivo | Runtime | Propósito |
|---|---|---|
| `opencode/manager.template.md` | OpenCode | Manager detallado con rutas SDD y gates condicionales |
| `codex/manager.template.md` | Codex | Manager compacto con skills y Context Packs |
| `contracts/manager.md` | Ambos | Contrato portable |

Instalación: `pnpm opencode:install --target <path>` o `pnpm codex:install --target <path>`. Los templates pueden mencionar capacidades externas, pero el instalador no las descarga.