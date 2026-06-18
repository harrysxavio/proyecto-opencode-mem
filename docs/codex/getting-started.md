# Getting Started — Codex Runtime

5 pasos para tener el Runtime Kit funcionando en Codex.

## 1. Clonar el repositorio

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
pnpm install
```

## 2. Validar el kit

```bash
pnpm validate
pnpm test:codex
```

Ambos deben pasar sin errores.

## 3. Dry-run del overlay

Simula la instalación sin escribir archivos:

```bash
pnpm codex:install:dry-run --target ~/.codex
```

Revisa la lista de archivos que se copiarán. El dry-run nunca escribe nada.

## 4. Instalar el overlay

Cuando estés listo:

```bash
pnpm codex:install --target ~/.codex
```

Esto copia:
- `codex/manager.template.md` → `<target>/AGENTS.md`
- Skills portables → `<target>/skills/opencode-runtime-kit/`
- Registry de skills → `<target>/.atl/skill-registry.md`

Siempre hace backup previo en `<target>/.opencode-kit-backups/`.

## 5. Validar la instalación

```bash
pnpm codex:doctor --target ~/.codex
```

Si pasa, el overlay está listo. Codex usará el Manager template y skills portables en adelante.

## Rollback si algo sale mal

```bash
pnpm codex:rollback --target ~/.codex
```

## Comandos útiles

```bash
pnpm codex:memory:lint           # Validar archivos de memoria
pnpm codex:context:check         # Validar context packs
pnpm codex:tokens:report         # Reporte de tokens
pnpm codex:registry              # Generar registry de skills
```
