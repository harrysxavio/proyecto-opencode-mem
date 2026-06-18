# Phase 2A â€” Import Decision Package

> **PropÃ³sito:** Clasificar cada componente runtime y decidir quÃ©, cÃ³mo y cuÃ¡ndo importarlo.
> **Fecha:** 2026-06-17
> **Basado en:** PHASE-2A-RUNTIME-PARITY-INVENTORY.md + auditorÃ­a read-only

---

## 1. Decisiones generales

### D1. Orden de importaciÃ³n por slices

Las importaciones deben hacerse en este orden, cada una como gate independiente:

```
Slice A: AGENTS.md template sanitizado
  â†’ Slice B: opencode template config sanitizado
    â†’ Slice C: SDD subagents (skills) â€” los 10 sdd-*
      â†’ Slice D: gentle-orchestrator template
        â†’ Slice E: Engram plugin sanitizado (el mÃ¡s complejo)
          â†’ Slice F: Skills no-SDD
            â†’ Slice G: Otros plugins (background-agents, model-variants)
              â†’ Slice H: Agentes adicionales
                â†’ Slice I: Ponytail check (confirm sin cambios)
```

**RazÃ³n:** Cada slice depende del anterior. No importar skills sin tener config. No importar Engram sin tener la infraestructura de plugins.

### D2. `must-have` primero, `should-have` despuÃ©s, `optional` al final

Phase 2B importa solo `must-have` + `should-have`. Phase 2C valida. Si pasa, discusiÃ³n sobre `optional`.

### D3. No duplicar skills

Skills que existen en `.config/opencode/skills/` Y `.codex/skills/`: usar `.config/opencode/skills/` como fuente primaria. No importar la versiÃ³n `.codex/`.

### D4. Skills .config/opencode/skills/ como fuente Ãºnica, no .codex/

La plataforma OpenCode descubre skills desde `.config/opencode/skills/`. La ruta `.codex/skills/` es legacy de Codex. Usar `.config/` como Ãºnica fuente de verdad.

---

## 2. Decisiones por slice

### Slice A â€” AGENTS.md

| DecisiÃ³n | Valor |
|---|---|
| **Â¿Importar?** | âœ… SÃ­, `must-have` |
| **Fuente** | `~/.config/opencode/AGENTS.md` (16KB) |
| **SanitizaciÃ³n** | Reemplazar paths personales por placeholders. Preservar completo: Manager routing + SDD workflow + Ponytail Code Gate + Engram governance + Noise Gate + mem_context + gentle-ai alignment-only + GPT fallback |
| **Destino** | `runtime/opencode/AGENTS.template.md` |
| **Tests** | `contains Manager routing`, `contains SDD workflow`, `contains Ponytail guidance`, `no personal paths`, `contains Engram governance` |
| **Riesgo** | Bajo â€” es un archivo markdown, no tiene lÃ³gica ejecutable |

### Slice B â€” opencode config

| DecisiÃ³n | Valor |
|---|---|
| **Â¿Importar?** | âœ… SÃ­, `must-have` |
| **Fuente** | `~/.config/opencode/opencode.json` (64KB) |
| **SanitizaciÃ³n** | Reemplazar todos los paths absolutos. Cambiar `"<USER_HOME_ESCAPED>\\..."` por `${OPENCODE_KIT_DIR}/runtime/...`. Reemplazar `"dbPath"` por `${ENGRAM_DB_PATH}`. Quitar referencias a gentle-ai externo. Preservar: Manager primary, 10 SDD subagents, Engram plugin reference, agent definitions, tools, MCP servers |
| **Formato destino** | JSONC (JSON con comentarios) para portabilidad: `runtime/opencode/opencode.template.jsonc` |
| **Tests** | `is valid JSONC`, `no absolute paths`, `contains Manager primary`, `contains 10 sdd-* agents`, `contains Engram plugin reference`, `no gentle-ai external reference` |
| **Riesgo** | Medio â€” 64KB, muchos paths. Requiere sanitizaciÃ³n cuidadosa |

### Slice C â€” SDD subagents (skills)

