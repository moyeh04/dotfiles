#!/usr/bin/env bash

################################################################################
# Kanata Setup Script
#
# Description: Downloads latest Kanata from GitHub and sets up auto-start
#
# What it does:
#   1. Checks if latest version is already installed
#   2. Downloads kanata-windows-binaries-x64 ZIP from GitHub releases
#   3. Extracts the GUI variant (no cmd_allowed)
#   4. Copies kanata_config.kbd from WSL to Windows
#   5. Registers Kanata to start automatically on login
#

# Requirements:
#   - kanata_config.kbd in ~/.config/windows/kanata/
#   - Internet connection
#   - unzip utility
#
################################################################################

set -euo pipefail

readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'

readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RESET='\033[0m'

readonly PWSH_EXE="pwsh.exe"

# Get script directory - expect to be in ~/.config/winconf/kanata_windows/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd && cd ../../)"
readonly WSL_KANATA_CONFIG="${SCRIPT_DIR}/kanata/kanata_config.kbd"
readonly WIN_KANATA_PATH="/mnt/c/Windows/Kanata"
readonly GITHUB_API_URL="https://api.github.com/repos/jtroo/kanata/releases/latest"
readonly BINARY_VARIANT="kanata_winIOv2_cmd_allowed.exe" # TTY variant with cmd support

print_color() {
    echo -e "${1}${2}${COLOR_RESET}"
}

# Check if config file exists
if [[ ! -f "${WSL_KANATA_CONFIG}" ]]; then
    print_color "${COLOR_RED}" "ERROR: kanata_config.kbd not found at ${WSL_KANATA_CONFIG}"
    exit 1
fi

print_color "${COLOR_BLUE}" "Checking latest Kanata version..."

# Get latest release info from GitHub API
latest_version=$(curl -s "${GITHUB_API_URL}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

print_color "${COLOR_YELLOW}" "[INFO] Latest version: ${latest_version}"

# Check current installed version
if [[ -f "${WIN_KANATA_PATH}/version.txt" ]]; then
    current_version=$(cat "${WIN_KANATA_PATH}/version.txt")
    if [[ "${current_version}" == "${latest_version}" ]]; then
        print_color "${COLOR_GREEN}" "[INFO] Already up to date (${current_version})"
        print_color "${COLOR_YELLOW}" "[INFO] Skipping download, only updating config..."

        # Just copy config and register startup

        cp "${WSL_KANATA_CONFIG}" "${WIN_KANATA_PATH}/kanata_config.kbd"
        print_color "${COLOR_GREEN}" "[OK] Updated kanata_config.kbd"

        # Register startup (skip to end)
        SKIP_DOWNLOAD=true
    else
        print_color "${COLOR_YELLOW}" "[INFO] Current version: ${current_version}, updating..."
        SKIP_DOWNLOAD=false
    fi

else
    print_color "${COLOR_YELLOW}" "[INFO] No existing installation found"
    SKIP_DOWNLOAD=false
fi

if [[ "${SKIP_DOWNLOAD}" != "true" ]]; then
    # Create directory if needed
    mkdir -p "${WIN_KANATA_PATH}"

    # Download the x64 Windows binaries ZIP
    print_color "${COLOR_YELLOW}" "[INFO] Downloading Kanata ${latest_version}..."
    download_url="https://github.com/jtroo/kanata/releases/download/${latest_version}/kanata-windows-binaries-x64-${latest_version}.zip"

    if ! curl -L -o "${WIN_KANATA_PATH}/kanata.zip" "${download_url}"; then
        print_color "${COLOR_RED}" "ERROR: Failed to download kanata"
        exit 1
    fi

    # Extract the specific binary variant
    print_color "${COLOR_YELLOW}" "[INFO] Extracting ${BINARY_VARIANT}..."
    if ! unzip -o "${WIN_KANATA_PATH}/kanata.zip" "${BINARY_VARIANT}" -d "${WIN_KANATA_PATH}"; then
        print_color "${COLOR_RED}" "ERROR: Failed to extract binary"

        rm -f "${WIN_KANATA_PATH}/kanata.zip"
        exit 1
    fi

    # Rename to kanata.exe for simplicity
    mv "${WIN_KANATA_PATH}/${BINARY_VARIANT}" "${WIN_KANATA_PATH}/kanata.exe"

    # Save version info
    echo "${latest_version}" >"${WIN_KANATA_PATH}/version.txt"

    # Cleanup
    rm -f "${WIN_KANATA_PATH}/kanata.zip"

    print_color "${COLOR_GREEN}" "[OK] Downloaded and extracted kanata.exe"

    # Copy config
    cp "${WSL_KANATA_CONFIG}" "${WIN_KANATA_PATH}/kanata_config.kbd"
    print_color "${COLOR_GREEN}" "[OK] Copied kanata_config.kbd"
fi

# Register startup

"${PWSH_EXE}" -Command "Start-Process pwsh.exe -Verb RunAs -ArgumentList '-NoProfile -Command', {
    # Register startup
    \$StartupPath = 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run'

    \$ProgramName = 'Kanata'
    \$KanataPath = 'C:\\Windows\\Kanata\\kanata.exe'
    \$KanataConfigPath = 'C:\\Windows\\Kanata\\kanata_config.kbd'
    \$StartupCommand = 'C:\\Windows\\system32\\conhost.exe --headless ' + \$KanataPath + ' --cfg ' + \$KanataConfigPath

    
    Set-ItemProperty -LiteralPath \$StartupPath -Name \$ProgramName -Value \$StartupCommand
    Write-Host '[OK] Registered Kanata for startup' -ForegroundColor Green
    Write-Host '[DONE] Kanata setup complete' -ForegroundColor Cyan
    
    Read-Host 'Press Enter to close'
} -Wait"

print_color "${COLOR_GREEN}" "✓ Setup complete"
