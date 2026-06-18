# Phase 2A â€” Runtime Parity Definition

> **PropÃ³sito:** Definir quÃ© significa "funcionar como mi OpenCode" para el perfil `runtime-parity`.
> **Fecha:** 2026-06-17

---

## 1. DefiniciÃ³n

Un OpenCode instalado desde el perfil `runtime-parity` de `proyecto-opencode-mem` debe poder:

> **Funcionar como mi OpenCode, pero sin mis datos privados.**

Es decir: misma arquitectura, mismos agentes, mismas skills, misma configuraciÃ³n portable, misma memoria governance â€” pero con memoria vacÃ­a, sin secretos, sin rutas personales, sin logs, sin backups.

---

## 2. Criterios funcionales obligatorios

| # | Criterio | VerificaciÃ³n |
|---|---|---|
| 1 | **Manager arranca como primary**, no compite con otros agentes | `opencode.json` agent.manager.mode = primary |
| 2 | **AGENTS.md sanitizado se carga** con Manager routing, SDD workflow, Ponytail guidance, Engram governance, gentle-ai alignment | Template existe, no contiene paths personales |
| 3 | **Config OpenCode portable se puede usar** â€” paths relativos o placeholders, sin rutas absolutas | `opencode.template.jsonc` es parseable, no contiene `<WINDOWS_USER_HOME>\\` |
| 4 | **10 SDD subagents son discoverables** como mode: subagent, hidden: true | `opencode.template.jsonc` incluye los 10 `sdd-*` agents |
| 5 | **`sdd-init` funciona como entry point** del pipeline SDD, produce SDD_INIT_PACKET | SKILL.md contiene SDD_INIT_PACKET |
| 6 | **`gentle-orchestrator` local estÃ¡ disponible** si corresponde al routing actual | Template config existe, documentado como subagent local, no como gentle-ai externo |
| 7 | **Engram plugin puede cargarse** sin errores de path | Tipo TypeScript vÃ¡lido, placeholders reemplazables |
| 8 | **Engram usa `${ENGRAM_DB_PATH}`** â€” ruta configurable, no hardcodeada | Plugin contiene placeholder, no path real |
| 9 | **Puede iniciar con DB vacÃ­a** o crear DB nueva al arrancar | Plugin no requiere DB preexistente |
| 10 | **mem_context / mem_search / mem_save / mem_session_summary estÃ¡n disponibles** si el plugin Engram los expone | Plugin exporta las 12+ herramientas Engram |
| 11 | **Noise Gate estÃ¡ activo** â€” clasifica prompts antes de capturarlos | Plugin contiene clasificaciÃ³n Noise Gate |
| 12 | **F4B/F4C estÃ¡n presentes** como guidance en plugin | Plugin contiene F4B RECENT_SESSION_PACK y F4C Memory Context Selector |
| 13 | **Skills reales sanitizadas estÃ¡n disponibles** en las rutas configuradas | `runtime/skills/` contiene los skills importados |
| 14 | **Ponytail Code Gate estÃ¡ presente como guidance** en AGENTS template | Template contiene secciÃ³n Ponytail, sin plugin |
| 15 | **No hay memorias reales** â€” no se copia `~/.engram/engram.db` | Test verifica ausencia de DB real |
| 16 | **No hay secretos** â€” sanitize check pasa sin tokens/credentials | `pnpm sanitize:check` pasa |
| 17 | **No hay rutas personales** â€” no hay `<USER_HOME>\\...` | Test verifica ausencia de paths personales |
| 18 | **gentle-ai externo no es dependencia runtime obligatoria** | Profile no instala gentle-ai, no reference en opcode config |
| 19 | **Sandbox install no toca HOME real** â€” solo escribe en `tests/tmp/` | `install:temp` no escribe fuera de tests/tmp |
| 20 | **Tests de paridad pasan** â€” 23+ tests de runtime-parity | `pnpm test` incluye runtime tests |

---

## 3. Lo que NO significa "funcionar como mi OpenCode"

| No significa | ExplicaciÃ³n |
|---|---|
| Tener mis memorias | La DB Engram no se copia. El usuario nuevo empieza con memoria vacÃ­a. |
| Tener mis secretos | API keys, tokens, credenciales no se exportan. |
| Tener mis rutas | `<USER_HOME>\\...` se reemplaza por placeholders. |
| Tener mis logs | Archivos de log no se copian. |
| Tener gentle-ai externo | No se instala gentle-ai como runtime. |
| Tener Ponytail plugin | No estÃ¡ instalado en runtime real, no se incluye. |
| Ser idÃ©ntico byte a byte | Es una copia funcional sanitizada, no un clone. |

---

## 4. Audiencia objetivo

| Perfil de usuario | QuÃ© recibe |
|---|---|
| Nuevo usuario de OpenCode | Un OpenCode funcional con Manager, SDD, memoria, skills â€” listo para usar |
| Usuario que migra desde Codex | Misma arquitectura, sin datos legacy |
| Desarrollador que quiere mi setup | Misma config, mismos agentes, sin mis datos privados |
| Contribuidor del kit | Un entorno reproducible para desarrollar y testear |

---

## 5. Comparativa: template kit vs runtime parity

| DimensiÃ³n | `full` (Phase 1) | `runtime-parity` (Phase 2) |
|---|---|---|
| Manager | Template de ejemplo | Prompt real sanitizado |
| AGENTS.md | Template de ejemplo | AGENTS.md real sanitizado |
| SDD agents | Templates con estructura genÃ©rica | Skills reales con frontmatter real |
| Engram | Template conceptual `.ts` | Plugin real sanitizado con 12+ tools |
| gentle-orchestrator | âŒ No existe | âœ… Template de config + doc |
| Skills | âŒ Solo estructura de directorios | âœ… Skills reales importados |
| Plugins adicionales | âŒ No existen | âœ… background-agents, model-variants (opcional) |
| Agentes adicionales | âŒ No existen | âœ… frontend-specialist, etc (opcional) |
| InstalaciÃ³n | Dry-run + temp | Dry-run + temp + plan para future local |
| Memoria | No aplica | Engram plugin funcional, DB vacÃ­a |

---

*Fin de PHASE-2A-RUNTIME-PARITY-DEFINITION.md*

