Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Receipt.psm1')

if (-not ('CodexKit.Config.JsonNumber' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

namespace CodexKit.Config {
    public sealed class JsonNumber {
        public string Literal { get; }
        public JsonNumber(string literal) { Literal = literal ?? throw new ArgumentNullException(nameof(literal)); }
        public override string ToString() => Literal;
    }

    public static class NativeDirectoryLock {
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern SafeFileHandle CreateFileW(
            string name, uint access, uint share, IntPtr security, uint creation, uint flags, IntPtr template);
    }
}
'@
}

$script:AllowedRoots = @('mcp', 'agent', 'plugin', 'instructions')
$script:ForbiddenNames = @('__proto__', 'constructor', 'prototype')

function New-OrdinalDictionary {
    [Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
}

function ConvertFrom-JsonElementValue {
    param([Parameter(Mandatory)][System.Text.Json.JsonElement]$Element)
    switch ($Element.ValueKind) {
        ([System.Text.Json.JsonValueKind]::Object) {
            $result = New-OrdinalDictionary
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
            return [CodexKit.Config.JsonNumber]::new($Element.GetRawText())
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
        $copy = New-OrdinalDictionary
        foreach ($key in $Value.Keys) {
            if ($key -isnot [string]) { throw 'CONFIG_OWNED_KEY_INVALID:<non-string>' }
            $copy.Add($key, (Copy-ConfigValue $Value[$key]))
        }
        return $copy
    }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = [Collections.Generic.List[object]]::new()
        foreach ($entry in $Value) { $items.Add((Copy-ConfigValue $entry)) }
        return ,$items.ToArray()
    }
    if ($Value.GetType() -eq [pscustomobject]) {
        $copy = New-OrdinalDictionary
        foreach ($property in $Value.PSObject.Properties) { $copy.Add($property.Name, (Copy-ConfigValue $property.Value)) }
        return $copy
    }
    return $Value
}

function Get-ConfigNumberLiteral {
    param([Parameter(Mandatory)][object]$Value)
    if ($Value -is [CodexKit.Config.JsonNumber]) { return $Value.Literal }
    $culture = [Globalization.CultureInfo]::InvariantCulture
    switch ([Type]::GetTypeCode($Value.GetType())) {
        ([TypeCode]::Single) { return ([single]$Value).ToString('R', $culture) }
        ([TypeCode]::Double) { return ([double]$Value).ToString('R', $culture) }
        ([TypeCode]::Decimal) { return ([decimal]$Value).ToString('G29', $culture) }
        default { return ([IFormattable]$Value).ToString($null, $culture) }
    }
}

function Get-CanonicalConfigNumber {
    param([Parameter(Mandatory)][string]$Literal)
    $match = [regex]::Match($Literal, '^(?<sign>-?)(?<integer>0|[1-9][0-9]*)(?:\.(?<fraction>[0-9]+))?(?:[eE](?<exponent>[+-]?[0-9]+))?$')
    if (-not $match.Success) { throw "CONFIG_NUMBER_INVALID:$Literal" }
    $fraction = $match.Groups['fraction'].Value
    $digits = ($match.Groups['integer'].Value + $fraction).TrimStart('0')
    if ($digits.Length -eq 0) { return '0e0' }
    $power = [Numerics.BigInteger]::Zero
    if ($match.Groups['exponent'].Success) { $power = [Numerics.BigInteger]::Parse($match.Groups['exponent'].Value, [Globalization.CultureInfo]::InvariantCulture) }
    $power -= $fraction.Length
    while ($digits.EndsWith('0', [StringComparison]::Ordinal)) {
        $digits = $digits.Substring(0, $digits.Length - 1)
        $power += [Numerics.BigInteger]::One
    }
    $sign = if ($match.Groups['sign'].Value -eq '-') { '-' } else { '' }
    return $sign + $digits + 'e' + $power.ToString([Globalization.CultureInfo]::InvariantCulture)
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
    $leftNumeric = $Left -is [CodexKit.Config.JsonNumber] -or $numericCodes -contains [Type]::GetTypeCode($Left.GetType())
    $rightNumeric = $Right -is [CodexKit.Config.JsonNumber] -or $numericCodes -contains [Type]::GetTypeCode($Right.GetType())
    if ($leftNumeric -or $rightNumeric) {
        if (-not ($leftNumeric -and $rightNumeric)) { return $false }
        return (Get-CanonicalConfigNumber (Get-ConfigNumberLiteral $Left)) -ceq (Get-CanonicalConfigNumber (Get-ConfigNumberLiteral $Right))
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
            if ($key -in @('plugin', 'instructions')) {
                $index = 0
                foreach ($entry in $value) {
                    $entryPath = "$path[$index]"
                    if ($entry -is [string]) {
                        if ([string]::IsNullOrWhiteSpace($entry) -or $entry -match '[\x00-\x1f\x7f]') { throw "CONFIG_OWNED_KEY_INVALID:$entryPath" }
                    }
                    elseif ($entry -is [Collections.IDictionary]) { Assert-ConfigOwnedTree -Node $entry -Prefix $entryPath }
                    else { throw "CONFIG_OWNED_KEY_INVALID:$entryPath" }
                    $index++
                }
                continue
            }
        }
        if ($value -is [Collections.IDictionary]) { Assert-ConfigOwnedTree -Node $value -Prefix $path }
        elseif ($value -is [Collections.IEnumerable] -and $value -isnot [string]) {
            $index = 0
            foreach ($entry in $value) {
                if ($entry -is [Collections.IDictionary]) { Assert-ConfigOwnedTree -Node $entry -Prefix "$path[$index]" }
                elseif ($entry -is [Collections.IEnumerable] -and $entry -isnot [string]) {
                    Assert-ConfigOwnedArray -Values $entry -Prefix "$path[$index]"
                }
                $index++
            }
        }
    }
}

function Assert-ConfigOwnedArray {
    param([Collections.IEnumerable]$Values, [string]$Prefix)
    $index = 0
    foreach ($entry in $Values) {
        if ($entry -is [Collections.IDictionary]) { Assert-ConfigOwnedTree -Node $entry -Prefix "$Prefix[$index]" }
        elseif ($entry -is [Collections.IEnumerable] -and $entry -isnot [string]) { Assert-ConfigOwnedArray -Values $entry -Prefix "$Prefix[$index]" }
        $index++
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
                if (-not $exists) {
                    $empty = New-OrdinalDictionary
                    $Target.Add($key, $empty)
                    $Changes.Add([pscustomobject][ordered]@{ action = 'add'; path = $path; value = (New-OrdinalDictionary) })
                }
                elseif (-not (Test-ConfigDeepEqual $Target[$key] $ownedValue)) { throw "CONFIG_COLLISION:$path" }
                continue
            }
            if (-not $exists) { $Target.Add($key, (New-OrdinalDictionary)) }
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
    $stream = [IO.MemoryStream]::new()
    $options = [System.Text.Json.JsonWriterOptions]::new()
    $options.Indented = $true
    $options.Encoder = [System.Text.Encodings.Web.JavaScriptEncoder]::UnsafeRelaxedJsonEscaping
    $writer = [System.Text.Json.Utf8JsonWriter]::new($stream, $options)
    try {
        Write-ConfigJsonValue -Writer $writer -Value $Document
        $writer.Flush()
        return [Text.Encoding]::UTF8.GetString($stream.ToArray())
    }
    finally { $writer.Dispose(); $stream.Dispose() }
}

function Write-ConfigJsonValue {
    param([Parameter(Mandatory)][System.Text.Json.Utf8JsonWriter]$Writer, [AllowNull()][object]$Value)
    if ($null -eq $Value) { $Writer.WriteNullValue(); return }
    if ($Value -is [Collections.IDictionary]) {
        $Writer.WriteStartObject()
        foreach ($key in $Value.Keys) {
            $Writer.WritePropertyName([string]$key)
            Write-ConfigJsonValue -Writer $Writer -Value $Value[$key]
        }
        $Writer.WriteEndObject()
        return
    }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        $Writer.WriteStartArray()
        foreach ($entry in $Value) { Write-ConfigJsonValue -Writer $Writer -Value $entry }
        $Writer.WriteEndArray()
        return
    }
    if ($Value -is [CodexKit.Config.JsonNumber]) { $Writer.WriteRawValue($Value.Literal, $false); return }
    if ($Value -is [string]) { $Writer.WriteStringValue([string]$Value); return }
    if ($Value -is [bool]) { $Writer.WriteBooleanValue([bool]$Value); return }
    switch ([Type]::GetTypeCode($Value.GetType())) {
        ([TypeCode]::Byte) { $Writer.WriteNumberValue([int]$Value); return }
        ([TypeCode]::SByte) { $Writer.WriteNumberValue([int]$Value); return }
        ([TypeCode]::Int16) { $Writer.WriteNumberValue([int]$Value); return }
        ([TypeCode]::UInt16) { $Writer.WriteNumberValue([int]$Value); return }
        ([TypeCode]::Int32) { $Writer.WriteNumberValue([int]$Value); return }
        ([TypeCode]::UInt32) { $Writer.WriteNumberValue([uint32]$Value); return }
        ([TypeCode]::Int64) { $Writer.WriteNumberValue([long]$Value); return }
        ([TypeCode]::UInt64) { $Writer.WriteNumberValue([uint64]$Value); return }
        ([TypeCode]::Single) { $Writer.WriteNumberValue([single]$Value); return }
        ([TypeCode]::Double) { $Writer.WriteNumberValue([double]$Value); return }
        ([TypeCode]::Decimal) { $Writer.WriteNumberValue([decimal]$Value); return }
        default { throw "CONFIG_OWNED_VALUE_INVALID:$($Value.GetType().FullName)" }
    }
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

function Copy-ValidatedInstallReceipt {
    param([Parameter(Mandatory)][object]$Receipt)
    [void](Assert-InstallReceipt $Receipt)
    $json = ConvertTo-Json -InputObject $Receipt -Depth 100 -Compress
    $copy = $json | ConvertFrom-Json -Depth 100 -DateKind String
    [void](Assert-InstallReceipt $copy)
    return $copy
}

function Add-ReceiptToMergeResult {
    param([Parameter(Mandatory)][object]$Merge, [Parameter(Mandatory)][object]$Receipt)
    $Merge | Add-Member -MemberType NoteProperty -Name Receipt -Value $Receipt -Force
    $Merge | Add-Member -MemberType NoteProperty -Name UpdatedReceipt -Value $Receipt -Force
    return $Merge
}

function Get-ConfigMutexName {
    param([Parameter(Mandatory)][string]$Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = [Convert]::ToHexString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Path.ToUpperInvariant()))).ToLowerInvariant() }
    finally { $sha.Dispose() }
    return 'Local\CodexKit.Config.' + $hash
}

