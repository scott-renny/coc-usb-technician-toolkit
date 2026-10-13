[CmdletBinding()]
param([ValidateSet('Index','Baseline','Compare','Handover','Hold','Release','NewTemp','CompleteTemp')][string]$Action='Index',[string]$First,[string]$Second,[string]$SessionName)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'COC.Core.psm1') -Force
$root=[IO.Path]::GetPathRoot($PSScriptRoot);$null=Assert-CocUsb $root
$managed=Join-Path $root 'Reports\COC-Managed'
if($Action -eq 'NewTemp'){
    $session=New-CocSession -Root $root -Category Diagnostics
    'Default retention hold for sensitive diagnostic trace/dump. Release only after investigation/retention review.'|Set-Content -LiteralPath (Join-Path $session.Path '.coc-hold')
    Write-Host "Temporary diagnostic output directory: $($session.Path)"
    Write-Host 'Only save explicitly authorized tool outputs as PerfView.etl, Procmon.pml, CrashDump.dmp or temporary.txt here. CompleteTemp records hashes; Release requires explicit retention approval.'
    exit 0
}
if($Action -in @('Hold','Release','CompleteTemp')){
    if($SessionName -notmatch '^COC-\d{8}-\d{6}-[a-f0-9]{32}$'){throw 'Exact managed session name required.'}
    $path=Join-Path $managed $SessionName;$null=Assert-CocPath -Root $managed -Path $path
    if(-not(Test-Path -LiteralPath (Join-Path $path '.coc-session.json'))){throw 'Managed session missing.'}
    $hold=Join-Path $path '.coc-hold';$null=Assert-CocPath -Root $managed -Path $hold
    if($Action -eq 'CompleteTemp'){
        $data=Get-Content -LiteralPath (Join-Path $path '.coc-session.json') -Raw|ConvertFrom-Json
        if($data.Generator -ne 'COC-Functional-Update' -or $data.State -ne 'Active'){throw 'Active toolkit-created temporary session required.'}
        $files=@(Get-ChildItem -LiteralPath $path -File|Where-Object Name -notin '.coc-session.json','.coc-hold')
        if(@($files|Where-Object Name -notin 'PerfView.etl','Procmon.pml','CrashDump.dmp','temporary.txt').Count){throw 'Unexpected files in temporary session; preserve and review.'}
        if(($files|Measure-Object Length -Sum).Sum -gt 4GB){throw 'Temporary session exceeds 4 GB reports/working budget; use separate protected evidence storage.'}
        $files|Select-Object FullName,Length|Format-Table -AutoSize|Out-Host
        if((Read-Host "Confirm toolkit-generated outputs; type COMPLETE TEMP $SessionName") -cne "COMPLETE TEMP $SessionName"){exit 0}
        Complete-CocSession ([pscustomobject]@{Path=$path;Category=$data.Category;Started=$data.Started})
        Write-Host 'Output hashes recorded; retention hold remains until separately released.';exit 0
    }
    if($Action -eq 'Hold'){'Retention hold. Do not delete.'|Set-Content -LiteralPath $hold;Write-Host 'Hold applied.'}
    elseif(Test-Path -LiteralPath $hold){if((Read-Host "Type RELEASE HOLD $SessionName after authorization") -cne "RELEASE HOLD $SessionName"){exit 0};Remove-Item -LiteralPath $hold -ErrorAction Stop;Write-Host 'Hold released.'}
    exit 0
}
$session=New-CocSession -Root $root -Category Diagnostics
try{
    switch($Action){
        Index{
            $rows=foreach($dir in Get-ChildItem -LiteralPath $managed -Directory){
                try{$null=Assert-CocPath -Root $managed -Path $dir.FullName;$data=Get-Content -LiteralPath (Join-Path $dir.FullName '.coc-session.json') -Raw|ConvertFrom-Json
                    [pscustomobject]@{Session=$dir.Name;Computer=$data.Computer;Started=$data.Started;Category=$data.Category;State=$data.State;Held=Test-Path -LiteralPath (Join-Path $dir.FullName '.coc-hold');Bytes=(Get-ChildItem -LiteralPath $dir.FullName -File|Measure-Object Length -Sum).Sum}
                }catch{Write-Warning "Skipped invalid case: $($dir.Name)"}
            }
            $rows|Export-Csv -LiteralPath (Join-Path $session.Path 'case-index.csv') -NoTypeInformation
            $rows|Format-Table -AutoSize|Out-Host
        }
        Baseline{
            $data=[ordered]@{Schema=1;Computer=$env:COMPUTERNAME;Created=(Get-Date).ToString('o');OS=@(Get-CimInstance Win32_OperatingSystem|Select-Object Caption,Version,BuildNumber);Services=@(Get-Service|Select-Object Name,Status,StartType);Startup=@(Get-CimInstance Win32_StartupCommand|Select-Object Name,Location);Tasks=@(Get-ScheduledTask|Select-Object TaskPath,TaskName,State);Devices=@(Get-CimInstance Win32_PnPEntity|Select-Object DeviceID,ConfigManagerErrorCode)}
            $data|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $session.Path 'baseline.json') -Encoding UTF8
        }
        Compare{
            foreach($p in @($First,$Second)){$null=Assert-CocPath -Root $managed -Path $p;if((Split-Path $p -Leaf) -ne 'baseline.json'){throw 'Compare only managed baseline.json files.'}}
            $a=Get-Content -LiteralPath $First -Raw|ConvertFrom-Json;$b=Get-Content -LiteralPath $Second -Raw|ConvertFrom-Json
            if($a.Computer -ne $b.Computer){throw 'Baselines belong to different computers.'}
            $rows=foreach($type in @('OS','Services','Startup','Tasks','Devices')){
                $before=@($a.$type|ForEach-Object{$_|ConvertTo-Json -Compress}|Sort-Object);$after=@($b.$type|ForEach-Object{$_|ConvertTo-Json -Compress}|Sort-Object)
                if(-not $before.Count -and -not $after.Count){continue}
                if(-not $before.Count){foreach($value in $after){[pscustomobject]@{Area=$type;Direction='=>';Value=$value}};continue}
                if(-not $after.Count){foreach($value in $before){[pscustomobject]@{Area=$type;Direction='<=';Value=$value}};continue}
                foreach($change in Compare-Object $before $after){[pscustomobject]@{Area=$type;Direction=$change.SideIndicator;Value=$change.InputObject}}
            }
            $rows|Export-Csv -LiteralPath (Join-Path $session.Path 'comparison.csv') -NoTypeInformation
            Write-Host 'Comparison saved. <= removed/before; => added/after. Investigate differences in context.'
        }
        Handover{
            $lines=@('# Technician handover',('Date: '+(Get-Date).ToString('o')),('Computer: '+$env:COMPUTERNAME))
            foreach($field in @('Case ID','Authorized scope','Reported symptom','Backup status','Tests and evidence','Findings','Changes and rollback','Verification result','Outstanding risks','Owner acceptance','Escalation/contact')){$lines+=($field+': '+(Read-Host "$field (no secrets)"))}
            $lines|Set-Content -LiteralPath (Join-Path $session.Path 'handover.md') -Encoding UTF8
        }
    }
}finally{Complete-CocSession $session}
Write-Host "Case output: $($session.Path)"
