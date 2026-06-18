# Runtime Kit — OpenCode & Codex

Este repositorio unifica la arquitectura de agente para **OpenCode** y **Codex** bajo contratos portables compartidos. Un solo agente Manager, 7 contratos runtime-agnostic, adaptadores específicos por runtime y skills portables cargadas por trigger.

## ¿Para quién es esto?

| Si usas... | Empieza aquí |
|------------|-------------|
| **OpenCode** | [`QUICKSTART_OPENCODE.md`](QUICKSTART_OPENCODE.md) |
| **Codex** | [`QUICKSTART_CODEX.md`](QUICKSTART_CODEX.md) |

## Contratos portables

Los contratos definen QUÉ hace cada componente, no CÓMO se implementa:

| Contrato | Propósito |
|----------|-----------|
| [`contracts/manager.md`](contracts/manager.md) | Orquestación primaria del agente |
| [`contracts/sdd-pipeline.md`](contracts/sdd-pipeline.md) | Fases de Spec-Driven Development |
| [`contracts/memory-governance.md`](contracts/memory-governance.md) | Reglas de memoria persistente |
| [`contracts/noise-gate.md`](contracts/noise-gate.md) | Filtro de ruido conversacional |
| [`contracts/token-discipline.md`](contracts/token-discipline.md) | Presupuesto de tokens |
| [`contracts/context-pack-schema.md`](contracts/context-pack-schema.md) | Empaquetado de contexto |
| [`contracts/ponytail.md`](contracts/ponytail.md) | Anti-sobreingeniería |

**Ver**: [`ARCHITECTURE.md`](ARCHITECTURE.md) para la vista completa.

---

## 1. Para personas no técnicas: qué problema resuelve

Cuando usas un asistente de IA para programar, cada conversación empieza desde cero. El asistente no recuerda lo que hiciste ayer, las decisiones que tomaste, o los bugs que encontraste. Este kit resuelve eso: **memoria entre sesiones**, **control de tokens** para no gastar contexto en ruido, y un **Manager** que orquesta todo el flujo de manera estructurada.

### Modelo mental

Imagina que tu asistente de IA es un equipo de trabajo:

- El **Manager** es el líder: escucha, decide qué hacer, delega y revisa el resultado.
- La **memoria** es el cuaderno de bitácora: guarda decisiones, bugs y descubrimientos.
- El **Noise Gate** es el asistente que decide qué merece anotarse y qué es ruido.
- El **Token Budgeter** es el que vigila que no nos quedemos sin papel para escribir.
- Los **skills** son especialistas que se llaman solo cuando se necesitan.

---

## 2. La idea central: menos ruido, más criterio

Este kit prioriza **calidad de contexto sobre cantidad**. En lugar de cargar todo el proyecto en cada petición, carga solo lo necesario bajo demanda.

**Principios**:
- Instrucciones estables cortas.
- Skills lazy-loaded por trigger.
- Memoria gobernada por Noise Gate.
- Context packs mínimos para subagentes.
- Pipeline SDD para cambios grandes.

---

## 3. Arquitectura para OpenCode

OpenCode ejecuta el **Manager Global** con subagentes y gates. Cada solicitud del usuario pasa por un flujo estructurado:

```
┌──────────────────────────────────────────────────────┐
│                    USUARIO                            │
│  "Agrega autenticación con Google al proyecto"       │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  1. MANAGER CLASIFICA                                │
│     Tiny → respuesta directa                         │
│     Small → intake corto + diseño + aplicar          │
│     Medium/Large → pipeline completo                 │
│     "Esto es Medium: múltiples archivos, API"        │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  2. SUPERPOWERS BRAINSTORMING (Intake)               │
│     ¿Qué problema resuelve? ¿Qué archivos?           │
│     ¿Qué NO debe tocarse?                            │
│     → Diseño con 2-3 enfoques                        │
│     → "¿Apruebas este diseño?"                       │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  3. GRAPHIFY CONTEXT GATE  (si 4+ archivos)          │
│     "Buscá relaciones entre auth y database"         │
│     → Mapa de archivos afectados                     │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  4. SDD PIPELINE (8 fases)                           │
│     Explore → Propose → Spec → Design                │
│     → Tasks → Apply → Verify → Archive               │
│     Cada fase delega a un subagente @sdd-*           │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  5. QUALITY GATES                                    │
│     Code Review / Judgment Day                       │
│     GPT-5.5 OAuth Review                             │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  6. MEMORIA + RESPUESTA                              │
│     mem_session_summary → guarda lo aprendido        │
│     "Listo. 3 archivos modificados, tests pasan."    │
└──────────────────────────────────────────────────────┘
```

