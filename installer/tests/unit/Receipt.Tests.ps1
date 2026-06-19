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

    It 'rejects blank and ordinal-duplicate component ids with stable errors' {
        $blank = New-TestReceipt
        $blank.components = @([pscustomobject]@{ id = '  '; state = 'PLANNED' })
        { Assert-InstallReceipt $blank } | Should -Throw 'RECEIPT_COMPONENT_ID_INVALID*'

        $duplicate = New-TestReceipt
        $duplicate.components = @(
            [pscustomobject]@{ id = 'component'; state = 'PLANNED' },
            [pscustomobject]@{ id = 'component'; state = 'CONFIGURED' }
        )
        { Assert-InstallReceipt $duplicate } | Should -Throw 'RECEIPT_COMPONENT_ID_DUPLICATE*'
        { Set-ReceiptComponentState (New-TestReceipt) ' ' 'PLANNED' } | Should -Throw 'RECEIPT_COMPONENT_ID_INVALID*'
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

    It 'rejects a junction-backed backup root before creating its outside container' {
        $allowed = Join-Path $TestDrive 'junction-source'; New-Item -ItemType Directory $allowed -Force | Out-Null
        $source = Join-Path $allowed 'source.txt'; 'original' | Set-Content $source
        $outside = Join-Path $TestDrive 'junction-backup-outside'; New-Item -ItemType Directory $outside -Force | Out-Null
        $backupRoot = Join-Path $TestDrive 'backup-junction'
        try { New-Item -ItemType Junction -Path $backupRoot -Target $outside -ErrorAction Stop | Out-Null }
        catch { Set-ItResult -Skipped -Because 'Junction creation is unavailable'; return }
        $outsideContainer = Join-Path $outside '20260618T123456Z-a1b2c3d4'

        { Backup-InstallPath -Receipt (New-TestReceipt) -Path $source -BackupRoot $backupRoot -BackupId '20260618T123456Z-a1b2c3d4' -AllowedRoots @($allowed) } |
            Should -Throw 'ROLLBACK_PATH_OUTSIDE_OWNERSHIP*'
        Test-Path -LiteralPath $outsideContainer | Should -BeFalse
    }

    It 'does not overwrite a file backup when two receipts collide on backup id and item number' {
        $allowed = Join-Path $TestDrive 'file-collision'; $backupRoot = Join-Path $TestDrive 'file-collision-backups'
        New-Item -ItemType Directory $allowed -Force | Out-Null
        $source = Join-Path $allowed 'settings.bin'; [IO.File]::WriteAllBytes($source, [byte[]](1,2,3))
        $first = New-TestReceipt
        Backup-InstallPath $first $source $backupRoot '20260618T123456Z-a1b2c3d4' @($allowed)
        [IO.File]::WriteAllBytes($source, [byte[]](9,8,7))

        { Backup-InstallPath (New-TestReceipt) $source $backupRoot '20260618T123456Z-a1b2c3d4' @($allowed) } |
            Should -Throw 'BACKUP_DESTINATION_EXISTS*'
        [IO.File]::ReadAllBytes($first.backups[0].backupPath) | Should -Be ([byte[]](1,2,3))
    }

    It 'does not merge or overwrite a directory backup on destination collision' {
        $allowed = Join-Path $TestDrive 'dir-collision'; $backupRoot = Join-Path $TestDrive 'dir-collision-backups'
        $tree = Join-Path $allowed 'tree'; New-Item -ItemType Directory (Join-Path $tree 'sub') -Force | Out-Null
        'first' | Set-Content (Join-Path $tree 'sub/first.txt') -NoNewline
        $first = New-TestReceipt
        Backup-InstallPath $first $tree $backupRoot '20260618T123457Z-a1b2c3d4' @($allowed)
        Remove-Item $tree -Recurse; New-Item -ItemType Directory $tree -Force | Out-Null
        'second' | Set-Content (Join-Path $tree 'second.txt') -NoNewline

        { Backup-InstallPath (New-TestReceipt) $tree $backupRoot '20260618T123457Z-a1b2c3d4' @($allowed) } |
            Should -Throw 'BACKUP_DESTINATION_EXISTS*'
        (Get-Content (Join-Path $first.backups[0].backupPath 'sub/first.txt') -Raw) | Should -Be 'first'
        Test-Path (Join-Path $first.backups[0].backupPath 'second.txt') | Should -BeFalse
    }

    It 'cleans failed staging and permits an exact retry' {
        $allowed = Join-Path $TestDrive 'copy-failure'; $backupRoot = Join-Path $TestDrive 'copy-failure-backups'
        New-Item -ItemType Directory $allowed -Force | Out-Null
        $source = Join-Path $allowed 'source.bin'; [IO.File]::WriteAllBytes($source, [byte[]](5,4,3,2,1))
        $receipt = New-TestReceipt
        $failingCopy = {
            param($Source, $Destination, $Type)
            [IO.File]::WriteAllText($Destination, 'partial')
            throw 'SIMULATED_COPY_FAILURE'
        }

        { Backup-InstallPath $receipt $source $backupRoot '20260618T123458Z-a1b2c3d4' @($allowed) -CopyOperation $failingCopy } |
            Should -Throw 'SIMULATED_COPY_FAILURE*'
        $container = Join-Path $backupRoot '20260618T123458Z-a1b2c3d4'
        if (Test-Path $container) { @(Get-ChildItem $container -Force).Count | Should -Be 0 }

        $record = Backup-InstallPath $receipt $source $backupRoot '20260618T123458Z-a1b2c3d4' @($allowed)
        [IO.File]::ReadAllBytes($record.backupPath) | Should -Be ([byte[]](5,4,3,2,1))
    }

    It 'finds the first component not yet verified for resume' {
        $receipt = New-TestReceipt
        Set-ReceiptComponentState $receipt 'one' 'VERIFIED'
        Set-ReceiptComponentState $receipt 'two' 'CONFIGURED'
        Set-ReceiptComponentState $receipt 'three' 'PLANNED'
        (Get-ReceiptResumeComponent -Receipt $receipt).id | Should -Be 'two'
        @($receipt.components.id) | Should -Be @('one', 'two', 'three')
        { Set-ReceiptComponentState $receipt 'three' 'BROKEN' } | Should -Throw 'RECEIPT_COMPONENT_INVALID*'
    }
}
