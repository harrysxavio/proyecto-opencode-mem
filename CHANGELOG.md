# Changelog

## v0.2.0 (2026-06-18)

### Arquitectura unificada dual-runtime (OpenCode + Codex)

**Contratos portables** (`contracts/`):
- Manager, SDD Pipeline, Memory Governance, Noise Gate, Token Discipline, Context Pack Schema, Ponytail
- Runtime-agnostic, documentados en español e inglés

**Adaptador OpenCode** (`opencode/`):
- Manager template de 15 secciones con clasificación de solicitudes, SDD pipeline, gates (Graphify, Frontend, GPT-5.5), Engram memory, Ponytail, fast-track, completion contract
- Tests de instalación dry-run y doctor

**Adaptador Codex** (`codex/`):
- Manager template compacto con overlay de skills, memory-governance, context packs
- Scripts: install, doctor, rollback, memory-lint, context-pack-check, token-budget-report, skill-registry-generate
- Tests de cada script más integration test de overlay

**Skills portables** (18 skills compartidas):
- manager-router, memory-governance, noise-gate, context-pack-builder, token-budgeter, work-unit-commits, chained-pr, branch-pr, issue-creation, judgment-day, deploy-security-gate, cognitive-doc-design, flow-diagram, web-design-guidelines, skill-improver, bigquery-table-cleaning, sandbox-data-loader, sql-learning

**Documentación y onboarding**:
- README.md unificado como entry point
- QUICKSTART_OPENCODE.md y QUICKSTART_CODEX.md (5 pasos cada uno)
- ARCHITECTURE.md con vista completa
- docs/codex/ (getting-started, overlay-install, troubleshooting)
- docs/plan-unificacion/PLAN.md con diagnóstico, 7 fases, ADRs y cronograma

**Tests y validación**:
- 96 tests: unitarios, integración, contratos, skills, docs-check
- validate, sanitize-check, docs-check — todos PASS
- Runner cross-platform (run-tests.mjs) para Windows y Linux

**Limpieza**:
- Eliminados: agents/, plugins/, README_CODEX.md, 5 docs obsoletos
- Archivados a docs/archive/: bootstrap docs, phase-1, phase-2, proposals
- Manifest actualizado con nuevas IDs de componentes y perfiles

---

## v0.1.0 (2026-06-17)

### Lanzamiento inicial

- Estructura base con agents/, plugins/, docs/
- SDD templates para OpenCode
- Engram template plugin
- Documentación inicial en español
- Scripts de instalación y backup
- Perfiles minimal, agents, sdd, memory-enabled, full