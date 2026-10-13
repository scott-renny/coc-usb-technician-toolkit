$ErrorActionPreference = 'Stop'

$Root = (Get-Item -LiteralPath $PSScriptRoot).PSDrive.Root
$Disk = Get-Partition -DriveLetter $Root.Substring(0,1) | Get-Disk
$Volume = Get-Volume -DriveLetter $Root.Substring(0,1)

if (
    $Disk.FriendlyName -ne 'Lexar USB Flash Drive' -or
    $Disk.BusType -ne 'USB' -or
    $Volume.FileSystemLabel -ne 'COC_USB_1'
) {
    throw 'COC USB identity verification failed.'
}

$Assessment = Join-Path $PSScriptRoot 'COC-ReadOnly-Health-Assessment-v1.ps1'
$Reports = Join-Path $Root 'Reports'

if (-not (Test-Path -LiteralPath $Assessment -PathType Leaf)) {
    throw 'Assessment script not found.'
}

if (-not (Test-Path -LiteralPath $Reports -PathType Container)) {
    throw 'Reports folder not found.'
}

$Computer = $env:COMPUTERNAME -replace '[^a-zA-Z0-9_-]', '_'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Report = Join-Path $Reports "Health-$Computer-$Timestamp.txt"

Write-Host "`nRunning COC Health Assessment..." -ForegroundColor Cyan

& $Assessment *>&1 | Tee-Object -FilePath $Report

Write-Host "`nReport saved to:" -ForegroundColor Green
Write-Host $Report