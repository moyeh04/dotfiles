#!/usr/bin/env bash
# Alacritty Setup Script - Downloads ConPTY files and manages config migration

################################################################################
# Description: Copies Alacritty configuration and downloads latest ConPTY files
#
# What it does:
#   1. Checks if ConPTY is already up-to-date (skips download if same version)
#   2. Downloads latest ConPTY package from Windows Terminal releases
#   3. Extracts conpty.dll and OpenConsole.exe
#   4. Closes Alacritty and copies files
#   5. Runs alacritty migrate to handle config updates
#   6. Launches Alacritty as non-elevated user via scheduled task
#
# Requirements:
#   - alacritty.toml in ~/.config/alacritty/
#   - Alacritty installed at C:\Program Files\Alacritty\
#   - Internet connection
#   - Required tools: curl, unzip, pwsh.exe, wslpath
#
################################################################################

set -euo pipefail

readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RESET='\033[0m'

readonly PWSH_EXE="pwsh.exe"
readonly ALACRITTY_CONFIG="${HOME}/.config/alacritty/alacritty.toml"
readonly ALACRITTY_INSTALL_DIR="/mnt/c/Program Files/Alacritty"
readonly GITHUB_API_URL="https://api.github.com/repos/microsoft/terminal/releases/latest"

print_color() {
    echo -e "${1}${2}${COLOR_RESET}"
}

# Check required dependencies
print_color "${COLOR_BLUE}" "Checking dependencies..."

for cmd in curl unzip wslpath; do
    if ! command -v "$cmd" &>/dev/null; then
        print_color "${COLOR_RED}" "ERROR: Required tool '$cmd' not found"
        print_color "${COLOR_RED}" "Please install it and try again"
        exit 1
    fi
done

if ! command -v "${PWSH_EXE}" &>/dev/null; then
    print_color "${COLOR_RED}" "ERROR: PowerShell (pwsh.exe) not found"
    print_color "${COLOR_RED}" "Please install PowerShell 7+ and try again"
    exit 1
fi

print_color "${COLOR_GREEN}" "[OK] All dependencies found"

# Check if config file exists
if [[ ! -f "${ALACRITTY_CONFIG}" ]]; then
    print_color "${COLOR_RED}" "ERROR: alacritty.toml not found at ${ALACRITTY_CONFIG}"
    exit 1
fi

# Check if Alacritty is installed
if [[ ! -d "${ALACRITTY_INSTALL_DIR}" ]]; then
    print_color "${COLOR_RED}" "ERROR: Alacritty not found at ${ALACRITTY_INSTALL_DIR}"
    print_color "${COLOR_RED}" "Please install Alacritty first"
    exit 1
fi

print_color "${COLOR_BLUE}" "Fetching latest Windows Terminal version..."

