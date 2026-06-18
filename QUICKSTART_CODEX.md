# QuickStart — Codex

## Resultado

Instala el Manager Codex y 18 skills dentro de tu configuración de usuario. No instala Codex, memoria, conectores, MCP ni modelos.

## 1. Prerrequisitos

- Codex instalado y autenticado.
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
pnpm codex:install:dry-run --target ~/.codex
```

El dry-run muestra cada destino y el backup previsto sin crear archivos.

## 3. Instalar

Cierra Codex antes de cambiar su overlay.

```bash
pnpm codex:install --target ~/.codex
```

Se crean:

- `AGENTS.md`;
- `skills/opencode-runtime-kit/<skill>/SKILL.md`;
- `.atl/skill-registry.md`;
- `.opencode-kit/last-install.json`;
- `.opencode-kit-backups/<id>/`.

El target es obligatorio para una instalación real.

## 4. Validar

```bash
pnpm codex:doctor --target ~/.codex
```

El doctor comprueba el overlay local y rutas del registro. No comprueba autenticación, memoria, conectores o servicios externos.

## 5. Reiniciar y probar

Abre Codex y pregunta:

> ¿Qué contrato sigue el Manager y qué skills del Runtime Kit tienes disponibles?

Codex usará memoria, tools o agentes sólo si tu entorno los expone. El overlay no los crea.

## Rollback

```bash
pnpm codex:rollback:dry-run --target ~/.codex
pnpm codex:rollback --target ~/.codex
```

Restaura destinos respaldados y elimina únicamente elementos creados por la última instalación.

## Herramientas del repositorio

Estos comandos se ejecutan desde el clon; no se copian al target:

```bash
pnpm codex:memory:lint
pnpm codex:context:check
pnpm codex:tokens:report
pnpm codex:registry
pnpm test:codex
```

Lee la [arquitectura maestra](arquitectura.md) para conocer límites y responsabilidades.