# COC Network Diagnostics Toolkit
# Version 1.0 - Read-only collection

$ErrorActionPreference = 'Continue'

$UsbRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ReportFolder = Join-Path $UsbRoot 'Reports\Network'
# Optional managed-session output. Standalone behavior remains unchanged when unset.
if ($env:COC_REPORT_OUTPUT) {
    $cocRoot = [IO.Path]::GetPathRoot($PSScriptRoot)
    Import-Module (Join-Path $cocRoot 'Scripts\Toolkit\COC.Core.psm1') -Force
    $ReportFolder = Get-CocReportDestination -Root $cocRoot -Path $env:COC_REPORT_OUTPUT
}

New-Item -ItemType Directory -Path $ReportFolder -Force | Out-Null

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Computer = $env:COMPUTERNAME
$Report = Join-Path $ReportFolder "Network-$Computer-$Timestamp.txt"

function Add-Section {
    param(
        [string]$Title,
        [scriptblock]$Command
    )

    "`r`n========== $Title ==========" | Out-File $Report -Append

    try {
        & $Command |
            Out-String -Width 240 |
            Out-File $Report -Append
    }
    catch {
        "ERROR: $($_.Exception.Message)" |
            Out-File $Report -Append
    }
}

"COC NETWORK DIAGNOSTICS" | Out-File $Report
"Computer: $Computer" | Out-File $Report -Append
"Date: $(Get-Date -Format o)" | Out-File $Report -Append

Add-Section 'Network Adapters' {
    Get-NetAdapter |
        Format-Table Name, InterfaceDescription, Status, LinkSpeed, MacAddress -AutoSize
}

Add-Section 'IP Configuration' {
    Get-NetIPConfiguration -Detailed | Format-List *
}

Add-Section 'IPv4 and IPv6 Addresses' {
    Get-NetIPAddress |
        Format-Table InterfaceAlias, AddressFamily, IPAddress, PrefixLength, PrefixOrigin -AutoSize
}

Add-Section 'DNS Servers' {
    Get-DnsClientServerAddress |
        Format-Table InterfaceAlias, AddressFamily, ServerAddresses -Wrap
}

Add-Section 'DHCP Configuration' {
    Get-NetIPInterface |
        Format-Table InterfaceAlias, AddressFamily, Dhcp, ConnectionState -AutoSize
}

Add-Section 'Default Routes' {
    Get-NetRoute |
        Where-Object DestinationPrefix -in @('0.0.0.0/0', '::/0') |
        Format-Table InterfaceAlias, DestinationPrefix, NextHop, RouteMetric -AutoSize
}

Add-Section 'Network Profiles' {
    Get-NetConnectionProfile | Format-List *
}

Add-Section 'Adapter Statistics' {
    Get-NetAdapterStatistics | Format-List *
}

Add-Section 'TCP Connectivity - Cloudflare HTTPS' {
    Test-NetConnection -ComputerName 1.1.1.1 -Port 443 |
        Select-Object ComputerName, RemoteAddress, RemotePort, TcpTestSucceeded |
        Format-List
}

Add-Section 'DNS Resolution' {
    Resolve-DnsName -Name example.com -Type A |
        Select-Object Name, Type, IPAddress |
        Format-Table -AutoSize
}

Write-Host "`nNetwork diagnostics completed." -ForegroundColor Green
Write-Host "Report: $Report" -ForegroundColor Cyan