function Enter-ConfigDirectoryLocks {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Parent)
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'CONFIG_DIRECTORY_LOCK_UNAVAILABLE:platform' }
    $result = [Collections.Generic.List[object]]::new()
    try {
        foreach ($path in @($Root, $Parent) | Select-Object -Unique) {
            if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "CONFIG_DIRECTORY_LOCK_UNAVAILABLE:$path" }
            $identity = (Resolve-Path -LiteralPath $path).Path
            $handle = [CodexKit.Config.NativeDirectoryLock]::CreateFileW(
                $identity, 0, 3, [IntPtr]::Zero, 3, 0x02000000, [IntPtr]::Zero)
            if ($null -eq $handle -or $handle.IsInvalid) {
                if ($null -ne $handle) { $handle.Dispose() }
                throw "CONFIG_DIRECTORY_LOCK_UNAVAILABLE:${path}:$([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
            }
            $result.Add([pscustomobject]@{ Path = [IO.Path]::GetFullPath($path); Identity = $identity; Handle = $handle })
        }
        return ,$result.ToArray()
    }
    catch {
        foreach ($entry in $result) { $entry.Handle.Dispose() }
        throw
    }
}

function Assert-ConfigDirectoryLocksCurrent {
    param([Parameter(Mandatory)][object[]]$Locks)
    foreach ($entry in $Locks) {
        if (-not (Test-Path -LiteralPath $entry.Path -PathType Container)) { throw 'CONFIG_CONCURRENT_MODIFICATION:directory missing' }
        $item = Get-Item -LiteralPath $entry.Path -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'CONFIG_CONCURRENT_MODIFICATION:directory reparse' }
        $current = (Resolve-Path -LiteralPath $entry.Path).Path
        if (-not $current.Equals($entry.Identity, [StringComparison]::OrdinalIgnoreCase)) { throw 'CONFIG_CONCURRENT_MODIFICATION:directory identity' }
    }
}

