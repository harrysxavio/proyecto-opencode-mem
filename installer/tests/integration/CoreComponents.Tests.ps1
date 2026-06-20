$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    Import-Module (Join-Path $repoRoot 'installer/modules/LockManifest.psm1') -Force
    Import-Module (Join-Path $repoRoot 'installer/modules/CoreComponents.psm1') -Force
    Import-Module (Join-Path $repoRoot 'installer/modules/ComponentRunner.psm1') -Force
    Import-Module (Join-Path $repoRoot 'installer/modules/Verification.psm1') -Force
    Import-Module (Join-Path $repoRoot 'installer/modules/Receipt.psm1') -Force
    $lock = Read-ComponentLock -Path (Join-Path $repoRoot 'installer/components.lock.json')
    $fixture = Join-Path $repoRoot 'installer/tests/e2e/fixtures/graphify/sample.js'
}

Describe 'install command core sequence' {
    It 'runs the three locked core components through checkpoints after prerequisites' {
        $versions = @{ git='2.53.0'; node='22.17.0'; pnpm='11.8.0'; python='3.13.5'; uv='0.11.14'; opencode='1.17.8'; engram='1.16.3'; graphify='0.8.41'; winget=$null }
        $resolver = { param($id) [pscustomobject]@{ Present=$true; Usable=$true; Version=$versions[$id] } }.GetNewClosure()
        $receipt = New-InstallReceipt -KitVersion '0.2.0-rc.1' -LockDigest ('a' * 64) -SourceCommit 'test'
        $coreCalls = [Collections.Generic.List[string]]::new(); $checkpointCounter = [pscustomobject]@{ Value=0 }
        $executor = { param($Component,$Phase); $coreCalls.Add("$($Component.id):$Phase"); [pscustomobject]@{ Success=$true; Evidence=$Phase } }.GetNewClosure()
        $checkpoint = { param($candidate) $checkpointCounter.Value++ }.GetNewClosure()
        $null = & (Join-Path $repoRoot 'installer/commands/install.ps1') -Root $repoRoot -ConfirmInstall -NonInteractive -Json -KitRoot (Join-Path $TestDrive 'kit') -CommandResolver $resolver -CoreReceipt $receipt -CoreExecutor $executor -CoreVerifier { [pscustomobject]@{ Status='PASS'; ErrorCode=$null; Evidence='verified' } } -CoreCheckpointWriter $checkpoint
        $coreCalls | Should -Be @('opencode:Install','opencode:Configure','engram:Install','engram:Configure','graphify:Install','graphify:Configure')
        $checkpointCounter.Value | Should -Be 12
        @($receipt.components | ForEach-Object state | Select-Object -Unique) | Should -Be @('VERIFIED')
    }

    It 'runs core exactly once after one interactive approval and reports the core result' {
        $versions = @{ git='2.53.0'; node='22.17.0'; pnpm='11.8.0'; python='3.13.5'; uv='0.11.14'; opencode='1.17.8'; engram='1.16.3'; graphify='0.8.41'; winget=$null }
        $resolver = { param($id) [pscustomobject]@{ Present=$true; Usable=$true; Version=$versions[$id] } }.GetNewClosure()
        $receipt = New-InstallReceipt -KitVersion '0.2.0-rc.1' -LockDigest ('a' * 64) -SourceCommit 'test'
        $calls=[Collections.Generic.List[string]]::new(); $answers=[pscustomobject]@{ Count=0 }
        $executor={ param($c,$p); if($p -eq 'Install'){$calls.Add($c.id)}; [pscustomobject]@{Success=$true;Evidence=$p} }.GetNewClosure()
        $reader={ $answers.Count++; 'INSTALL' }.GetNewClosure()
        $json = & (Join-Path $repoRoot 'installer/commands/install.ps1') -Root $repoRoot -Json -KitRoot (Join-Path $TestDrive 'approved') -CommandResolver $resolver -ConfirmationReader $reader -CoreReceipt $receipt -CoreExecutor $executor -CoreVerifier { [pscustomobject]@{Status='PASS'} } -CoreCheckpointWriter { param($candidate) }
        $document=$json|ConvertFrom-Json -Depth 20
        $answers.Count | Should -Be 1
        $calls | Should -Be @('opencode','engram','graphify')
        $document.state | Should -Be 'COMPLETED'
        $document.coreResult.Status | Should -Be 'COMPLETED'
    }

    It 'does not run core after interactive cancellation' {
        $versions = @{ git='2.53.0'; node='22.17.0'; pnpm='11.8.0'; python='3.13.5'; uv='0.11.14'; opencode='1.17.8'; engram='1.16.3'; graphify='0.8.41'; winget=$null }
        $resolver = { param($id) [pscustomobject]@{ Present=$true; Usable=$true; Version=$versions[$id] } }.GetNewClosure()
        $calls=[Collections.Generic.List[string]]::new(); $executor={ param($c,$p); $calls.Add($c.id); [pscustomobject]@{Success=$true} }.GetNewClosure()
        $json = & (Join-Path $repoRoot 'installer/commands/install.ps1') -Root $repoRoot -Json -KitRoot (Join-Path $TestDrive 'cancel') -CommandResolver $resolver -ConfirmationReader { 'NO' } -CoreExecutor $executor
        $document=$json|ConvertFrom-Json -Depth 20
        $calls.Count | Should -Be 0
        $document.state | Should -Be 'CANCELED'
        $document.coreResult | Should -BeNullOrEmpty
    }
}

