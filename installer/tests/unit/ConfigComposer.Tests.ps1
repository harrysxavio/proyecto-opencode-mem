$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    Import-Module (Join-Path $repoRoot 'installer/modules/Receipt.psm1') -Force
    Import-Module (Join-Path $repoRoot 'installer/modules/ConfigComposer.psm1') -Force
    $fixture = Join-Path $repoRoot 'installer/tests/fixtures/opencode-existing.jsonc'
    function New-TestReceipt { New-InstallReceipt -KitVersion '1.2.3' -LockDigest ('a' * 64) -SourceCommit 'abc123' }
    function New-EngramOwned {
        [ordered]@{ mcp = [ordered]@{ engram = [ordered]@{ command = @('uvx', 'engram-mcp'); enabled = $true } } }
    }
}

Describe 'ConvertFrom-Jsonc' {
    It 'parses comments and trailing commas without altering comment markers inside strings' {
        $document = ConvertFrom-Jsonc ([IO.File]::ReadAllText($fixture))
        $document.mcp.custom.command[1] | Should -Be 'https://example.test/a//b'
        $document.agent.reviewer.prompt | Should -Be 'keep /* literal */ and escaped quote: "ok" \ path'
        $document.plugin | Should -Be @('user-plugin')
    }

    It 'preserves JSON scalar, array, object, and null types' {
        $document = ConvertFrom-Jsonc '{"i":1,"n":1.25,"yes":true,"no":false,"nil":null,"a":[1,"x"],"o":{"x":2}}'
        $document.i | Should -BeOfType Int64
        $document.n.ToString() | Should -Be '1.25'
        $document.yes | Should -BeTrue
        $document.no | Should -BeFalse
        $document.nil | Should -BeNullOrEmpty
        $document.a.Count | Should -Be 2
        $document.o | Should -BeOfType ([Collections.IDictionary])
    }

    It 'rejects malformed JSONC with a stable error' {
        { ConvertFrom-Jsonc '{ "mcp": [ }' } | Should -Throw 'CONFIG_JSONC_INVALID*'
    }
}

