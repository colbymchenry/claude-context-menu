@echo off
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0modern\install.ps1"
echo.
echo   Press any key to close.
pause >nul
