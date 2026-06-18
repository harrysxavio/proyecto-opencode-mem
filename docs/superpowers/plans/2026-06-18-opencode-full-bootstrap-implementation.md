# OpenCode Full Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a Windows/PowerShell installer that installs and functionally verifies OpenCode, its credential-free core, persistent Engram memory, Graphify, MCP servers, plugins, skills and ten SDD subagents, while preserving user configuration and clearly reporting optional authentication.

**Architecture:** A single `bootstrap.ps1` command dispatches lifecycle verbs into focused PowerShell modules. A locked manifest defines versions, dependencies, ownership and executable verification IDs; receipts and structural configuration merges provide resume and rollback. Verification is split into source, disposable-install and clean-machine gates, and user documentation is generated around observable doctor results rather than copied-file claims.

**Tech Stack:** PowerShell 7, Pester 5, JSON/JSONC, winget, Git, Node.js 22, pnpm 11, Python 3.13, uv, OpenCode, Engram, Graphify, MCP, GitHub Actions Windows runners.

---

## Delivery decomposition

The work is delivered in four independently testable milestones:

1. **Installer kernel:** lock schema, command router, preflight, receipts, composer and rollback.
2. **Credential-free core:** OpenCode, Engram, Graphify, MCPs, Manager, plugins, agents and skills.
3. **Optional integrations and onboarding:** secure authentication continuation, status and project onboarding.
4. **Documentation and release proof:** beginner path, architecture, CI and clean-machine evidence.

No milestone may weaken the existing Node overlay installer or Codex behavior. PowerShell tests are added beside, not in place of, `pnpm test:all`.

## Target file map

| Path | Responsibility |
|---|---|
| `installer/bootstrap.ps1` | Public lifecycle dispatcher: install, doctor, status, configure, onboard, rollback |
| `installer/components.lock.json` | Exact component versions, packs, dependencies, ownership and verification IDs |
| `installer/modules/LockManifest.psm1` | Parse and validate the lock without executing manifest strings |
| `installer/modules/Preflight.psm1` | Detect Windows, PowerShell, network, disk, winget and installed prerequisites |
| `installer/modules/ProcessRunner.psm1` | Invoke executables with argument arrays and redacted structured results |
| `installer/modules/Receipt.psm1` | Installation identity, checkpoints, provenance, backups and safe restore |
| `installer/modules/ConfigComposer.psm1` | JSON/JSONC structural merge with ownership and collision handling |
| `installer/modules/ComponentRunner.psm1` | Dependency ordering and component state transitions |
| `installer/modules/Verification.psm1` | Fixed registry mapping `verificationId` to executable probes |
| `installer/modules/CredentialFlow.psm1` | Optional OAuth/API-key continuation without secret persistence |
| `installer/modules/Onboarding.psm1` | Safe Graphify plus onboarding-agent flow for a selected project |
| `installer/assets/opencode/` | Canonical OpenCode Manager, agents, plugins and generated bindings |
| `installer/tests/unit/` | Pester tests for each module |
| `installer/tests/integration/` | Disposable fake-runtime installation tests |
| `installer/tests/e2e/` | Windows clean-machine and real-component probes |
| `.github/workflows/windows-bootstrap.yml` | Windows source and disposable-install CI gate |
| `docs/capability-matrix.md` | Machine-verifiable installed/degraded/pending/unsupported matrix |
| `docs/bootstrap-troubleshooting.md` | Repair and resume commands keyed by failure code |
| `README.md` | Beginner-first product and installation entry point |
| `QUICKSTART_OPENCODE.md` | Exact Windows happy path and first-use proof |
| `ARQUITECTURA.md` | Updated three-plane architecture and lifecycle |
| `docs/getting-started.md` | Detailed install walkthrough |
| `docs/installation-targets.md` | User-owned locations and ownership boundaries |
| `docs/safety-and-sanitization.md` | Credentials, backups, logs, checksums and rollback guarantees |

## Locked compatibility candidate

The first release candidate starts with this exact matrix, then remains a release candidate until Task 15 proves it on a clean Windows machine:

| Component | Version |
|---|---:|
| Git for Windows | `2.53.0` |
| Node.js | `22.17.0` |
| pnpm | `11.8.0` |
| Python | `3.13.5` |
| uv | `0.11.14` |
| OpenCode (`opencode-ai`) | `1.17.8` |
| Engram | `1.16.3` |
| Graphify (`graphifyy`) | `0.8.41` |
| Context7 MCP | `3.2.1` |
| Playwright MCP | `0.0.76` |
| Pester (development/test only) | `5.7.1` |

Changing any value requires updating the lock, compatibility evidence and clean-machine result together.

### Task 1: Establish the PowerShell test harness and lock contract

**Files:**
- Create: `installer/components.lock.json`
- Create: `installer/modules/LockManifest.psm1`
- Create: `installer/tests/unit/LockManifest.Tests.ps1`
- Modify: `package.json`

- [ ] **Step 1: Write the failing lock validation tests**

```powershell
BeforeAll {
  Import-Module "$PSScriptRoot/../../modules/LockManifest.psm1" -Force
  $LockPath = "$PSScriptRoot/../../components.lock.json"
}

Describe 'components.lock.json' {
  It 'contains core and authenticated packs' {
    $lock = Read-ComponentLock -Path $LockPath
    $lock.packs.core.Count | Should -BeGreaterThan 0
    $lock.packs.authenticated.Count | Should -Be 4
  }

  It 'maps every component to an executable verification id' {
    $lock = Read-ComponentLock -Path $LockPath
    foreach ($component in $lock.components) {
      $component.verificationIds.Count | Should -BeGreaterThan 0
      $component.install.command | Should -Not -Match '[;&|]'
      $component.install.arguments | Should -BeOfType [System.Object[]]
    }
  }
}
```

