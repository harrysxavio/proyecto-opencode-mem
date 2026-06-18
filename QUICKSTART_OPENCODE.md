# QuickStart — OpenCode Runtime

5 pasos para tener el Runtime Kit en OpenCode.

## 1. Clonar el repositorio

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
pnpm install
```

## 2. Validar el kit

```bash
pnpm validate
pnpm test:opencode
```

Ambos deben pasar sin errores.

## 3. Elegir perfil

Revisar los perfiles disponibles en `opencode-kit.manifest.json`:

- **full**: Manager detallado + SDD + skills + Engram + gates
- **gentle-alignment**: Solo documentación de alineación

```bash
pnpm validate  # Confirma que los perfiles resuelven
```

## 4. Usar el template Manager

El template está en `opencode/manager.template.md`. Copiarlo a tu AGENTS.md de OpenCode:

```bash
# Manual: copiar opencode/manager.template.md a ~/.config/opencode/AGENTS.md
# Siempre respaldar el AGENTS.md existente primero
```

O usar dry-run para ver el plan:

```bash
pnpm opencode:install:dry-run --target ~/.config/opencode
```

## 5. Validar la instalación

```bash
pnpm opencode:doctor --target ~/.config/opencode
```

Si pasa, OpenCode está listo con el Manager unificado.

## Comandos útiles

```bash
pnpm opencode:install:dry-run    # Simular instalación
pnpm opencode:doctor             # Validar instalación
pnpm test:all                    # Todos los tests
```

--- 

**Ver también**: [`ARCHITECTURE.md`](ARCHITECTURE.md) para entender los contratos y adaptadores.
