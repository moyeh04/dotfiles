# This script registers "kanata.exe" to automatically run at user login.
# It uses conhost.exe in headless mode to hide the console window.
# The configuration file "kanata.kbd" is passed to Kanata for keyboard remapping.
# The startup entry is created in the registry under:
# HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
# This script is intended for Windows OS. However, you can download the latest kanata.exe using curl from WSL.
# Remember to download the latest kanata.exe from GitHub using one of the following commands:
# PowerShell (Windows):
# Invoke-WebRequest -Uri "https://github.com/jtroo/kanata/releases/latest/download/kanata.exe" -OutFile "C:\Windows\Kanata\kanata.exe"
# WSL (Linux subsystem within Windows):
# curl -L -o /mnt/c/Windows/Kanata/kanata.exe https://github.com/jtroo/kanata/releases/latest/download/kanata.exe

$StartupPath="HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$ProgramName="Kanata"
# Change the executable path
$KanataPath="C:\Windows\Kanata\kanata.exe"
# Change the config path
$KanataConfigPath="C:\Windows\Kanata\kanata.kbd"
$StartupCommand="C:\Windows\system32\conhost.exe --headless $KanataPath --cfg $KanataConfigPath"
Set-ItemProperty -LiteralPath "$StartupPath" -Name "$ProgramName" -Value "$StartupCommand"
