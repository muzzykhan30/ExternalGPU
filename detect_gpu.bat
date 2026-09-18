@echo off
setlocal
title Windows GPU Auto-Detector and Driver Portal Launcher
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0detect_gpu.ps1" %*
if errorlevel 1 (
    echo.
    echo Script encountered an error.
    pause
)