| DecisiÃ³n | Valor |
|---|---|
| **Â¿Importar?** | âœ… SÃ­, must-have. Los 10 sdd-*. |
| **Fuente** | `~/.config/opencode/skills/sdd-init/`, `sdd-explore/`, `sdd-propose/`, `sdd-spec/`, `sdd-design/`, `sdd-tasks/`, `sdd-apply/`, `sdd-verify/`, `sdd-archive/`, `sdd-onboard/` |
| **SanitizaciÃ³n** | Quitar paths personales. Preservar SKILL.md entero (es la instrucciÃ³n del subagente) |
| **Destino** | `runtime/skills/sdd-*/SKILL.md` |
| **Tests** | `frontmatter vÃ¡lido`, `triggers presentes`, `no paths personales`, `contiene instrucciones completas` |
| **Riesgo** | Bajo â€” skills markdown, no ejecutable |

### Slice D â€” gentle-orchestrator

| DecisiÃ³n | Valor |
|---|---|
| **Â¿Importar?** | âœ… SÃ­, `must-have` |
| **Fuente** | `opencode.json` (la definiciÃ³n del subagente agent.gentle-orchestrator) |
| **SanitizaciÃ³n** | Quitar paths. Preservar definiciÃ³n de subagente, prompt, tools. No referenciar gentle-ai externo |
| **Destino** | `runtime/integrations/gentle/gentle-orchestrator.template.md` |
| **Tests** | `definiciÃ³n de subagente presente`, `no referencia gentle-ai externo`, `contiene routing` |
| **Riesgo** | Bajo â€” es documentaciÃ³n + template config |

### Slice E â€” Engram plugin (el mÃ¡s crÃ­tico)

| DecisiÃ³n | Valor |
|---|---|
| **Â¿Importar?** | âœ… SÃ­, `must-have` |
| **Fuente** | `~/.config/opencode/plugins/engram.ts` (~800+ lÃ­neas?) |
| **SanitizaciÃ³n** | Reemplazar `ENGRAM_BIN = "${ENGRAM_BIN}"` por `${ENGRAM_BIN}` o placeholder binario. Reemplazar `DEBUG_LOG = "<WINDOWS_USER_HOME_ESCAPED>\\...\\engram-debug.log"` por placeholder. Reemplazar `dbPath` real por `${ENGRAM_DB_PATH}`. **Preservar**: mem_search, mem_save, mem_update, mem_get_observation, mem_context, mem_timeline, mem_stats, mem_suggest_topic_key, mem_save_prompt, mem_session_summary, mem_session_start, mem_session_end, Noise Gate classification, F4B RECENT_SESSION_PACK, F4C Memory Context Selector, MEMORY_INSTRUCTIONS, prompt classification |
| **Destino** | `runtime/plugins/engram/engram.template.ts` |
| **Tests** | `TypeScript parseable`, `contiene mem_* tools`, `contiene Noise Gate`, `contiene F4B/F4C`, `contiene ENGRAM_DB_PATH placeholder`, `contiene MEMORY_INSTRUCTIONS`, `no personal paths`, `no DB hardcodeada` |
| **Riesgo** | **Alto** â€” es el mÃ¡s complejo. Si el sanitizado rompe la lÃ³gica de Engram, todo el sistema de memoria falla. Se requiere validaciÃ³n manual y tests unitarios |

### Slice F â€” Skills no-SDD

| DecisiÃ³n | Valor |
|---|---|
| **Â¿Importar?** | âœ… SÃ­, must-have los 4 core: `judgment-day`, `skill-creator`, `skill-improver`, `skill-registry`, `engram-agent` |
| **Fuente** | `~/.config/opencode/skills/judgment-day/`, `skill-creator/`, `skill-improver/`, `skill-registry/` |
| **SanitizaciÃ³n** | Quitar paths personales |
| **Destino** | `runtime/skills/judgment-day/`, etc. |
| **Riesgo** | Bajo â€” markdown |

### Slice G â€” otros plugins

| DecisiÃ³n | Valor |
|---|---|
| **background-agents.ts** | âš ï¸ `should-have`. Se importa template sanitizado con dependencia documentada a gentle-ai CLI. Destino: `runtime/plugins/background-agents/` |
| **model-variants.ts** | âš ï¸ `optional`. Depende de gentle-ai (escribe a `~/.gentle-ai/cache/`). Se importa como template si el usuario accede, con dependencia documentada. Destino: `runtime/plugins/model-variants/` |
| **Riesgo** | Medio. Si el usuario no tiene gentle-ai CLI, estos plugins fallan silenciosamente al cargar. Se debe documentar: "opcional, requiere gentle-ai instalado" |

