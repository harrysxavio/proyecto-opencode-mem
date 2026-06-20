Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'ProcessRunner.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'CommandResolution.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'ConfigComposer.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Receipt.psm1') -Force

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

function Add-CoreDirectoryLocks {
    param([Collections.Generic.List[object]]$Destination,[object[]]$Source)
    foreach ($entry in @($Source)) { $Destination.Add($entry) }
}

function Enter-CoreOwnedDirectory {
    param([string]$Path,[string]$OwnershipRoot,[Collections.Generic.List[object]]$Locks)
    $full=[IO.Path]::GetFullPath($Path)
    # Reject lexical escapes before finding an anchor or creating any directory.
    [void](Assert-OwnedPath -Path $full -AllowedRoots @($OwnershipRoot) -AllowMissing)
    if (Test-Path -LiteralPath $full) {
        [void](Assert-ConfigPath -Path $full -Root $OwnershipRoot)
        if (-not (Test-Path -LiteralPath $full -PathType Container)) { throw "CONFIG_PATH_OUTSIDE_ROOT:$full" }
        Add-CoreDirectoryLocks $Locks (Enter-ConfigDirectoryLocks -Root $full -Parent $full -OpenReparsePoint)
    }
    else {
        $anchor=Get-NearestExistingConfigDirectory $full
        Add-CoreDirectoryLocks $Locks (New-SafeConfigDirectoryPath -Anchor $anchor -Target $full)
        [void](Assert-ConfigPath -Path $full -Root $OwnershipRoot)
    }
    $full
}

function Assert-CoreOwnedFilePath {
    param([string]$Path,[string]$OwnershipRoot,[switch]$AllowMissing)
    [void](Assert-OwnedPath -Path $Path -AllowedRoots @($OwnershipRoot) -AllowMissing:$AllowMissing)
    [void](Assert-ConfigPath -Path $Path -Root $OwnershipRoot)
    [IO.Path]::GetFullPath($Path)
}

function Restore-CoreInstallBackup {
    param([object]$Backup,[string]$Target,[string]$OwnershipRoot)
    $targetPath=Assert-CoreOwnedFilePath -Path $Target -OwnershipRoot $OwnershipRoot -AllowMissing
    if ($Backup.existed) {
        $backupPath=Assert-CoreOwnedFilePath -Path $Backup.backupPath -OwnershipRoot $OwnershipRoot
        $targetDirectory=[IO.Path]::GetDirectoryName($targetPath)
        [void](Assert-CoreOwnedFilePath -Path $targetDirectory -OwnershipRoot $OwnershipRoot)
        $nonce=[guid]::NewGuid().ToString('N')
        $restorePath=Assert-CoreOwnedFilePath -Path (Join-Path $targetDirectory ".engram.exe.restore-$nonce") -OwnershipRoot $OwnershipRoot -AllowMissing
        $replacedPath=Assert-CoreOwnedFilePath -Path (Join-Path $targetDirectory ".engram.exe.replaced-$nonce") -OwnershipRoot $OwnershipRoot -AllowMissing
        try {
            $source=[IO.FileStream]::new($backupPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
            try {
                $destination=[IO.FileStream]::new($restorePath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None,65536,[IO.FileOptions]::WriteThrough)
                try { $source.CopyTo($destination);$destination.Flush($true) }
                finally { $destination.Dispose() }
            }
            finally { $source.Dispose() }
            $backupHash=Get-FileSha256Core $backupPath
            if ((Get-FileSha256Core $restorePath) -cne $backupHash) { throw 'CORE_RESTORE_HASH_MISMATCH:engram' }
            if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
                [IO.File]::Replace($restorePath,$targetPath,$replacedPath,$true)
            }
            else { [IO.File]::Move($restorePath,$targetPath,$false) }
            [void](Assert-CoreOwnedFilePath -Path $targetPath -OwnershipRoot $OwnershipRoot)
            [void](Get-ConfigFileIdentity $targetPath)
            if ((Get-FileSha256Core $targetPath) -cne $backupHash) { throw 'CORE_RESTORE_HASH_MISMATCH:engram' }
        }
        finally {
            foreach($cleanupPath in @($restorePath,$replacedPath)) {
                [void](Assert-CoreOwnedFilePath -Path $cleanupPath -OwnershipRoot $OwnershipRoot -AllowMissing)
                if (Test-Path -LiteralPath $cleanupPath -PathType Leaf) { Remove-Item -LiteralPath $cleanupPath -Force }
            }
        }
    }
    elseif (Test-Path -LiteralPath $targetPath) { Remove-Item -LiteralPath $targetPath -Force }
}

