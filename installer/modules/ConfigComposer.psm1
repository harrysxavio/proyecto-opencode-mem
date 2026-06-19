Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Receipt.psm1')

$script:AllowedRoots = @('mcp', 'agent', 'plugin', 'instructions')
$script:ForbiddenNames = @('__proto__', 'constructor', 'prototype')

function ConvertFrom-JsonElementValue {
    param([Parameter(Mandatory)][System.Text.Json.JsonElement]$Element)
    switch ($Element.ValueKind) {
        ([System.Text.Json.JsonValueKind]::Object) {
            $result = [ordered]@{}
            foreach ($property in $Element.EnumerateObject()) {
                if ($result.Contains($property.Name)) { throw "Duplicate JSON property: $($property.Name)" }
                $result.Add($property.Name, (ConvertFrom-JsonElementValue $property.Value))
            }
            return $result
        }
        ([System.Text.Json.JsonValueKind]::Array) {
            $items = [Collections.Generic.List[object]]::new()
            foreach ($item in $Element.EnumerateArray()) { $items.Add((ConvertFrom-JsonElementValue $item)) }
            return ,$items.ToArray()
        }
        ([System.Text.Json.JsonValueKind]::String) { return $Element.GetString() }
        ([System.Text.Json.JsonValueKind]::Number) {
            $integer = [long]0
            if ($Element.TryGetInt64([ref]$integer)) { return $integer }
            return $Element.GetDouble()
        }
        ([System.Text.Json.JsonValueKind]::True) { return $true }
        ([System.Text.Json.JsonValueKind]::False) { return $false }
        ([System.Text.Json.JsonValueKind]::Null) { return $null }
        default { throw "Unsupported JSON value kind: $($Element.ValueKind)" }
    }
}

function ConvertFrom-Jsonc {
    [CmdletBinding()]
    param([Parameter(Mandatory,Position=0)][AllowEmptyString()][string]$Text)
    try {
        $options = [System.Text.Json.JsonDocumentOptions]::new()
        $options.CommentHandling = [System.Text.Json.JsonCommentHandling]::Skip
        $options.AllowTrailingCommas = $true
        $document = [System.Text.Json.JsonDocument]::Parse($Text, $options)
        try {
            $value = ConvertFrom-JsonElementValue $document.RootElement
            if ($value -isnot [Collections.IDictionary]) { throw 'OpenCode config root must be an object' }
            return $value
        }
        finally { $document.Dispose() }
    }
    catch { throw "CONFIG_JSONC_INVALID:$($_.Exception.Message)" }
}

function Copy-ConfigValue {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in $Value.Keys) {
            if ($key -isnot [string]) { throw 'CONFIG_OWNED_KEY_INVALID:<non-string>' }
            $copy.Add($key, (Copy-ConfigValue $Value[$key]))
        }
        return $copy
    }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        return ,@($Value | ForEach-Object { Copy-ConfigValue $_ })
    }
    if ($Value.GetType() -eq [pscustomobject]) {
        $copy = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) { $copy.Add($property.Name, (Copy-ConfigValue $property.Value)) }
        return $copy
    }
    return $Value
}

function Test-ConfigDeepEqual {
    param([AllowNull()][object]$Left, [AllowNull()][object]$Right)
    if ($null -eq $Left -or $null -eq $Right) { return $null -eq $Left -and $null -eq $Right }
    if ($Left -is [Collections.IDictionary] -and $Right -is [Collections.IDictionary]) {
        if ($Left.Count -ne $Right.Count) { return $false }
        foreach ($key in $Left.Keys) {
            if (-not $Right.Contains($key) -or -not (Test-ConfigDeepEqual $Left[$key] $Right[$key])) { return $false }
        }
        return $true
    }
    $leftArray = $Left -is [Collections.IEnumerable] -and $Left -isnot [string]
    $rightArray = $Right -is [Collections.IEnumerable] -and $Right -isnot [string]
    if ($leftArray -or $rightArray) {
        if (-not ($leftArray -and $rightArray)) { return $false }
        $leftItems = @($Left); $rightItems = @($Right)
        if ($leftItems.Count -ne $rightItems.Count) { return $false }
        for ($index = 0; $index -lt $leftItems.Count; $index++) {
            if (-not (Test-ConfigDeepEqual $leftItems[$index] $rightItems[$index])) { return $false }
        }
        return $true
    }
    $numericCodes = @(
        [TypeCode]::Byte, [TypeCode]::SByte, [TypeCode]::Int16, [TypeCode]::UInt16,
        [TypeCode]::Int32, [TypeCode]::UInt32, [TypeCode]::Int64, [TypeCode]::UInt64,
        [TypeCode]::Single, [TypeCode]::Double, [TypeCode]::Decimal
    )
    if ($numericCodes -contains [Type]::GetTypeCode($Left.GetType()) -and $numericCodes -contains [Type]::GetTypeCode($Right.GetType())) {
        return [decimal]$Left -eq [decimal]$Right
    }
    return $Left.GetType() -eq $Right.GetType() -and $Left -ceq $Right
}

