<# :
@echo off
setlocal
title Windows GPU Auto-Detector and Driver Portal Launcher
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Invoke-Expression (Get-Content -LiteralPath '%~f0' -Raw)"
if errorlevel 1 (
    echo.
    echo [!] Script encountered an error.
)
echo.
pause
exit /b %errorlevel%
#>

# ==============================================================================
# Windows GPU Auto-Detector & Driver Portal Launcher
# Self-contained single-file script (can be double-clicked directly).
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Driver Download URLs
$DriverUrls = @{
    "NVIDIA"    = @{
        Name   = "NVIDIA Driver Downloads (GeForce / RTX / Studio)"
        Url    = "https://www.nvidia.com/Download/index.aspx"
    }
    "AMD"       = @{
        Name   = "AMD Drivers and Support (Radeon RX / PRO / APU)"
        Url    = "https://www.amd.com/en/support/download/drivers.html"
    }
    "INTEL_ARC" = @{
        Name   = "Intel Arc & Iris Xe Graphics Driver Portal"
        Url    = "https://www.intel.com/content/www/us/en/download/785597/intel-arc-iris-xe-graphics-windows.html"
    }
    "INTEL_GEN" = @{
        Name   = "Intel Driver & Support Assistant (Auto-Detect)"
        Url    = "https://www.intel.com/content/www/us/en/support/detect.html"
    }
}

# Known virtual/remote display adapters to ignore
$VirtualKeywords = @("parsec", "citrix", "remote display", "rdp", "virtualbox", "vmware", "splashtop", "anydesk", "teamviewer", "spacedesk", "viddummydriver", "mirage", "indirect display")

function Write-Banner {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "     WINDOWS GPU AUTO-DETECTOR & DRIVER PORTAL LAUNCHER   " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Get-GpuVendor {
    param(
        [string]$Name,
        [string]$PnpId
    )

    $upperName = if ($Name) { $Name.ToUpperInvariant() } else { "" }
    $upperPnp  = if ($PnpId) { $PnpId.ToUpperInvariant() } else { "" }

    # Match by PCI Vendor ID (most reliable) and string patterns:
    # VEN_10DE = NVIDIA
    # VEN_1002 = AMD / ATI
    # VEN_8086 = Intel
    if ($upperPnp -match "VEN_10DE" -or $upperName -match "NVIDIA|GEFORCE|RTX|GTX|QUADRO|TESLA|TITAN") {
        return "NVIDIA"
    }
    elseif ($upperPnp -match "VEN_1002" -or $upperName -match "AMD|RADEON|ATI TECHNOLOGIES|ADVANCED MICRO DEVICES") {
        return "AMD"
    }
    elseif ($upperPnp -match "VEN_8086" -or $upperName -match "INTEL") {
        # Check specifically for Intel Arc dedicated / modern architecture
        if ($upperName -match "ARC|A3\d\d|A5\d\d|A7\d\d|B5\d\d|B7\d\d|BATTLEMAGE|ALCHEMIST") {
            return "INTEL_ARC"
        } else {
            return "INTEL_GEN"
        }
    }

    return "UNKNOWN"
}

function Open-Url {
    param([string]$Url, [string]$Label)
    Write-Host "`n[>] Opening $Label in your default browser..." -ForegroundColor Green
    Write-Host "    $Url" -ForegroundColor Gray
    try {
        Start-Process $Url
    } catch {
        [System.Diagnostics.Process]::Start($Url) | Out-Null
    }
}

# --- Execution ---
Write-Banner

Write-Host "`nScanning system video controllers..." -ForegroundColor Gray

$rawAdapters = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)
if (-not $rawAdapters -or $rawAdapters.Count -eq 0) {
    Write-Host "[!] Could not query Win32_VideoController." -ForegroundColor Red
    exit 1
}

$detectedGpus = @()
$virtualAdapters = @()

foreach ($adapter in $rawAdapters) {
    $isVirtual = $false
    foreach ($vk in $VirtualKeywords) {
        if ($adapter.Name -like "*$vk*") {
            $isVirtual = $true
            break
        }
    }

    if ($isVirtual) {
        $virtualAdapters += $adapter
        continue
    }

    $vendorKey = Get-GpuVendor -Name $adapter.Name -PnpId $adapter.PNPDeviceID
    $gpuObj = [PSCustomObject]@{
        Name          = $adapter.Name
        VendorKey     = $vendorKey
        DriverVersion = $adapter.DriverVersion
        DriverDate    = if ($adapter.DriverDate) { (Get-Date $adapter.DriverDate).ToString("yyyy-MM-dd") } else { "Unknown" }
        PnpId         = $adapter.PNPDeviceID
        Status        = $adapter.Status
    }
    $detectedGpus += $gpuObj
}