Describe 'Merge-OpenCodeConfig' {
    It 'adds owned configuration and preserves unrelated user entries' {
        $result = Merge-OpenCodeConfig -ExistingText ([IO.File]::ReadAllText($fixture)) -Owned (New-EngramOwned)
        $result.Document.mcp.custom.command[0] | Should -Be 'custom-server'
        $result.Document.mcp.engram.enabled | Should -BeTrue
        $result.Document.agent.reviewer.prompt | Should -Match 'literal'
        $result.Document.plugin | Should -Be @('user-plugin')
        $result.Document.instructions | Should -Be @('USER.md')
        $result.OwnedKeys | Should -Be @('mcp.engram.command', 'mcp.engram.enabled')
        $result.Changes.Count | Should -Be 2
        $result.Changes[0].action | Should -Be 'add'
    }

    It 'is deterministic and idempotent with arrays treated atomically' {
        $first = Merge-OpenCodeConfig '{}' ([ordered]@{ plugin = @('kit-a', 'kit-b') })
        $second = Merge-OpenCodeConfig $first.Json ([ordered]@{ plugin = @('kit-a', 'kit-b') })
        $second.Changed | Should -BeFalse
        $second.Changes.Count | Should -Be 0
        $second.Json | Should -Be $first.Json
        { Merge-OpenCodeConfig '{"plugin":["kit-b","kit-a"]}' ([ordered]@{ plugin = @('kit-a', 'kit-b') }) } | Should -Throw 'CONFIG_COLLISION:plugin'
    }

    It 'treats equivalent JSON numeric CLR representations as semantically equal' {
        $result = Merge-OpenCodeConfig '{"mcp":{"server":{"priority":1}}}' ([ordered]@{ mcp = [ordered]@{ server = [ordered]@{ priority = [int]1 } } })
        $result.Changed | Should -BeFalse
        (Merge-OpenCodeConfig '{"mcp":{"server":{"priority":1.0}}}' ([ordered]@{ mcp = [ordered]@{ server = [ordered]@{ priority = [int]1 } } })).Changed | Should -BeFalse
        (Merge-OpenCodeConfig '{"mcp":{"server":{"priority":1e100}}}' ([ordered]@{ mcp = [ordered]@{ server = [ordered]@{ priority = [double]1e100 } } })).Changed | Should -BeFalse
        { Merge-OpenCodeConfig '{"mcp":{"server":{"priority":1e100}}}' ([ordered]@{ mcp = [ordered]@{ server = [ordered]@{ priority = [double]2e100 } } }) } |
            Should -Throw 'CONFIG_COLLISION:mcp.server.priority'
    }

    It 'round trips unrelated large and high precision numeric tokens exactly' {
        $existing = '{"mcp":{"custom":{"max":18446744073709551615,"huge":18446744073709551616,"precise":0.123456789012345678901234567890}}}'
        $result = Merge-OpenCodeConfig $existing ([ordered]@{ agent = [ordered]@{ kit = [ordered]@{ enabled = $true } } })
        $result.Json | Should -Match '18446744073709551615'
        $result.Json | Should -Match '18446744073709551616'
        $result.Json | Should -Match '0\.123456789012345678901234567890'
    }

    It 'preserves distinct JSON keys by ordinal case and matches owned paths case-sensitively' {
        $existing = '{"mcp":{"Engram":{"enabled":false}},"MCP":{"user":true}}'
        $result = Merge-OpenCodeConfig $existing ([ordered]@{ mcp = [ordered]@{ engram = [ordered]@{ enabled = $true } } })
        $result.Document['MCP']['user'] | Should -BeTrue
        $result.Document['mcp']['Engram']['enabled'] | Should -BeFalse
        $result.Document['mcp']['engram']['enabled'] | Should -BeTrue
        $roundTrip = ConvertFrom-Jsonc $result.Json
        @($roundTrip.Keys) | Should -Be @('mcp', 'MCP')
    }

    It 'detects semantic collisions at the exact owned path' {
        { Merge-OpenCodeConfig '{"mcp":{"engram":{"enabled":false}}}' ([ordered]@{ mcp = [ordered]@{ engram = [ordered]@{ enabled = $true } } }) } |
            Should -Throw 'CONFIG_COLLISION:mcp.engram.enabled'
    }

    It 'does not mutate either owned or parsed input-compatible values' {
        $owned = New-EngramOwned
        $before = $owned | ConvertTo-Json -Depth 10 -Compress
        $result = Merge-OpenCodeConfig '{}' $owned
        $result.Document.mcp.engram.command[0] = 'changed'
        ($owned | ConvertTo-Json -Depth 10 -Compress) | Should -Be $before
    }

    It 'rejects malicious, ambiguous, traversal, control, and unexpected root keys' {
        $bad = @(
            [ordered]@{ '__proto__' = 1 },
            [ordered]@{ mcp = [ordered]@{ constructor = 1 } },
            [ordered]@{ mcp = [ordered]@{ 'a.b' = 1 } },
            [ordered]@{ mcp = [ordered]@{ '..' = 1 } },
            [ordered]@{ mcp = [ordered]@{ "bad`nkey" = 1 } },
            [ordered]@{ unexpected = 1 },
            [ordered]@{ mcp = 'not-an-object' },
            [ordered]@{ plugin = 'not-an-array' },
            [ordered]@{ mcp = @{ 7 = 'non-string-key' } }
        )
        foreach ($owned in $bad) { { Merge-OpenCodeConfig '{}' $owned } | Should -Throw 'CONFIG_OWNED_KEY_INVALID*' }
    }

    It 'validates keys recursively inside arrays and rejects invalid root array primitives' {
        $bad = @(
            [ordered]@{ plugin = @([ordered]@{ '__proto__' = 'bad' }) },
            [ordered]@{ instructions = @([ordered]@{ nested = @([ordered]@{ 'bad.key' = 'bad' }) }) },
            [ordered]@{ plugin = @($null) },
            [ordered]@{ plugin = @($true) },
            [ordered]@{ instructions = @(42) },
            [ordered]@{ instructions = @(,@('nested-array')) }
        )
        foreach ($owned in $bad) { { Merge-OpenCodeConfig '{}' $owned } | Should -Throw 'CONFIG_OWNED_KEY_INVALID*' }
    }

    It 'accepts documented string and object array entries idempotently' {
        $owned = [ordered]@{
            plugin = @('kit-plugin', [ordered]@{ name = 'object-plugin'; options = [ordered]@{ mode = 'safe' } })
            instructions = @('AGENTS.md')
        }
        $first = Merge-OpenCodeConfig '{}' $owned
        $second = Merge-OpenCodeConfig $first.Json $owned
        $first.Changed | Should -BeTrue
        $second.Changed | Should -BeFalse
    }
}

