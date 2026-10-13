@echo off
setlocal
title COC Laptop Diagnostics
echo ==========================================
echo       COC LAPTOP DIAGNOSTICS
echo ==========================================
echo.
echo This tool collects system information and
echo saves diagnostic reports to the USB drive.
echo.
powershell.exe -NoProfile -File "%~dp0Laptop-Diagnostics.ps1"
echo.
echo ==========================================
echo Diagnostic process has ended.
echo Check the console for any errors.
echo ==========================================
pause
endlocal
