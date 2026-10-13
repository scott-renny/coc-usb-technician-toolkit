# COC Windows Installation Discovery v1.0
# Read-only detection. Does not perform repairs.

$Results = foreach ($Volume in Get-Volume) {
    if (-not $Volume.DriveLetter) { continue }

    $Drive = "$($Volume.DriveLetter):\"
    $WindowsPath = Join-Path $Drive 'Windows'
    $SystemHive = Join-Path $WindowsPath 'System32\config\SYSTEM'

    $WindowsFound = $false
    $HiveStatus = 'Not found'

    try {
        $WindowsFound = Test-Path -LiteralPath $WindowsPath -ErrorAction Stop
    }
    catch {
        $HiveStatus = 'Access restricted'
    }

    try {
        if (Test-Path -LiteralPath $SystemHive -ErrorAction Stop) {
            $HiveStatus = 'Found'
        }
    }
    catch [System.UnauthorizedAccessException] {
        $HiveStatus = 'Access restricted'
    }
    catch {
        $HiveStatus = 'Unable to verify'
    }

    [pscustomobject]@{
        Drive = $Drive
        Label = $Volume.FileSystemLabel
        FileSystem = $Volume.FileSystem
        WindowsDirectory = $WindowsFound
        SystemRegistryHive = $HiveStatus
    }
}

Write-Host "`n=== WINDOWS INSTALLATION DISCOVERY ===" -ForegroundColor Cyan
$Results | Format-Table -AutoSize

Write-Host "`nDiscovery only. No repair target has been selected." -ForegroundColor Yellow