### Slice H â€” Agentes adicionales

| DecisiÃ³n | Valor |
|---|---|
| **frontend-specialist** | âœ… `should-have`. Importar sanitizado |
| **bigquery-data-quality** | âš ï¸ `optional`. Importar sanitizado si el usuario accede |
| **data-memory-curator** | âš ï¸ `optional`. Similar |
| **sql-cleaning-agent** | âš ï¸ `optional`. Similar |
| **Destino** | `runtime/agents/additional/` |
| **Riesgo** | Bajo. Son markdown de agentes, no afectan el core. El riesgo es revelar datos de empresa en los agentes. |

### Slice I â€” Ponytail

| DecisiÃ³n | Valor |
|---|---|
| **Â¿Importar?** | âŒ No cambiar. El Code Gate ya estÃ¡ en AGENTS.md. No hay plugin que importar. Solo verificar que la reconciliaciÃ³n sigue siendo correcta |
| **Riesgo** | Bajo â€” nada que hacer |

---

## 3. Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | MitigaciÃ³n |
|---|---|---|---|---|
| R1 | Engram sanitizado rompe funcionalidad | Media | Alto | TypeScript compile check + test unitario en Phase 2C |
| R2 | JSONC de 64KB tiene paths residuales | Alta | Medio | Script de validaciÃ³n automatizado busca `<WINDOWS_USER_HOME>\\` |
| R3 | background-agents espera gentle-ai y falla | Alta | Medio | DocumentaciÃ³n clara + graceful fallback en el plugin (si posible) |
| R4 | SDD skills pierden contexto al sanitizar | Baja | Alto | Preservar SKILL.md completo sin truncar, solo reemplazar paths |
| R5 | Ponytail plugin se instala accidentalmente | Baja | Bajo | Excluido explÃ­citamente del inventory, no hay ruta que lo incluya |
| R6 | Noise Gate se rompe al sanitizar engram.ts | Media | Alto | Preservar Noise Gate classification intacta, solo tocar paths |
| R7 | F4B/F4C markers se pierden | Baja | Medio | Verificar markers especÃ­ficos post-sanitizaciÃ³n |

---

## 4. Orden de prioridad para implementaciÃ³n

### Fase 2B Gates (importaciÃ³n):

```
[Slice A] AGENTS.md template
   â†“
[Slice B] opencode config template
   â†“
[Slice C] SDD skills (10)
   â†“
[Slice D] gentle-orchestrator doc
   â†“
[Slice E] Engram plugin sanitizado (â›” ATENCIÃ“N: requiere revisiÃ³n manual)
   â†“
[Slice F] Skills core (judgment-day, skill-creator, skill-improver, skill-registry, engram-agent)
   â†“
[Slice G] background-agents + model-variants (should-have)
   â†“
[Slice H] frontend-specialist + agentes adicionales (should-have + optional)
   â†“
[Slice I] Ponytail verification pass
```

### Fase 2C (validaciÃ³n):

```
1. Test: install:temp con runtime-parity profile works
2. Test: opencode can parse generated config
3. Test: engram.ts compiles/is valid TS
4. Test: no personal paths in any imported file
5. Test: AGENTS template contains Manager routing
6. Test: SDD skills have valid frontmatter
7. Test: Engram plugin contains mem_search, mem_save, etc
8. Test: Engram plugin contains Noise Gate classification
9. Test: Engram plugin contains F4B and F4C markers
10. Test: no secrets in imported files
11. Test: gentle-ai external not required by config
12. Test: SDD_INIT_PACKET present in sdd-init
13. Test: SUBAGENT_RESULT present in sdd-* (where applicable)
14. Test: config is valid JSONC
15. Test: ENGRAM_DB_PATH placeholder present in plugin
16. Test: 22 must-have components present
17. Test: all SDD subagent names present in config
18. Test: all skills present at expected paths
19. Test: gentle-orchestrator documented as subagent not external
20. Test: Ponytail Code Gate present in AGENTS template
21. Test: no gentle-ai external reference in opencode template config
22. Test: Manager primary mode confirmed in config template
23. Test: README doc reflects runtime-parity profile purpose
```

---

*Fin de PHASE-2A-IMPORT-DECISION-PACKAGE.md*

