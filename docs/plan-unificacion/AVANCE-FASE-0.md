# Avance Fase 0 — Merge y Restructura Base

**Qué busca esta fase**: Unificar las dos ramas (`master` + `codex/codex-first-runtime`) en una sola línea base con estructura clara: `contracts/` (compartido), `opencode/` + `codex/` (runtime-specific).

---

## Subfase 0.1 — Branch base

- **Creada**: `unified-architecture` desde `codex/codex-first-runtime`
- **Contiene**: Todo el contenido de master + 12 commits de Codex-first (skills, scripts, docs)
- **Estado**: ✅ Completada

## Subfase 0.2 — Directorios base

- Creación de estructura de directorios
- **Pendiente**: ...

## Subfase 0.3 — Movimiento de scripts Codex

- **Scripts**: 8 archivos de `scripts/` a `codex/scripts/`
- **Tests**: 9 archivos de `tests/` a `codex/tests/`
- **Templates**: `templates/codex/` → `codex/manager.template.md`
- **Script OpenCode**: `scripts/install-opencode-overlay.mjs` → `opencode/scripts/install-overlay.mjs`
- **Pendiente**: ...

## Subfase 0.4 — Actualización de imports

- Scripts Codex: imports de `./manifest-utils.mjs` → `../../scripts/manifest-utils.mjs`
- Tests Codex: imports de scripts movidos
- **Pendiente**: ...

## Subfase 0.5 — ARCHITECTURE.md

- Creación del documento maestro de arquitectura
- **Pendiente**: ...

## Subfase 0.6 — package.json y manifest

- Scripts de package.json para ambos runtimes
- Manifest actualizado con nuevas rutas
- **Pendiente**: ...

## Subfase 0.7 — Validación

- `pnpm test:all` pasa
- `pnpm validate` pasa
- `pnpm sanitize:check` pasa
- Tests Codex pasan
- **Pendiente**: ...

---

## Aportes de esta fase

- Estructura clara: shared vs runtime-specific
- Historial preservado (git mv)
- Base para fases siguientes
- Sin breaking changes: el runtime real no se toca

## Decisiones durante la fase

| Decisión | Opción | Elegida | Por qué |
|----------|--------|---------|---------|
| Branch base | master vs codex | codex/codex-first-runtime | Tiene todo el contenido de ambas ramas |
| Movimiento | copy+delete vs git mv | git mv | Preserva historial de archivos |
