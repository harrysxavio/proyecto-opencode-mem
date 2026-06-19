$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    Import-Module (Join-Path $repoRoot 'installer/modules/Receipt.psm1') -Force
    Import-Module (Join-Path $repoRoot 'installer/modules/ComponentRunner.psm1') -Force

    function New-TestReceipt {
        [pscustomobject][ordered]@{
            schemaVersion=1; kitVersion='1.0.0'; createdAt='2026-06-19T00:00:00.0000000Z'; state='PLANNED'
            components=@(); ownedPaths=@(); ownedKeys=@(); backups=@()
            provenance=[pscustomobject]@{ sourceCommit='test'; lockDigest=('a' * 64) }
        }
    }
    function New-TestComponent {
        param([string]$Id, [string[]]$Dependencies = @(), [bool]$Required = $true, [bool]$Allowed = $true, [string[]]$VerificationIds = @('runtime-assets.layout'))
        [pscustomobject]@{
            id = $Id; version = '1.0.0'; dependencies = @($Dependencies); required = $Required
            install = [pscustomobject]@{ allowed = $Allowed; command = 'fixed'; arguments = @() }
            verificationIds = @($VerificationIds)
        }
    }
}

Describe 'component state and dependency order' {
    It 'exports only the minimal public API' {
        @((Get-Command -Module ComponentRunner).Name | Sort-Object) | Should -Be @('Assert-StateTransition','Invoke-ComponentPlan','Resolve-ComponentOrder')
    }
    It 'allows only the adjacent forward transitions' {
        foreach ($pair in @(@('DETECTED','PLANNED'),@('PLANNED','INSTALLED'),@('INSTALLED','CONFIGURED'),@('CONFIGURED','VERIFIED'))) {
            { Assert-StateTransition -From $pair[0] -To $pair[1] } | Should -Not -Throw
        }
        foreach ($pair in @(@('DETECTED','INSTALLED'),@('PLANNED','VERIFIED'),@('VERIFIED','CONFIGURED'),@('unknown','PLANNED'))) {
            { Assert-StateTransition -From $pair[0] -To $pair[1] } | Should -Throw 'COMPONENT_STATE_INVALID*'
        }
    }

    It 'performs a stable topological sort using manifest order as the tie breaker' {
        $components = @(
            (New-TestComponent -Id 'b' -Dependencies @('a')),
            (New-TestComponent -Id 'c'),
            (New-TestComponent -Id 'a')
        )
        @(Resolve-ComponentOrder -Components $components).id | Should -Be @('c','a','b')
    }

    It 'rejects duplicate, unknown, and cyclic dependency graphs with stable codes' {
        { Resolve-ComponentOrder -Components @((New-TestComponent a),(New-TestComponent a)) } | Should -Throw 'COMPONENT_DUPLICATE_ID:a*'
        { Resolve-ComponentOrder -Components @((New-TestComponent a @('missing'))) } | Should -Throw 'COMPONENT_DEPENDENCY_UNKNOWN:a:missing*'
        { Resolve-ComponentOrder -Components @((New-TestComponent a @('b')),(New-TestComponent b @('a'))) } | Should -Throw 'COMPONENT_DEPENDENCY_CYCLE*'
    }
}

