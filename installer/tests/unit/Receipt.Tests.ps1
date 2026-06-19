$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    Import-Module (Join-Path $repoRoot 'installer/modules/Receipt.psm1') -Force
    $digest = 'a' * 64
    function New-TestReceipt {
        New-InstallReceipt -KitVersion '1.2.3' -LockDigest $digest -SourceCommit 'abc123'
    }
}

Describe 'receipt identity and schema' {
    It 'accepts only an exact UTC timestamp plus eight lowercase hex characters' {
        Assert-SafeBackupId '20260618T123456Z-a1b2c3d4' | Should -Be '20260618T123456Z-a1b2c3d4'
        foreach ($bad in @('../20260618T123456Z-a1b2c3d4', '20260618T123456Z-A1B2C3D4', '20260618T123456-a1b2c3d4', '20260618T123456Z-a1b2c3d4/x')) {
            { Assert-SafeBackupId $bad } | Should -Throw 'BACKUP_ID_INVALID*'
        }
    }

    It 'creates a planned versioned receipt with UTC provenance and no secret fields' {
        $receipt = New-TestReceipt
        $receipt.schemaVersion | Should -Be 1
        $receipt.kitVersion | Should -Be '1.2.3'
        $receipt.state | Should -Be 'PLANNED'
        $receipt.createdAt | Should -Match 'Z$'
        @($receipt.components).Count | Should -Be 0
        @($receipt.ownedPaths).Count | Should -Be 0
        @($receipt.ownedKeys).Count | Should -Be 0
        @($receipt.backups).Count | Should -Be 0
        $receipt.provenance.sourceCommit | Should -Be 'abc123'
        $receipt.provenance.lockDigest | Should -Be $digest
        ($receipt | ConvertTo-Json -Depth 10) | Should -Not -Match '(?i)secret|password|credential|token'
        { New-InstallReceipt -KitVersion 1 -LockDigest ('A' * 64) -SourceCommit abc } | Should -Throw 'RECEIPT_LOCK_DIGEST_INVALID*'
    }

    It 'rejects bad schema, state, types, component state, and sensitive fields' {
        $root = Join-Path $TestDrive 'receipts'; New-Item -ItemType Directory $root -Force | Out-Null
        $path = Join-Path $root 'bad.json'
        $cases = @(
            '{"schemaVersion":2,"kitVersion":"1","createdAt":"2026-01-01T00:00:00Z","state":"PLANNED","components":[],"ownedPaths":[],"ownedKeys":[],"backups":[],"provenance":{"sourceCommit":"x","lockDigest":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}}',
            '{"schemaVersion":1,"kitVersion":"1","createdAt":"2026-01-01T00:00:00Z","state":"EVIL","components":[],"ownedPaths":[],"ownedKeys":[],"backups":[],"provenance":{"sourceCommit":"x","lockDigest":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}}',
            '{"schemaVersion":1,"kitVersion":"1","createdAt":"2026-01-01T00:00:00Z","state":"PLANNED","components":"bad","ownedPaths":[],"ownedKeys":[],"backups":[],"provenance":{"sourceCommit":"x","lockDigest":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}}',
            '{"schemaVersion":1,"kitVersion":"1","createdAt":"2026-01-01T00:00:00Z","state":"PLANNED","components":[{"id":"x","state":"BROKEN"}],"ownedPaths":[],"ownedKeys":[],"backups":[],"provenance":{"sourceCommit":"x","lockDigest":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}}',
            '{"schemaVersion":1,"kitVersion":"1","createdAt":"2026-01-01T00:00:00Z","state":"PLANNED","components":[],"ownedPaths":[],"ownedKeys":[],"backups":[],"password":"oops","provenance":{"sourceCommit":"x","lockDigest":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}}'
        )
        foreach ($json in $cases) {
            [IO.File]::WriteAllText($path, $json)
            { Read-InstallReceipt -Path $path -ReceiptRoot $root -AllowedRoots @($TestDrive) } | Should -Throw 'RECEIPT_*'
        }
    }
}

