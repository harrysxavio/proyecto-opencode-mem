# Arquitectura maestra

Este documento es la fuente de verdad funcional del Runtime Kit. Describe qué pertenece al repositorio, qué se copia a cada runtime y dónde termina la responsabilidad del kit.

## 1. Problema que resuelve

OpenCode y Codex pueden recibir instrucciones extensas, herramientas y skills. Sin una capa de orquestación, cada conversación puede cargar demasiado contexto, olvidar decisiones o ejecutar procesos distintos. El kit normaliza ese comportamiento sin modificar los runtimes.

## 2. Capas

```text
Repositorio
├── contracts/      reglas portables: qué debe ocurrir
├── skills/         procedimientos lazy-loaded: cómo hacerlo
├── opencode/       adaptación e instalador OpenCode
├── codex/          adaptación e instalador Codex
├── scripts/        validación del repositorio y perfiles de staging
├── templates/      ejemplos; no configuración activa
└── tests/          pruebas compartidas

Destino del usuario
├── AGENTS.md
├── skills/opencode-runtime-kit/*/SKILL.md
├── .atl/skill-registry.md
├── .opencode-kit/last-install.json
└── .opencode-kit-backups/<id>/
```

### Contratos

`contracts/` define invariantes: Manager único, SDD, memoria, Noise Gate, disciplina de tokens, Context Pack y Ponytail. Un contrato no es código ejecutable ni instala una herramienta.

### Skills

Cada `SKILL.md` contiene nombre, trigger y procedimiento. El instalador copia 18 skills y genera el registro desde el frontmatter real. Las skills no permanecen todas en contexto; el Manager las carga cuando coinciden con la tarea.

### Adaptadores

- `opencode/manager.template.md`: orquestación detallada y gates opcionales.
- `codex/manager.template.md`: overlay compacto, Codex-first.
- Los scripts de cada adaptador implementan dry-run, instalación, doctor y rollback.

## 3. Flujo de instalación

1. El usuario instala dependencias del repositorio con `pnpm install`.
2. Ejecuta dry-run con un `--target` explícito.
3. El instalador resuelve y valida la ruta.
4. Crea un backup con timestamp de cada destino existente.
5. Copia el Manager y las 18 skills.
6. Genera el registro con rutas `skills/opencode-runtime-kit/...`.
7. Escribe el recibo `.opencode-kit/last-install.json`.
8. El doctor verifica Manager, skills esenciales, registro y recibo.
9. El usuario reinicia el runtime.

La instalación no es transaccional a nivel de filesystem: si el proceso se interrumpe, se conserva el backup y el doctor detecta faltantes. El usuario puede ejecutar rollback o reinstalar.

## 4. OpenCode

Destino recomendado: `~/.config/opencode`.

El Manager de OpenCode puede enrutar tareas grandes a SDD, revisión, gates o subagentes **sólo cuando esas capacidades existen en el runtime**. El overlay aporta las reglas y skills incluidas en este repositorio; no descarga plugins ni configura proveedores externos.

Componentes instalados:

- Manager OpenCode como `AGENTS.md`;
- 18 skills portables;
- registro, metadata y backup.

Componentes no instalados:

- ejecutable OpenCode;
- Engram u otro backend de memoria;
- servidores MCP;
- Graphify;
- modelos/proveedores de revisión;
- plugins y subagentes externos.

## 5. Codex

Destino recomendado: `~/.codex`.

El Manager de Codex prioriza clasificación, Context Packs, lazy-load y verificación. Usa tools, memoria o agentes únicamente si la versión/entorno de Codex los expone. La arquitectura no asume que esas capacidades estén presentes en todas las instalaciones.

Componentes instalados y no instalados son los mismos tipos que en OpenCode, cambiando el template del Manager y el destino.

## 6. Memoria y degradación segura

La gobernanza de memoria es portable; el almacenamiento no.

```text
¿Existe herramienta de memoria?
├── sí -> recuperar sólo contexto relevante, guardar sólo evidencia durable
└── no -> continuar con contexto de sesión y declarar que no hay persistencia
```

Nunca se debe afirmar que el overlay “creó memoria” sólo porque copió `memory-governance/SKILL.md`.

## 7. Manifiesto y perfiles

`opencode-kit.manifest.json` describe paquetes para inventario, dry-run genérico y staging temporal dentro de `tests/tmp`. No es el instalador global de OpenCode o Codex.

- `scripts/install.mjs`: plan-only.
- `scripts/install-temp.mjs`: copia un perfil dentro del repositorio para pruebas.
- `codex/scripts/install-overlay.mjs`: instalación real Codex.
- `opencode/scripts/install-overlay.mjs`: instalación real OpenCode.

Esta separación evita confundir “perfil del kit” con “overlay activo del runtime”.

## 8. Seguridad

- escritura limitada al target;
- target real obligatorio en CLI;
- rechazo de directorios administrados por la aplicación OpenCode;
- backup antes de sobrescribir;
- metadata exacta para rollback;
- sanitización de secretos y rutas privadas en CI;
- sin descarga ni ejecución de código externo durante la instalación.

Riesgo residual: el usuario elige el target. Debe revisar el dry-run y no apuntar a una carpeta ajena.

## 9. Operación y evidencia

```bash
pnpm test:all
pnpm codex:install:dry-run --target ~/.codex
pnpm codex:install --target ~/.codex
pnpm codex:doctor --target ~/.codex
pnpm opencode:install:dry-run --target ~/.config/opencode
pnpm opencode:install --target ~/.config/opencode
pnpm opencode:doctor --target ~/.config/opencode
```

Un doctor exitoso significa que el overlay local está completo. No demuestra que el runtime esté autenticado ni que una integración externa responda.

## 10. Criterios de mantenimiento

1. Toda promesa de documentación debe tener código o estar marcada como externa/opcional.
2. Toda escritura real debe tener dry-run, backup, doctor y rollback.
3. La lista de skills se genera desde archivos reales, no desde conteos escritos a mano.
4. Las rutas de registro deben ser rutas del destino, no del repositorio fuente.
5. `pnpm test:all` debe ejecutarse antes de publicar.