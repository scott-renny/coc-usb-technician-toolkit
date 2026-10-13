# COC Connectivity Diagnostics v1.0
# Read-only network troubleshooting

$ErrorActionPreference = 'Continue'

$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Folder = Join-Path $Root 'Reports\Network'
# Optional managed-session output. Standalone behavior remains unchanged when unset.
if ($env:COC_REPORT_OUTPUT) {
    $cocRoot = [IO.Path]::GetPathRoot($PSScriptRoot)
    Import-Module (Join-Path $cocRoot 'Scripts\Toolkit\COC.Core.psm1') -Force
    $Folder = Get-CocReportDestination -Root $cocRoot -Path $env:COC_REPORT_OUTPUT
}

New-Item -ItemType Directory -Path $Folder -Force | Out-Null

$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Report = Join-Path $Folder "Connectivity-$env:COMPUTERNAME-$Stamp.txt"

$Results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param(
        [string]$Test,
        [string]$Status,
        [string]$Details
    )

    $Results.Add([pscustomobject]@{
        Test = $Test
        Status = $Status
        Details = $Details
    })
}

$Routes = @(
    Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
        Where-Object { $_.NextHop -ne '0.0.0.0' }
)

if ($Routes.Count -gt 0) {
    $Gateway = $Routes |
        Sort-Object RouteMetric, InterfaceMetric |
        Select-Object -First 1

    Add-Result 'Default Gateway' 'PASS' "$($Gateway.NextHop) via $($Gateway.InterfaceAlias)"

    try {
        $GatewayPing = Test-Connection -TargetName $Gateway.NextHop -Count 2 -Quiet -ErrorAction Stop

        if ($GatewayPing) {
            Add-Result 'Gateway ICMP' 'PASS' 'Gateway responds to ping'
        }
        else {
            Add-Result 'Gateway ICMP' 'WARNING' 'No ICMP response; ping may be blocked'
        }
    }
    catch {
        Add-Result 'Gateway ICMP' 'WARNING' 'Gateway ping unavailable or blocked'
    }
}
else {
    Add-Result 'Default Gateway' 'FAIL' 'No IPv4 default gateway found'
}

try {
    $Internet = Test-NetConnection -ComputerName 1.1.1.1 -Port 443 -WarningAction SilentlyContinue

    if ($Internet.TcpTestSucceeded) {
        Add-Result 'Internet TCP' 'PASS' '1.1.1.1:443 reachable'
    }
    else {
        Add-Result 'Internet TCP' 'FAIL' '1.1.1.1:443 unreachable'
    }
}
catch {
    Add-Result 'Internet TCP' 'FAIL' $_.Exception.Message
}

try {
    $DNS = @(Resolve-DnsName example.com -Type A -DnsOnly -ErrorAction Stop)

    if ($DNS.Count -gt 0) {
        Add-Result 'DNS Resolution' 'PASS' 'example.com resolved'
    }
    else {
        Add-Result 'DNS Resolution' 'FAIL' 'No DNS results'
    }
}
catch {
    Add-Result 'DNS Resolution' 'FAIL' $_.Exception.Message
}

try {
    $HTTPS = Test-NetConnection -ComputerName example.com -Port 443 -WarningAction SilentlyContinue

    if ($HTTPS.TcpTestSucceeded) {
        Add-Result 'HTTPS Connectivity' 'PASS' 'example.com:443 reachable'
    }
    else {
        Add-Result 'HTTPS Connectivity' 'FAIL' 'HTTPS connection failed'
    }
}
catch {
    Add-Result 'HTTPS Connectivity' 'FAIL' $_.Exception.Message
}

$Results |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Set-Content -LiteralPath $Report -Encoding utf8

Write-Host "`n=== CONNECTIVITY ASSESSMENT ===" -ForegroundColor Cyan
$Results | Format-Table -AutoSize

Write-Host "`nReport: $Report" -ForegroundColor Cyan
