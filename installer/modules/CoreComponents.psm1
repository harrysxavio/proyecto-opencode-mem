Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'ProcessRunner.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'CommandResolution.psm1') -Force

function Get-CoreComponentPreview {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Components,[Parameter(Mandatory)][string]$KitRoot)
    @($Components | ForEach-Object {
        [pscustomobject][ordered]@{
            Id = [string]$_.id
            Version = [string]$_.version
            Command = [string]$_.install.command
            Arguments = [string[]]@($_.install.arguments)
            Download = if ($_.id -ceq 'engram') { [string]$_.source.url } else { $null }
            Target = if ($_.id -ceq 'engram') { Join-Path ([IO.Path]::GetFullPath($KitRoot)) 'bin/engram.exe' }
                elseif ($_.id -ceq 'graphify') { 'uv-tool-bin:graphify.exe' }
                else { "command:$($_.id)" }
        }
    })
}

function Get-ProcessVersion {
    param([string]$FilePath,[string[]]$Arguments,[scriptblock]$ProcessInvoker)
    $result = & $ProcessInvoker $FilePath ([string[]]$Arguments)
    if ($null -eq $result -or $result.ExitCode -ne 0 -or $result.StdOut -isnot [string] -or $result.StdErr -isnot [string]) { return $null }
    $match = [regex]::Match(($result.StdOut + "`n" + $result.StdErr), '(?<![0-9A-Za-z])v?(?<v>\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)')
    if ($match.Success) { return $match.Groups['v'].Value }
    $null
}

function Get-FileSha256Core {
    param([Parameter(Mandatory)][string]$Path)
    $stream = [IO.File]::OpenRead($Path); $sha = [Security.Cryptography.SHA256]::Create()
    try { [Convert]::ToHexString($sha.ComputeHash($stream)).ToLowerInvariant() }
    finally { $sha.Dispose(); $stream.Dispose() }
}

function Assert-CoreVersion {
    param([string]$Id,[string]$ExpectedVersion,[AllowNull()][string]$ActualVersion)
    if ($ActualVersion -cne $ExpectedVersion) {
        $reported = if ([string]::IsNullOrWhiteSpace($ActualVersion)) { 'unknown' } else { $ActualVersion }
        throw "COMPONENT_VERSION_MISMATCH:$Id`:expected:$ExpectedVersion`:actual:$reported"
    }
}

