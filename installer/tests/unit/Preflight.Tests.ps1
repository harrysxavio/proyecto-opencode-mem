$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $modulePath = Join-Path $repoRoot 'installer/modules/Preflight.psm1'
    $lockModulePath = Join-Path $repoRoot 'installer/modules/LockManifest.psm1'
    $lockPath = Join-Path $repoRoot 'installer/components.lock.json'
    Import-Module $lockModulePath -Force
    Import-Module $modulePath -Force
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
        Invoke-ConfirmedPrerequisiteInstall -Plan $plan -Runner $script:runner -NonInteractive -ConfirmInstall | Out-Null
        $script:runnerCalls[0].FilePath | Should -Be 'winget'
        $script:runnerCalls[1].FilePath | Should -Be 'corepack'
        $script:runnerCalls[1].Arguments | Should -Be @('prepare', 'pnpm@11.8.0', '--activate')
    }
}

Describe 'install command contract' {
    It 'declares public command parameters and explicit safe confirmation' {
        $commandPath = Join-Path $repoRoot 'installer/commands/install.ps1'
        $text = Get-Content -LiteralPath $commandPath -Raw
        foreach ($name in @('Root', 'Project', 'Resume', 'NonInteractive', 'Json', 'ConfirmInstall')) { $text | Should -Match ([regex]::Escape('$' + $name)) }
    }
}
