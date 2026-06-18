# Phase 2A â€” Runtime Parity Inventory

> **PropÃ³sito:** Auditar el runtime real de OpenCode y clasificar cada componente para importaciÃ³n sanitizada.
> **Fecha:** 2026-06-17
> **Fuentes:** `~/.config/opencode/`, `~/.codex/skills/`, `Tools/.agents/skills/` (modo read-only)
> **Estado:** âœ… INVENTORY COMPLETE

---

## 1. Resumen ejecutivo

Se auditaron 4 fuentes runtime en modo read-only. Se identificaron **76 componentes** entre agentes, plugins, skills, configuraciones y datos. El inventario los clasifica como `must-have` (22), `should-have` (5), `optional` (12), `docs-only` (6) y `exclude` (4+). El resto son skills ya cubiertos o derivados.

**Regla base:** No se copia DB real, memorias, logs, backups, secretos ni rutas personales.

---

## 2. Tabla maestra de componentes

### 2.1 Capa de orquestaciÃ³n (opencode.json)

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **Manager primary** | âœ… | `opencode.json` agent.manager.prompt | Prompt primario | SÃ­ â€” sin Manager no hay orquestaciÃ³n | `must-have` | Template sanitizado | `runtime/opencode/AGENTS.template.md` | Quitar paths, emails, secretos, DB real | No secrets, no paths, contiene Manager routing |
| **gentle-orchestrator** | âœ… | `opencode.json` agent.gentle-orchestrator | Subagente + prompt | SÃ­ â€” es parte del routing SDD actual | `must-have` | Template de config + doc | `runtime/integrations/gentle/gentle-orchestrator.template.md` | Quitar referencias a paths | Es subagente, no primary, no depende de gentle-ai externo |
| **sdd-init** | âœ… | `opencode.json` + `.config/opencode/skills/` + `.codex/skills/` | Subagente + skill | SÃ­ â€” entry point SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-init/` | Quitar paths, preservar SDD_INIT_PACKET | Contiene SDD_INIT_PACKET + SUBAGENT_RESULT |
| **sdd-explore** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” fase SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-explore/` | Quitar paths, preservar return envelope | No secrets, SUBAGENT_RESULT presente |
| **sdd-propose** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” fase SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-propose/` | Quitar paths | SUBAGENT_RESULT presente |
| **sdd-spec** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” fase SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-spec/` | Quitar paths | SUBAGENT_RESULT presente |
| **sdd-design** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” fase SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-design/` | Quitar paths | SUBAGENT_RESULT presente |
| **sdd-tasks** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” fase SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-tasks/` | Quitar paths, preservar ponytail: check | SUBAGENT_RESULT presente |
| **sdd-apply** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” fase SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-apply/` | Quitar paths | SUBAGENT_RESULT presente |
| **sdd-verify** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” fase SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-verify/` | Quitar paths | SUBAGENT_RESULT presente |
| **sdd-archive** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” fase SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-archive/` | Quitar paths | SUBAGENT_RESULT presente |
| **sdd-onboard** | âœ… | `opencode.json` + skills | Subagente + skill | SÃ­ â€” onboarding SDD | `must-have` | SKILL.md sanitizado | `runtime/agents/sdd/sdd-onboard/` | Quitar paths | SUBAGENT_RESULT presente |

### 2.2 AGENTS.md

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **AGENTS.md real** | âœ… | `~/.config/opencode/AGENTS.md` (16KB) | System prompt | SÃ­ â€” sin AGENTS no hay personalidad del asistente | `must-have` | Template sanitizado | `runtime/opencode/AGENTS.template.md` | Quitar paths, emails, tokens, DB real, logs. Preservar: Manager routing, SDD workflow, Ponytail Code Gate, Engram governance, Noise Gate, mem_context, gentle-ai alignment-only, GPT fallback | No secrets, no paths, contiene Manager, SDD, Ponytail guidance, Engram governance |

### 2.3 ConfiguraciÃ³n OpenCode

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **opencode.json real** | âœ… | `~/.config/opencode/opencode.json` (64KB) | Config principal | SÃ­ â€” sin config no arranca OpenCode | `must-have` | Template JSONC portable | `runtime/opencode/opencode.template.jsonc` | Reemplazar paths absolutos por placeholders. Reemplazar `<USER_HOME>\\...` por `${OPENCODE_KIT_DIR}/runtime/...`. Cambiar DB path a `${ENGRAM_DB_PATH}`. Quitar referencias a gentle-ai externo como runtime obligatorio | JSONC parseable, no personal paths, Manager primary presente, SDD subagents presentes, Engram plugin referencia presente, gentle-ai externo ausente, DB real ausente |
| **opencode.jsonc** | âœ… | `~/.config/opencode/opencode.jsonc` (688B) | Config alterna | Baja | `optional` | Template si hay contenido Ãºnico | `runtime/opencode/opencode.additional.jsonc` | Sanitizar paths | No secrets |

### 2.4 Plugins

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **Engram plugin** | âœ… | `~/.config/opencode/plugins/engram.ts` | Plugin funcional real | SÃ­ â€” sin Engram no hay memoria persistente ni Noise Gate | `must-have` | Plugin sanitizado | `runtime/plugins/engram/engram.template.ts` | Reemplazar `ENGRAM_BIN = "<USER_HOME_ESCAPED>\\..."` por `${ENGRAM_BIN}` o placeholder. Reemplazar `DEBUG_LOG = "<USER_HOME_ESCAPED>\\..."` por placeholder. No copiar DB. Conservar mem_context, mem_save, mem_search, mem_session_summary, Noise Gate, F4B, F4C. Preservar MEMORY_INSTRUCTIONS | No DB real, no memorias, no personal paths, contiene ENGRAM_DB_PATH placeholder, contiene mem_context, Noise Gate, F4B/F4C markers |
| **background-agents** | âœ… | `~/.config/opencode/plugins/background-agents.ts` | Plugin async delegation | âš ï¸ Depende de gentle-ai CLI externo | `should-have` (requiere auditorÃ­a) | Plugin sanitizado si se resuelve dependencia | `runtime/plugins/background-agents/background-agents.template.ts` | Reemplazar path. NOTA: llama a `gentle-ai skill-registry refresh` â€” depende de external binary | No paths, documentar dependencia con gentle-ai CLI |
| **model-variants** | âœ… | `~/.config/opencode/plugins/model-variants.ts` | Plugin cache model variants | âš ï¸ Depende de gentle-ai | `optional` (si gentle-ai externo no es runtime obligatorio) | Template si se decide incluir | `runtime/plugins/model-variants/model-variants.template.ts` | Sanitizar paths. NOTA: escribe a `~/.gentle-ai/cache/` | No paths, documentar dependencia con gentle-ai |
| **engram-debug.log** | âœ… | `~/.config/opencode/plugins/engram-debug.log` | Log runtime | âŒ No | `exclude` | âŒ No importar | N/A | N/A | N/A |
| **engram.ts backups** (6) | âœ… | `~/.config/opencode/plugins/engram.ts.e6b-*` | Backups histÃ³ricos | âŒ No | `exclude` | âŒ No importar | N/A | N/A | N/A |

### 2.5 Engram

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **Engram DB** | âœ… | `~/.engram/engram.db` (3.3MB) | Base de datos SQLite | âŒ No â€” datos personales | `exclude` | âŒ No importar | N/A | N/A | N/A |
| **Engram Go binary** | âœ… | `${ENGRAM_BIN}` | Binario Engram | âŒ No copiable | `docs-only` | âŒ No importar (binario especÃ­fico de plataforma) | Documentar cÃ³mo obtener Engram | N/A | N/A |

### 2.6 Skills runtime (`~/.config/opencode/skills/`)

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **sdd-init skill** | âœ… | `.config/opencode/skills/sdd-init/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-init/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-explore skill** | âœ… | `.config/opencode/skills/sdd-explore/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-explore/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-propose skill** | âœ… | `.config/opencode/skills/sdd-propose/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-propose/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-spec skill** | âœ… | `.config/opencode/skills/sdd-spec/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-spec/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-design skill** | âœ… | `.config/opencode/skills/sdd-design/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-design/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-tasks skill** | âœ… | `.config/opencode/skills/sdd-tasks/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-tasks/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-apply skill** | âœ… | `.config/opencode/skills/sdd-apply/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-apply/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-verify skill** | âœ… | `.config/opencode/skills/sdd-verify/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-verify/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-archive skill** | âœ… | `.config/opencode/skills/sdd-archive/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-archive/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-onboard skill** | âœ… | `.config/opencode/skills/sdd-onboard/` | Skill | SÃ­ | `must-have` | Sanitizado | `runtime/skills/sdd-onboard/` | Quitar paths | Frontmatter vÃ¡lido, no secrets |
| **sdd-init skill (codex)** | âœ… | `.codex/skills/sdd-init/` | Skill (duplicado) | Ya cubierto | â€” | Elegir versiÃ³n mÃ¡s actual | N/A | N/A | N/A |
| **Otros SDD (codex)** | âœ… | `.codex/skills/sdd-*/` | Skills duplicados | Ya cubierto | â€” | Elegir `.config` como fuente principal | N/A | N/A â€” misma data | N/A |
| **judgment-day** | âœ… | `.config/opencode/skills/judgment-day/` | Skill | SÃ­ â€” quality gate | `must-have` | Sanitizado | `runtime/skills/judgment-day/` | Quitar paths | Frontmatter vÃ¡lido |
| **skill-creator** | âœ… | `.config/opencode/skills/skill-creator/` | Skill | SÃ­ â€” creaciÃ³n de skills | `must-have` | Sanitizado | `runtime/skills/skill-creator/` | Quitar paths | Frontmatter vÃ¡lido |
| **skill-improver** | âœ… | `.config/opencode/skills/skill-improver/` | Skill | SÃ­ â€” mejora de skills | `must-have` | Sanitizado | `runtime/skills/skill-improver/` | Quitar paths | Frontmatter vÃ¡lido |
| **skill-registry** | âœ… | `.config/opencode/skills/skill-registry/` | Skill | SÃ­ â€” indexado | `must-have` | Sanitizado | `runtime/skills/skill-registry/` | Quitar paths | Frontmatter vÃ¡lido |
| **canvas-design** | âœ… | `.config/opencode/skills/canvas-design/` | Skill | Opcional | `optional` | Template | `runtime/skills/canvas-design/` | Quitar paths | Frontmatter vÃ¡lido |
| **design-md** | âœ… | `.config/opencode/skills/design-md/` | Skill | Opcional | `optional` | Template | `runtime/skills/design-md/` | Quitar paths | Frontmatter vÃ¡lido |
| **flow-diagram** | âœ… | `.config/opencode/skills/flow-diagram/` | Skill | Opcional | `optional` | Template | `runtime/skills/flow-diagram/` | Quitar paths | Frontmatter vÃ¡lido |
| **deploy-security-gate** | âœ… | `.config/opencode/skills/deploy-security-gate/` | Skill | Opcional | `optional` | Template | `runtime/skills/deploy-security-gate/` | Quitar paths | Frontmatter vÃ¡lido |
| **sandbox-data-loader** | âœ… | `.config/opencode/skills/sandbox-data-loader/` | Skill | Opcional | `optional` | Template | `runtime/skills/sandbox-data-loader/` | Quitar paths | Frontmatter vÃ¡lido |
| **web-design-guidelines** | âœ… | `.config/opencode/skills/web-design-guidelines/` | Skill | Opcional | `optional` | Template | `runtime/skills/web-design-guidelines/` | Quitar paths | Frontmatter vÃ¡lido |
| **sql-learning** | âœ… | `.config/opencode/skills/sql-learning/` | Skill | Opcional | `optional` | Template | `runtime/skills/sql-learning/` | Quitar paths | Frontmatter vÃ¡lido |
| **go-testing** | âœ… | `.config/opencode/skills/go-testing/` | Skill | Opcional | `optional` | Template | `runtime/skills/go-testing/` | Quitar paths | Frontmatter vÃ¡lido |
| **comment-writer** | âœ… | `.config/opencode/skills/comment-writer/` | Skill | Opcional | `optional` | Template | `runtime/skills/comment-writer/` | Quitar paths | Frontmatter vÃ¡lido |
| **cognitive-doc-design** | âœ… | `.config/opencode/skills/cognitive-doc-design/` | Skill | Opcional | `optional` | Template | `runtime/skills/cognitive-doc-design/` | Quitar paths | Frontmatter vÃ¡lido |
| **work-unit-commits** | âœ… | `.config/opencode/skills/work-unit-commits/` | Skill | Opcional | `optional` | Template | `runtime/skills/work-unit-commits/` | Quitar paths | Frontmatter vÃ¡lido |
| **issue-creation** | âœ… | `.config/opencode/skills/issue-creation/` | Skill | Opcional | `optional` | Template | `runtime/skills/issue-creation/` | Quitar paths | Frontmatter vÃ¡lido |
| **chained-pr** | âœ… | `.config/opencode/skills/chained-pr/` | Skill | Opcional | `optional` | Template | `runtime/skills/chained-pr/` | Quitar paths | Frontmatter vÃ¡lido |
| **branch-pr** | âœ… | `.config/opencode/skills/branch-pr/` | Skill | Opcional | `optional` | Template | `runtime/skills/branch-pr/` | Quitar paths | Frontmatter vÃ¡lido |
| **bigquery-table-cleaning** | âœ… | `.config/opencode/skills/bigquery-table-cleaning/` | Skill | Opcional (domain-specific) | `optional` | Template | `runtime/skills/bigquery-table-cleaning/` | Quitar paths | Frontmatter vÃ¡lido |

