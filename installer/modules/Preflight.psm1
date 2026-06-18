Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runnerModule = Join-Path $PSScriptRoot 'ProcessRunner.psm1'
Import-Module $runnerModule -Force

function ConvertFrom-VersionProbeResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][object]$Result
    )

    if ($Result.ExitCode -ne 0) {
        return [pscustomobject]@{ Present = $true; Usable = $false; Version = $null; Id = $Id }
    }
    $text = "$($Result.StdOut) $($Result.StdErr)"
    if ($Id -eq 'git') {
        $gitForWindows = [regex]::Match($text, '(?i)git version (\d+\.\d+\.\d+)\.windows\.\d+(?![0-9A-Za-z.+-])')
        if ($gitForWindows.Success) {
            return [pscustomobject]@{ Present = $true; Usable = $true; Version = $gitForWindows.Groups[1].Value; Id = $Id }
        }
    }
    $match = [regex]::Match($text, '(?<!\d)(\d+\.\d+\.\d+(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?)(?![0-9A-Za-z.+-])')
    if (-not $match.Success) {
        return [pscustomobject]@{ Present = $true; Usable = $false; Version = $null; Id = $Id }
    }
    [pscustomobject]@{ Present = $true; Usable = $true; Version = $match.Groups[1].Value; Id = $Id }
}

function Test-CommandStateUsable {
    param([object]$State)
    if (-not $State.Present) { return $false }
    $usableProperty = $State.PSObject.Properties['Usable']
    return $null -eq $usableProperty -or [bool]$usableProperty.Value
}

function Get-DefaultCommandState {
    param([Parameter(Mandatory)][string]$Id)

    $commandName = if ($Id -eq 'python') { 'python' } else { $Id }
    $command = Get-Command -Name $commandName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{ Present = $false; Usable = $false; Version = $null }
    }
    if ($Id -eq 'winget') {
        return [pscustomobject]@{ Present = $true; Usable = $true; Version = $null }
    }

    $result = Invoke-SafeProcess -FilePath $command.Source -Arguments @('--version')
    ConvertFrom-VersionProbeResult -Id $Id -Result $result
}

function Update-BootstrapProcessPath {
    $segments = [Collections.Generic.List[string]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($scope in @('Machine', 'User')) {
        $value = [Environment]::GetEnvironmentVariable('Path', $scope)
        foreach ($segment in @($value -split ';')) {
            if (-not [string]::IsNullOrWhiteSpace($segment) -and $seen.Add($segment)) { [void]$segments.Add($segment) }
        }
    }
    foreach ($segment in @($env:Path -split ';')) {
        if (-not [string]::IsNullOrWhiteSpace($segment) -and $seen.Add($segment)) { [void]$segments.Add($segment) }
    }
    $env:Path = $segments -join ';'
}

function Resolve-BootstrapExecutable {
    param([Parameter(Mandatory)][string]$Name)
    $command = Get-Command -Name $Name -CommandType Application, ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command) { return $command.Source }
    if ($Name -eq 'corepack') {
        foreach ($candidate in @(
            (Join-Path $env:ProgramFiles 'nodejs\corepack.cmd'),
            (if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} 'nodejs\corepack.cmd' })
        )) {
            if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $candidate }
        }
    }
    return $null
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
        $usable = Test-CommandStateUsable -State $state
        $status = if (-not $state.Present) { 'Missing' } elseif (-not $usable) { 'Unusable' } elseif ($null -ne $requiredVersion -and $state.Version -ne $requiredVersion) { 'VersionMismatch' } else { 'Compatible' }
        [pscustomobject]@{ Id = $id; Present = [bool]$state.Present; Usable = $usable; Version = $state.Version; RequiredVersion = $requiredVersion; Status = $status }
    }

    [pscustomobject]@{
        Platform = 'windows-powershell'
        RequiredBytes = $RequiredBytes
        FreeBytes = $available
        Checks = @($checks)
        Actions = @($checks | Where-Object { $_.Status -in @('Missing', 'Unusable') } | ForEach-Object { "install:$($_.Id)" })
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
        if (-not (Test-CommandStateUsable -State $state)) {
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
        [scriptblock]$ExecutableResolver = { param($name) Resolve-BootstrapExecutable -Name $name },
        [scriptblock]$PathRefresher = { Update-BootstrapProcessPath },
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
    $needsPnpm = @($Plan.Items | Where-Object id -EQ 'pnpm').Count -gt 0
    $corepackPath = if ($needsPnpm) { & $ExecutableResolver 'corepack' } else { $null }
    $nodeInstalled = $false
    foreach ($component in @($Plan.Items)) {
        $id = [string]$component.id
        if (-not $component.install.allowed) { throw "PREREQUISITE_INSTALL_FAILED:$id`: installation is not allowed." }
        if ($id -eq 'pnpm') {
            if (-not $verified.Contains('node')) { throw 'PREREQUISITE_INSTALL_FAILED:pnpm: Node is not verified.' }
            if (-not $corepackPath -and $nodeInstalled) {
                & $PathRefresher
                $corepackPath = & $ExecutableResolver 'corepack'
            }
            if (-not $corepackPath) { throw 'PREREQUISITE_RESTART_REQUIRED:node: corepack is unavailable in the current process; resume after restarting PowerShell.' }
            $filePath = $corepackPath
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
        if ($id -eq 'node') { $nodeInstalled = $true }
    }

    [pscustomobject]@{ Status = 'COMPLETED'; Installed = @($installed) }
}

Export-ModuleMember -Function ConvertFrom-VersionProbeResult, Get-BootstrapPreflight, Resolve-PrerequisitePlan, Invoke-ConfirmedPrerequisiteInstall
