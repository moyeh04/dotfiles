#!/usr/bin/env bash

################################################################################
# Windows 11 Bing Search Toggle Script
#
# Author: Generated for Windows 11 user

# Description: Disables or re-enables Bing web search in Windows 11 Search
#              Runs from WSL and invokes PowerShell on Windows host
#
# Usage:
#   ./windows11-disable-bing-search.sh disable    # Turn OFF Bing search
#   ./windows11-disable-bing-search.sh enable     # Turn ON Bing search
#   ./windows11-disable-bing-search.sh status     # Check current status
#
# Requirements:
#   - WSL (Windows Subsystem for Linux)
#   - PowerShell on Windows (pwsh.exe accessible from WSL)

#   - Windows 11 (any edition - Home, Pro, Enterprise, etc.)
#
# What it does:

#   - Sets registry keys to disable/enable Bing web results in Windows Search
#   - Restarts Windows Explorer to apply changes immediately

#   - Works around the fact that Windows Settings toggles don't actually work
#
# Registry keys modified:

#   HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer
#     - DisableSearchBoxSuggestions (1=disabled, 0=enabled)

#   HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search

#     - BingSearchEnabled (0=disabled, 1=enabled)
#
################################################################################

set -euo pipefail

# Color codes for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# PowerShell executable path
readonly PWSH_EXE="pwsh.exe"

################################################################################
# Print colored message
# Arguments:
#   $1 - color code
#   $2 - message
################################################################################
print_color() {
    local color="${1}"
    local message="${2}"
    echo -e "${color}${message}${COLOR_RESET}"
}

################################################################################
# Check if PowerShell is accessible from WSL
################################################################################
check_requirements() {
    if ! command -v "${PWSH_EXE}" &>/dev/null; then
        print_color "${COLOR_RED}" "ERROR: pwsh.exe not found in PATH"
        print_color "${COLOR_YELLOW}" "Make sure PowerShell is installed on Windows"
        exit 1
    fi
}

################################################################################
# Disable Bing search in Windows 11
# Sets registry keys and restarts Explorer
################################################################################
disable_bing_search() {
    print_color "${COLOR_BLUE}" "Setting Bing search: OFF"

    "${PWSH_EXE}" -Command "Start-Process pwsh.exe -Verb RunAs -ArgumentList '-NoProfile -Command', {
        # Create Explorer policy key if it doesn't exist
        if (!(Test-Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer')) {
            New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force | Out-Null
            Write-Host '[OK] Created Explorer registry key' -ForegroundColor Green
        }

        # Set search box suggestions to disabled
        New-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1 -PropertyType DWORD -Force | Out-Null
        Write-Host '[OK] Set DisableSearchBoxSuggestions = 1' -ForegroundColor Green

        # Set Bing search to disabled
        New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -PropertyType DWORD -Force | Out-Null
        Write-Host '[OK] Set BingSearchEnabled = 0' -ForegroundColor Green

        # Restart Windows Explorer
        Write-Host '[INFO] Restarting Windows Explorer...' -ForegroundColor Yellow
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Write-Host '[DONE] Bing search is now OFF' -ForegroundColor Cyan
        
        Read-Host 'Press Enter to close'
    } -Wait"

    print_color "${COLOR_GREEN}" "✓ Applied successfully"
}

################################################################################

# Enable Bing search in Windows 11
# Reverts registry keys and restarts Explorer
################################################################################
enable_bing_search() {
    print_color "${COLOR_BLUE}" "Setting Bing search: ON"

    "${PWSH_EXE}" -Command "Start-Process pwsh.exe -Verb RunAs -ArgumentList '-NoProfile -Command', {
        # Set search box suggestions to enabled
        New-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 0 -PropertyType DWORD -Force | Out-Null
        Write-Host '[OK] Set DisableSearchBoxSuggestions = 0' -ForegroundColor Green

        # Set Bing search to enabled
        New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 1 -PropertyType DWORD -Force | Out-Null
        Write-Host '[OK] Set BingSearchEnabled = 1' -ForegroundColor Green


        # Restart Windows Explorer
        Write-Host '[INFO] Restarting Windows Explorer...' -ForegroundColor Yellow
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Write-Host '[DONE] Bing search is now ON' -ForegroundColor Cyan
        
        Read-Host 'Press Enter to close'
    } -Wait"

    print_color "${COLOR_GREEN}" "✓ Applied successfully"
}

################################################################################
# Check current status of Bing search settings
################################################################################
check_status() {
    print_color "${COLOR_BLUE}" "Checking current Bing search status..."

    "${PWSH_EXE}" -Command "
        Write-Host ''
        Write-Host '=== Current Registry Settings ===' -ForegroundColor Cyan

        Write-Host ''
        
        # Check DisableSearchBoxSuggestions
        try {
            \$searchBoxDisabled = Get-ItemPropertyValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -ErrorAction Stop
            if (\$searchBoxDisabled -eq 1) {
                Write-Host '[✓] DisableSearchBoxSuggestions: DISABLED (Value: 1)' -ForegroundColor Green
            } else {
                Write-Host '[✗] DisableSearchBoxSuggestions: ENABLED (Value: 0)' -ForegroundColor Red
            }
        } catch {
            Write-Host '[?] DisableSearchBoxSuggestions: NOT SET (using Windows default)' -ForegroundColor Yellow
        }
        
        # Check BingSearchEnabled
        try {
            \$bingEnabled = Get-ItemPropertyValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -ErrorAction Stop
            if (\$bingEnabled -eq 0) {

                Write-Host '[✓] BingSearchEnabled: DISABLED (Value: 0)' -ForegroundColor Green
            } else {
                Write-Host '[✗] BingSearchEnabled: ENABLED (Value: 1)' -ForegroundColor Red
            }
        } catch {

            Write-Host '[?] BingSearchEnabled: NOT SET (using Windows default)' -ForegroundColor Yellow
        }
        
        Write-Host ''
    "

}

################################################################################
# Display usage information
################################################################################
show_usage() {
    echo ""
    print_color "${COLOR_BLUE}" "Windows 11 Bing Search Toggle"
    echo ""
    echo "Usage: ${0} <command>"
    echo ""
    echo "Commands:"
    echo "    disable     Disable Bing web search in Windows 11 Search"
    echo "    enable      Re-enable Bing web search (undo disable)"
    echo "    status      Check current status of Bing search settings"
    echo "    help        Show this help message"
    echo ""
    echo "Examples:"
    echo "    ${0} disable    # Turn off web search"
    echo "    ${0} enable     # Turn back on web search"
    echo "    ${0} status     # See what's currently set"
    echo ""
}

################################################################################
# Main function - entry point
################################################################################
main() {
    local command="${1:-}"

    # Check requirements first
    check_requirements

    case "${command}" in
    disable)
        disable_bing_search
        ;;
    enable)
        enable_bing_search
        ;;
    status)

        check_status
        ;;
    help | --help | -h)
        show_usage
        ;;
    "")
        print_color "${COLOR_RED}" "ERROR: No command specified"
        show_usage
        exit 1
        ;;
    *)
        print_color "${COLOR_RED}" "ERROR: Unknown command '${command}'"
        show_usage
        exit 1
        ;;
    esac
}

# Run main function with all arguments
main "$@"
