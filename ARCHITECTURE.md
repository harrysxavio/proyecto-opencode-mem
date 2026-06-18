# Arquitectura del Proyecto

## Visión General

Este repositorio define una arquitectura de agente dual-runtime: **OpenCode** y **Codex** como runtimes destino, con contratos portables compartidos y adaptadores runtime-specific.

```
┌─────────────────────────────────────────────────────┐
│                   CONTRATOS (contracts/)              │
│  manager · sdd-pipeline · memory-governance          │
│  noise-gate · token-discipline · context-pack-schema │
│  ponytail                                             │
├─────────────────────────────────────────────────────┤
│           ADAPTADORES RUNTIME-SPECIFIC               │
│  ┌──────────────────┐   ┌──────────────────┐         │
│  │    OpenCode       │   │     Codex         │         │
│  │  opencode/        │   │  codex/           │         │
│  │  manager template │   │  manager template │         │
│  │  gates (Graphify, │   │  scripts (install │         │
│  │   Frontend, GPT)  │   │   doctor, memory) │         │
│  │  installer script │   │  tests            │         │
│  └──────────────────┘   └──────────────────┘         │
├─────────────────────────────────────────────────────┤
│                     SKILLS (skills/)                   │
│  Portables entre runtimes, cargados por trigger       │
├─────────────────────────────────────────────────────┤
│                     DOCS (docs/)                       │
│  Getting started, profiles, safety, roadmap, ADRs    │
└─────────────────────────────────────────────────────┘
```

## Contratos Portables

Cada contrato describe QUÉ hace un componente, no CÓMO se implementa en cada runtime.

| Contrato | Propósito |
|----------|-----------|
| [`contracts/manager.md`](contracts/manager.md) | Orquestación primaria del agente |
| [`contracts/sdd-pipeline.md`](contracts/sdd-pipeline.md) | Fases de Spec-Driven Development |
| [`contracts/memory-governance.md`](contracts/memory-governance.md) | Reglas de escritura/recuperación de memoria |
| [`contracts/noise-gate.md`](contracts/noise-gate.md) | Filtro de ruido antes de guardar memoria |
| [`contracts/token-discipline.md`](contracts/token-discipline.md) | Presupuesto de tokens y lazy-load |
| [`contracts/context-pack-schema.md`](contracts/context-pack-schema.md) | Empaquetado de contexto mínimo |
| [`contracts/ponytail.md`](contracts/ponytail.md) | Reducción de código y anti-sobreingeniería |

## Adaptadores Runtime

### OpenCode (`opencode/`)

Runtime primario con ecosistema completo de subagentes y gates:

- **Manager template**: orquestación detallada con gates Graphify, Frontend Design, GPT-5.5
- **Gates**: Graphify Context Gate, Frontend Design Gate, GPT-5.5 Review/Debug
- **Scripts**: instalador overlay con dry-run
- **Tests**: validación de template y scripts

### Codex (`codex/`)

Runtime secundario con scripts autónomos y memoria SQLite nativa:

- **Manager template**: orquestación compacta con lazy-load de skills
- **Scripts**: install-overlay, doctor, memory-lint, context-pack-check, token-budget-report, skill-registry-generate, rollback-overlay
- **Tests**: 34 tests unitarios e integración
- **Documentación**: `docs/codex-runtime.md`

## Skills Portables (`skills/`)

Skills que funcionan en ambos runtimes, cargadas por trigger en el AGENTS.md correspondiente:

- noise-gate, token-budgeter, context-pack-builder
- memory-governance, manager-router
- judgment-day, deploy-security-gate, web-design-guidelines
- cognitive-doc-design, flow-diagram, work-unit-commits
- branch-pr, chained-pr, issue-creation
- skill-improver, sandbox-data-loader, sql-learning
- bigquery-table-cleaning, canvas-design, hatch-pet
- frontend-design, design-md

## Perfiles (`opencode-kit.manifest.json`)

| Perfil | Componentes |
|--------|------------|
| `full` | Todo: Manager, SDD, skills, docs, Engram |
| `codex` | Overlay Codex: Manager compacto + scripts + skills |
| `codex-full` | Codex + SDD + validación |
| `gentle-alignment` | Solo documentación de alineación Gentle |

## Flujo de decisión

```
Request → Manager clasifica (Tiny/Small/Medium/Large)
  → [Medium+] Diseño y aprobación
  → [Large] Graphify Context Gate (OpenCode)
  → SDD Pipeline (Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive)
  → Code Review / Judgment Day
  → GPT-5.5 Review (OpenCode)
  → Memory Governance (session summary)
  → Respuesta al usuario
```

## Runtime Adaptations

Cada contrato en `contracts/` incluye una sección "Runtime Adaptations" que documenta las diferencias de implementación entre OpenCode y Codex. Esta sección es la fuente de verdad para entender qué cambia entre runtimes.
