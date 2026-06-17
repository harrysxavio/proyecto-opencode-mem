# 🧢 proyecto-opencode-mem

> **Estado:** 🟢 Pre-runtime — kit de componentes para armar tu configuración de OpenCode.
> **Versión:** 0.1.0 (Phase 1) — Documentación fundacional.
> **Phase 1:** ✅ Completada — Phase 1.1: ✅ Completada

[![Experimental](https://img.shields.io/badge/estado-experimental-yellow)](#)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](#)
[![Validate](https://github.com/harrysxavio/proyecto-opencode-mem/actions/workflows/validate.yml/badge.svg)](.#)

**proyecto-opencode-mem** (OpenCode Kit) es un conjunto portable de componentes, configuraciones, agentes SDD,
scripts de validación y documentación que te permite construir tu propio entorno OpenCode
— ya sea desde cero, migrando desde otra herramienta, o expandiendo uno existente.

No es un instalador automático. Es un **kit de construcción** pensado para que entiendas
cada pieza, elijas lo que necesitás, y armes tu setup con control total.

---

## Tabla de contenidos

- [¿Qué es OpenCode Kit?](#qué-es-opencode-kit)
- [Prerrequisitos](#prerrequisitos)
- [Arquitectura](#arquitectura)
- [Manager — El orquestador global](#manager--el-orquestador-global)
- [SDD — Structured Delta Development](#sdd--structured-delta-development)
- [Engram — Memoria persistente entre sesiones](#engram--memoria-persistente-entre-sesiones)
- [Ponytail Code Gate — Código mínimo, sin sobreingeniería](#ponytail-code-gate--código-mínimo-sin-sobreingeniería)
- [gentle-ai — Directivas de alineación](#gentle-ai--directivas-de-alineación)
- [Perfiles](#perfiles)
- [Guía rápida](#guía-rápida)
- [Destinos de instalación](#destinos-de-instalación)
- [Seguridad y sanitización](#seguridad-y-sanitización)
- [Hoja de ruta](#hoja-de-ruta)
- [FAQ](#faq)
- [Glosario](#glosario)
- [Variables de entorno](#variables-de-entorno)
- [Compatibilidad con OpenCode](#compatibilidad-con-opencode)
- [Desinstalación](#desinstalación)
- [Solución de problemas](#solución-de-problemas)
- [Comunidad y soporte](#comunidad-y-soporte)
- [Ejemplo guiado](#ejemplo-guiado)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

---

## ¿Qué es OpenCode Kit?

OpenCode Kit nace de una necesidad simple: **armar un entorno OpenCode no tendría por
qué ser complicado**, pero la documentación existente está dispersa y las configuraciones
suelen copiarse sin entenderlas.

Este kit te da:

- **Componentes modulares** — perfiles que van desde lo mínimo hasta una configuración
  completa con agentes SDD, memoria persistente, y gates de calidad.
- **Scripts de validación** — verificá que tu setup es seguro, portable, y consistente
  antes de usarlo.
- **Documentación clara** — cada decisión técnica tiene una explicación, cada archivo
  tiene un propósito documentado.
- **Templates listos** — ejemplos de configuración que podés adaptar sin empezar de cero.

> ⚠️ **Importante:** OpenCode Kit **no instala nada en tu sistema**. Te da los archivos
> y las instrucciones para que configures OpenCode vos mismo. No hay scripts que
> modifiquen tu PATH, ni instaladores que toquen archivos de sistema.

---

## Prerrequisitos

Antes de usar OpenCode Kit necesitás tener instalado:

| Herramienta | Versión mínima | Por qué |
|---|---|---|
| [Node.js](https://nodejs.org/) | 20.x | Los scripts de validación y utilidades usan Node.js. |
| [pnpm](https://pnpm.io/) | 9.x | Preferido para instalar dependencias del kit. |
| [Git](https://git-scm.com/) | 2.x | Para clonar el repositorio y versionar cambios. |
| [OpenCode](https://opencode.ai/) | 1.x (última estable) | El entorno que vas a configurar. |

> 💡 No tenés pnpm? Podés instalarlo con `corepack enable && corepack prepare pnpm@latest --activate`.

---

## Arquitectura

OpenCode Kit está diseñado como un conjunto de componentes independientes que se pueden
combinar según el perfil que elijas.

```
┌─────────────────────────────────────────────────┐
│                   OpenCode Kit                   │
├─────────────────────────────────────────────────┤
│  Manager (orquestador global)                    │
│  ├── SDD Pipeline (explore → apply → archive)    │
│  ├── Engram (memoria persistente)                │
│  ├── Ponytail Code Gate (calidad de código)      │
│  └── gentle-ai alignment (directivas de IA)      │
├─────────────────────────────────────────────────┤
│  Perfiles: minimal → agents → sdd → full         │
├─────────────────────────────────────────────────┤
│  Scripts: validate, doctor, sanitize, install     │
├─────────────────────────────────────────────────┤
│  Templates: opencode.jsonc, AGENTS.md, env        │
├─────────────────────────────────────────────────┤
│  Tests: unitarios + integración                   │
└─────────────────────────────────────────────────┘
```

### Flujo de trabajo típico

1. **Elegís tu perfil** — minimal si estás arrancando, full si querés todo.
2. **Copiás los templates** a tu carpeta de configuración de OpenCode.
3. **Ejecutás `pnpm validate`** para verificar que todo esté correcto.
4. **Ejecutás `pnpm doctor`** para diagnosticar el entorno.
5. **Arrancás OpenCode** y comenzás a trabajar.

---

## Manager — El orquestador global

El **Manager** es el cerebro de OpenCode Kit. Actúa como:

- **Product Manager** — toma requerimientos.
- **Solution Architect** — diseña la solución.
- **Technical Lead** — planifica la implementación.
- **QA Lead** — verifica calidad.
- **Release Manager** — decide cuándo algo está listo.

Manager **coordina, no hace todo él solo**. Delega fases a agentes especializados
(como los agentes SDD) pero retiene el control de la orquestación.

> 📘 El Manager sigue un protocolo estricto de 8 fases que va desde la toma de
> requerimientos hasta el archivado de cambios completados. Todo está documentado
> en `docs/` y en los templates de la carpeta `agents/manager/`.

### Reglas clave del Manager

1. **No salta a implementar** — primero entiende el problema, diseña, y obtiene aprobación.
2. **No delega orquestación** — los subagentes ejecutan, el Manager decide.
3. **No dice "está listo" sin verificar** — cada cambio pasa por review y tests.
4. **Usa memoria** — todo lo que aprende queda registrado en Engram.

---

## SDD — Structured Delta Development

**SDD** es la metodología que usa OpenCode Kit para hacer cambios de código de forma
estructurada y segura. Son 8 fases:

```
Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive
```

Cada fase tiene un propósito claro y produce un artefacto específico:

| Fase | Rol | Qué produce |
|---|---|---|
| **Explore** | Investigador | Análisis del código existente y áreas afectadas |
| **Propose** | Arquitecto | Propuesta de cambio estructurada |
| **Spec** | Analista | Especificaciones y criterios de aceptación |
| **Design** | Arquitecto técnico | Diseño técnico detallado |
| **Tasks** | Planificador | Lista de tareas de implementación |
| **Apply** | Implementador | Código modificado |
| **Verify** | QA | Resultados de verificación |
| **Archive** | Documentador | Artefactos actualizados y memoria guardada |

> 💡 Cada fase puede ejecutarla un agente especializado (como `@sdd-explore` o
> `@sdd-apply`) o el Manager si el agente no está disponible. La decisión la toma
> el Manager según la complejidad de la tarea.

---

## Engram — Memoria persistente entre sesiones

**Engram** es el sistema de memoria que permite que OpenCode recuerde decisiones,
bugs, configuraciones y descubrimientos de una sesión a la siguiente.

Sin Engram, cada sesión empieza en blanco. Con Engram, el asistente sabe:

- Qué decisiones de arquitectura se tomaron.
- Qué bugs se encontraron y cómo se resolvieron.
- Qué preferencias tiene el usuario.
- Qué patrones se establecieron.

> 📘 Engram no es un simple archivo de texto. Es un sistema con búsqueda por
> similitud, versión de observaciones, y detección de conflictos entre memorias.

### Cómo se usa

- **Guardar:** después de una decisión importante, bug fix, o descubrimiento, llamar
  a `mem_save` con el contenido estructurado.
- **Buscar:** al empezar una tarea, llamar a `mem_context` o `mem_search` para ver
  qué se hizo antes.
- **Cerrar sesión:** siempre llamar a `mem_session_summary` para que la próxima
  sesión sepa qué pasó.

El template de Manager en `agents/manager/manager.template.md` incluye el protocolo
completo de Engram.

---

## Ponytail Code Gate — Código mínimo, sin sobreingeniería

**Ponytail** es una guarda de calidad conceptual para reducir código innecesario.
En este repo, Ponytail está disponible como **guidance/template** para que el
Manager lo aplique en tareas de código. No es un plugin instalable ni un runtime
que se active solo.

Las preguntas que guían a Ponytail:

1. **¿Esto necesita existir?** — Tal vez se puede eliminar directamente.
2. **¿La stdlib lo hace?** — Preferí la biblioteca estándar.
3. **¿La plataforma lo hace nativamente?** — El runtime o el browser ya tienen esto.
4. **¿Una dependencia ya instalada lo hace?** — No agregues otra.
5. **¿Una línea alcanza?** — Si sí, escribí una línea.

> ⚠️ Ponytail **nunca simplifica** seguridad, validación, accesibilidad, manejo de
> errores críticos, o tests requeridos. Solo elimina sobreingeniería.

### Cómo se aplica

Ponytail **no se instala como plugin por defecto**. Su aplicación es conceptual:

- El Manager lo usa como guía durante tareas de código.
- Los templates SDD incluyen referencias a Ponytail como recordatorio.
- No hay enforcement runtime automático.
- No hay skills Ponytail precargados.
- No está activo en modo *ultra* por defecto.

Se aplica como criterio de diseño cuando la tarea involucra:

- Crear o modificar código
- Refactorizar
- Revisar un diff
- Agregar una nueva abstracción o dependencia

> 📘 Ponytail está documentado como protocolo en los templates del Manager y SDD.
> Es una guía de estilo, no un plugin que se active al instalar el kit.

---

## gentle-ai — Directivas de alineación

**gentle-ai** se trata como **alignment-only**: una referencia conceptual y
documental para evaluación, arquitectura y comportamiento esperado del asistente.
No es un runtime ni un plugin. No se instala como dependencia. No se incluye
en el perfil `full`. No se invoca automáticamente.

Lo que gentle-ai provee:

- **Directrices de persona** — describe cómo debería comportarse un asistente
  ideal (arquitecto senior, didáctico, directo).
- **Reglas de respuesta** — longitud mínima, una pregunta por vez, verificar
  antes de afirmar.
- **Protocolo de memoria** — referencia a Engram para persistencia.
- **Integración de skills** — referencia a carga contextual.

> 📘 gentle-ai es **alignment-only**: puede inspirar decisiones y patrones, pero
> no hay runtime que lo ejecute. Está documentado en `templates/AGENTS.example.md`
> como referencia, no como sistema activo.

---

## Perfiles

OpenCode Kit ofrece 7 perfiles que van desde lo mínimo hasta una configuración completa.

| Perfil | Componentes | Ideal para |
|---|---|---|
| **minimal** | Manager básico, Ponytail, sanitize | Quién arranca por primera vez |
| **agents** | minimal + 10 agentes SDD | Equipos que usan SDD |
| **sdd** | agents + SDD pipeline completo | Desarrollo estructurado |
| **memory-enabled** | sdd + Engram + memoria persistente | Sesiones largas y proyectos grandes |
| **ponytail-code-gate** | Ponytail avanzado + review automático | Equipos que priorizan código mínimo |
| **gentle-alignment** | gentle-ai alignment + directivas de IA | Quiere control sobre el comportamiento del asistente |
| **full** | Todo (no incluye gentle-ai runtime) | La configuración más completa |

> 📘 Cada perfil está explicado en detalle en [`docs/profiles.md`](docs/profiles.md).

### Cómo elegir un perfil

1. **Sos nuevo?** → Empezá con `minimal`. Son 3 archivos, nada más.
2. **Ya conocés OpenCode?** → `agents` te da los 10 agentes SDD.
3. **Trabajás en proyectos grandes?** → `memory-enabled` te da memoria persistente.
4. **Querés TODO?** → `full` incluye todos los componentes.

---

## Guía rápida

En 3 pasos tenés tu configuración lista:

```bash
# 1. Cloná el repositorio
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem

# 2. Instalá las dependencias
pnpm install

# 3. Validá que todo esté bien
pnpm validate
```

Después de eso:

```bash
# Verificá la salud del kit
pnpm doctor

# Revisá que no haya caminos absolutos ni secretos
pnpm sanitize:check

# Simulá una instalación dry-run con el perfil full
pnpm install:dry-run --profile full
```

> 💡 Los comandos `install:*` son dry-run y temp — no modifican tu sistema. Te
> muestran qué archivos se copiarían y dónde.

### ✅ Qué puedes hacer hoy

- Clonar el repositorio y explorar el código.
- Instalar dependencias (`pnpm install`).
- Validar la estructura del kit (`pnpm validate`).
- Diagnosticar tu entorno (`pnpm doctor`).
- Revisar que no haya secretos ni caminos absolutos (`pnpm sanitize:check`).
- Simular una instalación dry-run (`pnpm install:dry-run --profile full`).
- Probar una instalación temporal en `tests/tmp/` (`pnpm install:temp`).
- Leer los perfiles y elegir el que mejor se adapte a tu necesidad.
- Leer toda la documentación y entender cada componente.

### ❌ Qué todavía NO puedes hacer

- ~~Instalar automáticamente en tu OpenCode real~~ — el kit no tiene installer real.
- ~~Usar un installer real con backup/rollback ejecutable~~ — solo existen `backup:plan` y `rollback:plan`.
- ~~Copiar DB o memorias~~ — Engram es conceptual, no hay DB real.
- ~~Asumir soporte Codex actual~~ — Codex no es un destino soportado en Phase 1.
- ~~Asumir Ponytail plugin instalado~~ — Ponytail es guidance/template, no plugin.
- ~~Asumir gentle-ai runtime activo~~ — gentle-ai es alignment-only.
- ~~Usar un instalador que toque archivos fuera del repo~~ — no existe.

---

## Destinos de instalación

OpenCode Kit puede aplicarse a diferentes destinos de OpenCode. Cada destino tiene
su propia carpeta de configuración y forma de cargar los archivos.

| Destino | Carpeta de configuración | Cómo se carga |
|---|---|---|
| **OpenCode CLI** | `~/.config/opencode/` | Lee `opencode.json` y `AGENTS.md` automáticamente |
| **VS Code Extension** | `~/.config/opencode/` | Usa la misma carpeta que CLI |
| **Cursor** | `~/.cursor/` | Requiere adaptar la configuración |
| **Proyecto local** | `.opencode/` en el proyecto | Soporte para configuración por proyecto |
| **Direct agent** | Variable de entorno `OPENCODE_CONFIG_DIR` | Apuntá a la carpeta que quieras |

> 📘 Los detalles específicos de cada destino están en
> [`docs/installation-targets.md`](docs/installation-targets.md).

---

## Seguridad y sanitización

OpenCode Kit incluye varias capas de seguridad:

- **Sanitize check** (`pnpm sanitize:check`) — busca caminos absolutos, secretos,
  archivos `.env`, y tokens hardcodeados.
- **Validación** (`pnpm validate`) — verifica estructura de directorios, perfiles,
  y consistencia del manifest.
- **Doctor** (`pnpm doctor`) — diagnóstico del entorno Node.js, pnpm, y Git.
- **Dry-run** (`pnpm install:dry-run`) — muestra qué se copiaría sin tocar nada.
- **Rollback plan** (`pnpm rollback:plan`) — muestra qué se restauraría (plan-only,
  no ejecuta rollback real).
- **Backup plan** (`pnpm backup:plan`) — muestra qué se respaldaría (plan-only).

> 📘 La guía completa está en [`docs/safety-and-sanitization.md`](docs/safety-and-sanitization.md).

### Buenas prácticas

1. **Siempre ejecutá `pnpm sanitize:check` antes de copiar archivos.**
2. **Nunca commits `.env` ni secretos.**
3. **Usá `pnpm doctor` ante cualquier error inesperado.**
4. **Probá cambios con `install:dry-run` antes de la instalación real.**

---

## Hoja de ruta

OpenCode Kit evoluciona en 5 fases. Cada fase agrega capacidades sin romper lo
anterior.

| Fase | Estado | Qué agrega |
|---|---|---|---|
| **Phase 0** — Bootstrap | ✅ Completada | Estructura base, manifest, perfiles, scripts de validación |
| **Phase 1** — Install UX & Docs | ✅ Completada | README en español, guías, audit, documentación completa |
| **Phase 1.1** — Documentation Accuracy | ✅ Completada | Corrección de placeholders, claims, consistencia |
| **Phase 2** — Componentes portables | 📅 Futura | Componentes independientes, registro distribuido |
| **Phase 3** — Agentes exportables | 📅 Futura | Agentes pre-armados exportables como skills |
| **Phase 4** — Ecosistema | 📅 Futura | Marketplace de componentes, comunidad, CI/CD |

> 📘 El detalle de cada fase está en [`docs/phase-roadmap.md`](docs/phase-roadmap.md).

---

## FAQ

### ¿OpenCode Kit es un plugin de OpenCode?

No. Es un kit de construcción. Te da los archivos, configuraciones y documentación
para que armes tu setup de OpenCode. No se "instala" como plugin.

### ¿Necesito conocer OpenCode para usarlo?

No. La documentación está pensada para que alguien sin experiencia previa pueda
entender cada cosa.

### ¿Puedo usar solo una parte del kit?

Sí. Cada perfil es independiente. Podés empezar con `minimal` e ir agregando
componentes de a uno.

### ¿Esto modifica mi configuración actual de OpenCode?

No, a menos que específicamente copies los archivos a tu carpeta de configuración.
El kit trabaja en su propio directorio.

### ¿Cómo sé si mi configuración es segura?

Ejecutá `pnpm sanitize:check` — busca caminos absolutos, tokens, y secretos.

### ¿Puedo contribuir?

Sí. Todo el código es abierto. Mirá la sección [Contribuir](#contribuir) para
más detalles.

---

## Glosario

| Término | Significado |
|---|---|
| **SDD** | Structured Delta Development — metodología de 8 fases para cambios de código. |
| **Manager** | Agente orquestador que coordina todo el flujo de trabajo. |
| **Engram** | Sistema de memoria persistente entre sesiones de OpenCode. |
| **Ponytail** | Guarda de calidad que reduce código innecesario. |
| **gentle-ai** | Directivas de comportamiento para el asistente de IA. |
| **Perfil** | Combinación predefinida de componentes del kit. |
| **Manifest** | Archivo `opencode-kit.manifest.json` que describe todos los componentes. |
| **Sanitize** | Proceso que busca secretos, caminos absolutos, y tokens en los archivos. |
| **Dry-run** | Ejecución simulada que muestra qué pasaría sin hacer cambios reales. |
| **Template** | Archivo de ejemplo listo para adaptar (no para usar directamente). |

---

## Variables de entorno

| Variable | Propósito | Valor por defecto |
|---|---|---|
| `KIT_ROOT` | Ruta base del kit | Directorio del proyecto |
| `OPENCODE_CONFIG_DIR` | Carpeta de configuración de OpenCode | `~/.config/opencode/` |
| `OPENCODE_KIT_PROFILE` | Perfil activo | `minimal` |
| `NODE_ENV` | Entorno de Node.js | `development` |

> 💡 Las variables no son obligatorias. El kit funciona sin ninguna configurada.

---

## Compatibilidad con OpenCode

| Versión de OpenCode | Compatibilidad |
|---|---|---|
| 1.0.x | ✅ Esperada (validada por templates) |
| 1.1.x | ✅ Esperada (validada por templates) |
| 1.2.x | 🟡 Pendiente de prueba cross-machine |
| 2.x (futura) | ⚠️ No probada, pero los componentes son independientes y deberían funcionar. |

> 📘 El kit usa APIs estándar de OpenCode (configuración por archivos, AGENTS.md,
> skills, plugins). No depende de APIs internas o no documentadas.

---

## Desinstalación

Para "desinstalar" proyecto-opencode-mem:

1. **Si solo copiaste archivos:** borrá los archivos que copiaste de la carpeta de
   configuración de OpenCode.
2. **Si usaste `install:temp`:** borrá la carpeta temporal que se creó.
3. **El repositorio:** borralo con `rm -rf proyecto-opencode-mem` (o `Remove-Item` en Windows).

No hay scripts de desinstalación porque el kit nunca modifica archivos fuera de su
directorio sin que vos lo copies explícitamente.

---

## Solución de problemas

### `pnpm validate` da error de directorio faltante

Algún directorio de la estructura esperada no existe. Revisá que hayas clonado
completo el repositorio.

### `pnpm doctor` dice "Node.js not found"

Node.js no está instalado o no está en tu PATH. Instalalo desde [nodejs.org](https://nodejs.org/).

### `sanitize:check` encuentra caminos absolutos

Ejecutá el script de sanitización que reemplaza los caminos con placeholders:

```bash
pnpm sanitize:check
```

Si hay falsos positivos, agregá el patrón a las reglas de exclusión.

### No encuentro un archivo que la documentación menciona

Todos los archivos del kit están en sus directorios. Si falta alguno, ejecutá
`pnpm validate` que te dice exactamente qué falta.

---

## Comunidad y soporte

- **Issues y bugs:** [GitHub Issues](https://github.com/harrysxavio/proyecto-opencode-mem/issues) (o abrí uno si no existe)
- **Pull requests:** Bienvenidos — revisá la sección [Contribuir](#contribuir) antes.

> 💡 Este es un proyecto personal mantenido en tiempo libre. Los tiempos de
> respuesta pueden variar.

---

## Ejemplo guiado

Querés ver el kit en acción? Seguí estos pasos:

1. Cloná el repositorio.
2. Ejecutá `pnpm validate` — debería dar PASS.
3. Ejecutá `pnpm doctor` — debería diagnosticar tu entorno.
4. Ejecutá `pnpm install:dry-run --profile full` — vas a ver qué componentes se
   instalarían para el perfil completo.
5. Explorá [`docs/getting-started.md`](docs/getting-started.md) para una guía
   paso a paso para principiantes.

---

## Contribuir

Las contribuciones son bienvenidas. Algunas pautas:

1. **Abrí un issue primero** para discutir el cambio antes de mandar un PR.
2. **Seguí el flujo SDD** para cambios de código — el Manager lo orquesta.
3. **Incluí tests** cuando sea práctico.
4. **Usá commits convencionales** (feat:, fix:, docs:, chore:).
5. **No incluyas atribución de IA** (no "Co-Authored-By").

---

## Licencia

MIT. Hacé lo que quieras con esto. Si te sirve, genial. Si lo mejorás,
mandá un PR.
