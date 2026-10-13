# COC DNS Diagnostics
# Version 1.0 - Read-only DNS troubleshooting

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
$Report = Join-Path $ReportFolder "DNS-$Computer-$Timestamp.txt"

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

"COC DNS DIAGNOSTICS" |
    Out-File -LiteralPath $Report -Encoding utf8

"Computer: $Computer" |
    Out-File -LiteralPath $Report -Append -Encoding utf8

"Date: $(Get-Date -Format o)" |
    Out-File -LiteralPath $Report -Append -Encoding utf8

Add-Section 'Configured DNS Servers' {
    Get-DnsClientServerAddress |
        Format-Table InterfaceAlias, AddressFamily, ServerAddresses -Wrap
}

Add-Section 'DNS Client Configuration' {
    Get-DnsClient |
        Select-Object InterfaceAlias, ConnectionSpecificSuffix,
            RegisterThisConnectionsAddress, UseSuffixWhenRegistering |
        Format-Table -AutoSize
}

Add-Section 'DNS Resolution Tests' {
    $Results = foreach ($Name in @('example.com', 'microsoft.com')) {
        try {
            $Records = @(
                Resolve-DnsName -Name $Name -Type A -DnsOnly -ErrorAction Stop |
                    Where-Object { $_.Type -eq 'A' }
            )

            [pscustomobject]@{
                Domain = $Name
                Success = $Records.Count -gt 0
                Records = $Records.Count
            }
        }
        catch {
            [pscustomobject]@{
                Domain = $Name
                Success = $false
                Records = 0
            }
        }
    }

    $Results | Format-Table -AutoSize
}

Add-Section 'DNS Cache Summary' {
    $Entries = @(Get-DnsClientCache -ErrorAction Stop)

    [pscustomobject]@{
        CachedEntries = $Entries.Count
        Note = 'Cache contents omitted to reduce sensitive browsing data.'
    } | Format-List
}

Add-Section 'DNS Resolution Policies' {
    $Policies = @(Get-DnsClientNrptPolicy -ErrorAction Stop)

    if ($Policies.Count -eq 0) {
        'No DNS namespace resolution policies returned.'
    }
    else {
        $Policies |
            Select-Object Namespace, NameServers, DirectAccessEnabled |
            Format-Table -Wrap
    }
}

Add-Section 'DNS Client Service' {
    Get-Service -Name Dnscache -ErrorAction Stop |
        Select-Object Name, Status, StartType |
        Format-Table -AutoSize
}

Write-Host "`nDNS diagnostics completed." -ForegroundColor Green
Write-Host "Report: $Report" -ForegroundColor Cyan

