# Phase 1.1 — Documentation Accuracy Audit

> **Date:** 2026-06-17
> **Scope:** README.md + 6 docs creadas en Phase 1 + scripts/docs-check.mjs + tests
> **Method:** Manual review against Phase 1.1 requirements

---

## Summary

| Metric | Value |
|---|---|
| Files reviewed | 9 |
| Must fix now | 18 |
| Should fix now | 4 |
| Can defer | 0 |

---

## Must fix now

### R1. Badge CI apunta a repo incorrecto

**File:** `README.md:8`
**Current:** `https://github.com/harry/opencode-kit/actions/workflows/validate.yml/badge.svg`
**Fix:** `https://github.com/harrysxavio/proyecto-opencode-mem/actions/workflows/validate.yml/badge.svg`
**Riesgo:** Badge roto para cualquier lector del repo.
**Principiante:** ❌ Sí — un badge roto resta confianza.

### R2. Quickstart usa repo y carpeta incorrectos

**File:** `README.md:283-286`
**Current:** `git clone https://github.com/tu-usuario/opencode-kit.git` + `cd opencode-kit`
**Fix:** `git clone https://github.com/harrysxavio/proyecto-opencode-mem.git` + `cd proyecto-opencode-mem`
**Riesgo:** El comando no funciona.
**Principiante:** ❌ Sí — el primer comando del README debe funcionar.

### R3. Mismo problema en getting-started.md

**File:** `docs/getting-started.md:62` y `:257`
**Current:** `github.com/tu-usuario/opencode-kit.git` + `cd opencode-kit`
**Fix:** Ídem R2.
**Riesgo:** Ídem R2.
**Principiante:** ❌ Sí.

### R4. Phase 1 marcada "En curso" — debe ser "Completada"

**Files:**
- `README.md:362`
- `docs/phase-roadmap.md:10` y `:151`
- `docs/PHASE-1-INSTALL-UX-REPORT.md` (implícito como reporte final)
**Current:** `🔄 En curso`
**Fix:** `✅ Completada`
**Nota:** Phase 1.1 es una fase correctiva posterior.
**Riesgo:** Confunde sobre el estado real del proyecto.
**Principiante:** ❌ Sí.

### R5. `pnpm rollback` mencionado pero no existe

**File:** `README.md:341`, `docs/safety-and-sanitization.md:196,291`
**Current:** `pnpm rollback`
**Fix:** `pnpm rollback:plan` (aclarar que es plan-only, no ejecución real)
**Riesgo:** Usuario ejecuta `pnpm rollback` y falla.
**Principiante:** ❌ Sí.

### R6. `pnpm backup` mencionado pero no existe

**File:** `README.md` (inferido de rollback), `docs/safety-and-sanitization.md:169,222,290`
**Current:** `pnpm backup`
**Fix:** `pnpm backup:plan`
**Riesgo:** Ídem R5.
**Principiante:** ❌ Sí.

### R7. Ponytail suena a plugin automático activo

**File:** `README.md:216-226` — "Ponytail se aplica automáticamente"
**Current:** Da a entender que es un plugin operativo que se activa solo.
**Fix:** Dejar claro que es guidance/template, no plugin por defecto, no enforcement runtime.
**Riesgo:** Usuario cree que Ponytail ya está activo y monitorizando su código.
**Principiante:** ❌ Sí.

### R8. gentle-ai suena a runtime obligatorio

**File:** `README.md:233-250` — "en cada interacción", "directivas que el asistente debe seguir"
**Current:** Parece un sistema activo, no alignment-only.
**Fix:** Reformular como alignment-only: referencia conceptual, no runtime, no incluido en full.
**Riesgo:** Usuario cree que gentle-ai runtime ya está instalado.
**Principiante:** ❌ Sí.

### R9. Compatibilidad OpenCode afirma "probada" sin evidencia

**File:** `README.md:438-441`
**Current:** ✅ Compatible (probada) para 1.2.x
**Fix:** Cambiar a "Esperada" / "Validada por templates" / "Pendiente de prueba cross-machine"
**Riesgo:** Afirmación falsa si no se probó realmente.
**Principiante:** 🟡 Medio.

### R10. Links de comunidad apuntan a tu-usuario/opencode-kit