Describe 'Invoke-ComponentPlan' {
    BeforeEach {
        $script:executorCalls = [Collections.Generic.List[string]]::new()
        $script:checkpoints = [Collections.Generic.List[string]]::new()
        $script:verifierCalls = [Collections.Generic.List[string]]::new()
        $script:executor = { param($Component, $Phase) [void]$script:executorCalls.Add("$($Component.id):$Phase"); [pscustomobject]@{ Success = $true; Evidence = $Phase } }
        $script:verifier = { param($Id, $Component) [void]$script:verifierCalls.Add("$($Component.id):$Id"); [pscustomobject]@{ Status = 'PASS'; Evidence = $Id } }
        $script:checkpoint = {
            param($Candidate)
            [void]$script:checkpoints.Add((@($Candidate.components | ForEach-Object { "$($_.id):$($_.state)" }) -join ','))
        }
    }

    It 'checkpoints every successful transition in order' {
        $receipt = New-TestReceipt
        $result = Invoke-ComponentPlan -Components @((New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'COMPLETED'
        $script:executorCalls | Should -Be @('a:Install','a:Configure')
        $script:checkpoints | Should -Be @('a:PLANNED','a:INSTALLED','a:CONFIGURED','a:VERIFIED')
        $receipt.components[0].state | Should -Be 'VERIFIED'
    }

    It 'resumes from CONFIGURED at verification and never repeats executor phases' {
        $receipt = New-TestReceipt
        $receipt.components = @([pscustomobject]@{ id='a'; state='CONFIGURED' })
        $result = Invoke-ComponentPlan -Components @((New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'COMPLETED'
        $script:executorCalls.Count | Should -Be 0
        $script:checkpoints | Should -Be @('a:VERIFIED')
    }

    It 'does nothing for an already VERIFIED component' {
        $receipt = New-TestReceipt
        $receipt.components = @([pscustomobject]@{ id='a'; state='VERIFIED' })
        $result = Invoke-ComponentPlan -Components @((New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'COMPLETED'
        $script:executorCalls.Count | Should -Be 0
        $script:checkpoints.Count | Should -Be 0
    }

    It 'requires dependencies to be VERIFIED before installation' {
        $receipt = New-TestReceipt
        $receipt.components = @([pscustomobject]@{ id='a'; state='CONFIGURED' })
        $result = Invoke-ComponentPlan -Components @((New-TestComponent b @('a')),(New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'COMPLETED'
        $script:executorCalls[0] | Should -Be 'b:Install'
        $script:checkpoints[0] | Should -Be 'a:VERIFIED'
    }

    It 'blocks install.allowed false before invoking the executor' {
        $receipt = New-TestReceipt
        $result = Invoke-ComponentPlan -Components @((New-TestComponent a -Allowed $false)) -Receipt $receipt -Executor $script:executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'FAILED'
        $result.ErrorCode | Should -Be 'COMPONENT_INSTALL_BLOCKED:a'
        $script:executorCalls.Count | Should -Be 0
        $receipt.components[0].state | Should -Be 'PLANNED'
    }

    It 'stops at the first mandatory failure and preserves the successful checkpoint and evidence' {
        $receipt = New-TestReceipt
        $executor = { param($Component, $Phase) if ($Phase -eq 'Install') { [pscustomobject]@{ Success = $false; Evidence = 'installer exit 7' } } else { [pscustomobject]@{ Success = $true } } }
        $result = Invoke-ComponentPlan -Components @((New-TestComponent a),(New-TestComponent b)) -Receipt $receipt -Executor $executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'FAILED'
        $result.ErrorCode | Should -Be 'COMPONENT_EXECUTOR_FAILED:a:Install'
        $result.Evidence | Should -Be 'installer exit 7'
        $script:checkpoints | Should -Be @('a:PLANNED')
        @($receipt.components | Where-Object id -EQ 'b').Count | Should -Be 0
    }

    It 'reports an optional failure as degraded without failing required core work' {
        $receipt = New-TestReceipt
        $executor = { param($Component, $Phase) if ($Component.id -eq 'optional' -and $Phase -eq 'Configure') { $false } else { [pscustomobject]@{ Success = $true } } }
        $result = Invoke-ComponentPlan -Components @((New-TestComponent core),(New-TestComponent optional -Required $false)) -Receipt $receipt -Executor $executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'COMPLETED_DEGRADED'
        ($result.Components | Where-Object Id -EQ 'optional').Outcome | Should -Be 'INSTALLED_DEGRADED'
        ($result.Components | Where-Object Id -EQ 'core').State | Should -Be 'VERIFIED'
    }

    It 'turns verifier exceptions into stable mandatory failures' {
        $receipt = New-TestReceipt
        $result = Invoke-ComponentPlan -Components @((New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier { throw 'boom' } -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'FAILED'
        $result.ErrorCode | Should -Be 'COMPONENT_VERIFIER_EXCEPTION:a:runtime-assets.layout'
        $receipt.components[0].state | Should -Be 'CONFIGURED'
    }

    It 'rejects a verifier result whose Status is not a string' {
        $receipt = New-TestReceipt
        $result = Invoke-ComponentPlan -Components @((New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier { [pscustomobject]@{ Status=$true } } -CheckpointWriter $script:checkpoint
        $result.ErrorCode | Should -Be 'COMPONENT_VERIFIER_RESULT_INVALID:a:runtime-assets.layout'
    }

    It 'reports optional verification failure as PENDING' {
        $receipt = New-TestReceipt
        $result = Invoke-ComponentPlan -Components @((New-TestComponent optional -Required $false)) -Receipt $receipt -Executor $script:executor -Verifier { $false } -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'COMPLETED_DEGRADED'
        $result.Components[0].Outcome | Should -Be 'PENDING'
        $receipt.components[0].state | Should -Be 'CONFIGURED'
    }

    It 'does not expose the removed custom Registry seam' {
        (Get-Command Invoke-ComponentPlan).Parameters.Keys | Should -Not -Contain 'Registry'
    }

    It 'keeps every transition transactional and retries from the unchanged receipt' -TestCases @(
        @{ Start='DETECTED'; Target='PLANNED'; RetryExecutor='a:Install'; RetryVerifier=$true }
        @{ Start='PLANNED'; Target='INSTALLED'; RetryExecutor='a:Install'; RetryVerifier=$true }
        @{ Start='INSTALLED'; Target='CONFIGURED'; RetryExecutor='a:Configure'; RetryVerifier=$true }
        @{ Start='CONFIGURED'; Target='VERIFIED'; RetryExecutor=$null; RetryVerifier=$true }
    ) {
        param($Start,$Target,$RetryExecutor,$RetryVerifier)
        $receipt = New-TestReceipt
        if ($Start -cne 'DETECTED') { $receipt.components = @([pscustomobject]@{ id='a'; state=$Start }) }
        $failingWriter = { param($Candidate) if (($Candidate.components | Where-Object id -EQ 'a').state -ceq $Target) { throw 'disk full' } }

        $failed = Invoke-ComponentPlan -Components @((New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier $script:verifier -CheckpointWriter $failingWriter

        $failed.Status | Should -Be 'FAILED'
        $failed.ErrorCode | Should -Be "COMPONENT_CHECKPOINT_FAILED:a:$Target"
        $failed.Evidence | Should -Be 'disk full'
        if ($Start -ceq 'DETECTED') { @($receipt.components).Count | Should -Be 0 }
        else { $receipt.components[0].state | Should -Be $Start }

        $script:executorCalls.Clear(); $script:verifierCalls.Clear()
        $retry = Invoke-ComponentPlan -Components @((New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $retry.Status | Should -Be 'COMPLETED'
        if ($null -eq $RetryExecutor) { $script:executorCalls.Count | Should -Be 0 }
        else { $script:executorCalls[0] | Should -Be $RetryExecutor }
        if ($RetryVerifier) { $script:verifierCalls | Should -Contain 'a:runtime-assets.layout' }
        $receipt.components[0].state | Should -Be 'VERIFIED'
    }

    It 'uses a private immutable plan and defensive callback copies' {
        $receipt = New-TestReceipt
        $components = @((New-TestComponent a),(New-TestComponent b @('a')))
        $calls = [Collections.Generic.List[string]]::new()
        $executor = {
            param($Component,$Phase)
            [void]$calls.Add("$($Component.id):$Phase")
            if ($Component.id -ceq 'a' -and $Phase -ceq 'Install') {
                $Component.id = 'mutated-current'; $Component.required = $false; $Component.dependencies = @('missing')
                $components[1].id = 'mutated-future'; $components[1].required = $false
                $components[1].dependencies = @('missing'); $components[1].install.allowed = $false
            }
            [pscustomobject]@{ Success=$true }
        }
        $verifier = { param($Id,$Component) $Component.id='mutated-by-verifier'; [pscustomobject]@{ Status='PASS' } }

        $result = Invoke-ComponentPlan -Components $components -Receipt $receipt -Executor $executor -Verifier $verifier -CheckpointWriter $script:checkpoint

        $result.Status | Should -Be 'COMPLETED'
        $calls | Should -Be @('a:Install','a:Configure','b:Install','b:Configure')
        @($result.Components.Id) | Should -Be @('a','b')
        @($receipt.components.Id) | Should -Be @('a','b')
        @($receipt.components.State) | Should -Be @('VERIFIED','VERIFIED')
    }

    It 'does not let an executor downgrade a mandatory failure or change its identity' {
        $receipt = New-TestReceipt
        $executor = { param($Component,$Phase) $Component.required=$false; $Component.id='optional-now'; $false }
        $result = Invoke-ComponentPlan -Components @((New-TestComponent core -Required $true)) -Receipt $receipt -Executor $executor -Verifier $script:verifier -CheckpointWriter $script:checkpoint
        $result.Status | Should -Be 'FAILED'
        $result.ErrorCode | Should -Be 'COMPONENT_EXECUTOR_FAILED:core:Install'
        $receipt.components[0].id | Should -Be 'core'
        $receipt.components[0].state | Should -Be 'PLANNED'
    }

    It 'restores the original receipt when a checkpoint closure mutates it and throws' {
        $receipt = New-TestReceipt
        $receipt.components = @([pscustomobject]@{ id='a'; state='PLANNED' })
        $writer = { param($Candidate) $receipt.components[0].state='VERIFIED'; $receipt.state='FAILED'; throw 'publish failed' }

        $result = Invoke-ComponentPlan -Components @((New-TestComponent a)) -Receipt $receipt -Executor $script:executor -Verifier $script:verifier -CheckpointWriter $writer

        $result.ErrorCode | Should -Be 'COMPONENT_CHECKPOINT_FAILED:a:INSTALLED'
        $receipt.state | Should -Be 'PLANNED'
        $receipt.components[0].state | Should -Be 'PLANNED'
    }
}
