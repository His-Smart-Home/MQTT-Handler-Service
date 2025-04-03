# Configuration
$licenseUrl = "https://raw.githubusercontent.com/His-Smart-Home/MQTT-Handler-Service/refs/heads/main/LICENSE"
$installerUrl = "https://github.com/His-Smart-Home/MQTT-Handler-Service/releases/download/main-1.0/installer.zip"
$tempZip = "$env:TEMP\mqtt_installer.zip"
$installPath = "C:\Program Files (x86)\His Smart Home\MQTT Handler"
$logDir = "C:\ProgramData\His Smart Home\Installer"
$logFile = Join-Path $logDir "install.log"
$startMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\His Smart Home"
$runKeyPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$runKeyName = "MQTTHandlerConfig"

# Logging function
function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# Ensure logging directory exists
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
Log "`n--- Intune Installation Started ---"

# Ensure installation path exists
if (!(Test-Path $installPath)) {
    try {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        Log "Created installation directory: $installPath"
    } catch {
        Log "ERROR: Failed to create installation directory. $_"
        exit 1
    }
}

# Download installer
try {
    Log "Downloading installer from $installerUrl"
    Invoke-WebRequest -Uri $installerUrl -OutFile $tempZip -UseBasicParsing
    Log "Installer downloaded to $tempZip"
} catch {
    Log "ERROR: Failed to download installer. $_"
    exit 1
}

# Extract installer
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $installPath)
    Log "Installer extracted to $installPath"
} catch {
    Log "ERROR: Failed to extract ZIP. $_"
    exit 1
}

# Create Start Menu Shortcuts
function Create-Shortcut {
    param (
        [string]$targetPath,
        [string]$shortcutPath,
        [string]$description = ""
    )
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetPath
    $shortcut.WorkingDirectory = Split-Path $targetPath
    $shortcut.Description = $description
    $shortcut.Save()
}

if (!(Test-Path -Path $startMenuFolder)) {
    New-Item -ItemType Directory -Path $startMenuFolder -Force | Out-Null
    Log "Created Start Menu folder: $startMenuFolder"
}

$configExe = Join-Path $installPath "mqtt-handler-config-util.exe"
$serviceExe = Join-Path $installPath "mqtt-handler-service.exe"

Create-Shortcut -targetPath $configExe -shortcutPath "$startMenuFolder\MQTT Handler Config.lnk" -description "MQTT Config Tool"
Create-Shortcut -targetPath $serviceExe -shortcutPath "$startMenuFolder\MQTT Handler Service.lnk" -description "MQTT Handler Service"
Log "Created Start Menu shortcuts."

# Add Config Utility to startup (for all users using HKLM Run key)
try {
    Set-ItemProperty -Path $runKeyPath -Name $runKeyName -Value "`"$configExe`""
    Log "Registered $configExe in system startup (Run key: $runKeyName)"
} catch {
    Log "ERROR: Failed to add startup entry to registry. $_"
}

Log "--- Intune Installation Completed ---"
