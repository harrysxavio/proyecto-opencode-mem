# Contrato: SDD Pipeline (Spec-Driven Development)

## Propósito

Organizar cambios Medium/Large en fases secuenciales, cada una con entrada, proceso y salida definidos. Reduce riesgos, mejora trazabilidad y permite verificación por fase.

## Fases

| Fase | Qué produce | Verificación |
|------|-------------|-------------|
| **Explore** | Análisis del codebase, áreas afectadas, riesgos | Lectura de archivos, Graphify |
| **Propose** | Propuesta estructurada de cambio | Coherencia con diseño aprobado |
| **Spec** | Escenarios Given/When/Then, criterios de aceptación | Cada escenario es testeable |
| **Design** | Arquitectura, interfaces, flujo de datos | Consistencia con spec y proyecto |
| **Tasks** | Lista ordenada de tareas pequeñas verificables | Cada tarea tiene done-condition |
| **Apply** | Código implementado | Tests pasan, diff revisado |
| **Verify** | Validación contra spec y tasks | Commands ejecutados, resultados |
| **Archive** | Delta specs sincronizados, metadatos archivados | Engram actualizado |

## Reglas

- No saltar fases (excepto para cambios Tiny).
- Cada fase debe completarse antes de iniciar la siguiente.
- Si una fase revela un problema de diseño, volver a Design o Propose.
- Apply nunca expande scope sin aprobación.

## Contrato de subagentes

Cada template SDD retorna `SUBAGENT_RESULT` con: fase ejecutada, archivos leídos/escritos, decisiones tomadas, riesgos y next phase recomendada.

## Runtime Adaptations

- **OpenCode**: subagentes `@sdd-*` ejecutan cada fase con contexto propio. Usa Graphify en Explore.
- **Codex**: funciones locales ejecutan cada fase con context packs. Usa Token Budgeter para contexto eficiente.
