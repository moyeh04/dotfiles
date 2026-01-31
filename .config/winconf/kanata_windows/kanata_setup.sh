#!/usr/bin/env bash

################################################################################
# Kanata Setup Script
#
# Usage:
#   ./kanata_setup.sh [command]
#
# Commands:
#   install   Download and install latest Kanata (default if no command)
#   update    Same as install - always overwrites with latest
#   start     Start Kanata headless
#   stop      Stop Kanata process
#   enable    Register Kanata to start on login
#   disable   Remove startup registration (keeps files)
#   status    Check installation and startup status
#   uninstall Remove everything (files + startup registration)
#
################################################################################

set -euo pipefail

readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

readonly PWSH_EXE="pwsh.exe"
readonly WSL_KANATA_CONFIG="${HOME}/.config/kanata/kanata_config.kbd"
readonly WIN_KANATA_DIR="/mnt/c/Windows/Kanata"
readonly VERSION_FILE="${WIN_KANATA_DIR}/version.txt"
readonly GITHUB_API_URL="https://api.github.com/repos/jtroo/kanata/releases/latest"
readonly BINARY_VARIANT="kanata_windows_tty_winIOv2_cmd_allowed_x64.exe"
readonly STARTUP_COMMAND="C:\\Windows\\system32\\conhost.exe --headless C:\\Windows\\Kanata\\kanata.exe --cfg C:\\Windows\\Kanata\\kanata_config.kbd"

print_color() {
    echo -e "${1}${2}${COLOR_RESET}"
}

check_dependencies() {
    for cmd in curl unzip wslpath; do
        if ! command -v "$cmd" &>/dev/null; then
            print_color "${COLOR_RED}" "ERROR: Required tool '$cmd' not found"
            exit 1
        fi
    done

    if ! command -v "${PWSH_EXE}" &>/dev/null; then
        print_color "${COLOR_RED}" "ERROR: PowerShell (pwsh.exe) not found"
        exit 1
    fi
}

get_startup_status() {
    # Returns: "registered", "different", or "none"
    local result
    result=$("${PWSH_EXE}" -NoProfile -Command "
        \$val = Get-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' -Name 'Kanata' -ErrorAction SilentlyContinue
        if (\$val) {
            if (\$val.Kanata -eq '${STARTUP_COMMAND}') {
                Write-Output 'registered'
            } else {
                Write-Output 'different'
            }
        } else {
            Write-Output 'none'
        }
    " 2>/dev/null | tr -d '\r')
    echo "${result}"
}

cmd_status() {
    print_color "${COLOR_BLUE}" "=== Kanata Status ==="
    echo ""

    # Check installation
    print_color "${COLOR_CYAN}" "Installation:"
    if [[ -f "${WIN_KANATA_DIR}/kanata.exe" ]]; then
        print_color "${COLOR_GREEN}" "  ✓ kanata.exe installed"
    else
        print_color "${COLOR_RED}" "  ✗ kanata.exe not found"
    fi

    if [[ -f "${WIN_KANATA_DIR}/kanata_config.kbd" ]]; then
        print_color "${COLOR_GREEN}" "  ✓ kanata_config.kbd installed"
    else
        print_color "${COLOR_RED}" "  ✗ kanata_config.kbd not found"
    fi

    if [[ -f "${VERSION_FILE}" ]]; then
        local installed_version
        installed_version=$(cat "${VERSION_FILE}")
        print_color "${COLOR_GREEN}" "  ✓ Version: ${installed_version}"
    else
        print_color "${COLOR_YELLOW}" "  ? Version: unknown (no version.txt)"
    fi

    # Check WSL config
    echo ""
    print_color "${COLOR_CYAN}" "WSL Config:"
    if [[ -f "${WSL_KANATA_CONFIG}" ]]; then
        print_color "${COLOR_GREEN}" "  ✓ ${WSL_KANATA_CONFIG}"
    else
        print_color "${COLOR_RED}" "  ✗ ${WSL_KANATA_CONFIG} not found"
    fi

    # Check startup registration
    echo ""
    print_color "${COLOR_CYAN}" "Startup Registration:"
    local status
    status=$(get_startup_status)
    case "${status}" in
        registered)
            print_color "${COLOR_GREEN}" "  ✓ Registered (correct command)"
            ;;
        different)
            print_color "${COLOR_YELLOW}" "  ⚠ Registered but with different command"
            ;;
        none)
            print_color "${COLOR_RED}" "  ✗ Not registered"
            ;;
    esac

    # Check if running
    echo ""
    print_color "${COLOR_CYAN}" "Process:"
    if "${PWSH_EXE}" -NoProfile -Command "Get-Process kanata -ErrorAction SilentlyContinue" &>/dev/null; then
        print_color "${COLOR_GREEN}" "  ✓ Kanata is running"
    else
        print_color "${COLOR_YELLOW}" "  ○ Kanata is not running"
    fi

    # Check latest version
    echo ""
    print_color "${COLOR_CYAN}" "Latest Available:"
    local latest
    latest=$(curl -s "${GITHUB_API_URL}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -n "${latest}" ]]; then
        print_color "${COLOR_BLUE}" "  ${latest}"
        if [[ -f "${VERSION_FILE}" ]]; then
            local installed
            installed=$(cat "${VERSION_FILE}")
            if [[ "${installed}" == "${latest}" ]]; then
                print_color "${COLOR_GREEN}" "  ✓ Up to date"
            else
                print_color "${COLOR_YELLOW}" "  ↑ Update available"
            fi
        fi
    else
        print_color "${COLOR_RED}" "  ? Could not fetch (network issue?)"
    fi
}