- [ ] **Step 2: Run the test and confirm the module is missing**

Run:

```powershell
if (-not (Get-Module -ListAvailable Pester | Where-Object Version -EQ '5.7.1')) {
  Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -Force
}
Invoke-Pester installer/tests/unit/LockManifest.Tests.ps1 -Output Detailed
```

Expected: FAIL because `LockManifest.psm1` and `components.lock.json` do not exist.

- [ ] **Step 3: Add the locked manifest with schema version and capability packs**

The root object must use this exact shape; component records repeat this structure for every row in the compatibility matrix and for GitHub, Supabase, NotebookLM and Browserbase:

```json
{
  "schemaVersion": 1,
  "kitVersion": "0.2.0-rc.1",
  "platform": "windows-powershell",
  "packs": {
    "core": ["git", "node", "pnpm", "python", "uv", "opencode", "engram", "graphify", "context7", "playwright", "runtime-assets"],
    "authenticated": ["github", "supabase", "notebooklm", "browserbase"]
  },
  "components": [
    {
      "id": "opencode",
      "version": "1.17.8",
      "required": true,
      "dependencies": ["node", "pnpm"],
      "source": { "kind": "npm", "package": "opencode-ai" },
      "install": { "command": "pnpm", "arguments": ["add", "--global", "opencode-ai@1.17.8"] },
      "ownedTargets": [],
      "verificationIds": ["opencode.version", "opencode.config"]
    }
  ]
}
```

- [ ] **Step 4: Implement strict lock loading**

```powershell
Set-StrictMode -Version Latest

function Read-ComponentLock {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)

  $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
  $lock = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 30
  if ($lock.schemaVersion -ne 1) { throw "LOCK_SCHEMA_UNSUPPORTED: $($lock.schemaVersion)" }
  if ($lock.platform -ne 'windows-powershell') { throw "LOCK_PLATFORM_INVALID: $($lock.platform)" }
  $ids = @($lock.components.id)
  if ($ids.Count -ne @($ids | Select-Object -Unique).Count) { throw 'LOCK_COMPONENT_DUPLICATE' }
  return $lock
}

Export-ModuleMember -Function Read-ComponentLock
```

- [ ] **Step 5: Add and run the PowerShell test command**

Add to `package.json`:

```json
"test:powershell": "pwsh -NoProfile -File installer/tests/run.ps1"
```

Create `installer/tests/run.ps1` with:

```powershell
$ErrorActionPreference = 'Stop'
$result = Invoke-Pester -Path $PSScriptRoot -PassThru -Output Detailed
if ($result.FailedCount -gt 0) { exit 1 }
```

Run `pnpm test:powershell`; expected: PASS.

- [ ] **Step 6: Commit the lock contract**

```powershell
git add installer/components.lock.json installer/modules/LockManifest.psm1 installer/tests package.json
git commit -m "feat(installer): add locked component contract"
```

### Task 2: Build the safe process runner and public command router

**Files:**
- Create: `installer/modules/ProcessRunner.psm1`
- Create: `installer/bootstrap.ps1`
- Create: `installer/tests/unit/ProcessRunner.Tests.ps1`
- Create: `installer/tests/unit/Bootstrap.Tests.ps1`

- [ ] **Step 1: Write failing tests for argument arrays, redaction and verb validation**

```powershell
Describe 'Invoke-SafeProcess' {
  BeforeAll { Import-Module "$PSScriptRoot/../../modules/ProcessRunner.psm1" -Force }
  It 'redacts configured values' {
    $result = Invoke-SafeProcess -FilePath 'pwsh' -Arguments @('-NoProfile','-Command','Write-Output secret-value') -Redact @('secret-value')
    $result.StdOut | Should -Be '[REDACTED]'
    $result.ExitCode | Should -Be 0
  }
}

Describe 'bootstrap command parser' {
  It 'rejects unknown verbs' {
    { & "$PSScriptRoot/../../bootstrap.ps1" destroy } | Should -Throw '*COMMAND_UNSUPPORTED*'
  }
}
```

- [ ] **Step 2: Confirm RED**

Run `Invoke-Pester installer/tests/unit/ProcessRunner.Tests.ps1,installer/tests/unit/Bootstrap.Tests.ps1`; expected: FAIL for missing files.

- [ ] **Step 3: Implement the process runner without expression evaluation**

```powershell
function Invoke-SafeProcess {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FilePath,
    [string[]]$Arguments = @(),
    [string[]]$Redact = @()
  )
  $stdout = [System.IO.Path]::GetTempFileName()
  $stderr = [System.IO.Path]::GetTempFileName()
  try {
    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $out = Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue
    $err = Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
    foreach ($secret in $Redact | Where-Object { $_ }) {
      $out = $out.Replace($secret, '[REDACTED]')
      $err = $err.Replace($secret, '[REDACTED]')
    }
    [pscustomobject]@{ ExitCode = $process.ExitCode; StdOut = $out.Trim(); StdErr = $err.Trim() }
  } finally {
    Remove-Item -LiteralPath $stdout,$stderr -Force -ErrorAction SilentlyContinue
  }
}
Export-ModuleMember -Function Invoke-SafeProcess
```