Describe 'receipt persistence and ownership' {
    It 'round trips atomically as UTF8 and leaves no temp file' {
        $root = Join-Path $TestDrive 'receipts'; New-Item -ItemType Directory $root -Force | Out-Null
        $path = Join-Path $root 'receipt.json'
        Save-InstallReceipt -Receipt (New-TestReceipt) -Path $path -ReceiptRoot $root
        [IO.File]::ReadAllText($path) | Should -Match '"schemaVersion"'
        @(Get-ChildItem $root -Filter '*.tmp').Count | Should -Be 0
        (Read-InstallReceipt -Path $path -ReceiptRoot $root -AllowedRoots @($TestDrive)).kitVersion | Should -Be '1.2.3'
    }

    It 'rejects a receipt path outside its receipt root before reading' {
        $root = Join-Path $TestDrive 'receipts'; New-Item -ItemType Directory $root -Force | Out-Null
        $outside = Join-Path $TestDrive 'outside.json'; '{}' | Set-Content $outside
        { Read-InstallReceipt -Path $outside -ReceiptRoot $root -AllowedRoots @($TestDrive) } | Should -Throw 'ROLLBACK_PATH_OUTSIDE_OWNERSHIP*'
    }

    It 'deduplicates owned paths and keys' {
        $receipt = New-TestReceipt
        Add-ReceiptOwnedPath -Receipt $receipt -Path (Join-Path $TestDrive 'owned')
        Add-ReceiptOwnedPath -Receipt $receipt -Path (Join-Path $TestDrive 'owned')
        Add-ReceiptOwnedKey -Receipt $receipt -Key 'mcp.engram'
        Add-ReceiptOwnedKey -Receipt $receipt -Key 'mcp.engram'
        @($receipt.ownedPaths).Count | Should -Be 1
        @($receipt.ownedKeys).Count | Should -Be 1
    }

    It 'backs up exact file bytes, directory trees, and records an absent destination' {
        $allowed = Join-Path $TestDrive 'config'; $backupRoot = Join-Path $TestDrive 'backups'
        New-Item -ItemType Directory (Join-Path $allowed 'tree/sub') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $allowed 'binary.bin'), [byte[]](0,255,13,10))
        'nested' | Set-Content (Join-Path $allowed 'tree/sub/file.txt') -NoNewline
        $receipt = New-TestReceipt
        Backup-InstallPath -Receipt $receipt -Path (Join-Path $allowed 'binary.bin') -BackupRoot $backupRoot -BackupId '20260618T123456Z-a1b2c3d4' -AllowedRoots @($allowed)
        Backup-InstallPath -Receipt $receipt -Path (Join-Path $allowed 'tree') -BackupRoot $backupRoot -BackupId '20260618T123456Z-a1b2c3d4' -AllowedRoots @($allowed)
        Backup-InstallPath -Receipt $receipt -Path (Join-Path $allowed 'created.txt') -BackupRoot $backupRoot -BackupId '20260618T123456Z-a1b2c3d4' -AllowedRoots @($allowed)
        $receipt.backups[0].existed | Should -BeTrue
        [IO.File]::ReadAllBytes($receipt.backups[0].backupPath) | Should -Be ([byte[]](0,255,13,10))
        (Get-Content (Join-Path $receipt.backups[1].backupPath 'sub/file.txt') -Raw) | Should -Be 'nested'
        $receipt.backups[2].existed | Should -BeFalse
        $receipt.backups[2].backupPath | Should -BeNullOrEmpty
        $receipt.ownedPaths | Should -Contain ([IO.Path]::GetFullPath((Join-Path $allowed 'created.txt')))
    }

    It 'finds the first component not yet verified for resume' {
        $receipt = New-TestReceipt
        Set-ReceiptComponentState $receipt 'one' 'VERIFIED'
        Set-ReceiptComponentState $receipt 'two' 'CONFIGURED'
        Set-ReceiptComponentState $receipt 'three' 'PLANNED'
        (Get-ReceiptResumeComponent -Receipt $receipt).id | Should -Be 'two'
        { Set-ReceiptComponentState $receipt 'three' 'BROKEN' } | Should -Throw 'RECEIPT_COMPONENT_INVALID*'
    }
}
