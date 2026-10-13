# COC Firewall Diagnostics v1.0
# Read-only Windows Firewall assessment

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
$Report = Join-Path $Folder "Firewall-$env:COMPUTERNAME-$Stamp.txt"

$Sections = [System.Collections.Generic.List[string]]::new()

function Add-Section {
    param(
        [string]$Title,
        [object]$Data
    )

    $Sections.Add("========== $Title ==========")
    $Sections.Add(($Data | Out-String -Width 220))
}

Add-Section 'Firewall Profiles' (
    Get-NetFirewallProfile |
        Select-Object Name, Enabled, DefaultInboundAction,
            DefaultOutboundAction, AllowInboundRules,
            AllowLocalFirewallRules
)

Add-Section 'Active Network Profiles' (
    Get-NetConnectionProfile |
        Select-Object Name, InterfaceAlias, NetworkCategory,
            IPv4Connectivity, IPv6Connectivity
)

Add-Section 'Effective Firewall Profiles' (
    Get-NetFirewallProfile -PolicyStore ActiveStore |
        Select-Object Name, Enabled, DefaultInboundAction,
            DefaultOutboundAction
)

Add-Section 'Firewall Services' (
    Get-Service -Name BFE, MpsSvc -ErrorAction SilentlyContinue |
        Select-Object Name, DisplayName, Status, StartType
)

$BlockingRules = @(
    Get-NetFirewallRule -PolicyStore ActiveStore -Enabled True -Action Block -ErrorAction SilentlyContinue
)

Add-Section 'Enabled Blocking Rule Summary' (
    [pscustomobject]@{
        TotalEnabledBlockingRules = $BlockingRules.Count
        Inbound = @($BlockingRules | Where-Object Direction -eq Inbound).Count
        Outbound = @($BlockingRules | Where-Object Direction -eq Outbound).Count
    }
)

Add-Section 'Blocking Rules By Profile' (
    $BlockingRules |
        Group-Object Profile |
        Select-Object Name, Count
)

Add-Section 'Firewall Logging Configuration' (
    Get-NetFirewallProfile |
        Select-Object Name, LogAllowed, LogBlocked,
            LogFileName, LogMaxSizeKilobytes
)

$Sections | Set-Content -LiteralPath $Report -Encoding utf8

Write-Host "`n=== FIREWALL DIAGNOSTICS ===" -ForegroundColor Cyan

Get-NetFirewallProfile |
    Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
    Format-Table -AutoSize

Write-Host "Enabled blocking rules: $($BlockingRules.Count)"
Write-Host "Report: $Report"
