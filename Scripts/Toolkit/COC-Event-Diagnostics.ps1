[CmdletBinding()]
param([ValidateSet('System','Application','Security','Microsoft-Windows-WindowsUpdateClient/Operational','Microsoft-Windows-GroupPolicy/Operational')][string]$Log='System',[ValidateRange(1,168)][int]$Hours=24,[ValidateRange(1,2000)][int]$MaxEvents=200,[int[]]$EventId,[ValidateSet(0,1,2,3,4,5)][int[]]$Level=@(1,2,3),[string]$Provider,[switch]$SecurityAuthorized,[switch]$IncludeMessages)
$ErrorActionPreference='Stop'
if($Log -eq 'Security' -and -not $SecurityAuthorized){throw 'Security-log collection requires explicit -SecurityAuthorized and legitimate authorization.'}
if($Log -eq 'Security' -and -not $PSBoundParameters.ContainsKey('Level')){$Level=@(0)}
Import-Module (Join-Path $PSScriptRoot 'COC.Core.psm1') -Force
$session=New-CocSession -Root ([IO.Path]::GetPathRoot($PSScriptRoot)) -Category Diagnostics
$failed=$false
try{
    $filter=@{LogName=$Log;StartTime=(Get-Date).AddHours(-$Hours);Level=$Level}
    if($EventId){$filter.Id=$EventId};if($Provider){$filter.ProviderName=$Provider}
    $events=Get-WinEvent -FilterHashtable $filter -MaxEvents $MaxEvents -ErrorAction Stop
    $fields=@('TimeCreated','Id','ProviderName','LevelDisplayName')
    if($IncludeMessages){$fields+='Message';Write-Host 'Messages are explicitly requested. Pattern redaction cannot detect every secret; review and protect the resulting report.'}
    $text=$events|Select-Object $fields|Format-List|Out-String -Width 240
    Protect-CocReportText $text|Set-Content -LiteralPath (Join-Path $session.Path 'events.txt') -Encoding UTF8
}catch{
    if($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*'){'NO MATCHING EVENTS for the selected filters. This does not certify health/security.'|Set-Content -LiteralPath (Join-Path $session.Path 'events.txt')}
    else{$failed=$true;Protect-CocReportText ('CHECK FAILED: '+$_.Exception.Message)|Set-Content -LiteralPath (Join-Path $session.Path 'events.txt')}
}
finally{Complete-CocSession $session}
if($failed){exit 2};exit 0