Describe 'pinned core component lock' {
    It 'pins verified immutable Engram provenance and the Graphify artifact digest' {
        $engram = $lock.components | Where-Object id -CEQ 'engram'
        $engram.version | Should -Be '1.16.3'
        $engram.integrityStatus | Should -Be 'verified'
        $engram.install.allowed | Should -BeTrue
        $engram.source.url | Should -Be 'https://github.com/Gentleman-Programming/engram/releases/download/v1.16.3/engram_1.16.3_windows_amd64.zip'
        $engram.source.sha256 | Should -Be '7e26447bf79040c79583f4cbd8acac4665e3c73ebc4eeb25d911763204dc0089'
        $engram.source.provenance | Should -Be 'project-pinned-verified-download'
        $graphify=$lock.components | Where-Object id -CEQ 'graphify'
        $graphify.source.sha256 | Should -Be 'ac2134b89a801e1a8bdf8f9b2bf2ac273c60e8cb8745f5818e6b22098002ebe3'
        $graphify.ownedTargets | Should -Contain 'uv-tool-bin:graphify.exe'
    }
}

Describe 'CoreComponents installer' {
    BeforeEach {
        $script:calls = [Collections.Generic.List[object]]::new()
        $script:process = {
            param($FilePath,$Arguments)
            $script:calls.Add([pscustomobject]@{ FilePath=$FilePath; Arguments=[string[]]@($Arguments) })
            [pscustomobject]@{ ExitCode=0; StdOut=''; StdErr='' }
        }
    }

    It 'uses exact argument arrays for OpenCode and Graphify' {
        $layout=Join-Path $TestDrive 'exact-layout'; $uvBin=Join-Path $layout 'uv-bin'; New-Item -ItemType Directory $layout,$uvBin | Out-Null
        $pnpm=Join-Path $layout 'pnpm.cmd'; $open=Join-Path $layout 'opencode.cmd'; $uv=Join-Path $layout 'uv.exe'; $graph=Join-Path $uvBin 'graphify.exe'
        Set-Content $pnpm 'pnpm'; Set-Content $uv 'uv'
        $state=[pscustomobject]@{ OpenInstalled=$false; GraphInstalled=$false }; $callList=$script:calls
        $resolver={ param($name); if($name -ceq 'pnpm'){@($pnpm)}elseif($name -ceq 'opencode' -and $state.OpenInstalled){@($open)}elseif($name -ceq 'uv'){@($uv)}else{@()} }.GetNewClosure()
        $process={
            param($file,$arguments)
            $callList.Add([pscustomobject]@{FilePath=[string]$file;Arguments=[string[]]@($arguments)})
            if($file -ceq $pnpm){$state.OpenInstalled=$true; Set-Content $open 'open'; return [pscustomobject]@{ExitCode=0;StdOut='';StdErr=''}}
            if($file -ceq $uv -and (@($arguments) -join ' ') -ceq 'tool dir --bin'){return [pscustomobject]@{ExitCode=0;StdOut=$uvBin;StdErr=''}}
            if($file -ceq $uv){$state.GraphInstalled=$true; Set-Content $graph 'graph'; return [pscustomobject]@{ExitCode=0;StdOut='';StdErr=''}}
            if($file -ceq $open){return [pscustomobject]@{ExitCode=0;StdOut='opencode 1.17.8';StdErr=''}}
            if($file -ceq $graph){return [pscustomobject]@{ExitCode=0;StdOut='graphify 0.8.41';StdErr=''}}
            [pscustomobject]@{ExitCode=9;StdOut='';StdErr='unexpected'}
        }.GetNewClosure()
        (Install-CoreComponent -Component ($lock.components|Where-Object id -CEQ 'opencode') -KitRoot $TestDrive -ProcessInvoker $process -CommandResolver $resolver).Status | Should -Be 'INSTALLED'
        (Install-CoreComponent -Component ($lock.components|Where-Object id -CEQ 'graphify') -KitRoot $TestDrive -ProcessInvoker $process -CommandResolver $resolver).Status | Should -Be 'INSTALLED'
        @($script:calls | Where-Object FilePath -CEQ $pnpm)[0].Arguments | Should -Be @('add','--global','opencode-ai@1.17.8')
        @($script:calls | Where-Object { $_.FilePath -ceq $uv -and $_.Arguments[1] -ceq 'install' })[0].Arguments | Should -Be @('tool','install','graphifyy==0.8.41')
    }

    It 'selects the Windows OpenCode cmd shim when a ps1 shim is discovered first' {
        $bin = Join-Path $TestDrive 'opencode-layout'; New-Item -ItemType Directory $bin | Out-Null
        $ps1 = Join-Path $bin 'opencode.ps1'; $cmd = Join-Path $bin 'opencode.cmd'; $pnpm = Join-Path $bin 'pnpm.cmd'
        Set-Content $ps1 '# powershell shim'; Set-Content $cmd '@echo off'; Set-Content $pnpm '@echo off'
        $calls = [Collections.Generic.List[object]]::new(); $probe = [pscustomobject]@{ Count=0 }
        $resolver = {
            param($name)
            if ($name -ceq 'opencode') { return @($ps1,$cmd) }
            if ($name -ceq 'pnpm') { return @($pnpm) }
            @()
        }.GetNewClosure()
        $process = {
            param($file,$arguments)
            $calls.Add([pscustomobject]@{ FilePath=[string]$file; Arguments=[string[]]@($arguments) })
            if ($file -ceq $cmd -and $arguments[0] -ceq '--version') {
                $probe.Count++; return [pscustomobject]@{ ExitCode=0; StdOut=$(if($probe.Count -eq 1){'opencode 1.17.7'}else{'opencode 1.17.8'}); StdErr='' }
            }
            [pscustomobject]@{ ExitCode=0; StdOut='installed'; StdErr='' }
        }.GetNewClosure()

        $result = Install-CoreComponent -Component ($lock.components | Where-Object id -CEQ 'opencode') -KitRoot $TestDrive -CommandResolver $resolver -ProcessInvoker $process

        $result.Action | Should -Be 'UPDATE_TO_PINNED'
        $result.Target | Should -Be $cmd
        @($calls.FilePath) | Should -Not -Contain $ps1
        @($calls | Where-Object { $_.Arguments[0] -ceq '--version' }).FilePath | Should -Be @($cmd,$cmd)
    }

    It 'owns the uv tool executable and ignores an older Graphify earlier on PATH' {
        $oldBin = Join-Path $TestDrive 'old-path'; $uvCommandBin=Join-Path $TestDrive 'uv-command'; $ownedBin = Join-Path $TestDrive 'uv-tool-bin'; New-Item -ItemType Directory $oldBin,$uvCommandBin,$ownedBin | Out-Null
        $oldGraphify = Join-Path $oldBin 'graphify.exe'; $ownedGraphify = Join-Path $ownedBin 'graphify.exe'; $uv = Join-Path $uvCommandBin 'uv.exe'
        Set-Content $oldGraphify 'old'; Set-Content $ownedGraphify 'uv-owned-old'; Set-Content $uv 'uv'
        $calls = [Collections.Generic.List[object]]::new(); $state = [pscustomobject]@{ Installed=$false }
        $process = {
            param($file,$arguments)
            $calls.Add([pscustomobject]@{ FilePath=[string]$file; Arguments=[string[]]@($arguments) })
            if ($file -ceq $uv -and @($arguments) -join ' ' -ceq 'tool dir --bin') { return [pscustomobject]@{ ExitCode=0; StdOut=$ownedBin; StdErr='' } }
            if ($file -ceq $uv -and $arguments[0] -ceq 'tool' -and $arguments[1] -ceq 'install') { $state.Installed=$true; return [pscustomobject]@{ ExitCode=0; StdOut='installed'; StdErr='' } }
            if ($file -ceq $ownedGraphify) { return [pscustomobject]@{ ExitCode=0; StdOut=$(if($state.Installed){'graphify 0.8.41'}else{'graphify 0.8.40'}); StdErr='' } }
            if ($file -ceq $oldGraphify) { return [pscustomobject]@{ ExitCode=0; StdOut='graphify 0.8.39'; StdErr='' } }
            [pscustomobject]@{ ExitCode=9; StdOut=''; StdErr='unexpected command' }
        }.GetNewClosure()

        $savedPath=$env:PATH
        try {
            $env:PATH="$oldBin;$uvCommandBin;$savedPath"
            (Get-Command graphify -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source | Should -Be $oldGraphify
            $result = Install-CoreComponent -Component ($lock.components | Where-Object id -CEQ 'graphify') -KitRoot $TestDrive -ProcessInvoker $process
        }
        finally { $env:PATH=$savedPath }

        $result.Action | Should -Be 'UPDATE_TO_PINNED'
        $result.Target | Should -Be $ownedGraphify
        @($calls.FilePath) | Should -Not -Contain $oldGraphify
        @($calls | Where-Object FilePath -CEQ $ownedGraphify).Count | Should -Be 2
    }

    It 'uses deterministic Windows paths for OpenCode and Graphify version verification' {
        $bin = Join-Path $TestDrive 'verification-layout'; $ownedBin = Join-Path $TestDrive 'verification-uv-bin'; New-Item -ItemType Directory $bin,$ownedBin | Out-Null
        $ps1=Join-Path $bin 'opencode.ps1'; $cmd=Join-Path $bin 'opencode.cmd'; $uv=Join-Path $bin 'uv.exe'; $old=Join-Path $bin 'graphify.exe'; $owned=Join-Path $ownedBin 'graphify.exe'
        foreach($path in @($ps1,$cmd,$uv,$old,$owned)){Set-Content $path 'fixture'}
        $calls=[Collections.Generic.List[string]]::new()
        $resolver={ param($name); if($name -ceq 'opencode'){@($ps1,$cmd)}elseif($name -ceq 'uv'){@($uv)}elseif($name -ceq 'graphify'){@($old)}else{@()} }.GetNewClosure()
        $process={ param($file,$arguments); $calls.Add([string]$file); if($file -ceq $uv){[pscustomobject]@{ExitCode=0;StdOut=$ownedBin;StdErr=''}}elseif($file -ceq $cmd){[pscustomobject]@{ExitCode=0;StdOut='opencode 1.17.8';StdErr=''}}elseif($file -ceq $owned -and $arguments[0] -ceq 'extract'){$out=Join-Path $arguments[1] 'graphify-out';New-Item -ItemType Directory $out|Out-Null;Set-Content (Join-Path $out 'graph.json') '{}';[pscustomobject]@{ExitCode=0;StdOut='built';StdErr=''}}elseif($file -ceq $owned -and $arguments[0] -ceq 'query'){[pscustomobject]@{ExitCode=0;StdOut='hello';StdErr=''}}elseif($file -ceq $owned){[pscustomobject]@{ExitCode=0;StdOut='graphify 0.8.41';StdErr=''}}else{[pscustomobject]@{ExitCode=0;StdOut='0.0.0';StdErr=''}} }.GetNewClosure()

        (Invoke-VerificationId -Id 'opencode.version' -ExpectedVersion '1.17.8' -CommandResolver $resolver -ProcessInvoker $process).Status | Should -Be 'PASS'
        (Invoke-VerificationId -Id 'graphify.version' -ExpectedVersion '0.8.41' -CommandResolver $resolver -ProcessInvoker $process).Status | Should -Be 'PASS'
        (Invoke-VerificationId -Id 'graphify.query' -CommandResolver $resolver -ProcessInvoker $process).Status | Should -Be 'PASS'
        @($calls) | Should -Not -Contain $ps1
        @($calls) | Should -Not -Contain $old
        @($calls) | Should -Contain $cmd
        @($calls) | Should -Contain $owned
    }

    It 'reuses exact compatible package tools and reinstalls a detected mismatch at the pin' {
        $exact = Install-CoreComponent -Component ($lock.components | Where-Object id -CEQ 'opencode') -KitRoot $TestDrive -CommandResolver { 'opencode.exe' } -ProcessInvoker {
            param($file,$arguments); [pscustomobject]@{ ExitCode=0; StdOut='opencode 1.17.8'; StdErr='' }
        }
        $exact.Status | Should -Be 'REUSED'

        $script:mismatchCalls = [Collections.Generic.List[object]]::new(); $mismatchCalls=$script:mismatchCalls
        $bin=Join-Path $TestDrive 'mismatch-uv-bin'; New-Item -ItemType Directory $bin|Out-Null; $graph=Join-Path $bin 'graphify.exe'; $uv=Join-Path $TestDrive 'mismatch-uv.exe'; Set-Content $graph old; Set-Content $uv uv
        $probe=[pscustomobject]@{ Count=0 }; $resolver={param($name);if($name -ceq 'uv'){@($uv)}else{@()}}.GetNewClosure()
        $mismatch = Install-CoreComponent -Component ($lock.components | Where-Object id -CEQ 'graphify') -KitRoot $TestDrive -CommandResolver $resolver -ProcessInvoker {
            param($file,$arguments); $mismatchCalls.Add([pscustomobject]@{FilePath=$file;Arguments=[string[]]@($arguments)});
            if ($file -ceq $uv -and (@($arguments)-join ' ') -ceq 'tool dir --bin') { [pscustomobject]@{ExitCode=0;StdOut=$bin;StdErr=''} }
            elseif ($arguments[0] -eq '--version') { $probe.Count++; [pscustomobject]@{ ExitCode=0; StdOut=$(if($probe.Count -eq 1){'graphify 0.8.40'}else{'graphify 0.8.41'}); StdErr='' } }
            else { [pscustomobject]@{ ExitCode=0; StdOut='installed'; StdErr='' } }
        }.GetNewClosure()
        $mismatch.Status | Should -Be 'INSTALLED'
        $mismatch.Action | Should -Be 'UPDATE_TO_PINNED'
        $mismatch.PreviousVersion | Should -Be '0.8.40'
        @($script:mismatchCalls | Where-Object { $_.FilePath -ceq $uv -and $_.Arguments[1] -ceq 'install' })[0].Arguments | Should -Be @('tool','install','graphifyy==0.8.41')
    }

    It 'fails closed when a pinned package install does not produce the exact version' {
        { Install-CoreComponent -Component ($lock.components | Where-Object id -CEQ 'opencode') -KitRoot $TestDrive -CommandResolver { 'opencode.exe' } -ProcessInvoker {
            param($file,$arguments); if($arguments[0] -eq '--version'){[pscustomobject]@{ExitCode=0;StdOut='opencode 1.17.7';StdErr=''}}else{[pscustomobject]@{ExitCode=0;StdOut='installed';StdErr=''}}
        } } | Should -Throw 'COMPONENT_VERSION_MISMATCH:opencode:expected:1.17.8:actual:1.17.7*'
    }

    It 'does not checkpoint INSTALLED or VERIFIED when the post-install version probe mismatches' {
        $component = $lock.components | Where-Object id -CEQ 'opencode' | ConvertTo-Json -Depth 20 | ConvertFrom-Json -Depth 20
        $component.dependencies = @()
        $receipt = New-InstallReceipt -KitVersion '0.2.0-rc.1' -LockDigest ('a' * 64) -SourceCommit 'test'
        $checkpoints = [Collections.Generic.List[string]]::new()
        $executor = {
            param($candidate,$phase)
            if ($phase -ceq 'Configure') { return [pscustomobject]@{ Success=$true; Evidence='configured' } }
            try {
                $evidence = Install-CoreComponent -Component $candidate -KitRoot $TestDrive -CommandResolver { 'opencode.exe' } -ProcessInvoker {
                    param($file,$arguments)
                    if ($arguments[0] -ceq '--version') { [pscustomobject]@{ ExitCode=0; StdOut='opencode 1.17.7'; StdErr='' } }
                    else { [pscustomobject]@{ ExitCode=0; StdOut='installed'; StdErr='' } }
                }
                [pscustomobject]@{ Success=$true; Evidence=$evidence }
            }
            catch { [pscustomobject]@{ Success=$false; Evidence=$_.Exception.Message } }
        }.GetNewClosure()
        $result = Invoke-ComponentPlan -Components @($component) -Receipt $receipt -Executor $executor -Verifier { [pscustomobject]@{ Status='PASS' } } -CheckpointWriter {
            param($candidate)
            $state = @($candidate.components | Where-Object id -CEQ 'opencode')[0].state
            $checkpoints.Add($state)
        }.GetNewClosure()

        $result.Status | Should -Be 'FAILED'
        $result.Evidence | Should -BeLike 'COMPONENT_VERSION_MISMATCH:opencode:expected:1.17.8:actual:1.17.7*'
        $checkpoints | Should -Be @('PLANNED')
        @($receipt.components | Where-Object id -CEQ 'opencode')[0].state | Should -Be 'PLANNED'
    }

    It 'reuses an exact existing Engram and does not download' {
        $root = Join-Path $TestDrive 'reuse'; $bin = Join-Path $root 'bin'; New-Item -ItemType Directory $bin -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $bin 'engram.exe') -Value 'existing' -NoNewline
        $downloaded = $false
        $process = { [pscustomobject]@{ ExitCode=0; StdOut='engram 1.16.3'; StdErr='' } }
        $result = Install-CoreComponent -Component ($lock.components | Where-Object id -CEQ 'engram') -KitRoot $root -ProcessInvoker $process -Downloader { $script:downloaded=$true }
        $result.Status | Should -Be 'REUSED'
        $downloaded | Should -BeFalse
        (Get-Content -Raw (Join-Path $bin 'engram.exe')) | Should -Be 'existing'
    }

    It 'updates an existing Engram mismatch only after the pinned archive verifies' {
        $root = Join-Path $TestDrive 'mismatch'; $bin = Join-Path $root 'bin'; New-Item -ItemType Directory $bin -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $bin 'engram.exe') -Value 'old' -NoNewline
        $payload=Join-Path $TestDrive 'mismatch-payload'; New-Item -ItemType Directory $payload|Out-Null; Set-Content -LiteralPath (Join-Path $payload 'engram.exe') -Value 'new' -NoNewline
        $archive=Join-Path $TestDrive 'mismatch.zip'; Compress-Archive -Path (Join-Path $payload 'engram.exe') -DestinationPath $archive
        $component=$lock.components|Where-Object id -CEQ 'engram'|ConvertTo-Json -Depth 10|ConvertFrom-Json; $component.source.sha256=(Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        $probe=[pscustomobject]@{Count=0}
        $downloader=({param($u,$d) Copy-Item $archive $d}).GetNewClosure(); $process=({ $probe.Count++; [pscustomobject]@{ExitCode=0;StdOut=$(if($probe.Count -eq 1){'engram 1.16.2'}else{'engram 1.16.3'});StdErr=''} }).GetNewClosure()
        $result=Install-CoreComponent -Component $component -KitRoot $root -Downloader $downloader -ProcessInvoker $process
        $result.Action | Should -Be 'UPDATE_TO_PINNED'
        (Get-Content -Raw (Join-Path $bin 'engram.exe')) | Should -Be 'new'
    }

    It 'verifies checksum before publishing and cleans failed staging' {
        $component = $lock.components | Where-Object id -CEQ 'engram'
        $root = Join-Path $TestDrive 'bad-hash'
        { Install-CoreComponent -Component $component -KitRoot $root -Downloader { param($Uri,$Destination) [IO.File]::WriteAllText($Destination,'bad') } -ProcessInvoker $script:process } | Should -Throw 'CHECKSUM_MISMATCH*'
        Test-Path (Join-Path $root 'bin/engram.exe') | Should -BeFalse
        @(Get-ChildItem $root -Recurse -Filter '*.stage*').Count | Should -Be 0
    }

    It 'publishes a verified Engram archive atomically and exclusively' {
        $component = $lock.components | Where-Object id -CEQ 'engram' | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $payload = Join-Path $TestDrive 'payload'; New-Item -ItemType Directory $payload | Out-Null
        Set-Content -LiteralPath (Join-Path $payload 'engram.exe') -Value 'new-exe' -NoNewline
        $archive = Join-Path $TestDrive 'source.zip'; Compress-Archive -Path (Join-Path $payload 'engram.exe') -DestinationPath $archive
        $component.source.sha256 = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        $result = Install-CoreComponent -Component $component -KitRoot (Join-Path $TestDrive 'kit') -Downloader { param($Uri,$Destination) Copy-Item $archive $Destination } -ProcessInvoker { [pscustomobject]@{ ExitCode=0; StdOut='engram 1.16.3'; StdErr='' } }
        $result.Status | Should -Be 'INSTALLED'
        (Get-Content -Raw (Join-Path $TestDrive 'kit/bin/engram.exe')) | Should -Be 'new-exe'
    }
}

