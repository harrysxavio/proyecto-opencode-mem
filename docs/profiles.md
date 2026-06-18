# Perfiles de OpenCode Kit

> Cada perfil es una combinación predefinida de componentes. Elegí el que
> mejor se adapte a tu nivel de experiencia y necesidades.

---

## Cómo leer este documento

Cada perfil incluye:

- **Componentes** que lo forman.
- **Para quién** está pensado.
- **Qué archivos** agrega.
- **Cómo activarlo**.

Los perfiles son **acumulativos**: cada perfil más avanzado incluye todo lo
del anterior.

---

## Tabla comparativa

| Perfil | Componentes | Archivos | Conocimiento requerido |
|---|---|---|---|
| **minimal** | 3 componentes | ~5 archivos | Ninguno |
| **agents** | 13 componentes | ~15 archivos | Básico de OpenCode |
| **sdd** | 14 componentes | ~18 archivos | SDD básico |
| **memory-enabled** | 16 componentes | ~20 archivos | Familiaridad con OpenCode |
| **ponytail-code-gate** | 5 componentes | ~8 archivos | OpenCode intermedio |
| **gentle-alignment** | 5 componentes | ~8 archivos | IA/LLM básico |
| **full** | 22 componentes | ~30 archivos | Avanzado |
| **codex** | 4 componentes | ~6 archivos | Codex básico |
| **codex-full** | 7 componentes | ~20 archivos | Codex avanzado |

---

## minimal

> **El punto de partida.** Ideal para quien arranca de cero.

### Componentes

- **opencode-kit.manifest.json** — El catálogo de componentes y perfiles.
- **scripts/validate.mjs** — Validación de estructura.
- **scripts/sanitize-check.mjs** — Busca secretos y caminos absolutos.

### Archivos que agrega

```
docs/
├── install.md
├── decisions/
│   └── 0001-bootstrap-sanitized-runtime-kit.md
templates/
├── opencode.example.jsonc
├── AGENTS.example.md
├── env.example
scripts/
├── doctor.mjs
├── validate.mjs
├── sanitize-check.mjs
├── install.mjs
├── install-temp.mjs
├── backup.mjs
├── rollback.mjs
├── export-inventory.mjs
```

### Para quién

- Personas que usan OpenCode por primera vez.
- Quien quiere entender la estructura antes de agregar complejidad.
- Proyectos chicos que solo necesitan configuración básica.

### Cómo activarlo

```bash
pnpm install:dry-run --profile minimal
```

---

## agents

> **Para equipos que usan SDD.** Agrega los 10 agentes del pipeline.

### Componentes de minimal, más:

- **agents/manager/manager.template.md** — Template del orquestador global.
- **agents/sdd/sdd-init.template.md** — Inicialización SDD.
- **agents/sdd/sdd-explore.template.md** — Fase de exploración.
- **agents/sdd/sdd-propose.template.md** — Fase de propuesta.
- **agents/sdd/sdd-spec.template.md** — Fase de especificación.
- **agents/sdd/sdd-design.template.md** — Fase de diseño.
- **agents/sdd/sdd-tasks.template.md** — Fase de tareas.
- **agents/sdd/sdd-apply.template.md** — Fase de implementación.
- **agents/sdd/sdd-verify.template.md** — Fase de verificación.
- **agents/sdd/sdd-archive.template.md** — Fase de archivado.
- **agents/sdd/sdd-onboard.template.md** — Onboarding SDD.

### Para quién

- Equipos que quieren adoptar SDD como metodología.
- Desarrolladores que ya conocen OpenCode y quieren estructura.
- Proyectos medianos con múltiples cambios coordinados.

### Cómo activarlo

```bash
pnpm install:dry-run --profile agents
```

---

## sdd

> **Pipeline SDD completo.** Lo mismo que agents, más el pipeline orquestado.

### Componentes de agents, más:

- **plugins/engram.template.ts** — Plugin de memoria persistente.

### Diferencia con agents

`agents` te da los templates de agentes. `sdd` agrega el plugin de memoria
(Engram) que necesitan los agentes para funcionar correctamente.

### Para quién

- Quien ya usa agentes SDD y quiere el pipeline completo.
- Proyectos donde la trazabilidad de cambios es importante.

### Cómo activarlo

```bash
pnpm install:dry-run --profile sdd
```

---

## memory-enabled

> **Con memoria persistente.** Ideal para sesiones largas y proyectos grandes.

### Componentes de sdd, más:

- **scripts/export-inventory.mjs** — Inventario de componentes instalados.
- **scripts/backup.mjs** — Backup de configuración.

### Para quién

- Proyectos grandes con múltiples sesiones de trabajo.
- Equipos que necesitan continuidad entre sesiones.
- Quien quiere que OpenCode recuerde decisiones anteriores.

### Cómo activarlo

```bash
pnpm install:dry-run --profile memory-enabled
```

---

## ponytail-code-gate

> **Enfocado en código mínimo.** Para equipos que priorizan simplicidad.

### Componentes

- **scripts/validate.mjs** — Validación de estructura.
- **scripts/sanitize-check.mjs** — Sanitización.
- **scripts/doctor.mjs** — Diagnóstico del entorno.
- **Ponytail protocol** — Directivas de código mínimo (integradas en Manager).
- **templates/opencode.example.jsonc** — Configuración de ejemplo.

