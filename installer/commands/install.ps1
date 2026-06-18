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
    [scriptblock]$ConfirmationReader
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
$preflight = Get-BootstrapPreflight @preflightArgs
$plan = Resolve-PrerequisitePlan @planArgs

$display = [pscustomobject]@{
    Project = $Project
    Resume = [bool]$Resume
    Preflight = $preflight
    Install = @($plan.Items | ForEach-Object { [pscustomobject]@{ Id = $_.id; Version = $_.version; Source = $_.source.kind } })
    VersionMismatches = @($plan.VersionMismatches)
}
Write-Host ($display | ConvertTo-Json -Depth 10)

$installArgs = @{ Plan = $plan; NonInteractive = $NonInteractive; ConfirmInstall = $ConfirmInstall }
if ($PSBoundParameters.ContainsKey('Runner')) { $installArgs.Runner = $Runner }
if ($PSBoundParameters.ContainsKey('ConfirmationReader')) { $installArgs.ConfirmationReader = $ConfirmationReader }
$result = Invoke-ConfirmedPrerequisiteInstall @installArgs
if ($Json) { $result | ConvertTo-Json -Depth 10 } else { $result }
