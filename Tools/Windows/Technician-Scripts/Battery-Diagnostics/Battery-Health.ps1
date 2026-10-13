$ErrorActionPreference = "Stop"

$UsbRoot = (Get-Item -LiteralPath $PSScriptRoot).PSDrive.Root
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Computer = $env:COMPUTERNAME -replace '[^\w-]', '_'

$ReportDir = Join-Path $UsbRoot "Reports\Battery-$Computer-$Timestamp"
# Optional managed-session output. Standalone behavior remains unchanged when unset.
if ($env:COC_REPORT_OUTPUT) {
    $cocRoot = [IO.Path]::GetPathRoot($PSScriptRoot)
    Import-Module (Join-Path $cocRoot 'Scripts\Toolkit\COC.Core.psm1') -Force
    $ReportDir = Get-CocReportDestination -Root $cocRoot -Path $env:COC_REPORT_OUTPUT
}

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

$HtmlReport = Join-Path $ReportDir "Battery-Report.html"
$TextReport = Join-Path $ReportDir "Battery-Summary.txt"

Write-Host "Generating Windows battery report..." -ForegroundColor Cyan

& "$env:SystemRoot\System32\powercfg.exe" /batteryreport /output "$HtmlReport"

if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $HtmlReport)) {
    throw "Windows could not generate a battery report. The computer may not have a supported battery."
}

Write-Host "Collecting battery information..." -ForegroundColor Cyan

$Battery = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)

$Lines = @(
    "COC BATTERY HEALTH DIAGNOSTICS"
    "Computer: $Computer"
    "Collected: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    ""
    "Battery devices detected: $($Battery.Count)"
    ""
)

if ($Battery.Count -gt 0) {
    $Lines += ($Battery |
        Select-Object Name, BatteryStatus, EstimatedChargeRemaining, DesignVoltage |
        Format-List | Out-String)
} else {
    $Lines += "Windows did not expose battery information through Win32_Battery."
}

$Lines += @(
    ""
    "See Battery-Report.html for:"
    "- Design capacity"
    "- Full charge capacity"
    "- Cycle count, if available"
    "- Battery capacity history"
    "- Battery usage and life estimates"
    ""
    "Battery wear formula:"
    "Wear % = (1 - FullChargeCapacity / DesignCapacity) * 100"
    ""
    "Note: Capacity estimates depend on information reported by the battery controller."
)

# Calculate capacity-based health from the Windows battery report.
$Html = Get-Content -LiteralPath $HtmlReport -Raw

function Get-BatteryField {
    param([string]$Label)

    $Pattern = [regex]::Escape($Label) + '(?s:.{0,300}?)<td[^>]*>\s*([\d,]+)\s*mWh'
    $Match = [regex]::Match($Html, $Pattern, 'IgnoreCase')

    if ($Match.Success) {
        return [double]($Match.Groups[1].Value -replace ',', '')
    }

    return $null
}

$DesignCapacity = Get-BatteryField "DESIGN CAPACITY"
$FullChargeCapacity = Get-BatteryField "FULL CHARGE CAPACITY"

if ($null -ne $DesignCapacity -and
    $null -ne $FullChargeCapacity -and
    $DesignCapacity -gt 0) {

    $Health = ($FullChargeCapacity / $DesignCapacity) * 100
    $Wear = (1 - ($FullChargeCapacity / $DesignCapacity)) * 100

    $Lines += @(
        ""
        "=== CALCULATED BATTERY HEALTH ==="
        "Design capacity: $DesignCapacity mWh"
        "Full charge capacity: $FullChargeCapacity mWh"
        "Capacity health: $([math]::Round($Health, 2))%"
        "Calculated wear: $([math]::Round($Wear, 2))%"
    )
} else {
    $Lines += "Automatic capacity calculation unavailable. Review HTML report."
}
$Lines | Set-Content -LiteralPath $TextReport -Encoding UTF8

Write-Host ""
Write-Host "Battery diagnostics completed." -ForegroundColor Green
Write-Host "Report folder: $ReportDir" -ForegroundColor Yellow

