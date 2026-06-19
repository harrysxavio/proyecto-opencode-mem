$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $modulePath = Join-Path $repoRoot 'installer/modules/Preflight.psm1'
    $lockModulePath = Join-Path $repoRoot 'installer/modules/LockManifest.psm1'
    $lockPath = Join-Path $repoRoot 'installer/components.lock.json'
    Import-Module $lockModulePath -Force
    Import-Module $modulePath -Force
    Import-Module (Join-Path $repoRoot 'installer/modules/Receipt.psm1') -Force
    $lock = Read-ComponentLock -Path $lockPath
}

Describe 'Get-BootstrapPreflight' {
    It 'defaults RequiredBytes to one gigabyte and does not require a lock for discovery' {
        $resolver = { param($id) [pscustomobject]@{ Present = $true; Version = '1.0.0' } }
        $result = Get-BootstrapPreflight -PlatformIsWindows $true -PowerShellVersion ([version]'7.5') -FreeBytes 2GB -CommandResolver $resolver
        $result.RequiredBytes | Should -Be 1GB
    }

    It 'returns the Windows checks and missing actions without running installers' {
        $calls = [Collections.Generic.List[string]]::new()
        $resolver = { param($id) [void]$calls.Add($id); [pscustomobject]@{ Present = ($id -eq 'git'); Version = if ($id -eq 'git') { '2.53.0' } else { $null } } }

        $result = Get-BootstrapPreflight -PlatformIsWindows $true -PowerShellVersion ([version]'7.5.0') -FreeBytes 2GB -CommandResolver $resolver -Lock $lock

        $result.Platform | Should -Be 'windows-powershell'
        @($result.Checks.Id) | Should -Be @('winget', 'git', 'node', 'pnpm', 'python', 'uv', 'opencode', 'engram', 'graphify')
        @($result.Actions) | Should -Contain 'install:node'
        @($result.Actions) | Should -Not -Contain 'install:git'
        @($calls) | Should -Be @('winget', 'git', 'node', 'pnpm', 'python', 'uv', 'opencode', 'engram', 'graphify')
    }

    It 'rejects unsupported platform, PowerShell, and disk with stable codes' {
        $resolver = { param($id) [pscustomobject]@{ Present = $true; Version = '1.0.0' } }
        { Get-BootstrapPreflight -PlatformIsWindows $false -PowerShellVersion ([version]'7.5') -FreeBytes 2GB -CommandResolver $resolver -Lock $lock } | Should -Throw 'PLATFORM_UNSUPPORTED*'
        { Get-BootstrapPreflight -PlatformIsWindows $true -PowerShellVersion ([version]'6.2') -FreeBytes 2GB -CommandResolver $resolver -Lock $lock } | Should -Throw 'POWERSHELL_UNSUPPORTED*'
        { Get-BootstrapPreflight -PlatformIsWindows $true -PowerShellVersion ([version]'7.5') -FreeBytes (1GB - 1) -CommandResolver $resolver -Lock $lock } | Should -Throw 'DISK_SPACE_INSUFFICIENT*'
    }
}

Describe 'ConvertFrom-VersionProbeResult' {
    It 'parses successful semantic versions including common command aliases' {
        (ConvertFrom-VersionProbeResult -Id node -Result ([pscustomobject]@{ ExitCode = 0; StdOut = 'v22.17.0'; StdErr = '' })).Version | Should -Be '22.17.0'
        (ConvertFrom-VersionProbeResult -Id node -Result ([pscustomobject]@{ ExitCode = 0; StdOut = 'v22.17.0-rc.1'; StdErr = '' })).Version | Should -Be '22.17.0-rc.1'
        (ConvertFrom-VersionProbeResult -Id python -Result ([pscustomobject]@{ ExitCode = 0; StdOut = ''; StdErr = 'Python 3.13.5' })).Version | Should -Be '3.13.5'
        (ConvertFrom-VersionProbeResult -Id git -Result ([pscustomobject]@{ ExitCode = 0; StdOut = 'git version 2.53.0.windows.1'; StdErr = '' })).Version | Should -Be '2.53.0'
    }

    It 'marks failed probes and non-semver output explicitly unusable' {
        foreach ($result in @(
            [pscustomobject]@{ ExitCode = 1; StdOut = '1.2.3'; StdErr = 'failed' },
            [pscustomobject]@{ ExitCode = 0; StdOut = 'unknown'; StdErr = '' }
        )) {
            $state = ConvertFrom-VersionProbeResult -Id node -Result $result
            $state.Present | Should -BeTrue
            $state.Usable | Should -BeFalse
            $state.Version | Should -BeNullOrEmpty
        }
    }
}

