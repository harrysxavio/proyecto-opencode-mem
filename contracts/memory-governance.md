# Contrato: Memory Governance

## Propósito

Definir qué se guarda en memoria persistente, cómo se recupera y cómo se evita memoria ruidosa o sensible entre sesiones.

## Reglas de escritura

Guardar decisiones, bugs con causa raíz, descubrimientos no obvios, preferencias estables, cambios de configuración y resúmenes de sesión. No guardar prompts crudos, logs completos, secretos, código fuente ni conjeturas.

## Recuperación

1. Contexto reciente.
2. Búsqueda por palabras clave.
3. Observación completa sólo si es relevante.
4. Docs y ADRs versionados como autoridad del proyecto.

## Runtime Adaptations

- **OpenCode:** puede usar Engram/MCP si está instalado y configurado.
- **Codex:** puede usar el sistema de memoria que exponga el runtime.
- **Sin backend:** el Manager continúa con contexto de sesión y declara que no hay persistencia.

Este contrato y `memory-governance/SKILL.md` gobiernan una capacidad; no crean una base de datos ni instalan un proveedor.
