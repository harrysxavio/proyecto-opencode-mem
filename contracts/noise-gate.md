# Contrato: Noise Gate

## Propósito

Filtrar ruido conversacional antes de guardar memoria, expandir contexto o registrar prompts. El objetivo no es recordar menos, sino recordar solo lo que ayudará a un agente futuro a tomar mejores decisiones.

## Clasificación de prompts

| Clase | Significado | Acción default |
|-------|-------------|----------------|
| `instruction` | El usuario pide trabajo, fija constraint, cambia scope | Guardar si tiene valor futuro |
| `question` | El usuario pide explicación, status, validación | No guardar |
| `confirmation` | "sí", "ok", "continúa", "no" | No guardar |
| `navigation` | "muestra", "abre", "lista", "inspecciona" | No guardar |
| `noise` | Chatter, texto duplicado, pegado accidental | No guardar |

## Cuándo guardar

Guardar solo si al menos UNA condición es cierta:

1. Se tomó una decisión durable.
2. Se corrigió un bug con causa raíz conocida.
3. Se estableció un workflow, convención o preferencia reusable.
4. Se verificó un descubrimiento no obvio del codebase.
5. Cambió configuración o entorno.
6. Se necesita session summary para handoff.

## Cuándo rechazar

- Solo repite el prompt actual.
- Es una confirmación simple.
- Es navegación temporal.
- Carece de evidencia.
- Puede contener secretos o datos privados.
- Duplica memoria existente sin nuevo valor.

## Formato de reporte

```
classification: instruction | question | confirmation | navigation | noise
should_save: yes | no
reason: una oración
```

## Runtime Adaptations

- **OpenCode**: el Noise Gate se aplica en hooks de captura de prompt cerca de `mem_save_prompt`.
- **Codex**: se aplica como paso explícito de governance en Manager, memoria y session-summary.