# Get latest release info
latest_version=$(curl -s "${GITHUB_API_URL}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//')
print_color "${COLOR_YELLOW}" "[INFO] Latest Windows Terminal version: ${latest_version}"

# Check if we already have this version installed
version_file="${ALACRITTY_INSTALL_DIR}/conpty_version.txt"
conpty_dll_file="${ALACRITTY_INSTALL_DIR}/conpty.dll"
openconsole_file="${ALACRITTY_INSTALL_DIR}/OpenConsole.exe"

if [[ -f "${version_file}" ]] && [[ -f "${conpty_dll_file}" ]] && [[ -f "${openconsole_file}" ]]; then
    installed_version=$(cat "${version_file}")
    if [[ "${installed_version}" == "${latest_version}" ]]; then
        print_color "${COLOR_GREEN}" "[OK] ConPTY is already up-to-date (version ${latest_version})"
        print_color "${COLOR_GREEN}" "✓ No update needed"
        exit 0
    else
        print_color "${COLOR_YELLOW}" "[INFO] Installed version: ${installed_version}"
        print_color "${COLOR_YELLOW}" "[INFO] Updating to: ${latest_version}"
    fi
else
    if [[ ! -f "${version_file}" ]]; then
        print_color "${COLOR_YELLOW}" "[INFO] No version file found"
    fi
    if [[ ! -f "${conpty_dll_file}" ]]; then
        print_color "${COLOR_YELLOW}" "[INFO] conpty.dll missing"
    fi
    if [[ ! -f "${openconsole_file}" ]]; then
        print_color "${COLOR_YELLOW}" "[INFO] OpenConsole.exe missing"
    fi
    print_color "${COLOR_YELLOW}" "[INFO] Proceeding with installation"
fi

# Download ConPTY NuGet package
print_color "${COLOR_YELLOW}" "[INFO] Downloading ConPTY package..."

# Get the build number from the API
build_number=$(curl -s "${GITHUB_API_URL}" | grep -o 'Microsoft\.Windows\.Console\.ConPTY\.[0-9.]*\.nupkg' | head -1 | sed 's/Microsoft\.Windows\.Console\.ConPTY\.\(.*\)\.nupkg/\1/')

download_url="https://github.com/microsoft/terminal/releases/download/v${latest_version}/Microsoft.Windows.Console.ConPTY.${build_number}.nupkg"

temp_dir=$(mktemp -d)

if ! curl -L -o "${temp_dir}/conpty.nupkg" "${download_url}"; then
    print_color "${COLOR_RED}" "ERROR: Failed to download ConPTY package"
    rm -rf "${temp_dir}"
    exit 1
fi

# Extract the nupkg (it's just a ZIP)
print_color "${COLOR_YELLOW}" "[INFO] Extracting ConPTY files..."
unzip -q "${temp_dir}/conpty.nupkg" -d "${temp_dir}/extracted"

# Find the actual location of the files
print_color "${COLOR_YELLOW}" "[INFO] Locating ConPTY binaries..."

conpty_dll=$(find "${temp_dir}/extracted" -name "conpty.dll" -type f | grep -i "x64\|amd64" | head -1)
openconsole_exe=$(find "${temp_dir}/extracted" -name "OpenConsole.exe" -type f | grep -i "x64\|amd64" | head -1)

if [[ -z "${conpty_dll}" ]] || [[ -z "${openconsole_exe}" ]]; then
    print_color "${COLOR_RED}" "ERROR: Could not find ConPTY files in package"
    print_color "${COLOR_YELLOW}" "Package contents:"
    find "${temp_dir}/extracted" -name "*.dll" -o -name "*.exe"
    rm -rf "${temp_dir}"
    exit 1
fi

print_color "${COLOR_GREEN}" "[OK] Found conpty.dll"
print_color "${COLOR_GREEN}" "[OK] Found OpenConsole.exe"

# Copy files to temp directory first
TEMP_CONPTY="${temp_dir}/conpty.dll"
TEMP_OPENCONSOLE="${temp_dir}/OpenConsole.exe"

cp "${conpty_dll}" "${TEMP_CONPTY}"
cp "${openconsole_exe}" "${TEMP_OPENCONSOLE}"

# Convert paths to Windows format
WIN_ALACRITTY_DIR=$(wslpath -w "${ALACRITTY_INSTALL_DIR}")
WIN_TEMP_CONPTY=$(wslpath -w "${TEMP_CONPTY}")
WIN_TEMP_OPENCONSOLE=$(wslpath -w "${TEMP_OPENCONSOLE}")
WIN_CONFIG_PATH=$(wslpath -w "${ALACRITTY_CONFIG}")

# Copy files using PowerShell with admin privileges
print_color "${COLOR_RED}" "=========================================="
print_color "${COLOR_RED}" "WARNING: Alacritty will now close"
print_color "${COLOR_RED}" "=========================================="
print_color "${COLOR_YELLOW}" "[INFO] Elevated PowerShell will open"
sleep 2

# Create a PowerShell script
ps_script="${temp_dir}/copy_files.ps1"
cat >"${ps_script}" <<'EOF'
param(
    [string]$TempConpty,
    [string]$TempOpenConsole,
    [string]$AlacrittyDir,
    [string]$Version,
    [string]$ConfigPath
)

$ErrorActionPreference = "Stop"

try {
    Write-Host "Closing Alacritty..." -ForegroundColor Yellow
    Get-Process alacritty -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Wait for process to release file handles
    Start-Sleep -Milliseconds 500
    
    # Verify closed
    $retries = 0
    while ((Get-Process alacritty -ErrorAction SilentlyContinue) -and ($retries -lt 20)) {
        Start-Sleep -Milliseconds 100
        $retries++
    }
    
    Write-Host "Copying ConPTY files..." -ForegroundColor Yellow
    Copy-Item $TempConpty "$AlacrittyDir\conpty.dll" -Force
    Write-Host "[OK] Copied conpty.dll" -ForegroundColor Green
    
    Copy-Item $TempOpenConsole "$AlacrittyDir\OpenConsole.exe" -Force
    Write-Host "[OK] Copied OpenConsole.exe" -ForegroundColor Green
    
    $Version | Out-File -FilePath "$AlacrittyDir\conpty_version.txt" -Encoding ASCII -NoNewline -Force
    Write-Host "[OK] Saved version" -ForegroundColor Green
    
    # Copy config to AppData
    Write-Host ""
    Write-Host "Setting up config..." -ForegroundColor Yellow
    $AlacrittyConfigDir = "$env:APPDATA\alacritty"
    
    if (!(Test-Path $AlacrittyConfigDir)) {
        New-Item -ItemType Directory -Path $AlacrittyConfigDir -Force | Out-Null
        Write-Host "[OK] Created config directory" -ForegroundColor Green
    }
    
    Copy-Item $ConfigPath "$AlacrittyConfigDir\alacritty.toml" -Force
    Write-Host "[OK] Copied config to AppData" -ForegroundColor Green
    
    # Run alacritty migrate to update any deprecated config keys
    Write-Host ""
    Write-Host "Running alacritty migrate..." -ForegroundColor Yellow
    
    Push-Location $AlacrittyConfigDir
    $migrateOutput = & "$AlacrittyDir\alacritty.exe" migrate 2>&1 | Out-String
    Pop-Location
    
    Write-Host "Migration output:" -ForegroundColor Cyan
    Write-Host $migrateOutput -ForegroundColor Gray
    Write-Host "[OK] Migration complete" -ForegroundColor Green
    
    # Always copy config back to WSL
    Write-Host "Copying config back to WSL..." -ForegroundColor Yellow
    Copy-Item "$AlacrittyConfigDir\alacritty.toml" $ConfigPath -Force
    Write-Host "[OK] Config copied back to WSL" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Launching Alacritty as current user (not admin)..." -ForegroundColor Yellow
    
    # Get the current logged-in user
    $currentUser = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -expand UserName)
    Write-Host "Current user: $currentUser" -ForegroundColor Cyan
    
    # Create a scheduled task that runs as the current user (NOT admin)
    # This task will launch Alacritty and then self-delete
    $taskName = "LaunchAlacritty_Temp_$(Get-Random)"
    
    $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive
    
    # Trigger immediately
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
    $trigger.StartBoundary = (Get-Date).ToString("yyyy-MM-dd'T'HH:mm:ss")
    $trigger.EndBoundary = (Get-Date).AddMinutes(1).ToString("yyyy-MM-dd'T'HH:mm:ss")
    
    # Configure to auto-delete after task expires (no execution time limit - Alacritty runs forever)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -Hidden -DontStopIfGoingOnBatteries -DeleteExpiredTaskAfter (New-TimeSpan -Seconds 10)
    
    # Action: launch Alacritty
    $action = New-ScheduledTaskAction -Execute "$AlacrittyDir\alacritty.exe"
    
    # Register and run the task
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
    Register-ScheduledTask -TaskName $taskName -InputObject $task | Out-Null
    
    # Start the task immediately
    Start-ScheduledTask -TaskName $taskName
    
    Write-Host "[OK] Alacritty launched as normal user (not admin)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Success! All files copied." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to close"
EOF

WIN_PS_SCRIPT=$(wslpath -w "${ps_script}")

# Launch elevated PowerShell and wait for it to complete
"${PWSH_EXE}" -Command "Start-Process pwsh -Verb RunAs -Wait -ArgumentList '-ExecutionPolicy', 'Bypass', '-File', '\"${WIN_PS_SCRIPT}\"', '-TempConpty', '\"${WIN_TEMP_CONPTY}\"', '-TempOpenConsole', '\"${WIN_TEMP_OPENCONSOLE}\"', '-AlacrittyDir', '\"${WIN_ALACRITTY_DIR}\"', '-Version', '\"${latest_version}\"', '-ConfigPath', '\"${WIN_CONFIG_PATH}\"'"

# Cleanup
rm -rf "${temp_dir}"

print_color "${COLOR_GREEN}" "✓ Setup complete"