### Diferencias con otros perfiles

Este perfil NO incluye agentes SDD ni Engram. Está pensado para quien solo
quiere las guardas de calidad sin el pipeline completo.

### Para quién

- Equipos que priorizan código mantenible y minimalista.
- Proyectos donde la simplicidad es más importante que la estructura SDD.
- Quien quiere las reglas de Ponytail sin adoptar SDD.

### Cómo activarlo

```bash
pnpm install:dry-run --profile ponytail-code-gate
```

---

## gentle-alignment

> **Control de comportamiento del asistente.** Para quien quiere definir cómo
> se comporta la IA.

### Componentes

- **templates/AGENTS.example.md** — Directivas de personalidad y protocolo.
- **templates/opencode.example.jsonc** — Configuración con las directivas.
- **Ponytail protocol** — Guardas de calidad.
- **gentle-ai directives** — Reglas de alineación de IA.
- **scripts/validate.mjs** — Validación.

### Diferencias con otros perfiles

Este perfil se enfoca en el **comportamiento del asistente**, no en el pipeline
de desarrollo. Las directivas de gentle-ai definen cómo el asistente interactúa
con el usuario.

### Para quién

- Quien quiere control fino sobre el comportamiento de la IA.
- Equipos que quieren consistencia en las interacciones con el asistente.
- Usuarios avanzados que quieren personalizar la personalidad del asistente.

### Cómo activarlo

```bash
pnpm install:dry-run --profile gentle-alignment
```

---

## full

> **La configuración completa.** Todo lo que OpenCode Kit ofrece.

### Componentes

Todos los componentes de todos los perfiles anteriores:

- Manager + 10 agentes SDD
- Engram (memoria persistente)
- Ponytail Code Gate
- gentle-ai alignment
- Scripts de validación, doctor, sanitize, backup, rollback
- Templates de configuración
- Tests unitarios y de integración

### Para quién

- Usuarios avanzados que quieren aprovechar todo el kit.
- Proyectos grandes que necesitan el pipeline completo.
- Equipos que adoptan SDD + memoria + calidad como práctica estándar.

### Cómo activarlo

```bash
pnpm install:dry-run --profile full
```

---

## codex

> **Codex primero.** Perfil pensado para instalar la arquitectura del Manager
> como overlay de Codex, sin depender de OpenCode.

### Componentes

- **docs-core** — Documentación base del kit.
- **codex-manager-template** — Template compacto del Manager para Codex.
- **codex-skills** — Skills Codex-first para routing, memoria, contexto y tokens.
- **codex-memory-governance** — Guía de memoria segura para Codex.

### Para quién

- Usuarios que quieren mejorar primero Codex.
- Equipos que quieren un Manager liviano y lazy-loaded.
- Proyectos donde OpenCode vendrá después, no antes.

### Cómo activarlo

```bash
pnpm install:dry-run --profile codex
```

> Nota: el instalador Codex real se implementa en una fase posterior. Hoy este
> perfil ya define el contrato del manifest y permite validar componentes.

---

## codex-full

> **Codex con pipeline completo.** Agrega SDD y validación al perfil `codex`.

### Componentes de codex, más:

- **templates-core** — Templates portables base.
- **sdd-templates** — Subagentes SDD sanitizados.
- **memory-governance** — Política de memoria compartida.
- **validation-harness** — Scripts de validate, doctor y sanitize.

### Diferencia con full

`full` está orientado a OpenCode Kit completo. `codex-full` está orientado a
Codex-first y no incluye el template runtime de plugin Engram por defecto.

### Para quién

- Usuarios avanzados de Codex.
- Equipos que quieren SDD desde Codex.
- Proyectos que necesitan validar memoria, contexto y tokens antes de portar a
  OpenCode.

### Cómo activarlo

```bash
pnpm install:dry-run --profile codex-full
```

> Nota: igual que `codex`, este perfil define el contrato antes del instalador
> real. Eso evita prometer soporte runtime antes de tener doctor, backup y
> rollback listos.

---

## Compatibilidad entre perfiles

| Perfil A | Perfil B | Se pueden combinar? |
|---|---|---|
| minimal | agents | ❌ (agents ya incluye minimal) |
| agents | sdd | ❌ (sdd ya incluye agents) |
| ponytail-code-gate | gentle-alignment | ✅ (no compiten) |
| memory-enabled | sdd | ❌ (memory-enabled ya incluye sdd) |
| full | cualquier otro | ❌ (full ya lo incluye todo) |
| codex | codex-full | ❌ (codex-full ya incluye codex) |
| codex-full | full | ⚠️ (objetivos distintos: Codex-first vs OpenCode full) |

En la práctica, siempre elegí **un solo perfil**. Usá `full` si querés todo,
o `minimal` si estás arrancando.

---

## Resumen

```
minimal  →  agents  →  sdd  →  memory-enabled  →  full
                   ↘                        ↗
         ponytail-code-gate → gentle-alignment

codex → codex-full
```

La línea horizontal muestra la progresión acumulativa. La línea diagonal
muestra perfiles independientes que también están incluidos en `full`.

---

*¿No encontrás el perfil que necesitás? Abrí un issue o consultá la [FAQ](../README.md#faq).*