**Ejemplo concreto**: Pedís "Agrega un comando `format` al Makefile que ejecute Prettier".  
→ Manager clasifica como **Small** (1 archivo, cambio mecánico)  
→ Intake corto: "¿Solo Prettier o también ESLint?"  
→ Diseño breve + aprobación  
→ Aplica el cambio en `Makefile`  
→ Verifica que `make format` funcione  
→ Code Review  
→ Responde con el diff y confirmación

---

## 4. Arquitectura para Codex

Codex ejecuta el **Manager overlay** con skills portables y memoria propia. El flujo es más liviano que OpenCode porque Codex no tiene subagentes nativos:

```
┌──────────────────────────────────────────────────────┐
│                    USUARIO                            │
│  "Hacé un diagrama de flujo del login"               │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  1. MANAGER CLASSIFICA                               │
│     ¿Es una pregunta? → responde directo             │
│     ¿Necesita un skill? → carga el skill             │
│     ¿Necesita memoria? → busca en mem_context        │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  2. MEMORIA + CONTEXTO                               │
│     Busca sesiones anteriores (mem_context)           │
│     Arma context pack mínimo para la tarea           │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  3. SKILL LAZY-LOADING                               │
│     "diagrama de flujo" → carga skill flow-diagram   │
│     "creá una PR" → carga branch-pr + work-unit-*   │
│     "auditá la UI" → carga web-design-guidelines     │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  4. EJECUCIÓN + VERIFICACIÓN                         │
│     El skill ejecuta su workflow                     │
│     Manager verifica el resultado                    │
└────────────────────┬─────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────┐
│  5. MEMORIA + RESPUESTA                              │
│     Guarda en memoria si es decisión o descubrimiento│
│     "Acá tenés el diagrama ASCII del flujo login"   │
└──────────────────────────────────────────────────────┘
```

**Ejemplo concreto**: Pedís "Creá una Pull Request para el fix de caché".  
→ Manager busca memoria: "¿había contexto de este fix?"  
→ Carga `branch-pr` + `work-unit-commits`  
→ `work-unit-commits` planifica los commits  
→ `branch-pr` crea la PR con descripción  
→ Manager verifica que la PR se creó correctamente  
→ Guarda en memoria: "PR #42 creada para fix de caché"

---

## 5. Comparación: flujo OpenCode vs flujo Codex

| Aspecto | OpenCode | Codex |
|---------|----------|-------|
| **Subagentes** | `@sdd-*` para cada fase SDD | No tiene subagentes nativos |
| **Gates** | Graphify, Frontend, Judgment Day, GPT-5.5 | Skills portables + verificación inline |
| **Memoria** | Engram MCP (servidor externo) | SQLite nativa + scripts memory-lint |
| **Instalación** | Overlay sobre AGENTS.md | Overlay sobre AGENTS.md |
| **Skills** | Cargados por trigger como subagentes | 18 skills portables cargados por trigger |
| **Complejidad** | Alta (proyectos grandes, Medium/Large) | Media (proyectos pequeños/medianos) |
| **Mejor para** | Equipos, APIs, auth, producción | Proyectos personales, scripts, experimentos |

---

## 6. Qué es la memoria en esta arquitectura

La memoria es **persistente entre sesiones**. Guarda:
- Decisiones arquitectónicas.
- Bugs y su causa raíz.
- Descubrimientos no obvios.
- Preferencias del usuario.
- Patrones reusables.

**No guarda**: prompts crudos, logs, secretos, código fuente, fallos transitorios.

---

## 7. Archivos de memoria y archivos relacionados

