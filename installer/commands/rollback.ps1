[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ReceiptPath,
    [Parameter(Mandatory)][string]$ReceiptRoot,
    [Parameter(Mandatory)][string[]]$AllowedRoots,
    [Parameter(Mandatory)][string]$BackupRoot,
    [switch]$NonInteractive,
    [switch]$ConfirmRollback,
    [switch]$Json,
    [scriptblock]$ConfirmationReader
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/Receipt.psm1') -Force
$receipt = Read-InstallReceipt -Path $ReceiptPath -ReceiptRoot $ReceiptRoot -AllowedRoots $AllowedRoots -BackupRoot $BackupRoot

if ($receipt.state -ceq 'ROLLED_BACK') {
    $result = [pscustomobject][ordered]@{ Status = 'ALREADY_ROLLED_BACK'; Actions = @(); ReceiptPath = [IO.Path]::GetFullPath($ReceiptPath) }
    if ($Json) { Write-Output -NoEnumerate ($result | ConvertTo-Json -Depth 10 -Compress) } else { $result }
    return
}

# Construct and validate every action before asking for confirmation or mutating anything.
$actions = [Collections.Generic.List[object]]::new()
$restored = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($backup in $receipt.backups) {
    $target = Assert-OwnedPath -Path $backup.path -AllowedRoots $AllowedRoots -AllowMissing
    if ($backup.existed) {
        $source = Assert-OwnedPath -Path $backup.backupPath -AllowedRoots @($BackupRoot)
        $sourceIsDirectory = Test-Path -LiteralPath $source -PathType Container
        if (-not (Test-Path -LiteralPath $source) -or (($backup.type -eq 'directory') -ne $sourceIsDirectory)) { throw "ROLLBACK_BACKUP_INVALID:$source" }
        [void]$actions.Add([pscustomobject]@{ Kind = 'RESTORE'; Target = $target; Source = $source; Type = $backup.type })
        [void]$restored.Add($target)
    }
    elseif ($restored.Add($target)) {
        [void]$actions.Add([pscustomobject]@{ Kind = 'REMOVE'; Target = $target; Source = $null; Type = 'absent' })
    }
}
foreach ($ownedPath in $receipt.ownedPaths) {
    $target = Assert-OwnedPath -Path $ownedPath -AllowedRoots $AllowedRoots -AllowMissing
    if ($restored.Add($target)) { [void]$actions.Add([pscustomobject]@{ Kind = 'REMOVE'; Target = $target; Source = $null; Type = 'owned' }) }
}

if ($NonInteractive) {
    if (-not $ConfirmRollback) { throw 'ROLLBACK_CONFIRMATION_REQUIRED: pass -ConfirmRollback' }
}
else {
    $answer = if ($PSBoundParameters.ContainsKey('ConfirmationReader')) { & $ConfirmationReader } else { Read-Host 'Type ROLLBACK to continue' }
    if ($answer -cne 'ROLLBACK') {
        $result = [pscustomobject][ordered]@{ Status = 'CANCELED'; Actions = @($actions); ReceiptPath = [IO.Path]::GetFullPath($ReceiptPath) }
        if ($Json) { Write-Output -NoEnumerate ($result | ConvertTo-Json -Depth 10 -Compress) } else { $result }
        return
    }
}

foreach ($action in $actions) {
    if ($action.Kind -eq 'RESTORE') {
        if (Test-Path -LiteralPath $action.Target) { Remove-Item -LiteralPath $action.Target -Recurse -Force }
        $parent = [IO.Path]::GetDirectoryName($action.Target)
        if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $action.Source -Destination $action.Target -Recurse -Force
    }
    elseif (Test-Path -LiteralPath $action.Target) {
        Remove-Item -LiteralPath $action.Target -Recurse -Force
    }
}

$receipt.state = 'ROLLED_BACK'
Save-InstallReceipt -Receipt $receipt -Path $ReceiptPath -ReceiptRoot $ReceiptRoot
$result = [pscustomobject][ordered]@{ Status = 'ROLLED_BACK'; Actions = @($actions); ReceiptPath = [IO.Path]::GetFullPath($ReceiptPath) }
if ($Json) { Write-Output -NoEnumerate ($result | ConvertTo-Json -Depth 10 -Compress) } else { $result }
