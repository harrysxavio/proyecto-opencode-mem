# QuickStart — OpenCode Runtime

5 pasos para tener el Runtime Kit funcionando en OpenCode. Al final, tu asistente tendrá un **Manager global** que orquesta cada solicitud con memoria entre sesiones, pipeline SDD y quality gates.

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
pnpm test:opencode
```

**Qué pasa**: `validate` verifica que el manifiesto esté íntegro, todas las rutas existan y los perfiles resuelvan correctamente. `test:opencode` ejecuta los tests del adaptador OpenCode.

**Si pasa**: Tu kit está sano. Todos los contratos existen, los perfiles son válidos, las rutas son correctas.

---

## 3. Elegir un perfil

El kit tiene perfiles que definen qué componentes se activan. Revisalos en `opencode-kit.manifest.json`:

| Perfil | Incluye | Para qué sirve |
|--------|---------|----------------|
| **agents** | Manager template OpenCode | Tener solo el Manager sin SDD ni memoria |
| **sdd** | Manager + pipeline SDD | Proyectos con cambios estructurados |
| **memory-enabled** | Manager + memoria + Noise Gate | Proyectos que necesitan memoria entre sesiones |
| **full** | Todo: Manager, SDD, memoria, gates, Codex, contratos | Proyectos complejos con ambos runtimes |

```bash
pnpm validate  # Confirma que los perfiles existen y resuelven
```

**Qué significa**: Elegir un perfil determina qué instrucciones recibe tu Manager. El perfil `full` es el más completo: incluye clasificación de solicitudes (Tiny/Small/Medium/Large), pipeline SDD de 8 fases, gates de calidad (Graphify, Frontend, GPT-5.5), memoria con Noise Gate, y Ponytail anti-sobreingeniería.

---

## 4. Instalar el overlay en OpenCode

Esto copia el template Manager a tu configuración de OpenCode:

```bash
# 1. Opcional: ver qué se va a copiar (no escribe nada)
pnpm opencode:install:dry-run --target ~/.config/opencode

# 2. Real: instalar el overlay
pnpm opencode:install --target ~/.config/opencode
```

> ⚠️ **Siempre hace backup** del AGENTS.md existente en `<target>/.opencode-kit-backups/` antes de escribir.

**Qué se instala**:

| Archivo destino | Qué hace |
|----------------|----------|
| `<target>/AGENTS.md` | **Manager global**: clasifica solicitudes, orquesta SDD, ejecuta quality gates, gestiona memoria |
| `<target>/skills/opencode-runtime-kit/` | **Skills portables**: manager-router, memory-governance, noise-gate, context-pack-builder, token-budgeter, judgment-day y más |
| `<target>/.atl/skill-registry.md` | **Registro de skills**: permite que OpenCode encuentre cada skill por trigger |

**Qué cambia en el comportamiento de OpenCode**:

| Antes | Después |
|-------|---------|
| Cada conversación empieza sin contexto de sesiones anteriores | El Manager busca memoria automáticamente al empezar |
| No hay clasificación de solicitudes | El Manager clasifica como Tiny/Small/Medium/Large y aplica el flujo correspondiente |
| No hay pipeline estructurado para cambios grandes | SDD pipeline de 8 fases con Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive |
| No hay quality gates | Code Review / Judgment Day + GPT-5.5 Review antes de completar |
| Todo el contexto se carga siempre | Skills lazy-loaded por trigger, contexto mínimo bajo demanda |

---

## 5. Validar la instalación

```bash
pnpm opencode:doctor --target ~/.config/opencode
```

**Qué verifica**: El doctor comprueba que:
- El AGENTS.md destino existe y tiene contenido válido
- Los skills portables están en su lugar
- El skill-registry.md existe y es válido

**Si pasa**: OpenCode ya está usando el Manager unificado. **Toda solicitud que hagas ahora pasa por el flujo del Manager.**

---

## Cómo probar que funciona

Después de instalar, abrí OpenCode y probá estos mensajes:

**Prueba 1** — Verificar que el Manager responde:
> "Hola, ¿qué tipo de solicitud es esto según tu clasificación?"

El Manager debería clasificarla como **Tiny** (respuesta directa, sin cambios de archivo).

**Prueba 2** — Verificar memoria entre sesiones:
> "Acordate de que estamos probando el Runtime Kit"

Luego cerrá la sesión, abrí una nueva y preguntá:
> "¿Qué estábamos probando?"

El Manager debería recordar la sesión anterior.

**Prueba 3** — Verificar el pipeline SDD:
> "Quiero agregar un comando nuevo al Makefile"

El Manager debería pedir diseño y aprobación antes de implementar (Medium).

**Prueba 4** — Verificar skills:
> "Necesito un diagrama de flujo para la autenticación"

El Manager debería cargar el skill `flow-diagram` y generar un diagrama ASCII.

---

## Rollback si algo sale mal

```bash
# Restaurar el AGENTS.md original desde el backup
pnpm opencode:rollback --target ~/.config/opencode
```

---

## Comandos útiles

```bash
pnpm opencode:install:dry-run    # Ver plan de instalación sin escribir
pnpm opencode:doctor             # Validar instalación actual
pnpm opencode:rollback           # Restaurar backup
pnpm test:all                    # Todos los tests del kit
```

---

**Ver también**: [`README.md`](README.md) — arquitectura completa explicada para principiantes.  
[`ARCHITECTURE.md`](ARCHITECTURE.md) — vista técnica de contratos y adaptadores.  
[`docs/codex/getting-started.md`](docs/codex/getting-started.md) — si también usás Codex.