function Assert-ConfigOwnedName {
    param([string]$Name, [string]$Path, [switch]$Root)
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name.IndexOfAny([char[]]@('.', '/', '\')) -ge 0 -or
        $Name -match '[\x00-\x1f\x7f]' -or $script:ForbiddenNames -contains $Name -or $Name -in @('.', '..')) {
        throw "CONFIG_OWNED_KEY_INVALID:$Path"
    }
    if ($Root -and $script:AllowedRoots -cnotcontains $Name) { throw "CONFIG_OWNED_KEY_INVALID:$Path" }
}

function Assert-ConfigOwnedTree {
    param([Collections.IDictionary]$Node, [string]$Prefix, [switch]$Root)
    foreach ($keyValue in $Node.Keys) {
        $key = [string]$keyValue
        $path = if ($Prefix) { "$Prefix.$key" } else { $key }
        Assert-ConfigOwnedName -Name $key -Path $path -Root:$Root
        $value = $Node[$keyValue]
        if ($Root) {
            if ($key -in @('mcp', 'agent') -and $value -isnot [Collections.IDictionary]) { throw "CONFIG_OWNED_KEY_INVALID:$path" }
            if ($key -in @('plugin', 'instructions') -and
                ($value -is [string] -or $value -is [Collections.IDictionary] -or $value -isnot [Collections.IEnumerable])) {
                throw "CONFIG_OWNED_KEY_INVALID:$path"
            }
        }
        if ($value -is [Collections.IDictionary]) { Assert-ConfigOwnedTree -Node $value -Prefix $path }
        elseif ($value -is [pscustomobject]) { Assert-ConfigOwnedTree -Node (Copy-ConfigValue $value) -Prefix $path }
    }
}

function Add-ConfigOwnedValues {
    param(
        [Collections.IDictionary]$Target,
        [Collections.IDictionary]$Owned,
        [string]$Prefix,
        [Collections.Generic.List[string]]$OwnedKeys,
        [Collections.Generic.List[object]]$Changes
    )
    foreach ($keyValue in $Owned.Keys) {
        $key = [string]$keyValue
        $path = if ($Prefix) { "$Prefix.$key" } else { $key }
        $ownedValue = $Owned[$keyValue]
        $exists = $Target.Contains($key)
        if ($ownedValue -is [Collections.IDictionary]) {
            if ($ownedValue.Count -eq 0) {
                $OwnedKeys.Add($path)
                if (-not $exists) { $Target.Add($key, [ordered]@{}); $Changes.Add([pscustomobject][ordered]@{ action = 'add'; path = $path; value = [ordered]@{} }) }
                elseif (-not (Test-ConfigDeepEqual $Target[$key] $ownedValue)) { throw "CONFIG_COLLISION:$path" }
                continue
            }
            if (-not $exists) { $Target.Add($key, [ordered]@{}) }
            elseif ($Target[$key] -isnot [Collections.IDictionary]) { throw "CONFIG_COLLISION:$path" }
            Add-ConfigOwnedValues -Target $Target[$key] -Owned $ownedValue -Prefix $path -OwnedKeys $OwnedKeys -Changes $Changes
            continue
        }
        $OwnedKeys.Add($path)
        if (-not $exists) {
            $copy = Copy-ConfigValue $ownedValue
            $Target.Add($key, $copy)
            $Changes.Add([pscustomobject][ordered]@{ action = 'add'; path = $path; value = (Copy-ConfigValue $copy) })
        }
        elseif (-not (Test-ConfigDeepEqual $Target[$key] $ownedValue)) { throw "CONFIG_COLLISION:$path" }
    }
}

function ConvertTo-DeterministicConfigJson {
    param([Collections.IDictionary]$Document)
    ConvertTo-Json -InputObject $Document -Depth 100
}

function Merge-OpenCodeConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][AllowEmptyString()][string]$ExistingText,
        [Parameter(Mandatory,Position=1)][object]$Owned
    )
    $ownedCopy = Copy-ConfigValue $Owned
    if ($ownedCopy -isnot [Collections.IDictionary]) { throw 'CONFIG_OWNED_KEY_INVALID:<root>' }
    Assert-ConfigOwnedTree -Node $ownedCopy -Prefix '' -Root
    $document = ConvertFrom-Jsonc $ExistingText
    $target = Copy-ConfigValue $document
    $ownedKeys = [Collections.Generic.List[string]]::new()
    $changes = [Collections.Generic.List[object]]::new()
    Add-ConfigOwnedValues -Target $target -Owned $ownedCopy -Prefix '' -OwnedKeys $ownedKeys -Changes $changes
    [pscustomobject][ordered]@{
        Document = $target
        OwnedKeys = $ownedKeys.ToArray()
        Json = ConvertTo-DeterministicConfigJson $target
        Changes = $changes.ToArray()
        Changed = $changes.Count -gt 0
    }
}

