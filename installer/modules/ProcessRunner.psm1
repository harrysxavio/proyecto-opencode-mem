Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-ProcessArgument {
    param([AllowEmptyString()][string]$Argument)

    if ($Argument.Length -eq 0) { return '""' }
    if ($Argument -notmatch '[\s"]') { return $Argument }

    $builder = [Text.StringBuilder]::new()
    [void]$builder.Append('"')
    $backslashes = 0
    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
            [void]$builder.Append('"')
        }
        else {
            [void]$builder.Append(('\' * $backslashes))
            [void]$builder.Append($character)
        }
        $backslashes = 0
    }
    [void]$builder.Append(('\' * ($backslashes * 2)))
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Protect-ProcessOutput {
    param(
        [AllowEmptyString()][string]$Text,
        [AllowEmptyCollection()][string[]]$Secrets
    )

    $uniqueSecrets = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($secret in $Secrets) {
        if ($null -ne $secret -and $secret.Length -gt 0) {
            [void]$uniqueSecrets.Add($secret)
        }
    }

    $protected = $Text
    foreach ($secret in @($uniqueSecrets | Sort-Object Length -Descending)) {
        $protected = $protected.Replace($secret, '[REDACTED]')
    }
    return $protected
}

function Invoke-SafeProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [AllowEmptyCollection()]
        [string[]]$Arguments = @(),

        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Secrets = @()
    )

    $identifier = [Guid]::NewGuid().ToString('N')
    $stdoutPath = Join-Path ([IO.Path]::GetTempPath()) "opencode-process-$identifier-stdout.tmp"
    $stderrPath = Join-Path ([IO.Path]::GetTempPath()) "opencode-process-$identifier-stderr.tmp"

    try {
        $argumentList = @($Arguments | ForEach-Object { ConvertTo-ProcessArgument -Argument $_ })
        try {
            $process = Start-Process -FilePath $FilePath -ArgumentList $argumentList -Wait -PassThru -NoNewWindow `
                -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -ErrorAction Stop
        }
        catch {
            throw "PROCESS_START_FAILED: Cannot start '$FilePath'. $($_.Exception.Message)"
        }

        $stdout = if (Test-Path -LiteralPath $stdoutPath) { [IO.File]::ReadAllText($stdoutPath) } else { '' }
        $stderr = if (Test-Path -LiteralPath $stderrPath) { [IO.File]::ReadAllText($stderrPath) } else { '' }

        [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = Protect-ProcessOutput -Text $stdout -Secrets $Secrets
            StdErr = Protect-ProcessOutput -Text $stderr -Secrets $Secrets
        }
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Invoke-SafeProcess
