# Contrato: Ponytail Code Gate

## Propósito

Reducir código innecesario, evitar sobreingeniería y preferir capacidades existentes de stdlib, plataforma o runtime antes de agregar nuevas abstracciones o dependencias.

## Cuándo aplicar

Cuando la tarea involucra: crear, modificar, refactorizar código; revisar un diff; proponer una abstracción; agregar una dependencia; implementar SDD Apply; preparar un PR.

NO aplicar cuando es solo: documentación, memoria, discusión arquitectónica, planificación, contenido, explicación, búsqueda de archivos.

## Flujo de revisión

Para cada pieza de código, preguntar en orden:

1. ¿Esto necesita existir?
2. ¿Puede stdlib hacerlo?
3. ¿Puede la plataforma/browser/runtime hacerlo nativamente?
4. ¿Puede una dependencia ya instalada hacerlo?
5. ¿Una línea basta?
6. Solo entonces: implementar la versión más pequeña que funcione.

## Qué NUNCA simplificar

- Validación de boundaries de confianza.
- Controles de seguridad.
- Accesibilidad.
- Manejo crítico de errores.
- Prevención de pérdida de datos.
- Tests requeridos.
- Contratos públicos.
- Auditabilidad requerida por el proyecto.
- Requerimientos explícitos del usuario.

## Marcadores

Cuando un shortcut tiene un techo conocido, documentarlo con `ponytail:` comment y la ruta de mejora.

## Runtime Adaptations

- **OpenCode**: Ponytail se integra como Code Gate en SDD Tasks y SDD Apply. Incluye `ponytail-review` para auditoría post-implementación.
- **Codex**: se aplica como paso de revisión en SDD Tasks (campo `ponytail: check`). Sin agente de auditoría dedicado.
