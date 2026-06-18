$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $bootstrapPath = Join-Path $repoRoot 'installer/bootstrap.ps1'
    $commandsRoot = Join-Path $repoRoot 'installer/commands'
    New-Item -ItemType Directory -Path $commandsRoot -Force | Out-Null
}

Describe 'bootstrap command router' {
    It 'rejects an unsupported command with a stable code, including traversal input' {
        { & $bootstrapPath 'unsupported' } | Should -Throw 'COMMAND_UNSUPPORTED:unsupported'
        { & $bootstrapPath '../install' } | Should -Throw 'COMMAND_UNSUPPORTED:../install'
    }

    It 'reports a known command whose handler is missing' {
        $handlerPath = Join-Path $commandsRoot 'doctor.ps1'
        Remove-Item -LiteralPath $handlerPath -Force -ErrorAction SilentlyContinue

        { & $bootstrapPath doctor } | Should -Throw 'COMMAND_HANDLER_MISSING:doctor'
    }

    It 'routes the default command to a controlled handler under installer commands and forwards structured parameters' {
        $handlerPath = Join-Path $commandsRoot 'install.ps1'
        @'
param(
    [string]$Project,
    [switch]$Resume,
    [switch]$NonInteractive,
    [switch]$Json
)
[pscustomobject]@{
    HandlerPath = $PSCommandPath
    Project = $Project
    Resume = [bool]$Resume
    NonInteractive = [bool]$NonInteractive
    Json = [bool]$Json
}
'@ | Set-Content -LiteralPath $handlerPath

        try {
            $result = & $bootstrapPath -Project 'project path with spaces' -Resume -NonInteractive -Json
        }
        finally {
            Remove-Item -LiteralPath $handlerPath -Force -ErrorAction SilentlyContinue
        }

        [IO.Path]::GetFullPath($result.HandlerPath) | Should -Be ([IO.Path]::GetFullPath($handlerPath))
        [IO.Path]::GetFullPath($result.HandlerPath).StartsWith(([IO.Path]::GetFullPath($commandsRoot) + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase) | Should -BeTrue
        $result.Project | Should -Be 'project path with spaces'
        $result.Resume | Should -BeTrue
        $result.NonInteractive | Should -BeTrue
        $result.Json | Should -BeTrue
    }
}
