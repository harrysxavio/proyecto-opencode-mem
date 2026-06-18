# Runtime Kit para OpenCode y Codex

Overlay portable de instrucciones y skills para que OpenCode y Codex trabajen con un Manager, memoria gobernada, contexto pequeño y flujos verificables.

> **Idea para principiantes:** este repositorio no reemplaza OpenCode ni Codex. Instala archivos de configuración dentro del directorio de usuario del runtime que ya tienes instalado.

## Inicio rápido

### Requisitos

- Git.
- Node.js 20 o superior.
- `pnpm` (puedes habilitarlo con `corepack enable`).
- OpenCode y/o Codex ya instalados y autenticados.

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
corepack enable
pnpm install
pnpm test:all
```

Después elige **un** runtime:

```bash
# Codex
pnpm codex:install:dry-run --target ~/.codex
pnpm codex:install --target ~/.codex
pnpm codex:doctor --target ~/.codex

# OpenCode
pnpm opencode:install:dry-run --target ~/.config/opencode
pnpm opencode:install --target ~/.config/opencode
pnpm opencode:doctor --target ~/.config/opencode
```

En Windows puedes reemplazar `~` por `$HOME` en PowerShell.

## 1. Para personas no técnicas

El kit agrega tres capas de comportamiento:

1. **Manager:** decide si una solicitud es pequeña, de código, documentación, seguridad o QA.
2. **Skills:** procedimientos Markdown que se cargan sólo cuando son útiles.
3. **Gobernanza:** reglas para memoria, seguridad, presupuesto de contexto, backup y rollback.

No instala un modelo de IA. Tampoco ejecuta un servidor propio. Copia archivos que los runtimes leen como instrucciones.

## 2. Qué instala exactamente

Ambos instaladores escriben únicamente dentro del `--target` explícito:

| Destino | Contenido |
|---|---|
| `AGENTS.md` | Overlay del Manager específico del runtime |
| `skills/opencode-runtime-kit/<skill>/SKILL.md` | 18 skills portables |
| `.atl/skill-registry.md` | Índice generado con rutas instaladas válidas |
| `.opencode-kit/last-install.json` | Recibo de instalación para doctor y rollback |
| `.opencode-kit-backups/<id>/` | Copia de cada destino que existía antes de sobrescribirlo |

El instalador no escribe en la carpeta donde está instalada la aplicación. Rechaza explícitamente una ruta administrada por el actualizador de OpenCode.

## Contratos portables

Los archivos de [`contracts/`](contracts/) definen reglas compartidas; [`ARCHITECTURE.md`](ARCHITECTURE.md) resume la arquitectura y enlaza a la fuente maestra. Un contrato describe comportamiento, no instala software.

## 3. Arquitectura para OpenCode

```text
solicitud
  -> OpenCode carga AGENTS.md
  -> Manager clasifica y elige la ruta mínima
  -> carga skills bajo demanda
  -> puede aplicar SDD/gates si la tarea y las herramientas disponibles lo permiten
  -> verifica y responde
```

OpenCode recibe el Manager detallado de `opencode/manager.template.md`. Éste describe clasificación, SDD y gates opcionales. Los contratos viven en `contracts/`; los procedimientos reutilizables, en `skills/`.

**Importante:** instalar instrucciones para Engram, Graphify, modelos de revisión o subagentes no instala esos proveedores. Si no están disponibles, el Manager debe degradar a ejecución inline o declarar la capacidad faltante.

## 4. Arquitectura para Codex

```text
solicitud
  -> Codex carga AGENTS.md
  -> Manager clasifica y crea un Context Pack pequeño cuando corresponde
  -> carga el SKILL.md pertinente
  -> usa memoria/herramientas sólo si el runtime las expone
  -> verifica y responde
