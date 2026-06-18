# QuickStart — OpenCode

## Resultado

Instala el Manager OpenCode y 18 skills dentro de tu configuración de usuario. No instala OpenCode, memoria, plugins ni proveedores externos.

## 1. Prerrequisitos

- OpenCode instalado y autenticado.
- Git, Node.js 20+ y `pnpm`.

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
corepack enable
pnpm install
pnpm test:all
```

## 2. Revisar sin escribir

```bash
pnpm opencode:install:dry-run --target ~/.config/opencode
```

Verás el Manager, registro, 18 skills y ruta de backup. El dry-run no crea archivos.

## 3. Instalar

Cierra OpenCode antes de cambiar su overlay.

```bash
pnpm opencode:install --target ~/.config/opencode
```

Se crean:

- `AGENTS.md`;
- `skills/opencode-runtime-kit/<skill>/SKILL.md`;
- `.atl/skill-registry.md`;
- `.opencode-kit/last-install.json`;
- `.opencode-kit-backups/<id>/`.

El target es obligatorio para una instalación real. El script rechaza el directorio administrado donde vive el ejecutable de OpenCode.

## 4. Validar

```bash
pnpm opencode:doctor --target ~/.config/opencode
```

El doctor comprueba el overlay local. No comprueba autenticación, Engram, MCP, Graphify, modelos ni subagentes.

## 5. Reiniciar y probar

Abre OpenCode y pregunta:

> ¿Qué contrato sigue el Manager y qué skills del Runtime Kit tienes disponibles?

Las funciones que dependan de integraciones externas sólo operarán si las configuraste por separado.

## Rollback

```bash
pnpm opencode:rollback:dry-run --target ~/.config/opencode
pnpm opencode:rollback --target ~/.config/opencode
```

Restaura destinos respaldados y elimina únicamente elementos creados por la última instalación.

## Solución rápida de problemas

- `Node >=20 required`: actualiza Node.
- `pnpm not found`: ejecuta `corepack enable`.
- `Missing ...`: repite instalación y doctor usando exactamente el mismo target.
- OpenCode no cambia: ciérralo y vuelve a abrirlo.
- Memoria no persiste: configura un backend compatible; el kit sólo instala gobernanza.

Lee la [arquitectura maestra](arquitectura.md) para conocer límites y responsabilidades.