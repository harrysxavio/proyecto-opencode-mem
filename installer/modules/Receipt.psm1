Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ReceiptStates = @('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'ROLLED_BACK')
$script:ComponentStates = @('DETECTED', 'PLANNED', 'INSTALLED', 'CONFIGURED', 'VERIFIED')

function Assert-SafeBackupId {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$BackupId)
    if ($BackupId -cnotmatch '^\d{8}T\d{6}Z-[0-9a-f]{8}$') { throw "BACKUP_ID_INVALID:$BackupId" }
    $BackupId
}

function Test-PathWithinRoot {
    param([string]$Path, [string]$Root)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $fullPath.StartsWith($fullRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoReparsePoint {
    param([string]$Path, [string[]]$StopRoots)
    $candidate = [IO.Path]::GetFullPath($Path)
    while ($candidate) {
        if (Test-Path -LiteralPath $candidate) {
            $item = Get-Item -LiteralPath $candidate -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "ROLLBACK_PATH_OUTSIDE_OWNERSHIP:$Path"
            }
        }
        if (@($StopRoots | Where-Object { [IO.Path]::GetFullPath($_).Equals($candidate, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0) { break }
        $parent = [IO.Path]::GetDirectoryName($candidate)
        if (-not $parent -or $parent -eq $candidate) { break }
        $candidate = $parent
    }
}

function Assert-OwnedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string[]]$AllowedRoots,
        [switch]$AllowMissing
    )
    if ($AllowedRoots.Count -eq 0) { throw "ROLLBACK_PATH_OUTSIDE_OWNERSHIP:$Path" }
    $full = try { [IO.Path]::GetFullPath($Path) } catch { throw "ROLLBACK_PATH_OUTSIDE_OWNERSHIP:$Path" }
    $matchingRoots = @($AllowedRoots | Where-Object { Test-PathWithinRoot $full $_ })
    if ($matchingRoots.Count -eq 0) { throw "ROLLBACK_PATH_OUTSIDE_OWNERSHIP:$Path" }
    Assert-NoReparsePoint -Path $full -StopRoots $matchingRoots
    if ((Test-Path -LiteralPath $full) -and -not $AllowMissing) {
        $resolved = (Resolve-Path -LiteralPath $full).Path
        if (@($matchingRoots | Where-Object { Test-PathWithinRoot $resolved $_ }).Count -eq 0) {
            throw "ROLLBACK_PATH_OUTSIDE_OWNERSHIP:$Path"
        }
    }
    $full
}

function Test-SensitiveProperties {
    param([object]$Value)
    if ($null -eq $Value) { return $false }
    if ($Value -is [Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            if ([string]$key -match '(?i)(secret|password|credential|token|api[_-]?key)') { return $true }
            if (Test-SensitiveProperties $Value[$key]) { return $true }
        }
        return $false
    }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        foreach ($entry in $Value) { if (Test-SensitiveProperties $entry) { return $true } }
        return $false
    }
    foreach ($property in @($Value.PSObject.Properties)) {
        if ($property.Name -match '(?i)(secret|password|credential|token|api[_-]?key)') { return $true }
        if (Test-SensitiveProperties $property.Value) { return $true }
    }
    $false
}

function Assert-StringArray {
    param([object]$Value, [string]$Name)
    if ($Value -isnot [array]) { throw "RECEIPT_TYPE_INVALID:$Name" }
    foreach ($entry in $Value) { if ($entry -isnot [string] -or [string]::IsNullOrWhiteSpace($entry)) { throw "RECEIPT_TYPE_INVALID:$Name" } }
}

