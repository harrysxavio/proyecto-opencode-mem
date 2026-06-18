# OpenCode Full Bootstrap Design

**Date:** 2026-06-18

**Status:** Comparative revision pending approval

**Platform:** Windows with PowerShell
**Target runtime:** OpenCode

## 1. Goal

Provide a beginner-friendly interactive installer that turns a clean Windows computer into a verified OpenCode environment with persistent memory, code graph support, core MCP servers, required plugins, portable skills and the complete SDD subagent pipeline.

The installer must remain useful when optional credentials are omitted. In that case it guarantees the credential-free core and reports each authenticated integration as pending.

## 2. Success states

The installer exposes exactly three terminal states:

- `CORE_READY`: every mandatory component is installed, configured and verified.
- `READY_WITH_PENDING_AUTH`: the core is ready and at least one optional integration requires credentials.
- `FAILED`: at least one mandatory component could not be verified.

Missing optional credentials never produce `FAILED`. A mandatory plugin, skill, MCP server or subagent that cannot be discovered or exercised prevents a ready result.

## 3. Supported environment

The first release supports only Windows and PowerShell. It does not claim macOS or Linux support.

The bootstrap may install missing prerequisites through `winget` after showing the plan and receiving confirmation. It requests elevation only for the operation that requires it. Existing compatible installations are reused and never reinstalled solely to change their installation source.

## 4. Version policy

All tools and packages use versions pinned in `installer/components.lock.json`. Downloaded artifacts require an expected SHA-256 value when the upstream distribution provides stable release artifacts.

The installer never resolves `latest` during normal installation. Updating versions requires a reviewed repository change. A user-facing update command is explicitly outside this first implementation and will be designed later.

## 5. Architecture

```text
bootstrap.ps1
  -> preflight
  -> interactive plan
  -> backup
  -> component runner
  -> OpenCode config composer
  -> optional credential flows
  -> integral doctor
  -> installation receipt
```

The public interface is one beginner-facing command with explicit verbs:

```powershell
.\installer\bootstrap.ps1 install
.\installer\bootstrap.ps1 doctor
.\installer\bootstrap.ps1 status
.\installer\bootstrap.ps1 configure
.\installer\bootstrap.ps1 onboard -Project C:\path\to\project
.\installer\bootstrap.ps1 rollback
```

The specialized scripts remain internal module boundaries or compatibility shims. Documentation does not require a beginner to discover which script performs each lifecycle action.

The architecture has three planes:

1. **Canonical capability plane:** shared contracts, skills and role definitions exist once.
2. **Runtime adapter plane:** thin OpenCode bindings point to canonical capabilities and contain only runtime-specific metadata.
3. **State plane:** installation receipts are separate from project-work persistence.

Runtime adapters must not duplicate full role or skill procedures. The doctor validates every adapter target.

### 5.1 Proposed files

| File | Responsibility |
|---|---|
| `installer/components.lock.json` | Pinned component catalog, hashes, dependencies and verification commands |
| `installer/bootstrap.ps1` | Interactive entry point and phase orchestrator |
| `installer/configure-integrations.ps1` | Resume optional OAuth and API-key configuration |
| `installer/doctor.ps1` | Verify installed runtime behavior and produce readiness status |
| `installer/rollback.ps1` | Restore owned configuration and files from an installation receipt |
| `installer/modules/Preflight.psm1` | Platform, permissions, network, disk and prerequisite discovery |
| `installer/modules/ComponentRunner.psm1` | Idempotent component state machine |
| `installer/modules/ConfigComposer.psm1` | Structural, ownership-aware OpenCode configuration merge |
| `installer/modules/CredentialFlow.psm1` | OAuth and secure environment-variable setup |
| `installer/modules/Receipt.psm1` | Checkpoints, ownership metadata and rollback information |
| `installer/tests/` | Pester unit and integration tests |

Each module owns one concern and communicates through structured objects rather than parsing console output.

### 5.2 Component packs

`components.lock.json` groups components into declarative capability packs:

- `core`: every credential-free component required for readiness;
- `authenticated`: optional integrations selected during the interactive flow.

Each component declares its source, exact version, dependencies, owned targets and one or more `verificationId` values. A public guarantee without an executable `verificationId` is invalid and must be described as policy rather than verified behavior.

Future packs may be added without changing the component runner. The first release still installs the complete mandatory core; packs do not make required components optional.

Commands are stored as executable plus argument arrays. The lock never contains arbitrary shell command strings and the runner never uses `Invoke-Expression` or an equivalent `eval` mechanism.

## 6. Installation phases

1. Detect Windows, PowerShell and current configuration.
2. Resolve the locked component plan.
3. Display downloads, package installations, target paths and configuration changes.
4. Ask for confirmation.
5. Back up every destination that may change.
6. Install missing prerequisites.
7. Install and configure the mandatory core.
8. Offer optional authenticated integrations individually.
9. Run the integral doctor.
10. Write a receipt containing component states and owned paths.
11. Print the installed locations, readiness state, pending integrations and exact next command.

