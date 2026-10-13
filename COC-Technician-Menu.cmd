@echo off
setlocal
color 0B
title COC - Cybersecurity Operations Center
set "ROOT=%~dp0"
set "SCRIPTS=%ROOT%\Tools\Windows\Technician-Scripts"

:MAIN
cls
call :COCCENTER 30
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                   CYBERSECURITY OPERATIONS CENTER
echo %COC_PAD%                    COC TECHNICIAN CONTROL CENTER
echo %COC_PAD%                              VERSION 9
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. System Diagnostics
echo %COC_PAD%  2. Hardware Information
echo %COC_PAD%  3. Storage and Recovery
echo %COC_PAD%  4. Networking
echo %COC_PAD%  5. Windows Repair and Troubleshooting
echo %COC_PAD%  6. Driver Toolkit
echo %COC_PAD%  7. Utilities and Sysinternals
echo %COC_PAD%  8. Automated Diagnostic Session
echo %COC_PAD%  9. Reports and Documentation
echo.
echo %COC_PAD%  A. Functional Toolkit Extensions
echo %COC_PAD%  0. Exit
echo.
choice /c 123456789A0 /n /m "%COC_PAD%Select an option: "
if errorlevel 11 goto END
if errorlevel 10 goto FUNCTIONAL
if errorlevel 9 goto REPORTS
if errorlevel 8 goto AUTOSESSION
if errorlevel 7 goto UTILITIES
if errorlevel 6 goto DRIVERTOOLKIT
if errorlevel 5 goto WINDOWS
if errorlevel 4 goto NETWORK
if errorlevel 3 goto STORAGE
if errorlevel 2 goto HARDWARE
if errorlevel 1 goto DIAGNOSTICS

:DIAGNOSTICS
cls
call :COCCENTER 21
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                             DIAGNOSTICS
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. Full Laptop Diagnostics
echo %COC_PAD%  2. Battery Health Diagnostics
echo %COC_PAD%  3. RAM Information
echo %COC_PAD%  4. Read-only Health Assessment
echo %COC_PAD%  0. Back
echo.
choice /c 12340 /n /m "%COC_PAD%Select: "
if errorlevel 5 goto MAIN
if errorlevel 4 goto HEALTH
if errorlevel 3 goto RAM
if errorlevel 2 goto BATTERY
if errorlevel 1 goto LAPTOP

:HEALTH
cls
call :COCCENTER 16
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                     READ-ONLY HEALTH ASSESSMENT
echo %COC_PAD%======================================================================
echo.
if not exist "%SCRIPTS%\COC-ReadOnly-Health-Assessment-v1.ps1" (
    echo Assessment script not found.
    pause
    goto DIAGNOSTICS
)
where pwsh.exe >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTS%\COC-ReadOnly-Health-Assessment-v1.ps1"
) else (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTS%\COC-ReadOnly-Health-Assessment-v1.ps1"
)
if errorlevel 1 echo Assessment process reported an error.
echo.
pause
goto DIAGNOSTICS
:LAPTOP
call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name Laptop
goto DIAGNOSTICS

:BATTERY
call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name Battery
goto DIAGNOSTICS

:RAM
powershell.exe -NoProfile -Command "Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, Manufacturer, @{Name='CapacityGB';Expression={[math]::Round($_.Capacity / 1GB, 2)}}, Speed, PartNumber | Format-Table -AutoSize"
pause
goto DIAGNOSTICS

:HARDWARE
cls
call :COCCENTER 21
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                         HARDWARE INFORMATION
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. HWiNFO 64-bit
echo %COC_PAD%  2. CPU-Z 64-bit
echo %COC_PAD%  3. USB Device Tree Viewer
echo %COC_PAD%  4. USBDeview - USB Device History
echo %COC_PAD%  0. Back
echo.
choice /c 12340 /n /m "%COC_PAD%Select: "
if errorlevel 5 goto MAIN
if errorlevel 4 (
    call :LAUNCH "%ROOT%\Tools\Windows\USBDeview\USBDeview.exe"
    goto HARDWARE
)
if errorlevel 3 (
    call :LAUNCH "%ROOT%\Tools\Windows\USB-Device-Tree-Viewer\UsbTreeView.exe"
    goto HARDWARE
)
if errorlevel 2 (
    call :LAUNCH "%ROOT%\Tools\Windows\CPU-Z\cpuz_x64.exe"
    goto HARDWARE
)
if errorlevel 1 (
    call :LAUNCH "%ROOT%\Tools\Windows\HWiNFO\HWiNFO64.exe"
    goto HARDWARE
)

