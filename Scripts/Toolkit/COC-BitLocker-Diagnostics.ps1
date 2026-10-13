[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'COC.Core.psm1') -Force
$session=New-CocSession -Root ([IO.Path]::GetPathRoot($PSScriptRoot)) -Category Diagnostics
$failed=$false
try{
    $lines=New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('BitLocker status and recovery protector IDs only. No password/key retrieval, unlock, suspension or decryption.')
    & "$env:SystemRoot\System32\manage-bde.exe" -status 2>&1 | ForEach-Object{$lines.Add([string]$_)}
    $lines.Add('manage-bde exit: '+$LASTEXITCODE)
    if($LASTEXITCODE -ne 0){$failed=$true}
    $volumes=@(Get-CimInstance -Namespace 'root\CIMV2\Security\MicrosoftVolumeEncryption' -ClassName Win32_EncryptableVolume -ErrorAction Stop)
    foreach($volume in $volumes){
        $protectors=Invoke-CimMethod -InputObject $volume -MethodName GetKeyProtectors -Arguments @{KeyProtectorType=[uint32]3} -ErrorAction Stop
        $lines.Add(('Volume {0}: protector query return {1}' -f $volume.DriveLetter,$protectors.ReturnValue))
        if($protectors.ReturnValue -eq 0){foreach($id in $protectors.VolumeKeyProtectorID){$lines.Add('Recovery protector ID: '+$id)}}
        elseif($protectors.ReturnValue -ne 2150694920){$failed=$true}
    }
    $lines|Set-Content -LiteralPath (Join-Path $session.Path 'bitlocker.txt') -Encoding UTF8
}catch{$failed=$true;('CHECK UNAVAILABLE: '+$_.Exception.Message)|Set-Content -LiteralPath (Join-Path $session.Path 'bitlocker.txt') -Encoding UTF8}
finally{Complete-CocSession $session}
Write-Host "Report: $($session.Path). Use owner/admin recovery UI for key entry; do not put secrets into commands or reports."
if($failed){exit 1};exit 0
