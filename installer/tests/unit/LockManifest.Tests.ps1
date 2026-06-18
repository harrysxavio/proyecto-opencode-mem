$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $modulePath = Join-Path $repoRoot 'installer/modules/LockManifest.psm1'
    $lockPath = Join-Path $repoRoot 'installer/components.lock.json'
    Import-Module $modulePath -Force
    $lock = Read-ComponentLock -Path $lockPath
}

Describe 'components.lock.json contract' {
    It 'pins the schema, platform, and kit version' {
        $lock.schemaVersion | Should -Be 1
        $lock.platform | Should -Be 'windows-powershell'
        $lock.kitVersion | Should -Be '0.2.0-rc.1'
    }

    It 'defines the exact core and authenticated packs' {
        @($lock.packs.core) | Should -Be @('git', 'node', 'pnpm', 'python', 'uv', 'opencode', 'engram', 'graphify', 'context7', 'playwright', 'runtime-assets')
        @($lock.packs.authenticated) | Should -Be @('github', 'supabase', 'notebooklm', 'browserbase')
    }

    It 'uses unique component IDs and exact non-latest versions' {
        $ids = @($lock.components.id)
        @($ids | Select-Object -Unique).Count | Should -Be $ids.Count

        $expectedVersions = @{
            git = '2.53.0'; node = '22.17.0'; pnpm = '11.8.0'; python = '3.13.5'
            uv = '0.11.14'; opencode = '1.17.8'; engram = '1.16.3'; graphify = '0.8.41'
            context7 = '3.2.1'; playwright = '0.0.76'; 'runtime-assets' = '0.2.0-rc.1'
        }
        foreach ($entry in $expectedVersions.GetEnumerator()) {
            ($lock.components | Where-Object id -EQ $entry.Key).version | Should -Be $entry.Value
        }
        foreach ($component in $lock.components) {
            $component.version | Should -Not -BeNullOrEmpty
            $component.version | Should -Not -Match '(?i)latest'
            $component.version | Should -Match '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$'
        }
    }

    It 'defines safe structured installation and verification metadata' {
        foreach ($component in $lock.components) {
            $component.required | Should -BeOfType [bool]
            $component.install.allowed | Should -BeOfType [bool]
            $component.integrityStatus | Should -BeIn @('verified', 'planning-only-unverified', 'not-applicable')
            $component.source.kind | Should -BeIn @('winget', 'npm', 'python-package', 'github-release', 'repository-assets')
            ($component.ownedTargets -is [array]) | Should -BeTrue
            @($component.ownedTargets | Where-Object { $_ -isnot [string] }).Count | Should -Be 0
            ($component.dependencies -is [array]) | Should -BeTrue
            @($component.dependencies | Where-Object { $_ -isnot [string] }).Count | Should -Be 0
            $component.install.command | Should -Not -BeNullOrEmpty
            $component.install.command | Should -Not -Match '[;&|]'
            ($component.install.arguments -is [array]) | Should -BeTrue
            @($component.install.arguments | Where-Object { $_ -isnot [string] }).Count | Should -Be 0
            @($component.verificationIds).Count | Should -BeGreaterThan 0
        }
    }

    It 'uses immutable HTTPS URLs and SHA-256 hashes for GitHub releases' {
        foreach ($component in @($lock.components | Where-Object { $_.source.kind -eq 'github-release' -and $_.integrityStatus -eq 'verified' })) {
            $component.source.url | Should -Match '^https://'
            $component.source.url | Should -Match ([regex]::Escape($component.version))
            $component.source.sha256 | Should -Match '^[0-9a-f]{64}$'
        }
    }

    It 'keeps Engram planning honest while its artifact integrity is unverified' {
        $engram = $lock.components | Where-Object id -EQ 'engram'
        $engram.source.kind | Should -Be 'github-release'
        $engram.integrityStatus | Should -Be 'planning-only-unverified'
        $engram.install.allowed | Should -BeFalse
    }

    It 'uses one canonical OpenCode root for runtime assets install and ownership' {
        $runtimeAssets = $lock.components | Where-Object id -EQ 'runtime-assets'
        $runtimeAssets.install.arguments | Should -Contain '${OPENCODE_KIT_ROOT}'
        $runtimeAssets.ownedTargets | Should -Contain 'path:${OPENCODE_KIT_ROOT}'
        ($runtimeAssets.install.arguments -join ' ') | Should -Not -Match 'CODEX_OVERLAY_ROOT'
    }

    It 'gives authenticated components concrete versioned configuration' {
        foreach ($id in @('github', 'supabase', 'notebooklm', 'browserbase')) {
            $component = $lock.components | Where-Object id -EQ $id
            $component.version | Should -Match '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$'
            $component.config.command | Should -Not -BeNullOrEmpty
            @($component.config.arguments).Count | Should -BeGreaterThan 0
        }
    }

    It 'references only declared component IDs' {
        $ids = @($lock.components.id)
        foreach ($id in @($lock.packs.core) + @($lock.packs.authenticated)) { $ids | Should -Contain $id }
        foreach ($dependency in @($lock.components.dependencies)) { if ($null -ne $dependency) { $ids | Should -Contain $dependency } }
    }
}

