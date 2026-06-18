# Contrato: Context Pack Schema

## Propósito

Estandarizar cómo se empaqueta contexto mínimo para delegar trabajo a subagentes, skills o fases SDD, evitando sobrecarga de información.

## Schema

```json
{
  "classification": "tiny|small|memory|docs|code|sdd|research|security|qa",
  "token_budget": 3000,
  "included": [],
  "excluded": []
}
```

## Regla de inclusión

Incluir solo items con una razón específica. Preferir referencias y resúmenes cortos sobre contenido completo.

## Budget defaults por clasificación

| Clasificación | Budget / Regla |
|---------------|----------------|
| `tiny` | Sin pack |
| `small` | Evidencia local solamente |
| `memory` | Máximo 3 memorias |
| `docs` | Máximo 3 secciones |
| `sdd` | Referencias de input de fase, no historia completa |
| `research` | Resúmenes de fuentes + links |
| `security` | Hallazgos + evidencia |
| `qa` | Diff + criterios de aceptación |

## Regla de exclusión

Excluir contexto duplicado, sensible, desactualizado o de baja relevancia.

## Validación

- El pack no debe exceder el token_budget.
- Cada item `included` debe tener `kind`, `ref` y `reason`.
- Items con sensibilidad alta deben ser excluidos.
- Máximo 8 items incluidos por defecto.

## Runtime Adaptations

- **OpenCode**: Context Pack Builder skill genera packs con validación. Usa `context-pack-check.mjs` para validar.
- **Codex**: usa `context-pack-check.mjs` script para validar packs manuales o generados.