Describe 'Resolve-PrerequisitePlan' {
    It 'returns only missing prerequisites in dependency order' {
        $resolver = {
            param($id)
            $versions = @{ git = '2.53.0'; node = $null; pnpm = $null; python = '3.13.5'; uv = $null }
            [pscustomobject]@{ Present = ($null -ne $versions[$id]); Version = $versions[$id] }
        }

        $plan = Resolve-PrerequisitePlan -Lock $lock -CommandResolver $resolver

        @($plan.Items.Id) | Should -Be @('node', 'pnpm', 'uv')
        @($plan.VersionMismatches).Count | Should -Be 0
    }

    It 'reports version mismatches structurally without treating source as absence or using latest' {
        $resolver = { param($id) [pscustomobject]@{ Present = $true; Version = if ($id -eq 'git') { '2.52.0' } else { ($lock.components | Where-Object id -EQ $id).version } } }

        $plan = Resolve-PrerequisitePlan -Lock $lock -CommandResolver $resolver

        @($plan.Items).Count | Should -Be 0
        $plan.VersionMismatches[0].Id | Should -Be 'git'
        $plan.VersionMismatches[0].InstalledVersion | Should -Be '2.52.0'
        $plan.VersionMismatches[0].RequiredVersion | Should -Be '2.53.0'
        ($plan | ConvertTo-Json -Depth 10) | Should -Not -Match '(?i)latest'
    }

    It 'compares prerelease versions exactly against the lock' {
        $resolver = { param($id) [pscustomobject]@{ Present = $true; Usable = $true; Version = if ($id -eq 'node') { '22.17.0-rc.1' } else { ($lock.components | Where-Object id -EQ $id).version } } }
        $stablePlan = Resolve-PrerequisitePlan -Lock $lock -CommandResolver $resolver
        $stablePlan.VersionMismatches.Id | Should -Contain 'node'

        $prereleaseLock = $lock | ConvertTo-Json -Depth 30 | ConvertFrom-Json -Depth 30
        ($prereleaseLock.components | Where-Object id -EQ 'node').version = '22.17.0-rc.1'
        $prereleasePlan = Resolve-PrerequisitePlan -Lock $prereleaseLock -CommandResolver $resolver
        $prereleasePlan.VersionMismatches.Id | Should -Not -Contain 'node'
        $prereleasePlan.CompatibleIds | Should -Contain 'node'
    }
}

