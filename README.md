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

## 3. Flujo completo de una petición

```
Usuario → Manager clasifica (Tiny/Small/Medium/Large)
  → [Medium+] Diseño + aprobación
  → [Large] Graphify Context Gate
  → SDD Pipeline (Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive)
  → Code Review / Judgment Day
  → GPT-5.5 Review
  → Memory Governance (session summary)
  → Respuesta
```

Cada fase tiene su contrato en [`contracts/`](contracts/) y su implementación en el adaptador runtime correspondiente.

---

## 4. Qué es la memoria en esta arquitectura

La memoria es **persistente entre sesiones**. Guarda:
- Decisiones arquitectónicas.
- Bugs y su causa raíz.
- Descubrimientos no obvios.
- Preferencias del usuario.
- Patrones reusables.

**No guarda**: prompts crudos, logs, secretos, código fuente, fallos transitorios.

---

## 5. Archivos de memoria y archivos relacionados

| Archivo | Propósito |
|---------|-----------|
| `contracts/memory-governance.md` | Reglas de escritura/recuperación |
| `contracts/noise-gate.md` | Filtro antes de guardar |
| `opencode/manager.template.md` | Manager con auto-triggers Engram |
| `codex/scripts/memory-lint.mjs` | Validador de archivos de memoria |

---

## 6. Noise Gate: qué es y por qué quita ruido

El Noise Gate clasifica cada interacción como `instruction`, `question`, `confirmation`, `navigation` o `noise`. Solo las `instruction` con valor futuro o decisiones durables merecen guardarse en memoria.

**Ver**: [`contracts/noise-gate.md`](contracts/noise-gate.md) para las reglas completas.

---

## 7. Tokens: explicación simple

Los tokens son el "papel" donde el asistente escribe su contexto. Este kit optimiza el uso de ese papel:

1. **Contexto fijo**: lo que siempre está presente (poco).
2. **Contexto dinámico**: lo que se carga bajo demanda (skills, docs largos).
3. **Context packs**: paquetes mínimos para subagentes.

**Ver**: [`contracts/token-discipline.md`](contracts/token-discipline.md)

---

## 8. Memoria entre sesiones y memoria persistente

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

## 9. Ponytail: contra la sobreingeniería

Antes de implementar, preguntar:
1. ¿Esto necesita existir?
2. ¿Puede stdlib hacerlo?
3. ¿Puede la plataforma/runtime hacerlo nativamente?
4. ¿Una línea basta?
5. Solo entonces: implementar lo más pequeño que funcione.

**Nunca simplificar**: seguridad, accesibilidad, data-loss, tests requeridos, contratos públicos.

**Ver**: [`contracts/ponytail.md`](contracts/ponytail.md)

---

## 10. Regla final para mantener la arquitectura sana

1. **No mezclar niveles**: lo portable va en `contracts/`, lo runtime-specific en `opencode/` o `codex/`.
2. **Validar antes de commit**: `pnpm test:all` debe pasar.
3. **Memoria con criterio**: si no tiene valor futuro, no lo guardes.
4. **Contexto mínimo**: cada subagente recibe solo lo que necesita.
5. **Review antes de done**: siempre pasar por Code Review y quality gates.

---

## 11. Estado actual

| Fase | Estado |
|------|--------|
| Fase 0 — Merge + directorios | ✅ |
| Fase 1 — Contratos portables | ✅ |
| Fase 2 — Adaptador OpenCode | ✅ |
| Fase 3 — Adaptador Codex | ✅ |
| Fase 4 — README + QuickStarts | ✅ |
| Fase 5 — Tests y CI | 🔲 |
| Fase 6 — Limpieza y release | 🔲 |

**Ver**: [`docs/plan-unificacion/PLAN.md`](docs/plan-unificacion/PLAN.md) para el plan detallado.

---

## 12. Cómo validar

```bash
pnpm validate              # Validación de manifiesto
pnpm test:all              # Todos los tests (shared + codex + opencode)
pnpm docs:check            # Chequeo de documentación
pnpm codex:doctor          # Doctor Codex
pnpm codex:install:dry-run # Simular instalación Codex
```

---

## 13. Rollback

```bash
pnpm codex:rollback --target ~/.codex   # Codex
```

El instalador siempre respalda antes de escribir.

---

## Licencia y notas

Este repositorio es un overlay de usuario. No modifica binarios de OpenCode ni Codex. Siempre hace backup antes de instalar.
