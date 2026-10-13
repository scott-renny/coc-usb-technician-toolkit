# COC automated session v2
# Read-only system queries; reports written only to verified USB.
& {
    $ErrorActionPreference = 'Stop'
    $Root = [IO.Path]::GetPathRoot($PSScriptRoot)

    function Confirm-USB {
        $Letter = $Root.Substring(0,1)
        $Disk = Get-Partition -DriveLetter $Letter | Get-Disk
        $Volume = Get-Volume -DriveLetter $Letter
        if (
            $Disk.FriendlyName -ne 'Lexar USB Flash Drive' -or
            $Disk.BusType -ne 'USB' -or
            $Volume.FileSystemLabel -ne 'Ventoy'
        ) {
            throw 'Verified Lexar Ventoy USB required.'
        }
    }

    Confirm-USB
    if (Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT') {
        throw 'Installed Windows required. Offline Windows assessment is not supported.'
    }

    $Reports = Join-Path $Root 'Reports'
    if (-not (Test-Path -LiteralPath $Reports -PathType Container)) {
        throw 'Existing USB Reports folder missing.'
    }

    $Findings = New-Object 'System.Collections.Generic.List[object]'
    $Data = [ordered]@{
        Computer = $env:COMPUTERNAME
        Started = (Get-Date).ToString('o')
        Scope = 'Currently running installed Windows'
    }

    function Add-Finding {
        param($Check, $Status, $Detail, $Next)
        $Findings.Add([pscustomobject]@{
            Check = $Check
            Status = $Status
            Detail = $Detail
            FollowUp = $Next
        })
    }

    function Invoke-Check {
        param($Name, [scriptblock]$Action)
        Write-Host "Checking $Name..."
        try { & $Action }
        catch {
            Add-Finding $Name 'UNKNOWN' $_.Exception.Message (
                'Retry this check in an elevated terminal; investigate if still unavailable.'
            )
        }
    }

    Invoke-Check 'System and memory' {
        $PC = Get-CimInstance Win32_ComputerSystem
        $OS = Get-CimInstance Win32_OperatingSystem
        $Data.System = [pscustomobject]@{
            Manufacturer = $PC.Manufacturer
            Model = $PC.Model
            Windows = $OS.Caption
            Build = $OS.BuildNumber
            LastBoot = $OS.LastBootUpTime
            InstalledMemoryGB = [math]::Round($PC.TotalPhysicalMemory / 1GB, 1)
            AvailableMemoryGB = [math]::Round($OS.FreePhysicalMemory / 1MB, 1)
        }
        Add-Finding 'System' 'INFO' (
            "$($PC.Manufacturer) $($PC.Model); $($OS.Caption)"
        ) 'Record the actual symptom before selecting a repair.'
        Add-Finding 'Memory' 'INFO' (
            "$($Data.System.InstalledMemoryGB) GB installed; " +
            "$($Data.System.AvailableMemoryGB) GB available."
        ) 'For unexplained crashes or memory symptoms, run bootable Memtest86+.'
    }

    Invoke-Check 'Disks' {
        $Items = @(Get-Disk)
        $Data.Disks = @($Items | Select-Object Number, FriendlyName,
            BusType, HealthStatus, OperationalStatus, Size)
        if ($Items.Count -eq 0) { throw 'No disks returned.' }
        foreach ($Item in $Items) {
            $Status = 'REVIEW'
            $Next = 'Inspect SMART with CrystalDiskInfo; protect data before repair.'
            if (
                "$($Item.HealthStatus)" -eq 'Healthy' -and
                (@($Item.OperationalStatus) -join ', ') -eq 'Online'
            ) {
                $Status = 'OK'
                $Next = 'Provider status only; use SMART if storage symptoms persist.'
            }
            Add-Finding "Disk $($Item.Number)" $Status (
                "$($Item.FriendlyName); $($Item.HealthStatus); " +
                "$(@($Item.OperationalStatus) -join ', ')"
            ) $Next
        }
    }

    Invoke-Check 'Volumes' {
        $Items = @(Get-Volume | Where-Object {
            $_.DriveType -eq 'Fixed' -and $_.Size -gt 0
        })
        $Data.Volumes = @($Items | Select-Object DriveLetter, Path,
            FileSystemLabel, HealthStatus, Size, SizeRemaining)
        if ($Items.Count -eq 0) { throw 'No fixed volumes returned.' }
        foreach ($Item in $Items) {
            $Free = [math]::Round(100 * $Item.SizeRemaining / $Item.Size, 1)
            $Name = $Item.DriveLetter
            if (-not $Name) { $Name = $Item.Path }
            $Status = 'OK'
            $Next = ''
            if ($Free -lt 10 -or "$($Item.HealthStatus)" -ne 'Healthy') {
                $Status = 'REVIEW'
                $Next = 'Investigate capacity or volume status; do not alter recovery partitions.'
            }
            Add-Finding "Volume $Name" $Status (
                "$Free percent free; health $($Item.HealthStatus)"
            ) $Next
        }
    }

    Invoke-Check 'Device errors' {
        $Items = @(Get-CimInstance Win32_PnPEntity)
        if ($Items.Count -eq 0) { throw 'No device inventory returned.' }
        $Problems = @($Items | Where-Object {
            $null -ne $_.ConfigManagerErrorCode -and
            $_.ConfigManagerErrorCode -ne 0
        })
        $Data.DeviceErrors = @($Problems | Select-Object Name,
            PNPDeviceID, ConfigManagerErrorCode)
        if ($Problems.Count -eq 0) {
            Add-Finding 'Device errors' 'OK' 'No nonzero device error codes reported.' ''
        }
        foreach ($Item in $Problems) {
            Add-Finding 'Device errors' 'REVIEW' (
                "$($Item.Name); code $($Item.ConfigManagerErrorCode)"
            ) 'Inspect this device in Device Manager before changing drivers.'
        }
    }

    Invoke-Check 'Battery' {
        $Items = @(Get-CimInstance Win32_Battery)
        $Data.Battery = @($Items | Select-Object Name,
            EstimatedChargeRemaining, BatteryStatus)
        if ($Items.Count -eq 0) {
            Add-Finding 'Battery' 'INFO' 'No battery reported.' ''
        }
        foreach ($Item in $Items) {
            Add-Finding 'Battery' 'INFO' (
                "$($Item.Name); charge $($Item.EstimatedChargeRemaining) percent."
            ) 'Use existing Battery Health Diagnostics for capacity wear; charge is not health.'
        }
    }

    Invoke-Check 'Recent system events' {
        $Events = @()
        try {
            $Events = @(Get-WinEvent -FilterHashtable @{
                LogName = 'System'
                Level = @(1,2,3)
                StartTime = (Get-Date).AddDays(-7)
            } -MaxEvents 50 -ErrorAction Stop)
        } catch {
            if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') {
                throw
            }
        }
        $Data.SystemEvents = @($Events | Select-Object TimeCreated,
            ProviderName, Id, LevelDisplayName, Message)
        if ($Events.Count -eq 0) {
            Add-Finding 'Recent system events' 'OK' 'No matching events in the last 7 days.' ''
        } else {
            Add-Finding 'Recent system events' 'REVIEW' (
                "$($Events.Count) recent warnings/errors collected (maximum 50)."
            ) 'Correlate event times and messages with the symptom; events alone do not prove a fault.'
        }
    }

    Invoke-Check 'Network configuration' {
        $Data.NetworkAdapters = @(Get-NetAdapter |
            Select-Object Name, InterfaceDescription, Status, LinkSpeed)
        $Data.IPAddresses = @(Get-NetIPAddress |
            Select-Object InterfaceAlias, AddressFamily, IPAddress, PrefixLength)
        $Data.DNS = @(Get-DnsClientServerAddress |
            Select-Object InterfaceAlias, AddressFamily, ServerAddresses)
        Add-Finding 'Network' 'INFO' 'Adapter, IP, and DNS configuration collected.' (
            'For connectivity symptoms, inspect supporting data before resets. Internet access was not tested.'
        )
    }

    $Review = @($Findings | Where-Object Status -eq 'REVIEW').Count
    $Unknown = @($Findings | Where-Object Status -eq 'UNKNOWN').Count
    $Data.Completed = (Get-Date).ToString('o')
    $Data.Findings = @($Findings.ToArray())

    $Lines = New-Object 'System.Collections.Generic.List[string]'
    $Lines.Add('COC AUTOMATED DIAGNOSTIC SESSION V2')
    $Lines.Add("Computer: $env:COMPUTERNAME")
    $Lines.Add("Started: $($Data.Started)")
    $Lines.Add("Completed: $($Data.Completed)")
    $Lines.Add("Review findings: $Review | Unavailable checks: $Unknown")
    $Lines.Add('REVIEW means investigate; UNKNOWN means the check was unavailable.')
    $Lines.Add('This screening does not certify hardware health. No repairs executed.')
    $Lines.Add('Symptom not supplied; recommendations are conditional.')
    foreach ($Finding in $Findings) {
        $Lines.Add('')
        $Lines.Add("[$($Finding.Status)] $($Finding.Check): $($Finding.Detail)")
        if ($Finding.FollowUp) {
            $Lines.Add("Follow-up: $($Finding.FollowUp)")
        }
    }

    Confirm-USB
    $Name = 'COC-Auto-{0}-{1}' -f (
        Get-Date -Format 'yyyyMMdd-HHmmss'
    ), ([guid]::NewGuid().ToString('N').Substring(0,8))
    $Session = Join-Path $Reports $Name
    $null = New-Item -ItemType Directory -Path $Session

    $Summary = Join-Path $Session 'Summary.txt'
    $Details = Join-Path $Session 'Details.json'
    $SummaryText = $Lines -join [Environment]::NewLine
    $Json = $Data | ConvertTo-Json -Depth 8
    $Encoding = [Text.UTF8Encoding]::new($false)

    [IO.File]::WriteAllText($Summary, $SummaryText, $Encoding)
    [IO.File]::WriteAllText($Details, $Json, $Encoding)
    if (
        [IO.File]::ReadAllText($Summary) -cne $SummaryText -or
        [IO.File]::ReadAllText($Details) -cne $Json
    ) {
        throw 'Report verification failed.'
    }

    Write-Host "`n$SummaryText"
    Write-Host "`nREPORTS SAVED AND CONTENTS VERIFIED" -ForegroundColor Green
    Write-Host "Summary: $Summary"
    Write-Host "Supporting data: $Details"
}