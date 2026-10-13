# COC USB #1 - Read-only health assessment v1
# Displays findings only. No repairs, file output, or configuration changes.
# Run in the Windows installation of the laptop being diagnosed.

& {
    $ErrorActionPreference = 'Stop'
    $Findings = New-Object 'System.Collections.Generic.List[object]'

    function Add-Finding {
        param([string]$Check, [string]$Status, [string]$Detail)
        $Findings.Add([pscustomobject]@{
            Check = $Check
            Status = $Status
            Detail = $Detail
        })
    }

    Write-Host "`nCOC READ-ONLY HEALTH ASSESSMENT" -ForegroundColor Cyan
    Write-Host "Computer: $env:COMPUTERNAME"
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host 'Scope: the currently running Windows system.'
    Write-Host 'REVIEW = investigate; UNKNOWN = data unavailable.'
    Write-Host ''

    try {
        $OS = Get-CimInstance Win32_OperatingSystem
        $PC = Get-CimInstance Win32_ComputerSystem
        Add-Finding 'System' 'INFO' (
            '{0} {1}; {2}; last boot {3}' -f
            $PC.Manufacturer, $PC.Model, $OS.Caption, $OS.LastBootUpTime
        )
        $TotalGB = [math]::Round($PC.TotalPhysicalMemory / 1GB, 1)
        $FreeGB = [math]::Round(($OS.FreePhysicalMemory * 1KB) / 1GB, 1)
        Add-Finding 'Memory' 'INFO' (
            "$TotalGB GB installed; $FreeGB GB currently available. This is not a RAM test."
        )
    } catch {
        Add-Finding 'System / memory' 'UNKNOWN' $_.Exception.Message
    }

    try {
        $Disks = @(Get-Disk)
        if ($Disks.Count -eq 0) {
            Add-Finding 'Disk status' 'UNKNOWN' 'No disks returned.'
        }
        foreach ($Disk in $Disks) {
            $Operations = @($Disk.OperationalStatus) -join ', '
            $Status = 'REVIEW'
            if (
                "$($Disk.HealthStatus)" -eq 'Healthy' -and
                $Operations -eq 'Online'
            ) {
                $Status = 'OK'
            }
            Add-Finding "Disk $($Disk.Number)" $Status (
                '{0}; bus {1}; health {2}; operation {3}. Provider status only.' -f
                $Disk.FriendlyName, $Disk.BusType, $Disk.HealthStatus, $Operations
            )
        }
    } catch {
        Add-Finding 'Disk status' 'UNKNOWN' $_.Exception.Message
    }

    try {
        $Volumes = @(Get-Volume | Where-Object {
            $_.DriveType -eq 'Fixed' -and $_.Size -gt 0
        })
        if ($Volumes.Count -eq 0) {
            Add-Finding 'Free space' 'UNKNOWN' 'No fixed volumes returned.'
        }
        foreach ($Volume in $Volumes) {
            $FreePercent = 100 * $Volume.SizeRemaining / $Volume.Size
            $Status = 'OK'
            if ($FreePercent -lt 10) { $Status = 'REVIEW' }
            $Name = $Volume.DriveLetter
            if (-not $Name) { $Name = $Volume.Path }
            Add-Finding "Volume $Name" $Status (
                '{0:N1}% free ({1:N1} GB); health {2}' -f
                $FreePercent, ($Volume.SizeRemaining / 1GB), $Volume.HealthStatus
            )
            if ("$($Volume.HealthStatus)" -ne 'Healthy') {
                Add-Finding "Volume $Name health" 'REVIEW' "$($Volume.HealthStatus)"
            }
        }
    } catch {
        Add-Finding 'Free space / volumes' 'UNKNOWN' $_.Exception.Message
    }

    try {
        $Devices = @(Get-CimInstance Win32_PnPEntity | Where-Object {
            $null -ne $_.ConfigManagerErrorCode -and
            $_.ConfigManagerErrorCode -ne 0
        })
        if ($Devices.Count -eq 0) {
            Add-Finding 'Device errors' 'OK' 'No nonzero device error codes reported.'
        }
        foreach ($Device in $Devices) {
            Add-Finding 'Device errors' 'REVIEW' (
                '{0}; device error code {1}' -f
                $Device.Name, $Device.ConfigManagerErrorCode
            )
        }
    } catch {
        Add-Finding 'Device errors' 'UNKNOWN' $_.Exception.Message
    }

    try {
        $Batteries = @(Get-CimInstance Win32_Battery)
        if ($Batteries.Count -eq 0) {
            Add-Finding 'Battery' 'INFO' 'No battery reported by Windows.'
        }
        foreach ($Battery in $Batteries) {
            Add-Finding 'Battery' 'INFO' (
                '{0}; charge {1}%; status code {2}. Capacity wear is not assessed.' -f
                $Battery.Name, $Battery.EstimatedChargeRemaining,
                $Battery.BatteryStatus
            )
        }
    } catch {
        Add-Finding 'Battery' 'UNKNOWN' $_.Exception.Message
    }

    $Findings | Format-Table -Wrap -AutoSize

    $ReviewCount = @($Findings | Where-Object Status -eq 'REVIEW').Count
    $UnknownCount = @($Findings | Where-Object Status -eq 'UNKNOWN').Count
    Write-Host "Review findings: $ReviewCount | Unavailable checks: $UnknownCount"
    Write-Host 'This screening does not certify hardware health.'
    Write-Host 'Separate memory, SMART, temperature, and stability checks remain necessary.'
}