| Archivo | Propósito |
|---------|-----------|
| `contracts/memory-governance.md` | Reglas de escritura/recuperación |
| `contracts/noise-gate.md` | Filtro antes de guardar |
| `opencode/manager.template.md` | Manager con auto-triggers Engram |
| `codex/scripts/memory-lint.mjs` | Validador de archivos de memoria |

---

## 8. Noise Gate: qué es y por qué quita ruido

El Noise Gate clasifica cada interacción como `instruction`, `question`, `confirmation`, `navigation` o `noise`. Solo las `instruction` con valor futuro o decisiones durables merecen guardarse en memoria.

**Ver**: [`contracts/noise-gate.md`](contracts/noise-gate.md) para las reglas completas.

---

## 9. Tokens: explicación simple

Los tokens son el "papel" donde el asistente escribe su contexto. Este kit optimiza el uso de ese papel:

1. **Contexto fijo**: lo que siempre está presente (poco).
2. **Contexto dinámico**: lo que se carga bajo demanda (skills, docs largos).
3. **Context packs**: paquetes mínimos para subagentes.

**Ver**: [`contracts/token-discipline.md`](contracts/token-discipline.md)

---

## 10. Memoria entre sesiones y memoria persistente

### Flujo de memoria entre sesiones

1. **Sesión 1**: trabajas, se guardan decisiones y descubrimientos, al cerrar se ejecuta `mem_session_summary`.
2. **Entre sesiones**: los datos persisten en Engram (OpenCode) o SQLite (Codex).
3. **Sesión 2**: al empezar, el Manager busca contexto de sesiones anteriores.

### Reglas de retrieval

1. Intentar contexto de sesión reciente (`mem_context`).
2. Si no se encuentra, búsqueda por keywords (`mem_search`).
3. Observación completa solo si es relevante.

**Ver**: [`contracts/memory-governance.md`](contracts/memory-governance.md)

---

## 11. Ponytail: contra la sobreingeniería

Antes de implementar, preguntar:
1. ¿Esto necesita existir?
2. ¿Puede stdlib hacerlo?
3. ¿Puede la plataforma/runtime hacerlo nativamente?
4. ¿Una línea basta?
5. Solo entonces: implementar lo más pequeño que funcione.

**Nunca simplificar**: seguridad, accesibilidad, data-loss, tests requeridos, contratos públicos.

**Ver**: [`contracts/ponytail.md`](contracts/ponytail.md)

---

## 12. Regla final para mantener la arquitectura sana

1. **No mezclar niveles**: lo portable va en `contracts/`, lo runtime-specific en `opencode/` o `codex/`.
2. **Validar antes de commit**: `pnpm test:all` debe pasar.
3. **Memoria con criterio**: si no tiene valor futuro, no lo guardes.
4. **Contexto mínimo**: cada subagente recibe solo lo que necesita.
5. **Review antes de done**: siempre pasar por Code Review y quality gates.

---

## 13. Estado actual

| Fase | Estado |
|------|--------|
| Fase 0 — Merge + directorios | ✅ |
| Fase 1 — Contratos portables | ✅ |
| Fase 2 — Adaptador OpenCode | ✅ |
| Fase 3 — Adaptador Codex | ✅ |
| Fase 4 — README + QuickStarts | ✅ |
| Fase 5 — Tests y CI | ✅ |
| Fase 6 — Limpieza y release | ✅ |

Todas las fases del plan de unificación están completadas.  
**Ver**: [`docs/plan-unificacion/PLAN.md`](docs/plan-unificacion/PLAN.md) para el detalle.

---

## 14. Cómo validar

```bash
pnpm validate              # Validación de manifiesto
pnpm test:all              # Todos los tests (shared + codex + opencode)
pnpm docs:check            # Chequeo de documentación
pnpm codex:doctor          # Doctor Codex
pnpm codex:install:dry-run # Simular instalación Codex
pnpm opencode:doctor       # Doctor OpenCode
```

---

## 15. Rollback

```bash
pnpm codex:rollback --target ~/.codex       # Codex
pnpm opencode:rollback --target ~/.config/opencode  # OpenCode
```

El instalador siempre respalda antes de escribir.

---

## Licencia y notas

Este repositorio es un overlay de usuario. No modifica binarios de OpenCode ni Codex. Siempre hace backup antes de instalar.
