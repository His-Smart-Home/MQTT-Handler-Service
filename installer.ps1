# --- Configuration ---
$licenseUrl = "https://raw.githubusercontent.com/His-Smart-Home/MQTT-Handler-Service/refs/heads/main/LICENSE"
$installerUrl = "https://github.com/His-Smart-Home/MQTT-Handler-Service/releases/download/main-1.0/installer.zip"
$tempZip = "$env:TEMP\mqtt_installer.zip"
$installPath = "C:\Program Files (x86)\His Smart Home\MQTT Handler"
$logDir = "C:\ProgramData\His Smart Home\Installer"
$logFile = Join-Path $logDir "install.log"
$startMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\His Smart Home"
$userStartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

# --- Logging Function ---
function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Tee-Object -FilePath $logFile -Append
}

# --- Start Logging ---
if (!(Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
Log "`n--- Installation Started ---"

# --- Create Install Directory ---
if (!(Test-Path -Path $installPath)) {
    try {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        Log "Created installation directory: $installPath"
    } catch {
        Log "ERROR: Failed to create installation directory. $_"
        exit 1
    }
}

# --- License Agreement ---
Log "Downloading license from $licenseUrl"
try {
    $licenseText = Invoke-WebRequest -Uri $licenseUrl -UseBasicParsing
    Write-Host $licenseText.Content
    Log "License displayed to user."
} catch {
    Log "ERROR: Failed to download license. $_"
    exit 1
}

$agree = Read-Host "`nDo you agree to the terms of the license above? (yes/no)"
if ($agree -ne "yes") {
    Log "User declined license agreement. Installation aborted."
    Write-Host "You did not agree to the license. Exiting installer."
    exit 1
}

# --- Download Installer ---
Log "Downloading installer from $installerUrl"
try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $tempZip -UseBasicParsing
    Log "Installer downloaded to $tempZip"
} catch {
    Log "ERROR: Failed to download installer. $_"
    exit 1
}

# --- Extract ZIP ---
Log "Extracting ZIP to $installPath"
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $installPath)
    Log "Extraction complete."
} catch {
    Log "ERROR: Failed to extract installer ZIP. $_"
    exit 1
}

# --- Create Start Menu Shortcuts ---
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

# --- Add to Startup ---
$startupShortcut = Join-Path $userStartupFolder "MQTT Handler Config.lnk"
Create-Shortcut -targetPath $configExe -shortcutPath $startupShortcut -description "MQTT Config Auto Start"
Log "Added config tool to user startup: $startupShortcut"

# --- Done ---
Log "--- Installation Completed Successfully ---"
Write-Host "Installation complete! Files extracted to '$installPath'."
