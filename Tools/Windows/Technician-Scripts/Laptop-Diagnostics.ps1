$ErrorActionPreference = "Continue"

$UsbRoot = (Get-Item -LiteralPath $PSScriptRoot).PSDrive.Root
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$SafeComputer = $env:COMPUTERNAME -replace '[^\w-]', '_'
$ReportDir = Join-Path $UsbRoot "Reports\$SafeComputer-$Timestamp"
# Optional managed-session output. Standalone behavior remains unchanged when unset.
if ($env:COC_REPORT_OUTPUT) {
    $cocRoot = [IO.Path]::GetPathRoot($PSScriptRoot)
    Import-Module (Join-Path $cocRoot 'Scripts\Toolkit\COC.Core.psm1') -Force
    $ReportDir = Get-CocReportDestination -Root $cocRoot -Path $env:COC_REPORT_OUTPUT
}

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

function Save-Report {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Host "Collecting $Name..." -ForegroundColor Cyan

    try {
        & $Command |
            Out-String -Width 240 |
            Set-Content -LiteralPath (Join-Path $ReportDir "$Name.txt") -Encoding UTF8
    }
    catch {
        "Collection failed: $($_.Exception.Message)" |
            Set-Content -LiteralPath (Join-Path $ReportDir "$Name-ERROR.txt")
    }
}

Save-Report "01-System" {
    Get-CimInstance Win32_ComputerSystem |
        Select-Object Manufacturer, Model, Name, TotalPhysicalMemory

    Get-CimInstance Win32_OperatingSystem |
        Select-Object Caption, Version, BuildNumber, OSArchitecture, LastBootUpTime

    Get-CimInstance Win32_BIOS |
        Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate, SerialNumber

    Get-CimInstance Win32_Processor |
        Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
}

Save-Report "02-Memory" {
    Get-CimInstance Win32_PhysicalMemory |
        Select-Object Manufacturer, PartNumber, Capacity, Speed, DeviceLocator

    Get-CimInstance Win32_OperatingSystem |
        Select-Object TotalVisibleMemorySize, FreePhysicalMemory
}

Save-Report "03-Storage" {
    Get-CimInstance Win32_DiskDrive |
        Select-Object Model, SerialNumber, Size, InterfaceType, Status

    Get-PhysicalDisk |
        Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, Size

    Get-Volume |
        Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus, Size, SizeRemaining
}

Save-Report "04-Battery" {
    Get-CimInstance Win32_Battery |
        Select-Object Name, BatteryStatus, EstimatedChargeRemaining, DesignVoltage
}

Save-Report "05-Device-Problems" {
    Get-PnpDevice -PresentOnly |
        Where-Object Status -ne "OK" |
        Select-Object Class, FriendlyName, Status, InstanceId
}

Save-Report "06-Recent-Errors" {
    Get-WinEvent -FilterHashtable @{
        LogName = "System"
        Level = 1,2
        StartTime = (Get-Date).AddDays(-7)
    } -MaxEvents 100 -ErrorAction Stop |
        Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message
}

Write-Host ""
Write-Host "Diagnostic collection finished." -ForegroundColor Green
Write-Host "Reports saved to: $ReportDir" -ForegroundColor Yellow


