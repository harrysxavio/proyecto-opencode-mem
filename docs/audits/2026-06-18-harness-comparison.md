# Auditoría comparativa: Runtime Kit vs. `sergioahumada/harness`

**Fecha:** 2026-06-18

**Referencia auditada:** `sergioahumada/harness@a7dcea2cc40a595ae41196cedbab6c3aa6315f19` (`main`)

**Objetivo:** extraer patrones valiosos para el bootstrap de OpenCode sin reducir sus garantías de instalación, seguridad o verificación.

## 1. Conclusión ejecutiva

`harness` y este proyecto se parecen en el objetivo de entregar un proceso SDD portable, reanudable y compatible con varios agentes, pero no son instaladores equivalentes:

- `harness` instala archivos de proceso dentro de un repositorio existente;
- este proyecto debe instalar además el runtime OpenCode, prerrequisitos, MCP servers, Engram, Graphify, plugins, skills y subagentes en Windows.

La mejor contribución de `harness` no está en su mecanismo de instalación, sino en cinco ideas de producto:

1. una fuente canónica de roles y adaptadores delgados por runtime;
2. estado explícito y reanudable en archivos;
3. un único comando de verificación como prueba de que el entorno está listo;
4. separación entre proceso común y paquetes o sabores de capacidades;
5. documentación que empieza por “qué es”, muestra el layout y termina con el siguiente comando.

Estas ideas se incorporan al diseño ajustado. No se copiarán su instalación remota por tubería, sus escrituras sin backup ni su verificador parcialmente declarativo.

## 2. Comparación de alcance

| Dimensión | `harness` | Runtime Kit ajustado |
|---|---|---|
| Propósito | Convención SDD basada en archivos | Entorno OpenCode funcional más convención SDD |
| Plataforma del instalador | Bash | Windows PowerShell |
| Runtime OpenCode | No lo instala | Lo instala y verifica |
| MCP servers | No los instala | Engram, Context7, Playwright y opcionales |
| Memoria persistente | Selector `files`/`engram`; no instala Engram | Instala Engram, prueba persistencia y mantiene checkpoint de recuperación |
| Grafo de código | No incluye Graphify | Instala, construye y consulta una fixture |
| Plugins | No instala plugins de OpenCode | Instala adaptadores auditados y fijados |
| Agentes | Copia adaptadores de roles | Instala Manager y diez subagentes, y valida su descubrimiento |
| Seguridad de instalación | Copias directas y ejemplo `curl` remoto | lock, hashes, preview, backup, ownership y rollback |
| Verificación | `./init.sh` | `bootstrap.ps1 doctor` más pruebas funcionales |

## 3. Hallazgos valiosos que se adoptan

### A1. Fuente canónica y adaptadores delgados — adoptar

Los roles viven una sola vez en `core/roles/`; los archivos de `.opencode/agents/` y `.codex/agents/` sólo enlazan conceptualmente cada runtime con ese contrato. Esto evita que dos copias del mismo proceso evolucionen de forma distinta.

**Ajuste:** el catálogo bloqueado identificará para cada capacidad su fuente canónica y sus adaptadores generados. El doctor rechazará lógica de proceso duplicada o adaptadores que apunten a una fuente inexistente.

### A2. Estado explícito para reanudación — adaptar

`harness` separa `feature_list.json`, `progress/current.md`, historial y specs. El estado no depende únicamente del contexto de una conversación.

**Ajuste:** se formalizan dos planos distintos:

- estado de instalación: recibos y checkpoints sanitizados, fuera del repositorio del usuario;
- estado de trabajo: Engram como memoria semántica principal y un checkpoint mínimo basado en archivos para reanudar si el MCP no está disponible.

El checkpoint de archivos no duplica la base semántica ni almacena prompts, secretos o logs.

### A3. Un verificador como contrato — adoptar y fortalecer

La frase “verde es la única prueba” es clara para principiantes y evita confundir archivos copiados con funcionalidad real.

**Ajuste:** todos los caminos terminan en un único contrato: `bootstrap.ps1 doctor`. La salida incluye estado global, evidencia por componente, integraciones pendientes y el siguiente comando exacto. La documentación no puede declarar “listo” sin evidencia de ese doctor.

### A4. Proceso común y sabores — adaptar

`harness` separa el proceso agnóstico de los `stacks`. Es una extensión sencilla: agregar un directorio y metadata.

**Ajuste:** el lock tendrá paquetes de capacidades declarativos, no stacks de aplicación:

- `core`: todo lo obligatorio sin credenciales;
- `authenticated`: integraciones opcionales elegidas por el usuario;
- espacio versionado para futuros paquetes, sin modificar el motor del instalador.

La primera versión sigue instalando el núcleo completo solicitado; los paquetes no son una excusa para omitir componentes obligatorios.

### A5. Onboarding de repositorios existentes — adoptar

El rol `auditor` de `harness` construye un baseline una sola vez. Esto mejora el primer uso después de instalar.

