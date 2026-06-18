$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $modulePath = Join-Path $repoRoot 'installer/modules/ProcessRunner.psm1'
    Import-Module $modulePath -Force
    $pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
}

Describe 'Invoke-SafeProcess' {
    It 'captures standard output' {
        $scriptPath = Join-Path $TestDrive 'stdout.ps1'
        "Write-Output 'runner stdout'" | Set-Content -LiteralPath $scriptPath

        $result = Invoke-SafeProcess -FilePath $pwshPath -Arguments @('-NoProfile', '-File', $scriptPath)

        $result.ExitCode | Should -Be 0
        $result.StdOut.Trim() | Should -Be 'runner stdout'
        $result.StdErr | Should -BeNullOrEmpty
    }

    It 'captures standard error and a nonzero exit code' {
        $scriptPath = Join-Path $TestDrive 'stderr.ps1'
        "[Console]::Error.WriteLine('runner stderr'); exit 7" | Set-Content -LiteralPath $scriptPath

        $result = Invoke-SafeProcess -FilePath $pwshPath -Arguments @('-NoProfile', '-File', $scriptPath)

        $result.ExitCode | Should -Be 7
        $result.StdErr.Trim() | Should -Be 'runner stderr'
    }

    It 'redacts each nonempty secret literally and case-sensitively in both streams' {
        $scriptPath = Join-Path $TestDrive 'secrets.ps1'
        @"
Write-Output 'token=a.b* token=A.B*'
[Console]::Error.WriteLine('password=p[ass] password=P[ASS]')
"@ | Set-Content -LiteralPath $scriptPath

        $result = Invoke-SafeProcess -FilePath $pwshPath -Arguments @('-NoProfile', '-File', $scriptPath) -Secrets @('a.b*', 'p[ass]')

        $result.StdOut.Trim() | Should -Be 'token=[REDACTED] token=A.B*'
        $result.StdErr.Trim() | Should -Be 'password=[REDACTED] password=P[ASS]'
    }

    It 'redacts overlapping secrets completely regardless of input order in both streams' {
        $scriptPath = Join-Path $TestDrive 'overlapping-secrets.ps1'
        @"
Write-Output 'value=abcdef'
[Console]::Error.WriteLine('value=abcdef')
"@ | Set-Content -LiteralPath $scriptPath

        foreach ($secrets in @(@('abc', 'abcdef'), @('abcdef', 'abc'))) {
            $result = Invoke-SafeProcess -FilePath $pwshPath -Arguments @('-NoProfile', '-File', $scriptPath) -Secrets $secrets

            $result.StdOut.Trim() | Should -Be 'value=[REDACTED]'
            $result.StdErr.Trim() | Should -Be 'value=[REDACTED]'
        }
    }

    It 'ignores empty secrets rather than altering output' {
        $scriptPath = Join-Path $TestDrive 'empty-secret.ps1'
        "Write-Output 'unchanged'" | Set-Content -LiteralPath $scriptPath

        $result = Invoke-SafeProcess -FilePath $pwshPath -Arguments @('-NoProfile', '-File', $scriptPath) -Secrets @('', $null)

        $result.StdOut.Trim() | Should -Be 'unchanged'
    }

    It 'uses a stable error code when the executable cannot be started and cleans temporary files' {
        $tempPath = [IO.Path]::GetTempPath()
        $before = @(Get-ChildItem -LiteralPath $tempPath -Filter 'opencode-process-*.tmp' -ErrorAction SilentlyContinue).FullName

        { Invoke-SafeProcess -FilePath (Join-Path $TestDrive 'missing executable.exe') -Arguments @() } |
            Should -Throw 'PROCESS_START_FAILED:*'

        $after = @(Get-ChildItem -LiteralPath $tempPath -Filter 'opencode-process-*.tmp' -ErrorAction SilentlyContinue).FullName
        @($after | Where-Object { $_ -notin $before }).Count | Should -Be 0
    }

    It 'preserves executable paths and arguments containing spaces' {
        $folder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'folder with spaces')
        $scriptPath = Join-Path $folder.FullName 'emit argument.ps1'
        "param([string]`$Value); Write-Output `$Value" | Set-Content -LiteralPath $scriptPath

        $result = Invoke-SafeProcess -FilePath $pwshPath -Arguments @('-NoProfile', '-File', $scriptPath, 'argument with spaces')

        $result.ExitCode | Should -Be 0
        $result.StdOut.Trim() | Should -Be 'argument with spaces'
    }

    It 'preserves quotes, trailing backslashes, empty arguments, and shell metacharacters as literal data' {
        $folder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'argument fixtures with spaces')
        $scriptPath = Join-Path $folder.FullName 'emit encoded arguments.ps1'
        @'
param([Parameter(ValueFromRemainingArguments)][string[]]$Values)
for ($index = 0; $index -lt $Values.Count; $index++) {
    "${index}:$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Values[$index])))"
}
'@ | Set-Content -LiteralPath $scriptPath
        $values = @(
            'value "quoted" here',
            'relative path with spaces\',
            '',
            'literal&value',
            'literal$(Get-Date)',
            'literal;value'
        )

        $result = Invoke-SafeProcess -FilePath $pwshPath -Arguments (@('-NoProfile', '-File', $scriptPath) + $values)

        $expected = @(for ($index = 0; $index -lt $values.Count; $index++) {
            "${index}:$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($values[$index])))"
        })
        @($result.StdOut -split '\r?\n' | Where-Object { $_.Length -gt 0 }) | Should -Be $expected
        $result.ExitCode | Should -Be 0
        $result.StdErr | Should -BeNullOrEmpty
    }

    It 'exports only Invoke-SafeProcess and contains no shell evaluation primitive' {
        @((Get-Module ProcessRunner).ExportedFunctions.Keys) | Should -Be @('Invoke-SafeProcess')
        Get-Content -LiteralPath $modulePath -Raw | Should -Not -Match '(?i)Invoke-Expression|\beval\b|cmd(?:\.exe)?\s+/c'
    }
}
