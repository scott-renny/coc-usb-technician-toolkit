[CmdletBinding()]
param([ValidateSet('Laptop','Battery','Auto','Network','WiFi','DHCP','DNS','Connectivity','Firewall','Drivers')][string]$Name='Auto')
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'COC.Core.psm1') -Force
$root=[IO.Path]::GetPathRoot($PSScriptRoot)
$map=@{
Laptop='Tools\Windows\Technician-Scripts\Laptop-Diagnostics.ps1'
Battery='Tools\Windows\Technician-Scripts\Battery-Diagnostics\Battery-Health.ps1'
Auto='Tools\Windows\Technician-Scripts\COC-Automated-Session-v2.ps1'
Network='Scripts\Network\COC-Network-Diagnostics.ps1'
WiFi='Scripts\Network\COC-WiFi-Diagnostics.ps1'
DHCP='Scripts\Network\COC-DHCP-Diagnostics.ps1'
DNS='Scripts\Network\COC-DNS-Diagnostics.ps1'
Connectivity='Scripts\Network\COC-Connectivity-Diagnostics.ps1'
Firewall='Scripts\Network\COC-Firewall-Diagnostics.ps1'
Drivers='Tools\Windows\Driver-Toolkit\Driver-Inventory.ps1'
}
$script=Join-Path $root $map[$Name];$null=Assert-CocUsb $root
$null=Assert-CocPath -Root $root -Path $script
if(-not(Test-Path -LiteralPath $script -PathType Leaf)){throw 'Canonical collector missing.'}
$category=if($Name -in @('Network','WiFi','DHCP','DNS','Connectivity','Firewall')){'Network'}elseif($Name -in @('Laptop','Battery','Drivers')){'Hardware'}else{'Diagnostics'}
$session=New-CocSession -Root $root -Category $category
$old=$env:COC_REPORT_OUTPUT;$failed=$false
try{
    $env:COC_REPORT_OUTPUT=$session.Path
    & $script
    # Existing collectors can explicitly report unavailable checks; collection is not certification.
}catch{$failed=$true;Protect-CocReportText ('COLLECTOR FAILED: '+$_.Exception.Message)|Set-Content -LiteralPath (Join-Path $session.Path 'collector-error.txt')}
finally{$env:COC_REPORT_OUTPUT=$old;Complete-CocSession $session}
Write-Host "Managed output: $($session.Path). Review all findings/unavailable checks; no health certification is inferred."
if($failed){exit 2};exit 0
