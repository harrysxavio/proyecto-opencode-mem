# Hoja de ruta

> OpenCode Kit evoluciona en 5 fases. Cada fase agrega capacidades sin romper
> lo anterior. Esta guía explica qué esperar de cada una.

---

## Estado actual

**Fase actual: Phase 1.1** — Documentation Accuracy & Beginner Clarity Fix.

---

## Fases

### Phase 0 — Bootstrap ✅ Completada

**Objetivo:** Crear la estructura base del kit con todos los componentes,
perfiles, scripts, y documentación inicial.

#### Qué se hizo

- Definición de 7 perfiles (minimal → full).
- Creación de 18 componentes en el manifest.
- 8 scripts de validación, doctor, sanitize, backup, rollback.
- 10 templates de agentes SDD.
- Template de Manager.
- Template de plugin Engram.
- Tests unitarios y de integración.
- CI básico con GitHub Actions.
- Templates de perfiles (env.example, opencode.example.jsonc, AGENTS.example.md).
- Directorio de ejemplos para cada perfil.
- Documentación inicial en inglés.

#### Artefactos

- `opencode-kit.manifest.json`
- `docs/install.md`
- `docs/decisions/0001-bootstrap-sanitized-runtime-kit.md`
- Todos los scripts en `scripts/`
- Todos los templates en `templates/` y `agents/`

---

### Phase 1 — Install UX & Documentation Foundation ✅ Completada

**Objetivo:** Convertir el bootstrap inicial en un kit comprensible, usable y
seguro tanto para usuarios técnicos como para principiantes.

#### Qué incluye

- **README completo en español** — con todas las secciones requeridas:
  arquitectura, Manager, SDD, Engram, Ponytail, gentle-ai, perfiles,
  instalación, seguridad, hoja de ruta, FAQ, glosario.
- **Audit de documentación** — `docs/PHASE-1-DOCUMENTATION-AUDIT.md` con
  clasificación de issues (CRITICAL, MAJOR, MINOR).
- **Guías dedicadas:**
  - `docs/getting-started.md` — tutorial paso a paso para principiantes.
  - `docs/profiles.md` — explicación detallada de cada perfil.
  - `docs/installation-targets.md` — VS Code, Cursor, CLI, proyectos locales.
  - `docs/safety-and-sanitization.md` — buenas prácticas de seguridad.
  - `docs/phase-roadmap.md` — esta misma hoja de ruta.
- **Nuevo ADR:** `docs/decisions/0002-phase-documentation-standard.md`.
- **Script de integridad:** `scripts/docs-check.mjs` + test unitario.
- **CI actualizado:** `docs:check` en GitHub Actions.

#### Criterios de éxito

- ✅ `pnpm validate` pasa.
- ✅ `pnpm sanitize:check` pasa sin criticals.
- ✅ `pnpm doctor` diagnostica correctamente.
- ✅ `pnpm docs:check` (nuevo) pasa.
- ✅ `pnpm test` pasa.
- ✅ `pnpm test:all` pasa.
- ✅ `pnpm install:dry-run --profile full` funciona.
- ✅ `pnpm install:temp` funciona.

---

### Phase 1.1 — Documentation Accuracy & Beginner Clarity Fix ✅ Completada

**Objetivo:** Corregir placeholders, inconsistencias y afirmaciones confusas
en la documentación de Phase 1 para que el repo sea preciso y seguro para
principiantes.

#### Qué se hizo

- **Audit de precisión** — `docs/PHASE-1.1-DOCUMENTATION-ACCURACY-AUDIT.md` con
  23 issues clasificados (18 must fix, 5 should fix).
- **README corregido:** URL real del repo, comandos correctos, Phase 1 marcada
  como completada, Ponytail como guidance-only, gentle-ai como alignment-only,
  compatibilidad como esperada/pendiente, cajas de "qué puedes / no puedes hacer".
- **Guias corregidas:** `getting-started.md`, `installation-targets.md`,
  `safety-and-sanitization.md` sin placeholders ni comandos inexistentes.
- **Script fortalecido:** `docs-check.mjs` ahora detecta placeholders de repo
  y claims incorrectos.
