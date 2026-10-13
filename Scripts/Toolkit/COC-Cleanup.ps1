[CmdletBinding()]
param([switch]$Interactive)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'COC.Core.psm1') -Force
$root=[IO.Path]::GetPathRoot($PSScriptRoot)
$null=Assert-CocUsb $root
$items=@(Get-CocCleanupCandidates $root -IncludeMetadata)
$usage=Get-PSDrive -Name $root.Substring(0,1)
Write-Host ('USB free: {0:N2} GB; eligible report bytes: {1:N0}; eligible files: {2}' -f ($usage.Free/1GB), (($items|Measure-Object Bytes -Sum).Sum),$items.Count)
if(-not $items.Count){Write-Host 'No eligible completed reports. Active/held sessions, untracked reports and backups are preserved.';exit 0}
for($i=0;$i -lt $items.Count;$i++){Write-Host ('{0}: {1} | {2} | {3} | {4} bytes | {5}' -f ($i+1),$items[$i].Computer,$items[$i].Created,$items[$i].Category,$items[$i].Bytes,$items[$i].Path)}
Write-Host 'Preview only. No target-PC logs or unrelated files are eligible.'
if(-not $Interactive){exit 0}
Write-Host 'Selections: comma-separated file numbers; SESSION=session-name; CATEGORY=Network/Hardware/Diagnostics/Repair/Migration/Temporary; ALL; Enter cancels.'
$selection=Read-Host 'Select completed reports'
if([string]::IsNullOrWhiteSpace($selection)){Write-Host 'Cancelled.';exit 0}
$chosen=@(Select-CocCleanupCandidate -Candidates $items -Selection $selection)
if(-not $chosen.Count){Write-Host 'Selection contains no eligible files.';exit 0}
$chosen|Select-Object Path,Bytes|Format-Table -AutoSize|Out-Host
$total=($chosen|Measure-Object Bytes -Sum).Sum
Write-Host "Exact preview: $($chosen.Count) files; $total bytes. Confirm retention requirements and investigation holds before deleting."
$phrase='DELETE '+$chosen.Count+' COC REPORT FILES'
$result=Invoke-CocCleanupBatch -Root $root -Candidates $chosen -Confirmation (Read-Host "Type exactly $phrase")
if($result.Cancelled){Write-Host 'Cancelled.';exit 0}
$result.Results|Format-Table -AutoSize|Out-Host
Write-Host "Deleted logical bytes: $($result.DeletedBytes); failures: $($result.Failures). Unselected/held/untracked files preserved. Empty session folders are retained."
$after=Get-PSDrive -Name $root.Substring(0,1)
Write-Host ('Observed free-space change: {0:N0} bytes (allocation rounding and concurrent writes can affect this value).' -f ($after.Free-$usage.Free))
if($result.Failures){exit 2};exit 0
