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

function Test-SameOrAncestorPath {
    param([Parameter(Mandatory)][string]$Ancestor, [Parameter(Mandatory)][string]$Path)
    $ancestorFull = [IO.Path]::GetFullPath($Ancestor).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $pathFull.Equals($ancestorFull, [StringComparison]::OrdinalIgnoreCase) -or
        $pathFull.StartsWith($ancestorFull + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function Test-OverlappingPath {
    param([Parameter(Mandatory)][string]$Left, [Parameter(Mandatory)][string]$Right)
    (Test-SameOrAncestorPath $Left $Right) -or (Test-SameOrAncestorPath $Right $Left)
}

function ConvertTo-RollbackActionDto {
    param([Parameter(Mandatory)][Collections.IEnumerable]$Plan)
    foreach ($item in $Plan) {
        [pscustomobject][ordered]@{ Kind = $item.Item1; Target = $item.Item2; Source = $item.Item3; Type = $item.Item4 }
    }
}

if ($receipt.state -ceq 'ROLLED_BACK') {
    $result = [pscustomobject][ordered]@{ Status = 'ALREADY_ROLLED_BACK'; Actions = @(); ReceiptPath = [IO.Path]::GetFullPath($ReceiptPath) }
    if ($Json) { Write-Output -NoEnumerate ($result | ConvertTo-Json -Depth 10 -Compress) } else { $result }
    return
}

# Construct and validate every action before asking for confirmation or mutating anything.
$actions = [Collections.Generic.List[object]]::new()
foreach ($backup in $receipt.backups) {
    $target = Assert-OwnedPath -Path $backup.path -AllowedRoots $AllowedRoots -AllowMissing
    if ($backup.existed) {
        $source = Assert-OwnedPath -Path $backup.backupPath -AllowedRoots @($BackupRoot)
        $sourceIsDirectory = Test-Path -LiteralPath $source -PathType Container
        if (-not (Test-Path -LiteralPath $source) -or (($backup.type -eq 'directory') -ne $sourceIsDirectory)) { throw "ROLLBACK_BACKUP_INVALID:$source" }
        [void]$actions.Add([pscustomobject]@{ Kind = 'RESTORE'; Target = $target; Source = $source; Type = $backup.type; Origin = 'backup' })
    }
    else {
        [void]$actions.Add([pscustomobject]@{ Kind = 'REMOVE'; Target = $target; Source = $null; Type = 'absent'; Origin = 'backup' })
    }
}
foreach ($ownedPath in $receipt.ownedPaths) {
    $target = Assert-OwnedPath -Path $ownedPath -AllowedRoots $AllowedRoots -AllowMissing
    [void]$actions.Add([pscustomobject]@{ Kind = 'REMOVE'; Target = $target; Source = $null; Type = 'owned'; Origin = 'ownership' })
}

# Validate global relationships and then freeze the complete plan before any action.
$deduplicated = [Collections.Generic.List[object]]::new()
foreach ($action in $actions) {
    $sameTarget = @($deduplicated | Where-Object { $_.Target.Equals($action.Target, [StringComparison]::OrdinalIgnoreCase) })
    if ($sameTarget.Count -gt 0) {
        $prior = $sameTarget[0]
        if ($prior.Kind -eq 'REMOVE' -and $action.Kind -eq 'REMOVE' -and @($prior.Type, $action.Type) -contains 'absent' -and @($prior.Type, $action.Type) -contains 'owned') { continue }
        throw "ROLLBACK_PATH_CONFLICT:$($action.Target)"
    }
    foreach ($prior in $deduplicated) {
        if (Test-OverlappingPath $prior.Target $action.Target) { throw "ROLLBACK_PATH_CONFLICT:$($action.Target)" }
    }
    [void]$deduplicated.Add($action)
}

$sourcePaths = @($deduplicated | Where-Object { $null -ne $_.Source } | ForEach-Object Source)
for ($index = 0; $index -lt $sourcePaths.Count; $index++) {
    for ($other = $index + 1; $other -lt $sourcePaths.Count; $other++) {
        if (Test-OverlappingPath $sourcePaths[$index] $sourcePaths[$other]) { throw "ROLLBACK_PATH_CONFLICT:$($sourcePaths[$other])" }
    }
}
$protectedPaths = @([IO.Path]::GetFullPath($ReceiptPath), [IO.Path]::GetFullPath($ReceiptRoot), [IO.Path]::GetFullPath($BackupRoot)) + $sourcePaths
foreach ($action in $deduplicated) {
    foreach ($protected in $protectedPaths) {
        if (Test-OverlappingPath $action.Target $protected) { throw "ROLLBACK_PATH_CONFLICT:$($action.Target)" }
    }
    foreach ($allowedRoot in $AllowedRoots) {
        if (Test-SameOrAncestorPath $action.Target $allowedRoot) { throw "ROLLBACK_PATH_CONFLICT:$($action.Target)" }
    }
}
$executionItems = [Collections.Generic.List[Tuple[string,string,string,string]]]::new()
foreach ($action in $deduplicated) {
    $sourceValue = if ($null -eq $action.Source) { $null } else { [string]$action.Source }
    [void]$executionItems.Add([Tuple[string,string,string,string]]::new([string]$action.Kind, [string]$action.Target, $sourceValue, [string]$action.Type))
}
$executionPlan = [Collections.ObjectModel.ReadOnlyCollection[Tuple[string,string,string,string]]]::new($executionItems.ToArray())

if ($NonInteractive) {
    if (-not $ConfirmRollback) { throw 'ROLLBACK_CONFIRMATION_REQUIRED: pass -ConfirmRollback' }
}
else {
    $answer = if ($PSBoundParameters.ContainsKey('ConfirmationReader')) { & $ConfirmationReader } else { Read-Host 'Type ROLLBACK to continue' }
    if ($answer -cne 'ROLLBACK') {
        $result = [pscustomobject][ordered]@{ Status = 'CANCELED'; Actions = @(ConvertTo-RollbackActionDto $executionPlan); ReceiptPath = [IO.Path]::GetFullPath($ReceiptPath) }
        if ($Json) { Write-Output -NoEnumerate ($result | ConvertTo-Json -Depth 10 -Compress) } else { $result }
        return
    }
}

foreach ($action in $executionPlan) {
    $kind = $action.Item1
    $target = $action.Item2
    $source = $action.Item3
    if ($kind -eq 'RESTORE') {
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        $parent = [IO.Path]::GetDirectoryName($target)
        if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
    }
    elseif (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }
}

$receipt.state = 'ROLLED_BACK'
Save-InstallReceipt -Receipt $receipt -Path $ReceiptPath -ReceiptRoot $ReceiptRoot
$result = [pscustomobject][ordered]@{ Status = 'ROLLED_BACK'; Actions = @(ConvertTo-RollbackActionDto $executionPlan); ReceiptPath = [IO.Path]::GetFullPath($ReceiptPath) }
if ($Json) { Write-Output -NoEnumerate ($result | ConvertTo-Json -Depth 10 -Compress) } else { $result }
