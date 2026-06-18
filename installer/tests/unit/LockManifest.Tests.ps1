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
            @($component.dependencies).GetType().Name | Should -Be 'Object[]'
            $component.install.command | Should -Not -BeNullOrEmpty
            $component.install.command | Should -Not -Match '[;&|]'
            @($component.install.arguments).GetType().Name | Should -Be 'Object[]'
            @($component.verificationIds).Count | Should -BeGreaterThan 0
        }
    }

    It 'uses immutable HTTPS URLs and SHA-256 hashes for GitHub releases' {
        foreach ($component in @($lock.components | Where-Object { $_.source.kind -eq 'github-release' })) {
            $component.source.url | Should -Match '^https://'
            $component.source.url | Should -Match ([regex]::Escape($component.version))
            $component.source.sha256 | Should -Match '^[0-9a-f]{64}$'
        }
    }

    It 'keeps Engram planning honest while its artifact integrity is unverified' {
        $engram = $lock.components | Where-Object id -EQ 'engram'
        $engram.source.kind | Should -Be 'versioned-package'
        $engram.integrityStatus | Should -Be 'planning-only-unverified'
        $engram.install.allowed | Should -BeFalse
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

    It 'rejects missing references with stable codes' {
        $document.packs.core[0] = 'missing-pack-component'
        $path = Join-Path $TestDrive 'pack-reference.json'
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path
        { Read-ComponentLock -Path $path } | Should -Throw 'LOCK_UNKNOWN_REFERENCE*'

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
}