cmd_enable() {
    print_color "${COLOR_BLUE}" "Registering Kanata for startup..."

    local status
    status=$(get_startup_status)

    if [[ "${status}" == "registered" ]]; then
        print_color "${COLOR_GREEN}" "Already registered with correct command"
        return 0
    fi

    if [[ "${status}" == "different" ]]; then
        print_color "${COLOR_YELLOW}" "Startup entry exists but with different command. Updating..."
    fi

    "${PWSH_EXE}" -NoProfile -Command "
        \$StartupPath = 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run'
        \$StartupCommand = '${STARTUP_COMMAND}'
        Set-ItemProperty -LiteralPath \$StartupPath -Name 'Kanata' -Value \$StartupCommand
    "
    print_color "${COLOR_GREEN}" "✓ Registered Kanata for startup"
}

cmd_disable() {
    print_color "${COLOR_BLUE}" "Removing startup registration..."

    local status
    status=$(get_startup_status)

    if [[ "${status}" == "none" ]]; then
        print_color "${COLOR_YELLOW}" "Not registered, nothing to disable"
        return 0
    fi

    "${PWSH_EXE}" -NoProfile -Command "
        Remove-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' -Name 'Kanata' -ErrorAction SilentlyContinue
    "
    print_color "${COLOR_GREEN}" "✓ Removed startup registration (files kept)"
}

is_kanata_running() {
    "${PWSH_EXE}" -NoProfile -Command "Get-Process kanata -ErrorAction SilentlyContinue" &>/dev/null
}

cmd_start() {
    if ! [[ -f "${WIN_KANATA_DIR}/kanata.exe" ]]; then
        print_color "${COLOR_RED}" "ERROR: Kanata not installed. Run './kanata_setup.sh install' first."
        exit 1
    fi

    if is_kanata_running; then
        print_color "${COLOR_YELLOW}" "Kanata is already running"
        return 0
    fi

    print_color "${COLOR_BLUE}" "Starting Kanata..."
    "${PWSH_EXE}" -NoProfile -Command "Start-Process -FilePath 'C:\Windows\system32\conhost.exe' -ArgumentList '--headless', 'C:\Windows\Kanata\kanata.exe', '--cfg', 'C:\Windows\Kanata\kanata_config.kbd' -WindowStyle Hidden"
    sleep 1

    if is_kanata_running; then
        print_color "${COLOR_GREEN}" "✓ Kanata started"
    else
        print_color "${COLOR_RED}" "✗ Failed to start Kanata"
        exit 1
    fi
}

cmd_stop() {
    if ! is_kanata_running; then
        print_color "${COLOR_YELLOW}" "Kanata is not running"
        return 0
    fi

    print_color "${COLOR_BLUE}" "Stopping Kanata..."
    "${PWSH_EXE}" -NoProfile -Command "Get-Process kanata -ErrorAction SilentlyContinue | Stop-Process -Force"
    sleep 1

    if ! is_kanata_running; then
        print_color "${COLOR_GREEN}" "✓ Kanata stopped"
    else
        print_color "${COLOR_RED}" "✗ Failed to stop Kanata"
        exit 1
    fi
}

