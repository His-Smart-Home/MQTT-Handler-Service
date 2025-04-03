# --- Config ---
$installPath = "C:\Program Files (x86)\His Smart Home\MQTT Handler"
$startMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\His Smart Home"
$logDir = "C:\ProgramData\His Smart Home\Installer"
$logFile = Join-Path $logDir "uninstall.log"
$runKeyPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$runKeyName = "MQTTHandlerConfig"

# --- Logging ---
function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
Log "`n--- Uninstallation Started ---"

# --- Stop Running Processes (Optional) ---
# Example: Stop-Process -Name "mqtt-handler-config-util" -Force -ErrorAction SilentlyContinue

# --- Remove Installation Directory ---
if (Test-Path $installPath) {
    try {
        Remove-Item -Path $installPath -Recurse -Force
        Log "Deleted installation folder: $installPath"
    } catch {
        Log "ERROR: Could not delete install path. $_"
    }
} else {
    Log "Install path not found: $installPath"
}

# --- Remove Start Menu Shortcuts ---
if (Test-Path $startMenuFolder) {
    try {
        Remove-Item -Path $startMenuFolder -Recurse -Force
        Log "Removed Start Menu folder: $startMenuFolder"
    } catch {
        Log "ERROR: Could not delete Start Menu folder. $_"
    }
} else {
    Log "Start Menu folder not found."
}

# --- Remove Registry Startup Entry ---
try {
    if (Get-ItemProperty -Path $runKeyPath -Name $runKeyName -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $runKeyPath -Name $runKeyName -Force
        Log "Removed startup Run key: $runKeyName"
    } else {
        Log "Startup Run key not found."
    }
} catch {
    Log "ERROR: Failed to remove startup registry key. $_"
}

Log "--- Uninstallation Completed ---"
Write-Host "Uninstallation complete."
