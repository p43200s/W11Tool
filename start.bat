@echo off
chcp 65001 >nul
net session >nul 2>&1 || (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
set "WIN_TOOL_ROOT=%~dp0"
if "%WIN_TOOL_ROOT:~-1%"=="\" set "WIN_TOOL_ROOT=%WIN_TOOL_ROOT:~0,-1%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%WIN_TOOL_ROOT%\_modules\menu.ps1"