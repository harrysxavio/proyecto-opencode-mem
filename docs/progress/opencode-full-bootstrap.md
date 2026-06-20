# OpenCode full bootstrap progress

## Objetivo

Completar el bootstrap full de OpenCode con trazabilidad versionada de tareas, pruebas, revisiones y decisiones de seguridad.

## Branch y worktree

- Branch: `codex/opencode-full-bootstrap`
- Worktree: `.worktrees/codex-opencode-full-bootstrap`

## Leyenda

- `pending`: trabajo aún no iniciado.
- `in_progress`: trabajo en curso.
- `completed`: trabajo terminado y verificado.
- `blocked`: trabajo detenido por una dependencia o verificación pendiente.

## Tasks

| Task | Título | Status |
|---|---|---|
| Task 1 | [Establish the PowerShell test harness and lock contract](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-1-establish-the-powershell-test-harness-and-lock-contract) | `completed` |
| Task 2 | [Build the safe process runner and public command router](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-2-build-the-safe-process-runner-and-public-command-router) | `completed` |
| Task 3 | [Implement Windows preflight and confirmed prerequisite installation](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-3-implement-windows-preflight-and-confirmed-prerequisite-installation) | `completed` |
| Task 4 | [Add receipts, backups, checkpoints, resume and safe rollback](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-4-add-receipts-backups-checkpoints-resume-and-safe-rollback) | `completed` |
| Task 5 | [Compose OpenCode JSON/JSONC without overwriting user entries](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-5-compose-opencode-jsonjsonc-without-overwriting-user-entries) | `completed` |
| Task 6 | [Implement dependency execution and the verification registry](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-6-implement-dependency-execution-and-the-verification-registry) | `completed` |
| Task 7 | [Install the pinned OpenCode, Engram and Graphify core](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-7-install-the-pinned-opencode-engram-and-graphify-core) | `in_progress` |
| Task 8 | [Configure and probe credential-free MCP servers](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-8-configure-and-probe-credential-free-mcp-servers) | `pending` |
| Task 9 | [Install canonical Manager, ten SDD subagents, skills and audited plugins](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-9-install-canonical-manager-ten-sdd-subagents-skills-and-audited-plugins) | `pending` |
| Task 10 | [Add optional authenticated integrations and secure continuation](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-10-add-optional-authenticated-integrations-and-secure-continuation) | `pending` |
| Task 11 | [Implement doctor, status and project onboarding](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-11-implement-doctor-status-and-project-onboarding) | `pending` |
| Task 12 | [Add source, disposable-install and tamper test suites](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-12-add-source-disposable-install-and-tamper-test-suites) | `pending` |
| Task 13 | [Rewrite beginner-facing and architectural documentation](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-13-rewrite-beginner-facing-and-architectural-documentation) | `pending` |
| Task 14 | [Add Windows CI and release provenance](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-14-add-windows-ci-and-release-provenance) | `pending` |
| Task 15 | [Execute the clean Windows release gate and finalize documentation status](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-15-execute-the-clean-windows-release-gate-and-finalize-documentation-status) | `pending` |

## Estado actual