```

Codex recibe el Manager compacto de `codex/manager.template.md`. El overlay añade procedimientos y reglas; no modifica el binario, el modelo, los permisos ni los conectores instalados.

## 5. Memoria

La arquitectura define **cómo decidir, guardar y recuperar memoria persistente**, pero el almacenamiento lo aporta el runtime o una integración externa:

- si existe Engram/MCP, el Manager puede usar `mem_context`, `mem_search` y `mem_save`;
- si Codex ofrece memoria persistente, el Manager sigue las mismas reglas;
- si no existe herramienta de memoria, el kit no inventa persistencia: trabaja con el contexto de la sesión y lo declara.

## Memoria entre sesiones

La memoria entre sesiones sólo existe cuando el runtime expone un backend persistente. El Manager recupera primero contexto reciente, busca lo mínimo necesario y evita guardar ruido o secretos.

Nunca se deben guardar secretos, dumps de prompts, logs completos ni afirmaciones sin verificar.

## 6. Noise Gate

El Noise Gate es una regla, no un daemon ni un plugin. Evita convertir saludos, confirmaciones y ruido en memoria permanente. Sólo conserva decisiones, correcciones, configuración y descubrimientos reutilizables.

## 7. Tokens y contexto

El Manager evita cargar todo el repositorio. Para trabajo amplio crea un Context Pack con clasificación, presupuesto, elementos incluidos y exclusiones justificadas. `token-budgeter` ayuda a mover detalle estable a docs o skills lazy-loaded.

## 8. Qué NO hace ni instala

- No instala OpenCode, Codex, Node.js, Git ni `pnpm`.
- No autentica cuentas ni configura API keys.
- No instala Engram, MCP servers, Graphify, Ponytail, modelos, plugins o subagentes.
- No crea una base de memoria por sí mismo.
- No modifica ejecutables ni directorios administrados por actualizadores.
- No garantiza que una integración externa esté disponible; `doctor` valida el overlay local, no servicios de terceros.
- No activa automáticamente un overlay ya abierto: reinicia el runtime después de instalar.
- No usa los perfiles del manifiesto para la instalación global. Los perfiles son paquetes/staging del repositorio; los comandos `codex:*` y `opencode:*` son los instaladores reales.

## 9. Estado actual

| Área | Estado verificable |
|---|---|
| Codex: install / doctor / rollback | Implementado y probado |
| OpenCode: install / doctor / rollback | Implementado y probado |
| Backup antes de sobrescribir | Implementado |
| Registro con 18 skills y rutas destino | Generado durante la instalación |
| Tests Node y CI | `pnpm test:all` |
| Integraciones externas | Opcionales; no instaladas por este kit |

## 10. Ponytail

Ponytail es una guía contra la sobreingeniería. El kit incluye el contrato y criterios, pero no instala un plugin Ponytail.

## 11. Cómo validar

```bash
pnpm doctor
pnpm test:all
pnpm codex:doctor --target ~/.codex
pnpm opencode:doctor --target ~/.config/opencode
```

`doctor` del repositorio valida prerrequisitos y estructura. Los doctors de runtime validan los archivos instalados y el recibo de instalación. Ninguno prueba autenticación o disponibilidad de servicios externos.

## 12. Rollback

```bash
pnpm codex:rollback:dry-run --target ~/.codex
pnpm codex:rollback --target ~/.codex
pnpm opencode:rollback:dry-run --target ~/.config/opencode
pnpm opencode:rollback --target ~/.config/opencode
```

Rollback restaura sólo los elementos respaldados y elimina sólo los que la última instalación creó. No toca otros archivos del usuario.

## 13. Documentación

- [Arquitectura maestra](arquitectura.md)
- [QuickStart Codex](QUICKSTART_CODEX.md)
- [QuickStart OpenCode](QUICKSTART_OPENCODE.md)
- [Destinos de instalación](docs/installation-targets.md)
- [Seguridad y sanitización](docs/safety-and-sanitization.md)

## Licencia

MIT. Consulta [LICENSE](LICENSE).