- [ ] **Step 4: Implement explicit lifecycle dispatch**

```powershell
[CmdletBinding()]
param(
  [Parameter(Position=0)][string]$Command = 'install',
  [string]$Project,
  [switch]$Resume,
  [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$supported = @('install','doctor','status','configure','onboard','rollback')
if ($Command -notin $supported) { throw "COMMAND_UNSUPPORTED: $Command" }
& (Join-Path $root "commands/$Command.ps1") -Root $root -Project $Project -Resume:$Resume -NonInteractive:$NonInteractive
```

- [ ] **Step 5: Run tests and commit**

Run `pnpm test:powershell`; expected: PASS. Then:

```powershell
git add installer/bootstrap.ps1 installer/modules/ProcessRunner.psm1 installer/tests/unit
git commit -m "feat(installer): add safe lifecycle command router"
```

### Task 3: Implement Windows preflight and confirmed prerequisite installation

**Files:**
- Create: `installer/modules/Preflight.psm1`
- Create: `installer/commands/install.ps1`
- Create: `installer/tests/unit/Preflight.Tests.ps1`

- [ ] **Step 1: Write failing detection and plan tests**

```powershell
Describe 'Get-BootstrapPreflight' {
  BeforeAll { Import-Module "$PSScriptRoot/../../modules/Preflight.psm1" -Force }
  It 'returns a structured plan without installing' {
    $result = Get-BootstrapPreflight -RequiredBytes 1073741824
    $result.Platform | Should -Be 'windows-powershell'
    $result.Checks.Name | Should -Contain 'winget'
    $result.Actions | Should -BeOfType [System.Object[]]
  }
}
```

- [ ] **Step 2: Confirm RED**

Run `Invoke-Pester installer/tests/unit/Preflight.Tests.ps1`; expected: FAIL because the module is missing.

- [ ] **Step 3: Implement non-mutating discovery**

```powershell
function Get-BootstrapPreflight {
  [CmdletBinding()]
  param([long]$RequiredBytes = 1073741824)
  if (-not $IsWindows) { throw 'PLATFORM_UNSUPPORTED: Windows is required' }
  if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'POWERSHELL_UNSUPPORTED: PowerShell 7 is required' }
  $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($HOME).TrimEnd(':\'))
  if ($drive.Free -lt $RequiredBytes) { throw 'DISK_SPACE_INSUFFICIENT' }
  $tools = @('winget','git','node','pnpm','python','uv','opencode','engram','graphify')
  $checks = foreach ($tool in $tools) {
    [pscustomobject]@{ Name=$tool; Present=[bool](Get-Command $tool -ErrorAction SilentlyContinue) }
  }
  [pscustomobject]@{
    Platform='windows-powershell'
    Checks=@($checks)
    Actions=@($checks | Where-Object { -not $_.Present } | ForEach-Object { "install:$($_.Name)" })
  }
}
Export-ModuleMember -Function Get-BootstrapPreflight
```

- [ ] **Step 4: Add interactive confirmation and least-scope winget invocation**

`installer/commands/install.ps1` must print the plan, require `INSTALL` in interactive mode, and call winget once per missing prerequisite using argument arrays:

```powershell
$answer = if ($NonInteractive) { 'INSTALL' } else { Read-Host 'Type INSTALL to continue' }
if ($answer -ne 'INSTALL') { Write-Output 'CANCELED'; return }
$wingetArgs = @('install','--id','Git.Git','--exact','--version','2.53.0','--accept-package-agreements','--accept-source-agreements')
$result = Invoke-SafeProcess -FilePath 'winget' -Arguments $wingetArgs
if ($result.ExitCode -ne 0) { throw "PREREQUISITE_INSTALL_FAILED: git $($result.StdErr)" }
```

Drive every prerequisite from the lock instead of duplicating imperative branches:

```powershell
foreach ($component in $lock.components | Where-Object { $_.source.kind -eq 'winget' -and $_.id -in $missingIds }) {
  $arguments = @(
    'install','--id',$component.source.id,'--exact','--version',$component.version,
    '--accept-package-agreements','--accept-source-agreements'
  )
  $result = Invoke-SafeProcess -FilePath 'winget' -Arguments $arguments
  if ($result.ExitCode -ne 0) { throw "PREREQUISITE_INSTALL_FAILED:$($component.id):$($result.StdErr)" }
}
if ('pnpm' -in $missingIds) {
  $result = Invoke-SafeProcess -FilePath 'corepack' -Arguments @('prepare','pnpm@11.8.0','--activate')
  if ($result.ExitCode -ne 0) { throw "PREREQUISITE_INSTALL_FAILED:pnpm:$($result.StdErr)" }
}
```

- [ ] **Step 5: Run tests and commit**

```powershell
pnpm test:powershell
git add installer/modules/Preflight.psm1 installer/commands/install.ps1 installer/tests/unit/Preflight.Tests.ps1
git commit -m "feat(installer): add Windows preflight and prerequisite plan"
```

Expected: all Pester tests PASS and tests never invoke real winget.

### Task 4: Add receipts, backups, checkpoints, resume and safe rollback

**Files:**
- Create: `installer/modules/Receipt.psm1`
- Create: `installer/commands/rollback.ps1`
- Create: `installer/tests/unit/Receipt.Tests.ps1`
- Create: `installer/tests/integration/Rollback.Tests.ps1`

- [ ] **Step 1: Write traversal, resume and exact-restore tests**