function Test-ConfigBytesEqual {
    param([AllowNull()][byte[]]$Left, [AllowNull()][byte[]]$Right)
    if ($null -eq $Left -or $null -eq $Right) { return $null -eq $Left -and $null -eq $Right }
    if ($Left.Length -ne $Right.Length) { return $false }
    for ($index = 0; $index -lt $Left.Length; $index++) { if ($Left[$index] -ne $Right[$index]) { return $false } }
    return $true
}

function Assert-ConfigFileUnchanged {
    param([Parameter(Mandatory)][string]$Path, [AllowNull()][byte[]]$OriginalBytes)
    $exists = Test-Path -LiteralPath $Path -PathType Leaf
    if (($null -eq $OriginalBytes) -ne (-not $exists)) { throw 'CONFIG_CONCURRENT_MODIFICATION:existence changed' }
    if ($exists) {
        $current = [IO.File]::ReadAllBytes($Path)
        if (-not (Test-ConfigBytesEqual $OriginalBytes $current)) { throw 'CONFIG_CONCURRENT_MODIFICATION:content changed' }
    }
}

function Assert-ConfigStateUnchanged {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][object[]]$Locks,
        [AllowNull()][byte[]]$OriginalBytes
    )
    try {
        [void](Assert-ConfigPath -Path $Path -Root $Root)
        Assert-ConfigDirectoryLocksCurrent $Locks
        Assert-ConfigFileUnchanged -Path $Path -OriginalBytes $OriginalBytes
    }
    catch {
        if ($_.Exception.Message -like 'CONFIG_CONCURRENT_MODIFICATION:*') { throw }
        throw "CONFIG_CONCURRENT_MODIFICATION:$($_.Exception.Message)"
    }
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
        [scriptblock]$AtomicWriteOperation,
        [Alias('BeforePublishOperation','PrePublishOperation')][scriptblock]$BeforePublishValidation
    )
    $fullPath = Assert-ConfigPath -Path $ConfigPath -Root $OpenCodeConfigRoot
    $parent = [IO.Path]::GetDirectoryName($fullPath)
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $mutex = [Threading.Mutex]::new($false, (Get-ConfigMutexName $fullPath))
    $mutexAcquired = $false
    try {
        try { $mutexAcquired = $mutex.WaitOne([timespan]::FromSeconds(30)) }
        catch [Threading.AbandonedMutexException] { $mutexAcquired = $true }
        if (-not $mutexAcquired) { throw 'CONFIG_LOCK_TIMEOUT' }
        $locks = Enter-ConfigDirectoryLocks -Root ([IO.Path]::GetFullPath($OpenCodeConfigRoot)) -Parent $parent
        try {
            [void](Assert-ConfigPath -Path $fullPath -Root $OpenCodeConfigRoot)
            Assert-ConfigDirectoryLocksCurrent $locks
            $exists = Test-Path -LiteralPath $fullPath -PathType Leaf
            if ((Test-Path -LiteralPath $fullPath) -and -not $exists) { throw "CONFIG_PATH_OUTSIDE_ROOT:$ConfigPath" }
            $originalBytes = if ($exists) { [IO.File]::ReadAllBytes($fullPath) } else { $null }
            $existingText = if ($exists) { [IO.File]::ReadAllText($fullPath, [Text.Encoding]::UTF8) } else { '{}' }
            $merge = Merge-OpenCodeConfig -ExistingText $existingText -Owned $Owned
            $receiptCopy = Copy-ValidatedInstallReceipt $Receipt
            Add-ReceiptOwnedPath -Receipt $receiptCopy -Path $fullPath
            foreach ($key in $merge.OwnedKeys) { Add-ReceiptOwnedKey -Receipt $receiptCopy -Key $key }
            [void](Assert-InstallReceipt $receiptCopy)
            if (-not $merge.Changed) { return Add-ReceiptToMergeResult -Merge $merge -Receipt $receiptCopy }

            if ($PSBoundParameters.ContainsKey('BeforePublishValidation')) {
                try { & $BeforePublishValidation }
                catch { throw "CONFIG_CONCURRENT_MODIFICATION:$($_.Exception.Message)" }
            }
            Assert-ConfigStateUnchanged -Path $fullPath -Root $OpenCodeConfigRoot -Locks $locks -OriginalBytes $originalBytes

            $backupParameters = @{ Receipt = $receiptCopy; Path = $fullPath; BackupRoot = $BackupRoot; BackupId = $BackupId; AllowedRoots = @($OpenCodeConfigRoot) }
            if ($PSBoundParameters.ContainsKey('BackupCopyOperation')) { $backupParameters.CopyOperation = $BackupCopyOperation }
            [void](Backup-InstallPath @backupParameters)
            [void](Assert-InstallReceipt $receiptCopy)
            Assert-ConfigStateUnchanged -Path $fullPath -Root $OpenCodeConfigRoot -Locks $locks -OriginalBytes $originalBytes

            $temp = Join-Path $parent ('.' + [IO.Path]::GetFileName($fullPath) + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
            try {
                if ($PSBoundParameters.ContainsKey('AtomicWriteOperation')) { & $AtomicWriteOperation $temp $fullPath $merge.Json }
                else { [IO.File]::WriteAllText($temp, $merge.Json, [Text.UTF8Encoding]::new($false)) }
                Assert-ConfigStateUnchanged -Path $fullPath -Root $OpenCodeConfigRoot -Locks $locks -OriginalBytes $originalBytes
                if (-not (Test-Path -LiteralPath $temp -PathType Leaf)) { throw 'CONFIG_ATOMIC_TEMP_MISSING' }
                [IO.File]::Move($temp, $fullPath, $true)
            }
            finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
            return Add-ReceiptToMergeResult -Merge $merge -Receipt $receiptCopy
        }
        finally { foreach ($entry in $locks) { $entry.Handle.Dispose() } }
    }
    finally {
        if ($mutexAcquired) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

Export-ModuleMember -Function ConvertFrom-Jsonc, Merge-OpenCodeConfig, Write-OpenCodeConfig
