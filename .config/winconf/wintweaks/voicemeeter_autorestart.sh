#!/usr/bin/env bash

################################################################################
# Voicemeeter Auto-Restart Script
#
# Description: Sets up automatic Voicemeeter audio engine restart when audio
#              devices reconnect (e.g., Bluetooth headphones)
#
# Problem: When Bluetooth devices disconnect/reconnect, Voicemeeter doesn't
#          detect the reconnection and keeps flashing red. Manual restart of
#          the audio engine fixes it, but this automates it.
#
# Solution: Uses Windows Task Scheduler to monitor audio device events and
#           automatically restart Voicemeeter's audio engine when devices
#           reconnect (Event ID 65 in Microsoft-Windows-Audio/Operational log)
#
# Usage:
#   ./voicemeeter_autorestart.sh enable     # Set up auto-restart
#   ./voicemeeter_autorestart.sh disable    # Remove auto-restart
#   ./voicemeeter_autorestart.sh status     # Check if enabled
#
# Requirements:
#   - Voicemeeter/Voicemeeter Banana/Voicemeeter Potato installed
#   - Admin privileges (UAC prompt will appear)
#
################################################################################

set -euo pipefail

readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

readonly PWSH_EXE="pwsh.exe"
readonly TASK_NAME="Voicemeeter Auto Restart"

# Voicemeeter executable paths (script will detect which one is installed)
readonly VM_PATHS=(
    "C:\\Program Files (x86)\\VB\\Voicemeeter\\voicemeeter.exe"
    "C:\\Program Files (x86)\\VB\\Voicemeeter\\voicemeeterpro.exe"
    "C:\\Program Files (x86)\\VB\\Voicemeeter\\voicemeeter8.exe"
    "C:\\Program Files (x86)\\VB\\Voicemeeter\\voicemeeter8x64.exe"
)

print_color() {
    local color="${1}"
    local message="${2}"

    echo -e "${color}${message}${COLOR_RESET}"

}

################################################################################
# Detect which Voicemeeter variant is installed
################################################################################
detect_voicemeeter() {
    for vm_path in "${VM_PATHS[@]}"; do
        # Convert Windows path to WSL path for checking
        local wsl_path=$(echo "$vm_path" | sed 's|C:\\|/mnt/c/|g' | sed 's|\\|/|g')
        if [[ -f "$wsl_path" ]]; then

            echo "$vm_path"
            return 0
        fi
    done
    return 1
}

################################################################################
# Enable auto-restart via Task Scheduler
################################################################################
enable_autorestart() {
    print_color "${COLOR_BLUE}" "Setting up Voicemeeter auto-restart..."

    "${PWSH_EXE}" -Command "Start-Process pwsh.exe -Verb RunAs -ArgumentList '-NoProfile -Command', {
        \$taskName = 'Voicemeeter Auto Restart'
        
        # Detect which Voicemeeter is RUNNING (best method)
        Write-Host '[INFO] Detecting running Voicemeeter process...' -ForegroundColor Yellow
        \$vmProcess = Get-Process -Name 'voicemeeter*' -ErrorAction SilentlyContinue | Where-Object { 
            \$_.ProcessName -eq 'voicemeeter' -or 
            \$_.ProcessName -eq 'voicemeeterpro' -or 
            \$_.ProcessName -eq 'voicemeeter8' -or
            \$_.ProcessName -eq 'voicemeeter8x64'
        } | Select-Object -First 1
        
        \$vmPath = \$null
        if (\$vmProcess) {
            \$vmPath = \$vmProcess.Path
            Write-Host '[INFO] Path:' \$vmPath -ForegroundColor Cyan
        } else {
            Write-Host '[WARNING] Voicemeeter not running, checking installed files...' -ForegroundColor Yellow

            # Fallback: check which files exist (prefer Pro/Potato over basic)
            \$vmPaths = @(
                'C:\Program Files (x86)\VB\Voicemeeter\voicemeeter8x64.exe',
                'C:\Program Files (x86)\VB\Voicemeeter\voicemeeter8.exe',
                'C:\Program Files (x86)\VB\Voicemeeter\voicemeeterpro.exe',
                'C:\Program Files (x86)\VB\Voicemeeter\voicemeeter.exe'
            )
            
            foreach (\$path in \$vmPaths) {
                if (Test-Path \$path) {
                    \$vmPath = \$path
                    break
                }
            }
        }
        
        if (-not \$vmPath) {

            Write-Host '[ERROR] Voicemeeter not found' -ForegroundColor Red
            Write-Host '[INFO] Install from: https://vb-audio.com/Voicemeeter/' -ForegroundColor Yellow
            Read-Host 'Press Enter to close'
            exit 1
        }
        
        Write-Host '[INFO] Task name:' \$taskName -ForegroundColor Yellow
        Write-Host '[INFO] Voicemeeter path:' \$vmPath -ForegroundColor Yellow
        Write-Host ''
        
        # Check if task already exists
        \$existingTask = Get-ScheduledTask -TaskName \$taskName -ErrorAction SilentlyContinue
        if (\$existingTask) {
            Write-Host '[INFO] Task already exists, removing old one...' -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName \$taskName -Confirm:\$false
        }
        
        # Create the trigger (event-based)
        \$trigger = New-ScheduledTaskTrigger -AtLogOn -RandomDelay (New-TimeSpan -Seconds 0)
        
        # Override trigger with CIM instance for event-based trigger
        # Only trigger on NewState=1 (device became Active/connected)
        # NewState values: 1=Active, 4=NotPresent, 8=Unplugged
        \$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
        \$trigger = New-CimInstance -CimClass \$CIMTriggerClass -ClientOnly
        \$xmlQuery = '<QueryList><Query><Select Path=' + [char]34 + 'Microsoft-Windows-Audio/Operational' + [char]34 + '>*[System[Provider[@Name=' + [char]34 + 'Microsoft-Windows-Audio' + [char]34 + '] and EventID=65] and EventData[Data[@Name=' + [char]34 + 'NewState' + [char]34 + ']=' + [char]34 + '1' + [char]34 + ']]</Select></Query></QueryList>'
        \$trigger.Subscription = \$xmlQuery
        \$trigger.Enabled = \$true
        
        # Create the action (restart Voicemeeter)
        \$action = New-ScheduledTaskAction -Execute \$vmPath -Argument '-R'
        
        # Register the task
        try {
            Register-ScheduledTask -TaskName \$taskName -Trigger \$trigger -Action \$action -Force | Out-Null
            Write-Host '[OK] Task created successfully' -ForegroundColor Green
            Write-Host '[INFO] Voicemeeter will auto-restart when audio devices reconnect' -ForegroundColor Cyan
        } catch {
            Write-Host '[ERROR] Failed to create task:' \$_.Exception.Message -ForegroundColor Red
        }
        
        Write-Host ''
        Read-Host 'Press Enter to close'
    } -Wait"

    print_color "${COLOR_GREEN}" "✓ Auto-restart enabled"
}

