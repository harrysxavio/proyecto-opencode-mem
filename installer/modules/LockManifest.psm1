Set-StrictMode -Version Latest

function Throw-LockError {
    param([string]$Code, [string]$Message)
    throw "$Code`: $Message"
}

function Test-LockProperty {
    param([object]$Object, [string]$Name)
    return $null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name]
}

function Test-LockStringArray {
    param([object]$Value)
    if ($Value -isnot [array]) { return $false }
    foreach ($item in $Value) {
        if ($item -isnot [string]) { return $false }
    }
    return $true
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

    foreach ($property in @('schemaVersion', 'kitVersion', 'platform', 'packs', 'components')) {
        if (-not (Test-LockProperty $document $property)) { Throw-LockError 'LOCK_SCHEMA' "Missing top-level property '$property'." }
    }
    if ($document.schemaVersion -ne 1) { Throw-LockError 'LOCK_SCHEMA_VERSION' 'schemaVersion must be 1.' }
    if ($document.kitVersion -ne '0.2.0-rc.1') { Throw-LockError 'LOCK_KIT_VERSION_INVALID' 'kitVersion must be 0.2.0-rc.1.' }
    if ($document.platform -ne 'windows-powershell') { Throw-LockError 'LOCK_PLATFORM' 'platform must be windows-powershell.' }
    if ($null -eq $document.packs -or $document.components -isnot [array]) { Throw-LockError 'LOCK_SCHEMA' 'packs and components are required.' }
    if ($document.components.Count -ne 15) { Throw-LockError 'LOCK_COMPONENT_COUNT_INVALID' 'components must contain exactly 15 entries.' }
    foreach ($packName in @('core', 'authenticated')) {
        if (-not (Test-LockProperty $document.packs $packName)) { Throw-LockError 'LOCK_SCHEMA' "Missing pack '$packName'." }
    }
    $expectedPacks = @{
        core = @('git', 'node', 'pnpm', 'python', 'uv', 'opencode', 'engram', 'graphify', 'context7', 'playwright', 'runtime-assets')
        authenticated = @('github', 'supabase', 'notebooklm', 'browserbase')
    }
    foreach ($packName in @('core', 'authenticated')) {
        $actual = $document.packs.$packName
        $expected = $expectedPacks[$packName]
        if ($actual -isnot [array] -or $actual.Count -ne $expected.Count -or (($actual -join "`u{001f}") -cne ($expected -join "`u{001f}"))) {
            Throw-LockError 'LOCK_PACK_INVALID' "Pack '$packName' does not match the schema 1 contract."
        }
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
        if (-not (Test-LockProperty $component 'required') -or $component.required -isnot [bool]) {
            Throw-LockError 'LOCK_COMPONENT_REQUIRED_INVALID' "Component '$($component.id)' required must be boolean."
        }
        if (-not (Test-LockProperty $component 'ownedTargets') -or -not (Test-LockStringArray $component.ownedTargets)) {
            Throw-LockError 'LOCK_COMPONENT_OWNERSHIP_INVALID' "Component '$($component.id)' ownedTargets must be an array."
        }
        if (-not (Test-LockProperty $component.install 'allowed') -or $component.install.allowed -isnot [bool]) {
            Throw-LockError 'LOCK_INSTALL_ALLOWED_INVALID' "Component '$($component.id)' install.allowed must be boolean."
        }
        if (-not (Test-LockProperty $component 'integrityStatus') -or $component.integrityStatus -notin @('verified', 'planning-only-unverified', 'not-applicable')) {
            Throw-LockError 'LOCK_INTEGRITY_STATUS_INVALID' "Component '$($component.id)' has an invalid integrityStatus."
        }
        if ($component.source.kind -notin @('winget', 'npm', 'python-package', 'github-release', 'repository-assets')) {
            Throw-LockError 'LOCK_SOURCE_KIND_INVALID' "Component '$($component.id)' has an unsupported source kind."
        }
        if ([string]::IsNullOrWhiteSpace($component.id)) { Throw-LockError 'LOCK_COMPONENT_ID' 'Every component requires an ID.' }
        if (-not $ids.Add([string]$component.id)) { Throw-LockError 'LOCK_DUPLICATE_ID' "Duplicate component ID '$($component.id)'." }
        if ([string]::IsNullOrWhiteSpace($component.version) -or $component.version -match '(?i)latest' -or $component.version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
            Throw-LockError 'LOCK_VERSION' "Component '$($component.id)' requires an exact version."
        }
        if (-not (Test-LockStringArray $component.dependencies)) { Throw-LockError 'LOCK_DEPENDENCIES_INVALID' "Component '$($component.id)' dependencies must be a string array." }
        if ($component.install.command -isnot [string] -or [string]::IsNullOrWhiteSpace($component.install.command) -or $component.install.command -match '[;&|]') {
            Throw-LockError 'LOCK_INSTALL_COMMAND' "Component '$($component.id)' has an unsafe install command."
        }
        if (-not (Test-LockStringArray $component.install.arguments)) { Throw-LockError 'LOCK_INSTALL_ARGUMENTS_INVALID' "Component '$($component.id)' install arguments must be a string array." }
        if (-not (Test-LockStringArray $component.verificationIds) -or $component.verificationIds.Count -eq 0) {
            Throw-LockError 'LOCK_VERIFICATION_IDS' "Component '$($component.id)' requires verification IDs."
        }
        switch ($component.source.kind) {
            'winget' {
                if ($component.integrityStatus -ne 'verified' -or -not (Test-LockProperty $component.source 'id') -or $component.source.id -isnot [string] -or [string]::IsNullOrWhiteSpace($component.source.id)) {
                    Throw-LockError 'LOCK_SOURCE_METADATA_INVALID' "Component '$($component.id)' requires a verified winget ID."
                }
            }
            'npm' {
                if ($component.integrityStatus -ne 'verified' -or -not (Test-LockProperty $component.source 'package') -or $component.source.package -isnot [string] -or [string]::IsNullOrWhiteSpace($component.source.package)) {
                    Throw-LockError 'LOCK_SOURCE_METADATA_INVALID' "Component '$($component.id)' requires a verified npm package."
                }
            }
            'python-package' {
                if ($component.integrityStatus -ne 'verified' -or -not (Test-LockProperty $component.source 'package') -or $component.source.package -isnot [string] -or [string]::IsNullOrWhiteSpace($component.source.package)) {
                    Throw-LockError 'LOCK_SOURCE_METADATA_INVALID' "Component '$($component.id)' requires a verified Python package."
                }
            }
            'repository-assets' {
                if ($component.integrityStatus -ne 'not-applicable' -or -not (Test-LockProperty $component.source 'sourcePath') -or $component.source.sourcePath -isnot [string] -or [string]::IsNullOrWhiteSpace($component.source.sourcePath)) {
                    Throw-LockError 'LOCK_SOURCE_METADATA_INVALID' "Component '$($component.id)' requires a repository sourcePath."
                }
            }
            'github-release' {
                if ($component.integrityStatus -eq 'planning-only-unverified') {
                    if ($component.install.allowed) { Throw-LockError 'LOCK_SOURCE_INTEGRITY' "Unverified GitHub release '$($component.id)' cannot be installed." }
                }
                elseif ($component.integrityStatus -eq 'verified') {
                    if (-not (Test-LockProperty $component.source 'url') -or -not (Test-LockProperty $component.source 'sha256') -or
                        -not (Test-LockProperty $component.source 'checksumUrl') -or -not (Test-LockProperty $component.source 'provenance')) {
                        Throw-LockError 'LOCK_SOURCE_INTEGRITY' "Component '$($component.id)' is missing GitHub release integrity metadata."
                    }
                    if ($component.source.url -isnot [string] -or [string]::IsNullOrWhiteSpace($component.source.url) -or
                        $component.source.sha256 -isnot [string] -or [string]::IsNullOrWhiteSpace($component.source.sha256)) {
                        Throw-LockError 'LOCK_SOURCE_INTEGRITY' "Component '$($component.id)' GitHub release URL and hash must be strings."
                    }
                    $versionToken = [regex]::Escape([string]$component.version)
                    if ($component.source.url -notmatch '^https://' -or $component.source.url -notmatch $versionToken -or $component.source.sha256 -notmatch '^[0-9a-f]{64}$' -or
                        $component.source.checksumUrl -isnot [string] -or $component.source.checksumUrl -notmatch '^https://' -or $component.source.checksumUrl -notmatch $versionToken -or
                        $component.source.provenance -isnot [string] -or $component.source.provenance -cne 'project-pinned-verified-download') {
                        Throw-LockError 'LOCK_SOURCE_INTEGRITY' "Component '$($component.id)' has invalid GitHub release integrity metadata."
                    }
                }
                else { Throw-LockError 'LOCK_SOURCE_INTEGRITY' "Component '$($component.id)' has invalid GitHub release integrity state." }
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