- Tarea activa: Task 7, remediación Spec (`in_progress`).
- Siguiente tarea: [Task 8 — Configure and probe credential-free MCP servers](../superpowers/plans/2026-06-18-opencode-full-bootstrap-implementation.md#task-8-configure-and-probe-credential-free-mcp-servers) (`pending`).

## Checkpoints

### 2026-06-18 — Task 1

- Preparación del worktree: commit `8533b43` en `master`.
- Baseline sanitizer: commit `1e66dc7`, aprobado con `103/103`.
- Task 1: commits `60ccabf`, `0f496cd`, `f1ce1735`, `e4c1018e`.
- Resultado final de Task 1:
  - Pester: `28/28`.
  - `pnpm test:powershell`: `28/28`.
  - `pnpm test:all`: `103/103`.
  - Spec: `APPROVED`.
  - Quality: `APPROVED`.

### 2026-06-18 — Task 2

- Status: `completed`.
- Commits: `1a2c5d6`, `a771a49`, `359dc90`, `be6fbbe`, `797fe7c`.
- Tests:
  - TDD focalizado: `12/12`.
  - `pnpm test:powershell`: `40/40`.
  - `pnpm test:all`: `109/109`.
- Reviews:
  - Self-review: `APPROVED`.
  - Spec: `APPROVED`.
  - Quality: `APPROVED`.

### 2026-06-18 — Task 3

- Status: `completed`.
- Commits: inicio `a8d5e9b`; implementación `40cd384`; quality fixes `3fde3c3`, `c36f5a3`; checkpoint `4d9c8a8`.
- Tests:
  - TDD RED focalizado: `2/13` passed, `11/13` failed por funcionalidad aún ausente.
  - TDD GREEN focalizado: `14/14`.
  - Quality fix RED focalizado: `11/16` passed, `5/16` failed por remediaciones aún ausentes.
  - Quality fix GREEN focalizado: `16/16`.
  - Prerelease RED focalizado: `16/17` passed, `1/17` failed por pérdida del sufijo semver.
  - Prerelease GREEN focalizado: `17/17`.
  - `pnpm test:powershell`: `57/57`.
  - `pnpm test:all`: `109/109`.
  - `pnpm docs:check`: `PASS`.
  - `git diff --check`: `PASS`.
- Reviews:
  - Self-review: `APPROVED`.
  - Spec: `CHANGES_REQUESTED`; remediación en curso para aprobación interactiva y post-verificación exacta.
  - Quality: `APPROVED`.

### 2026-06-18 — Task 4

- Status: `completed`.
- Commits: inicio `01f8acf`; implementación `49cb141`; remediaciones de seguridad/calidad `77bab38`, `1441d65`, `6c32ffc`; checkpoint final `c31ce43`.
- Tests:
  - TDD RED inicial: `0/12` passed; `12/12` fallaron por módulo y comando ausentes.
  - TDD RED forwarding: `8/9` passed; `1/9` falló por parámetros de rollback aún ausentes.
  - TDD RED checkpoint: `7/8` passed; `1/8` falló por API de checkpoint aún ausente.
  - TDD GREEN focalizado: `17/17`.
  - Spec remediation RED: `13/15` passed; `2/15` fallaron al reproducir creación vía junction y solapamiento destructivo source/target.
  - Spec remediation GREEN: `15/15`.
  - Callback isolation RED: `6/7` passed; el callback mutó el target después de validar.
  - Callback isolation GREEN: `7/7` con plan ejecutable de tuplas inmutables y DTOs de salida nuevos.
  - Quality remediation RED: `9/13` passed; fallaron IDs ambiguos, colisiones file/directory y staging ausente.
  - Quality remediation GREEN: `13/13` con publicación exclusiva y verificada.
  - `pnpm test:powershell`: `78/78`.
  - `pnpm test:all`: `109/109`.
  - `pnpm docs:check`: `PASS`.
  - `git diff --check`: `PASS`.
- Reviews:
  - Self-review: `APPROVED`.
  - Spec: `PENDING RE-REVIEW` tras remediar prevalidación de `BackupRoot`, conflictos globales y mutación del plan desde `ConfirmationReader`.
  - Quality: `APPROVED`.

### 2026-06-18 — Task 5

- Status: `completed`.
- Commits: inicio `e29b5ca`; implementación `24d4ab0`; remediación Spec `8193dc7`; hardening Quality `2caa3b9`; regresión absent-root `4266584`; CAS final `00cd76a`; verificación handle post-open `ed803ba`.
- Tests:
  - TDD RED inicial: `0/13` passed; `13/13` fallaron por módulo y funciones ausentes.
  - TDD GREEN base: `13/13`.
  - Quality RED backup: `15/16` passed; faltaba inyección de fallo de backup.
  - Quality RED semántica/forma: `15/17` passed; fallaron equivalencia numérica y tipos raíz inválidos.
  - Quality RED claves no string: `16/17` passed.
  - TDD GREEN focalizado final: `17/17`.
  - Spec remediation RED: `15/20` passed; fallaron validación recursiva de arrays y atomicidad del receipt.
  - Spec remediation GREEN: `20/20` con receipt validado/clonado y arrays validados recursivamente.
  - Quality hardening RED: `18/24` passed; fallaron fidelidad numérica, comparación sin overflow, case sensitivity y seams TOCTOU.
  - Quality hardening GREEN: `24/24` con tokens numéricos raw, canonicalización BigInteger, diccionarios ordinales y locks/revalidación fail-closed.
  - Spec absent-root RED: `24/25` passed; un receipt inválido creaba el root antes de fallar.
  - Spec absent-root GREEN: `25/25` con validación pura previa y lock del ancestro existente más cercano.
  - Quality final RED: `25/29` passed; faltaban prevalidación BackupId, creación segmentada y CAS/restore post-replace.
  - Quality final GREEN: `29/29` con handles por segmento y publicación CAS que preserva al último escritor.
  - Quality P1 RED: `29/30` passed; faltaba verificar reparse/FileId desde el handle abierto tras el precheck.
  - Quality P1 GREEN: `30/30` con atributos y FileId validados mediante `GetFileInformationByHandle`.
  - `pnpm test:powershell`: `108/108`.
  - `pnpm test:all`: `109/109`.
  - `pnpm docs:check`: `PASS`.
  - `git diff --check`: `PASS`.
- Reviews:
  - Self-review: `APPROVED`.
  - Spec: `APPROVED`.
  - Quality: `APPROVED`.

### 2026-06-19 — Task 6

- Status: `completed`.
- Commits: inicio `4b11ac3`; implementación `0c6e838`; remediación Quality inicio `8b84390`; hardening `c5b83ae`; checkpoint `ba916e3`.
- Tests:
  - TDD RED inicial: `0/19` passed; `19/19` fallaron por módulos y APIs aún ausentes.
  - GREEN parcial: `18/19` passed; una aserción Pester enumeraba el array de argumentos.
  - TDD focalizado final: `23/23`.
  - Quality RED: fallaron el seam `Registry`, los cuatro checkpoints no transaccionales y la mutación del descriptor canónico; RED adicional de cierre capturado: `21/22`.
  - Quality GREEN focalizado: `33/33`.
  - `pnpm test:powershell`: `141/141`.
  - `pnpm test:all`: `109/109`.
  - `pnpm docs:check`: `PASS`.
  - `git diff --check`: `PASS`.
- Reviews:
  - Self-review: `APPROVED`.
  - Spec: `APPROVED`.
  - Quality: `APPROVED`.

### 2026-06-19 — Task 7

- Status: `in_progress`; remediación de Spec implementada y pendiente de re-review independiente.
- Commits: inicio `7c096e2`; implementación `b7445b9`; inicio remediación `776a902`; remediación `284da8b`.
- Provenance Engram:
  - URL inmutable: `https://github.com/Gentleman-Programming/engram/releases/download/v1.16.3/engram_1.16.3_windows_amd64.zip`.
  - SHA256 oficial y verificado por descarga: `7e26447bf79040c79583f4cbd8acac4665e3c73ebc4eeb25d911763204dc0089`.
  - Estado: `project-pinned-verified-download`.
- Provenance Graphify: wheel PyPI `graphifyy-0.8.41-py3-none-any.whl`, SHA256 `ac2134b89a801e1a8bdf8f9b2bf2ac273c60e8cb8745f5818e6b22098002ebe3`.
- Tests:
  - TDD RED inicial: `0/9`; módulo, APIs y lock verificado ausentes.
  - TDD RED integración install: `9/10`; faltaba el contrato de core en `install.ps1`.
  - TDD RED reuse/mismatch: `9/11`; faltaba detección de herramientas compatibles.
  - TDD GREEN focalizado: `11/11`.
  - `pnpm test:powershell`: `153/153`.
  - `pnpm test:all`: `109/109`.
  - `pnpm docs:check`: `PASS`.
  - `git diff --check`: `PASS`.
  - Probe manual: Engram `1.16.3` persistió y encontró un canary con `ENGRAM_DATA_DIR` aislado; Graphify `0.8.41` creó `graph.json` y consultó `hello` desde el fixture.
- Reviews:
  - Self-review: `APPROVED`.
  - Spec: `CHANGES_REQUESTED`; se corrigieron los dos hallazgos y queda pendiente el re-review.
  - Quality: `PENDING`.

### 2026-06-20 — Task 7, remediación de Spec

- Se preservaron e inspeccionaron los cambios parciales del agente anterior antes de continuar.
- TDD RED focalizado: `11/14` passed; fallaron la señal `UPDATE_TO_PINNED`, el post-probe exacto y la actualización controlada de Engram.
- TDD GREEN focalizado: `15/15`.
- La aprobación interactiva válida y `-ConfirmInstall` ahora producen `InstallApproved = true` y ejecutan el plan core una sola vez; una cancelación ejecuta cero componentes core.
- Un componente existente con versión distinta se reinstala en el pin con `Action = UPDATE_TO_PINNED`; toda instalación/reinstalación se vuelve a probar y falla como `COMPONENT_VERSION_MISMATCH:<id>:expected:<v>:actual:<v>` si no quedó exacta.
- Engram verifica checksum y versión del candidato antes de publicarlo, reemplaza la versión distinta por el pin y vuelve a probar el ejecutable publicado.
- Un post-probe fallido deja el receipt en `PLANNED`: no escribe checkpoints `INSTALLED`, `CONFIGURED` ni `VERIFIED`.
- Gates:
  - `pnpm test:powershell`: `157/157`.
  - `pnpm test:all`: `109/109`.
  - `pnpm validate`: `PASS`.
  - `pnpm sanitize:check`: `PASS`.
  - `pnpm docs:check`: `PASS`.
  - `git diff --check`: `PASS`.
- Review: `PENDING RE-REVIEW`; no se inició Task 8.

### 2026-06-20 — Task 7, segunda remediación de Spec

- Status: `in_progress`; los dos hallazgos HIGH de resolución Windows fueron remediados y quedan pendientes de re-review.
- Commit de implementación: `3d88720`.
- TDD RED inicial: `15/18` passed; se reprodujeron selección accidental del shim `opencode.ps1`, uso del Graphify viejo que antecedía en `PATH` y falta del seam de resolución determinística en Verification.
- TDD RED adicional: `0/1`; el probe funcional `graphify.query` todavía usaba el nombre ambiguo de PATH. RED de ownership: `0/1`; el lock aún declaraba `command:graphify`.
- Diseño aplicado:
  - `Resolve-SafeWindowsCommand` solo acepta `.exe` o `.cmd`, prioriza `.exe` y luego `.cmd`, y nunca entrega `.ps1` a `ProcessRunner`.
  - OpenCode usa esa misma resolución antes y después de instalar y durante `opencode.version`.
  - Graphify obtiene el directorio user-owned oficial con `uv tool dir --bin` y usa el path absoluto `<uv-tool-bin>/graphify.exe` para detección, post-probe, `graphify.version` y `graphify.query`.
  - La ruta se deriva nuevamente en futuras sesiones; no se modifica PATH ni un directorio administrado por OpenCode. El lock declara `uv-tool-bin:graphify.exe` como target owned.
- Evidencia hermética: layout con `opencode.ps1` descubierto antes que `opencode.cmd`, y colisión PATH real con Graphify `0.8.39` antes que el bin uv-owned; el runtime efectivo y verificado quedó en `0.8.41`.
- TDD GREEN focalizado final: `21/21`.
- Gates:
  - `pnpm test:powershell`: `163/163`.
  - `pnpm test:all`: `109/109`.
  - `pnpm validate`: `PASS`.
  - `pnpm sanitize:check`: `PASS`.
  - `pnpm docs:check`: `PASS`.
  - `git diff --check`: `PASS`.
- Review: `PENDING RE-REVIEW`; no se inició Task 8.

### 2026-06-20 — Task 7, remediación de Quality

- Status: `in_progress`; los cuatro hallazgos de Quality fueron remediados y quedan pendientes de re-review.
- Commit de implementación: `5c59ff0`.
- TDD RED: `18/24` passed; los seis fallos reprodujeron Resume repitiendo las seis fases, receipts missing/corrupt no rechazados, fallback inseguro de comandos, ausencia de backup/restore Engram y escritura posible mediante junction.
- TDD GREEN focalizado: `25/25`.
- Engram transaccional:
  - usa `Backup-InstallPath` y `Save-InstallReceipt` antes de `Move`;
  - conserva el backup bajo el `KitRoot` user-owned y en el receipt canónico;
  - restaura el ejecutable previo o elimina el nuevo inmediatamente si el post-probe falla;
  - un receipt fallido permanece antes de `INSTALLED/VERIFIED` y conserva evidencia para rollback posterior.
- Ownership/TOCTOU:
  - combina `Assert-OwnedPath` con las primitivas de ConfigComposer para creación segmentada, handles de directorio, rechazo reparse y comparación de FileId;
  - revalida candidate, backup, receipt y target antes/después de publicar y nuevamente después del post-probe;
  - un junction en `KitRoot/bin` es rechazado y la prueba confirma cero escritura outside.
- Resume real:
  - `install.ps1 -Resume` carga y valida `state/install-receipt.json`, verifica `kitVersion` y lock digest, y falla con códigos estables para missing/corrupt/incompatible;
  - una segunda ejecución no repite ninguna de las seis fases de los tres componentes ya `VERIFIED`.
- Fail-closed: pnpm, OpenCode, uv y Graphify sin `.exe/.cmd` seguro producen `CORE_COMMAND_UNRESOLVED:<id>`; los shims `.ps1` nunca se invocan.
- Gates:
  - `pnpm test:powershell`: `170/170`.
  - `pnpm test:all`: `109/109`.
  - `pnpm validate`: `PASS`.
  - `pnpm sanitize:check`: `PASS`.
  - `pnpm docs:check`: `PASS`.
  - `git diff --check`: `PASS`.
- Review: `PENDING RE-REVIEW`; no se inició Task 8.

## Decisiones

- Engram `1.16.3` está habilitado mediante asset Windows amd64 versionado, checksum oficial y verificación local previa a publicación.
- `OPENCODE_KIT_ROOT` define la ownership del kit.
- No afirmar `100%` hasta completar un E2E limpio en Windows.

## Plantilla de checkpoint

### YYYY-MM-DD — Task N

- Status: `pending|in_progress|completed|blocked`.
- Commits: `SHA`.
- Tests: resultado y conteo.
- Reviews: resultado.
