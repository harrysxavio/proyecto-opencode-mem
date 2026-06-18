# Phase 2A â€” Runtime Parity Inventory: Reporte Final

> **Veredicto:** âœ… PHASE 2A RUNTIME PARITY INVENTORY PASS
> **Fecha:** 2026-06-17

---

## 1. Resumen ejecutivo

Se completÃ³ la auditorÃ­a read-only del runtime real de OpenCode. Se identificaron **76 componentes** runtime, se clasificaron en **22 `must-have`**, **3 `should-have`**, **25 `optional`**, **3 `docs-only`** y **6+ `exclude`**. Se definiÃ³ el plan de importaciÃ³n por **9 slices** (A â†’ I) con sanitizaciÃ³n, tests y validaciones.

Los artefactos producidos:

| Archivo | PropÃ³sito |
|---|---|
| `PHASE-2A-RUNTIME-PARITY-INVENTORY.md` | Inventario completo de los 76 componentes runtime |
| `PHASE-2A-RUNTIME-PARITY-DEFINITION.md` | DefiniciÃ³n de "funcionar como mi OpenCode" |
| `PHASE-2A-IMPORT-DECISION-PACKAGE.md` | Decisiones de importaciÃ³n, riesgos, tests, prioridades |

---

## 2. Validaciones realizadas

| # | ValidaciÃ³n | Resultado |
|---|---|---|
| âœ… V1 | Clasificaciones contabilizadas correctamente | PASS â€” 34 must-have marks verificados (22 Ãºnicos), 3 should-have, 25 optional, 3 docs-only, 12 exclude marks |
| âœ… V2 | Sin paths personales en contenido de Phase 2A que no sean referencias documentadas | PASS â€” 6 menciones de `<USER_HOME>\\...`, todas son documentaciÃ³n legÃ­tima de quÃ© sanitizar |
| âœ… V3 | Cross-references entre los 3 artefactos | PASS â€” cada archivo referencia a los otros. Definition cita criteria del inventory. Decision package cita slices del inventory |
| âœ… V4 | Consistency inventario â†” decision package | PASS â€” clasificaciones alineadas. Inconsistencia `should-have` corregida de 5â†’3 |
| âœ… V5 | Gentle-ai external classification | PASS â€” no es runtime obligatorio, es docs-only. `background-agents` es should-have con dependencia documentada |
| âœ… V6 | Ponytail reconciliation | PASS â€” Code Gate presente en AGENTS.md, plugin NO instalado, skills NO instalados. Sin cambios |
| âœ… V7 | 23 tests definidos para Phase 2C | PASS â€” lista completa en decision package |

---

## 3. ClasificaciÃ³n resumen

| ClasificaciÃ³n | Cantidad | Componentes clave |
|---|---|---|
| **must-have** | 22 | Manager, AGENTS.md, opencode config, gentle-orchestrator, 10 SDD subagentes, 10 SDD skills + Engram plugin + 4 skills core (judgment-day, skill-creator, skill-improver, skill-registry, engram-agent) + Noise Gate + F4B + F4C + Ponytail Code Gate |
| **should-have** | 3 | background-agents, find-skills, frontend-specialist |
| **optional** | 25 | Skills diseÃ±o (canvas, design-md), skills utilidad (deploy, sandbox, web-design), skills domain (bigquery, sql, go, playwright), agentes adicionales, model-variants, etc |
| **docs-only** | 3 | Engram Go binary doc, gentle-ai external alignment, codex-primary-runtime |
| **exclude** | 6+ | Engram DB, Codex memories, logs, backups, secrets, .system, Ponytail plugin/skills |

---

## 4. Plan de importaciÃ³n (Phase 2B â†’ 2C)

```
Phase 2B â€” ImportaciÃ³n por 9 slices:
  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
  â”‚ A  â†’  B  â†’  C  â†’  D  â†’  E  â†’  F  â†’  G  â†’  H  â†’  I  â”‚
  â”‚ AG   cfg    SDD   g-o   Eng   ski   plg   agt   Pon  â”‚
  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜

  A: AGENTS.md template sanitizado
  B: opencode template config (opencode.template.jsonc)
  C: 10 SDD skills sdd-* sanitizadas
  D: gentle-orchestrator template doc
  E: Engram plugin sanitizado (âš ï¸ mÃ¡s riesgoso)
  F: Skills core (judgment-day, skill-creator, etc.)
  G: background-agents + model-variants
  H: frontend-specialist + agentes adicionales
  I: Ponytail verification pass

Phase 2C â€” 23 validaciones:
  1-23 tests runtime-parity (desde validaciÃ³n de TS hasta
  ausencia de paths personales y presencia de todos los
  componentes must-have)
```

---

## 5. Riesgos identificados

| Riesgo | Nivel | MitigaciÃ³n |
|---|---|---|
| Engram sanitizado rompe funcionalidad | ðŸ”´ Alto | TypeScript compile check + test unitario |
| Config de 64KB tiene paths residuales | ðŸŸ¡ Medio | Script de validaciÃ³n busca `<WINDOWS_USER_HOME>\\` |
| background-agents depende de gentle-ai y falla | ðŸŸ¡ Medio | DocumentaciÃ³n clara + graceful fallback |
| SDD skills pierden contexto al sanitizar | ðŸŸ¢ Bajo | Preservar SKILL.md completo, solo reemplazar paths |

---

## 6. Siguiente paso

Phase 2B: implementar importaciÃ³n por slices.

> **Â¿AprobÃ¡s este inventario para pasar a Phase 2B (importaciÃ³n por slices)?**

---

*Fin de PHASE-2A-REPORT.md*

