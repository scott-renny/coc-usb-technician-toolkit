# COC DHCP Diagnostics
# Version 1.0 - Read-only DHCP troubleshooting

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
$Report = Join-Path $ReportFolder "DHCP-$Computer-$Timestamp.txt"

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

"COC DHCP DIAGNOSTICS" |
    Out-File -LiteralPath $Report -Encoding utf8

"Computer: $Computer" |
    Out-File -LiteralPath $Report -Append -Encoding utf8

"Date: $(Get-Date -Format o)" |
    Out-File -LiteralPath $Report -Append -Encoding utf8

Add-Section 'DHCP Interface Configuration' {
    Get-NetIPInterface -AddressFamily IPv4 |
        Select-Object InterfaceAlias, ConnectionState, Dhcp |
        Format-Table -AutoSize
}

Add-Section 'DHCP Lease Information' {
    Get-CimInstance Win32_NetworkAdapterConfiguration |
        Where-Object { $_.IPEnabled } |
        Select-Object Description, DHCPEnabled, DHCPServer,
            DHCPLeaseObtained, DHCPLeaseExpires |
        Format-Table -AutoSize
}

Add-Section 'IPv4 Address Assignment' {
    Get-NetIPAddress -AddressFamily IPv4 |
        Select-Object InterfaceAlias, IPAddress, PrefixLength,
            PrefixOrigin, AddressState |
        Format-Table -AutoSize
}

Add-Section 'APIPA Address Detection' {
    $Addresses = @(
        Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object { $_.IPAddress -like '169.254.*' }
    )

    if ($Addresses.Count -eq 0) {
        'No APIPA addresses detected.'
    }
    else {
        $Addresses |
            Select-Object InterfaceAlias, IPAddress, AddressState |
            Format-Table -AutoSize
    }
}

Add-Section 'Default IPv4 Gateways' {
    Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
        Select-Object InterfaceAlias, NextHop, RouteMetric |
        Format-Table -AutoSize
}

Add-Section 'DHCP Lease Health' {
    $Now = Get-Date

    Get-CimInstance Win32_NetworkAdapterConfiguration |
        Where-Object { $_.IPEnabled -and $_.DHCPEnabled } |
        ForEach-Object {
            $Expiry = $_.DHCPLeaseExpires

            $Status = if (-not $Expiry) {
                'Lease expiration unavailable'
            }
            elseif ($Expiry -lt $Now) {
                'EXPIRED'
            }
            elseif ($Expiry -lt $Now.AddHours(2)) {
                'Expires within 2 hours'
            }
            else {
                'Valid'
            }

            [pscustomobject]@{
                Adapter = $_.Description
                DHCPServer = $_.DHCPServer
                Expires = $Expiry
                Status = $Status
            }
        } |
        Format-Table -AutoSize
}

Add-Section 'Recent DHCP Administrative Events' {
    $Log = 'Microsoft-Windows-Dhcp-Client/Admin'

    if (Get-WinEvent -ListLog $Log -ErrorAction SilentlyContinue) {
        Get-WinEvent -FilterHashtable @{
            LogName = $Log
            StartTime = (Get-Date).AddDays(-7)
        } -MaxEvents 20 -ErrorAction SilentlyContinue |
            Select-Object TimeCreated, Id, LevelDisplayName,
                @{Name='Message';Expression={
                    ($_.Message -replace '\s+', ' ').Trim()
                }} |
            Format-Table -Wrap
    }
    else {
        'DHCP administrative event log unavailable.'
    }
}

Write-Host "`nDHCP diagnostics completed." -ForegroundColor Green
Write-Host "Report: $Report" -ForegroundColor Cyan