function Install-CoreComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Component,
        [Parameter(Mandatory)][string]$KitRoot,
        [scriptblock]$ProcessInvoker,
        [scriptblock]$Downloader,
        [scriptblock]$CommandResolver,
        [object]$Receipt,
        [string]$ReceiptPath,
        [string]$ReceiptRoot,
        [string]$BackupRoot,
        [string]$BackupId
    )
    $id = [string]$Component.id
    if (@('opencode','engram','graphify') -cnotcontains $id) { throw "CORE_INSTALL_FAILED:$id`: unsupported core component" }
    $invoke = if ($PSBoundParameters.ContainsKey('ProcessInvoker')) { $ProcessInvoker } else { { param($FilePath,$Arguments) Invoke-SafeProcess -FilePath $FilePath -Arguments $Arguments } }
    if ($id -cne 'engram') {
        $safeArgs = @{}
        if ($PSBoundParameters.ContainsKey('CommandResolver')) { $safeArgs.CommandResolver=$CommandResolver }
        $installPath = Resolve-SafeWindowsCommand -Name ([string]$Component.install.command) @safeArgs
        if ([string]::IsNullOrWhiteSpace($installPath)) { throw "CORE_COMMAND_UNRESOLVED:$([string]$Component.install.command)" }
        $uvPath = if ($id -ceq 'graphify') { $installPath } else { $null }
        $existingPath = if ($id -ceq 'opencode') {
            Resolve-SafeWindowsCommand -Name 'opencode' @safeArgs
        }
        else {
            $toolArgs = @{ ToolName='graphify'; UvPath=$uvPath; ProcessInvoker=$invoke }
            if ($PSBoundParameters.ContainsKey('CommandResolver')) { $toolArgs.CommandResolver=$CommandResolver }
            Resolve-UvToolExecutable @toolArgs
        }
        if ($id -ceq 'graphify' -and [string]::IsNullOrWhiteSpace($uvPath)) { throw 'CORE_COMMAND_UNRESOLVED:uv' }
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
        if ([string]::IsNullOrWhiteSpace([string]$installedPath)) { throw "CORE_COMMAND_UNRESOLVED:$id" }
        $installedVersion = Get-ProcessVersion -FilePath ([string]$installedPath) -Arguments @('--version') -ProcessInvoker $invoke
        Assert-CoreVersion -Id $id -ExpectedVersion ([string]$Component.version) -ActualVersion $installedVersion
        $action = if ($hadExisting) { 'UPDATE_TO_PINNED' } else { 'INSTALL_PINNED' }
        return [pscustomobject][ordered]@{ Id=$id; Version=$installedVersion; Status='INSTALLED'; Action=$action; Target=[string]$installedPath; PreviousVersion=$previousVersion }
    }

    $root = [IO.Path]::GetFullPath($KitRoot)
    $locks=[Collections.Generic.List[object]]::new()
    $published=$false; $backupRecord=$null; $stageRoot=$null
    try {
        $root = Enter-CoreOwnedDirectory -Path $root -OwnershipRoot $root -Locks $locks
        $bin = Enter-CoreOwnedDirectory -Path (Join-Path $root 'bin') -OwnershipRoot $root -Locks $locks
        $target = Assert-CoreOwnedFilePath -Path (Join-Path $bin 'engram.exe') -OwnershipRoot $root -AllowMissing
        $previousVersion = $null
        if (Test-Path -LiteralPath $target) {
            $previousVersion = Get-ProcessVersion -FilePath $target -Arguments @('version') -ProcessInvoker $invoke
            if ($previousVersion -ceq [string]$Component.version) { return [pscustomobject][ordered]@{ Id=$id; Version=$previousVersion; Status='REUSED'; Action='REUSE_PINNED'; Target=$target } }
        }
        $stageParent=Enter-CoreOwnedDirectory -Path (Join-Path $root '.staging') -OwnershipRoot $root -Locks $locks
        $stageRoot = Enter-CoreOwnedDirectory -Path (Join-Path $stageParent ('engram-' + [guid]::NewGuid().ToString('N'))) -OwnershipRoot $root -Locks $locks
        $archive = Join-Path $stageRoot 'engram.zip'; $extract = Join-Path $stageRoot 'extract'
        $download = if ($PSBoundParameters.ContainsKey('Downloader')) { $Downloader } else { { param($Uri,$Destination) Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing } }
        Assert-ConfigDirectoryLocksCurrent $locks
        & $download ([string]$Component.source.url) $archive
        [void](Assert-CoreOwnedFilePath -Path $archive -OwnershipRoot $root)
        if (-not (Test-Path -LiteralPath $archive -PathType Leaf)) { throw 'download did not create archive' }
        $actualHash = Get-FileSha256Core $archive
        if ($actualHash -cne [string]$Component.source.sha256) { throw "CHECKSUM_MISMATCH:engram:$actualHash" }
        Expand-Archive -LiteralPath $archive -DestinationPath $extract
        $extract=Enter-CoreOwnedDirectory -Path $extract -OwnershipRoot $root -Locks $locks
        $candidate = Assert-CoreOwnedFilePath -Path (Join-Path $extract 'engram.exe') -OwnershipRoot $root
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { throw 'archive missing engram.exe' }
        $candidateBytes=[IO.File]::ReadAllBytes($candidate);$candidateIdentity=Get-ConfigFileIdentity $candidate
        $candidateVersion = Get-ProcessVersion -FilePath $candidate -Arguments @('version') -ProcessInvoker $invoke
        Assert-CoreVersion -Id $id -ExpectedVersion ([string]$Component.version) -ActualVersion $candidateVersion
        $receiptValue = if ($PSBoundParameters.ContainsKey('Receipt')) { [void](Assert-InstallReceipt $Receipt); $Receipt } else {
            New-InstallReceipt -KitVersion ("engram-"+[string]$Component.version) -LockDigest ([string]$Component.source.sha256) -SourceCommit 'core-direct'
        }
        $receiptRootValue = if ([string]::IsNullOrWhiteSpace($ReceiptRoot)) { Join-Path $root 'state' } else { [IO.Path]::GetFullPath($ReceiptRoot) }
        $receiptRootValue=Enter-CoreOwnedDirectory -Path $receiptRootValue -OwnershipRoot $root -Locks $locks
        $receiptPathValue = if ([string]::IsNullOrWhiteSpace($ReceiptPath)) { Join-Path $receiptRootValue 'install-receipt.json' } else { $ReceiptPath }
        $receiptPathValue=Assert-CoreOwnedFilePath -Path $receiptPathValue -OwnershipRoot $root -AllowMissing
        $backupRootValue = if ([string]::IsNullOrWhiteSpace($BackupRoot)) { Join-Path $root 'backups' } else { [IO.Path]::GetFullPath($BackupRoot) }
        $backupRootValue=Enter-CoreOwnedDirectory -Path $backupRootValue -OwnershipRoot $root -Locks $locks
        $backupIdValue = if ([string]::IsNullOrWhiteSpace($BackupId)) { [datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8) } else { $BackupId }
        [void](Assert-SafeBackupId $backupIdValue)
        [void](Enter-CoreOwnedDirectory -Path (Join-Path $backupRootValue $backupIdValue) -OwnershipRoot $root -Locks $locks)
        Assert-ConfigDirectoryLocksCurrent $locks
        $targetBytes=if(Test-Path -LiteralPath $target -PathType Leaf){[IO.File]::ReadAllBytes($target)}else{$null}
        $targetIdentity=if($null -ne $targetBytes){Get-ConfigFileIdentity $target}else{$null}
        $backupRecord=Backup-InstallPath -Receipt $receiptValue -Path $target -BackupRoot $backupRootValue -BackupId $backupIdValue -AllowedRoots @($root)
        if ($backupRecord.existed) { [void](Assert-CoreOwnedFilePath -Path $backupRecord.backupPath -OwnershipRoot $root) }
        Assert-ConfigFileUnchanged -Path $target -OriginalBytes $targetBytes -OriginalIdentity $targetIdentity
        Save-InstallReceipt -Receipt $receiptValue -Path $receiptPathValue -ReceiptRoot $receiptRootValue
        [void](Assert-CoreOwnedFilePath -Path $receiptPathValue -OwnershipRoot $root)
        Assert-ConfigDirectoryLocksCurrent $locks
        Assert-ConfigFileUnchanged -Path $candidate -OriginalBytes $candidateBytes -OriginalIdentity $candidateIdentity
        [IO.File]::Move($candidate, $target, $true)
        $published=$true
        [void](Assert-CoreOwnedFilePath -Path $target -OwnershipRoot $root)
        $publishedIdentity=Get-ConfigFileIdentity $target
        $installedVersion = Get-ProcessVersion -FilePath $target -Arguments @('version') -ProcessInvoker $invoke
        Assert-CoreVersion -Id $id -ExpectedVersion ([string]$Component.version) -ActualVersion $installedVersion
        [void](Assert-CoreOwnedFilePath -Path $target -OwnershipRoot $root)
        if ((Get-ConfigFileIdentity $target) -cne $publishedIdentity) { throw 'CONFIG_CONCURRENT_MODIFICATION:engram target identity' }
        $action = if ($null -ne $previousVersion) { 'UPDATE_TO_PINNED' } else { 'INSTALL_PINNED' }
        return [pscustomobject][ordered]@{ Id=$id; Version=$installedVersion; Status='INSTALLED'; Action=$action; Target=$target; PreviousVersion=$previousVersion; Sha256=$actualHash }
    }
    catch {
        $failure=$_.Exception
        if ($published -and $null -ne $backupRecord) {
            try { Restore-CoreInstallBackup -Backup $backupRecord -Target $target -OwnershipRoot $root }
            catch { throw "CORE_ROLLBACK_FAILED:engram:$($failure.Message):$($_.Exception.Message)" }
        }
        if ($failure.Message -like 'CHECKSUM_MISMATCH:*' -or $failure.Message -like 'COMPONENT_VERSION_MISMATCH:*') { throw $failure }
        throw "CORE_INSTALL_FAILED:engram: $($failure.Message)"
    }
    finally {
        if ($null -ne $stageRoot -and (Test-Path -LiteralPath $stageRoot)) { Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue }
        foreach($entry in $locks){$entry.Handle.Dispose()}
    }
}

Export-ModuleMember -Function Get-CoreComponentPreview, Install-CoreComponent