if ($detectedGpus.Count -eq 0) {
    Write-Host "`n[!] No physical AMD, NVIDIA, or Intel GPUs were detected." -ForegroundColor Yellow
    if ($virtualAdapters.Count -gt 0) {
        $virtNames = ($virtualAdapters | Select-Object -ExpandProperty Name) -join ', '
        Write-Host "    (Ignored virtual adapters: $virtNames)" -ForegroundColor DarkGray
    }
    Write-Host "`nDriver portal links:" -ForegroundColor Cyan
    Write-Host "  * NVIDIA:    $($DriverUrls['NVIDIA'].Url)"
    Write-Host "  * AMD:       $($DriverUrls['AMD'].Url)"
    Write-Host "  * Intel Arc: $($DriverUrls['INTEL_ARC'].Url)"
    exit 0
}

Write-Host "`nDetected Graphics Hardware:" -ForegroundColor Cyan
for ($i = 0; $i -lt $detectedGpus.Count; $i++) {
    $gpu = $detectedGpus[$i]
    $badge = switch ($gpu.VendorKey) {
        "NVIDIA"    { "[NVIDIA]" }
        "AMD"       { "[AMD]" }
        "INTEL_ARC" { "[INTEL ARC]" }
        "INTEL_GEN" { "[INTEL GRAPHICS]" }
        default     { "[OTHER]" }
    }
    
    $color = switch ($gpu.VendorKey) {
        "NVIDIA"    { "Green" }
        "AMD"       { "Red" }
        "INTEL_ARC" { "Cyan" }
        "INTEL_GEN" { "Blue" }
        default     { "White" }
    }

    Write-Host "  [$($i + 1)] " -NoNewline -ForegroundColor White
    Write-Host "$badge " -NoNewline -ForegroundColor $color
    Write-Host "$($gpu.Name)" -ForegroundColor White
    Write-Host "      Installed Driver: $($gpu.DriverVersion) (Date: $($gpu.DriverDate))" -ForegroundColor Gray
}

if ($virtualAdapters.Count -gt 0) {
    $virtNames = ($virtualAdapters | Select-Object -ExpandProperty Name) -join ', '
    Write-Host "`n  (Ignored virtual adapters: $virtNames)" -ForegroundColor DarkGray
}

# Unique vendors as an array
$uniqueVendors = @($detectedGpus.VendorKey | Select-Object -Unique | Where-Object { $DriverUrls.ContainsKey($_) })

if ($uniqueVendors.Count -eq 1) {
    $driverInfo = $DriverUrls[$uniqueVendors[0]]
    Open-Url -Url $driverInfo.Url -Label $driverInfo.Name
} elseif ($uniqueVendors.Count -gt 1) {
    Write-Host "`nMultiple GPU vendors detected. Select which driver page to open:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $uniqueVendors.Count; $i++) {
        $v = $uniqueVendors[$i]
        Write-Host "  [$($i + 1)] $($DriverUrls[$v].Name)" -ForegroundColor White
    }
    Write-Host "  [A] Open all detected portals" -ForegroundColor White
    Write-Host "  [Q] Quit without opening" -ForegroundColor White

    $choice = Read-Host "`nSelect an option [1-$($uniqueVendors.Count), A, Q]"
    
    if ($choice -match "^[0-9]+$" -and [int]$choice -ge 1 -and [int]$choice -le $uniqueVendors.Count) {
        $selectedVendor = $uniqueVendors[[int]$choice - 1]
        $driverInfo = $DriverUrls[$selectedVendor]
        Open-Url -Url $driverInfo.Url -Label $driverInfo.Name
    } elseif ($choice -match "^[aA]$") {
        foreach ($vendor in $uniqueVendors) {
            $driverInfo = $DriverUrls[$vendor]
            Open-Url -Url $driverInfo.Url -Label $driverInfo.Name
        }
    } else {
        Write-Host "`nExiting. No pages opened." -ForegroundColor Gray
    }
}

Write-Host "`nDone!" -ForegroundColor Green
