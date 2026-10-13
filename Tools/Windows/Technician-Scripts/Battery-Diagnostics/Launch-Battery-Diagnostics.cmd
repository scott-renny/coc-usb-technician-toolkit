@echo off
setlocal
title COC Battery Health Diagnostics
echo ==========================================
echo       COC BATTERY HEALTH DIAGNOSTICS
echo ==========================================
echo.
echo Generates a Windows battery report and
echo calculates battery capacity health.
echo.
powershell.exe -NoProfile -File "%~dp0Battery-Health.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" (
    echo Battery diagnostics reported an error.
    echo Exit code: %RESULT%
) else (
    echo Battery diagnostic process completed.
    echo Review the report folder shown above.
)
echo.
pause
endlocal
exit /b %RESULT%