:STORAGE
cls
call :COCCENTER 23
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                         STORAGE AND RECOVERY
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. CrystalDiskInfo 64-bit
echo %COC_PAD%  2. TestDisk - Advanced Recovery
echo %COC_PAD%  3. PhotoRec - File Recovery
echo %COC_PAD%  4. DMDE Free Edition
echo %COC_PAD%  5. WizTree - Disk Space Analysis
echo %COC_PAD%  6. smartmontools Command Prompt
echo %COC_PAD%  0. Back
echo.
choice /c 1234560 /n /m "%COC_PAD%Select: "
if errorlevel 7 goto MAIN
if errorlevel 6 (
    call :TOOLCMD "%ROOT%\Tools\Storage\smartmontools\bin\smartctl.exe"
    goto STORAGE
)
if errorlevel 5 (
    call :LAUNCH "%ROOT%\Tools\Windows\WizTree\WizTree64.exe"
    goto STORAGE
)
if errorlevel 4 (
    call :LAUNCH "%ROOT%\Tools\Windows\DMDE\dmde.exe"
    goto STORAGE
)
if errorlevel 3 (
    call :LAUNCH "%ROOT%\Tools\Storage\TestDisk-PhotoRec\testdisk-7.2\qphotorec_win.exe"
    goto STORAGE
)
if errorlevel 2 (
    call :LAUNCH "%ROOT%\Tools\Storage\TestDisk-PhotoRec\testdisk-7.2\testdisk_win.exe"
    goto STORAGE
)
if errorlevel 1 (
    call :LAUNCH "%ROOT%\Tools\Storage\CrystalDiskInfo\DiskInfo64.exe"
    goto STORAGE
)
:NETWORK
cls
call :COCCENTER 23
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                              NETWORKING
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. Wireshark
echo %COC_PAD%  2. PuTTY
echo %COC_PAD%  3. WinSCP Portable
echo %COC_PAD%  4. Nmap Command Prompt
echo %COC_PAD%  5. iperf3 Command Prompt
echo %COC_PAD%  6. Network Diagnostic Scripts
echo %COC_PAD%  0. Back
echo.
choice /c 1234560 /n /m "%COC_PAD%Select: "
if errorlevel 7 goto MAIN
if errorlevel 6 goto NETSCRIPTS
if errorlevel 5 (
    call :TOOLCMD "%ROOT%\Tools\Network\iperf3\iperf3.exe"
    goto NETWORK
)
if errorlevel 4 (
    call :TOOLCMD "%ROOT%\Tools\Networking\Nmap\nmap.exe"
    goto NETWORK
)
if errorlevel 3 (
    call :LAUNCHCMD "%ROOT%\Tools\Networking\WinSCP\Launch-WinSCP.cmd"
    goto NETWORK
)
if errorlevel 2 (
    call :LAUNCH "%ROOT%\Tools\Networking\PuTTY\putty.exe"
    goto NETWORK
)
if errorlevel 1 (
    call :LAUNCH "%ROOT%\Tools\Networking\Wireshark\Wireshark.exe"
    goto NETWORK
)

