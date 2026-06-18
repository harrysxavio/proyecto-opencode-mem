$ErrorActionPreference = 'Stop'

Import-Module Pester -RequiredVersion 5.7.1 -ErrorAction Stop
$testsPath = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$result = Invoke-Pester -Path $testsPath -PassThru
if ($result.FailedCount -gt 0) {
    exit 1
}

exit 0
