# Contrato: Token Discipline

## Propósito

Mantener el contexto del agente dentro de un presupuesto de tokens sin sacrificar seguridad, calidad ni requerimientos del usuario.

## Principios

1. Las instrucciones estables deben ser cortas.
2. Los documentos largos deben cargarse bajo demanda (lazy-load).
3. Los skills deben cargarse por trigger, no en fixed context.
4. Las herramientas y superficies MCP deben activarse solo cuando se necesiten.
5. Los subagentes deben recibir context packs compactos.

## Reporte de presupuesto

Cuando se requiera, reportar:

- Candidatos a contexto fijo vs dinámico.
- Archivos o bloques de instrucciones más grandes.
- Movimientos seguros a lazy-load.
- Comandos de verificación.

## Advertencia

Nunca remover safety, seguridad, accesibilidad, tests o auditabilidad solo para ahorrar tokens.

## Runtime Adaptations

- **OpenCode**: usa Token Budgeter skill para estimar y reducir contexto. Lazy-load de skills por trigger en AGENTS.md.
- **Codex**: usa `token-budget-report.mjs` script para estimar archivos grandes y candidatos a lazy-load.
