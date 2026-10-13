# COC Wi-Fi Diagnostics
# Version 1.0 - Read-only collection
# Does not export Wi-Fi passwords or modify connections.

$ErrorActionPreference = 'Stop'

$UsbRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ReportFolder = Join-Path $UsbRoot 'Reports\Network'
# Optional managed-session output. Standalone behavior remains unchanged when unset.
if ($env:COC_REPORT_OUTPUT) {
    $cocRoot = [IO.Path]::GetPathRoot($PSScriptRoot)
    Import-Module (Join-Path $cocRoot 'Scripts\Toolkit\COC.Core.psm1') -Force
    $ReportFolder = Get-CocReportDestination -Root $cocRoot -Path $env:COC_REPORT_OUTPUT
}

New-Item -ItemType Directory -Path $ReportFolder -Force -ErrorAction Stop | Out-Null

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Computer = $env:COMPUTERNAME
$Report = Join-Path $ReportFolder "WiFi-$Computer-$Timestamp.txt"

function Add-Section {
    param(
        [string]$Title,
        [scriptblock]$Command
    )

    "`r`n========== $Title ==========" |
        Out-File -LiteralPath $Report -Append -Encoding utf8

    try {
        $Result = & $Command 2>&1 | Out-String -Width 240

        $Result | Out-File -LiteralPath $Report -Append -Encoding utf8
    }
    catch {
        "ERROR: $($_.Exception.Message)" |
            Out-File -LiteralPath $Report -Append -Encoding utf8
    }
}

"COC WI-FI DIAGNOSTICS" |
    Out-File -LiteralPath $Report -Encoding utf8

"Computer: $Computer" |
    Out-File -LiteralPath $Report -Append -Encoding utf8

"Date: $(Get-Date -Format o)" |
    Out-File -LiteralPath $Report -Append -Encoding utf8

Add-Section 'WLAN Service' {
    Get-Service -Name WlanSvc -ErrorAction Stop |
        Select-Object Name, Status, StartType |
        Format-Table -AutoSize
}

Add-Section 'Wireless Interfaces and Signal' {
    netsh wlan show interfaces
}

Add-Section 'Wireless Driver Capabilities' {
    netsh wlan show drivers
}

Add-Section 'Visible Wireless Networks' {
    netsh wlan show networks mode=bssid
}

Add-Section 'Wireless Adapter Details' {
    Get-NetAdapter |
        Where-Object {
            $_.InterfaceDescription -match 'Wireless|Wi-Fi|802\.11|WLAN|MT7921'
        } |
        Format-List Name, InterfaceDescription, Status, LinkSpeed, DriverInformation
}

Add-Section 'Wireless IP Configuration' {
    Get-NetIPConfiguration |
        Where-Object {
            $_.InterfaceAlias -match 'Wi-Fi|Wireless|WLAN'
        } |
        Format-List *
}

Add-Section 'Wireless Adapter Statistics' {
    Get-NetAdapterStatistics |
        Where-Object {
            $_.Name -match 'Wi-Fi|Wireless|WLAN'
        } |
        Format-List *
}

Write-Host "`nWi-Fi diagnostics completed." -ForegroundColor Green
Write-Host "Report: $Report" -ForegroundColor Cyan
Write-Host "Note: Report may contain SSIDs, BSSIDs and MAC addresses."
