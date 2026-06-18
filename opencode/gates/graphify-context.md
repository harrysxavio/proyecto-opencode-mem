# Graphify Context Gate — OpenCode

## Propósito

Usar Graphify como capa de contexto y descubrimiento arquitectónico antes de SDD Explore, para tareas que involucran múltiples archivos, módulos o relaciones.

## Activación

Aplicar cuando:
- Tarea Medium/Large con 4+ archivos potencialmente afectados.
- Estructura del proyecto desconocida.
- El usuario pregunta por arquitectura, dependencias o impacto.
- `graphify-out/graph.json` o `graphify-out/GRAPH_REPORT.md` existen.

NO aplicar cuando:
- Tarea Tiny/Small de 1-3 archivos.
- Lectura directa es más rápida y segura.
- No existe grafo y construirlo es más caro que inspeccionar.
- El proyecto contiene archivos sensibles no ignorados.

## Comandos recomendados

```
graphify query "<pregunta sobre relaciones>"
graphify path "<concepto origen>" "<concepto destino>"
graphify explain "<nodo o concepto>"
```

## Reglas

1. Preferir queries scoped de Graphify antes de leer archivos.
2. Usar Graphify para identificar archivos candidatos, módulos y riesgos.
3. **Verificar siempre** los hallazgos importantes leyendo los archivos directamente.
4. Graphify es contexto, NO fuente de verdad.

## Archivos sensibles

Antes de construir/actualizar grafo, verificar si existen:
- `.env`, credenciales, API keys, secretos
- Datos personales, documentos confidenciales
- Archivos financieros internos

Si existen, recomendar `.graphifyignore` o scope reducido.

## Staleness

Si el código cambió después del último grafo, recomendar `graphify . --update` (con aprobación).

## Post-implementación

Si la implementación cambió interfaces públicas, arquitectura o integraciones, recomendar actualizar el grafo.

## Output esperado

Pasar a SDD Explore con:
- Resumen arquitectónico
- Archivos candidatos
- Módulos relacionados
- Dependencias ocultas
- Áreas de riesgo
- Preguntas para inspección directa