**Ajuste:** el cierre exitoso ofrecerá `bootstrap.ps1 onboard -Project <ruta>`. El flujo usa Graphify y el agente `onboard` para producir un índice compacto del proyecto, sin modificar código y sin bloquear la instalación global.

### A6. Tabla de capacidades por runtime — adoptar

`harness` distingue capacidad completa, sin shell y sólo asesoría. Esa claridad es útil aunque sus datos concretos puedan cambiar.

**Ajuste:** README y doctor mostrarán por capacidad uno de estos estados verificables:

- `INSTALLED_VERIFIED`;
- `INSTALLED_DEGRADED`;
- `PENDING_AUTH`;
- `NOT_INSTALLED`;
- `UNSUPPORTED`.

No se inferirá soporte sólo porque exista un archivo adaptador.

## 4. Patrones que no se adoptan

### R1. Ejecución remota por tubería

El README propone ejecutar `install.sh` desde una URL mediante sustitución de proceso. Esto impide revisar y fijar fácilmente el contenido exacto que se ejecuta.

**Decisión:** sólo clon o release versionado, archivo local, SHA-256 y preview. Nunca `curl | iex` ni equivalentes.

### R2. Escritura sin ownership, backup ni rollback

`install.sh` copia `AGENTS.md`, adaptadores y reglas directamente al proyecto. No registra propiedad por clave, no crea backup integral y no ofrece rollback.

**Decisión:** conservar el composer estructural, detección de colisiones, recibos y rollback ownership-aware del diseño actual.

### R3. Manifestar reglas sin verificarlas

El verificador contiene TODO explícitos para reglas declaradas en `feature_list.json`, como aprobación previa y pruebas obligatorias. Una regla escrita pero no ejecutada puede producir una garantía falsa.

**Decisión:** cada garantía pública tendrá un `verificationId` en el lock y una prueba ejecutable. Lo no verificable se documentará como política, no como garantía técnica.

### R4. Comando dinámico con `eval`

El verificador ejecuta `verifyCommand` con `eval`. Es flexible, pero amplía innecesariamente la superficie de inyección.

**Decisión:** comandos como ejecutable más arreglo de argumentos; no se aceptan strings de shell arbitrarios en el lock.

### R5. Verificador que no pasa en el repositorio fuente

En el commit auditado, `node bin/check-harness.mjs` falla con 13 errores porque valida rutas de un proyecto ya instalado aunque se ejecuta desde el repositorio fuente. Además, no existe workflow de GitHub Actions en ese snapshot.

**Decisión:** separar y probar explícitamente `source doctor`, `installed doctor` y `clean-machine E2E`. Los tres son gates de release independientes.

### R6. Sobrescrituras y symlinks no portables a Windows

El instalador usa copias recursivas y un symlink de compatibilidad. En Windows esto puede requerir condiciones especiales y no satisface el alcance PowerShell-only acordado.

**Decisión:** archivos nativos, rutas Windows validadas y cero dependencia de WSL, Git Bash o Developer Mode.

## 5. Mejoras de presentación que se incorporan

La documentación final tendrá esta secuencia estable:

1. **Qué es** en una frase.
2. **Qué instala** y **qué no instala**.
3. **Un único camino recomendado** para un Windows limpio.
4. Comando de preview, confirmación e instalación.
5. Ejemplo real de salida final con estado y pendientes.
6. Mapa de archivos y ubicaciones instaladas.
7. Primer uso: abrir OpenCode, probar memoria, grafo y subagentes.
8. `doctor`, completar autenticación y rollback.
9. Matriz de capacidades y límites.
10. Sección avanzada de arquitectura.

El README no usará el atajo “no runtime to install”, porque este proyecto sí instala y gobierna dependencias reales.

## 6. Cambios requeridos en la especificación

1. Unificar la interfaz en `bootstrap.ps1 <install|doctor|configure|onboard|rollback|status>`.
2. Añadir fuente canónica y adaptadores delgados al modelo de componentes.
3. Separar formalmente estado de instalación y estado de trabajo.
4. Añadir paquetes declarativos `core` y `authenticated`.
5. Asociar cada garantía pública con una prueba mediante `verificationId`.
6. Incorporar estados de capacidad legibles y generados por doctor.
7. Añadir onboarding opcional posterior a la instalación.
8. Separar gates de source, instalación desechable y máquina limpia.
9. Añadir procedencia de release: versión del kit, commit, lock y hashes.
10. Reestructurar README y QuickStart alrededor del camino recomendado y salida observable.

## 7. Veredicto

La arquitectura propia sigue siendo más adecuada para el objetivo “instalar todo en otro Windows”. `harness` aporta una presentación de proceso más compacta y buenos patrones de fuente canónica, reanudación y verificación, pero su instalador no debe usarse como base técnica para el bootstrap completo.

El diseño ajustado toma sus fortalezas sin rebajar las garantías ya aprobadas de versiones fijadas, instalación interactiva, credenciales opcionales, doctor funcional, seguridad, idempotencia y rollback.
