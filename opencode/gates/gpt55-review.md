# GPT-5.5 Review Gate — OpenCode

## Propósito

Gate de calidad final antes de declarar completion. Se ejecuta después de Code Review / Judgment Day y antes de la respuesta al usuario.

## Activación

Siempre en tareas Medium y Large. Opcional en Small con cambios críticos.

## Modos

### Modo 1: `@review-gpt55` (preferido)

Delegar a subagente con este prompt:

```
@review-gpt55 Revisa el diff final contra:
- Requerimiento confirmado
- Diseño aprobado
- Graphify context (si se usó)
- SDD proposal/spec/design/tasks
- Evidencia de verificación
- Maintainabilidad, seguridad, performance, edge cases, riesgo de regresión

No modifiques archivos. Retorna PASS, PASS WITH WARNINGS, o BLOCKED.
```

### Modo 2: Inline (fallback)

Si el subagente no está disponible, ejecutar la revisión manualmente con los mismos criterios.

## Criterios de bloqueo

BLOCKED si se encuentra:
- Bug crítico.
- Mismatch con requerimiento.
- Issue de seguridad.
- Riesgo de pérdida de datos.
- Test roto no explicado.
- Comportamiento riesgoso no verificado.
- Desviación mayor de scope.
- Suposición crítica no verificada de Graphify.

## Criterios de frontend (adicionales)

Cuando la tarea es frontend, incluir:
- Consistencia con DESIGN.md.
- Accesibilidad (contraste, labels, keyboard nav).
- Responsive (mobile/tablet/desktop).
- Estados de UI (loading, empty, error, success).
- Performance (re-renders, bundle, imágenes).

## Output

```text
estado: PASS | PASS_WITH_WARNINGS | BLOCKED
hallazgos:
- [hallazgo 1]
- [hallazgo 2]
recomendacion: [próximo paso]
```