```powershell
Describe 'receipt safety' {
  BeforeAll { Import-Module "$PSScriptRoot/../../modules/Receipt.psm1" -Force }
  It 'rejects a backup id containing traversal' {
    { Assert-SafeBackupId -BackupId '../outside' } | Should -Throw '*RECEIPT_BACKUP_ID_INVALID*'
  }
  It 'round-trips a checkpoint without secrets' {
    $path = Join-Path $TestDrive 'receipt.json'
    $receipt = New-InstallReceipt -KitVersion '0.2.0-rc.1' -LockDigest ('a' * 64)
    Save-InstallReceipt -Receipt $receipt -Path $path
    (Get-Content $path -Raw) | Should -Not -Match 'token|password|apiKey'
    (Read-InstallReceipt -Path $path).components.Count | Should -Be 0
  }
}
```

- [ ] **Step 2: Confirm RED**

Run `Invoke-Pester installer/tests/unit/Receipt.Tests.ps1`; expected: FAIL for missing exports.

- [ ] **Step 3: Implement sanitized receipt primitives**

```powershell
function Assert-SafeBackupId {
  param([Parameter(Mandatory)][string]$BackupId)
  if ($BackupId -notmatch '^[0-9]{8}T[0-9]{6}Z-[a-f0-9]{8}$') { throw 'RECEIPT_BACKUP_ID_INVALID' }
}
function New-InstallReceipt {
  param([string]$KitVersion,[string]$LockDigest)
  [ordered]@{
    schemaVersion=1; kitVersion=$KitVersion; lockDigest=$LockDigest
    createdAt=(Get-Date).ToUniversalTime().ToString('o')
    state='PLANNED'; components=@(); ownedPaths=@(); ownedKeys=@(); backups=@()
  }
}
function Save-InstallReceipt {
  param($Receipt,[string]$Path)
  $parent = Split-Path -Parent $Path
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
  $Receipt | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function Read-InstallReceipt {
  param([string]$Path)
  Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
}
Export-ModuleMember -Function Assert-SafeBackupId,New-InstallReceipt,Save-InstallReceipt,Read-InstallReceipt
```

- [ ] **Step 4: Implement rollback boundaries**

Rollback resolves every receipt path, confirms it is within `$HOME/.opencode-runtime-kit` or the detected OpenCode user config, restores backups, removes only `ownedPaths`, and preserves Git, Node, Python, uv, OpenCode and credentials. A path outside those roots throws `ROLLBACK_PATH_OUTSIDE_OWNERSHIP` before any mutation.

- [ ] **Step 5: Prove interrupted resume and exact restoration**

Run:

```powershell
Invoke-Pester installer/tests/integration/Rollback.Tests.ps1 -Output Detailed
```

Expected: PASS for an interrupted `CONFIGURED` component, second-run continuation, exact original JSON restoration and rejection of a tampered receipt.

- [ ] **Step 6: Commit**

```powershell
git add installer/modules/Receipt.psm1 installer/commands/rollback.ps1 installer/tests
git commit -m "feat(installer): add resumable receipts and safe rollback"
```

### Task 5: Compose OpenCode JSON/JSONC without overwriting user entries

**Files:**
- Create: `installer/modules/ConfigComposer.psm1`
- Create: `installer/tests/unit/ConfigComposer.Tests.ps1`
- Create: `installer/tests/fixtures/opencode-existing.jsonc`

- [ ] **Step 1: Write failing preservation and collision tests**

```powershell
Describe 'Merge-OpenCodeConfig' {
  BeforeAll { Import-Module "$PSScriptRoot/../../modules/ConfigComposer.psm1" -Force }
  It 'preserves unrelated MCP entries' {
    $existing = '{"mcp":{"custom":{"command":["custom.exe"]}}}'
    $owned = [ordered]@{ mcp = [ordered]@{ engram = [ordered]@{ command=@('engram','mcp','--tools=agent') } } }
    $result = Merge-OpenCodeConfig -ExistingText $existing -Owned $owned
    $result.Document.mcp.custom.command[0] | Should -Be 'custom.exe'
    $result.Document.mcp.engram.command[0] | Should -Be 'engram'
  }
  It 'reports a kit-name collision without writing' {
    $existing = '{"mcp":{"engram":{"command":["other.exe"]}}}'
    { Merge-OpenCodeConfig -ExistingText $existing -Owned @{mcp=@{engram=@{command=@('engram','mcp')}}} } | Should -Throw '*CONFIG_COLLISION:mcp.engram*'
  }
}
```

- [ ] **Step 2: Confirm RED**

Run `Invoke-Pester installer/tests/unit/ConfigComposer.Tests.ps1`; expected: FAIL.

- [ ] **Step 3: Implement comment-aware parsing and structural ownership merge**

Use a repository-owned JSONC parser module pinned in `installer/vendor/` or a tested comment stripper that preserves string literals. The exported API is fixed:

```powershell
function Merge-OpenCodeConfig {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$ExistingText,[Parameter(Mandatory)][hashtable]$Owned)
  $document = ConvertFrom-Jsonc -Text $ExistingText
  $ownedKeys = [System.Collections.Generic.List[string]]::new()
  Merge-OwnedNode -Target $document -Source $Owned -Prefix '' -OwnedKeys $ownedKeys
  [pscustomobject]@{ Document=$document; OwnedKeys=@($ownedKeys); Json=($document | ConvertTo-Json -Depth 30) }
}
```

`Merge-OwnedNode` treats equal values as idempotent, adds absent values and throws `CONFIG_COLLISION:<path>` for a different existing value.

