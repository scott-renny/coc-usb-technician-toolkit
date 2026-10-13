[CmdletBinding()]
param([ValidateSet('CheckHealth','ScanHealth','RestoreHealth','SfcVerify','SfcRepair')][string]$Action='CheckHealth',[switch]$Apply)
$ErrorActionPreference='Stop'
$commands = @{
    CheckHealth=@('dism.exe','/Online','/Cleanup-Image','/CheckHealth')
    ScanHealth=@('dism.exe','/Online','/Cleanup-Image','/ScanHealth')
    RestoreHealth=@('dism.exe','/Online','/Cleanup-Image','/RestoreHealth')
    SfcVerify=@('sfc.exe','/verifyonly')
    SfcRepair=@('sfc.exe','/scannow')
}
$command = $commands[$Action]
Write-Host "Target: currently running Windows ($env:SystemRoot) on $env:COMPUTERNAME"
Write-Host ('Command: ' + ($command -join ' '))
Write-Host 'RestoreHealth may use Windows Update. Review CBS/DISM logs and verify symptom after completion.'
if (-not $Apply) { Write-Host 'Preview only. Use -Apply to request execution with typed confirmation.'; exit 0 }
if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT') { throw 'Installed Windows required. Use the offline playbook in WinPE/WinRE.' }
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run from an elevated terminal.' }
Import-Module (Join-Path $PSScriptRoot 'COC.Core.psm1') -Force
$root=[IO.Path]::GetPathRoot($PSScriptRoot)
$null=Assert-CocUsb $root
$phrase="RUN $Action ON $env:COMPUTERNAME"
if ((Read-Host "Confirm backup and stable storage, then type $phrase") -cne $phrase) { Write-Host 'Cancelled.'; exit 0 }
$session=New-CocSession -Root $root -Category Repair
$code=1
try {
    $exe=Join-Path "$env:SystemRoot\System32" $command[0]
    $arguments=@($command | Select-Object -Skip 1)
    & $exe @arguments 2>&1 | Tee-Object -FilePath (Join-Path $session.Path 'result.txt') | Out-Host
    $code=$LASTEXITCODE
    "`r`nNative exit code: $code. Review native output; exit code alone does not prove repair." | Add-Content -LiteralPath (Join-Path $session.Path 'result.txt')
} finally { Complete-CocSession $session }
Write-Host "Result: $($session.Path). Reboot if requested and retest the original symptom."
exit $code