**File:** `README.md:492-494`
**Current:** `github.com/tu-usuario/opencode-kit/issues`, `/discussions`
**Fix:** Usar `github.com/harrysxavio/proyecto-opencode-mem/issues` o eliminar si no existen.
**Riesgo:** Links rotos.
**Principiante:** ❌ Sí.

### R11. installation-targets.md referencia `opencode-kit/templates`

**File:** `docs/installation-targets.md:196`
**Current:** `cp -r opencode-kit/templates /ruta/mi-config/`
**Fix:** `cp -r proyecto-opencode-mem/templates /ruta/mi-config/`
**Riesgo:** Path incorrecto.
**Principiante:** ❌ Sí.

### R12. README sin cajas "Qué puedes hacer hoy" / "Qué todavía NO puedes hacer"

**File:** `README.md`
**Current:** No hay.
**Requirement:** Phase 1.1 pide ambas cajas visibles.
**Riesgo:** Principiante no sabe qué esperar del kit.
**Principiante:** ❌ Sí.

### R13. Uninstall referencia `opencode-kit` en lugar de `proyecto-opencode-mem`

**File:** `README.md:455`
**Current:** `rm -rf opencode-kit`
**Fix:** `rm -rf proyecto-opencode-mem`
**Riesgo:** No borra la carpeta correcta.
**Principiante:** ❌ Sí.

### R14. docs-check no detecta placeholders de repo

**File:** `scripts/docs-check.mjs`
**Current:** No verifica `tu-usuario`, `opencode-kit` (como repo), `harrysxavio` incorrecto.
**Fix:** Agregar patterns para detectar `tu-usuario`, `github.com/harry/opencode-kit`, `github.com/tu-usuario/opencode-kit`, `cd opencode-kit`, `pnpm rollback` (sin `:plan`), claims falsos.
**Riesgo:** Los placeholders volverán a aparecer en el futuro.
**Principiante:** 🟡 Medio.

### R15. tests/docs-check.test.mjs no cubre placeholders

**File:** `tests/unit/docs-check.test.mjs`
**Current:** Solo cubre docs existentes y paths absolutos.
**Fix:** Agregar tests para placeholders de repo, comandos correctos, Ponytail/gentle-ai claims.
**Riesgo:** Misma fuga que R14.
**Principiante:** 🟡 Medio.

---

## Should fix now

### S1. safety-and-sanitization.md dice "Siempre hay un comando de rollback"

**File:** `docs/safety-and-sanitization.md:16`
**Current:** "Siempre hay un comando de rollback disponible"
**Fix:** Aclarar que es `rollback:plan` (plan-only, no ejecución real).
**Riesgo:** Falsa sensación de seguridad.
**Principiante:** ❌ Sí.

### S2. Phase 1.1 no reflejada en phase-roadmap.md

**File:** `docs/phase-roadmap.md`
**Current:** Solo muestra Phase 0-4.
**Fix:** Agregar Phase 1.1 como fase correctiva documental.
**Riesgo:** Bajo — no afecta uso.
**Principiante:** 🟡 Medio.

### S3. safety-and-sanitization.md dice `pnpm backup` en checklist

**File:** `docs/safety-and-sanitization.md:222`
**Current:** "Hacé backup antes de cambios grandes — `pnpm backup` es rápido"
**Fix:** `pnpm backup:plan`
**Riesgo:** Bajo — el comando falla pero no daña.
**Principiante:** ❌ Sí.

### S4. README mention de `cd opencode-kit` en desinstalación

**File:** `README.md:455`
**Current:** `rm -rf opencode-kit` (mencionado ya en R13 como must fix)
**Status:** Ya cubierto por R13.
**Principiante:** ❌ Sí.

---

## Audit summary

| Archivo | Must fix | Should fix | Total |
|---|---|---|---|
| `README.md` | 10 | 1 | 11 |
| `docs/getting-started.md` | 1 | 0 | 1 |
| `docs/profiles.md` | 0 | 0 | 0 |
| `docs/installation-targets.md` | 1 | 0 | 1 |
| `docs/safety-and-sanitization.md` | 2 | 3 | 5 |
| `docs/phase-roadmap.md` | 1 | 1 | 2 |
| `docs/PHASE-1-INSTALL-UX-REPORT.md` | 1 | 0 | 1 |
| `scripts/docs-check.mjs` | 1 | 0 | 1 |
| `tests/unit/docs-check.test.mjs` | 1 | 0 | 1 |
| **Total** | **18** | **5** | **23** |
