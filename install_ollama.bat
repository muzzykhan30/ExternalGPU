@echo off
setlocal
title Ollama Windows Installer
echo Starting Ollama installer script...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_ollama.ps1" %*
if errorlevel 1 (
    echo.
    echo [!] An error occurred during execution.
)

echo.
pause
