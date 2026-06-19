Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'ProcessRunner.psm1') -Force

$script:VerificationRegistry = @(
    [pscustomobject][ordered]@{ Id='git.version'; Kind='version'; Command='git'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='node.version'; Kind='version'; Command='node'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='pnpm.version'; Kind='version'; Command='pnpm'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='python.version'; Kind='version'; Command='python'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='uv.version'; Kind='version'; Command='uv'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='opencode.version'; Kind='version'; Command='opencode'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='engram.version'; Kind='version'; Command='engram'; Arguments=@('version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='graphify.version'; Kind='version'; Command='graphify'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='context7.version'; Kind='version'; Command='context7'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='playwright.version'; Kind='version'; Command='playwright'; Arguments=@('--version'); Handler=$null }
    [pscustomobject][ordered]@{ Id='engram.persist'; Kind='functional'; Command=$null; Arguments=@(); Handler='engram.persist' }
    [pscustomobject][ordered]@{ Id='graphify.query'; Kind='functional'; Command=$null; Arguments=@(); Handler='graphify.query' }
    [pscustomobject][ordered]@{ Id='mcp.context7'; Kind='functional'; Command=$null; Arguments=@(); Handler='mcp.context7' }
    [pscustomobject][ordered]@{ Id='mcp.playwright'; Kind='functional'; Command=$null; Arguments=@(); Handler='mcp.playwright' }
    [pscustomobject][ordered]@{ Id='runtime-assets.layout'; Kind='functional'; Command=$null; Arguments=@(); Handler='runtime-assets.layout' }
    [pscustomobject][ordered]@{ Id='config.github'; Kind='functional'; Command=$null; Arguments=@(); Handler='config.github' }
    [pscustomobject][ordered]@{ Id='config.supabase'; Kind='functional'; Command=$null; Arguments=@(); Handler='config.supabase' }
    [pscustomobject][ordered]@{ Id='config.notebooklm'; Kind='functional'; Command=$null; Arguments=@(); Handler='config.notebooklm' }
    [pscustomobject][ordered]@{ Id='config.browserbase'; Kind='functional'; Command=$null; Arguments=@(); Handler='config.browserbase' }
)

function Copy-VerificationDescriptor {
    param([Parameter(Mandatory)][object]$Descriptor)
    [pscustomobject][ordered]@{
        Id = [string]$Descriptor.Id
        Kind = [string]$Descriptor.Kind
        Command = if ($null -eq $Descriptor.Command) { $null } else { [string]$Descriptor.Command }
        Arguments = [string[]]@($Descriptor.Arguments | ForEach-Object { [string]$_ })
        Handler = if ($null -eq $Descriptor.Handler) { $null } else { [string]$Descriptor.Handler }
    }
}

function Get-VerificationRegistry {
    [CmdletBinding()]
    param()
    foreach ($entry in $script:VerificationRegistry) { Copy-VerificationDescriptor $entry }
}

function New-VerificationResult {
    param([string]$Id,[string]$Status,[string]$ErrorCode,[object]$Evidence,[string]$ExpectedVersion,[string]$ActualVersion)
    [pscustomobject][ordered]@{
        Id = $Id
        Status = $Status
        ErrorCode = $ErrorCode
        Evidence = $Evidence
        ExpectedVersion = $ExpectedVersion
        ActualVersion = $ActualVersion
    }
}

function Get-NormalizedVersion {
    param([AllowEmptyString()][string]$Text)
    $match = [regex]::Match($Text, '(?<![0-9A-Za-z])v?(?<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)')
    if (-not $match.Success) { return $null }
    $match.Groups['version'].Value
}

function Test-TypedSuccessResult {
    param([object]$Result)
    $null -ne $Result -and $Result -isnot [bool] -and $Result -isnot [string] -and
        $null -ne $Result.PSObject.Properties['Success'] -and $Result.Success -is [bool]
}

function Invoke-VerificationProcess {
    param([string]$FilePath,[string[]]$Arguments,[System.Collections.IDictionary]$Environment,[scriptblock]$ProcessInvoker)
    if ($null -ne $ProcessInvoker) { return & $ProcessInvoker $FilePath $Arguments $Environment }
    $saved = @{}
    try {
        foreach ($key in $Environment.Keys) {
            $saved[$key] = [Environment]::GetEnvironmentVariable([string]$key, 'Process')
            [Environment]::SetEnvironmentVariable([string]$key, [string]$Environment[$key], 'Process')
        }
        Invoke-SafeProcess -FilePath $FilePath -Arguments $Arguments
    }
    finally { foreach ($key in $Environment.Keys) { [Environment]::SetEnvironmentVariable([string]$key, $saved[$key], 'Process') } }
}

function Test-EngramPersistence {
    [CmdletBinding()]
    param([string]$EngramPath='engram',[string]$TempRoot=([IO.Path]::GetTempPath()),[scriptblock]$ProcessInvoker)
    $work = Join-Path ([IO.Path]::GetFullPath($TempRoot)) ('engram-probe-' + [guid]::NewGuid().ToString('N'))
    $data = Join-Path $work 'data'; $canary = 'engram-canary-' + [guid]::NewGuid().ToString('N')
    try {
        New-Item -ItemType Directory -Path $data -Force | Out-Null
        $environment = @{ ENGRAM_DATA_DIR=$data }
        $save = Invoke-VerificationProcess $EngramPath @('save',$canary,$canary,'--type','discovery','--project','opencode-kit-verification','--scope','project') $environment $ProcessInvoker
        if ($null -eq $save -or $save.ExitCode -ne 0) { return [pscustomobject]@{ Success=$false; Evidence=[pscustomobject]@{ Stage='save'; Error=$save.StdErr } } }
        $search = Invoke-VerificationProcess $EngramPath @('search',$canary,'--project','opencode-kit-verification','--limit','5') $environment $ProcessInvoker
        $found = $null -ne $search -and $search.ExitCode -eq 0 -and (($search.StdOut + "`n" + $search.StdErr).Contains($canary, [StringComparison]::Ordinal))
        [pscustomobject]@{ Success=[bool]$found; Evidence=[pscustomobject]@{ Stage='restart-search'; CanaryFound=[bool]$found; Invocations=2 } }
    }
    catch { [pscustomobject]@{ Success=$false; Evidence=[pscustomobject]@{ Stage='exception'; Error=$_.Exception.Message } } }
    finally { if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } }
}

function Test-GraphifyFixture {
    [CmdletBinding()]
    param(
        [string]$GraphifyPath='graphify',
        [string]$FixturePath=(Join-Path $PSScriptRoot '../tests/e2e/fixtures/graphify/sample.js'),
        [string]$TempRoot=([IO.Path]::GetTempPath()),
        [scriptblock]$ProcessInvoker
    )
    $work = Join-Path ([IO.Path]::GetFullPath($TempRoot)) ('graphify-probe-' + [guid]::NewGuid().ToString('N'))
    $invoke = if ($PSBoundParameters.ContainsKey('ProcessInvoker')) { $ProcessInvoker } else { { param($FilePath,$Arguments) Invoke-SafeProcess -FilePath $FilePath -Arguments $Arguments } }
    try {
        New-Item -ItemType Directory -Path $work -Force | Out-Null
        Copy-Item -LiteralPath $FixturePath -Destination (Join-Path $work 'sample.js')
        $build = & $invoke $GraphifyPath ([string[]]@('extract',$work,'--no-cluster'))
        if ($null -eq $build -or $build.ExitCode -ne 0) { return [pscustomobject]@{ Success=$false; Evidence=[pscustomobject]@{ Stage='extract'; Error=$build.StdErr } } }
        $graph = Join-Path $work 'graphify-out/graph.json'
        if (-not (Test-Path -LiteralPath $graph -PathType Leaf)) { return [pscustomobject]@{ Success=$false; Evidence=[pscustomobject]@{ Stage='extract'; Error='graph.json missing' } } }
        $query = & $invoke $GraphifyPath ([string[]]@('query','hello','--graph',$graph))
        $found = $null -ne $query -and $query.ExitCode -eq 0 -and (($query.StdOut + "`n" + $query.StdErr) -cmatch 'hello')
        [pscustomobject]@{ Success=[bool]$found; Evidence=[pscustomobject]@{ Stage='query'; HelloFound=[bool]$found; Invocations=2 } }
    }
    catch { [pscustomobject]@{ Success=$false; Evidence=[pscustomobject]@{ Stage='exception'; Error=$_.Exception.Message } } }
    finally { if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } }
}

