<# :
@echo off
setlocal
title Ollama Windows Installer and Setup
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; & ([scriptblock]::Create((Get-Content -LiteralPath '%~f0' -Raw))) %*"
if errorlevel 1 (
    echo.
    echo [!] Script encountered an error.
)
echo.
pause
exit /b %errorlevel%
#>

# ==============================================================================
# Ollama Windows Installer, Environment Setup & Health Check
# Self-contained single-file script (can be double-clicked directly).
# ==============================================================================

[CmdletBinding()]
param(
    [ValidateSet("Auto", "Winget", "Direct")]
    [string]$Method = "Auto",

    [switch]$Force,
    [switch]$Silent,
    [switch]$NoStart
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$OllamaDirectUrl  = "https://ollama.com/download/OllamaSetup.exe"
$OllamaDefaultDir = "$env:LOCALAPPDATA\Programs\Ollama"
$OllamaExePath    = Join-Path $OllamaDefaultDir "ollama.exe"
$OllamaAppPath    = Join-Path $OllamaDefaultDir "ollama app.exe"
$OllamaApiUrl     = "http://127.0.0.1:11434"

function Write-Banner {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "         OLLAMA WINDOWS INSTALLER & ENVIRONMENT SETUP     " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Test-OllamaInstalled {
    if (Get-Command "ollama.exe" -ErrorAction SilentlyContinue) {
        return $true
    }
    if (Test-Path $OllamaExePath) {
        return $true
    }
    return $false
}

function Get-InstalledVersion {
    try {
        if (Get-Command "ollama" -ErrorAction SilentlyContinue) {
            $verOutput = & ollama --version 2>&1
            if ($verOutput -match "version is ([0-9\.]+)") {
                return $matches[1]
            }
        } elseif (Test-Path $OllamaExePath) {
            $verOutput = & $OllamaExePath --version 2>&1
            if ($verOutput -match "version is ([0-9\.]+)") {
                return $matches[1]
            }
        }
    } catch {}
    return "Unknown"
}

function Test-OllamaServiceRunning {
    try {
        $resp = Invoke-WebRequest -Uri $OllamaApiUrl -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        if ($resp.Content -match "Ollama is running") {
            return $true
        }
    } catch {}
    return $false
}

function Ensure-PathConfigured {
    Write-Host "`n[+] Checking system PATH for Ollama..." -ForegroundColor Cyan
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$OllamaDefaultDir*") {
        Write-Host "    Adding $OllamaDefaultDir to User PATH..." -ForegroundColor Yellow
        $newPath = "$currentPath;$OllamaDefaultDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    } else {
        Write-Host "    Ollama directory is already in User PATH." -ForegroundColor Gray
    }

    # Also update current session's PATH
    if ($env:Path -notlike "*$OllamaDefaultDir*") {
        $env:Path = "$env:Path;$OllamaDefaultDir"
    }
}

function Install-ViaWinget {
    Write-Host "`n[+] Attempting installation via Windows Package Manager (winget)..." -ForegroundColor Cyan
    
    $wingetCmd = Get-Command "winget.exe" -ErrorAction SilentlyContinue
    if (-not $wingetCmd) {
        Write-Host "    winget not found on this system." -ForegroundColor Yellow
        return $false
    }

    $wingetArgs = @(
        "install",
        "--id", "Ollama.Ollama",
        "--exact",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    if ($Silent) {
        $wingetArgs += "--silent"
    }

    Write-Host "    Running: winget $($wingetArgs -join ' ')" -ForegroundColor Gray
    $process = Start-Process -FilePath "winget.exe" -ArgumentList $wingetArgs -Wait -NoNewWindow -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "    Winget installation completed successfully!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    Winget exited with code $($process.ExitCode). Falling back to direct download..." -ForegroundColor Yellow
        return $false
    }
}

function Install-ViaDirectDownload {
    Write-Host "`n[+] Downloading Ollama installer directly from official servers..." -ForegroundColor Cyan
    Write-Host "    URL: $OllamaDirectUrl" -ForegroundColor Gray

    $tempInstaller = Join-Path $env:TEMP "OllamaSetup.exe"

    if (Test-Path $tempInstaller) {
        Remove-Item -Force $tempInstaller -ErrorAction SilentlyContinue
    }

    try {
        Write-Host "    Downloading OllamaSetup.exe (approx ~1.5 GB package)..." -ForegroundColor Yellow
        
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        
        $downloadTask = $webClient.DownloadFileTaskAsync($OllamaDirectUrl, $tempInstaller)
        
        while (-not $downloadTask.IsCompleted) {
            Start-Sleep -Milliseconds 800
            if (Test-Path $tempInstaller) {
                $currentBytes = (Get-Item $tempInstaller).Length
                $mb = [math]::Round($currentBytes / 1MB, 1)
                Write-Host "`r    Downloaded: $mb MB..." -NoNewline -ForegroundColor Gray
            }
        }
        Write-Host ""
        
        if ($downloadTask.IsFaulted) {
            throw $downloadTask.Exception
        }

        Write-Host "    Download complete!" -ForegroundColor Green
    } catch {
        Write-Host "    WebClient download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Attempting fallback with Invoke-WebRequest..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $OllamaDirectUrl -OutFile $tempInstaller -UseBasicParsing
    }

    if (-not (Test-Path $tempInstaller)) {
        Write-Host "[!] Failed to locate downloaded installer at $tempInstaller" -ForegroundColor Red
        return $false
    }

    Write-Host "`n[+] Running Ollama installer..." -ForegroundColor Cyan
    $installerArgs = @()
    if ($Silent) {
        $installerArgs = @("/VERYSILENT", "/NORESTART", "/SUPPRESSMSGBOXES")
        Write-Host "    Installing silently in background..." -ForegroundColor Gray
    } else {
        Write-Host "    Launching installer wizard..." -ForegroundColor Gray
    }

    $installProc = Start-Process -FilePath $tempInstaller -ArgumentList $installerArgs -Wait -PassThru

    Remove-Item -Force $tempInstaller -ErrorAction SilentlyContinue

    if ($installProc.ExitCode -eq 0 -or (Test-Path $OllamaExePath)) {
        Write-Host "    Direct installation finished successfully!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    Installer exited with code $($installProc.ExitCode)." -ForegroundColor Yellow
        return (Test-Path $OllamaExePath)
    }
}

function Start-OllamaDaemon {
    Write-Host "`n[+] Checking Ollama background service status..." -ForegroundColor Cyan
    
    if (Test-OllamaServiceRunning) {
        Write-Host "    Ollama service is already active and responding on $OllamaApiUrl" -ForegroundColor Green
        return
    }

    Write-Host "    Starting Ollama daemon..." -ForegroundColor Yellow
    if (Test-Path $OllamaAppPath) {
        Start-Process -FilePath $OllamaAppPath
    } elseif (Test-Path $OllamaExePath) {
        Start-Process -FilePath $OllamaExePath -ArgumentList "serve" -WindowStyle Hidden
    } else {
        Write-Host "[!] Ollama executable not found to start daemon." -ForegroundColor Red
        return
    }

    # Wait up to 10 seconds for API to respond
    Write-Host "    Waiting for API to initialize on $OllamaApiUrl..." -NoNewline -ForegroundColor Gray
    $timeout = 10
    $started = $false
    for ($i = 0; $i -lt $timeout; $i++) {
        Start-Sleep -Seconds 1
        Write-Host "." -NoNewline -ForegroundColor Gray
        if (Test-OllamaServiceRunning) {
            $started = $true
            break
        }
    }
    Write-Host ""

    if ($started) {
        Write-Host "    Ollama server is live and ready!" -ForegroundColor Green
    } else {
        Write-Host "    Note: Service launched. It may take a few moments to initialize." -ForegroundColor Gray
    }
}

function Print-Summary {
    $version = Get-InstalledVersion
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "             OLLAMA IS READY TO USE!                      " -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  * Installed Version : " -NoNewline -ForegroundColor Gray
    Write-Host "v$version" -ForegroundColor Cyan
    Write-Host "  * Location          : " -NoNewline -ForegroundColor Gray
    Write-Host "$OllamaDefaultDir" -ForegroundColor White
    Write-Host "  * API Endpoint      : " -NoNewline -ForegroundColor Gray
    Write-Host "$OllamaApiUrl" -ForegroundColor White

    Write-Host "`nQuick-Start Commands (run in any new terminal):" -ForegroundColor Yellow
    Write-Host "  ollama run llama3.2          " -NoNewline -ForegroundColor White
    Write-Host "# Fast, lightweight Meta Llama 3.2 model" -ForegroundColor DarkGray
    Write-Host "  ollama run deepseek-r1       " -NoNewline -ForegroundColor White
    Write-Host "# State-of-the-art open reasoning model" -ForegroundColor DarkGray
    Write-Host "  ollama run mistral           " -NoNewline -ForegroundColor White
    Write-Host "# Popular general-purpose 7B model" -ForegroundColor DarkGray
    Write-Host "  ollama run nomic-embed-text  " -NoNewline -ForegroundColor White
    Write-Host "# High-quality text embedding model" -ForegroundColor DarkGray
    Write-Host "  ollama list                  " -NoNewline -ForegroundColor White
    Write-Host "# View all locally installed models" -ForegroundColor DarkGray
    Write-Host "  ollama ps                    " -NoNewline -ForegroundColor White
    Write-Host "# View currently running models" -ForegroundColor DarkGray
    Write-Host "==========================================================`n" -ForegroundColor Green
}

# --- Main Program ---
Write-Banner

$isInstalled = Test-OllamaInstalled

if ($isInstalled -and -not $Force) {
    $currentVer = Get-InstalledVersion
    $isRunning  = Test-OllamaServiceRunning

    Write-Host "`n[i] Ollama is already installed on this machine." -ForegroundColor Green
    Write-Host "    Installed Version : v$currentVer" -ForegroundColor White
    Write-Host "    Location          : $OllamaDefaultDir" -ForegroundColor White
    Write-Host "    Server Status     : $(if ($isRunning) { 'Running on ' + $OllamaApiUrl } else { 'Stopped' })" -ForegroundColor $(if ($isRunning) { 'Green' } else { 'Yellow' })

    Ensure-PathConfigured

    if (-not $isRunning -and -not $NoStart) {
        Start-OllamaDaemon
    }

    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-Host "  [1] Keep current version & show quick-start guide" -ForegroundColor White
    Write-Host "  [2] Reinstall / Update Ollama to latest version" -ForegroundColor White
    Write-Host "  [Q] Exit" -ForegroundColor White

    $choice = Read-Host "`nEnter your choice [1, 2, Q]"
    if ($choice -eq "2") {
        $Force = $true
    } else {
        Print-Summary
        exit 0
    }
}

# Run installation
$success = $false

if ($Method -eq "Winget") {
    $success = Install-ViaWinget
} elseif ($Method -eq "Direct") {
    $success = Install-ViaDirectDownload
} else {
    $success = Install-ViaWinget
    if (-not $success) {
        $success = Install-ViaDirectDownload
    }
}

if (-not $success -and -not (Test-Path $OllamaExePath)) {
    Write-Host "`n[!] Installation could not be completed automatically." -ForegroundColor Red
    Write-Host "    You can manually download the installer at: $OllamaDirectUrl" -ForegroundColor Yellow
    exit 1
}

Ensure-PathConfigured

if (-not $NoStart) {
    Start-OllamaDaemon
}

Print-Summary