function Assert-ConfigPath {
    param([string]$Path, [string]$Root)
    try { $fullPath = [IO.Path]::GetFullPath($Path); $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) }
    catch { throw "CONFIG_PATH_OUTSIDE_ROOT:$Path" }
    if (-not ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $fullPath.StartsWith($fullRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase))) {
        throw "CONFIG_PATH_OUTSIDE_ROOT:$Path"
    }
    $candidate = $fullPath
    while ($candidate -and $candidate.Length -ge $fullRoot.Length) {
        if (Test-Path -LiteralPath $candidate) {
            $item = Get-Item -LiteralPath $candidate -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "CONFIG_PATH_OUTSIDE_ROOT:$Path" }
        }
        if ($candidate.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) { break }
        $candidate = [IO.Path]::GetDirectoryName($candidate)
    }
    if (-not $candidate -or -not $candidate.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "CONFIG_PATH_OUTSIDE_ROOT:$Path" }
    return $fullPath
}

function Write-OpenCodeConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][Alias('Path')][string]$ConfigPath,
        [Parameter(Mandatory,Position=1)][string]$OpenCodeConfigRoot,
        [Parameter(Mandatory,Position=2)][object]$Owned,
        [Parameter(Mandatory,Position=3)][object]$Receipt,
        [Parameter(Mandatory,Position=4)][string]$BackupRoot,
        [Parameter(Mandatory,Position=5)][string]$BackupId,
        [scriptblock]$BackupCopyOperation,
        [scriptblock]$AtomicWriteOperation
    )
    $fullPath = Assert-ConfigPath -Path $ConfigPath -Root $OpenCodeConfigRoot
    $exists = Test-Path -LiteralPath $fullPath -PathType Leaf
    if ((Test-Path -LiteralPath $fullPath) -and -not $exists) { throw "CONFIG_PATH_OUTSIDE_ROOT:$ConfigPath" }
    $existingText = if ($exists) { [IO.File]::ReadAllText($fullPath, [Text.Encoding]::UTF8) } else { '{}' }
    $merge = Merge-OpenCodeConfig -ExistingText $existingText -Owned $Owned
    if (-not $merge.Changed) { return $merge }

    $backupParameters = @{ Receipt = $Receipt; Path = $fullPath; BackupRoot = $BackupRoot; BackupId = $BackupId; AllowedRoots = @($OpenCodeConfigRoot) }
    if ($PSBoundParameters.ContainsKey('BackupCopyOperation')) { $backupParameters.CopyOperation = $BackupCopyOperation }
    [void](Backup-InstallPath @backupParameters)
    $parent = [IO.Path]::GetDirectoryName($fullPath)
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $temp = Join-Path $parent ('.' + [IO.Path]::GetFileName($fullPath) + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        if ($PSBoundParameters.ContainsKey('AtomicWriteOperation')) { & $AtomicWriteOperation $temp $fullPath $merge.Json }
        else {
            [IO.File]::WriteAllText($temp, $merge.Json, [Text.UTF8Encoding]::new($false))
            [IO.File]::Move($temp, $fullPath, $true)
        }
    }
    finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
    Add-ReceiptOwnedPath -Receipt $Receipt -Path $fullPath
    foreach ($key in $merge.OwnedKeys) { Add-ReceiptOwnedKey -Receipt $Receipt -Key $key }
    return $merge
}

Export-ModuleMember -Function ConvertFrom-Jsonc, Merge-OpenCodeConfig, Write-OpenCodeConfig
