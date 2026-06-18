# Runtime Kit — OpenCode & Codex

Este repositorio unifica la arquitectura de agente para **OpenCode** y **Codex** bajo contratos portables compartidos. Un solo agente Manager, 7 contratos runtime-agnostic, adaptadores específicos por runtime y skills portables cargadas por trigger.

## ¿Para quién es esto?

| Si usas... | Empieza aquí |
|------------|-------------|
| **OpenCode** | [`QUICKSTART_OPENCODE.md`](QUICKSTART_OPENCODE.md) |
| **Codex** | [`QUICKSTART_CODEX.md`](QUICKSTART_CODEX.md) |

> 📘 **Arquitectura completa**: Si querés entender en detalle cómo funciona todo —capas, componentes, flujos, memoria, Noise Gate, contratos, skills, y cómo se comunican— leé el documento maestro [`arquitectura.md`](arquitectura.md). Está escrito tanto para audiencia técnica como no técnica.

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

## 6. Memoria persistente: cómo funciona

La memoria en este kit es **persistente entre sesiones**. No es memoria de conversación (el asistente no recuerda cada mensaje), sino **memoria de decisiones**: guarda lo que tiene valor futuro para que el asistente lo recuerde en la próxima sesión.

### ¿Qué se guarda?

| Tipo de memoria | Ejemplo concreto |
|----------------|------------------|
| **Decisión arquitectónica** | "Elegimos PostgreSQL sobre MySQL por las funciones de array" |
| **Bug con causa raíz** | "El error de login era por cookie sin SameSite=Strict, no por el token" |
| **Descubrimiento no obvio** | "La API de pagos rechaza montos con más de 2 decimales" |
| **Preferencia del usuario** | "El usuario quiere commits en español y prefiere convención conventional-commits" |
| **Patrón reusable** | "Para validar emails, usamos la regex de OWASP, no una custom" |
| **Session summary** | Resumen de todo lo que se hizo en la sesión actual |

**NO se guarda nunca**: mensajes de conversación, logs de compilación, secretos, contraseñas, código fuente completo, errores transitorios ("no encontré el archivo", "intentá de nuevo").

### ¿Cómo se guarda? (mecánica concreta)

Cuando ocurre un evento relevante, el Manager llama a `mem_save` con esta estructura:

```
mem_save(
  title: "Elegimos PostgreSQL sobre MySQL",
  type: "decision",
  scope: "project",
  topic_key: "database/choice-postgresql",
  content: "
    **What**: Reemplazamos MySQL por PostgreSQL
    **Why**: Necesitábamos funciones de array para el módulo de reporting
    **Where**: docker-compose.yml, prisma/schema.prisma
    **Learned**: La migración no fue tan cara porque Prisma abstrae las diferencias
  "
)
```

**Qué pasa internamente**:

1. Engram recibe el llamado.
2. Asigna un **ID único** (ej: `480`) y un `sync_id` (`obs-f45f86aa09a86323`).
3. Si hay conflictos con memorias existentes, pide revisión (ver sección Noise Gate abajo).
4. La memoria queda disponible para futuras sesiones vía `mem_context` o `mem_search`.

### ¿Cómo se recupera?

Cuando empezás una nueva sesión y preguntás "¿qué hicimos con la base de datos?", el Manager ejecuta este flujo:

```
Pregunta: "¿qué hicimos con la base de datos?"
  → 1. mem_context() → busca sesiones recientes (rápido, barato en tokens)
  → 2. Si encuentra sesiones, las muestra con resumen
  → 3. Si NO encuentra, mem_search("base de datos") → búsqueda por keywords (FTS5)
  → 4. De los resultados, usa F4C Selector para rankear
  → 5. Solo toma las observaciones más relevantes (top 3-5)
  → 6. Responde con el contexto recuperado
```

### F4C Memory Context Selector (el sistema de ranking)

Cuando hay múltiples memorias, el Manager no las carga todas — las **rankea** por:

| Factor | Peso | Por qué |
|--------|------|---------|
| **Relevancia** | 50% | Qué tan relacionada está con lo que preguntaste |
| **Recencia** | 30% | Las decisiones recientes importan más que las viejas (decaen 5% por día) |
| **Tipo** | 20% | `decision` > `constraint` > `architecture` > `bugfix` > `discovery` > `config` |