function Assert-InstallReceipt {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Receipt)
    $required = @('schemaVersion','kitVersion','createdAt','state','components','ownedPaths','ownedKeys','backups','provenance')
    foreach ($name in $required) { if ($null -eq $Receipt.PSObject.Properties[$name]) { throw "RECEIPT_SCHEMA_INVALID:$name" } }
    if (($Receipt.schemaVersion -isnot [int] -and $Receipt.schemaVersion -isnot [long]) -or $Receipt.schemaVersion -ne 1) { throw 'RECEIPT_SCHEMA_INVALID:schemaVersion' }
    if ($Receipt.kitVersion -isnot [string] -or [string]::IsNullOrWhiteSpace($Receipt.kitVersion)) { throw 'RECEIPT_TYPE_INVALID:kitVersion' }
    if ($Receipt.createdAt -isnot [string] -or $Receipt.createdAt -cnotmatch 'Z$') { throw 'RECEIPT_TYPE_INVALID:createdAt' }
    $parsed = [datetimeoffset]::MinValue
    if (-not [datetimeoffset]::TryParse($Receipt.createdAt, [ref]$parsed) -or $parsed.Offset -ne [timespan]::Zero) { throw 'RECEIPT_TYPE_INVALID:createdAt' }
    if ($Receipt.state -isnot [string] -or $script:ReceiptStates -cnotcontains $Receipt.state) { throw 'RECEIPT_STATE_INVALID' }
    if ($Receipt.components -isnot [array]) { throw 'RECEIPT_TYPE_INVALID:components' }
    foreach ($component in $Receipt.components) {
        if ($null -eq $component.PSObject.Properties['id'] -or $component.id -isnot [string] -or
            $null -eq $component.PSObject.Properties['state'] -or $script:ComponentStates -cnotcontains $component.state) { throw 'RECEIPT_COMPONENT_INVALID' }
    }
    Assert-StringArray $Receipt.ownedPaths 'ownedPaths'
    Assert-StringArray $Receipt.ownedKeys 'ownedKeys'
    if ($Receipt.backups -isnot [array]) { throw 'RECEIPT_TYPE_INVALID:backups' }
    foreach ($backup in $Receipt.backups) {
        foreach ($name in @('path','backupPath','existed','type')) { if ($null -eq $backup.PSObject.Properties[$name]) { throw "RECEIPT_BACKUP_INVALID:$name" } }
        if ($backup.path -isnot [string] -or $backup.existed -isnot [bool] -or $backup.type -notin @('file','directory','absent')) { throw 'RECEIPT_BACKUP_INVALID:type' }
        if ($backup.existed -and ($backup.backupPath -isnot [string] -or [string]::IsNullOrWhiteSpace($backup.backupPath))) { throw 'RECEIPT_BACKUP_INVALID:backupPath' }
        if (-not $backup.existed -and $null -ne $backup.backupPath) { throw 'RECEIPT_BACKUP_INVALID:backupPath' }
    }
    if ($null -eq $Receipt.provenance -or $Receipt.provenance.sourceCommit -isnot [string] -or $Receipt.provenance.lockDigest -isnot [string] -or $Receipt.provenance.lockDigest -cnotmatch '^[0-9a-f]{64}$') { throw 'RECEIPT_PROVENANCE_INVALID' }
    if (Test-SensitiveProperties $Receipt) { throw 'RECEIPT_SENSITIVE_DATA' }
    $Receipt
}

function New-InstallReceipt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$KitVersion,
        [Parameter(Mandatory)][string]$LockDigest,
        [Parameter(Mandatory)][string]$SourceCommit
    )
    if ($LockDigest -cnotmatch '^[0-9a-f]{64}$') { throw 'RECEIPT_LOCK_DIGEST_INVALID' }
    [pscustomobject][ordered]@{
        schemaVersion = 1
        kitVersion = $KitVersion
        createdAt = [datetime]::UtcNow.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
        state = 'PLANNED'
        components = @()
        ownedPaths = @()
        ownedKeys = @()
        backups = @()
        provenance = [pscustomobject][ordered]@{ sourceCommit = $SourceCommit; lockDigest = $LockDigest }
    }
}

function Save-InstallReceipt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][object]$Receipt,
        [Parameter(Mandatory,Position=1)][string]$Path,
        [Parameter(Mandatory,Position=2)][string]$ReceiptRoot
    )
    [void](Assert-InstallReceipt $Receipt)
    $fullPath = Assert-OwnedPath -Path $Path -AllowedRoots @($ReceiptRoot) -AllowMissing
    $parent = [IO.Path]::GetDirectoryName($fullPath)
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $temp = Join-Path $parent ('.' + [IO.Path]::GetFileName($fullPath) + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $json = $Receipt | ConvertTo-Json -Depth 30
        [IO.File]::WriteAllText($temp, $json, [Text.UTF8Encoding]::new($false))
        [IO.File]::Move($temp, $fullPath, $true)
    }
    finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}

function Read-InstallReceipt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ReceiptRoot,
        [Parameter(Mandatory)][string[]]$AllowedRoots,
        [string]$BackupRoot
    )
    $fullPath = Assert-OwnedPath -Path $Path -AllowedRoots @($ReceiptRoot)
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { throw 'RECEIPT_NOT_FOUND' }
    try { $receipt = [IO.File]::ReadAllText($fullPath, [Text.Encoding]::UTF8) | ConvertFrom-Json -Depth 30 -DateKind String } catch { throw "RECEIPT_JSON_INVALID:$($_.Exception.Message)" }
    [void](Assert-InstallReceipt $receipt)
    foreach ($ownedPath in $receipt.ownedPaths) { [void](Assert-OwnedPath -Path $ownedPath -AllowedRoots $AllowedRoots -AllowMissing) }
    foreach ($backup in $receipt.backups) {
        [void](Assert-OwnedPath -Path $backup.path -AllowedRoots $AllowedRoots -AllowMissing)
        if ($backup.existed) {
            if ([string]::IsNullOrWhiteSpace($BackupRoot)) { throw 'RECEIPT_BACKUP_ROOT_REQUIRED' }
            [void](Assert-OwnedPath -Path $backup.backupPath -AllowedRoots @($BackupRoot))
        }
    }
    $receipt
}

