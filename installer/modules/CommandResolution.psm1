Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'ProcessRunner.psm1') -Force

function Get-CommandCandidatePath {
    param([AllowNull()][object]$Candidate)
    if ($null -eq $Candidate) { return $null }
    if ($Candidate -is [string]) { return [string]$Candidate }
    foreach ($property in @('Source','Path','Definition')) {
        if ($null -ne $Candidate.PSObject.Properties[$property] -and -not [string]::IsNullOrWhiteSpace([string]$Candidate.$property)) {
            return [string]$Candidate.$property
        }
    }
    $null
}

function Resolve-SafeWindowsCommand {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name,[scriptblock]$CommandResolver)

    $candidates = if ($PSBoundParameters.ContainsKey('CommandResolver')) { @(& $CommandResolver $Name) } else {
        @(Get-Command -Name $Name -All -CommandType Application,ExternalScript -ErrorAction SilentlyContinue)
    }
    $ranked = [Collections.Generic.List[object]]::new()
    $ordinal = 0
    foreach ($candidate in $candidates) {
        $path = Get-CommandCandidatePath $candidate
        if ([string]::IsNullOrWhiteSpace($path)) { $ordinal++; continue }
        $extension = [IO.Path]::GetExtension($path)
        $priority = switch -Regex ($extension) {
            '^(?i)\.exe$' { 0; break }
            '^(?i)\.cmd$' { 1; break }
            default { $null }
        }
        if ($null -ne $priority) { [void]$ranked.Add([pscustomobject]@{ Path=$path; Priority=$priority; Ordinal=$ordinal }) }
        $ordinal++
    }
    $selected = $ranked | Sort-Object Priority,Ordinal | Select-Object -First 1
    if ($null -ne $selected) { return [string]$selected.Path }
    $null
}

function Get-UvToolBinDirectory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$UvPath,[scriptblock]$ProcessInvoker)
    $invoke = if ($PSBoundParameters.ContainsKey('ProcessInvoker')) { $ProcessInvoker } else {
        { param($FilePath,$Arguments) Invoke-SafeProcess -FilePath $FilePath -Arguments $Arguments }
    }
    $result = & $invoke $UvPath ([string[]]@('tool','dir','--bin'))
    if ($null -eq $result -or $result -is [string] -or $result -is [bool] -or
        $null -eq $result.PSObject.Properties['ExitCode'] -or $result.ExitCode -ne 0 -or
        $result.StdOut -isnot [string] -or $result.StdErr -isnot [string]) { return $null }
    $output = $result.StdOut.Trim()
    if ([string]::IsNullOrWhiteSpace($output) -or $output -match '[\r\n]' -or -not [IO.Path]::IsPathFullyQualified($output)) { return $null }
    [IO.Path]::GetFullPath($output)
}

function Resolve-UvToolExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ToolName,
        [string]$UvPath,
        [scriptblock]$CommandResolver,
        [scriptblock]$ProcessInvoker,
        [switch]$AllowMissing
    )
    $resolvedUv = if (-not [string]::IsNullOrWhiteSpace($UvPath)) { $UvPath } else {
        $args = @{ Name='uv' }
        if ($PSBoundParameters.ContainsKey('CommandResolver')) { $args.CommandResolver=$CommandResolver }
        Resolve-SafeWindowsCommand @args
    }
    if ([string]::IsNullOrWhiteSpace($resolvedUv)) { return $null }
    $binArgs = @{ UvPath=$resolvedUv }
    if ($PSBoundParameters.ContainsKey('ProcessInvoker')) { $binArgs.ProcessInvoker=$ProcessInvoker }
    $bin = Get-UvToolBinDirectory @binArgs
    if ([string]::IsNullOrWhiteSpace($bin)) { return $null }
    $target = Join-Path $bin ($ToolName + '.exe')
    if (-not $AllowMissing -and -not (Test-Path -LiteralPath $target -PathType Leaf)) { return $null }
    [IO.Path]::GetFullPath($target)
}

Export-ModuleMember -Function Resolve-SafeWindowsCommand, Get-UvToolBinDirectory, Resolve-UvToolExecutable