Describe 'Read-ComponentLock validation' {
    BeforeEach {
        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
    }

    It 'rejects an unsupported schema with a stable code' {
        $document.schemaVersion = 2
        $path = Join-Path $TestDrive 'schema.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_SCHEMA_VERSION*'
    }

    It 'rejects the wrong kit version with a stable code' {
        $document.kitVersion = '0.2.0'
        $path = Join-Path $TestDrive 'kit-version.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_KIT_VERSION_INVALID*'
    }

    It 'rejects any component count other than 15' {
        $document.components = @($document.components | Select-Object -First 14)
        $path = Join-Path $TestDrive 'component-count.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_COMPONENT_COUNT_INVALID*'
    }

    It 'rejects pack extras and omissions with a stable code' {
        foreach ($case in @(
            @{ Name = 'core-extra'; Pack = 'core'; Value = @($document.packs.core) + 'browserbase' },
            @{ Name = 'core-omission'; Pack = 'core'; Value = @($document.packs.core | Select-Object -Skip 1) },
            @{ Name = 'authenticated-extra'; Pack = 'authenticated'; Value = @($document.packs.authenticated) + 'git' },
            @{ Name = 'authenticated-omission'; Pack = 'authenticated'; Value = @($document.packs.authenticated | Select-Object -Skip 1) }
        )) {
            $candidate = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
            $candidate.packs.($case.Pack) = $case.Value
            $path = Join-Path $TestDrive "$($case.Name).json"
            $candidate | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
            { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_PACK_INVALID*'
        }
    }

    It 'rejects the wrong platform with a stable code' {
        $document.platform = 'linux'
        $path = Join-Path $TestDrive 'platform.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_PLATFORM*'
    }

    It 'rejects duplicate IDs with a stable code' {
        $document.components[1].id = $document.components[0].id
        $path = Join-Path $TestDrive 'duplicate.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_DUPLICATE_ID*'
    }

    It 'rejects malformed component structure with a stable code' {
        $document.components[0].PSObject.Properties.Remove('install')
        $path = Join-Path $TestDrive 'malformed-component.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_SCHEMA*'
    }

    It 'rejects missing or non-boolean required metadata' {
        $document.components[0].PSObject.Properties.Remove('required')
        $path = Join-Path $TestDrive 'required-missing.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_COMPONENT_REQUIRED_INVALID*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].required = 'true'
        $path = Join-Path $TestDrive 'required-type.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_COMPONENT_REQUIRED_INVALID*'
    }

    It 'rejects missing or non-array ownership metadata' {
        $document.components[0].PSObject.Properties.Remove('ownedTargets')
        $path = Join-Path $TestDrive 'ownership-missing.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_COMPONENT_OWNERSHIP_INVALID*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].ownedTargets = 'bin/git.exe'
        $path = Join-Path $TestDrive 'ownership-type.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_COMPONENT_OWNERSHIP_INVALID*'
    }

    It 'rejects missing or non-boolean install allowed metadata' {
        $document.components[0].install.PSObject.Properties.Remove('allowed')
        $path = Join-Path $TestDrive 'allowed-missing.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_INSTALL_ALLOWED_INVALID*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].install.allowed = 'true'
        $path = Join-Path $TestDrive 'allowed-type.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_INSTALL_ALLOWED_INVALID*'
    }

    It 'rejects missing or unknown integrity status' {
        $document.components[0].PSObject.Properties.Remove('integrityStatus')
        $path = Join-Path $TestDrive 'integrity-missing.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_INTEGRITY_STATUS_INVALID*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].integrityStatus = 'unknown'
        $path = Join-Path $TestDrive 'integrity-unknown.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_INTEGRITY_STATUS_INVALID*'
    }

    It 'rejects unknown source kinds' {
        $document.components[0].source.kind = 'remote-script'
        $path = Join-Path $TestDrive 'source-kind.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_SOURCE_KIND_INVALID*'
    }

    It 'rejects changed pack membership and missing dependency references with stable codes' {
        $document.packs.core[0] = 'missing-pack-component'
        $path = Join-Path $TestDrive 'pack-reference.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_PACK_INVALID*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].dependencies = @('missing-dependency')
        $path = Join-Path $TestDrive 'dependency-reference.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_UNKNOWN_REFERENCE*'
    }

    It 'rejects unsafe commands and non-array arguments' {
        $document.components[0].install.command = 'winget;calc'
        $path = Join-Path $TestDrive 'command.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_INSTALL_COMMAND*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].install.arguments = 'install'
        $path = Join-Path $TestDrive 'arguments.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_INSTALL_ARGUMENTS*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].install.arguments = @([pscustomobject]@{ value = 'install' })
        $path = Join-Path $TestDrive 'argument-object.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_INSTALL_ARGUMENTS*'
    }

    It 'rejects non-string install commands' {
        foreach ($case in @(
            @{ Name = 'array'; Value = @('winget') },
            @{ Name = 'object'; Value = [pscustomobject]@{ executable = 'winget' } }
        )) {
            $candidate = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
            $candidate.components[0].install.command = $case.Value
            $path = Join-Path $TestDrive "command-$($case.Name).json"
            $candidate | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
            { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_INSTALL_COMMAND*'
        }
    }

    It 'rejects scalar and non-string dependency or ownership arrays' {
        $document.components[0].dependencies = 'node'
        $path = Join-Path $TestDrive 'dependencies-scalar.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_DEPENDENCIES*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].ownedTargets = @([pscustomobject]@{ path = 'git.exe' })
        $path = Join-Path $TestDrive 'ownership-object.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_COMPONENT_OWNERSHIP_INVALID*'
    }

    It 'requires metadata appropriate to each source kind' {
        foreach ($case in @(
            @{ Name = 'winget'; Id = 'git'; Field = 'id'; Code = 'LOCK_SOURCE_METADATA_INVALID*' },
            @{ Name = 'npm'; Id = 'pnpm'; Field = 'package'; Code = 'LOCK_SOURCE_METADATA_INVALID*' },
            @{ Name = 'python'; Id = 'graphify'; Field = 'package'; Code = 'LOCK_SOURCE_METADATA_INVALID*' },
            @{ Name = 'assets'; Id = 'runtime-assets'; Field = 'sourcePath'; Code = 'LOCK_SOURCE_METADATA_INVALID*' }
        )) {
            $candidate = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
            $component = $candidate.components | Where-Object id -EQ $case.Id
            $component.source.PSObject.Properties.Remove($case.Field)
            $path = Join-Path $TestDrive "source-$($case.Name).json"
            $candidate | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
            { Read-ComponentLock -Path $path } | Should -Throw $case.Code
        }

        $candidate = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $engram = $candidate.components | Where-Object id -EQ 'engram'
        $engram.install.allowed = $true
        $path = Join-Path $TestDrive 'engram-planning-allowed.json'
        $candidate | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_SOURCE_INTEGRITY*'
    }

    It 'rejects empty verification IDs and invalid GitHub release integrity' {
        $document.components[0].verificationIds = @()
        $path = Join-Path $TestDrive 'verification.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_VERIFICATION_IDS*'

        $document = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
        $document.components[0].source = [pscustomobject]@{ kind = 'github-release'; url = 'http://example.test/latest/tool.exe'; sha256 = 'ABC' }
        $path = Join-Path $TestDrive 'hash.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_SOURCE_INTEGRITY*'
    }

    It 'rejects non-string GitHub release URLs and hashes' {
        $validUrl = 'https://github.com/example/engram/releases/download/v1.16.3/engram.exe'
        $validHash = ('a' * 64) -join ''
        foreach ($case in @(
            @{ Name = 'url-array'; Field = 'url'; Value = @($validUrl) },
            @{ Name = 'url-object'; Field = 'url'; Value = [pscustomobject]@{ href = $validUrl } },
            @{ Name = 'url-number'; Field = 'url'; Value = 42 },
            @{ Name = 'hash-array'; Field = 'sha256'; Value = @($validHash) },
            @{ Name = 'hash-object'; Field = 'sha256'; Value = [pscustomobject]@{ value = $validHash } },
            @{ Name = 'hash-number'; Field = 'sha256'; Value = 42 }
        )) {
            $candidate = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json -Depth 30
            $engram = $candidate.components | Where-Object id -EQ 'engram'
            $engram.integrityStatus = 'verified'
            $engram.install.allowed = $true
            $engram.source | Add-Member -NotePropertyName url -NotePropertyValue $validUrl
            $engram.source | Add-Member -NotePropertyName sha256 -NotePropertyValue $validHash
            $engram.source.($case.Field) = $case.Value
            $path = Join-Path $TestDrive "$($case.Name).json"
            $candidate | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
            { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_SOURCE_INTEGRITY*'
        }
    }
}
