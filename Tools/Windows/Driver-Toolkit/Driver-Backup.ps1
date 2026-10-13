$ErrorActionPreference = 'Stop'

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($Identity)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    throw 'Run PowerShell as Administrator to export drivers.'
}

$Root = (Get-Item -LiteralPath $PSScriptRoot).PSDrive.Root
$Letter = $Root.Substring(0,1)
$Disk = Get-Partition -DriveLetter $Letter | Get-Disk
$Volume = Get-Volume -DriveLetter $Letter

if (
    $Disk.FriendlyName -ne 'Lexar USB Flash Drive' -or
    $Disk.BusType -ne 'USB' -or
    $Volume.FileSystemLabel -ne 'COC_USB_1' -or
    $Volume.FileSystem -ne 'exFAT'
) {
    throw 'COC USB identity verification failed.'
}

if ($Volume.SizeRemaining -lt 5GB) {
    throw 'Less than 5 GB free on USB. Export cancelled.'
}

$Computer = $env:COMPUTERNAME -replace '[^a-zA-Z0-9_-]', '_'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Destination = Join-Path $Root "Drivers\Backups\$Computer-$Timestamp"

New-Item -ItemType Directory -Path $Destination -ErrorAction Stop | Out-Null

Write-Host "`nCOC DRIVER BACKUP" -ForegroundColor Cyan
Write-Host "Computer: $Computer"
Write-Host "Destination: $Destination"
Write-Host 'Exporting third-party driver packages...'

$Log = Join-Path $Destination 'Export-Log.txt'

& pnputil.exe /export-driver '*' $Destination 2>&1 |
    Out-File -LiteralPath $Log -Encoding UTF8

$ExitCode = $LASTEXITCODE

$Packages = @(
    Get-ChildItem -LiteralPath $Destination -Recurse -File -Filter '*.inf'
)

$Summary = @(
    'COC DRIVER BACKUP'
    "Computer: $Computer"
    "Date: $(Get-Date)"
    "PnPUtil exit code: $ExitCode"
    "Exported INF files: $($Packages.Count)"
    "Destination: $Destination"
    ''
    'Only third-party driver packages are exported.'
    'Some OEM applications and firmware are not included.'
    'Review compatibility before restoring drivers.'
)

$Summary | Set-Content -LiteralPath (
    Join-Path $Destination 'Backup-Summary.txt'
) -Encoding UTF8

if ($ExitCode -ne 0 -or $Packages.Count -eq 0) {
    throw "Driver export incomplete or failed. Review $Log"
}

Write-Host "`nDRIVER BACKUP COMPLETE" -ForegroundColor Green
Write-Host "Exported INF files: $($Packages.Count)"
Write-Host "Saved to: $Destination"