Describe 'Write-OpenCodeConfig' {
    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $backupRoot = Join-Path $TestDrive ('backups-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $path = Join-Path $root 'opencode.jsonc'
        $receipt = New-TestReceipt
        $backupId = '20260618T123456Z-a1b2c3d4'
    }

    It 'backs up exact original bytes before an atomic write and records ownership' {
        $bytes = [byte[]](0xEF,0xBB,0xBF) + [Text.Encoding]::UTF8.GetBytes("{`r`n // original`r`n `"mcp`": {},`r`n}`r`n")
        [IO.File]::WriteAllBytes($path, $bytes)
        $result = Write-OpenCodeConfig -ConfigPath $path -OpenCodeConfigRoot $root -Owned (New-EngramOwned) -Receipt $receipt -BackupRoot $backupRoot -BackupId $backupId
        $result.Changed | Should -BeTrue
        $receipt.backups.Count | Should -Be 0
        $result.Receipt.backups.Count | Should -Be 1
        [IO.File]::ReadAllBytes($result.Receipt.backups[0].backupPath) | Should -Be $bytes
        $result.Receipt.ownedKeys | Should -Be @('mcp.engram.command', 'mcp.engram.enabled')
        $result.Receipt.ownedPaths | Should -Contain ([IO.Path]::GetFullPath($path))
        $result.UpdatedReceipt.ownedKeys | Should -Be $result.Receipt.ownedKeys
        @(Get-ChildItem $root -Filter '*.tmp' -Force).Count | Should -Be 0
    }

    It 'validates the complete receipt before backup or write without mutating either original' {
        $original = '{"mcp":{}}'; [IO.File]::WriteAllText($path, $original)
        $missingPaths = New-TestReceipt; $missingPaths.PSObject.Properties.Remove('ownedPaths')
        $missingKeys = New-TestReceipt; $missingKeys.PSObject.Properties.Remove('ownedKeys')
        $badSchema = New-TestReceipt; $badSchema.schemaVersion = 2
        foreach ($badReceipt in @($missingPaths, $missingKeys, $badSchema)) {
            $before = ConvertTo-Json -InputObject $badReceipt -Depth 20 -Compress
            { Write-OpenCodeConfig $path $root (New-EngramOwned) $badReceipt $backupRoot $backupId } | Should -Throw 'RECEIPT_*'
            [IO.File]::ReadAllText($path) | Should -Be $original
            (ConvertTo-Json -InputObject $badReceipt -Depth 20 -Compress) | Should -Be $before
            Test-Path $backupRoot | Should -BeFalse
        }
    }

    It 'does not back up or write on collision and leaves the original unchanged' {
        $original = '{"mcp":{"engram":{"enabled":false}}}'
        [IO.File]::WriteAllText($path, $original)
        { Write-OpenCodeConfig $path $root ([ordered]@{ mcp = [ordered]@{ engram = [ordered]@{ enabled = $true } } }) $receipt $backupRoot $backupId } | Should -Throw 'CONFIG_COLLISION*'
        [IO.File]::ReadAllText($path) | Should -Be $original
        $receipt.backups.Count | Should -Be 0
    }

    It 'does not back up or write malformed existing JSONC' {
        $original = '{"mcp": [ }'; [IO.File]::WriteAllText($path, $original)
        { Write-OpenCodeConfig $path $root (New-EngramOwned) $receipt $backupRoot $backupId } | Should -Throw 'CONFIG_JSONC_INVALID*'
        [IO.File]::ReadAllText($path) | Should -Be $original
        $receipt.backups.Count | Should -Be 0
    }

    It 'leaves the original unchanged when the exact backup cannot complete' {
        $original = '{"mcp":{}}'; [IO.File]::WriteAllText($path, $original)
        $copy = { param($Source, $Destination, $Type) [IO.File]::WriteAllText($Destination, 'partial'); throw 'simulated backup failure' }
        { Write-OpenCodeConfig $path $root (New-EngramOwned) $receipt $backupRoot $backupId -BackupCopyOperation $copy } | Should -Throw 'simulated backup failure'
        [IO.File]::ReadAllText($path) | Should -Be $original
        $receipt.backups.Count | Should -Be 0
        $receipt.ownedKeys.Count | Should -Be 0
    }

    It 'records absent creation and performs no duplicate backup or write on the second run' {
        $first = Write-OpenCodeConfig $path $root (New-EngramOwned) $receipt $backupRoot $backupId
        $stamp = (Get-Item $path).LastWriteTimeUtc
        Start-Sleep -Milliseconds 30
        $second = Write-OpenCodeConfig $path $root (New-EngramOwned) $first.Receipt $backupRoot $backupId
        $first.Changed | Should -BeTrue
        $second.Changed | Should -BeFalse
        $receipt.backups.Count | Should -Be 0
        $second.Receipt.backups.Count | Should -Be 1
        $second.Receipt.backups[0].type | Should -Be 'absent'
        (Get-Item $path).LastWriteTimeUtc | Should -Be $stamp
    }

    It 'keeps the original and cleans temp files when atomic publication is interrupted' {
        $original = '{"mcp":{}}'; [IO.File]::WriteAllText($path, $original)
        $operation = { param($TempPath, $Destination, $Json) [IO.File]::WriteAllText($TempPath, $Json); throw 'simulated interruption' }
        { Write-OpenCodeConfig $path $root (New-EngramOwned) $receipt $backupRoot $backupId -AtomicWriteOperation $operation } | Should -Throw 'simulated interruption'
        [IO.File]::ReadAllText($path) | Should -Be $original
        $receipt.ownedPaths.Count | Should -Be 0
        $receipt.ownedKeys.Count | Should -Be 0
        $receipt.backups.Count | Should -Be 0
        @(Get-ChildItem $root -Filter '*.tmp' -Force).Count | Should -Be 0
    }

    It 'rejects a concurrent file content swap before backup and preserves the concurrent writer' {
        $original = '{"mcp":{}}'; $concurrent = '{"mcp":{"concurrent":true}}'
        [IO.File]::WriteAllText($path, $original)
        $operation = { [IO.File]::WriteAllText($path, $concurrent) }
        { Write-OpenCodeConfig $path $root (New-EngramOwned) $receipt $backupRoot $backupId -BeforePublishValidation $operation } |
            Should -Throw 'CONFIG_CONCURRENT_MODIFICATION*'
        [IO.File]::ReadAllText($path) | Should -Be $concurrent
        $receipt.backups.Count | Should -Be 0
        Test-Path $backupRoot | Should -BeFalse
    }

    It 'fails closed when a concurrent operation attempts to replace the locked config root' {
        $outsideRoot = Join-Path $TestDrive ('swap-target-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $outsideRoot -Force | Out-Null
        [IO.File]::WriteAllText($path, '{"mcp":{}}')
        $operation = {
            Remove-Item -LiteralPath $root -Recurse -Force
            New-Item -ItemType Junction -Path $root -Target $outsideRoot | Out-Null
        }
        { Write-OpenCodeConfig $path $root (New-EngramOwned) $receipt $backupRoot $backupId -BeforePublishValidation $operation } |
            Should -Throw 'CONFIG_CONCURRENT_MODIFICATION*'
        Test-Path (Join-Path $outsideRoot 'opencode.jsonc') | Should -BeFalse
    }

    It 'rejects lexical path escape before backup or write' {
        $outside = Join-Path $TestDrive 'outside.json'
        { Write-OpenCodeConfig $outside $root (New-EngramOwned) $receipt $backupRoot $backupId } | Should -Throw 'CONFIG_PATH_OUTSIDE_ROOT*'
        Test-Path $outside | Should -BeFalse
        $receipt.backups.Count | Should -Be 0
    }

    It 'rejects a junction escape when junction creation is available' {
        $outsideRoot = Join-Path $TestDrive ('outside-' + [guid]::NewGuid().ToString('N'))
        $junction = Join-Path $root 'linked'
        New-Item -ItemType Directory -Path $outsideRoot -Force | Out-Null
        try { New-Item -ItemType Junction -Path $junction -Target $outsideRoot -ErrorAction Stop | Out-Null }
        catch { Set-ItResult -Skipped -Because 'junction creation is unavailable'; return }
        $escaped = Join-Path $junction 'opencode.jsonc'
        { Write-OpenCodeConfig $escaped $root (New-EngramOwned) $receipt $backupRoot $backupId } | Should -Throw 'CONFIG_PATH_OUTSIDE_ROOT*'
        Test-Path (Join-Path $outsideRoot 'opencode.jsonc') | Should -BeFalse
    }
}