Describe 'real functional verification handlers with hermetic processes' {
    It 'persists an Engram canary across two process invocations in one isolated data dir' {
        $script:calls = [Collections.Generic.List[object]]::new()
        $result = Test-EngramPersistence -EngramPath 'fake-engram.exe' -TempRoot $TestDrive -ProcessInvoker {
            param($FilePath,$Arguments,$Environment)
            $script:calls.Add([pscustomobject]@{ FilePath=$FilePath; Arguments=[string[]]@($Arguments); DataDir=$Environment.ENGRAM_DATA_DIR })
            if ($Arguments[0] -eq 'search') { return [pscustomobject]@{ ExitCode=0; StdOut=$Arguments[1]; StdErr='' } }
            [pscustomobject]@{ ExitCode=0; StdOut='saved'; StdErr='' }
        }
        $result.Success | Should -BeTrue
        $script:calls.Count | Should -Be 2
        $script:calls[0].Arguments[0] | Should -Be 'save'
        $script:calls[1].Arguments[0] | Should -Be 'search'
        $script:calls[0].DataDir | Should -Be $script:calls[1].DataDir
        Test-Path $script:calls[0].DataDir | Should -BeFalse
    }

    It 'builds and queries the Graphify fixture and requires hello in query output' {
        $script:calls = [Collections.Generic.List[object]]::new()
        $result = Test-GraphifyFixture -GraphifyPath 'fake-graphify.exe' -FixturePath $fixture -TempRoot $TestDrive -ProcessInvoker {
            param($FilePath,$Arguments)
            $script:calls.Add([pscustomobject]@{ FilePath=$FilePath; Arguments=[string[]]@($Arguments) })
            if ($Arguments[0] -eq 'extract') {
                $out = Join-Path $Arguments[1] 'graphify-out'; New-Item -ItemType Directory $out | Out-Null; Set-Content (Join-Path $out 'graph.json') '{}'
                return [pscustomobject]@{ ExitCode=0; StdOut='built'; StdErr='' }
            }
            [pscustomobject]@{ ExitCode=0; StdOut='hello'; StdErr='' }
        }
        $result.Success | Should -BeTrue
        $script:calls[0].Arguments[0] | Should -Be 'extract'
        $script:calls[0].Arguments[-1] | Should -Be '--no-cluster'
        $script:calls[1].Arguments[0] | Should -Be 'query'
        $script:calls[1].Arguments[1] | Should -Be 'hello'
    }

    It 'fails Graphify verification on build, query, or missing hello' {
        (Test-GraphifyFixture -GraphifyPath x -FixturePath $fixture -TempRoot $TestDrive -ProcessInvoker { [pscustomobject]@{ ExitCode=1; StdOut=''; StdErr='build failed' } }).Success | Should -BeFalse
        (Test-GraphifyFixture -GraphifyPath x -FixturePath $fixture -TempRoot $TestDrive -ProcessInvoker { param($f,$a); if($a[0]-eq'extract'){ $o=Join-Path $a[1] 'graphify-out'; New-Item -ItemType Directory $o | Out-Null; Set-Content (Join-Path $o 'graph.json') '{}'; [pscustomobject]@{ExitCode=0;StdOut='';StdErr=''} } else { [pscustomobject]@{ExitCode=0;StdOut='absent';StdErr=''} } }).Success | Should -BeFalse
    }
}
