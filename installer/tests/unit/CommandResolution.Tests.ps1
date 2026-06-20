$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    Import-Module (Join-Path $repoRoot 'installer/modules/CommandResolution.psm1') -Force
}

Describe 'deterministic Windows command resolution' {
    It 'rejects ps1-only shims and prefers exe then cmd independently of discovery order' {
        (Resolve-SafeWindowsCommand -Name 'tool' -CommandResolver { @('tool.ps1') }) | Should -BeNullOrEmpty
        Resolve-SafeWindowsCommand -Name 'tool' -CommandResolver { @('tool.ps1','tool.cmd') } | Should -Be 'tool.cmd'
        Resolve-SafeWindowsCommand -Name 'tool' -CommandResolver { @('tool.ps1','tool.cmd','tool.exe') } | Should -Be 'tool.exe'
    }

    It 'derives a rooted uv-owned executable and never consults a same-name PATH tool' {
        $bin=Join-Path $TestDrive 'uv-bin'; New-Item -ItemType Directory $bin|Out-Null
        $target=Join-Path $bin 'graphify.exe'; Set-Content $target 'fixture'
        $calls=[Collections.Generic.List[string]]::new()
        $resolved=Resolve-UvToolExecutable -ToolName 'graphify' -UvPath 'uv.exe' -ProcessInvoker {
            param($file,$arguments); $calls.Add("$file $(@($arguments)-join ' ')"); [pscustomobject]@{ExitCode=0;StdOut=$bin;StdErr=''}
        }.GetNewClosure()
        $resolved | Should -Be ([IO.Path]::GetFullPath($target))
        $calls | Should -Be @('uv.exe tool dir --bin')
    }

    It 'fails closed for relative, multiline, failed, and missing uv tool targets' {
        Get-UvToolBinDirectory -UvPath 'uv.exe' -ProcessInvoker { [pscustomobject]@{ExitCode=0;StdOut='relative';StdErr=''} } | Should -BeNullOrEmpty
        Get-UvToolBinDirectory -UvPath 'uv.exe' -ProcessInvoker { [pscustomobject]@{ExitCode=0;StdOut="$TestDrive`n$TestDrive";StdErr=''} } | Should -BeNullOrEmpty
        Get-UvToolBinDirectory -UvPath 'uv.exe' -ProcessInvoker { [pscustomobject]@{ExitCode=1;StdOut='';StdErr='failed'} } | Should -BeNullOrEmpty
        Resolve-UvToolExecutable -ToolName 'missing' -UvPath 'uv.exe' -ProcessInvoker { [pscustomobject]@{ExitCode=0;StdOut=$TestDrive;StdErr=''} } | Should -BeNullOrEmpty
    }
}