- **Tests actualizados:** `docs-check.test.mjs` cubre placeholders y claims.

#### Criterios de éxito

- ✅ README sin placeholders de repo.
- ✅ README usa URL real.
- ✅ README no menciona comandos inexistentes.
- ✅ README explica Ponytail como guidance-only.
- ✅ README explica gentle-ai como alignment-only.
- ✅ docs-check detecta placeholders en el futuro.
- ✅ test:all PASS.

---

### Phase 2 — Componentes portables 📅 Futura

**Objetivo:** Hacer que cada componente del kit sea independiente, portable,
y registrable en un catálogo distribuible.

#### Qué incluiría

- Cada componente con su propio `component.json` (metadatos, dependencias,
  versiones).
- Registro de componentes local y remoto.
- Comando `kit add <componente>` para agregar componentes individuales.
- Comando `kit search <término>` para buscar componentes.
- Validación de dependencias entre componentes.
- Tests de portabilidad (Windows, macOS, Linux).

#### Por qué es importante

Hoy los componentes están atados al manifest central. Phase 2 los libera para
que puedan compartirse, versionarse, y combinarse independientemente.

---

### Phase 3 — Agentes exportables 📅 Futura

**Objetivo:** Empaquetar los agentes SDD como skills instalables en cualquier
configuración de OpenCode.

#### Qué incluiría

- Cada agente SDD como un skill independiente con frontmatter (trigger,
  description, location).
- Comando `kit export agent <nombre>` para generar el skill.
- Registro de skills local.
- Compatibilidad con el skill-registry de OpenCode.
- Documentación de cómo crear skills propios basados en los templates.

#### Por qué es importante

Los templates de agentes están en `agents/` pero no son directamente instalables
como skills. Phase 3 los convierte en skills que cualquier usuario de OpenCode
puede agregar con un comando.

---

### Phase 4 — Ecosistema 📅 Futura

**Objetivo:** Crear un ecosistema alrededor del kit con comunidad,
contribuciones, y un marketplace básico de componentes.

#### Qué incluiría

- **Marketplace de componentes** — un registro público donde la comunidad
  pueda publicar componentes.
- **Sistema de versionado semántico** para componentes.
- **CI/CD para publicación automática.**
- **Templates de contribución** — guías, ejemplos, y herramientas para que
  cualquiera pueda crear y compartir componentes.
- **Galería de configuraciones** — ejemplos de setups reales de la comunidad.

#### Por qué es importante

El kit es tan útil como su comunidad. Phase 4 abre la puerta para que otras
personas contribuyan, compartan, y mejoren el ecosistema.

---

## Timeline estimado

| Fase | Inicio estimado | Duración estimada | Estado |
|---|---|---|---|
| Phase 0 | 2026-06 | 2 semanas | ✅ Completada |
| Phase 1 | 2026-06 | 1-2 semanas | ✅ Completada |
| Phase 1.1 | 2026-06 | 1 sesión | ✅ Completada |
| Phase 2 | 2026-07 | 3-4 semanas | 📅 Planeada |
| Phase 3 | 2026-08 | 2-3 semanas | 📅 Planeada |
| Phase 4 | 2026-09+ | 4-6 semanas | 📅 Futura |

> 💡 Las fechas son estimadas. Cada fase puede acortarse o extenderse según
> la complejidad descubierta durante la implementación.

---

## Principios de evolución

1. **Backward compatibility.** Cada fase es compatible con la anterior.
   No se rompen configuraciones existentes.
2. **Incremental.** Podés saltar de Phase 0 a Phase 2 si no necesitás la
   documentación de Phase 1. Cada fase es independiente.
3. **Validación continua.** Cada fase agrega sus propios tests y validaciones.
4. **Documentación primero.** Nunca se agrega una funcionalidad sin su
   documentación correspondiente.

---

## Cómo seguir el progreso

- **Issues de GitHub** — cada fase tiene un issue de seguimiento.
- **Milestones** — los PRs se agrupan por fase.
- **Documentación** — `docs/phase-roadmap.md` se actualiza con cada avance.

---

*¿Tenés sugerencias para fases futuras? Abrí un issue o un discussion en GitHub.*