cmd_uninstall() {
    print_color "${COLOR_RED}" "=== Uninstalling Kanata ==="

    # Disable startup first
    cmd_disable

    # Kill if running
    print_color "${COLOR_BLUE}" "Stopping Kanata if running..."
    "${PWSH_EXE}" -NoProfile -Command "Get-Process kanata -ErrorAction SilentlyContinue | Stop-Process -Force" 2>/dev/null || true
    sleep 1

    # Delete files
    print_color "${COLOR_BLUE}" "Removing files..."
    if [[ -d "${WIN_KANATA_DIR}" ]]; then
        rm -rf "${WIN_KANATA_DIR}"
        print_color "${COLOR_GREEN}" "✓ Removed ${WIN_KANATA_DIR}"
    else
        print_color "${COLOR_YELLOW}" "Directory doesn't exist, nothing to delete"
    fi

    print_color "${COLOR_GREEN}" "✓ Kanata uninstalled"
}

cmd_install() {
    check_dependencies

    # Check WSL config exists
    if [[ ! -f "${WSL_KANATA_CONFIG}" ]]; then
        print_color "${COLOR_RED}" "ERROR: kanata_config.kbd not found at ${WSL_KANATA_CONFIG}"
        exit 1
    fi
    print_color "${COLOR_GREEN}" "[OK] Config found"

    # Get latest version
    print_color "${COLOR_BLUE}" "Fetching latest Kanata version..."
    local latest_version
    latest_version=$(curl -s "${GITHUB_API_URL}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "${latest_version}" ]]; then
        print_color "${COLOR_RED}" "ERROR: Failed to get latest version from GitHub"
        exit 1
    fi
    print_color "${COLOR_YELLOW}" "[INFO] Latest version: ${latest_version}"

    # Check if already up to date
    if [[ -f "${VERSION_FILE}" ]] && [[ -f "${WIN_KANATA_DIR}/kanata.exe" ]] && [[ -f "${WIN_KANATA_DIR}/kanata_config.kbd" ]]; then
        local installed_version
        installed_version=$(cat "${VERSION_FILE}")
        if [[ "${installed_version}" == "${latest_version}" ]]; then
            print_color "${COLOR_GREEN}" "[OK] Already up to date (${latest_version})"

            # Check if config needs syncing
            if ! cmp -s "${WSL_KANATA_CONFIG}" "${WIN_KANATA_DIR}/kanata_config.kbd" 2>/dev/null; then
                print_color "${COLOR_YELLOW}" "[INFO] Config differs, syncing..."
                cp "${WSL_KANATA_CONFIG}" "${WIN_KANATA_DIR}/kanata_config.kbd"
                print_color "${COLOR_GREEN}" "[OK] Config synced"
            fi

            # Check startup registration
            local status
            status=$(get_startup_status)
            if [[ "${status}" != "registered" ]]; then
                print_color "${COLOR_YELLOW}" "[INFO] Startup not registered, registering..."
                cmd_enable
            fi

            # Check if kanata is running, start if not
            if ! is_kanata_running; then
                print_color "${COLOR_YELLOW}" "[INFO] Kanata not running, starting..."
                cmd_start
            else
                print_color "${COLOR_GREEN}" "[OK] Kanata is running"
            fi

            print_color "${COLOR_GREEN}" "✓ All good!"
            return 0
        else
            print_color "${COLOR_YELLOW}" "[INFO] Installed: ${installed_version} → Updating to: ${latest_version}"
        fi
    fi

    # Create temp directory
    local temp_dir
    temp_dir=$(mktemp -d)

    # Download
    print_color "${COLOR_BLUE}" "Downloading Kanata ${latest_version}..."
    local download_url="https://github.com/jtroo/kanata/releases/download/${latest_version}/kanata-windows-binaries-x64-${latest_version}.zip"

    if ! curl -L -o "${temp_dir}/kanata.zip" "${download_url}"; then
        print_color "${COLOR_RED}" "ERROR: Failed to download"
        rm -rf "${temp_dir}"
        exit 1
    fi
    print_color "${COLOR_GREEN}" "[OK] Downloaded"

    # Extract
    print_color "${COLOR_BLUE}" "Extracting ${BINARY_VARIANT}..."
    if ! unzip -o "${temp_dir}/kanata.zip" "${BINARY_VARIANT}" -d "${temp_dir}"; then
        print_color "${COLOR_RED}" "ERROR: Failed to extract"
        rm -rf "${temp_dir}"
        exit 1
    fi
    print_color "${COLOR_GREEN}" "[OK] Extracted"

    # Convert paths to Windows format
    local WIN_TEMP_BINARY WIN_CONFIG
    WIN_TEMP_BINARY=$(wslpath -w "${temp_dir}/${BINARY_VARIANT}")
    WIN_CONFIG=$(wslpath -w "${WSL_KANATA_CONFIG}")

    # Create PowerShell script
    local ps_script="${temp_dir}/install_kanata.ps1"
    cat > "${ps_script}" << PSEOF
param(
    [string]\$TempBinary,
    [string]\$ConfigPath,
    [string]\$Version
)

\$ErrorActionPreference = "Stop"

try {
    # Kill kanata if running
    Write-Host "Stopping Kanata if running..." -ForegroundColor Yellow
    Get-Process kanata -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500

    # Create directory if needed
    if (-not (Test-Path "C:\Windows\Kanata")) {
        New-Item -ItemType Directory -Path "C:\Windows\Kanata" -Force | Out-Null
        Write-Host "[OK] Created C:\Windows\Kanata" -ForegroundColor Green
    }

    # Copy files
    Copy-Item \$TempBinary "C:\Windows\Kanata\kanata.exe" -Force
    Write-Host "[OK] Copied kanata.exe" -ForegroundColor Green

    Copy-Item \$ConfigPath "C:\Windows\Kanata\kanata_config.kbd" -Force
    Write-Host "[OK] Copied kanata_config.kbd" -ForegroundColor Green

    # Save version
    \$Version | Out-File -FilePath "C:\Windows\Kanata\version.txt" -Encoding ASCII -NoNewline -Force
    Write-Host "[OK] Saved version.txt" -ForegroundColor Green

    # Register startup
    \$StartupPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    \$StartupCommand = "${STARTUP_COMMAND}"

    \$existing = Get-ItemProperty -Path \$StartupPath -Name "Kanata" -ErrorAction SilentlyContinue
    if (\$existing -and \$existing.Kanata -eq \$StartupCommand) {
        Write-Host "[OK] Startup already registered" -ForegroundColor Green
    } else {
        Set-ItemProperty -LiteralPath \$StartupPath -Name "Kanata" -Value \$StartupCommand
        Write-Host "[OK] Registered Kanata for startup" -ForegroundColor Green
    }

    # Start Kanata headless
    Write-Host ""
    Write-Host "Starting Kanata..." -ForegroundColor Yellow
    Start-Process -FilePath "C:\Windows\system32\conhost.exe" -ArgumentList "--headless", "C:\Windows\Kanata\kanata.exe", "--cfg", "C:\Windows\Kanata\kanata_config.kbd" -WindowStyle Hidden
    Write-Host "[OK] Kanata started headless" -ForegroundColor Green

    Write-Host ""
    Write-Host "Setup complete!" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: \$_" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to close"
PSEOF

    local WIN_PS_SCRIPT
    WIN_PS_SCRIPT=$(wslpath -w "${ps_script}")

    print_color "${COLOR_BLUE}" "Installing (UAC prompt will appear)..."

    "${PWSH_EXE}" -NoProfile -Command "Start-Process pwsh.exe -Verb RunAs -Wait -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', '${WIN_PS_SCRIPT}', '-TempBinary', '${WIN_TEMP_BINARY}', '-ConfigPath', '${WIN_CONFIG}', '-Version', '${latest_version}'"

    rm -rf "${temp_dir}"
    print_color "${COLOR_GREEN}" "✓ Setup complete"
}

show_help() {
    echo "Kanata Setup Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install   Download and install latest Kanata (default)"
    echo "  update    Same as install"
    echo "  start     Start Kanata headless"
    echo "  stop      Stop Kanata process"
    echo "  enable    Register Kanata to start on login"
    echo "  disable   Remove startup registration (keeps files)"
    echo "  status    Check installation and startup status"
    echo "  uninstall Remove everything (files + startup)"
    echo "  help      Show this help"
}

# Main
command="${1:-install}"

case "${command}" in
    install|update)
        cmd_install
        ;;
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    enable)
        cmd_enable
        ;;
    disable)
        cmd_disable
        ;;
    status)
        cmd_status
        ;;
    uninstall)
        cmd_uninstall
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_color "${COLOR_RED}" "Unknown command: ${command}"
        echo ""
        show_help
        exit 1
        ;;
esac