:NETSCRIPTS
cls
call :COCCENTER 23
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                      NETWORK DIAGNOSTIC SCRIPTS
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. General Network Diagnostics
echo %COC_PAD%  2. Wi-Fi Diagnostics
echo %COC_PAD%  3. DHCP Diagnostics
echo %COC_PAD%  4. DNS Diagnostics
echo %COC_PAD%  5. Connectivity Diagnostics
echo %COC_PAD%  6. Firewall Diagnostics
echo %COC_PAD%  0. Back
echo.
choice /c 1234560 /n /m "%COC_PAD%Select: "
if errorlevel 7 goto NETWORK
if errorlevel 6 (
    call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name Firewall
    pause
    goto NETSCRIPTS
)
if errorlevel 5 (
    call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name Connectivity
    pause
    goto NETSCRIPTS
)
if errorlevel 4 (
    call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name DNS
    pause
    goto NETSCRIPTS
)
if errorlevel 3 (
    call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name DHCP
    pause
    goto NETSCRIPTS
)
if errorlevel 2 (
    call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name WiFi
    pause
    goto NETSCRIPTS
)
if errorlevel 1 (
    call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name Network
    pause
    goto NETSCRIPTS
)
:WINDOWS
cls
call :COCCENTER 26
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                  WINDOWS REPAIR AND TROUBLESHOOTING
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. Guided Troubleshooting Center
echo %COC_PAD%  2. Windows Installation Discovery
echo %COC_PAD%  3. Offline Windows Repair Playbook
echo %COC_PAD%  4. BlueScreenView
echo %COC_PAD%  5. Windows Device Manager
echo %COC_PAD%  6. WinDbg
echo %COC_PAD%  7. Microsoft PerfView
echo %COC_PAD%  8. Orca MSI Inspector
echo %COC_PAD%  9. BitLocker Status and Recovery Key IDs
echo %COC_PAD%  0. Back
echo.
choice /c 1234567890 /n /m "%COC_PAD%Select: "
if errorlevel 10 goto MAIN
if errorlevel 9 (
    call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-BitLocker-Diagnostics.ps1"
    pause
    goto WINDOWS
)
if errorlevel 8 (
    call :LAUNCH "%ROOT%\Tools\Windows\Orca\Orca.exe"
    goto WINDOWS
)
if errorlevel 7 (
    call :LAUNCH "%ROOT%\Tools\Windows\PerfView\PerfView.exe"
    goto WINDOWS
)
if errorlevel 6 (
    call :LAUNCH "%ROOT%\Tools\Windows\WinDbg\windbg.exe"
    goto WINDOWS
)
if errorlevel 5 (
    start "" devmgmt.msc
    goto WINDOWS
)
if errorlevel 4 (
    call :LAUNCH "%ROOT%\Tools\Windows\BlueScreenView\x64\BlueScreenView.exe"
    goto WINDOWS
)
if errorlevel 3 (
    if exist "%ROOT%\Documentation\Windows-Repair\Offline-Windows-Repair-Playbook.md" (
        start "" notepad.exe "%ROOT%\Documentation\Windows-Repair\Offline-Windows-Repair-Playbook.md"
    ) else (
        echo Repair playbook not found.
        pause
    )
    goto WINDOWS
)
if errorlevel 2 (
    call :RUNSCRIPT "%ROOT%\Scripts\Windows\COC-Windows-Installation-Discovery.ps1"
    pause
    goto WINDOWS
)
if errorlevel 1 (
    call :RUNSTRICT "%SCRIPTS%\COC-Guided-Technician-v1.ps1"
    pause
    goto WINDOWS
)
:REPORTS
cls
call :COCCENTER 20
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                      REPORTS AND DOCUMENTATION
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. Diagnostic Reports
echo %COC_PAD%  2. Windows Repair Documentation
echo %COC_PAD%  3. Driver Backups
echo %COC_PAD%  0. Back
echo.
choice /c 1230 /n /m "%COC_PAD%Select: "
if errorlevel 4 goto MAIN
if errorlevel 3 (
    call :OPENFOLDER "%ROOT%\Drivers\Backups"
    goto REPORTS
)
if errorlevel 2 (
    call :OPENFOLDER "%ROOT%\Documentation\Windows-Repair"
    goto REPORTS
)
if errorlevel 1 (
    call :OPENFOLDER "%ROOT%\Reports"
    goto REPORTS
)
:LAUNCH
if not exist "%~1" (
    echo.
    echo Tool not found: %~1
    pause
    exit /b 1
)
start "" "%~1"
exit /b 0

:LAUNCHCMD
if not exist "%~1" (
    echo.
    echo Launcher not found: %~1
    pause
    exit /b 1
)
call "%~1"
exit /b %errorlevel%

:TOOLCMD
if not exist "%~1" (
    echo.
    echo Tool not found: %~1
    pause
    exit /b 1
)
for %%I in ("%~1") do set "TOOLDIR=%%~dpI"
start "" cmd.exe /k "set PATH=%TOOLDIR%;%PATH%"
exit /b 0
:AUTOSESSION
cls
call :COCCENTER 11
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name Auto
pause
goto MAIN