- [ ] **Step 4: Add backup-before-write integration test**

The test creates an existing config, calls the composer write operation, asserts that the backup bytes equal the original bytes, and asserts a second run produces no diff.

- [ ] **Step 5: Run and commit**

```powershell
pnpm test:powershell
git add installer/modules/ConfigComposer.psm1 installer/tests
git commit -m "feat(installer): merge OpenCode config with ownership"
```

### Task 6: Implement dependency execution and the verification registry

**Files:**
- Create: `installer/modules/ComponentRunner.psm1`
- Create: `installer/modules/Verification.psm1`
- Create: `installer/tests/unit/ComponentRunner.Tests.ps1`
- Create: `installer/tests/unit/Verification.Tests.ps1`

- [ ] **Step 1: Write failing state-machine tests**

```powershell
Describe 'Invoke-ComponentPlan' {
  BeforeAll { Import-Module "$PSScriptRoot/../../modules/ComponentRunner.psm1" -Force }
  It 'orders dependencies and reaches VERIFIED' {
    $components = @(
      [pscustomobject]@{id='node';dependencies=@();verificationIds=@('node.version')},
      [pscustomobject]@{id='opencode';dependencies=@('node');verificationIds=@('opencode.version')}
    )
    $result = Invoke-ComponentPlan -Components $components -Executor { param($c) $true } -Verifier { param($id) $true }
    @($result.id) | Should -Be @('node','opencode')
    @($result.state | Select-Object -Unique) | Should -Be @('VERIFIED')
  }
}
```

- [ ] **Step 2: Confirm RED**

Run the two Pester files; expected: FAIL for missing modules.

- [ ] **Step 3: Implement the only legal component transitions**

```powershell
$script:Transitions = @{
  DETECTED=@('PLANNED'); PLANNED=@('INSTALLED'); INSTALLED=@('CONFIGURED'); CONFIGURED=@('VERIFIED')
}
function Assert-StateTransition {
  param([string]$From,[string]$To)
  if ($To -notin $script:Transitions[$From]) { throw "COMPONENT_STATE_INVALID:$From->$To" }
}
```

Topologically sort dependencies, reject cycles as `COMPONENT_DEPENDENCY_CYCLE`, save the receipt after every transition, and stop core readiness on the first mandatory verification failure.

- [ ] **Step 4: Implement a closed verification registry**

```powershell
$script:VerificationRegistry = @{
  'node.version'     = { Invoke-VersionProbe -Command 'node' -Arguments @('--version') -Expected '22.17.0' }
  'opencode.version' = { Invoke-VersionProbe -Command 'opencode' -Arguments @('--version') -Expected '1.17.8' }
  'engram.persist'   = { Test-EngramPersistence }
  'graphify.query'   = { Test-GraphifyFixture }
  'mcp.context7'     = { Test-McpServer -Name 'context7' }
  'mcp.playwright'   = { Test-McpServer -Name 'playwright' }
  'runtime.assets'   = { Test-RuntimeAssets }
}
function Invoke-VerificationId {
  param([string]$Id)
  if (-not $script:VerificationRegistry.ContainsKey($Id)) { throw "VERIFICATION_ID_UNKNOWN:$Id" }
  & $script:VerificationRegistry[$Id]
}
```

- [ ] **Step 5: Run tests and commit**

```powershell
pnpm test:powershell
git add installer/modules/ComponentRunner.psm1 installer/modules/Verification.psm1 installer/tests/unit
git commit -m "feat(installer): add component state and verification registry"
```

### Task 7: Install the pinned OpenCode, Engram and Graphify core

**Files:**
- Modify: `installer/components.lock.json`
- Modify: `installer/modules/Verification.psm1`
- Create: `installer/tests/integration/CoreComponents.Tests.ps1`
- Create: `installer/tests/e2e/fixtures/graphify/sample.js`

- [ ] **Step 1: Write failing fake-executable integration tests**

Create shims for `opencode`, `engram` and `graphify` in `$TestDrive/bin`; assert the runner uses exactly the locked versions and rejects a version mismatch as `COMPONENT_VERSION_MISMATCH`.

- [ ] **Step 2: Record exact source integrity**

For Engram `1.16.3`, download the official Windows release and its upstream checksum file into a temporary directory, run:

```powershell
Get-FileHash -Algorithm SHA256 .\engram-windows-amd64.exe
```

Store the resulting lowercase 64-character digest and immutable release URL in the Engram lock record. The test rejects a missing or non-64-character hash for `source.kind = "github-release"`.

- [ ] **Step 3: Add pinned install records**

Use `pnpm add --global opencode-ai@1.17.8`, the verified Engram release artifact, and `uv tool install graphifyy==0.8.41`. Do not use `latest`, remote script piping or an unversioned package command.

- [ ] **Step 4: Implement functional probes**

Engram probe uses an isolated temporary `ENGRAM_DATA_DIR`, saves a canary, stops the process, starts a fresh process and searches for the same canary. Graphify probe copies `sample.js`, builds the graph and executes a query whose result must contain `hello`.

```javascript
export function hello(name) {
  return `hello ${name}`;
}
```

- [ ] **Step 5: Run focused tests and commit**

```powershell
Invoke-Pester installer/tests/integration/CoreComponents.Tests.ps1 -Output Detailed
git add installer/components.lock.json installer/modules/Verification.psm1 installer/tests
git commit -m "feat(installer): install and verify OpenCode Engram Graphify"
```

