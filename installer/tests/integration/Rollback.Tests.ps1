$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $receiptModule = Join-Path $repoRoot 'installer/modules/Receipt.psm1'
    $rollbackCommand = Join-Path $repoRoot 'installer/commands/rollback.ps1'
    Import-Module $receiptModule -Force
    $digest = 'b' * 64
}

Describe 'safe rollback' {
    BeforeEach {
        $configRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $receiptRoot = Join-Path $configRoot '.opencode-kit/receipts'
        $backupRoot = Join-Path $configRoot '.opencode-kit/backups'
        New-Item -ItemType Directory $receiptRoot -Force | Out-Null
        $receiptPath = Join-Path $receiptRoot 'receipt.json'
        $receipt = New-InstallReceipt -KitVersion '1.0.0' -LockDigest $digest -SourceCommit abc
    }

    It 'cancels interactively and refuses unconfirmed noninteractive mutation' {
        $created = Join-Path $configRoot 'created.txt'; 'new' | Set-Content $created
        Add-ReceiptOwnedPath $receipt $created
        Save-InstallReceipt $receipt $receiptPath $receiptRoot
        (& $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -ConfirmationReader { 'NO' }).Status | Should -Be 'CANCELED'
        Test-Path $created | Should -BeTrue
        { & $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -NonInteractive } | Should -Throw 'ROLLBACK_CONFIRMATION_REQUIRED*'
        Test-Path $created | Should -BeTrue
    }

    It 'restores exact file bytes and directory trees, removes only created owned paths, and is idempotent' {
        $file = Join-Path $configRoot 'settings.json'; [IO.File]::WriteAllBytes($file, [byte[]](0,1,255))
        $tree = Join-Path $configRoot 'agents'; New-Item -ItemType Directory (Join-Path $tree 'sub') -Force | Out-Null; 'old' | Set-Content (Join-Path $tree 'sub/a.txt') -NoNewline
        $created = Join-Path $configRoot 'created.txt'
        Backup-InstallPath $receipt $file $backupRoot '20260618T123456Z-a1b2c3d4' @($configRoot)
        Backup-InstallPath $receipt $tree $backupRoot '20260618T123456Z-a1b2c3d4' @($configRoot)
        Backup-InstallPath $receipt $created $backupRoot '20260618T123456Z-a1b2c3d4' @($configRoot)
        [IO.File]::WriteAllText($file, 'changed'); Remove-Item $tree -Recurse; New-Item -ItemType Directory $tree | Out-Null; 'changed' | Set-Content (Join-Path $tree 'new.txt'); 'created' | Set-Content $created
        $unrelated = Join-Path $configRoot 'unrelated.txt'; 'leave me' | Set-Content $unrelated -NoNewline
        Save-InstallReceipt $receipt $receiptPath $receiptRoot

        $first = & $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -NonInteractive -ConfirmRollback
        $first.Status | Should -Be 'ROLLED_BACK'
        [IO.File]::ReadAllBytes($file) | Should -Be ([byte[]](0,1,255))
        (Get-Content (Join-Path $tree 'sub/a.txt') -Raw) | Should -Be 'old'
        Test-Path (Join-Path $tree 'new.txt') | Should -BeFalse
        Test-Path $created | Should -BeFalse
        (Get-Content $unrelated -Raw) | Should -Be 'leave me'

        (& $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -NonInteractive -ConfirmRollback).Status | Should -Be 'ALREADY_ROLLED_BACK'
    }

    It 'validates the complete plan before mutation when a backup path is tampered' {
        $one = Join-Path $configRoot 'one.txt'; $two = Join-Path $configRoot 'two.txt'
        'old1' | Set-Content $one; 'old2' | Set-Content $two
        Backup-InstallPath $receipt $one $backupRoot '20260618T123456Z-a1b2c3d4' @($configRoot)
        Backup-InstallPath $receipt $two $backupRoot '20260618T123456Z-a1b2c3d4' @($configRoot)
        'new1' | Set-Content $one; 'new2' | Set-Content $two
        $receipt.backups[1].backupPath = Join-Path $TestDrive 'outside.bin'
        Save-InstallReceipt $receipt $receiptPath $receiptRoot
        { & $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -NonInteractive -ConfirmRollback } | Should -Throw 'ROLLBACK_PATH_OUTSIDE_OWNERSHIP*'
        (Get-Content $one -Raw).Trim() | Should -Be 'new1'
        (Get-Content $two -Raw).Trim() | Should -Be 'new2'
    }

    It 'rejects a target ancestor of protected receipt and backup paths before any action' {
        $settings = Join-Path $configRoot 'settings.json'; 'before' | Set-Content $settings -NoNewline
        Backup-InstallPath $receipt $settings $backupRoot '20260618T123456Z-a1b2c3d4' @($configRoot)
        'after' | Set-Content $settings -NoNewline
        $credential = Join-Path $configRoot 'credentials.json'; 'credential-stays' | Set-Content $credential -NoNewline
        $unrelated = Join-Path $configRoot 'unrelated.txt'; 'unrelated-stays' | Set-Content $unrelated -NoNewline
        $receipt.ownedPaths = @($configRoot)
        Save-InstallReceipt $receipt $receiptPath $receiptRoot
        $backupSource = $receipt.backups[0].backupPath

        { & $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -NonInteractive -ConfirmRollback } |
            Should -Throw 'ROLLBACK_PATH_CONFLICT*'
        (Get-Content $settings -Raw) | Should -Be 'after'
        (Get-Content $credential -Raw) | Should -Be 'credential-stays'
        (Get-Content $unrelated -Raw) | Should -Be 'unrelated-stays'
        Test-Path -LiteralPath $backupSource | Should -BeTrue
        Test-Path -LiteralPath $receiptPath | Should -BeTrue
    }

    It 'does not expose executable actions to a malicious confirmation callback' {
        $created = Join-Path $configRoot 'created-by-kit.txt'; 'remove-me' | Set-Content $created -NoNewline
        $credential = Join-Path $configRoot 'credentials.json'; 'credential-stays' | Set-Content $credential -NoNewline
        Add-ReceiptOwnedPath $receipt $created
        Save-InstallReceipt $receipt $receiptPath $receiptRoot
        $reader = {
            if (Get-Variable plannedActions -ErrorAction SilentlyContinue) { $plannedActions[0].Target = $credential }
            if (Get-Variable deduplicated -ErrorAction SilentlyContinue) { $deduplicated[0].Target = $credential }
            if (Get-Variable actions -ErrorAction SilentlyContinue) { $actions[0].Target = $credential }
            if (Get-Variable executionItems -ErrorAction SilentlyContinue) { $executionItems.Clear() }
            if (Get-Variable executionPlan -ErrorAction SilentlyContinue) { try { $executionPlan[0] = $null } catch {} }
            'ROLLBACK'
        }

        $jsonResult = & $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -ConfirmationReader $reader -Json
        $result = $jsonResult | ConvertFrom-Json

        $result.Status | Should -Be 'ROLLED_BACK'
        $result.Actions[0].Target | Should -Be ([IO.Path]::GetFullPath($created))
        Test-Path -LiteralPath $created | Should -BeFalse
        (Get-Content $credential -Raw) | Should -Be 'credential-stays'
    }

    It 'emits one JSON document without auxiliary pipeline output' {
        Save-InstallReceipt $receipt $receiptPath $receiptRoot
        $output = @(& $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -NonInteractive -ConfirmRollback -Json)
        $output.Count | Should -Be 1
        ($output[0] | ConvertFrom-Json).Status | Should -Be 'ROLLED_BACK'
    }

    It 'rejects a junction that escapes the allowed root before mutation' {
        $outside = Join-Path $TestDrive 'junction-outside'; New-Item -ItemType Directory $outside -Force | Out-Null
        $junction = Join-Path $configRoot 'escaped'
        try { New-Item -ItemType Junction -Path $junction -Target $outside -ErrorAction Stop | Out-Null }
        catch { Set-ItResult -Skipped -Because 'Junction creation is unavailable'; return }
        $receipt.ownedPaths = @($junction)
        Save-InstallReceipt $receipt $receiptPath $receiptRoot
        { & $rollbackCommand -ReceiptPath $receiptPath -ReceiptRoot $receiptRoot -AllowedRoots @($configRoot) -BackupRoot $backupRoot -NonInteractive -ConfirmRollback } | Should -Throw 'ROLLBACK_PATH_OUTSIDE_OWNERSHIP*'
        Test-Path $outside | Should -BeTrue
    }
}
