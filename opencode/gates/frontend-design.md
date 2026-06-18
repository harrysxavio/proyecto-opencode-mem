# Frontend Design Gate — OpenCode

## Propósito

Establecer dirección estética y sistema de diseño antes de SDD Explore, cuando la tarea involucra interfaz de usuario.

## Activación

Aplicar cuando la tarea:
- Crea o modifica UI, componentes, páginas, layouts.
- El proyecto no tiene DESIGN.md o el diseño actual es inconsistente.
- El usuario pide mejorar calidad visual.
- Es Medium/Large con componente frontend significativo.

## Flujo

```
Graphify Context Gate → FRONTEND DESIGN GATE → SDD Explore
```

### Paso 1: design-md

Cargar el skill `design-md`. Si el proyecto no tiene DESIGN.md, analizar el código existente y generar DESIGN.md con:
- Tokens de diseño (colores, tipografía, spacing)
- Patrones de componentes
- Arquitectura visual
- Estados de UI (loading, empty, error, success)

Si DESIGN.md ya existe, leerlo para contexto.

### Paso 2: frontend-design

Cargar el skill `frontend-design` para guiar exploración estética cuando la tarea requiere dirección visual.

### Paso 3: canvas-design (opcional)

Cargar `canvas-design` cuando el proyecto necesita identidad visual fuerte: branding, posters, mood boards.

### Paso 4: Pasar contexto a SDD Design

Incluir DESIGN.md + dirección estética acordada como input para SDD Design.

## Modificaciones al SDD Design

Cuando la tarea es frontend, SDD Design DEBE incluir:
- Análisis del DESIGN.md como fuente de verdad visual.
- Referencia a la dirección estética definida.
- Componentes existentes y su reutilización.
- Evaluación de si `frontend-specialist` debe ejecutar SDD Apply.

## Modificaciones al SDD Apply

Cuando la tarea es frontend:
- Delegar implementación a `frontend-specialist`.
- Debe respetar DESIGN.md y dirección estética.
- No desviarse sin justificación y aprobación.

## Post-implementación

Evaluar si surgieron patrones reusables. Si es así, considerar crear un skill nuevo con `skill-creator`.