### Task 8: Configure and probe credential-free MCP servers

**Files:**
- Modify: `installer/components.lock.json`
- Create: `installer/assets/opencode/mcp.core.json`
- Create: `installer/tests/integration/McpCore.Tests.ps1`
- Modify: `installer/modules/Verification.psm1`

- [ ] **Step 1: Write failing MCP configuration tests**

Assert the composed config contains `engram`, `context7` and `playwright`; each command uses a versioned package or executable and no secret literal.

- [ ] **Step 2: Add canonical MCP definitions**

```json
{
  "mcp": {
    "engram": { "type": "local", "command": ["engram", "mcp", "--tools=agent"], "enabled": true },
    "context7": { "type": "local", "command": ["pnpm", "dlx", "@upstash/context7-mcp@3.2.1"], "enabled": true },
    "playwright": { "type": "local", "command": ["pnpm", "dlx", "@playwright/mcp@0.0.76"], "enabled": true }
  }
}
```

- [ ] **Step 3: Implement protocol-level probes**

Start each server with redirected stdio, send MCP `initialize`, assert a valid protocol response, then request `tools/list`. OpenCode `mcp list` is supporting evidence but is not the only probe.

- [ ] **Step 4: Prove no-credential readiness**

Run the integration test with GitHub, Supabase, NotebookLM and Browserbase environment variables removed. Expected global state: `CORE_READY` and optional components: `PENDING_AUTH`.

- [ ] **Step 5: Commit**

```powershell
git add installer/components.lock.json installer/assets/opencode/mcp.core.json installer/modules/Verification.psm1 installer/tests/integration/McpCore.Tests.ps1
git commit -m "feat(installer): configure credential-free MCP core"
```

### Task 9: Install canonical Manager, ten SDD subagents, skills and audited plugins

**Files:**
- Create: `installer/assets/opencode/agents/manager.md`
- Create: `installer/assets/opencode/agents/{init,explore,propose,spec,design,tasks,apply,verify,archive,onboard}.md`
- Create: `installer/assets/opencode/plugins/engram.ts`
- Create: `installer/assets/opencode/plugins/graphify.ts`
- Create: `installer/assets/opencode/catalog.json`
- Modify: `installer/components.lock.json`
- Create: `installer/tests/unit/RuntimeAssets.Tests.ps1`
- Create: `installer/tests/integration/OpenCodeDiscovery.Tests.ps1`

- [ ] **Step 1: Write failing catalog invariants**

Tests require exactly one primary Manager, ten hidden subagents, the 18 existing portable skills, ten SDD skills, Graphify skill, shared Engram/persistence conventions and both required plugins. Counts come from `catalog.json`, never README literals.

- [ ] **Step 2: Create thin agent bindings**

Every worker frontmatter uses `mode: subagent`, `hidden: true` and a canonical contract path. Manager alone uses `mode: primary`. Binding bodies contain only runtime-specific invocation instructions and never duplicate the complete canonical procedure.

- [ ] **Step 3: Add repository-owned plugin adapters**

`engram.ts` performs lifecycle/session integration without becoming a second memory database. `graphify.ts` validates project boundaries before graph operations. Both export OpenCode-compatible plugin functions, contain no development-machine paths and fail closed on an unsupported pinned OpenCode version.

- [ ] **Step 4: Verify runtime discovery**

Run OpenCode against a disposable config and assert it discovers one primary, all ten hidden workers, every catalog skill and both plugins without load errors.

- [ ] **Step 5: Commit**

```powershell
git add installer/assets installer/components.lock.json installer/tests
git commit -m "feat(installer): add OpenCode agents skills and plugins"
```

### Task 10: Add optional authenticated integrations and secure continuation

**Files:**
- Create: `installer/modules/CredentialFlow.psm1`
- Create: `installer/commands/configure.ps1`
- Create: `installer/assets/opencode/mcp.optional.json`
- Create: `installer/tests/unit/CredentialFlow.Tests.ps1`
- Create: `installer/tests/integration/OptionalIntegrations.Tests.ps1`

- [ ] **Step 1: Write failing skipped-auth and redaction tests**

Assert skipped integrations produce `PENDING_AUTH`, API keys appear only as environment-variable names, and receipts/logs/backups contain none of the supplied secret values.

- [ ] **Step 2: Implement explicit integration states**

```powershell
enum CapabilityState {
  INSTALLED_VERIFIED
  INSTALLED_DEGRADED
  PENDING_AUTH
  NOT_INSTALLED
  UNSUPPORTED
}
```

GitHub, Supabase, NotebookLM and Browserbase each expose `Detect`, `Configure`, `Verify` and `PendingInstructions`. Skipping any of them never changes credential-free core readiness.

- [ ] **Step 3: Implement secure credential behavior**

Use provider/OpenCode OAuth stores when available. For API-key integrations, write only references such as `{env:BROWSERBASE_API_KEY}` into config and instruct the user to create a user-scoped environment variable. Never echo, serialize or back up the value.

- [ ] **Step 4: Add resumable configuration command**

`bootstrap.ps1 configure` reads pending component IDs from the receipt, prompts one integration at a time, executes only selected flows, and reruns their verification IDs.

- [ ] **Step 5: Run tests and commit**

```powershell
pnpm test:powershell
git add installer/modules/CredentialFlow.psm1 installer/commands/configure.ps1 installer/assets/opencode/mcp.optional.json installer/tests
git commit -m "feat(installer): add optional secure integrations"
```

### Task 11: Implement doctor, status and project onboarding