Every component follows:

```text
DETECTED -> PLANNED -> INSTALLED -> CONFIGURED -> VERIFIED
```

An interrupted run can continue with `bootstrap.ps1 -Resume`. The receipt records the last completed state for each component.

The receipt also records release provenance: kit version, source commit, lock digest and artifact hashes. This makes an installation reproducible and auditable after the repository evolves.

## 7. Mandatory core

| Component | Installed behavior | Verification evidence |
|---|---|---|
| Git | Source control prerequisite | Compatible version command succeeds |
| Node.js and pnpm | OpenCode and Node MCP prerequisite | Locked compatible versions execute |
| Python and uv | Graphify and Python MCP prerequisite | Locked compatible versions execute |
| OpenCode | Agent runtime | Starts and reads the managed configuration |
| Engram | Persistent semantic memory | Temporary data directory survives process restart and returns a saved canary |
| Engram MCP | Memory tool surface | MCP starts and exposes the required agent tools |
| Graphify | Code graph generation and queries | Builds and queries a disposable fixture graph |
| Context7 MCP | External library documentation | OpenCode reports the server connected |
| Playwright MCP | Browser automation surface | MCP starts and responds to a protocol probe |
| Manager | Single primary orchestrator | OpenCode discovers exactly one kit-managed primary Manager |
| SDD subagents | Eight core phases plus init and onboard | OpenCode lists all ten as hidden subagents |
| Skills | Portable and SDD procedures | Registry count, frontmatter and every destination path validate |
| Required plugins | Engram and Graphify runtime hooks | OpenCode loads them without plugin errors |

The doctor uses isolated fixtures and temporary Engram storage where possible. Verification must not pollute the user's real memory database or project graph.

## 8. Skills and subagents

The installed skill catalog contains:

- the 18 portable skills already maintained by the repository;
- ten SDD skills: init, explore, propose, spec, design, tasks, apply, verify, archive and onboard;
- the Graphify skill;
- shared Engram, persistence and SDD conventions.

The exact count is generated from the locked manifest rather than duplicated in documentation. The doctor fails when a mandatory registered skill is missing, malformed or points outside the managed target.

The Manager is the only primary agent. Every SDD worker is configured as `mode: subagent`, hidden from primary selection and unable to become an orchestrator.

Canonical procedures are stored once. OpenCode agent and skill adapters are thin bindings generated or validated from the locked catalog. An adapter that embeds a second divergent copy of a canonical procedure fails validation.

## 9. Plugins

The bootstrap does not copy private plugins from the development computer. It installs only small, audited, repository-owned adapters compatible with the pinned OpenCode and dependency versions.

Required adapters provide:

- Engram lifecycle and prompt/session integration;
- Graphify safety checks before graph operations;
- subagent status support only when its compatibility is proven by the locked test matrix.

The Engram MCP is the memory source of truth. The plugin enriches runtime integration but does not replace or fork the Engram database protocol. A plugin load error blocks `CORE_READY`.

## 10. Optional integrations

| Integration | Authentication flow | State when skipped |
|---|---|---|
| GitHub | OpenCode-supported OAuth or secure token environment variable | `PENDING_AUTH` |
| Supabase | OpenCode MCP OAuth | `PENDING_AUTH` |
| NotebookLM | OAuth flow launched by its pinned MCP CLI | `PENDING_AUTH` |
| Browserbase | Secure user environment variables | `PENDING_AUTH` |

`configure-integrations.ps1` allows the user to finish any skipped integration later and then reruns the relevant doctor checks.

Secrets are never written to Git, logs, backups, receipts or generated Markdown. Console output is redacted. OAuth credentials remain in the store managed by OpenCode or the provider. API keys are referenced by environment-variable name, not embedded in OpenCode JSON.

## 11. Configuration ownership

The composer detects active OpenCode JSON/JSONC configuration, creates an exact backup and previews a structural diff. It adds only kit-owned MCP, agent, plugin and instruction entries.

The receipt records each owned key and filesystem path. Existing user entries that do not belong to the kit are preserved. Name collisions are reported before writing and require an explicit resolution; they are never silently overwritten.

### 11.1 State ownership

Installation state and agent work state are distinct:

- sanitized receipts and checkpoints describe what the installer changed;
- Engram is the semantic memory source of truth for agent work;
- a minimal repository-owned work checkpoint may record current phase, last completed task and next action so an interrupted session remains resumable during temporary MCP unavailability.

The file checkpoint never stores raw prompts, source code, secrets, full logs or a copy of the Engram database. After Engram recovers, memory retrieval remains governed by the canonical memory policy.

## 12. Security controls

