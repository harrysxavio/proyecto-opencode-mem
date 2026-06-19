Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Receipt.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Verification.psm1') -Force

$script:ComponentStates = @('DETECTED','PLANNED','INSTALLED','CONFIGURED','VERIFIED')

function Assert-StateTransition {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$From,[Parameter(Mandatory)][string]$To)
    $index = [array]::IndexOf($script:ComponentStates, $From)
    if ($index -lt 0 -or $index -ge ($script:ComponentStates.Count - 1) -or $script:ComponentStates[$index + 1] -cne $To) {
        throw "COMPONENT_STATE_INVALID:$From`:$To"
    }
}

function Resolve-ComponentOrder {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Components)
    $byId = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach ($component in $Components) {
        $id = if ($null -ne $component.PSObject.Properties['id']) { [string]$component.id } else { '' }
        if ([string]::IsNullOrWhiteSpace($id)) { throw 'COMPONENT_ID_INVALID' }
        if ($byId.ContainsKey($id)) { throw "COMPONENT_DUPLICATE_ID:$id" }
        $byId.Add($id, $component)
    }
    foreach ($component in $Components) {
        foreach ($dependency in @($component.dependencies)) {
            if (-not $byId.ContainsKey([string]$dependency)) { throw "COMPONENT_DEPENDENCY_UNKNOWN:$($component.id):$dependency" }
        }
    }
    $remaining = [Collections.Generic.HashSet[string]]::new($byId.Keys, [StringComparer]::Ordinal)
    $done = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $ordered = [Collections.Generic.List[object]]::new()
    while ($remaining.Count -gt 0) {
        $progress = $false
        foreach ($component in $Components) {
            if (-not $remaining.Contains([string]$component.id)) { continue }
            $ready = $true
            foreach ($dependency in @($component.dependencies)) { if (-not $done.Contains([string]$dependency)) { $ready = $false; break } }
            if ($ready) {
                [void]$ordered.Add($component)
                [void]$done.Add([string]$component.id)
                [void]$remaining.Remove([string]$component.id)
                $progress = $true
            }
        }
        if (-not $progress) { throw 'COMPONENT_DEPENDENCY_CYCLE' }
    }
    $ordered.ToArray()
}

function Get-ReceiptComponentState {
    param([object]$Receipt,[string]$Id)
    $match = @($Receipt.components | Where-Object { $_.id -ceq $Id })
    if ($match.Count -eq 0) { return 'DETECTED' }
    [string]$match[0].state
}

function Copy-RunnerValue {
    param([Parameter(Mandatory)][object]$Value)
    $Value | ConvertTo-Json -Depth 50 -Compress | ConvertFrom-Json -Depth 50 -DateKind String
}

function Restore-RunnerValue {
    param([Parameter(Mandatory)][object]$Target,[Parameter(Mandatory)][object]$Snapshot)
    $snapshotNames = @($Snapshot.PSObject.Properties.Name)
    foreach ($name in @($Target.PSObject.Properties.Name)) {
        if ($snapshotNames -cnotcontains $name) { $Target.PSObject.Properties.Remove($name) }
    }
    foreach ($property in $Snapshot.PSObject.Properties) {
        $value = $property.Value
        if ($null -eq $Target.PSObject.Properties[$property.Name]) {
            Add-Member -InputObject $Target -MemberType NoteProperty -Name $property.Name -Value $value
        }
        else { $Target.PSObject.Properties[$property.Name].Value = $value }
    }
}

function Invoke-ComponentStateCheckpoint {
    param([object]$Receipt,[object]$Component,[string]$From,[string]$To,[object]$Evidence,[scriptblock]$CheckpointWriter)
    [void](Assert-StateTransition -From $From -To $To)
    $baseline = Copy-RunnerValue $Receipt
    $candidate = Copy-RunnerValue $baseline
    Set-ReceiptComponentState -Receipt $candidate -Id $Component.id -State $To
    $failure = $null
    try {
        [void](Assert-InstallReceipt $candidate)
        & $CheckpointWriter $candidate
        [void](Assert-InstallReceipt $candidate)
        if ((Get-ReceiptComponentState $candidate $Component.id) -cne $To) { throw 'checkpoint candidate state changed' }
    }
    catch {
        $failure = [pscustomobject]@{ Success=$false; ErrorCode="COMPONENT_CHECKPOINT_FAILED:$($Component.id):$To"; Evidence=$_.Exception.Message }
    }
    finally { Restore-RunnerValue -Target $Receipt -Snapshot $baseline }
    if ($null -ne $failure) { return $failure }
    Set-ReceiptComponentState -Receipt $Receipt -Id $Component.id -State $To
    [pscustomobject]@{ Success=$true; ErrorCode=$null; Evidence=$Evidence }
}

