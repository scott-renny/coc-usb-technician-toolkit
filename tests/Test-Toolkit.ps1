$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'Scripts\Toolkit\COC.Core.psm1') -Force
$results=New-Object 'System.Collections.Generic.List[object]'
function Assert([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Check([string]$Name,[scriptblock]$Body){try{& $Body;$results.Add([pscustomobject]@{Test=$Name;Result='PASS'})}catch{$results.Add([pscustomobject]@{Test=$Name;Result='FAIL'});Write-Warning ($Name+': '+$_.Exception.Message)}}
$fixture=Join-Path $PSScriptRoot ('.test-work\'+[guid]::NewGuid().ToString('N'))
$session=Join-Path (Join-Path $fixture 'Reports\COC-Managed') ('COC-20261013-120000-'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory $session -Force
'owned report'|Set-Content (Join-Path $session 'system.txt')
'unrelated personal content'|Set-Content (Join-Path $session 'personal.txt')
$case=[pscustomobject]@{Path=$session;Category='Diagnostics';Started='2026-10-13T12:00:00'}
Complete-CocSession $case
Check 'All PowerShell files parse' {
 foreach($f in Get-ChildItem $root -Recurse -File | Where-Object Extension -in '.ps1','.psm1'){
  $t=$null;$e=$null;[void][Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$t,[ref]$e);Assert (@($e).Count -eq 0) ('Syntax: '+$f.Name)
 }
}
Check 'Untracked personal files are excluded' {
 $items=@(Get-CocCleanupCandidates $fixture)
 Assert ($items.Count -eq 1 -and $items[0].Path -eq (Join-Path $session 'system.txt')) 'Unexpected cleanup selection'
}
Check 'Wrong typed confirmation cancels without deletion' {
 $items=@(Get-CocCleanupCandidates $fixture)
 $r=Invoke-CocCleanupBatch -Root $fixture -Candidates $items -Confirmation 'DELETE WRONG COUNT'
 Assert ($r.Cancelled -and (Test-Path (Join-Path $session 'system.txt'))) 'Cancellation changed files'
}
Check 'Hold excludes an entire case' {
 'retain'|Set-Content (Join-Path $session '.coc-hold')
 Assert (@(Get-CocCleanupCandidates $fixture).Count -eq 0) 'Held case eligible'
}
# Use a second case rather than deleting the hold; test output remains available for inspection.
$second=Join-Path (Join-Path $fixture 'Reports\COC-Managed') ('COC-20261013-120001-'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory $second
'original'|Set-Content (Join-Path $second 'system.txt')
Complete-CocSession ([pscustomobject]@{Path=$second;Category='Diagnostics';Started='2026-10-13T12:00:01'})
'modified'|Set-Content (Join-Path $second 'system.txt')
Check 'Changed report hash is excluded' {Assert (@(Get-CocCleanupCandidates $fixture).Count -eq 0) 'Changed report eligible'}
Check 'Path traversal and sibling prefix are refused' {
 foreach($bad in @((Join-Path $fixture '..\outside.txt'),($fixture+'-sibling\file.txt'))){$blocked=$false;try{$null=Assert-CocPath -Root $fixture -Path $bad}catch{$blocked=$true};Assert $blocked 'Out-of-root path accepted'}
}
Check 'Window padding handles narrow and wide consoles' {
 foreach($width in @(60,70,100,140)){
  $out=@(& (Join-Path $root 'Scripts\Toolkit\COC-Console-Layout.ps1') -Columns $width -Rows 50 -ContentHeight 30)
  Assert ($out[0].Substring(3).Length -eq [Math]::Max(0,[Math]::Floor(($width-70)/2))) 'Horizontal padding'
  Assert (@($out|Where-Object {$_ -eq 'B:X'}).Count -eq 10) 'Vertical padding'
 }
}
$results|Export-Csv (Join-Path $root 'docs\publication-tests.csv') -NoTypeInformation
$results|Format-Table -AutoSize
if(@($results|Where-Object Result -eq FAIL).Count){exit 1}
