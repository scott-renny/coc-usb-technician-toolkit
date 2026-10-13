# COC guided technician v1
# System queries only. Session reports are written to the verified USB.
& {
    $ErrorActionPreference = 'Stop'
    $Root = [System.IO.Path]::GetPathRoot($PSScriptRoot)
    $Assessment = Join-Path $PSScriptRoot 'COC-ReadOnly-Health-Assessment-v1.ps1'

    function Confirm-USB {
        $Letter = $Root.Substring(0,1)
        $Disk = Get-Partition -DriveLetter $Letter | Get-Disk
        $Volume = Get-Volume -DriveLetter $Letter
        if (
            $Disk.FriendlyName -ne 'Lexar USB Flash Drive' -or
            $Disk.BusType -ne 'USB' -or
            $Volume.FileSystemLabel -ne 'COC_USB_1'
        ) {
            throw 'Verified Lexar Ventoy USB required.'
        }
    }

    function Invoke-Health {
        $Expected = 'F66E1FF66BA8B32F3782C8AE5D35801AA839AFBA112FEE84BBEE034E4EE2C361'
        if ((Get-FileHash -LiteralPath $Assessment).Hash -ne $Expected) {
            throw 'Health assessment hash mismatch.'
        }
        & $Assessment
    }

    function Show-RecentEvents {
        Write-Host "`nRECENT SYSTEM ERRORS / WARNINGS (last 7 days; up to 30)"
        try {
            $Events = @(Get-WinEvent -FilterHashtable @{
                LogName = 'System'
                Level = @(1,2,3)
                StartTime = (Get-Date).AddDays(-7)
            } -MaxEvents 30 -ErrorAction Stop)
            $Events |
                Select-Object TimeCreated, ProviderName, Id, LevelDisplayName |
                Format-Table -Wrap -AutoSize | Out-Host
            Write-Host 'Events are investigation leads, not proof of a hardware fault.'
        } catch {
            if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') {
                Write-Host 'No matching events found.'
            } else {
                Write-Host "Event check unavailable: $($_.Exception.Message)"
            }
        }
    }

    function Show-Network {
        Write-Host "`nCURRENT NETWORK CONFIGURATION"
        Get-NetAdapter |
            Select-Object Name, Status, LinkSpeed |
            Format-Table -AutoSize | Out-Host
        Get-NetIPConfiguration | Format-List |
            Out-Host
        Write-Host 'Configuration only; no network reset or external connection test performed.'
    }

    function Show-Playbook {
        Write-Host @"

COC WINDOWS REPAIR & TROUBLESHOOTING PLAYBOOK

Windows starts:
  1. Record the symptom, when it began, and recent changes.
  2. Run the health assessment and existing diagnostic collectors.
  3. Review device errors and recent events.
  4. Choose a targeted follow-up:
     Storage: CrystalDiskInfo; investigate SMART warnings.
     Memory: Memtest86+ from Ventoy; RAM inventory is not a memory test.
     Battery: existing Battery Health Diagnostics.
     Crashes: existing BlueScreenView; correlate dates and symptoms.
     Network: inspect adapters and IP settings before changing anything.
     Updates: record the exact failure code and update history.
     System files: decide whether verification is warranted before repairs.

Windows will not boot:
  1. Record the exact screen/error and whether firmware sees the SSD.
  2. Boot Ventoy > HBCD_PE_x64.iso, if the laptop supports it.
  3. Identify disks by model and capacity; drive letters may change.
  4. Locate the installed Windows volume before any offline diagnosis.
  5. Encrypted volumes may require the owner's BitLocker recovery key.
  6. Preserve important data before attempting repair.

Repair decision:
  Document evidence, proposed change, backup status, and owner approval.
  Then choose a specific repair and verify its result.
  This launcher does not run SFC repairs, DISM repairs, CHKDSK repairs,
  boot repair, update resets, driver changes, or partition operations.

Scope:
  These checks inspect the currently running Windows environment.
  In Windows PE, they do not automatically inspect offline Windows.
  PE support for these scripts and commands has not yet been tested.
"@
    }

    function Start-Session {
        Confirm-USB
        if (Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT') {
            throw 'This session workflow is for installed Windows. Use the offline playbook in PE.'
        }

        $Reports = Join-Path $Root 'Reports'
        if (-not (Test-Path -LiteralPath $Reports -PathType Container)) {
            throw 'Existing USB Reports folder missing.'
        }

        $Issue = Read-Host 'Brief symptom (avoid passwords and recovery keys)'
        $SessionName = 'COC-Session-{0}-{1}' -f (
            Get-Date -Format 'yyyyMMdd-HHmmss'
        ), ([guid]::NewGuid().ToString('N').Substring(0,8))
        Import-Module (Join-Path $Root 'Scripts\Toolkit\COC.Core.psm1') -Force
        $cocGuidedCase = New-CocSession -Root $Root -Category Diagnostics
        $Session = $cocGuidedCase.Path
        $Report = Join-Path $Session 'Session.txt'
        $Started = $false

        try {
            Start-Transcript -LiteralPath $Report -NoClobber | Out-Host
            $Started = $true
            Write-Host "`nCOC TECHNICIAN SESSION"
            Write-Host "Computer: $env:COMPUTERNAME"
            Write-Host "Symptom: $Issue"
            Write-Host "Environment: installed Windows"
            Write-Host 'Checks below are read-only; report output is on USB.'

            Invoke-Health
            Show-RecentEvents

            Write-Host "`nREVIEW FINDINGS"
            $Findings = Read-Host 'Record observations, or type none'
            Write-Host "Technician observations: $Findings"
            $Next = Read-Host 'Record next test/action (nothing is executed)'
            Write-Host "Planned follow-up: $Next"
            Write-Host 'Session complete. No repairs executed.'
        } finally {
            if ($Started) { Stop-Transcript | Out-Host }
            Complete-CocSession $cocGuidedCase
            Write-Host "USB report: $Report"
        }
    }

    Confirm-USB
    do {
        Write-Host "`nCOC GUIDED TECHNICIAN"
        Write-Host '1. New diagnostic session + USB report'
        Write-Host '2. Read-only health assessment'
        Write-Host '3. Recent system events'
        Write-Host '4. Network configuration'
        Write-Host '5. Repair and offline troubleshooting playbook'
        Write-Host '0. Exit'
        $Choice = Read-Host 'Select'
        try {
            switch ($Choice) {
                '1' { Start-Session }
                '2' { Invoke-Health }
                '3' { Show-RecentEvents }
                '4' { Show-Network }
                '5' { Show-Playbook }
                '0' { }
                default { Write-Host 'Choose 0 through 5.' }
            }
        } catch {
            Write-Host "Action stopped: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } while ($Choice -ne '0')
}