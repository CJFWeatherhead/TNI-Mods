@echo off
REM Tower Networking Inc - Mod Manager Launcher
REM This batch file launches the PowerShell mod manager with proper execution policy

SET SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

REM Launch with WPF GUI
REM Using -ExecutionPolicy Bypass to avoid script execution errors
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    REM PowerShell Core is available
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%ModManagerGUI.ps1"
) else (
    REM Fall back to Windows PowerShell
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%ModManagerGUI.ps1"
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo An error occurred. Press any key to exit...
    pause >nul
)
