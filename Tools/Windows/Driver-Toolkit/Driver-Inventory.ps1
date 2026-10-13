$ErrorActionPreference = 'Stop'

$Root = (Get-Item -LiteralPath $PSScriptRoot).PSDrive.Root
$Letter = $Root.Substring(0,1)

$Disk = Get-Partition -DriveLetter $Letter | Get-Disk
$Volume = Get-Volume -DriveLetter $Letter

if (
    $Disk.FriendlyName -ne 'Lexar USB Flash Drive' -or
    $Disk.BusType -ne 'USB' -or
    $Volume.FileSystemLabel -ne 'COC_USB_1'
) {
    throw 'COC USB verification failed.'
}

$Computer = $env:COMPUTERNAME -replace '[^a-zA-Z0-9_-]', '_'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ReportFolder = Join-Path $Root "Reports\Drivers-$Computer-$Timestamp"
# Optional managed-session output. Standalone behavior remains unchanged when unset.
if ($env:COC_REPORT_OUTPUT) {
    $cocRoot = [IO.Path]::GetPathRoot($PSScriptRoot)
    Import-Module (Join-Path $cocRoot 'Scripts\Toolkit\COC.Core.psm1') -Force
    $ReportFolder = Get-CocReportDestination -Root $cocRoot -Path $env:COC_REPORT_OUTPUT
}

New-Item -ItemType Directory -Path $ReportFolder -Force | Out-Null

Write-Host "`nCollecting installed driver information..." -ForegroundColor Cyan

$Drivers = Get-CimInstance Win32_PnPSignedDriver |
    Select-Object DeviceName, Manufacturer, DriverProviderName,
        DriverVersion, DriverDate, InfName, IsSigned, DeviceID

$Drivers |
    Sort-Object DeviceName |
    Export-Csv -LiteralPath (Join-Path $ReportFolder 'Installed-Drivers.csv') `
        -NoTypeInformation -Encoding UTF8

$Problems = @(
    Get-CimInstance Win32_PnPEntity |
        Where-Object { $_.ConfigManagerErrorCode -ne 0 } |
        Select-Object Name, DeviceID, ConfigManagerErrorCode, Status
)

$Problems |
    Export-Csv -LiteralPath (Join-Path $ReportFolder 'Device-Problems.csv') `
        -NoTypeInformation -Encoding UTF8

$Summary = @(
    'COC DRIVER INVENTORY'
    "Computer: $Computer"
    "Date: $(Get-Date)"
    "Drivers inventoried: $(@($Drivers).Count)"
    "Devices reporting errors: $($Problems.Count)"
    ''
    'Driver inventory is read-only.'
    'A signed driver is not necessarily compatible or trustworthy.'
)

$Summary |
    Set-Content -LiteralPath (Join-Path $ReportFolder 'Summary.txt') -Encoding UTF8

Write-Host "`nDRIVER INVENTORY COMPLETE" -ForegroundColor Green
Write-Host "Drivers inventoried: $(@($Drivers).Count)"
Write-Host "Devices reporting errors: $($Problems.Count)"
Write-Host "Report: $ReportFolder"
