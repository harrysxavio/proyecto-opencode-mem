$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $sourceBootstrapPath = Join-Path $repoRoot 'installer/bootstrap.ps1'
    $isolatedInstallerRoot = Join-Path $TestDrive 'installer'
    $bootstrapPath = Join-Path $isolatedInstallerRoot 'bootstrap.ps1'
    $commandsRoot = Join-Path $isolatedInstallerRoot 'commands'
    New-Item -ItemType Directory -Path $commandsRoot -Force | Out-Null
    Copy-Item -LiteralPath $sourceBootstrapPath -Destination $bootstrapPath
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
    [string]$ReceiptPath,
    [switch]$Resume,
    [switch]$NonInteractive,
    [switch]$Json,
    [switch]$ConfirmInstall,
    [switch]$ConfirmRollback
)
[pscustomobject]@{
    HandlerPath = $PSCommandPath
    Project = $Project
    ReceiptPath = $ReceiptPath
    Resume = [bool]$Resume
    NonInteractive = [bool]$NonInteractive
    Json = [bool]$Json
    ConfirmInstall = [bool]$ConfirmInstall
    ConfirmRollback = [bool]$ConfirmRollback
}
'@ | Set-Content -LiteralPath $handlerPath

        try {
            $result = & $bootstrapPath -Project 'project path with spaces' -Resume -NonInteractive -Json -ConfirmInstall
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
        $result.ConfirmInstall | Should -BeTrue
    }

    It 'forwards rollback receipt and confirmation only as structured parameters' {
        $handlerPath = Join-Path $commandsRoot 'rollback.ps1'
        @'
param([string]$ReceiptPath, [switch]$NonInteractive, [switch]$Json, [switch]$ConfirmRollback)
[pscustomobject]@{ ReceiptPath = $ReceiptPath; NonInteractive = [bool]$NonInteractive; Json = [bool]$Json; ConfirmRollback = [bool]$ConfirmRollback }
'@ | Set-Content -LiteralPath $handlerPath
        try { $result = & $bootstrapPath rollback -ReceiptPath 'path with spaces.json' -NonInteractive -Json -ConfirmRollback }
        finally { Remove-Item -LiteralPath $handlerPath -Force -ErrorAction SilentlyContinue }
        $result.ReceiptPath | Should -Be 'path with spaces.json'
        $result.NonInteractive | Should -BeTrue
        $result.Json | Should -BeTrue
        $result.ConfirmRollback | Should -BeTrue
    }
}