################################################################################
# Disable auto-restart (remove Task Scheduler task)
################################################################################

disable_autorestart() {
    print_color "${COLOR_BLUE}" "Removing Voicemeeter auto-restart..."

    "${PWSH_EXE}" -Command "Start-Process pwsh.exe -Verb RunAs -ArgumentList '-NoProfile -Command', {
        \$taskName = '${TASK_NAME}'
        
        \$existingTask = Get-ScheduledTask -TaskName \$taskName -ErrorAction SilentlyContinue
        if (\$existingTask) {
            Unregister-ScheduledTask -TaskName \$taskName -Confirm:\$false
            Write-Host '[OK] Removed task' -ForegroundColor Green
        } else {
            Write-Host '[INFO] Task does not exist (already disabled)' -ForegroundColor Yellow
        }
        
        Write-Host ''
        Read-Host 'Press Enter to close'
    } -Wait"

    print_color "${COLOR_GREEN}" "✓ Auto-restart disabled"
}

################################################################################
# Check status of auto-restart task
################################################################################

check_status() {
    print_color "${COLOR_BLUE}" "Checking Voicemeeter auto-restart status..."

    "${PWSH_EXE}" -Command "
        Write-Host ''
        Write-Host '=== Voicemeeter Auto-Restart Status ===' -ForegroundColor Cyan

        Write-Host ''
        
        \$taskName = '${TASK_NAME}'
        \$task = Get-ScheduledTask -TaskName \$taskName -ErrorAction SilentlyContinue
        
        if (\$task) {
            Write-Host '[✓] Auto-restart: ENABLED' -ForegroundColor Green
            Write-Host ''
            Write-Host 'Task Details:' -ForegroundColor Yellow
            Write-Host '  Name:' \$task.TaskName
            Write-Host '  State:' \$task.State
            
            \$trigger = \$task.Triggers[0]
            if (\$trigger) {
                Write-Host '  Trigger: Event-based (Audio device state changes)'

                Write-Host '  Event Channel:' \$trigger.Subscription
            }
            
            \$action = \$task.Actions[0]
            if (\$action) {
                Write-Host '  Action:' \$action.Execute \$action.Arguments
            }
        } else {
            Write-Host '[✗] Auto-restart: DISABLED (task not found)' -ForegroundColor Red
        }
        
        Write-Host ''
    "
}

################################################################################
# Display usage information
################################################################################
show_usage() {
    echo ""
    print_color "${COLOR_BLUE}" "Voicemeeter Auto-Restart"
    echo ""
    echo "Automatically restarts Voicemeeter audio engine when devices reconnect"
    echo ""
    echo "Usage: ${0} <command>"
    echo ""

    echo "Commands:"
    echo "    enable      Set up auto-restart (creates Task Scheduler task)"
    echo "    disable     Remove auto-restart (deletes task)"
    echo "    status      Check if auto-restart is enabled"

    echo "    help        Show this help message"
    echo ""

    echo "How it works:"
    echo "    - Monitors Windows Audio events (EventID 65 = device state change)"
    echo "    - When Bluetooth/USB audio device reconnects, automatically runs:"
    echo "      voicemeeter.exe -R (restarts audio engine)"
    echo "    - Zero CPU usage when idle (event-driven, not polling)"
    echo "    - Task runs in background, starts with Windows"
    echo ""
    echo "Why this is needed:"
    echo "    - Voicemeeter doesn't detect device reconnections automatically"
    echo "    - Results in red flashing and no audio until manual restart (Alt+F12)"
    echo "    - This automates the restart process"
    echo ""
}

################################################################################
# Main function
################################################################################
main() {
    local command="${1:-}"

    case "${command}" in
    enable)
        enable_autorestart
        ;;
    disable)
        disable_autorestart
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

main "$@"
