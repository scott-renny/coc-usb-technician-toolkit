@echo off
setlocal
title COC Automated Health Assessment

echo ============================================
echo       COC AUTOMATED HEALTH ASSESSMENT
echo ============================================
echo.
echo Running read-only system diagnostics...
echo.

powershell.exe -NoProfile -File "%~dp0Launch-Health-Assessment.ps1"

echo.
if errorlevel 1 (
    echo Assessment failed. Review the errors above.
) else (
    echo Assessment finished. Check the Reports folder.
)
echo.
pause
endlocal