**Files:**
- Create: `installer/commands/doctor.ps1`
- Create: `installer/commands/status.ps1`
- Create: `installer/commands/onboard.ps1`
- Create: `installer/modules/Onboarding.psm1`
- Create: `installer/tests/integration/Doctor.Tests.ps1`
- Create: `installer/tests/integration/Onboarding.Tests.ps1`

- [ ] **Step 1: Write failing terminal-state tests**

Test `CORE_READY`, `READY_WITH_PENDING_AUTH` and `FAILED`. A missing required plugin must produce `FAILED`; missing GitHub credentials must produce `READY_WITH_PENDING_AUTH` while core probes remain green.

- [ ] **Step 2: Implement evidence-backed doctor output**

```powershell
[pscustomobject]@{
  State = 'READY_WITH_PENDING_AUTH'
  Capabilities = @(
    @{ id='engram'; state='INSTALLED_VERIFIED'; evidence='restart canary returned' },
    @{ id='github'; state='PENDING_AUTH'; evidence='run bootstrap.ps1 configure' }
  )
  NextCommand = '.\installer\bootstrap.ps1 configure'
}
```

Support human-readable console output and `-Json` for CI. Status reads the latest verified receipt without mutating; doctor executes probes.

- [ ] **Step 3: Implement safe onboarding**

Resolve the project path, reject filesystem roots and the Runtime Kit install root, run Graphify only inside that project, then invoke the `onboard` subagent to write a compact repo-owned index. Do not edit application source.

- [ ] **Step 4: Test skip and idempotency**

Running onboarding twice must update the managed index without duplicating entries. Skipping onboarding leaves the global installation `CORE_READY`.

- [ ] **Step 5: Commit**

```powershell
git add installer/commands installer/modules/Onboarding.psm1 installer/tests/integration
git commit -m "feat(installer): add doctor status and onboarding"
```

### Task 12: Add source, disposable-install and tamper test suites

**Files:**
- Create: `installer/tests/source/SourceDoctor.Tests.ps1`
- Create: `installer/tests/integration/DisposableInstall.Tests.ps1`
- Create: `installer/tests/integration/Tamper.Tests.ps1`
- Modify: `installer/tests/run.ps1`
- Modify: `package.json`

- [ ] **Step 1: Write source-mode tests**

Source doctor validates repository assets, schema, hashes, canonical adapter targets and verification registry coverage without requiring an installed user target.

- [ ] **Step 2: Write disposable target tests**

Use `$TestDrive` plus fake executables to exercise install, second install, interrupted resume, doctor and rollback. Assert no source path leaks into the installed config or skill registry.

- [ ] **Step 3: Write negative security tests**

Cover bad checksums, dependency cycles, JSONC collisions, unknown verification IDs, receipt traversal, owned path escapes, secret redaction and a plugin load failure.

- [ ] **Step 4: Expose exact test commands**

Add:

```json
"test:bootstrap": "pwsh -NoProfile -File installer/tests/run.ps1",
"test:all": "node scripts/validate.mjs && node scripts/sanitize-check.mjs && node scripts/docs-check.mjs && node scripts/run-tests.mjs && pwsh -NoProfile -File installer/tests/run.ps1"
```

- [ ] **Step 5: Run the full suite and commit**

Run `pnpm test:all`; expected: all Node and Pester suites PASS.

```powershell
git add installer/tests package.json
git commit -m "test(installer): cover source disposable and tamper modes"
```

### Task 13: Rewrite beginner-facing and architectural documentation

**Files:**
- Modify: `README.md`
- Modify: `QUICKSTART_OPENCODE.md`
- Modify: `ARQUITECTURA.md`
- Modify: `docs/getting-started.md`
- Modify: `docs/installation-targets.md`
- Modify: `docs/safety-and-sanitization.md`
- Create: `docs/capability-matrix.md`
- Create: `docs/bootstrap-troubleshooting.md`
- Modify: `scripts/docs-check.mjs`
- Modify: `tests/unit/docs-check.test.mjs`

- [ ] **Step 1: Write failing documentation-contract tests**

Require README headings in this order: Qué es, Qué instala, Qué no instala, Instalación recomendada para Windows, Resultado esperado, Primer uso, Estado y doctor, Autenticación opcional, Rollback, Arquitectura avanzada. Reject the obsolete claims that OpenCode, Engram, MCP, Graphify, plugins or subagents are not installed.

- [ ] **Step 2: Rewrite README as the authoritative beginner entry**

The first screen must say that the new Windows bootstrap installs the complete OpenCode core, while Codex remains a separate overlay path. Show exactly:

```powershell
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
Set-Location proyecto-opencode-mem
.\installer\bootstrap.ps1 install
.\installer\bootstrap.ps1 doctor
```

Explain the interactive preview, winget confirmation, credential skipping, installed locations, three terminal states and that “100% functional” is only used after the release gate.

- [ ] **Step 3: Rewrite QuickStart OpenCode around observable proof**

Include a clean-Windows path, sample `READY_WITH_PENDING_AUTH` output, first memory canary, first Graphify fixture query, Manager/subagent discovery, optional `configure`, `status`, `onboard` and `rollback` commands.

- [ ] **Step 4: Update architecture and safety documents**

`ARQUITECTURA.md` must document canonical capability, runtime adapter and state planes; component transitions; packs; ownership; verification IDs; Engram primary plus minimal file checkpoint; and the three independent test modes. Installation targets must enumerate only user-owned paths. Safety must cover hashes, redaction, no remote piping, no expression evaluation, collision policy and rollback exclusions.

