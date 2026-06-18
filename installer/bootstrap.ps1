[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'install',

    [string]$Project,
    [switch]$Resume,
    [switch]$NonInteractive,
    [switch]$Json,
    [switch]$ConfirmInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$allowedCommands = @('install', 'doctor', 'status', 'configure', 'onboard', 'rollback')
if ($allowedCommands -cnotcontains $Command) {
    throw "COMMAND_UNSUPPORTED:$Command"
}

$commandsRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'commands'))
$handlerPath = [IO.Path]::GetFullPath((Join-Path $commandsRoot "$Command.ps1"))
$commandsPrefix = $commandsRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $handlerPath.StartsWith($commandsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "COMMAND_UNSUPPORTED:$Command"
}
if (-not (Test-Path -LiteralPath $handlerPath -PathType Leaf)) {
    throw "COMMAND_HANDLER_MISSING:$Command"
}

$handlerParameters = @{}
foreach ($name in @('Project', 'Resume', 'NonInteractive', 'Json', 'ConfirmInstall')) {
    if ($PSBoundParameters.ContainsKey($name)) {
        $handlerParameters[$name] = $PSBoundParameters[$name]
    }
}

& $handlerPath @handlerParameters