Describe 'Invoke-ConfirmedPrerequisiteInstall' {
    BeforeEach {
        $script:runnerCalls = [Collections.Generic.List[object]]::new()
        $script:runner = {
            param($FilePath, $Arguments)
            [void]$script:runnerCalls.Add([pscustomobject]@{ FilePath = $FilePath; Arguments = @($Arguments) })
            [pscustomobject]@{ ExitCode = 0; StdOut = ''; StdErr = '' }
        }
    }

    It 'cancels an interactive install without invoking the runner' {
        $plan = [pscustomobject]@{ Items = @($lock.components | Where-Object id -EQ 'git'); VersionMismatches = @() }
        $result = Invoke-ConfirmedPrerequisiteInstall -Plan $plan -Runner $script:runner -ConfirmationReader { 'NO' }
        $result.Status | Should -Be 'CANCELED'
        $script:runnerCalls.Count | Should -Be 0
    }

    It 'refuses noninteractive mutation unless ConfirmInstall is explicit' {
        $plan = [pscustomobject]@{ Items = @($lock.components | Where-Object id -EQ 'git'); VersionMismatches = @() }
        { Invoke-ConfirmedPrerequisiteInstall -Plan $plan -Runner $script:runner -NonInteractive } | Should -Throw 'INSTALL_CONFIRMATION_REQUIRED*'
        $script:runnerCalls.Count | Should -Be 0
    }

    It 'uses exact structured winget arguments including agreement flags' {
        $plan = [pscustomobject]@{ Items = @($lock.components | Where-Object id -EQ 'git'); VersionMismatches = @() }
        Invoke-ConfirmedPrerequisiteInstall -Plan $plan -Runner $script:runner -NonInteractive -ConfirmInstall | Out-Null
        $script:runnerCalls[0].FilePath | Should -Be 'winget'
        $script:runnerCalls[0].Arguments | Should -Be @('install', '--id', 'Git.Git', '--exact', '--version', '2.53.0', '--accept-package-agreements', '--accept-source-agreements')
    }

    It 'raises a stable component failure and stops' {
        $failingRunner = { param($FilePath, $Arguments) [pscustomobject]@{ ExitCode = 7; StdOut = ''; StdErr = 'failed' } }
        $plan = [pscustomobject]@{ Items = @($lock.components | Where-Object id -EQ 'git'); VersionMismatches = @() }
        { Invoke-ConfirmedPrerequisiteInstall -Plan $plan -Runner $failingRunner -NonInteractive -ConfirmInstall } | Should -Throw 'PREREQUISITE_INSTALL_FAILED:git*'
    }

    It 'installs Node before activating the locked pnpm through corepack' {
        $items = @($lock.components | Where-Object id -In @('node', 'pnpm'))
        $plan = [pscustomobject]@{ Items = $items; VersionMismatches = @() }
        Invoke-ConfirmedPrerequisiteInstall -Plan $plan -Runner $script:runner -NonInteractive -ConfirmInstall -ExecutableResolver { 'corepack.cmd' } | Out-Null
        $script:runnerCalls[0].FilePath | Should -Be 'winget'
        $script:runnerCalls[1].FilePath | Should -Be 'corepack.cmd'
        $script:runnerCalls[1].Arguments | Should -Be @('prepare', 'pnpm@11.8.0', '--activate')
    }

    It 'refreshes command resolution after Node install and uses the resolved corepack path' {
        $script:resolveCount = 0
        $script:resolvedCorepack = Join-Path $TestDrive 'nodejs/corepack.cmd'
        $resolver = {
            param($name)
            $script:resolveCount++
            if ($script:resolveCount -eq 1) { return $null }
            return $script:resolvedCorepack
        }
        $script:refreshCount = 0
        $items = @($lock.components | Where-Object id -In @('node', 'pnpm'))
        $plan = [pscustomobject]@{ Items = $items; VersionMismatches = @(); CompatibleIds = @() }

        Invoke-ConfirmedPrerequisiteInstall -Plan $plan -Runner $script:runner -NonInteractive -ConfirmInstall -ExecutableResolver $resolver -PathRefresher { $script:refreshCount++ } | Out-Null

        $script:resolveCount | Should -Be 2
        $script:refreshCount | Should -Be 1
        $script:runnerCalls[1].FilePath | Should -Be $script:resolvedCorepack
    }

    It 'requires resume instead of attempting pnpm when corepack remains unavailable after refresh' {
        $items = @($lock.components | Where-Object id -In @('node', 'pnpm'))
        $plan = [pscustomobject]@{ Items = $items; VersionMismatches = @(); CompatibleIds = @() }

        { Invoke-ConfirmedPrerequisiteInstall -Plan $plan -Runner $script:runner -NonInteractive -ConfirmInstall -ExecutableResolver { $null } -PathRefresher { } } | Should -Throw 'PREREQUISITE_RESTART_REQUIRED:node*'

        $script:runnerCalls.Count | Should -Be 1
        $script:runnerCalls[0].FilePath | Should -Be 'winget'
    }
}

Describe 'install command contract' {
    It 'declares public command parameters and explicit safe confirmation' {
        $commandPath = Join-Path $repoRoot 'installer/commands/install.ps1'
        $text = Get-Content -LiteralPath $commandPath -Raw
        foreach ($name in @('Root', 'Project', 'Resume', 'NonInteractive', 'Json', 'ConfirmInstall')) { $text | Should -Match ([regex]::Escape('$' + $name)) }
    }

    It 'emits exactly one parseable JSON document with the complete state and no information records' {
        $commandPath = Join-Path $repoRoot 'installer/commands/install.ps1'
        $resolver = { param($id) [pscustomobject]@{ Present = $false; Usable = $false; Version = $null } }
        $runner = { param($FilePath, $Arguments) [pscustomobject]@{ ExitCode = 0; StdOut = ''; StdErr = '' } }

        $receipt = New-InstallReceipt -KitVersion '0.2.0-rc.1' -LockDigest ('a' * 64) -SourceCommit 'test'
        $output = @(& $commandPath -Root $repoRoot -Json -NonInteractive -ConfirmInstall -PlatformIsWindows $true -PowerShellVersion ([version]'7.5') -FreeBytes 2GB -CommandResolver $resolver -Runner $runner -ExecutableResolver { 'corepack.cmd' } -PathRefresher { } -CoreReceipt $receipt -CoreExecutor { param($c,$p) [pscustomobject]@{Success=$true;Evidence=$p} } -CoreVerifier { [pscustomobject]@{Status='PASS'} } -CoreCheckpointWriter { param($candidate) } 6>&1)

        $output.Count | Should -Be 1
        $document = $output[0] | ConvertFrom-Json -Depth 20
        $document.preflight.Platform | Should -Be 'windows-powershell'
        @($document.plan.Items).Count | Should -Be 5
        @($document.actions).Count | Should -Be 8
        @($document.core).Count | Should -Be 3
        $document.state | Should -Be 'COMPLETED'
        $document.result.Status | Should -Be 'COMPLETED'
        $document.coreResult.Status | Should -Be 'COMPLETED'
    }
}