**Ejemplo**: Si preguntás "¿qué base de datos usamos?", el Manager va a rankear:
1. ✅ `database/choice-postgresql` (decisión, 2 días atrás) — score alto
2. ⚠️ `database/migration-notes` (descubrimiento, 1 semana atrás) — score medio
3. ❌ `database/connection-string` (config, 3 meses atrás) — score bajo, probablemente descartado

Las memorias con el mismo `topic_key` se deduplican: solo queda la de mayor score.

---

## 7. Memoria entre sesiones: el flujo completo

Así funciona en la práctica con una sesión real de este mismo repositorio:

### Sesión 1 (día 1)

```
Usuario: "Agrega una función de validación de emails al proyecto"

Manager: Clasifica como Small, implementa, y al cerrar la sesión ejecuta:
→ mem_session_summary(
    Goal: "Agregar validación de emails"
    Accomplished: ✅ isEmailValid() en lib/validators.ts
    Next Steps: []
    Relevant Files: lib/validators.ts, lib/validators.test.ts
  )
→ mem_save(
    title: "isEmailValid con regex OWASP",
    type: "pattern",
    topic_key: "validation/email-pattern"
  )
```

### Entre sesiones

Los datos persisten:
- **OpenCode**: Engram MCP (servidor externo con base de datos dedicada)
- **Codex**: SQLite nativa (`memories_1.sqlite`)

No se pierden al cerrar el editor, apagar la PC, o cambiar de proyecto.

### Sesión 2 (día 2, sesión nueva)

```
Usuario: "Acordate de la validación de emails que hicimos ayer"

Manager (al recibir el mensaje):
→ 1. mem_context(project="mi-proyecto")
   → Encuentra: "Session summary: ... mi-proyecto" con Accomplished + Relevant Files
→ 2. mem_search("validación emails")
   → Encuentra: "isEmailValid con regex OWASP" (observación #42)
→ 3. Responde:
   "Sí, ayer creamos isEmailValid() en lib/validators.ts usando la regex de OWASP.
    ¿Necesitás modificarla o agregar algo?"
```

**Esto funciona aunque:**

- Hayas cerrado el editor.
- Hayas apagado la computadora.
- Hayas trabajado en otro proyecto entre medio.
- Hayan pasado días o semanas (las memorias no expiran, solo bajan de ranking).

---

## 8. Noise Gate: el filtro que decide qué merece guardarse

El Noise Gate no es un "plugin" que se instala. Es una **regla que el Manager sigue** antes de cada `mem_save`: clasificar la interacción y decidir si tiene valor futuro.

### Las 5 clases

| Clase | Significa | Ejemplo real | ¿Se guarda? |
|-------|-----------|-------------|-------------|
| **`instruction`** | El usuario pide trabajo o fija una decisión | "Cambiá la fuente de datos a PostgreSQL" | ✅ Si tiene valor futuro |
| **`question`** | El usuario pregunta algo | "¿Cómo se configura el rate limiting?" | ❌ |
| **`confirmation`** | El usuario aprueba, niega o continua | "Sí, aprobado", "dale", "ok" | ❌ |
| **`navigation`** | El usuario pide ver/abrir/inspeccionar | "Mostrame el archivo .env", "listá los tests" | ❌ |
| **`noise`** | Chatter, errores, texto pegado accidental | "ups", "jaja", "no funcionó" (sin contexto) | ❌ |

### El flujo de decisión

Cada vez que el Manager considera guardar algo, hace estas preguntas:

```
¿La interacción es una instrucción con valor futuro?
  → NO: no guardar (es question, confirmation, navigation o noise)
  → SÍ: seguir preguntando

¿Se tomó una decisión durable?
  → NO: no guardar
  → SÍ: guardar con type="decision"

¿Se corrigió un bug con causa raíz conocida?
  → NO: seguir
  → SÍ: guardar con type="bugfix"

¿Se descubrió algo no obvio?
  → NO: seguir
  → SÍ: guardar con type="discovery"

¿Se estableció una preferencia reusable?
  → NO: no guardar
  → SÍ: guardar con type="preference" o type="pattern"
```