function Get-TypedOperationResult {
    param([object]$Result,[string]$InvalidCode,[string]$FalseCode)
    if ($Result -is [bool]) {
        if (-not $Result) { return [pscustomobject]@{ Success=$false; ErrorCode=$FalseCode; Evidence=$null } }
        return [pscustomobject]@{ Success=$false; ErrorCode=$InvalidCode; Evidence=$null }
    }
    if ($null -eq $Result -or $Result -is [string] -or $null -eq $Result.PSObject.Properties['Success'] -or $Result.Success -isnot [bool]) {
        return [pscustomobject]@{ Success=$false; ErrorCode=$InvalidCode; Evidence=$null }
    }
    [pscustomobject]@{ Success=[bool]$Result.Success; ErrorCode=if ($Result.Success) { $null } else { $FalseCode }; Evidence=if ($null -ne $Result.PSObject.Properties['Evidence']) { $Result.Evidence } else { $null } }
}

function New-PlanResult {
    param([string]$Status,[string]$ErrorCode,[object]$Evidence,[object[]]$Components)
    [pscustomobject][ordered]@{ Status=$Status; ErrorCode=$ErrorCode; Evidence=$Evidence; Components=@($Components) }
}

function Invoke-ComponentPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Components,
        [Parameter(Mandatory)][object]$Receipt,
        [Parameter(Mandatory)][scriptblock]$Executor,
        [scriptblock]$Verifier,
        [Parameter(Mandatory)][scriptblock]$CheckpointWriter
    )
    [void](Assert-InstallReceipt $Receipt)
    $privateComponents = @($Components | ForEach-Object { Copy-RunnerValue $_ })
    $ordered = @(Resolve-ComponentOrder -Components $privateComponents)
    $verify = if ($PSBoundParameters.ContainsKey('Verifier')) { $Verifier } else {
        { param($Id,$Component) Invoke-VerificationId -Id $Id -ExpectedVersion $Component.version }
    }
    $outcomes = [Collections.Generic.List[object]]::new()
    $degraded = $false

    foreach ($component in $ordered) {
        $state = Get-ReceiptComponentState $Receipt $component.id
        if ($state -ceq 'VERIFIED') {
            [void]$outcomes.Add([pscustomobject]@{ Id=$component.id; State='VERIFIED'; Outcome='VERIFIED'; ErrorCode=$null; Evidence=$null })
            continue
        }
        if ($script:ComponentStates -cnotcontains $state) { return New-PlanResult 'FAILED' "COMPONENT_STATE_INVALID:$state" $null $outcomes.ToArray() }

        if ($state -ceq 'DETECTED') {
            $transition = Invoke-ComponentStateCheckpoint $Receipt $component 'DETECTED' 'PLANNED' $null $CheckpointWriter
            if (-not $transition.Success) { return New-PlanResult 'FAILED' $transition.ErrorCode $transition.Evidence $outcomes.ToArray() }
            $state = 'PLANNED'
        }
        if ($state -ceq 'PLANNED') {
            foreach ($dependency in @($component.dependencies)) {
                if ((Get-ReceiptComponentState $Receipt $dependency) -cne 'VERIFIED') {
                    $code = "COMPONENT_DEPENDENCY_NOT_VERIFIED:$($component.id):$dependency"
                    if ($component.required) { return New-PlanResult 'FAILED' $code $null $outcomes.ToArray() }
                    $degraded = $true; [void]$outcomes.Add([pscustomobject]@{ Id=$component.id; State=$state; Outcome='PENDING'; ErrorCode=$code; Evidence=$null }); continue 2
                }
            }
            if (-not $component.install.allowed) {
                $code = "COMPONENT_INSTALL_BLOCKED:$($component.id)"
                if ($component.required) { return New-PlanResult 'FAILED' $code $null $outcomes.ToArray() }
                $degraded = $true; [void]$outcomes.Add([pscustomobject]@{ Id=$component.id; State=$state; Outcome='PENDING'; ErrorCode=$code; Evidence=$null }); continue
            }
            $operation = $null; $raw = $null
            try { $raw = & $Executor (Copy-RunnerValue $component) 'Install' }
            catch { $operation = [pscustomobject]@{ Success=$false; ErrorCode="COMPONENT_EXECUTOR_EXCEPTION:$($component.id):Install"; Evidence=$_.Exception.Message } }
            if ($null -eq $operation) { $operation = Get-TypedOperationResult $raw "COMPONENT_EXECUTOR_RESULT_INVALID:$($component.id):Install" "COMPONENT_EXECUTOR_FAILED:$($component.id):Install" }
            if (-not $operation.Success) {
                if ($component.required) { return New-PlanResult 'FAILED' $operation.ErrorCode $operation.Evidence $outcomes.ToArray() }
                $degraded = $true; [void]$outcomes.Add([pscustomobject]@{ Id=$component.id; State=$state; Outcome='PENDING'; ErrorCode=$operation.ErrorCode; Evidence=$operation.Evidence }); continue
            }
            $transition = Invoke-ComponentStateCheckpoint $Receipt $component 'PLANNED' 'INSTALLED' $operation.Evidence $CheckpointWriter
            if (-not $transition.Success) { return New-PlanResult 'FAILED' $transition.ErrorCode $transition.Evidence $outcomes.ToArray() }
            $state = 'INSTALLED'; $operation = $null; $raw = $null
        }
        if ($state -ceq 'INSTALLED') {
            $operation = $null; $raw = $null
            try { $raw = & $Executor (Copy-RunnerValue $component) 'Configure' }
            catch { $operation = [pscustomobject]@{ Success=$false; ErrorCode="COMPONENT_EXECUTOR_EXCEPTION:$($component.id):Configure"; Evidence=$_.Exception.Message } }
            if ($null -eq $operation) { $operation = Get-TypedOperationResult $raw "COMPONENT_EXECUTOR_RESULT_INVALID:$($component.id):Configure" "COMPONENT_EXECUTOR_FAILED:$($component.id):Configure" }
            if (-not $operation.Success) {
                if ($component.required) { return New-PlanResult 'FAILED' $operation.ErrorCode $operation.Evidence $outcomes.ToArray() }
                $degraded = $true; [void]$outcomes.Add([pscustomobject]@{ Id=$component.id; State=$state; Outcome='INSTALLED_DEGRADED'; ErrorCode=$operation.ErrorCode; Evidence=$operation.Evidence }); continue
            }
            $transition = Invoke-ComponentStateCheckpoint $Receipt $component 'INSTALLED' 'CONFIGURED' $operation.Evidence $CheckpointWriter
            if (-not $transition.Success) { return New-PlanResult 'FAILED' $transition.ErrorCode $transition.Evidence $outcomes.ToArray() }
            $state = 'CONFIGURED'; $operation = $null; $raw = $null
        }
        if ($state -ceq 'CONFIGURED') {
            $verificationEvidence = [Collections.Generic.List[object]]::new()
            $verificationFailure = $null
            foreach ($verificationId in @($component.verificationIds)) {
                try { $verification = & $verify $verificationId (Copy-RunnerValue $component) }
                catch { $verificationFailure = [pscustomobject]@{ ErrorCode="COMPONENT_VERIFIER_EXCEPTION:$($component.id):$verificationId"; Evidence=$_.Exception.Message }; break }
                if ($verification -is [bool]) {
                    $code = if ($verification) { 'COMPONENT_VERIFIER_RESULT_INVALID' } else { 'COMPONENT_VERIFIER_FAILED' }
                    $verificationFailure = [pscustomobject]@{ ErrorCode="$code`:$($component.id):$verificationId"; Evidence=$null }; break
                }
                if ($null -eq $verification -or $verification -is [array] -or $verification -is [string] -or
                    $null -eq $verification.PSObject.Properties['Status'] -or $verification.Status -isnot [string]) {
                    $verificationFailure = [pscustomobject]@{ ErrorCode="COMPONENT_VERIFIER_RESULT_INVALID:$($component.id):$verificationId"; Evidence=$null }; break
                }
                [void]$verificationEvidence.Add($verification)
                if ($verification.Status -cne 'PASS') {
                    $code = if ($null -ne $verification.PSObject.Properties['ErrorCode'] -and -not [string]::IsNullOrWhiteSpace([string]$verification.ErrorCode)) { [string]$verification.ErrorCode } else { 'COMPONENT_VERIFIER_FAILED' }
                    $evidence = if ($null -ne $verification.PSObject.Properties['Evidence']) { $verification.Evidence } else { $null }
                    $verificationFailure = [pscustomobject]@{ ErrorCode="$code`:$($component.id):$verificationId"; Evidence=$evidence }; break
                }
            }
            if ($null -ne $verificationFailure) {
                if ($component.required) { return New-PlanResult 'FAILED' $verificationFailure.ErrorCode $verificationFailure.Evidence $outcomes.ToArray() }
                $degraded = $true; [void]$outcomes.Add([pscustomobject]@{ Id=$component.id; State=$state; Outcome='PENDING'; ErrorCode=$verificationFailure.ErrorCode; Evidence=$verificationFailure.Evidence }); continue
            }
            $transition = Invoke-ComponentStateCheckpoint $Receipt $component 'CONFIGURED' 'VERIFIED' $verificationEvidence.ToArray() $CheckpointWriter
            if (-not $transition.Success) { return New-PlanResult 'FAILED' $transition.ErrorCode $transition.Evidence $outcomes.ToArray() }
            $state = 'VERIFIED'
        }
        [void]$outcomes.Add([pscustomobject]@{ Id=$component.id; State=$state; Outcome='VERIFIED'; ErrorCode=$null; Evidence=$null })
    }
    New-PlanResult $(if ($degraded) { 'COMPLETED_DEGRADED' } else { 'COMPLETED' }) $null $null $outcomes.ToArray()
}

Export-ModuleMember -Function Assert-StateTransition, Resolve-ComponentOrder, Invoke-ComponentPlan
