@echo off
setlocal
color 0B
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
:MAIN
cls
call :COCCENTER 25
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
echo %COC_PAD%                    FUNCTIONAL TOOLKIT EXTENSIONS
echo %COC_PAD%======================================================================
echo.
echo %COC_PAD%  1. Master IT Technician Playbook and coverage matrix
echo %COC_PAD%  2. System, security and enterprise diagnostic collection
echo %COC_PAD%  3. Guided Windows repair commands
echo %COC_PAD%  4. Deployment and migration workflow
echo %COC_PAD%  5. Report cleanup preview and selective deletion
echo %COC_PAD%  6. Additional installed tools
echo %COC_PAD%  7. Cases, baselines and handover
echo %COC_PAD%  8. Toolkit integrity and capacity
echo %COC_PAD%  9. Filtered Windows event diagnostics
echo %COC_PAD%  0. Back
choice /c 1234567890 /n /m "%COC_PAD%Select: "
if errorlevel 10 goto END
if errorlevel 9 goto EVENTS
if errorlevel 8 goto INTEGRITY
if errorlevel 7 goto CASES
if errorlevel 6 goto TOOLS
if errorlevel 5 goto CLEANUP
if errorlevel 4 goto MIGRATION
if errorlevel 3 goto REPAIR
if errorlevel 2 goto DIAGNOSTICS
if errorlevel 1 (
    call :DOC
    goto MAIN
)
:DIAGNOSTICS
echo %COC_PAD%Reports can contain sensitive device, user and network information.
call :RUNSCRIPT "%~dp0COC-Enterprise-Diagnostics.ps1"
pause
goto MAIN
:CLEANUP
call :RUNSCRIPT "%~dp0COC-Cleanup.ps1" -Interactive
pause
goto MAIN
:MIGRATION
call :DOC
echo %COC_PAD%Migration requires explicit source and new destination paths on a separate backup disk.
echo %COC_PAD%Review the playbook, then run COC-Migration.ps1 with -Source and -Destination.
echo %COC_PAD%Default mode previews; -Copy requests typed confirmation.
pause
goto MAIN
:REPAIR
cls
call :COCCENTER 17
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%  1. DISM CheckHealth
echo %COC_PAD%  2. DISM ScanHealth
echo %COC_PAD%  3. DISM RestoreHealth
echo %COC_PAD%  4. SFC verify only
echo %COC_PAD%  5. SFC repair
echo %COC_PAD%  0. Back
choice /c 123450 /n /m "%COC_PAD%Select: "
if errorlevel 6 goto MAIN
if errorlevel 5 (set "ACTION=SfcRepair") else if errorlevel 4 (set "ACTION=SfcVerify") else if errorlevel 3 (set "ACTION=RestoreHealth") else if errorlevel 2 (set "ACTION=ScanHealth") else (set "ACTION=CheckHealth")
call :RUNSCRIPT "%~dp0COC-Windows-Repair.ps1" -Action %ACTION%
choice /c YN /n /m "%COC_PAD%Request execution with typed confirmation (Y/N)? "
if errorlevel 2 goto REPAIR
call :RUNSCRIPT "%~dp0COC-Windows-Repair.ps1" -Action %ACTION% -Apply
pause
goto REPAIR
:TOOLS
cls
call :COCCENTER 15
echo.
echo %COC_PAD%                         .-----------------.
echo %COC_PAD%                         \   o---.    o    /
echo %COC_PAD%                          \      \---/    /
echo %COC_PAD%                           \  o---+      /
echo %COC_PAD%                            \     o     /
echo %COC_PAD%                             \   COC   /
echo %COC_PAD%                              \_______/
echo.
echo %COC_PAD%  1. 7-Zip file manager
echo %COC_PAD%  2. USMT component folder and reference
echo %COC_PAD%  3. 7-Zip full command prompt
echo %COC_PAD%  0. Back
choice /c 1230 /n /m "%COC_PAD%Select: "
if errorlevel 4 goto MAIN
if errorlevel 3 (
    if exist "%ROOT%\Tools\Windows\7-Zip\x64\7z.exe" start "" cmd.exe /k "set PATH=%ROOT%\Tools\Windows\7-Zip\x64;%PATH%"
    goto TOOLS
)
if errorlevel 2 (
    call :OPENFOLDER "%ROOT%\Tools\Windows\USMT\amd64"
    goto TOOLS
)
if errorlevel 1 (
    call :LAUNCH "%ROOT%\Tools\Windows\7-Zip\x64\7zFM.exe"
    goto TOOLS
)
:DOC
if not exist "%ROOT%\Documentation\Master-IT-Technician-Playbook.html" (
    echo Master playbook missing.
    pause
    exit /b 1
)
start "" "%ROOT%\Documentation\Master-IT-Technician-Playbook.html"
exit /b 0
:CASES
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
echo %COC_PAD%  1. Case index
echo %COC_PAD%  2. Configuration baseline
echo %COC_PAD%  3. Handover report
echo %COC_PAD%  4. Comparison and retention-hold instructions
echo %COC_PAD%  0. Back
choice /c 12340 /n /m "%COC_PAD%Select: "
if errorlevel 5 goto MAIN
if errorlevel 4 (
    call :DOC
    goto CASES
)
if errorlevel 3 (set "CASEACTION=Handover") else if errorlevel 2 (set "CASEACTION=Baseline") else (set "CASEACTION=Index")
call :RUNSCRIPT "%~dp0COC-Cases.ps1" -Action %CASEACTION%
pause
goto CASES
:INTEGRITY
echo %COC_PAD%Default checks required assets; full hashing also reads all ISOs and executables and can take several minutes.
call :RUNSCRIPT "%~dp0COC-Integrity.ps1"
pause
goto MAIN
:EVENTS
call :RUNSCRIPT "%~dp0COC-Event-Diagnostics.ps1"
echo %COC_PAD%See playbook for log, time, severity, provider and event-ID filters. Security logs require explicit authorization.
pause
goto MAIN
:OPENFOLDER
if not exist "%~1\" (
    echo Folder missing: %~1
    pause
    exit /b 1
)
start "" explorer.exe "%~1"
exit /b 0
:LAUNCH
if not exist "%~1" (
    echo Tool missing: %~1
    pause
    exit /b 1
)
start "" "%~1"
exit /b 0
:RUNSCRIPT
where pwsh.exe >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -File %*
) else (
    pwsh.exe -NoProfile -File %*
)
set "COC_EXIT=%errorlevel%"
if "%COC_EXIT%"=="3010" echo Operation completed; a restart is required when appropriate.
if not "%COC_EXIT%"=="0" if not "%COC_EXIT%"=="3010" echo Operation returned code %COC_EXIT%. Review the output and documented prerequisites.
exit /b %COC_EXIT%
:END
endlocal
exit /b 0

:COCCENTER
set "COC_PAD="
set "COC_CENTER_PS=powershell.exe"
where pwsh.exe >nul 2>&1
if not errorlevel 1 set "COC_CENTER_PS=pwsh.exe"
if not exist "%~dp0COC-Console-Layout.ps1" exit /b 0
for /f "tokens=1,* delims=:" %%A in ('%COC_CENTER_PS% -NoProfile -File "%~dp0COC-Console-Layout.ps1" -ContentHeight %1') do (
    if "%%A"=="P" set "COC_PAD=%%B"
    if "%%A"=="B" echo.
)
if defined COC_PAD set "COC_PAD=%COC_PAD:~1%"
exit /b 0