### 2.7 Skills Tools (`Tools/.agents/skills/`)

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **bigquery-expert** | âœ… | `Tools/.agents/skills/bigquery-expert/` | Skill | Domain-specific | `optional` | Template | `runtime/skills/bigquery-expert/` | Quitar paths | Frontmatter vÃ¡lido |
| **data-memory-governance** | âœ… | `Tools/.agents/skills/data-memory-governance/` | Skill | Domain-specific | `optional` | Template | `runtime/skills/data-memory-governance/` | Quitar paths | Frontmatter vÃ¡lido |
| **find-skills** | âœ… | `Tools/.agents/skills/find-skills/` | Skill | Ãštil | `should-have` | Template | `runtime/skills/find-skills/` | Quitar paths | Frontmatter vÃ¡lido |
| **frontend-design** | âœ… | `Tools/.agents/skills/frontend-design/` | Skill | Domain-specific | `optional` | Template | `runtime/skills/frontend-design/` | Quitar paths | Frontmatter vÃ¡lido |

### 2.8 Skills Codex (`~/.codex/skills/`) â€” adicionales no duplicados

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **engram-agent** | âœ… | `.codex/skills/engram-agent/` | Skill | SÃ­ â€” gestiÃ³n de memoria | `must-have` | Sanitizado | `runtime/skills/engram-agent/` | Quitar paths | Frontmatter vÃ¡lido |
| **hatch-pet** | âœ… | `.codex/skills/hatch-pet/` | Skill | No | `optional` | Template | `runtime/skills/hatch-pet/` | Quitar paths | Frontmatter vÃ¡lido |
| **playwright** | âœ… | `.codex/skills/playwright/` | Skill | Opcional | `optional` | Template | `runtime/skills/playwright/` | Quitar paths | Frontmatter vÃ¡lido |
| **codex-primary-runtime** | âœ… | `.codex/skills/codex-primary-runtime/` | Skill | Solo codex | `docs-only` | âŒ No importar (especÃ­fico Codex) | N/A | N/A | N/A |
| **.system** | âœ… | `.codex/skills/.system/` | System | Solo codex | `exclude` | âŒ No importar | N/A | N/A | N/A |