- [ ] **Step 5: Add capability matrix and repair guide**

The matrix is generated from the lock and doctor evidence and distinguishes installed, connected and functionally verified. Troubleshooting maps stable error codes such as `CONFIG_COLLISION`, `COMPONENT_VERSION_MISMATCH`, `CHECKSUM_MISMATCH`, `PENDING_AUTH` and `ROLLBACK_PATH_OUTSIDE_OWNERSHIP` to exact safe commands.

- [ ] **Step 6: Run documentation and full tests**

```powershell
pnpm docs:check
pnpm test:all
```

Expected: PASS with no stale “overlay only” OpenCode claims.

- [ ] **Step 7: Commit documentation together with its contract tests**

```powershell
git add README.md QUICKSTART_OPENCODE.md ARQUITECTURA.md docs scripts/docs-check.mjs tests/unit/docs-check.test.mjs
git commit -m "docs: explain complete OpenCode bootstrap"
```

### Task 14: Add Windows CI and release provenance

**Files:**
- Create: `.github/workflows/windows-bootstrap.yml`
- Create: `installer/scripts/source-doctor.ps1`
- Create: `installer/scripts/export-provenance.ps1`
- Create: `installer/tests/e2e/CleanMachine.Tests.ps1`
- Create: `docs/release-evidence/open-code-bootstrap-0.2.0-rc.1.md`

- [ ] **Step 1: Write the Windows workflow**

The workflow uses `windows-latest`, checks out the exact commit, enables corepack, installs dependencies with a frozen lockfile, runs `pnpm test:all`, runs source doctor and performs a disposable non-interactive install with fake credential providers.

- [ ] **Step 2: Export provenance**

Write JSON containing kit version, Git commit, lock SHA-256, artifact hashes, PowerShell version and test run URL. Reject a dirty working tree when producing release evidence.

- [ ] **Step 3: Add clean-machine assertions**

The E2E test requires OpenCode discovery, Engram restart persistence, Graphify build/query, Context7 and Playwright MCP responses, ten subagents, all catalog skills, both plugins, idempotent second run and exact rollback.

- [ ] **Step 4: Keep release status honest**

The evidence document remains `release candidate` until a Windows Sandbox or clean VM result records every gate as PASS. CI alone cannot change the wording to `100% functional`.

- [ ] **Step 5: Commit CI and evidence framework**

```powershell
git add .github/workflows/windows-bootstrap.yml installer/scripts installer/tests/e2e docs/release-evidence
git commit -m "ci: add Windows bootstrap release gates"
```

### Task 15: Execute the clean Windows release gate and finalize documentation status

**Files:**
- Modify: `docs/release-evidence/open-code-bootstrap-0.2.0-rc.1.md`
- Modify: `README.md`
- Modify: `QUICKSTART_OPENCODE.md`
- Modify: `docs/capability-matrix.md`

- [ ] **Step 1: Test a clean Windows machine with no prerequisites**

Clone the exact commit and run `bootstrap.ps1 install`. Record provenance and sanitized doctor JSON. Expected: prerequisites installed after confirmation and state `READY_WITH_PENDING_AUTH` or `CORE_READY` depending on optional choices.

- [ ] **Step 2: Test compatible preinstalled prerequisites**

Run the same commit on a machine containing the locked compatible versions. Expected: compatible installations are reused and no prerequisite is reinstalled only to change its source.

- [ ] **Step 3: Test lifecycle recovery**

Interrupt after one component reaches `CONFIGURED`, resume, rerun install for idempotency, then rollback. Expected: resume starts at the first incomplete component and rollback exactly restores prior configuration.

- [ ] **Step 4: Test optional authentication paths**

Complete each provider one at a time without recording secrets. Expected: only that capability transitions from `PENDING_AUTH` to `INSTALLED_VERIFIED`; core readiness remains unchanged.

- [ ] **Step 5: Update release claims from evidence**

If and only if every release gate passes, change documentation status from `release candidate` to `Windows verified` and link the evidence file. If any gate fails, retain release-candidate wording, record the failed verification ID and return to its owning task.

- [ ] **Step 6: Run final local verification**

```powershell
pnpm test:all
.\installer\bootstrap.ps1 doctor -Json
git diff --check
git status --short
```

Expected: all tests PASS, doctor reports no mandatory failure, diff check is empty and only intended release-evidence/documentation files are modified.

- [ ] **Step 7: Commit verified release evidence**

```powershell
git add README.md QUICKSTART_OPENCODE.md docs/capability-matrix.md docs/release-evidence/open-code-bootstrap-0.2.0-rc.1.md
git commit -m "docs: record verified Windows bootstrap evidence"
```

## Self-review results

- **Spec coverage:** all design sections map to Tasks 1–15; documentation is an explicit deliverable in Task 13 and release claims are evidence-gated in Task 15.
- **Security coverage:** hashes, no remote piping, argument arrays, redaction, path validation, ownership, backups, collision handling and safe rollback are tested.
- **Functional coverage:** OpenCode, Engram persistence, Graphify queries, MCP protocol, plugins, Manager, ten subagents and catalog skills have behavioral probes.
- **Portability boundary:** only Windows PowerShell is claimed; WSL, Bash, symlinks and application-managed directories are excluded.
- **Update boundary:** versions are pinned; a user-facing updater remains outside this implementation.
- **Regression boundary:** existing Codex and Node suites remain mandatory in `pnpm test:all`.
