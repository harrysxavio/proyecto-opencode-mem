# QuickStart — Codex Runtime

5 pasos para tener el Runtime Kit funcionando en Codex. Al final, tu asistente tendrá un **Manager** que gestiona memoria persistente, skills portables y contexto eficiente entre sesiones.

---

## 1. Clonar e instalar

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
pnpm install
```

**Qué pasa**: Se descarga el kit completo con contratos, templates, skills, scripts y tests.

---

## 2. Validar el kit

```bash
pnpm validate
pnpm test:codex
```

**Qué pasa**: `validate` verifica que el manifiesto esté íntegro, todas las rutas existan y los perfiles resuelvan. `test:codex` ejecuta los tests del adaptador Codex (scripts de instalación, doctor, rollback, memory-lint, context-pack-check, token-budget-report y skill-registry).

**Si pasa**: Tu kit está sano. Todos los scripts de Codex funcionan correctamente.

---

## 3. Ver qué va a instalar (dry-run)

```bash
pnpm codex:install:dry-run --target ~/.codex
```

**Qué pasa**: El dry-run simula la instalación sin escribir nada. Muestra:
- Qué archivos se van a copiar
- Dónde se va a hacer backup
- Qué perfiles y skills se van a instalar

**Ejemplo de salida**:
```
DRY RUN Codex overlay plan
Target: ~/.codex
Backup dir: ~/.codex/.opencode-kit-backups/2026-06-18T120000Z
Would copy:
  codex/manager.template.md → AGENTS.md
  skills/manager-router/     → skills/opencode-runtime-kit/manager-router/
  skills/memory-governance/  → skills/opencode-runtime-kit/memory-governance/
  skills/noise-gate/         → skills/opencode-runtime-kit/noise-gate/
  ...
Would generate: skill-registry.md
```

Esto **no modifica nada**. Podés ejecutarlo cuantas veces quieras para inspeccionar el plan.

---

## 4. Instalar el overlay

```bash
pnpm codex:install --target ~/.codex
```

**Qué se instala**:

| Archivo destino | Qué hace |
|----------------|----------|
| `<target>/AGENTS.md` | **Manager overlay**: orquesta solicitudes, gestiona memoria, carga skills bajo demanda |
| `<target>/skills/opencode-runtime-kit/` | **18 skills portables**: manager-router, memory-governance, noise-gate, context-pack-builder, token-budgeter, judgment-day, flow-diagram, work-unit-commits, branch-pr, issue-creation, deploy-security-gate, cognitive-doc-design, web-design-guidelines, skill-improver, bigquery-table-cleaning, sandbox-data-loader, sql-learning, chained-pr |
| `<target>/skill-registry.md` | **Registro**: Codex encuentra cada skill por trigger |

**Qué cambia en el comportamiento de Codex**:

| Antes | Después |
|-------|---------|
| Sin memoria entre sesiones | El Manager busca memoria al empezar (`mem_context`, `mem_search`) |
| Sin skills especializados | 18 skills portables cargados por trigger (diagramas, PRs, debugging, diseño UI, etc.) |
| Sin control de tokens | Context packs mínimos + token budgeting |
| Sin Noise Gate | El Manager filtra qué merece guardarse en memoria |

> ⚠️ **Siempre hace backup** del AGENTS.md existente en `<target>/.opencode-kit-backups/`.

---

## 5. Validar la instalación

```bash
pnpm codex:doctor --target ~/.codex
```

**Qué verifica el doctor**:

- ✅ Que `<target>/AGENTS.md` existe y tiene contenido
- ✅ Que `<target>/skills/opencode-runtime-kit/` existe con skills
- ✅ Que `<target>/skill-registry.md` existe y tiene referencias válidas
- ✅ Que no hay archivos rotos o referencias a rutas absolutas

**Si pasa**: Codex ya está usando el Manager overlay. **Toda solicitud que hagas ahora pasa por el flujo del Manager.**

---

## Cómo probar que funciona

Después de instalar, abrí Codex y probá estos mensajes:

**Prueba 1** — Verificar que el Manager cargó:
> "Hola, ¿qué skills tenés disponibles?"

El Manager debería listar los skills instalados (manager-router, memory-governance, noise-gate, etc.).

**Prueba 2** — Verificar skills de diagramas:
> "Necesito un diagrama de flujo para el login con OAuth"

El Manager debería cargar el skill `flow-diagram` y generar un diagrama ASCII.

**Prueba 3** — Verificar memoria entre sesiones:
> "Acordate de que estamos probando el Runtime Kit en Codex"

Después cerrá la sesión, abrí una nueva y preguntá:
> "¿Qué contexto había de la sesión anterior?"

**Prueba 4** — Verificar context packs:
> "Hacé un análisis de tokens de mi sesión actual"

El Manager puede generar un reporte de presupuesto de tokens.

**Prueba 5** — Probar un flujo completo:
> "Creá una Pull Request para el cambio que hicimos en el archivo X"

El Manager debería cargar `branch-pr` y `work-unit-commits`, planificar commits, y preparar la PR.

---

## Rollback si algo sale mal

```bash
pnpm codex:rollback --target ~/.codex
```

Restaura el AGENTS.md y skills originales desde el backup automático.

---

## Comandos útiles

```bash
pnpm codex:install:dry-run          # Ver plan sin escribir
pnpm codex:install                  # Instalar overlay
pnpm codex:doctor                   # Validar instalación
pnpm codex:rollback                 # Restaurar backup
pnpm codex:memory:lint              # Validar archivos de memoria
pnpm codex:context:check            # Validar context packs
pnpm codex:tokens:report            # Reporte de tokens
pnpm codex:registry                 # Generar skill-registry
pnpm test:codex                     # Tests del adaptador Codex
```

---

**Ver también**: [`README.md`](README.md) — arquitectura completa explicada para principiantes.  
[`ARCHITECTURE.md`](ARCHITECTURE.md) — vista técnica de contratos y adaptadores.  
[`docs/codex/getting-started.md`](docs/codex/getting-started.md) — guía detallada de instalación.
