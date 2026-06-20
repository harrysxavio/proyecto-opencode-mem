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
    [Nullable[long]]$FreeBytes,
    [string]$KitRoot = $(if ($env:OPENCODE_KIT_ROOT) { $env:OPENCODE_KIT_ROOT } else { Join-Path $env:LOCALAPPDATA 'OpenCodeKit' }),
    [scriptblock]$CoreExecutor,
    [scriptblock]$CoreVerifier,
    [scriptblock]$CoreCheckpointWriter,
    [scriptblock]$CoreProcessInvoker,
    [scriptblock]$CoreDownloader,
    [object]$CoreReceipt
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installerRoot = Join-Path $Root 'installer'
Import-Module (Join-Path $installerRoot 'modules/LockManifest.psm1') -Force
Import-Module (Join-Path $installerRoot 'modules/ProcessRunner.psm1') -Force
Import-Module (Join-Path $installerRoot 'modules/Preflight.psm1') -Force
Import-Module (Join-Path $installerRoot 'modules/CoreComponents.psm1') -Force
Import-Module (Join-Path $installerRoot 'modules/ComponentRunner.psm1') -Force
Import-Module (Join-Path $installerRoot 'modules/Receipt.psm1') -Force
Import-Module (Join-Path $installerRoot 'modules/Verification.psm1') -Force
$lock = Read-ComponentLock -Path (Join-Path $installerRoot 'components.lock.json')
$core = @($lock.components | Where-Object { $_.id -cin @('opencode','engram','graphify') } | ForEach-Object {
    $copy = $_ | ConvertTo-Json -Depth 30 -Compress | ConvertFrom-Json -Depth 30
    $copy.dependencies = @($copy.dependencies | Where-Object { $_ -cin @('opencode','engram','graphify') })
    $copy
})
$corePreview = @(Get-CoreComponentPreview -Components $core -KitRoot $KitRoot)

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
    actions = @($plan.Items | ForEach-Object { "install:$($_.id)" }) + @($corePreview | ForEach-Object { "install:$($_.Id)" })
    core = $corePreview
}
if (-not $Json) { Write-Host ($display | ConvertTo-Json -Depth 10) }

$installArgs = @{ Plan = $plan; NonInteractive = $NonInteractive; ConfirmInstall = $ConfirmInstall }
if ($PSBoundParameters.ContainsKey('Runner')) { $installArgs.Runner = $Runner }
if ($PSBoundParameters.ContainsKey('ConfirmationReader')) { $installArgs.ConfirmationReader = $ConfirmationReader }
if ($PSBoundParameters.ContainsKey('ExecutableResolver')) { $installArgs.ExecutableResolver = $ExecutableResolver }
if ($PSBoundParameters.ContainsKey('PathRefresher')) { $installArgs.PathRefresher = $PathRefresher }
$result = Invoke-ConfirmedPrerequisiteInstall @installArgs
$coreResult = $null
if ($result.Status -ceq 'COMPLETED' -and $result.InstallApproved) {
    $receipt = if ($PSBoundParameters.ContainsKey('CoreReceipt')) { $CoreReceipt } else {
        $digest = (Get-FileHash -LiteralPath (Join-Path $installerRoot 'components.lock.json') -Algorithm SHA256).Hash.ToLowerInvariant()
        New-InstallReceipt -KitVersion ([string]$lock.kitVersion) -LockDigest $digest -SourceCommit 'workspace'
    }
    $executor = if ($PSBoundParameters.ContainsKey('CoreExecutor')) { $CoreExecutor } else {
        {
            param($Component,$Phase)
            if ($Phase -ceq 'Configure') { return [pscustomobject]@{ Success=$true; Evidence='no configuration required' } }
            $args = @{ Component=$Component; KitRoot=$KitRoot }
            if ($null -ne $CoreProcessInvoker) { $args.ProcessInvoker = $CoreProcessInvoker }
            if ($null -ne $CoreDownloader) { $args.Downloader = $CoreDownloader }
            try { $installed = Install-CoreComponent @args; [pscustomobject]@{ Success=$true; Evidence=$installed } }
            catch { [pscustomobject]@{ Success=$false; Evidence=$_.Exception.Message } }
        }.GetNewClosure()
    }
    $verifier = if ($PSBoundParameters.ContainsKey('CoreVerifier')) { $CoreVerifier } else {
        {
            param($Id,$Component)
            if ($Id -ceq 'engram.persist') {
                $probeArgs = @{ EngramPath=(Join-Path ([IO.Path]::GetFullPath($KitRoot)) 'bin/engram.exe') }
                if ($null -ne $CoreProcessInvoker) { $probeArgs.ProcessInvoker=$CoreProcessInvoker }
                $probe = Test-EngramPersistence @probeArgs
                return [pscustomobject]@{ Status=$(if($probe.Success){'PASS'}else{'FAIL'}); ErrorCode=$(if($probe.Success){$null}else{'VERIFICATION_PROBE_FAILED'}); Evidence=$probe.Evidence }
            }
            if ($Id -ceq 'graphify.query') {
                $probeArgs = @{}
                if ($null -ne $CoreProcessInvoker) { $probeArgs.ProcessInvoker=$CoreProcessInvoker }
                $probe = Test-GraphifyFixture @probeArgs
                return [pscustomobject]@{ Status=$(if($probe.Success){'PASS'}else{'FAIL'}); ErrorCode=$(if($probe.Success){$null}else{'VERIFICATION_PROBE_FAILED'}); Evidence=$probe.Evidence }
            }
            $verifyArgs = @{ Id=$Id; ExpectedVersion=[string]$Component.version }
            $mapped = {
                param($FilePath,$Arguments)
                if($FilePath -ceq 'engram'){ $FilePath=Join-Path ([IO.Path]::GetFullPath($KitRoot)) 'bin/engram.exe' }
                if ($null -ne $CoreProcessInvoker) { & $CoreProcessInvoker $FilePath $Arguments }
                else { Invoke-SafeProcess -FilePath $FilePath -Arguments $Arguments }
            }.GetNewClosure()
            $verifyArgs.ProcessInvoker=$mapped
            Invoke-VerificationId @verifyArgs
        }.GetNewClosure()
    }
    $checkpoint = if ($PSBoundParameters.ContainsKey('CoreCheckpointWriter')) { $CoreCheckpointWriter } else {
        $receiptRoot = Join-Path ([IO.Path]::GetFullPath($KitRoot)) 'state'
        $receiptPath = Join-Path $receiptRoot 'install-receipt.json'
        { param($candidate) Save-InstallReceipt -Receipt $candidate -Path $receiptPath -ReceiptRoot $receiptRoot | Out-Null }.GetNewClosure()
    }
    $coreResult = Invoke-ComponentPlan -Components $core -Receipt $receipt -Executor $executor -Verifier $verifier -CheckpointWriter $checkpoint
}
$overallStatus = if ($null -ne $coreResult) { [string]$coreResult.Status } else { [string]$result.Status }
if ($Json) {
    $display.state = $overallStatus
    $display.result = $result
    $display.coreResult = $coreResult
    Write-Output -NoEnumerate ($display | ConvertTo-Json -Depth 20)
}
else { [pscustomobject][ordered]@{ Status=$overallStatus; Prerequisites=$result; Core=$coreResult } }