- HTTPS-only downloads from locked sources.
- SHA-256 verification for downloadable artifacts.
- No `curl | iex`, remote script piping or dynamic `latest` resolution.
- Process invocation uses argument arrays instead of shell-built command strings.
- Confirmation before package installation, configuration writes and authentication.
- Least-duration elevation for the specific `winget` operation.
- Sensitive-value redaction in logs and exceptions.
- Target-path validation and path-traversal rejection.
- Backup before every managed write.
- Sanitized receipts containing no secret values.

## 13. Failure handling and rollback

A mandatory verification failure stops readiness, preserves the checkpoint and prints the failed component, evidence and repair command. `-Resume` continues from the first incomplete state.

The rollback command:

- restores backed-up configuration and files;
- removes files and config keys owned by the kit;
- leaves user-owned configuration untouched;
- does not remove or revoke credentials unless separately requested;
- keeps shared prerequisites such as Git, Node.js and Python by default.

Automatic uninstall of shared prerequisites is excluded because other applications may depend on them. A future explicitly destructive option may be designed separately.

## 14. Testing strategy

### 14.1 Automated tests

- Pester unit tests for manifests, version checks, state transitions, merging, redaction and path policy.
- Integration tests using disposable targets and fake component executables.
- Negative tests for bad checksums, malformed JSONC, collisions, missing tools, interrupted phases and tampered receipts.
- Existing Node test suite remains green.
- Contract tests prove that every documented guarantee maps to a valid `verificationId`.
- Adapter tests prove that every OpenCode binding resolves to one canonical capability.

### 14.2 Windows end-to-end matrix

- Clean clone in Windows Sandbox or a clean VM.
- Computer with no prerequisites.
- Computer with compatible prerequisites.
- Existing OpenCode configuration containing unrelated MCPs, agents and plugins.
- Installation without optional credentials.
- Installation with each supported credential flow.
- Second installation proving idempotency.
- Interrupted installation followed by `-Resume`.
- Full rollback proving exact restoration.
- OpenCode restart proving Engram persistence and component discovery.

### 14.3 Independent verification modes

- **Source doctor:** validates the cloned repository before installation.
- **Disposable installed doctor:** validates an isolated target produced by the installer.
- **Clean-machine E2E:** validates the complete journey on Windows Sandbox or a clean VM.

All three modes must be green. Source validation must not assume that target-only paths already exist, and installed validation must not silently fall back to source files.

## 15. Release gate

The project may describe the Windows bootstrap as fully functional only when a clean-machine run proves all of the following:

1. The bootstrap reaches `CORE_READY` without optional credentials.
2. OpenCode discovers the Manager, ten SDD subagents, all mandatory skills and required plugins.
3. Engram memory persists across a process restart.
4. Graphify builds and queries a fixture.
5. Context7 and Playwright MCPs respond.
6. Skipped authenticated integrations are reported as `PENDING_AUTH` and can be completed later.
7. A second run is idempotent.
8. Rollback restores the original configuration.
9. CI and the Windows end-to-end workflow pass from a clean clone.
10. Source doctor and disposable installed doctor pass independently.
11. Every advertised capability has an executable verification result.

Until that gate passes, documentation must use `experimental` or `release candidate`, not `100% functional`.

## 16. Capability reporting and onboarding

`bootstrap.ps1 status` and the final installation summary report each capability as exactly one of:

- `INSTALLED_VERIFIED`;
- `INSTALLED_DEGRADED`;
- `PENDING_AUTH`;
- `NOT_INSTALLED`;
- `UNSUPPORTED`.

The result is generated from doctor evidence, never inferred only from the presence of a file.

After a ready result, the installer offers but does not force:

```powershell
.\installer\bootstrap.ps1 onboard -Project C:\path\to\project
```

Onboarding uses Graphify plus the `onboard` subagent to build a compact project index and initial operating context. It does not edit application code, does not block global installation, and is safe to skip.

## 17. Documentation contract

README and QuickStart use this fixed beginner-first order:

1. what the kit is;
2. what it installs and does not install;
3. one recommended path for a clean Windows computer;
4. preview, confirmation and install;
5. example final result and pending-auth states;
6. map of installed files and user-owned locations;
7. first-use proof for memory, graph, skills and subagents;
8. doctor, configure, status and rollback;
9. capability matrix and limitations;
10. advanced architecture links.

The documentation explicitly distinguishes “file installed”, “process connected” and “behavior functionally verified”.

## 18. Explicit exclusions

- macOS and Linux support.
- Automatic future updates.
- Bundling credentials or private memory data.
- Installing every MCP or plugin in the OpenCode ecosystem.
- Copying private plugins from the current workstation.
- Automatically uninstalling shared prerequisites during rollback.

## 19. Comparative design basis

The comparative audit against `sergioahumada/harness` is recorded in `docs/audits/2026-06-18-harness-comparison.md`. The design adopts its canonical-role, resumable-state, single-verifier and flavor-extension concepts while rejecting remote script piping, unowned overwrites, shell `eval`, Windows-incompatible symlinks and guarantees that are declared but not enforced.