:GUIDED
cls
call :COCCENTER 11
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
call :RUNSTRICT "%SCRIPTS%\COC-Guided-Technician-v1.ps1"
pause
goto MAIN

:RUNSCRIPT
if not exist "%~1" (
    echo Script not found: %~1
    exit /b 1
)
where pwsh.exe >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~1"
) else (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~1"
)
if errorlevel 1 (
    echo Script process reported an error.
    exit /b 1
)
exit /b 0
:DRIVERTOOLKIT
cls
call :COCCENTER 19
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                            DRIVER TOOLKIT
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. Installed Driver Inventory
echo %COC_PAD%  2. Backup Third-Party Drivers (Administrator Required)
echo %COC_PAD%  0. Back
echo.
choice /c 120 /n /m "%COC_PAD%Select: "
if errorlevel 3 goto MAIN
if errorlevel 2 goto DRIVERBACKUP
if errorlevel 1 goto DRIVERINVENTORY

:DRIVERINVENTORY
cls
call :COCCENTER 11
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
call :RUNSTRICT "%ROOT%\Scripts\Toolkit\COC-Run-Collector.ps1" -Name Drivers
pause
goto DRIVERTOOLKIT

:DRIVERBACKUP
cls
call :COCCENTER 14
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%Administrator privileges are required.
echo %COC_PAD%This exports third-party drivers without changing installed drivers.
echo.
call :RUNSCRIPT "%ROOT%\Tools\Windows\Driver-Toolkit\Driver-Backup.ps1"
pause
goto DRIVERTOOLKIT

:UTILITIES
cls
call :COCCENTER 21
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%======================================================================
echo %COC_PAD%                      UTILITIES AND SYSINTERNALS
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. Process Explorer
echo %COC_PAD%  2. Autoruns
echo %COC_PAD%  3. Everything File Search
echo %COC_PAD%  4. Sysinternals Suite Folder
echo %COC_PAD%  0. Back
echo.
choice /c 12340 /n /m "%COC_PAD%Select: "
if errorlevel 5 goto MAIN
if errorlevel 4 (
    call :OPENFOLDER "%ROOT%\Tools\Windows\Sysinternals"
    goto UTILITIES
)
if errorlevel 3 (
    call :LAUNCH "%ROOT%\Tools\Windows\Everything\x64\everything.exe"
    goto UTILITIES
)
if errorlevel 2 (
    call :LAUNCH "%ROOT%\Tools\Windows\Sysinternals\Autoruns64.exe"
    goto UTILITIES
)
if errorlevel 1 (
    call :LAUNCH "%ROOT%\Tools\Windows\Sysinternals\procexp64.exe"
    goto UTILITIES
)

:OPENFOLDER
if not exist "%~1\" (
    echo Folder not found: %~1
    pause
    exit /b 1
)
start "" explorer.exe "%~1"
exit /b 0
:FUNCTIONAL
call "%ROOT%\Scripts\Toolkit\COC-Functional-Menu.cmd"
goto MAIN

:RUNSTRICT
if not exist "%~1" (
    echo Script not found: %~1
    exit /b 1
)
where pwsh.exe >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -File %*
) else (
    pwsh.exe -NoProfile -File %*
)
exit /b %errorlevel%
:END
endlocal
exit /b 0

:COCCENTER
set "COC_PAD="
set "COC_CENTER_PS=powershell.exe"
where pwsh.exe >nul 2>&1
if not errorlevel 1 set "COC_CENTER_PS=pwsh.exe"
if not exist "%ROOT%Scripts\Toolkit\COC-Console-Layout.ps1" exit /b 0
for /f "tokens=1,* delims=:" %%A in ('%COC_CENTER_PS% -NoProfile -File "%ROOT%Scripts\Toolkit\COC-Console-Layout.ps1" -ContentHeight %1') do (
    if "%%A"=="P" set "COC_PAD=%%B"
    if "%%A"=="B" echo.
)
if defined COC_PAD set "COC_PAD=%COC_PAD:~1%"
exit /b 0