### Ejemplos concretos de filtrado

**Entra** (se guarda):
> "A partir de ahora, todos los commits en español con conventional-commits"

→ Clasificación: `instruction` (establece preferencia reusable) → se guarda como `preference`

**No entra** (no se guarda):
> "mostrame la carpeta src"

→ Clasificación: `navigation` → no se guarda

**Entra** (se guarda):
> "El bug era que el webhook fallaba porque faltaba el header X-Signature. Lo fixeamos en `lib/webhooks.ts`"

→ Clasificación: `instruction` (describe un bug con causa raíz) → se guarda como `bugfix`

**No entra** (no se guarda):
> "sí, está bien"

→ Clasificación: `confirmation` → no se guarda

### ¿Por qué es importante?

Sin Noise Gate, el Manager guardaría **todo**: cada "sí", cada "mostrame", cada "jaja". La memoria se llenaría de ruido y las búsquedas serían inútiles. Con Noise Gate, la memoria tiene **señal, no ruido**.

---

## 9. Tokens: presupuesto y disciplina

Los tokens son el "papel" donde el asistente escribe su contexto. Este kit optimiza el uso de ese papel:

| Tipo de contexto | Qué incluye | Tamaño típico |
|-----------------|-------------|---------------|
| **Contexto fijo** | Instrucciones del Manager (siempre presente) | Pequeño (~2-5% del presupuesto) |
| **Contexto dinámico** | Skills cargados por trigger, docs largos | Mediano, bajo demanda |
| **Context packs** | Paquetes mínimos para subagentes (SDD) | Pequeño, solo lo necesario |
| **Memoria recuperada** | Observaciones de sesiones anteriores | Pequeño, top 3-5 rankeadas |

**Principio**: cargar solo lo que se necesita en el momento, no todo el proyecto siempre.

**Ver**: [`contracts/token-discipline.md`](contracts/token-discipline.md)

---

## 10. Validación: evidencia de que la memoria entre sesiones funciona

Este repositorio es la **prueba viviente** de que la memoria persistente funciona. Toda la documentación que estás leyendo, las decisiones arquitectónicas, y los bugs fixeados se guardaron usando este mismo sistema.

### Datos reales de este repositorio

```
$ mem_context(project="opencode-architecture")

→ 5 sesiones activas
→ 44 observaciones en la sesión principal
→ 379 observaciones totales en el proyecto
→ 14 sesiones a lo largo de 10 días
```

### Ejemplos de memorias reales guardadas durante el desarrollo

| Título | Tipo | Cuándo | Valor |
|--------|------|--------|-------|
| "v0.2.0 release — unified dual-runtime architecture" | decision | Hoy | Sabe que la release está completa |
| "Updated quickstarts and README with architecture flows" | architecture | Hoy | Sabe que se mejoraron los docs |
| "Completed Fase 6 cleanup for unified architecture" | architecture | Hoy | Sabe que la limpieza está hecha |
| "Fixed gentle-ai runtime test regex" | bugfix | Ayer | Sabe cómo se fixeó el test |
| "Chose Zustand over Redux" | decision | Sem. pasada | Sabe por qué se eligió Zustand |
| "Session summary: opencode-architecture" | session_summary | Cada sesión | Resumen de lo que se hizo |

### Cómo probarlo vos mismo

1. **Instalá el kit** siguiendo el [QuickStart correspondiente](QUICKSTART_OPENCODE.md).
2. **Hacé una pregunta**: "Acordate de que estamos probando la memoria"
3. **El Manager guarda** la preferencia.
4. **Cerá la sesión**, abrí una nueva.
5. **Preguntá**: "¿De qué estábamos hablando?"
6. El Manager va a buscar `mem_context()` y responder basado en la sesión anterior.

### ¿Qué pasa si no hay memoria?

Si es la primera vez que usás el kit o no hay sesiones previas, el Manager responde honestamente:

> "No encontré sesiones anteriores en este proyecto. Es la primera vez que trabajamos juntos aquí."

No inventa contexto falso. Eso también es parte del diseño.

**Ver**: [`contracts/memory-governance.md`](contracts/memory-governance.md) para las reglas completas.

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
