$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    Import-Module (Join-Path $repoRoot 'installer/modules/LockManifest.psm1') -Force
    Import-Module (Join-Path $repoRoot 'installer/modules/Verification.psm1') -Force
    $lock = Read-ComponentLock -Path (Join-Path $repoRoot 'installer/components.lock.json')
}

Describe 'closed verification registry' {
    It 'exports only the minimal public API' {
        @((Get-Command -Module Verification).Name | Sort-Object) | Should -Be @('Get-VerificationRegistry','Invoke-VerificationId','Test-EngramPersistence','Test-GraphifyFixture')
    }
    It 'advertises every verification ID in the lock and no duplicate IDs' {
        $registry = @(Get-VerificationRegistry)
        $advertised = @($lock.components.verificationIds | ForEach-Object { $_ } | Sort-Object -Unique)
        @($registry.Id | Sort-Object -Unique) | Should -Be $advertised
        @($registry.Id).Count | Should -Be @($registry.Id | Sort-Object -Unique).Count
    }

    It 'uses fixed command and argument-array descriptors for all version probes' {
        $versions = @(Get-VerificationRegistry | Where-Object Kind -EQ 'version')
        @($versions.Id) | Should -Be @('git.version','node.version','pnpm.version','python.version','uv.version','opencode.version','engram.version','graphify.version','context7.version','playwright.version')
        foreach ($descriptor in $versions) {
            $descriptor.Command | Should -BeOfType [string]
            Should -ActualValue $descriptor.Arguments -BeOfType [array]
            $descriptor.Handler | Should -BeNullOrEmpty
        }
    }

    It 'rejects an unknown ID without invoking anything' {
        $script:called = $false
        { Invoke-VerificationId -Id 'arbitrary.command' -ExpectedVersion '1.0.0' -ProcessInvoker { $script:called = $true } } | Should -Throw 'VERIFICATION_ID_UNKNOWN:arbitrary.command*'
        $script:called | Should -BeFalse
    }

    It 'passes fixed command and arguments and requires the exact normalized version' {
        $script:call = $null
        $result = Invoke-VerificationId -Id 'git.version' -ExpectedVersion '2.53.0' -ProcessInvoker {
            param($FilePath, $Arguments)
            $script:call = [pscustomobject]@{ FilePath = $FilePath; Arguments = @($Arguments) }
            [pscustomobject]@{ ExitCode = 0; StdOut = 'git version 2.53.0.windows.1'; StdErr = '' }
        }
        $result.Status | Should -Be 'PASS'
        $result.ActualVersion | Should -Be '2.53.0'
        $script:call.FilePath | Should -Be 'git'
        $script:call.Arguments | Should -Be @('--version')

        $mismatch = Invoke-VerificationId -Id 'node.version' -ExpectedVersion '22.17.0' -ProcessInvoker {
            [pscustomobject]@{ ExitCode = 0; StdOut = 'v22.17.1'; StdErr = '' }
        }
        $mismatch.Status | Should -Be 'FAIL'
        $mismatch.ErrorCode | Should -Be 'VERIFICATION_VERSION_MISMATCH'
    }

    It 'fails closed for malformed or unsuccessful process results' {
        (Invoke-VerificationId -Id 'node.version' -ExpectedVersion '22.17.0' -ProcessInvoker { $false }).ErrorCode | Should -Be 'VERIFICATION_RESULT_INVALID'
        (Invoke-VerificationId -Id 'node.version' -ExpectedVersion '22.17.0' -ProcessInvoker { [pscustomobject]@{ ExitCode = 4; StdOut = ''; StdErr = 'no' } }).ErrorCode | Should -Be 'VERIFICATION_PROCESS_FAILED'
    }

    It 'invokes only the named functional handler and preserves typed evidence' {
        $handlers = @{ 'engram.persist' = { param($Descriptor) [pscustomobject]@{ Success = $true; Evidence = 'round-trip' } } }
        $result = Invoke-VerificationId -Id 'engram.persist' -ProbeHandlers $handlers
        $result.Status | Should -Be 'PASS'
        $result.Evidence | Should -Be 'round-trip'
    }

    It 'returns NOT_READY when a functional handler is absent' {
        $result = Invoke-VerificationId -Id 'mcp.context7'
        $result.Status | Should -Be 'NOT_READY'
        $result.ErrorCode | Should -Be 'VERIFICATION_HANDLER_MISSING'
    }

    It 'converts false, malformed, and throwing functional handlers to stable failures' {
        (Invoke-VerificationId -Id 'graphify.query' -ProbeHandlers @{ 'graphify.query' = { $false } }).ErrorCode | Should -Be 'VERIFICATION_PROBE_FAILED'
        (Invoke-VerificationId -Id 'graphify.query' -ProbeHandlers @{ 'graphify.query' = { 'yes' } }).ErrorCode | Should -Be 'VERIFICATION_RESULT_INVALID'
        (Invoke-VerificationId -Id 'graphify.query' -ProbeHandlers @{ 'graphify.query' = { throw 'boom' } }).ErrorCode | Should -Be 'VERIFICATION_PROBE_EXCEPTION'
    }

    It 'keeps functional descriptors canonical across hostile handler mutation' {
        $first = Invoke-VerificationId -Id 'engram.persist' -ProbeHandlers @{ 'engram.persist' = {
            param($Descriptor)
            $Descriptor.Id = 'mutated'; $Descriptor.Handler = 'mutated'; $Descriptor.Arguments += 'danger'
            [pscustomobject]@{ Success=$true }
        } }
        $secondDescriptor = $null
        $second = Invoke-VerificationId -Id 'engram.persist' -ProbeHandlers @{ 'engram.persist' = {
            param($Descriptor) $script:secondDescriptor = $Descriptor; [pscustomobject]@{ Success=$true }
        } }
        $first.Status | Should -Be 'PASS'
        $second.Status | Should -Be 'PASS'
        $script:secondDescriptor.Id | Should -Be 'engram.persist'
        $script:secondDescriptor.Handler | Should -Be 'engram.persist'
        @($script:secondDescriptor.Arguments).Count | Should -Be 0
    }

    It 'returns fresh argument arrays and does not share them with process callbacks' {
        $firstRegistry = @(Get-VerificationRegistry)
        ($firstRegistry | Where-Object Id -EQ 'git.version').Arguments[0] = 'mutated'
        $secondRegistry = @(Get-VerificationRegistry)
        ($secondRegistry | Where-Object Id -EQ 'git.version').Arguments | Should -Be @('--version')

        Invoke-VerificationId -Id 'git.version' -ExpectedVersion '2.53.0' -ProcessInvoker {
            param($FilePath,$Arguments) $Arguments[0]='mutated'; [pscustomobject]@{ ExitCode=0; StdOut='2.53.0'; StdErr='' }
        } | Out-Null
        $script:observedArguments = $null
        Invoke-VerificationId -Id 'git.version' -ExpectedVersion '2.53.0' -ProcessInvoker {
            param($FilePath,$Arguments) $script:observedArguments=@($Arguments); [pscustomobject]@{ ExitCode=0; StdOut='2.53.0'; StdErr='' }
        } | Out-Null
        $script:observedArguments | Should -Be @('--version')
    }
}
