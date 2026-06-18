[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$Project,
    [switch]$Resume,
    [switch]$NonInteractive,
    [switch]$Json,
    [switch]$ConfirmInstall,
    [scriptblock]$CommandResolver,
    [scriptblock]$Runner,
    [scriptblock]$ConfirmationReader,
    [scriptblock]$ExecutableResolver,
    [scriptblock]$PathRefresher,
    [Nullable[bool]]$PlatformIsWindows,
    [version]$PowerShellVersion,
    [Nullable[long]]$FreeBytes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installerRoot = Join-Path $Root 'installer'
Import-Module (Join-Path $installerRoot 'modules/LockManifest.psm1') -Force
Import-Module (Join-Path $installerRoot 'modules/ProcessRunner.psm1') -Force
Import-Module (Join-Path $installerRoot 'modules/Preflight.psm1') -Force
$lock = Read-ComponentLock -Path (Join-Path $installerRoot 'components.lock.json')

$resolver = if ($PSBoundParameters.ContainsKey('CommandResolver')) { $CommandResolver } else { $null }
$preflightArgs = @{ Lock = $lock }
$planArgs = @{ Lock = $lock }
if ($null -ne $resolver) { $preflightArgs.CommandResolver = $resolver; $planArgs.CommandResolver = $resolver }
foreach ($name in @('PlatformIsWindows', 'PowerShellVersion', 'FreeBytes')) {
    if ($PSBoundParameters.ContainsKey($name)) { $preflightArgs[$name] = $PSBoundParameters[$name] }
}
$preflight = Get-BootstrapPreflight @preflightArgs
$plan = Resolve-PrerequisitePlan @planArgs

$display = [ordered]@{
    Project = $Project
    Resume = [bool]$Resume
    preflight = $preflight
    plan = $plan
    actions = @($plan.Items | ForEach-Object { "install:$($_.id)" })
}
if (-not $Json) { Write-Host ($display | ConvertTo-Json -Depth 10) }

$installArgs = @{ Plan = $plan; NonInteractive = $NonInteractive; ConfirmInstall = $ConfirmInstall }
if ($PSBoundParameters.ContainsKey('Runner')) { $installArgs.Runner = $Runner }
if ($PSBoundParameters.ContainsKey('ConfirmationReader')) { $installArgs.ConfirmationReader = $ConfirmationReader }
if ($PSBoundParameters.ContainsKey('ExecutableResolver')) { $installArgs.ExecutableResolver = $ExecutableResolver }
if ($PSBoundParameters.ContainsKey('PathRefresher')) { $installArgs.PathRefresher = $PathRefresher }
$result = Invoke-ConfirmedPrerequisiteInstall @installArgs
if ($Json) {
    $display.state = $result.Status
    $display.result = $result
    Write-Output -NoEnumerate ($display | ConvertTo-Json -Depth 20)
}
else { $result }