function Add-ReceiptOwnedPath {
    [CmdletBinding()]
    param([Parameter(Mandatory,Position=0)][object]$Receipt, [Parameter(Mandatory,Position=1)][string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    if (@($Receipt.ownedPaths | Where-Object { $_.Equals($full, [StringComparison]::OrdinalIgnoreCase) }).Count -eq 0) { $Receipt.ownedPaths = @($Receipt.ownedPaths) + $full }
}

function Add-ReceiptOwnedKey {
    [CmdletBinding()]
    param([Parameter(Mandatory,Position=0)][object]$Receipt, [Parameter(Mandatory,Position=1)][string]$Key)
    if ($Receipt.ownedKeys -cnotcontains $Key) { $Receipt.ownedKeys = @($Receipt.ownedKeys) + $Key }
}

function Backup-InstallPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][object]$Receipt,
        [Parameter(Mandatory,Position=1)][string]$Path,
        [Parameter(Mandatory,Position=2)][string]$BackupRoot,
        [Parameter(Mandatory,Position=3)][string]$BackupId,
        [Parameter(Mandatory,Position=4)][string[]]$AllowedRoots
    )
    [void](Assert-SafeBackupId $BackupId)
    $full = Assert-OwnedPath -Path $Path -AllowedRoots $AllowedRoots -AllowMissing
    $existing = @($Receipt.backups | Where-Object { $_.path.Equals($full, [StringComparison]::OrdinalIgnoreCase) })
    if ($existing.Count -gt 0) { return $existing[0] }
    $exists = Test-Path -LiteralPath $full
    $type = if (-not $exists) { 'absent' } elseif (Test-Path -LiteralPath $full -PathType Container) { 'directory' } else { 'file' }
    $backupPath = $null
    if ($exists) {
        if ($type -eq 'directory') {
            $reparse = @(Get-ChildItem -LiteralPath $full -Force -Recurse | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 })
            if ($reparse.Count -gt 0) { throw "ROLLBACK_PATH_OUTSIDE_OWNERSHIP:$($reparse[0].FullName)" }
        }
        $fullBackupRoot = [IO.Path]::GetFullPath($BackupRoot)
        Assert-NoReparsePoint -Path $fullBackupRoot -StopRoots @()
        if ((Test-Path -LiteralPath $fullBackupRoot) -and -not (Test-Path -LiteralPath $fullBackupRoot -PathType Container)) {
            throw "ROLLBACK_PATH_OUTSIDE_OWNERSHIP:$BackupRoot"
        }
        $container = Join-Path $fullBackupRoot $BackupId
        $backupPath = Join-Path $container ('item-' + @($Receipt.backups).Count.ToString('D8'))
        [void](Assert-OwnedPath -Path $container -AllowedRoots @($fullBackupRoot) -AllowMissing)
        [void](Assert-OwnedPath -Path $backupPath -AllowedRoots @($BackupRoot) -AllowMissing)
        New-Item -ItemType Directory -Path $container -Force | Out-Null
        Copy-Item -LiteralPath $full -Destination $backupPath -Recurse -Force
    }
    $record = [pscustomobject][ordered]@{ path = $full; backupPath = $backupPath; existed = [bool]$exists; type = $type }
    $Receipt.backups = @($Receipt.backups) + $record
    if (-not $exists) { Add-ReceiptOwnedPath -Receipt $Receipt -Path $full }
    $record
}

function Get-ReceiptResumeComponent {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Receipt)
    @($Receipt.components | Where-Object state -CNE 'VERIFIED' | Select-Object -First 1)[0]
}

function Set-ReceiptComponentState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][object]$Receipt,
        [Parameter(Mandatory,Position=1)][string]$Id,
        [Parameter(Mandatory,Position=2)][string]$State
    )
    if ([string]::IsNullOrWhiteSpace($Id) -or $script:ComponentStates -cnotcontains $State) { throw 'RECEIPT_COMPONENT_INVALID' }
    $matches = @($Receipt.components | Where-Object { $_.id -ceq $Id })
    if ($matches.Count -gt 0) { $matches[0].state = $State }
    else { $Receipt.components = @($Receipt.components) + [pscustomobject][ordered]@{ id = $Id; state = $State } }
}

Export-ModuleMember -Function Assert-SafeBackupId, Assert-OwnedPath, Assert-InstallReceipt, New-InstallReceipt, Save-InstallReceipt, Read-InstallReceipt, Add-ReceiptOwnedPath, Add-ReceiptOwnedKey, Backup-InstallPath, Get-ReceiptResumeComponent, Set-ReceiptComponentState
