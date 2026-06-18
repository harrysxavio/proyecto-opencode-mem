Set-StrictMode -Version Latest

function Throw-LockError {
    param([string]$Code, [string]$Message)
    throw "$Code`: $Message"
}

function Test-LockProperty {
    param([object]$Object, [string]$Name)
    return $null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name]
}

function Read-ComponentLock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    }
    catch {
        Throw-LockError 'LOCK_PATH' "Cannot resolve lock path '$Path'."
    }

    try {
        $document = Get-Content -LiteralPath $resolvedPath -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 30 -ErrorAction Stop
    }
    catch {
        Throw-LockError 'LOCK_JSON' "Cannot parse lock file '$resolvedPath'."
    }

    foreach ($property in @('schemaVersion', 'platform', 'packs', 'components')) {
        if (-not (Test-LockProperty $document $property)) { Throw-LockError 'LOCK_SCHEMA' "Missing top-level property '$property'." }
    }
    if ($document.schemaVersion -ne 1) { Throw-LockError 'LOCK_SCHEMA_VERSION' 'schemaVersion must be 1.' }
    if ($document.platform -ne 'windows-powershell') { Throw-LockError 'LOCK_PLATFORM' 'platform must be windows-powershell.' }
    if ($null -eq $document.packs -or $document.components -isnot [array]) { Throw-LockError 'LOCK_SCHEMA' 'packs and components are required.' }
    foreach ($packName in @('core', 'authenticated')) {
        if (-not (Test-LockProperty $document.packs $packName)) { Throw-LockError 'LOCK_SCHEMA' "Missing pack '$packName'." }
    }

    $ids = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($component in $document.components) {
        foreach ($property in @('id', 'version', 'dependencies', 'source', 'install', 'verificationIds')) {
            if (-not (Test-LockProperty $component $property)) { Throw-LockError 'LOCK_SCHEMA' "Component is missing '$property'." }
        }
        foreach ($property in @('command', 'arguments')) {
            if (-not (Test-LockProperty $component.install $property)) { Throw-LockError 'LOCK_SCHEMA' "Component '$($component.id)' install is missing '$property'." }
        }
        if (-not (Test-LockProperty $component.source 'kind')) { Throw-LockError 'LOCK_SCHEMA' "Component '$($component.id)' source is missing 'kind'." }
        if ([string]::IsNullOrWhiteSpace($component.id)) { Throw-LockError 'LOCK_COMPONENT_ID' 'Every component requires an ID.' }
        if (-not $ids.Add([string]$component.id)) { Throw-LockError 'LOCK_DUPLICATE_ID' "Duplicate component ID '$($component.id)'." }
        if ([string]::IsNullOrWhiteSpace($component.version) -or $component.version -match '(?i)latest' -or $component.version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
            Throw-LockError 'LOCK_VERSION' "Component '$($component.id)' requires an exact version."
        }
        if ($component.dependencies -isnot [array]) { Throw-LockError 'LOCK_DEPENDENCIES' "Component '$($component.id)' dependencies must be an array." }
        if ([string]::IsNullOrWhiteSpace($component.install.command) -or $component.install.command -match '[;&|]') {
            Throw-LockError 'LOCK_INSTALL_COMMAND' "Component '$($component.id)' has an unsafe install command."
        }
        if ($component.install.arguments -isnot [array]) { Throw-LockError 'LOCK_INSTALL_ARGUMENTS' "Component '$($component.id)' install arguments must be an array." }
        if ($component.verificationIds -isnot [array] -or $component.verificationIds.Count -eq 0) {
            Throw-LockError 'LOCK_VERIFICATION_IDS' "Component '$($component.id)' requires verification IDs."
        }
        if ($component.source.kind -eq 'github-release') {
            if (-not (Test-LockProperty $component.source 'url') -or -not (Test-LockProperty $component.source 'sha256')) {
                Throw-LockError 'LOCK_SOURCE_INTEGRITY' "Component '$($component.id)' is missing GitHub release integrity metadata."
            }
            $versionToken = [regex]::Escape([string]$component.version)
            if ($component.source.url -notmatch '^https://' -or $component.source.url -notmatch $versionToken -or $component.source.sha256 -notmatch '^[0-9a-f]{64}$') {
                Throw-LockError 'LOCK_SOURCE_INTEGRITY' "Component '$($component.id)' has invalid GitHub release integrity metadata."
            }
        }
    }

    foreach ($packName in @('core', 'authenticated')) {
        $pack = $document.packs.$packName
        if ($pack -isnot [array]) { Throw-LockError 'LOCK_PACK' "Pack '$packName' must be an array." }
        foreach ($reference in $pack) {
            if (-not $ids.Contains([string]$reference)) { Throw-LockError 'LOCK_UNKNOWN_REFERENCE' "Pack '$packName' references '$reference'." }
        }
    }
    foreach ($component in $document.components) {
        foreach ($reference in $component.dependencies) {
            if (-not $ids.Contains([string]$reference)) { Throw-LockError 'LOCK_UNKNOWN_REFERENCE' "Component '$($component.id)' references '$reference'." }
        }
    }

    return $document
}

Export-ModuleMember -Function Read-ComponentLock