function Invoke-VerificationId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$ExpectedVersion,
        [scriptblock]$ProcessInvoker,
        [System.Collections.IDictionary]$ProbeHandlers
    )

    $matches = @($script:VerificationRegistry | Where-Object { $_.Id -ceq $Id })
    if ($matches.Count -ne 1) { throw "VERIFICATION_ID_UNKNOWN:$Id" }
    $descriptor = $matches[0]

    if ($descriptor.Kind -ceq 'version') {
        if ([string]::IsNullOrWhiteSpace($ExpectedVersion)) {
            return New-VerificationResult $Id 'FAIL' 'VERIFICATION_EXPECTED_VERSION_REQUIRED' $null $ExpectedVersion $null
        }
        $invoker = if ($PSBoundParameters.ContainsKey('ProcessInvoker')) { $ProcessInvoker } else {
            { param($FilePath,$Arguments) Invoke-SafeProcess -FilePath $FilePath -Arguments $Arguments }
        }
        $processArguments = [string[]]@($descriptor.Arguments | ForEach-Object { [string]$_ })
        try { $processResult = & $invoker $descriptor.Command $processArguments }
        catch { return New-VerificationResult $Id 'FAIL' 'VERIFICATION_PROCESS_EXCEPTION' $_.Exception.Message $ExpectedVersion $null }
        $typedProcessResult = $null -ne $processResult -and $processResult -isnot [bool] -and $processResult -isnot [string]
        if ($typedProcessResult) {
            $typedProcessResult = $null -ne $processResult.PSObject.Properties['ExitCode'] -and
                $null -ne $processResult.PSObject.Properties['StdOut'] -and
                $null -ne $processResult.PSObject.Properties['StdErr']
        }
        if ($typedProcessResult) {
            $typedProcessResult = ($processResult.ExitCode -is [int] -or $processResult.ExitCode -is [long]) -and
                $processResult.StdOut -is [string] -and $processResult.StdErr -is [string]
        }
        if (-not $typedProcessResult) {
            return New-VerificationResult $Id 'FAIL' 'VERIFICATION_RESULT_INVALID' $null $ExpectedVersion $null
        }
        if ($processResult.ExitCode -ne 0) {
            return New-VerificationResult $Id 'FAIL' 'VERIFICATION_PROCESS_FAILED' $processResult.StdErr $ExpectedVersion $null
        }
        $actual = Get-NormalizedVersion ($processResult.StdOut + "`n" + $processResult.StdErr)
        if ($null -eq $actual) { return New-VerificationResult $Id 'FAIL' 'VERIFICATION_VERSION_UNPARSEABLE' $processResult.StdOut $ExpectedVersion $null }
        if ($actual -cne $ExpectedVersion) { return New-VerificationResult $Id 'FAIL' 'VERIFICATION_VERSION_MISMATCH' $processResult.StdOut $ExpectedVersion $actual }
        return New-VerificationResult $Id 'PASS' $null $processResult.StdOut $ExpectedVersion $actual
    }

    if ($null -eq $ProbeHandlers) {
        $ProbeHandlers = @{
            'engram.persist' = { Test-EngramPersistence }
            'graphify.query' = { Test-GraphifyFixture }
        }
    }
    if (-not $ProbeHandlers.Contains($descriptor.Handler) -or $ProbeHandlers[$descriptor.Handler] -isnot [scriptblock]) {
        return New-VerificationResult $Id 'NOT_READY' 'VERIFICATION_HANDLER_MISSING' $null $null $null
    }
    $handlerDescriptor = Copy-VerificationDescriptor $descriptor
    try { $probeResult = & $ProbeHandlers[$descriptor.Handler] $handlerDescriptor }
    catch { return New-VerificationResult $Id 'FAIL' 'VERIFICATION_PROBE_EXCEPTION' $_.Exception.Message $null $null }
    if ($probeResult -is [bool]) {
        if (-not $probeResult) { return New-VerificationResult $Id 'FAIL' 'VERIFICATION_PROBE_FAILED' $null $null $null }
        return New-VerificationResult $Id 'FAIL' 'VERIFICATION_RESULT_INVALID' $null $null $null
    }
    if (-not (Test-TypedSuccessResult $probeResult)) { return New-VerificationResult $Id 'FAIL' 'VERIFICATION_RESULT_INVALID' $null $null $null }
    $evidence = if ($null -ne $probeResult.PSObject.Properties['Evidence']) { $probeResult.Evidence } else { $null }
    if (-not $probeResult.Success) { return New-VerificationResult $Id 'FAIL' 'VERIFICATION_PROBE_FAILED' $evidence $null $null }
    New-VerificationResult $Id 'PASS' $null $evidence $null $null
}

Export-ModuleMember -Function Get-VerificationRegistry, Invoke-VerificationId, Test-EngramPersistence, Test-GraphifyFixture
