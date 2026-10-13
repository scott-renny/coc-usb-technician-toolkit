[CmdletBinding()]
param([switch]$HashAll)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'COC.Core.psm1') -Force
$root=[IO.Path]::GetPathRoot($PSScriptRoot);$volume=Assert-CocUsb $root
Write-Host ('USB capacity {0:N2} GB; free {1:N2} GB; reserve requirement 15 GB' -f ($volume.Size/1GB),($volume.SizeRemaining/1GB))
if($volume.SizeRemaining -lt 15GB){Write-Warning 'USB reserve below requirement.'}
$manifest=Join-Path $root 'Documentation\toolkit-integrity.csv'
if(-not(Test-Path -LiteralPath $manifest)){throw 'Toolkit integrity baseline missing.'}
$rows=foreach($entry in Import-Csv -LiteralPath $manifest){
    $path=Join-Path $root $entry.Path
    $state='NOT TESTED';$actual=''
    try{
        $null=Assert-CocPath -Root $root -Path $path
        if(-not(Test-Path -LiteralPath $path -PathType Leaf)){$state='FAIL'}
        elseif(-not $HashAll -and $entry.Path -like 'ISO\*'){$state='NOT TESTED'}
        else{Write-Host ('Hashing '+$entry.Path);$actual=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;$state=if($actual -eq $entry.SHA256){'PASS'}else{'FAIL'}}
    }catch{$state='FAIL';$actual=$_.Exception.Message}
    [pscustomobject]@{Path=$entry.Path;Result=$state;Expected=$entry.SHA256;Actual=$actual}
}
$rows|Format-Table Path,Result -AutoSize|Out-Host
$session=New-CocSession -Root $root -Category Diagnostics
try{
    $rows|Export-Csv -LiteralPath (Join-Path $session.Path 'integrity.csv') -NoTypeInformation
    Get-ChildItem -LiteralPath (Join-Path $root 'Tools') -Recurse -File -Filter '*.exe'|ForEach-Object{
        [pscustomobject]@{Path=$_.FullName.Substring($root.Length);Bytes=$_.Length;Version=$_.VersionInfo.FileVersion;SHA256=if($HashAll){(Get-FileHash -LiteralPath $_.FullName).Hash}else{'NOT TESTED'}}
    }|Export-Csv -LiteralPath (Join-Path $session.Path 'tool-inventory.csv') -NoTypeInformation
    Get-Disk | Select-Object Number,FriendlyName,BusType,Size,HealthStatus,OperationalStatus | Out-String | Set-Content -LiteralPath (Join-Path $session.Path 'storage-health.txt')
}finally{Complete-CocSession $session}
if(@($rows|Where-Object Result -eq FAIL).Count){exit 1};exit 0
