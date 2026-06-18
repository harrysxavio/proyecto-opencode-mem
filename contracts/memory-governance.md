# Contrato: Memory Governance

## Propósito

Gobernar qué se guarda en memoria persistente, cómo se recupera y cómo se mantiene la calidad de la información entre sesiones.

## Reglas de escritura

Guardar solo cuando:

1. Se tomó una decisión arquitectónica o de diseño.
2. Se corrigió un bug con causa raíz conocida.
3. Se descubrió algo no obvio sobre el codebase.
4. Se estableció una preferencia del usuario o convención reusable.
5. Se cambió configuración o entorno.
6. Se necesita un session summary para handoff.

NO guardar: prompts crudos, logs, secretos, código fuente, fallos transitorios, conjeturas.

## Reglas de recuperación

1. Intentar contexto de sesión reciente primero (rápido).
2. Si no se encuentra, búsqueda por keywords.
3. Observación completa solo si el resultado es relevante.
4. ADRs o docs versionados como autoridad final.

## F4C Selector

Al recuperar memorias, priorizar por: relevancia (0.5) + recencia (0.3) + tipo (0.2).
Tipos con prioridad: decision > constraint > architecture > bugfix > discovery > config > other.
Deducar memorias con mismo topic_key — mantener la de mayor score.

## Session Close

Antes de finalizar una sesión, guardar session summary con: Goal, Instructions, Discoveries, Accomplished, Next Steps, Relevant Files.

## Runtime Adaptations

- **OpenCode**: usa Engram MCP (`mem_save`, `mem_search`, `mem_context`, `mem_session_summary`) con auto-triggers.
- **Codex**: usa memorias SQLite nativas con Noise Gate como paso explícito antes de guardar.
