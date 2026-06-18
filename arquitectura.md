# Arquitectura del Runtime Kit — OpenCode & Codex

**Documento maestro de arquitectura**

Este documento describe en detalle la arquitectura del Runtime Kit que unifica el comportamiento de agente para **OpenCode** y **Codex**. Está escrito para dos audiencias: la sección no técnica explica el qué y el por qué; las secciones técnicas explican el cómo con detalle de componentes, flujos y contratos.

---

## Índice

1. [Para toda audiencia: qué es esto y por qué existe](#1-para-toda-audiencia-qué-es-esto-y-por-qué-existe)
2. [Modelo mental: el equipo de trabajo](#2-modelo-mental-el-equipo-de-trabajo)
3. [Vista general de la arquitectura](#3-vista-general-de-la-arquitectura)
4. [Capas de la arquitectura](#4-capas-de-la-arquitectura)
5. [Los 7 contratos portables](#5-los-7-contratos-portables)
6. [OpenCode en detalle](#6-opencode-en-detalle)
7. [Codex en detalle](#7-codex-en-detalle)
8. [Las 18 skills portables](#8-las-18-skills-portables)
9. [Flujo de datos: OpenCode](#9-flujo-de-datos-opencode)
10. [Flujo de datos: Codex](#10-flujo-de-datos-codex)
11. [Arquitectura de memoria](#11-arquitectura-de-memoria)
12. [Arquitectura del Noise Gate](#12-arquitectura-del-noise-gate)
13. [Arquitectura de tokens](#13-arquitectura-de-tokens)
14. [Cómo se comunican los componentes](#14-cómo-se-comunican-los-componentes)
15. [Beneficios por persona](#15-beneficios-por-persona)
16. [OpenCode vs Codex: cuándo usar cada uno](#16-opencode-vs-codex-cuándo-usar-cada-uno)
17. [Seguridad y límites](#17-seguridad-y-límites)
18. [Referencia completa de archivos](#18-referencia-completa-de-archivos)

---

## 1. Para toda audiencia: qué es esto y por qué existe

### El problema

Cuando usás un asistente de IA para programar (OpenCode, Codex, Cursor, etc.), cada conversación empieza desde cero. El asistente:

- **No recuerda** lo que hiciste en la sesión de ayer.
- **No sabe** las decisiones arquitectónicas que ya tomaste.
- **No distingue** entre un "sí, está bien" (ruido) y un "cambiamos la base de datos a PostgreSQL" (decisión importante).
- **Carga todo** el contexto cada vez, desperdiciando tokens en cosas que no necesita.

### La solución

Este Runtime Kit resuelve eso con cuatro ideas:

1. **Un Manager**: un agente que clasifica cada solicitud y decide el flujo correcto (respuesta directa para cosas simples, pipeline completo para cambios grandes).
2. **Memoria persistente**: las decisiones, bugs y descubrimientos se guardan entre sesiones. No importa si apagás la PC — al volver, el asistente retoma donde dejaste.
3. **Filtro de ruido (Noise Gate)**: no todo merece guardarse. El Manager decide qué tiene valor futuro y qué es conversación pasajera.
4. **Contratos portables**: las reglas son las mismas sin importar si usás OpenCode o Codex. Cambia solo cómo se implementan.

### ¿Para quién es?

| Persona | Qué obtiene |
|---------|-------------|
| **Programador individual** | Un asistente que recuerda decisiones entre sesiones, con skills especializados para diagramas, PRs, debugging, etc. |
| **Equipo de desarrollo** | Pipeline SDD estructurado con diseño, aprobación, code review y quality gates antes de implementar. |
| **Arquitecto** | Contratos portables que garantizan el mismo comportamiento sin importar el runtime. |
| **No técnico** | Un asistente que explica la arquitectura con metáforas simples y no asume conocimiento técnico. |

---

## 2. Modelo mental: el equipo de trabajo

Imaginate que tu asistente de IA es un **equipo de trabajo**:

```
┌──────────────────────────────────────────────────┐
│                   EL EQUIPO                        │
│                                                    │
│  🧑‍💼 Manager (el líder)                           │
│     Escucha, clasifica, delega, revisa             │
│                                                    │
│  📓 Cuaderno de bitácora (memoria persistente)    │
│     Guarda decisiones, bugs, descubrimientos       │
│                                                    │
│  🚪 Noise Gate (el asistente del líder)           │
│     "Jefe, esto es importante, lo anoto"          │
│     "Esto es ruido, lo ignoro"                    │
│                                                    │
│  📋 Token Budgeter (el que vigila el papel)       │
│     "Nos quedan 3000 tokens, usemos solo lo      │
│      necesario"                                    │
│                                                    │
│  🧠 Skills (los especialistas)                    │
│     Diagramas de flujo, PRs, debugging, diseño    │
│     Se llaman solo cuando se los necesita         │
│                                                    │
│  📐 SDD Pipeline (el proceso estructurado)        │
│     Para cambios grandes: diseñar, aprobar,        │
│     implementar, verificar, archivar               │
└──────────────────────────────────────────────────┘
```

**El Manager es el único que decide.** Los skills no deciden, ejecutan. El Noise Gate no guarda, clasifica. La memoria no busca sola, el Manager decide cuándo buscar.

---

## 3. Vista general de la arquitectura

```
┌═══════════════════════════════════════════════════════════════┐
║                   CAPA 0: USUARIO                             ║
║  El usuario hace una solicitud en lenguaje natural            ║
╚═══════════════════════════════════════════════════════════════╝
                              │
                              ▼
┌═══════════════════════════════════════════════════════════════┐
║                   CAPA 1: MANAGER                              ║
║  ┌─────────────────────────────────────────────────────────┐  ║
║  │ Clasifica: Tiny / Small / Medium / Large                │  ║
║  │ Decide flujo: directo / diseño / pipeline completo      │  ║
║  │ Delega a skills o subagentes cuando corresponde         │  ║
║  └─────────────────────────────────────────────────────────┘  ║
╚═══════════════════════════════════════════════════════════════╝
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌─────────────────────┐ ┌──────────┐ ┌──────────────┐
│  CAPA 2: CONTRATOS   │ │  SKILLS  │ │   MEMORIA    │
│  (portables)         │ │ (18)     │ │  (Engram /   │
│  manager.md          │ │          │ │   SQLite)    │
│  sdd-pipeline.md     │ │ Cargados │ │              │
│  memory-governance.md│ │ por      │ │ mem_save()   │
│  noise-gate.md       │ │ trigger  │ │ mem_search() │
│  token-discipline.md │ │          │ │ mem_context()│
│  context-pack.md     │ │          │ │              │
│  ponytail.md         │ │          │ │              │
└─────────────────────┘ └──────────┘ └──────────────┘
                              │               │
                              ▼               ▼
┌═══════════════════════════════════════════════════════════════┐
║              CAPA 3: ADAPTADORES RUNTIME                      ║
║                                                               ║
║  ┌────────────────────────┐  ┌────────────────────────┐      ║
║  │     OPENCODE           │  │       CODEX            │      ║
║  │                        │  │                        │      ║
║  │ Subagentes @sdd-*     │  │ Scripts autónomos      │      ║
║  │ Graphify Context Gate │  │ Skills portables        │      ║
║  │ Frontend Design Gate  │  │ Memory-lint validador   │      ║
║  │ GPT-5.5 Review        │  │ Context-pack-check      │      ║
║  │ Engram MCP            │  │ Token-budget-report     │      ║
║  │                       │  │ Rollback overlay        │      ║
║  │ Manager: 15 secciones │  │ Manager: ~80 líneas     │      ║
║  └────────────────────────┘  └────────────────────────┘      ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 4. Capas de la arquitectura

### Capa 0 — Usuario

El usuario interactúa con el asistente en lenguaje natural. No necesita saber qué runtime está usando ni cómo está implementada la arquitectura.

### Capa 1 — Manager

El Manager es el **orquestador primario**. Es el único componente que toma decisiones. Todo pasa por él:

| Responsabilidad | Descripción |
|----------------|-------------|
| **Clasificación** | Tiny (respuesta directa), Small (1 archivo), Medium (múltiples archivos), Large (arquitectura/producción) |
| **Intake** | Entender qué quiere el usuario, por qué, y para qué |
| **Diseño** | Presentar enfoques, obtener aprobación antes de implementar |
| **Routing** | Delegar a skills, subagentes o gates según corresponda |
| **Memoria** | Decidir qué guardar, qué recuperar, cuándo buscar |
| **Contexto** | Controlar qué se carga y qué no (context packs, lazy-load) |
| **Calidad** | Code Review, Judgment Day, GPT-5.5 review antes de completar |
| **Síntesis** | Armar la respuesta final basada en todo lo ejecutado |

El Manager **nunca delega la decisión**. Skills y subagentes ejecutan trabajo acotado y devuelven resultados. El Manager revisa y sintetiza.

### Capa 2 — Contratos, Skills y Memoria

**Contratos portables** (`contracts/`): 7 archivos que definen QUÉ hace cada componente, de forma runtime-agnóstica. Ver sección 5.

**Skills** (`skills/`): 18 especialistas cargados bajo demanda por trigger. Ver sección 8.

**Memoria**: Persistente entre sesiones. En OpenCode usa Engram MCP, en Codex usa SQLite nativa. Ver sección 11.

### Capa 3 — Adaptadores Runtime

**OpenCode** (`opencode/`): Adaptador completo con subagentes, gates, instalador overlay y tests.

**Codex** (`codex/`): Adaptador compacto con scripts autónomos, skills portables y validación.

---

## 5. Los 7 contratos portables

Los contratos viven en `contracts/` y son el **corazón de la arquitectura**. Definen reglas que no dependen del runtime.

| Contrato | ¿Qué define? | ¿Por qué existe? |
|----------|-------------|------------------|
| [`contracts/manager.md`](contracts/manager.md) | El Manager como único orquestador primario, sus responsabilidades, cómo clasifica, cómo delega | Sin esto, cualquier subagente podría tomar decisiones que no le corresponden |
| [`contracts/sdd-pipeline.md`](contracts/sdd-pipeline.md) | Las 8 fases del pipeline SDD: Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive | Cambios grandes necesitan estructura o se vuelven inmanejables |
| [`contracts/memory-governance.md`](contracts/memory-governance.md) | Qué se guarda, qué no, cómo se recupera, F4C scoring, session close | Sin reglas, la memoria se llena de ruido o se guarda todo |
| [`contracts/noise-gate.md`](contracts/noise-gate.md) | Clasificación de interacciones, cuándo guardar, cuándo rechazar, formato de reporte | El filtro que separa señal de ruido antes de guardar |
| [`contracts/token-discipline.md`](contracts/token-discipline.md) | Presupuesto de tokens, contexto fijo vs dinámico, context packs | Los tokens son finitos — hay que usarlos con criterio |
| [`contracts/context-pack-schema.md`](contracts/context-pack-schema.md) | Formato de context packs: clasificación, token_budget, included/excluded, sensitivity | Los subagentes necesitan contexto mínimo, no todo el proyecto |
| [`contracts/ponytail.md`](contracts/ponytail.md) | Preguntas antes de implementar: ¿esto existe? ¿stdlib? ¿una línea? | Evita sobreingeniería sin sacrificar seguridad |

Cada contrato incluye una sección **Runtime Adaptations** que documenta las diferencias entre OpenCode y Codex. Esa sección es la fuente de verdad para entender qué cambia entre runtimes.

---

## 6. OpenCode en detalle

### Manager Template (`opencode/manager.template.md`)

218 líneas, 15 secciones. Es el Manager más completo del kit.

```
┌─────────────────────────────────────────────────────────────┐
│              OPENCODE MANAGER (15 secciones)                  │
│                                                               │
│  1. Clasificación de Solicitudes (Tiny/Small/Medium/Large)   │
│  2. Superpowers Brainstorming (Intake)                       │
│  3. Diseño y Aprobación                                      │
│  4. Graphify Context Gate                                    │
│  5. SDD Pipeline (8 fases)                                   │
│  6. Frontend Design Gate                                     │
│  7. TDD (Test-Driven Development)                            │
│  8. Code Review                                              │
│  9. GPT-5.5 Final Review                                     │
│  10. Debugging Sistemático                                   │
│  11. Engram Memory (auto-triggers)                           │
│  12. Ponytail Code Gate                                      │
│  13. Fast-Track Exceptions                                   │
│  14. Default Behavior                                        │
│  15. Completion Contract                                     │
└─────────────────────────────────────────────────────────────┘
```

### Gates específicos de OpenCode

**Graphify Context Gate**: Para tareas de 4+ archivos, construye un grafo de relaciones del proyecto. Ayuda a identificar archivos afectados, dependencias ocultas y riesgos antes de SDD Explore. No instala Graphify automáticamente — pide aprobación.

**Frontend Design Gate**: Para tareas frontend, genera/lee DESIGN.md, define dirección estética (frontend-design, canvas-design, design-md), y pasa el contexto a SDD Design.

**GPT-5.5 OAuth Final Review**: Quality gate final usando GPT-5.5 para revisar diff, seguridad, performance y edge cases.

### Subagentes SDD

OpenCode usa subagentes `@sdd-*` para cada fase del pipeline:

| Fase | Subagente | Qué hace |
|------|-----------|----------|
| Explore | `@sdd-explore` | Investiga codebase, identifica áreas afectadas, riesgos |
| Propose | `@sdd-propose` | Convierte diseño en propuesta estructurada |
| Spec | `@sdd-spec` | Escribe escenarios Given/When/Then |
| Design | `@sdd-design` | Diseño técnico: componentes, interfaces, flujo |
| Tasks | `@sdd-tasks` | Desglosa en tareas pequeñas con file impact map |
| Apply | `@sdd-apply` | Implementa código aprobado |
| Verify | `@sdd-verify` | Valida contra spec y tasks |
| Archive | `@sdd-archive` | Sincroniza specs finales, guarda en Engram |

### Frontend Specialist

Para tareas frontend, OpenCode puede delegar la implementación a `@frontend-specialist`: un subagente especializado en React, Next.js, Tailwind CSS, accesibilidad y responsive.

### Memoria: Engram MCP

OpenCode usa **Engram** como sistema de memoria persistente:

- **Protocolo MCP**: Engram corre como servidor MCP, accesible via herramientas `mem_save`, `mem_search`, `mem_context`, `mem_session_summary`.
- **Auto-triggers**: El Manager guarda automáticamente después de decisiones arquitectónicas, bug fixes, descubrimientos, preferencias del usuario.
- **Session close**: Siempre ejecuta `mem_session_summary` con Goal, Instructions, Discoveries, Accomplished, Next Steps, Relevant Files.
- **Deduplicación**: Si dos observaciones tienen el mismo `topic_key`, la de mayor score reemplaza a la anterior.
- **Conflict detection**: Cuando una nueva memoria podría conflictuar con una existente, Engram pide revisión al Manager via `mem_judge`.

---

## 7. Codex en detalle

### Manager Template (`codex/manager.template.md`)

~76 líneas, compacto. Codex no tiene subagentes nativos, así que el Manager se enfoca en:

```
┌─────────────────────────────────────────────────────────────┐
│               CODEX MANAGER (~76 líneas)                     │
│                                                               │
│  Manager contract (orquestador primario)                     │
│  Response contract (respuestas cortas por defecto)           │
│  Context Pack rule (contexto mínimo antes de cargar)         │
│  Memory retrieval (orden de búsqueda)                        │
│  Skills (lazy-load por trigger)                              │
│  Ponytail guidance (anti-sobreingeniería)                    │
│  Review and quality (verificación antes de done)             │
└─────────────────────────────────────────────────────────────┘
```

### Scripts autónomos de Codex

Codex incluye 8 scripts que ejecutan tareas específicas:

| Script | `pnpm` | Función |
|--------|--------|---------|
| `codex/scripts/install-overlay.mjs` | `codex:install` | Instala el overlay en el directorio destino, con backup automático |
| `codex/scripts/doctor.mjs` | `codex:doctor` | Valida que el overlay esté instalado correctamente |
| `codex/scripts/rollback-overlay.mjs` | `codex:rollback` | Restaura el backup del overlay anterior |
| `codex/scripts/memory-lint.mjs` | `codex:memory:lint` | Valida archivos de memoria (formato, tipos, paths) |
| `codex/scripts/context-pack-check.mjs` | `codex:context:check` | Valida context packs (budget, sensitivity, included fields) |
| `codex/scripts/token-budget-report.mjs` | `codex:tokens:report` | Genera reporte de uso de tokens |
| `codex/scripts/skill-registry-generate.mjs` | `codex:registry` | Genera el registro de skills desde SKILL.md files |
| `codex/scripts/backup.mjs` | `backup:plan` | Backup de scripts core |

### Memoria: SQLite nativa

Codex no tiene Engram MCP. Usa **memoria SQLite nativa** con:

- Tabla de observaciones con tipo, scope, contenido y metadata.
- Búsqueda FTS5 (Full-Text Search) para `mem_search`.
- Noise Gate como paso explícito antes de guardar.
- `memory-lint` script para validar integridad de archivos de memoria.

### Skills en Codex

Codex carga skills desde `skills/opencode-runtime-kit/`. El Manager usa lazy-load: lee el `SKILL.md` solo cuando el trigger coincide. Ver sección 8 para la lista completa.

---

## 8. Las 18 skills portables

Los skills viven en `skills/` y funcionan en **ambos runtimes**. Se cargan **bajo demanda** cuando el usuario menciona algo que coincide con su trigger.

| Skill | Trigger | Qué hace |
|-------|---------|----------|
| **manager-router** | Clasificar solicitudes, elegir ruta | Decide si una solicitud es Tiny/Small/Medium/Large |
| **memory-governance** | Memoria, recordar, guardar | Reglas de escritura y recuperación de memoria |
| **noise-gate** | Ruido, clasificar, filtrar | Clasifica interacciones antes de guardar |
| **context-pack-builder** | Contexto mínimo, pack | Construye paquetes de contexto para subagentes |
| **token-budgeter** | Tokens, presupuesto, contexto | Estima y reduce costos de tokens |
| **work-unit-commits** | Commits, implementación | Planifica commits revisables |
| **chained-pr** | PR grande, 400+ líneas | Divide PRs grandes en PRs encadenados |
| **branch-pr** | Pull request, PR | Crea PRs con verificación previa |
| **issue-creation** | GitHub issue, bug report | Crea issues con checklist |
| **judgment-day** | Revisión, juzgar, adversarial | Revisión dual a ciegas |
| **deploy-security-gate** | Predeploy, producción, seguridad | Revisa readiness de deploy |
| **cognitive-doc-design** | Documentación, guías, RFCs | Escribe documentación de baja carga cognitiva |
| **flow-diagram** | Diagrama, flujo, diagrama de flujo | Genera diagramas ASCII de flujo |
| **web-design-guidelines** | UI audit, accesibilidad | Auditoría contra guías Vercel |
| **skill-improver** | Mejorar skills, calidad skills | Audita y mejora skills existentes |
| **bigquery-table-cleaning** | BigQuery, limpiar tablas | Diagnostica y crea copias limpias |
| **sandbox-data-loader** | CSV, XLSX, subir datos | Carga y perfila archivos de datos |
| **sql-learning** | SQL, reglas de negocio | Captura lecciones de SQL |

**¿Por qué skills portables en lugar de plugins?**

Los plugins TypeScript son específicos de OpenCode y no funcionan en Codex. Los skills son archivos Markdown con frontmatter que cualquier runtime puede leer. Esto permite:

- Un solo skill para ambos runtimes.
- Trigger explícito en la descripción.
- Workflow detallado sin código compilado.
- Fáciles de crear, modificar y compartir.

---

## 9. Flujo de datos: OpenCode

### Solicitud Tiny

```
Usuario: "¿Cuánto es 2+2?"

Manager clasifica: Tiny (respuesta clara, sin cambios de archivo)
  → Responde directo: "4"
  → Fin
```

### Solicitud Small

```
Usuario: "Agrega un comando 'format' al Makefile que ejecute Prettier"

Manager clasifica: Small (1 archivo, bajo riesgo)
  → Intake: "¿Solo Prettier o también ESLint?"
  → Diseño: "Agregar una línea 'format:' al Makefile"
  → Aprueba el usuario
  → Aplica: edita Makefile
  → Verifica: corre `make format`
  → Code Review
  → Responde con diff
  → mem_session_summary al cerrar
```

### Solicitud Medium/Large

```
Usuario: "Agrega autenticación con Google OAuth al proyecto"

Manager clasifica: Medium (múltiples archivos, API, lógica de negocio)

  → 1. SUPERPOWERS BRAINSTORMING
       ¿Qué problema resuelve? Login social
       ¿Qué archivos tocar? rutas, controladores, frontend
       ¿Qué NO tocar? base de datos existente

  → 2. DISEÑO con 2-3 enfoques
       Opción A: Passport.js
       Opción B: next-auth (si es Next.js)
       Opción C: custom middleware
       Recomendación: B (next-auth, ya instalado)

  → 3. APROBACIÓN del usuario

  → 4. GRAPHIFY CONTEXT GATE (si 4+ archivos)
       "Mostrame relaciones entre auth y user model"
       Graphify responde: auth/middleware.ts → user/model.ts → db/schema.ts

  → 5. SDD PIPELINE
       Explore: @sdd-explore → investiga codebase, encuentra auth setup actual
       Propose: @sdd-propose → propuesta estructurada del cambio
       Spec: @sdd-spec → escenarios Given/When/Then
       Design: @sdd-design → componentes, interfaces, flujo OAuth
       Tasks: @sdd-tasks → 5 tareas pequeñas con file impact map
       Apply: @sdd-apply → implementa tarea por tarea
       Verify: @sdd-verify → valida contra spec, corre tests

  → 6. QUALITY GATES
       Code Review: revisa diff, edge cases, seguridad
       Judgment Day (opcional): revisión dual a ciegas
       GPT-5.5 Review: quality gate final

  → 7. RESPUESTA + MEMORIA
       Responde con resumen, archivos cambiados, tests
       mem_save: "Google OAuth implementado con next-auth"
       mem_session_summary al cerrar
```

---

## 10. Flujo de datos: Codex

### Solicitud directa

```
Usuario: "¿Qué skills tenés disponibles?"

Manager clasifica: pregunta simple
  → No necesita memoria, no necesita skills
  → Lista los skills instalados en skill-registry.md
  → Responde
```

### Solicitud con skill

```
Usuario: "Necesito un diagrama de flujo para el login"

Manager:
  → 1. Busca en memoria: ¿hay contexto de login?
       mem_context() → "no hay sesiones previas sobre login"

  → 2. Clasifica: necesita skill de diagramas
       "diagrama de flujo" → trigger de flow-diagram

  → 3. Carga skill: lee skills/flow-diagram/SKILL.md
       El skill dice: recibir descripción del proceso, generar ASCII flow

  → 4. Ejecuta: el Manager sigue las instrucciones del skill
       Genera el diagrama con entidades, decisiones, flujos de error

  → 5. Responde con el diagrama ASCII

  → 6. Memoria: si es un descubrimiento reusable, guarda

  → 7. Session summary al cerrar
```

### Solicitud de implementación

```
Usuario: "Creá una Pull Request para el fix de caché que hicimos ayer"

Manager:
  → 1. MEMORIA: busca contexto del fix de caché
       mem_context() → sesión de ayer
       mem_search("fix caché") → bugfix observación con causa raíz

  → 2. CONTEXT PACK: arma paquete mínimo
       Incluye: memoria del fix, skill branch-pr, skill work-unit-commits
       Token budget: 3000

  → 3. SKILLS: carga branch-pr + work-unit-commits
       work-unit-commits planifica commits
       branch-pr prepara la PR

  → 4. EJECUTA según instrucciones de skills

  → 5. VERIFICA: la PR se creó? el branch existe?

  → 6. RESPUESTA: "PR #43 creada para fix de caché. 2 commits, 3 archivos modificados."

  → 7. MEMORIA: "PR #43 creada para fix de caché en Redis client"
```

---

## 11. Arquitectura de memoria

### Visión general

```
┌────────────────────────────────────────────────────────────┐
│                    MEMORIA PERSISTENTE                       │
│                                                            │
│  ESCRITURA:                        RECUPERACIÓN:           │
│  ┌──────────────┐                 ┌──────────────────┐    │
│  │ Noise Gate   │                 │ mem_context()    │    │
│  │ clasifica     │──→ sí/no→      │ (sesiones recientes)│    │
│  │ la interacción│                 └──────────────────┘    │
│  └──────────────┘                        │                 │
│         │                                ▼                 │
│         ▼                        ┌──────────────────┐     │
│  ┌──────────────┐                │ mem_search()     │     │
│  │ mem_save()   │                │ (FTS5 keywords)  │     │
│  │ type:        │                └──────────────────┘     │
│  │ architecture │                       │                 │
│  │ decision     │                       ▼                 │
│  │ bugfix       │               ┌──────────────────┐      │
│  │ discovery    │               │ F4C Selector     │      │
│  │ session_sum  │               │ rankea por       │      │
│  └──────────────┘               │ relevancia(0.5)  │      │
│         │                       │ recencia(0.3)    │      │
│         ▼                       │ tipo(0.2)        │      │
│  ┌──────────────┐               └──────────────────┘      │
│  │ ALMACENAMIENTO│                      │                 │
│  │ OpenCode:     │                      ▼                 │
│  │   Engram MCP  │              ┌──────────────────┐      │
│  │ Codex:       │              │ Top 3-5 results  │      │
│  │   SQLite FTS5 │              │ + dedup por key  │      │
│  └──────────────┘              └──────────────────┘      │
│                                                            │
│  SESIONES:                         CONFLICTOS:             │
│  ┌──────────────┐                 ┌──────────────────┐    │
│  │ Session open │                 │ mem_save detecta │    │
│  │ → mem_context│                 │ memoria similar  │    │
│  │ → búsqueda   │                 │ → mem_judge()    │    │
│  │   automática  │                 │ → Manager decide  │    │
│  └──────────────┘                 └──────────────────┘    │
│                                                            │
│  Session close: mem_session_summary SIEMPRE                │
└────────────────────────────────────────────────────────────┘
```

### F4C Memory Context Selector

Cuando hay múltiples memorias candidatas, el Manager no las carga todas. Las **ranquea**:

| Factor | Peso | Fórmula |
|--------|------|---------|
| **Relevancia** | 0.5 | Qué tan relacionada está semánticamente con la consulta |
| **Recencia** | 0.3 | `max(0, 1 - díasTranscurridos * 0.05)` — las decisiones viejas decaen |
| **Tipo** | 0.2 | decision > constraint > architecture > bugfix > discovery > config > other |

**Score final**: `relevancia * 0.5 + recencia * 0.3 + tipo * 0.2`

**Deduplicación**: Si dos memorias tienen el mismo `topic_key`, solo la de mayor score sobrevive.

**Top-K por defecto**: 10 resultados normales, 20 para tareas de arquitectura, 5 para consultas simples.

### Session Close

Cada sesión termina con `mem_session_summary`:

```
## Goal
[Una línea: qué se hizo en la sesión]

## Instructions
[Preferencias del usuario descubiertas, si las hay]

## Discoveries
- [Hallazgos técnicos, gotchas, aprendizajes no obvios]

## Accomplished
- ✅ [Tarea completada con detalles clave]

## Next Steps
- [Lo que queda pendiente para la próxima sesión]

## Relevant Files
- path/to/file — [qué hace o qué cambió]
```

Este resumen es lo primero que ve el Manager en la sesión siguiente.

---

## 12. Arquitectura del Noise Gate

El Noise Gate **no es un plugin ni un servicio**. Es una **regla de decisión** que el Manager sigue antes de cada `mem_save`.

### Flujo de decisión

```
Llega una interacción del usuario
  │
  ▼
¿Qué tipo de interacción es?
  │
  ├── instruction (el usuario pide trabajo o toma decisión)
  │     └─ ¿Tiene valor futuro?
  │           ├─ Sí → ¿Cumple alguna condición de guardado?
  │           │         ├─ Decisión durable → GUARDAR como decision
  │           │         ├─ Bug con causa raíz → GUARDAR como bugfix
  │           │         ├─ Preferencia reusable → GUARDAR como preference
  │           │         └─ No → NO GUARDAR
  │           └─ No → NO GUARDAR
  │
  ├── question (el usuario pregunta)
  │     └─ NO GUARDAR
  │
  ├── confirmation (sí, ok, dale, aprobado)
  │     └─ NO GUARDAR
  │
  ├── navigation (mostrame, listá, abrí)
  │     └─ NO GUARDAR
  │
  └── noise (chatter, error transitorio, pegado accidental)
        └─ NO GUARDAR
```

### Ejemplos reales de clasificación

| Prompt del usuario | Clasificación | ¿Guarda? | ¿Por qué? |
|-------------------|---------------|----------|-----------|
| "Cambiá la fuente de datos a PostgreSQL" | instruction | ✅ Sí | Decisión durable que afecta toda la arquitectura |
| "El bug era que el webhook fallaba por X-Signature" | instruction | ✅ Sí | Bug con causa raíz documentada |
| "A partir de ahora commits en español" | instruction | ✅ Sí | Preferencia reusable |
| "¿Cómo se configura el rate limiting?" | question | ❌ No | Pregunta, no acción |
| "Sí, aprobado" | confirmation | ❌ No | No tiene valor futuro |
| "Mostrame el archivo .env" | navigation | ❌ No | Acción temporal |
| "jaja" | noise | ❌ No | Chatter |
| "no funcionó" (sin contexto) | noise | ❌ No | Error transitorio sin causa raíz |
| "La API de pagos rechaza montos con >2 decimales" | instruction | ✅ Sí | Descubrimiento no obvio del sistema |

### Conflicto de memorias

Cuando `mem_save` detecta que la nueva memoria podría conflictuar con una existente (mismo topic_key, contenido contradictorio), entra en modo **conflict review**:

```
mem_save detecta conflicto:
  Memoria existente: "Usamos MySQL para la DB principal" (hace 5 días)
  Nueva memoria:    "Migramos de MySQL a PostgreSQL" (hoy)

  → judgment_required: true
  → Manager recibe candidates[] con ambas memorias
  → Manager decide: "la nueva supersede a la anterior"
  → mem_judge(judgment_id, relation="supersedes")
  → La memoria antigua queda marcada como reemplazada
```

Si el Manager no tiene suficiente confianza (<0.7), **pregunta al usuario**.

---

## 13. Arquitectura de tokens

### Los tres tipos de contexto

```
CONTEXTO TOTAL DISPONIBLE (ej: 128K tokens)
│
├── CONTEXTO FIJO (~2-5%)
│   Instrucciones del Manager (siempre presente)
│   Contratos y reglas base
│
├── CONTEXTO DINÁMICO (~20-40%, bajo demanda)
│   Skills cargados por trigger
│   Docs largos referenciados
│   Memoria recuperada de sesiones anteriores
│
└── CONTEXTO DE SUBAGENTES (context packs)
    Paquetes mínimos para @sdd-* o skills
    Solo incluyen lo necesario para la tarea
```

### Context Packs

Cuando el Manager delega a un subagente o skill, no le pasa todo el contexto — arma un **context pack**:

```json
{
  "request_id": "20260618-1500-medium",
  "classification": "medium",
  "token_budget": 4000,
  "included": [
    {
      "kind": "memory",
      "ref": "obs-123",
      "reason": "Decisión de arquitectura relevante",
      "sensitivity": "low"
    },
    {
      "kind": "file",
      "ref": "src/auth/middleware.ts",
      "reason": "Archivo afectado por el cambio",
      "sensitivity": "low"
    }
  ],
  "excluded": [
    {
      "ref": "docs/archive/old-notes.md",
      "reason": "Irrelevante para esta tarea"
    }
  ]
}
```

Reglas:
- **Token budget**: nunca más del presupuesto asignado.
- **Sensitivity**: si es `high`, se rechaza el pack (podría contener secretos).
- **Cada item incluido necesita un reason**: si no hay razón, no se incluye.
- **Máximo 8 items** por defecto.

### Herramientas de token

Codex tiene scripts específicos para gestionar tokens:

| Comando | Qué hace |
|---------|----------|
| `pnpm codex:tokens:report` | Reporta tokens estimados por skill y doc |
| `pnpm codex:context:check` | Valida context packs existentes |

OpenCode usa el Token Budgeter skill para lo mismo.

---

## 14. Cómo se comunican los componentes

### OpenCode

```
USUARIO
  │  (lenguaje natural)
  ▼
MANAGER (opencode/manager.template.md)
  │
  ├──→ SKILLS (skills/*/SKILL.md)
  │     El Manager lee el skill, sigue sus instrucciones
  │     El skill NO toma decisiones, solo ejecuta
  │     ← Devuelve resultado (texto, diagrama, código)
  │
  ├──→ SUBAGENTES (@sdd-*)
  │     El Manager delega una fase SDD
  │     El subagente ejecuta trabajo acotado
  │     ← Devuelve SUBAGENT_RESULT (envelope compacto)
  │
  ├──→ MEMORIA (Engram MCP)
  │     mem_save() → guarda observación
  │     mem_search() → busca por keywords
  │     mem_context() → contexto de sesiones recientes
  │     mem_session_summary() → cierre de sesión
  │     ← Devuelve observaciones o confirmación
  │
  ├──→ GATES
  │     Graphify: grafo de relaciones del proyecto
  │     GPT-5.5: review/debug externo
  │     ← Devuelve análisis o veredicto
  │
  └──→ RESPUESTA AL USUARIO
        El Manager sintetiza todo y responde
```

### Codex

```
USUARIO
  │  (lenguaje natural)
  ▼
MANAGER (codex/manager.template.md)
  │
  ├──→ SKILLS (skills/opencode-runtime-kit/*/SKILL.md)
  │     El Manager lee el skill, sigue sus instrucciones
  │     ← Devuelve resultado
  │
  ├──→ MEMORIA (SQLite FTS5)
  │     Búsqueda nativa con FTS5
  │     Memory-lint script para validación
  │     ← Devuelve observaciones
  │
  ├──→ SCRIPTS (codex/scripts/*.mjs)
  │     Install, doctor, rollback, memory-lint, etc.
  │     ← Devuelve salida de consola
  │
  └──→ RESPUESTA AL USUARIO
        El Manager sintetiza todo y responde
```

### Principios de comunicación

1. **El Manager siempre inicia**: ningún componente habla sin ser llamado.
2. **Comunicación síncrona**: el Manager espera el resultado antes de continuar.
3. **Envelope compacto**: subagentes devuelven solo lo necesario (no todo el contexto).
4. **Sin loops**: skills y subagentes no llaman al Manager ni a otros skills/subagentes.
5. **El Manager sintetiza**: los componentes ejecutan, el Manager arma la respuesta final.

---

## 15. Beneficios por persona

### Para el programador individual

- **Memoria entre sesiones**: no tenés que repetir contexto cada vez que abrís el editor.
- **Skills especializados**: diagramas, PRs, debugging, diseño UI — todo desde el chat.
- **Menos ruido**: el Noise Gate filtra lo que no merece guardarse.
- **Contexto eficiente**: se carga solo lo necesario, ahorrando tokens.

### Para el equipo

- **Pipeline SDD estructurado**: Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive.
- **Quality gates**: Code Review, Judgment Day, GPT-5.5 review antes de completar.
- **Contratos portables**: el mismo comportamiento en OpenCode y Codex.
- **Decisiones registradas**: cada decisión arquitectónica queda en memoria persistente.

### Para el arquitecto

- **Separación de concerns**: contratos portables (`contracts/`), adaptadores runtime-specific (`opencode/`, `codex/`), skills compartidos (`skills/`).
- **Runtime Adaptations documentadas**: cada contrato especifica las diferencias entre OpenCode y Codex.
- **Validación automatizada**: `pnpm test:all` verifica integridad de todo el kit.
- **Perfiles seleccionables**: minimal, agents, sdd, memory-enabled, full, codex, codex-full.

### Para el no técnico

- **Explicaciones con metáforas**: el equipo de trabajo (Manager, memoria, Noise Gate, skills).
- **Documentación en español**: README, quickstarts, arquitectura — todo explicado para no asumir conocimiento previo.
- **Flujo visible**: cada solicitud sigue un proceso predecible y documentado.

---

## 16. OpenCode vs Codex: cuándo usar cada uno

| Aspecto | OpenCode | Codex |
|---------|----------|-------|
| **Complejidad del Manager** | Alta (218 líneas, 15 secciones) | Baja (~76 líneas, compacto) |
| **Subagentes** | `@sdd-*`, `@frontend-specialist`, etc. | No tiene subagentes nativos |
| **Gates** | Graphify, Frontend Design, GPT-5.5 | Skills portables + verificación inline |
| **Memoria** | Engram MCP (servidor externo) | SQLite nativa con FTS5 |
| **Skills** | Desde `skills/` (portables) | Desde `skills/` (portables) |
| **Scripts** | Instalador overlay + doctor | 8 scripts: install, doctor, rollback, memory-lint, context-pack-check, token-budget-report, skill-registry, backup |
| **Tests** | 4 tests (97 total del kit) | 34 tests (97 total del kit) |
| **Mejor para** | Proyectos grandes con equipo, APIs, auth, producción, cambios estructurados | Proyectos personales, scripts, experimentos, flujo liviano |
| **Cuando elegirlo** | Necesitás pipeline SDD completo, quality gates, y memoria gobernada por Engram | Necesitás skills portables y memoria sin la complejidad del pipeline OpenCode |
| **Costo de setup** | Medio (instalar overlay, configurar Engram) | Bajo (instalar overlay, ya tiene memoria nativa) |

**Regla general**: si tu proyecto tiene 2+ desarrolladores, APIs externas, autenticación o bases de datos → OpenCode. Si es un proyecto personal o experimental → Codex.

**Pueden convivir**: el kit está diseñado para que uses OpenCode en proyectos grandes y Codex en proyectos personales, con los mismos contratos y skills.

---

## 17. Seguridad y límites

### Lo que el kit NO hace

- **No modifica binarios** de OpenCode ni Codex.
- **No se instala automáticamente**: require `pnpm codex:install` o copia manual.
- **No ejecuta código no revisado**: el Manager pasa por Code Review antes de completar.
- **No expone secretos**: el Noise Gate rechaza contenido con alta sensibilidad.
- **No escribe fuera del directorio destino**: el instalador overlay escribe solo en `<target>/`.

### Lo que el kit garantiza

- **Backup antes de instalar**: el overlay siempre respalda el AGENTS.md existente.
- **Rollback**: un comando restaura el backup.
- **Dry-run**: podés ver el plan de instalación sin escribir nada.
- **Validación**: `doctor`, `validate` y `test:all` verifican integridad.
- **Portabilidad**: ningún archivo del kit contiene rutas absolutas o datos personales.

### Límites

- **Tokens**: el contexto disponible depende del modelo (128K para GPT-4, 200K para Claude, etc.). El kit optimiza el uso, no expande el límite.
- **Memoria**: Engram (OpenCode) tiene su propio límite de almacenamiento. Codex usa SQLite local (limitado por disco).
- **Subagentes**: OpenCode necesita subagentes `@sdd-*` instalados para el pipeline SDD completo. Si no están, el Manager ejecuta inline.

---

## 18. Referencia completa de archivos

### Raíz

| Archivo | Propósito |
|---------|-----------|
| `README.md` | Entry point principal con quickstarts, contratos y arquitectura simplificada |
| `arquitectura.md` | **Este documento**: arquitectura maestra detallada |
| `ARCHITECTURE.md` | Vista técnica resumida de contratos y adaptadores |
| `QUICKSTART_OPENCODE.md` | 5 pasos para instalar en OpenCode con pruebas |
| `QUICKSTART_CODEX.md` | 5 pasos para instalar en Codex con pruebas |
| `CHANGELOG.md` | Historial de versiones |
| `opencode-kit.manifest.json` | Catálogo de componentes y perfiles |
| `package.json` | Scripts pnpm (validate, test, install, doctor, etc.) |

### Contratos portables

| Archivo | Define |
|---------|--------|
| `contracts/manager.md` | Manager como único orquestador, clasificación, delegación |
| `contracts/sdd-pipeline.md` | 8 fases SDD con reglas de cada una |
| `contracts/memory-governance.md` | Escritura, recuperación, F4C scoring, session close |
| `contracts/noise-gate.md` | Clasificación de interacciones, cuándo guardar/rechazar |
| `contracts/token-discipline.md` | Presupuesto, contexto fijo/dinámico, lazy-load |
| `contracts/context-pack-schema.md` | Formato de context packs con validación |
| `contracts/ponytail.md` | Anti-sobreingeniería con preguntas antes de implementar |

### OpenCode

| Archivo | Propósito |
|---------|-----------|
| `opencode/manager.template.md` | Manager de 15 secciones con SDD, gates, Engram, Ponytail |
| `opencode/scripts/install-overlay.mjs` | Instalador overlay con dry-run y backup |
| `opencode/scripts/doctor.mjs` | Valida instalación OpenCode |
| `opencode/gates/graphify-context.md` | Documentación del Graphify Context Gate |
| `opencode/gates/frontend-design.md` | Documentación del Frontend Design Gate |
| `opencode/gates/gpt55-review.md` | Documentación del GPT-5.5 Review Gate |
| `opencode/tests/doctor.test.mjs` | Test del doctor |
| `opencode/tests/install-overlay-dry-run.test.mjs` | Test del instalador dry-run |
| `opencode/tests/manager-template.test.mjs` | Test del template |

### Codex

| Archivo | Propósito |
|---------|-----------|
| `codex/manager.template.md` | Manager compacto con skills, memoria, context packs |
| `codex/scripts/install-overlay.mjs` | Instalador overlay para Codex |
| `codex/scripts/doctor.mjs` | Valida instalación Codex |
| `codex/scripts/rollback-overlay.mjs` | Restaura backup del overlay |
| `codex/scripts/memory-lint.mjs` | Valida archivos de memoria |
| `codex/scripts/context-pack-check.mjs` | Valida context packs |
| `codex/scripts/token-budget-report.mjs` | Reporte de tokens |
| `codex/scripts/skill-registry-generate.mjs` | Genera registro de skills |
| `codex/tests/*.test.mjs` | 34 tests unitarios e integración |

### Skills (18 portables)

| Ruta | Trigger |
|------|---------|
| `skills/manager-router/SKILL.md` | Clasificar, rutear solicitudes |
| `skills/memory-governance/SKILL.md` | Memoria, recordar, guardar |
| `skills/noise-gate/SKILL.md` | Ruido, clasificar, filtrar |
| `skills/context-pack-builder/SKILL.md` | Contexto mínimo, pack |
| `skills/token-budgeter/SKILL.md` | Tokens, presupuesto |
| `skills/work-unit-commits/SKILL.md` | Commits, implementación |
| `skills/chained-pr/SKILL.md` | PR grande, 400+ líneas |
| `skills/branch-pr/SKILL.md` | Pull request, PR |
| `skills/issue-creation/SKILL.md` | GitHub issue, bug report |
| `skills/judgment-day/SKILL.md` | Revisión, adversarial |
| `skills/deploy-security-gate/SKILL.md` | Predeploy, producción |
| `skills/cognitive-doc-design/SKILL.md` | Documentación, guías |
| `skills/flow-diagram/SKILL.md` | Diagrama de flujo |
| `skills/web-design-guidelines/SKILL.md` | UI audit, accesibilidad |
| `skills/skill-improver/SKILL.md` | Mejorar skills |
| `skills/bigquery-table-cleaning/SKILL.md` | BigQuery, limpiar |
| `skills/sandbox-data-loader/SKILL.md` | CSV, XLSX, subir datos |
| `skills/sql-learning/SKILL.md` | SQL, reglas de negocio |

### Documentación

| Archivo | Propósito |
|---------|-----------|
| `docs/getting-started.md` | Primeros pasos generales |
| `docs/installation-targets.md` | Destinos de instalación |
| `docs/safety-and-sanitization.md` | Reglas de seguridad |
| `docs/manager.md` | Responsabilidades del Manager |
| `docs/architecture.md` | Vista técnica resumida |
| `docs/decisions/0002-phase-documentation-standard.md` | ADR: estándar de documentación |
| `docs/codex/getting-started.md` | Guía detallada Codex |
| `docs/codex/overlay-install.md` | Instalación overlay Codex |
| `docs/codex/troubleshooting.md` | Troubleshooting Codex |
| `docs/plan-unificacion/PLAN.md` | Plan maestro de unificación |
| `docs/plan-unificacion/AVANCE-FASE-0.md` | Avance Fase 0 |
| `docs/archive/` | Documentos históricos archivados |

### Scripts

| Script | Propósito |
|--------|-----------|
| `scripts/validate.mjs` | Valida manifiesto, rutas, perfiles |
| `scripts/sanitize-check.mjs` | Verifica que no hay secretos en el kit |
| `scripts/docs-check.mjs` | Verifica documentación requerida |
| `scripts/doctor.mjs` | Diagnóstico del kit |
| `scripts/install.mjs` | Instalación base |
| `scripts/install-temp.mjs` | Instalación temporal para tests |
| `scripts/backup.mjs` | Backup de scripts |
| `scripts/rollback.mjs` | Rollback de scripts |
| `scripts/export-inventory.mjs` | Exporta inventario de componentes |
| `scripts/run-tests.mjs` | Runner cross-platform para tests |

---

*Este documento es el maestro de arquitectura del Runtime Kit. Para comenzar a usar el kit, seguí el [`QUICKSTART_OPENCODE.md`](QUICKSTART_OPENCODE.md) o [`QUICKSTART_CODEX.md`](QUICKSTART_CODEX.md) según tu runtime.*
