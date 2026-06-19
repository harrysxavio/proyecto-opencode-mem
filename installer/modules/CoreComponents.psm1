Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'ProcessRunner.psm1') -Force

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
            Target = if ($_.id -ceq 'engram') { Join-Path ([IO.Path]::GetFullPath($KitRoot)) 'bin/engram.exe' } else { "command:$($_.id)" }
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
        $resolve = if ($PSBoundParameters.ContainsKey('CommandResolver')) { $CommandResolver } else {
            { param($name) $command=Get-Command -Name $name -CommandType Application,ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1; if($null -ne $command){$command.Source} }
        }
        $existingPath = & $resolve $id
        $previousVersion = $null
        if (-not [string]::IsNullOrWhiteSpace([string]$existingPath)) {
            $previousVersion = Get-ProcessVersion -FilePath ([string]$existingPath) -Arguments @('--version') -ProcessInvoker $invoke
            if ($previousVersion -ceq [string]$Component.version) {
                return [pscustomobject][ordered]@{ Id=$id; Version=$previousVersion; Status='REUSED'; Target=[string]$existingPath }
            }
        }
        try { $result = & $invoke ([string]$Component.install.command) ([string[]]@($Component.install.arguments)) }
        catch { throw "CORE_INSTALL_FAILED:$id`: $($_.Exception.Message)" }
        if ($null -eq $result -or $result.ExitCode -ne 0) { throw "CORE_INSTALL_FAILED:$id`: process failed" }
        return [pscustomobject][ordered]@{ Id=$id; Version=[string]$Component.version; Status='INSTALLED'; Target="command:$id"; PreviousVersion=$previousVersion }
    }

    $root = [IO.Path]::GetFullPath($KitRoot)
    $bin = Join-Path $root 'bin'; $target = Join-Path $bin 'engram.exe'
    if (Test-Path -LiteralPath $target) {
        $existing = Get-ProcessVersion -FilePath $target -Arguments @('version') -ProcessInvoker $invoke
        if ($existing -ceq [string]$Component.version) { return [pscustomobject][ordered]@{ Id=$id; Version=$existing; Status='REUSED'; Target=$target } }
        throw "CORE_INSTALL_FAILED:engram: existing version mismatch ($existing)"
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
        if ($candidateVersion -cne [string]$Component.version) { throw "candidate version mismatch ($candidateVersion)" }
        New-Item -ItemType Directory -Path $bin -Force | Out-Null
        if (Test-Path -LiteralPath $target) { throw 'exclusive target already exists' }
        [IO.File]::Move($candidate, $target, $false)
        return [pscustomobject][ordered]@{ Id=$id; Version=$candidateVersion; Status='INSTALLED'; Target=$target; Sha256=$actualHash }
    }
    catch {
        if ($_.Exception.Message -like 'CHECKSUM_MISMATCH:*') { throw $_.Exception }
        throw "CORE_INSTALL_FAILED:engram: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Export-ModuleMember -Function Get-CoreComponentPreview, Install-CoreComponent
