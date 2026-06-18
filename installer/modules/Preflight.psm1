Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runnerModule = Join-Path $PSScriptRoot 'ProcessRunner.psm1'
Import-Module $runnerModule -Force

function Get-DefaultCommandState {
    param([Parameter(Mandatory)][string]$Id)

    $commandName = if ($Id -eq 'python') { 'python' } else { $Id }
    $command = Get-Command -Name $commandName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{ Present = $false; Version = $null }
    }
    if ($Id -eq 'winget') {
        return [pscustomobject]@{ Present = $true; Version = $null }
    }

    $result = Invoke-SafeProcess -FilePath $command.Source -Arguments @('--version')
    $text = "$($result.StdOut) $($result.StdErr)"
    $match = [regex]::Match($text, '\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?')
    [pscustomobject]@{
        Present = $true
        Version = if ($match.Success) { $match.Value } else { $null }
    }
}

function Get-BootstrapPreflight {
    [CmdletBinding()]
    param(
        [long]$RequiredBytes = 1GB,
        [Nullable[bool]]$PlatformIsWindows,
        [version]$PowerShellVersion = $PSVersionTable.PSVersion,
        [Nullable[long]]$FreeBytes,
        [scriptblock]$CommandResolver = { param($id) Get-DefaultCommandState -Id $id },
        [object]$Lock
    )

    $onWindows = if ($null -eq $PlatformIsWindows) { [bool]$IsWindows } else { [bool]$PlatformIsWindows }
    if (-not $onWindows) { throw 'PLATFORM_UNSUPPORTED: Windows is required.' }
    if ($PowerShellVersion.Major -lt 7) { throw 'POWERSHELL_UNSUPPORTED: PowerShell 7 or newer is required.' }
    if ($null -eq $FreeBytes) {
        $root = [IO.Path]::GetPathRoot($PSScriptRoot)
        $available = ([IO.DriveInfo]::new($root)).AvailableFreeSpace
    }
    else { $available = [long]$FreeBytes }
    if ($available -lt $RequiredBytes) { throw "DISK_SPACE_INSUFFICIENT: $RequiredBytes bytes required." }

    $ids = @('winget', 'git', 'node', 'pnpm', 'python', 'uv', 'opencode', 'engram', 'graphify')
    $components = @{}
    if ($null -ne $Lock) {
        foreach ($component in $Lock.components) { $components[[string]$component.id] = $component }
    }
    $checks = foreach ($id in $ids) {
        $state = & $CommandResolver $id
        $requiredVersion = if ($components.ContainsKey($id)) { [string]$components[$id].version } else { $null }
        $status = if (-not $state.Present) { 'Missing' } elseif ($null -ne $requiredVersion -and $state.Version -ne $requiredVersion) { 'VersionMismatch' } else { 'Compatible' }
        [pscustomobject]@{ Id = $id; Present = [bool]$state.Present; Version = $state.Version; RequiredVersion = $requiredVersion; Status = $status }
    }

    [pscustomobject]@{
        Platform = 'windows-powershell'
        RequiredBytes = $RequiredBytes
        FreeBytes = $available
        Checks = @($checks)
        Actions = @($checks | Where-Object Status -EQ 'Missing' | ForEach-Object { "install:$($_.Id)" })
    }
}

function Resolve-PrerequisitePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Lock,
        [scriptblock]$CommandResolver = { param($id) Get-DefaultCommandState -Id $id }
    )

    $prerequisiteIds = @('git', 'node', 'pnpm', 'python', 'uv')
    $componentMap = @{}
    foreach ($component in $Lock.components) { $componentMap[[string]$component.id] = $component }
    $items = [Collections.Generic.List[object]]::new()
    $mismatches = [Collections.Generic.List[object]]::new()
    $compatibleIds = [Collections.Generic.List[string]]::new()

    foreach ($id in $prerequisiteIds) {
        $component = $componentMap[$id]
        $state = & $CommandResolver $id
        if (-not $state.Present) {
            [void]$items.Add($component)
        }
        elseif ([string]$state.Version -eq [string]$component.version) {
            [void]$compatibleIds.Add($id)
        }
        else {
            [void]$mismatches.Add([pscustomobject]@{
                Id = $id
                Status = 'VersionMismatch'
                InstalledVersion = $state.Version
                RequiredVersion = $component.version
            })
        }
    }

    [pscustomobject]@{ Items = @($items); VersionMismatches = @($mismatches); CompatibleIds = @($compatibleIds) }
}

function Invoke-ConfirmedPrerequisiteInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Plan,
        [scriptblock]$Runner = { param($FilePath, $Arguments) Invoke-SafeProcess -FilePath $FilePath -Arguments $Arguments },
        [scriptblock]$ConfirmationReader = { Read-Host 'Type INSTALL to continue' },
        [switch]$NonInteractive,
        [switch]$ConfirmInstall
    )

    if (@($Plan.Items).Count -eq 0) { return [pscustomobject]@{ Status = 'COMPLETED'; Installed = @() } }
    if ($NonInteractive) {
        if (-not $ConfirmInstall) { throw 'INSTALL_CONFIRMATION_REQUIRED: NonInteractive requires ConfirmInstall.' }
    }
    elseif ((& $ConfirmationReader) -cne 'INSTALL') {
        return [pscustomobject]@{ Status = 'CANCELED'; Installed = @() }
    }

    $verified = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    if ($null -ne $Plan.PSObject.Properties['CompatibleIds']) {
        foreach ($id in @($Plan.CompatibleIds)) { [void]$verified.Add([string]$id) }
    }
    $installed = [Collections.Generic.List[string]]::new()
    foreach ($component in @($Plan.Items)) {
        $id = [string]$component.id
        if (-not $component.install.allowed) { throw "PREREQUISITE_INSTALL_FAILED:$id`: installation is not allowed." }
        if ($id -eq 'pnpm') {
            if (-not $verified.Contains('node')) { throw 'PREREQUISITE_INSTALL_FAILED:pnpm: Node is not verified.' }
            $filePath = 'corepack'
            $arguments = @('prepare', "pnpm@$($component.version)", '--activate')
        }
        elseif ($component.source.kind -eq 'winget') {
            $filePath = 'winget'
            $arguments = @('install', '--id', [string]$component.source.id, '--exact', '--version', [string]$component.version, '--accept-package-agreements', '--accept-source-agreements')
        }
        else {
            $filePath = [string]$component.install.command
            $arguments = @($component.install.arguments)
        }

        try { $result = & $Runner -FilePath $filePath -Arguments $arguments }
        catch { throw "PREREQUISITE_INSTALL_FAILED:$id`: $($_.Exception.Message)" }
        if ($null -eq $result -or $result.ExitCode -ne 0) { throw "PREREQUISITE_INSTALL_FAILED:$id`: process exited unsuccessfully." }
        [void]$verified.Add($id)
        [void]$installed.Add($id)
    }

    [pscustomobject]@{ Status = 'COMPLETED'; Installed = @($installed) }
}

Export-ModuleMember -Function Get-BootstrapPreflight, Resolve-PrerequisitePlan, Invoke-ConfirmedPrerequisiteInstall