function Install-CoreComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Component,
        [Parameter(Mandatory)][string]$KitRoot,
        [scriptblock]$ProcessInvoker,
        [scriptblock]$Downloader,
        [scriptblock]$CommandResolver
    )
    $id = [string]$Component.id
    if (@('opencode','engram','graphify') -cnotcontains $id) { throw "CORE_INSTALL_FAILED:$id`: unsupported core component" }
    $invoke = if ($PSBoundParameters.ContainsKey('ProcessInvoker')) { $ProcessInvoker } else { { param($FilePath,$Arguments) Invoke-SafeProcess -FilePath $FilePath -Arguments $Arguments } }
    if ($id -cne 'engram') {
        $safeArgs = @{}
        if ($PSBoundParameters.ContainsKey('CommandResolver')) { $safeArgs.CommandResolver=$CommandResolver }
        $installPath = Resolve-SafeWindowsCommand -Name ([string]$Component.install.command) @safeArgs
        if ([string]::IsNullOrWhiteSpace($installPath)) { $installPath = [string]$Component.install.command }
        $uvPath = if ($id -ceq 'graphify') { $installPath } else { $null }
        $existingPath = if ($id -ceq 'opencode') {
            Resolve-SafeWindowsCommand -Name 'opencode' @safeArgs
        }
        else {
            $toolArgs = @{ ToolName='graphify'; UvPath=$uvPath; ProcessInvoker=$invoke }
            if ($PSBoundParameters.ContainsKey('CommandResolver')) { $toolArgs.CommandResolver=$CommandResolver }
            Resolve-UvToolExecutable @toolArgs
        }
        $hadExisting = -not [string]::IsNullOrWhiteSpace([string]$existingPath)
        $previousVersion = $null
        if ($hadExisting) {
            $previousVersion = Get-ProcessVersion -FilePath ([string]$existingPath) -Arguments @('--version') -ProcessInvoker $invoke
            if ($previousVersion -ceq [string]$Component.version) {
                return [pscustomobject][ordered]@{ Id=$id; Version=$previousVersion; Status='REUSED'; Action='REUSE_PINNED'; Target=[string]$existingPath }
            }
        }
        try { $result = & $invoke $installPath ([string[]]@($Component.install.arguments)) }
        catch { throw "CORE_INSTALL_FAILED:$id`: $($_.Exception.Message)" }
        if ($null -eq $result -or $result.ExitCode -ne 0) { throw "CORE_INSTALL_FAILED:$id`: process failed" }
        $installedPath = if ($id -ceq 'opencode') {
            Resolve-SafeWindowsCommand -Name 'opencode' @safeArgs
        }
        else {
            $toolArgs = @{ ToolName='graphify'; UvPath=$uvPath; ProcessInvoker=$invoke }
            if ($PSBoundParameters.ContainsKey('CommandResolver')) { $toolArgs.CommandResolver=$CommandResolver }
            Resolve-UvToolExecutable @toolArgs
        }
        $installedVersion = Get-ProcessVersion -FilePath ([string]$installedPath) -Arguments @('--version') -ProcessInvoker $invoke
        Assert-CoreVersion -Id $id -ExpectedVersion ([string]$Component.version) -ActualVersion $installedVersion
        $action = if ($hadExisting) { 'UPDATE_TO_PINNED' } else { 'INSTALL_PINNED' }
        return [pscustomobject][ordered]@{ Id=$id; Version=$installedVersion; Status='INSTALLED'; Action=$action; Target=[string]$installedPath; PreviousVersion=$previousVersion }
    }

    $root = [IO.Path]::GetFullPath($KitRoot)
    $bin = Join-Path $root 'bin'; $target = Join-Path $bin 'engram.exe'
    $previousVersion = $null
    if (Test-Path -LiteralPath $target) {
        $previousVersion = Get-ProcessVersion -FilePath $target -Arguments @('version') -ProcessInvoker $invoke
        if ($previousVersion -ceq [string]$Component.version) { return [pscustomobject][ordered]@{ Id=$id; Version=$previousVersion; Status='REUSED'; Action='REUSE_PINNED'; Target=$target } }
    }
    $stageRoot = Join-Path $root ('.staging/engram-' + [guid]::NewGuid().ToString('N'))
    $archive = Join-Path $stageRoot 'engram.zip'; $extract = Join-Path $stageRoot 'extract'
    $download = if ($PSBoundParameters.ContainsKey('Downloader')) { $Downloader } else { { param($Uri,$Destination) Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing } }
    try {
        New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
        & $download ([string]$Component.source.url) $archive
        if (-not (Test-Path -LiteralPath $archive -PathType Leaf)) { throw 'download did not create archive' }
        $actualHash = Get-FileSha256Core $archive
        if ($actualHash -cne [string]$Component.source.sha256) { throw "CHECKSUM_MISMATCH:engram:$actualHash" }
        Expand-Archive -LiteralPath $archive -DestinationPath $extract
        $candidate = Join-Path $extract 'engram.exe'
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { throw 'archive missing engram.exe' }
        $candidateVersion = Get-ProcessVersion -FilePath $candidate -Arguments @('version') -ProcessInvoker $invoke
        Assert-CoreVersion -Id $id -ExpectedVersion ([string]$Component.version) -ActualVersion $candidateVersion
        New-Item -ItemType Directory -Path $bin -Force | Out-Null
        [IO.File]::Move($candidate, $target, $true)
        $installedVersion = Get-ProcessVersion -FilePath $target -Arguments @('version') -ProcessInvoker $invoke
        Assert-CoreVersion -Id $id -ExpectedVersion ([string]$Component.version) -ActualVersion $installedVersion
        $action = if ($null -ne $previousVersion) { 'UPDATE_TO_PINNED' } else { 'INSTALL_PINNED' }
        return [pscustomobject][ordered]@{ Id=$id; Version=$installedVersion; Status='INSTALLED'; Action=$action; Target=$target; PreviousVersion=$previousVersion; Sha256=$actualHash }
    }
    catch {
        if ($_.Exception.Message -like 'CHECKSUM_MISMATCH:*' -or $_.Exception.Message -like 'COMPONENT_VERSION_MISMATCH:*') { throw $_.Exception }
        throw "CORE_INSTALL_FAILED:engram: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Export-ModuleMember -Function Get-CoreComponentPreview, Install-CoreComponent