### 2.9 Agentes adicionales (`~/.config/opencode/agents/`)

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **bigquery-data-quality** | âœ… | `.config/opencode/agents/bigquery-data-quality.md` | Subagente | Domain-specific | `optional` | Sanitizado | `runtime/agents/additional/bigquery-data-quality/` | Quitar datos empresa, credenciales | No secrets, no company data |
| **data-memory-curator** | âœ… | `.config/opencode/agents/data-memory-curator.md` | Subagente | Domain-specific | `optional` | Sanitizado | `runtime/agents/additional/data-memory-curator/` | Quitar datos empresa | No secrets |
| **frontend-specialist** | âœ… | `.config/opencode/agents/frontend-specialist.md` | Subagente | Ãštil para frontend | `should-have` | Sanitizado | `runtime/agents/additional/frontend-specialist/` | Quitar paths | No secrets |
| **sql-cleaning-agent** | âœ… | `.config/opencode/agents/sql-cleaning-agent.md` | Subagente | Domain-specific | `optional` | Sanitizado | `runtime/agents/additional/sql-cleaning-agent/` | Quitar datos empresa | No secrets |

### 2.10 Integraciones

| Componente | Existe runtime | Ruta fuente | Tipo | Necesario | ClasificaciÃ³n | Importar | Destino propuesto | SanitizaciÃ³n requerida | Tests |
|---|---|---|---|---|---|---|---|---|---|
| **Ponytail Code Gate** | âœ… (en AGENTS.md) | `~/.config/opencode/AGENTS.md` (secciÃ³n) | Guidance | SÃ­ â€” calidad de cÃ³digo | `must-have` | Preservado en AGENTS template | Ya incluido en `runtime/opencode/AGENTS.template.md` | Ya sanitizado en Phase 1.1 | Guidance presente, no plugin, ultra no default |
| **Ponytail plugin** | âŒ No instalado | Solo en repo externo `<USER_HOME>\\...\ponytail\` | Plugin | No | `exclude` | âŒ No importar | N/A | N/A | N/A |
| **Ponytail skills** | âŒ No instalados | Solo en repo externo `ponytail\.opencode\command\` | Skills | No | `exclude` | âŒ No importar | N/A | N/A | N/A |
| **gentle-ai externo** | âŒ No como runtime obligatorio | Sistema externo | Runtime | No | `docs-only` | âŒ No importar como dependencia | `docs/alignment/` (solo documentaciÃ³n) | N/A | gentle-ai external no estÃ¡ en runtime-parity |
| **Noise Gate** | âœ… (en engram.ts) | `plugins/engram.ts` | Feature | SÃ­ | `must-have` | Incluido en Engram plugin | `runtime/plugins/engram/` | Ya cubierto | Noise Gate classification presente |
| **F4B** | âœ… (en engram.ts) | `plugins/engram.ts` | Feature | SÃ­ | `must-have` | Incluido en Engram plugin | `runtime/plugins/engram/` | Ya cubierto | F4B RECENT_SESSION_PACK markers |
| **F4C** | âœ… (en engram.ts) | `plugins/engram.ts` | Feature | SÃ­ | `must-have` | Incluido en Engram plugin | `runtime/plugins/engram/` | Ya cubierto | F4C Memory Context Selector |

### 2.11 Datos excluidos

| Componente | Existe runtime | Ruta | ClasificaciÃ³n | RazÃ³n |
|---|---|---|---|---|
| **Engram DB** | âœ… | `~/.engram/engram.db` (3.3MB) | `exclude` | Datos personales, memorias reales |
| **Memorias Codex** | âœ… | `.codex/memories_1.sqlite` | `exclude` | Datos legacy no portables |
| **Logs** | âœ… | `engram-debug.log` | `exclude` | Datos de sesiÃ³n personales |
| **Backups** | âœ… | `engram.ts.*-backup` | `exclude` | Backups histÃ³ricos |
| **Secrets** | âš ï¸ Potencial | En cualquier archivo runtime | `exclude` | No copiar nunca |
| **Config personal** | âœ… | Paths `<USER_HOME>\\...` | `exclude` | Sanitizar a placeholders |

---

## 3. Resumen por clasificaciÃ³n

| ClasificaciÃ³n | Cantidad | Componentes |
|---|---|---|
| **must-have** | 22 | Manager, AGENTS.md, opencode config, gentle-orchestrator, 10 SDD subagents, 10 SDD skills + Engram plugin + Noise Gate + F4B + F4C + engram-agent skill + judgment-day + skill-creator + skill-improver + skill-registry |
| **should-have** | 3 | background-agents, find-skills, frontend-specialist |
| **optional** | 12 | canvas-design, design-md, flow-diagram, deploy-security-gate, sandbox-data-loader, web-design-guidelines, sql-learning, go-testing, comment-writer, cognitive-doc-design, work-unit-commits, issue-creation, chained-pr, branch-pr, bigquery-table-cleaning, bigquery-expert, data-memory-governance, frontend-design, hatch-pet, playwright |
| **docs-only** | 6 | gentle-ai externo alignment docs, Engram binary doc, codex-primary-runtime |
| **exclude** | 4+ | Engram DB, memorias Codex, logs, backups, secrets, Ponytail plugin/skills, .system |

---

## 4. Observaciones crÃ­ticas

### 4.1 background-agents.ts depende de gentle-ai CLI
El plugin `background-agents.ts` llama a `gentle-ai skill-registry refresh`. Esto significa que **no puede funcionar sin gentle-ai externo instalado**. Se clasifica como `should-have` con dependencia documentada.

### 4.2 model-variants.ts depende de gentle-ai
Escribe a `~/.gentle-ai/cache/model-variants.json`. Es claramente un componente de gentle-ai. Se clasifica como `optional` con dependencia documentada.

### 4.3 DuplicaciÃ³n skills SDD
Cada `sdd-*` existe en **dos** ubicaciones runtime: `.config/opencode/skills/` y `.codex/skills/`. La fuente `.config/opencode/skills/` es la mÃ¡s actual y la que OpenCode descubre primero. Usar esa como fuente principal y documentar la decisiÃ³n.

### 4.4 Ponytail reconciliado
Confirmado: Ponytail plugin NO estÃ¡ instalado en runtime. Ponytail skills NO estÃ¡n instalados. Solo existe el Code Gate como guidance en AGENTS.md. La reconciliaciÃ³n de Phase 1.1 es correcta.

### 4.5 Engram plugin es real y funcional
No es un template conceptual. El `engram.ts` real expone 12+ herramientas de memoria, Noise Gate, F4B/F4C, y un protocolo completo de persistencia. La importaciÃ³n debe preservar toda esta funcionalidad pero reemplazar los paths hardcodeados.

---

## 5. Fuentes auditadas

| Fuente | Ruta | Estado |
|---|---|---|
| opencode.json | `~/.config/opencode/opencode.json` | âœ… LeÃ­do (64KB) |
| AGENTS.md | `~/.config/opencode/AGENTS.md` | âœ… LeÃ­do (16KB) |
| opencode.jsonc | `~/.config/opencode/opencode.jsonc` | âœ… LeÃ­do (688B) |
| plugins/ | `~/.config/opencode/plugins/` | âœ… LeÃ­do (11 archivos) |
| engram.ts | `~/.config/opencode/plugins/engram.ts` | âœ… Analizado |
| background-agents.ts | `~/.config/opencode/plugins/background-agents.ts` | âœ… Analizado |
| model-variants.ts | `~/.config/opencode/plugins/model-variants.ts` | âœ… Analizado |
| skills/ | `~/.config/opencode/skills/` | âœ… Listado (29 skills) |
| agents/ | `~/.config/opencode/agents/` | âœ… Listado (4 agents) |
| .codex/skills/ | `~/.codex/skills/` | âœ… Listado (26 skills) |
| Tools/.agents/skills/ | `Tools/.agents/skills/` | âœ… Listado (4 skills) |
| Engram DB | `~/.engram/engram.db` | âœ… Verificado (3.3MB, excluido) |

---

*Fin de PHASE-2A-RUNTIME-PARITY-INVENTORY.md*

