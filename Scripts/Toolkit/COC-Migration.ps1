[CmdletBinding()]
param([Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$Destination,[switch]$Copy)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'COC.Core.psm1') -Force
$sourcePath=[IO.Path]::GetFullPath($Source).TrimEnd('\')
$destPath=[IO.Path]::GetFullPath($Destination).TrimEnd('\')
if ($sourcePath -notmatch '^[A-Za-z]:\\.+' -or $destPath -notmatch '^[A-Za-z]:\\.+') { throw 'Local subdirectories required. Volume roots and network paths are unsupported.' }
if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) { throw 'Source directory missing.' }
if (Test-Path -LiteralPath $destPath) { throw 'Destination must be a new directory; existing destinations are never merged or overwritten.' }
$null=Assert-CocPath -Root ([IO.Path]::GetPathRoot($sourcePath)) -Path $sourcePath
$null=Assert-CocPath -Root ([IO.Path]::GetPathRoot($destPath)) -Path $destPath
$sourceDisk=Get-Partition -DriveLetter $sourcePath.Substring(0,1) | Get-Disk
$destDisk=Get-Partition -DriveLetter $destPath.Substring(0,1) | Get-Disk
if ($sourceDisk.Number -eq $destDisk.Number) { throw 'Backup destination must be on a different physical disk.' }
$toolkitRoot=[IO.Path]::GetPathRoot($PSScriptRoot)
if ([IO.Path]::GetPathRoot($destPath) -eq $toolkitRoot) { throw 'Use a separate backup disk; toolkit USB is reserved for tools and reports.' }
$entries=New-Object 'System.Collections.Generic.List[object]'
$pending=New-Object 'System.Collections.Generic.Queue[string]'
$pending.Enqueue($sourcePath)
while($pending.Count) {
    foreach($entry in Get-ChildItem -LiteralPath $pending.Dequeue() -Force -ErrorAction Stop) {
        if($entry.Attributes -band ([IO.FileAttributes]::ReparsePoint -bor [IO.FileAttributes]::Encrypted -bor [IO.FileAttributes]::Offline)) {
            throw 'Source contains junctions, cloud placeholders, offline or EFS-encrypted items. Resolve these with an authorized migration plan first.'
        }
        $entries.Add($entry)
        if($entry.PSIsContainer){$pending.Enqueue($entry.FullName)}
    }
}
$bytes=($entries | Where-Object {-not $_.PSIsContainer} | Measure-Object Length -Sum).Sum
$volume=Get-Volume -DriveLetter $destPath.Substring(0,1)
if ($volume.SizeRemaining -lt ($bytes + 1GB)) { throw 'Insufficient destination space including 1 GB reserve.' }
$arguments=@($sourcePath,$destPath,'/E','/COPY:DAT','/DCOPY:DAT','/XJ','/R:1','/W:1')
Write-Host "Source: $sourcePath; destination: $destPath; file bytes: $bytes"
Write-Host 'Copies ordinary files and timestamps only. Applications, account credentials, ACLs, and Windows settings are not migrated. No /MIR or /MOVE.'
if (-not $Copy) {
    & "$env:SystemRoot\System32\robocopy.exe" @arguments /L
    $code=$LASTEXITCODE
    if ($code -ge 8) { throw "Preview failed: robocopy code $code" }
    Write-Host 'Preview complete. No copy performed. Review file scope before using -Copy.'
    exit 0
}
$null=Assert-CocUsb $toolkitRoot
if ((Read-Host 'Type COPY DATA TO NEW BACKUP to proceed') -cne 'COPY DATA TO NEW BACKUP') { Write-Host 'Cancelled.'; exit 0 }
# Repeat critical checks immediately before copying. Never overwrite an existing destination.
if (Test-Path -LiteralPath $destPath) { throw 'Destination appeared after preview; aborting.' }
$null=Assert-CocPath -Root ([IO.Path]::GetPathRoot($destPath)) -Path $destPath
$session=New-CocSession -Root $toolkitRoot -Category Migration
try {
    $null=New-Item -ItemType Directory -Path $destPath -ErrorAction Stop
    & "$env:SystemRoot\System32\robocopy.exe" @arguments 2>&1 | Tee-Object -FilePath (Join-Path $session.Path 'migration-copy.txt') | Out-Host
    $code=$LASTEXITCODE
    "Native exit code: $code. Robocopy codes 0-7 are not failures; review skipped/mismatched files and verify backups." | Add-Content -LiteralPath (Join-Path $session.Path 'migration-copy.txt')
    if ($code -ge 8) { throw "Copy incomplete: robocopy code $code. Preserve partial destination and investigate." }
    Write-Host 'Copy completed. Verify file counts, representative hashes and restore a sample before retiring the source.'
} finally { Complete-CocSession $session }
