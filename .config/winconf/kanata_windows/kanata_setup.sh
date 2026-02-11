#!/usr/bin/env bash

################################################################################
# Kanata Setup Script — Modular Configuration System
#
# Usage:
#   ./kanata_setup.sh [command] [options]
#
# Commands:
#   install [--mod1] [--mod2]   Select modules, merge, and deploy (default)
#   update                      Rebuild from last selection + check binary
#   start                       Start Kanata headless
#   stop                        Stop Kanata process
#   enable                      Register Kanata to start on login
#   disable                     Remove startup registration (keeps files)
#   status                      Check installation, modules, and startup
#   uninstall                   Remove everything (files + startup)
#
# Modules:
#   .kbd files in ~/.config/kanata/ with @module markers.
#   Each module declares its keys, aliases, and layers.
#   The script merges selected modules into one kanata_config.kbd.
#
# Examples:
#   ./kanata_setup.sh install                # Interactive module picker
#   ./kanata_setup.sh install --remaps       # Just key remaps
#   ./kanata_setup.sh install --german       # Just German characters
#   ./kanata_setup.sh install --remaps --german  # Both modules
#   ./kanata_setup.sh update                 # Rebuild with same modules
#
################################################################################

set -euo pipefail

readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_RESET='\033[0m'

readonly PWSH_EXE="pwsh.exe"
readonly KANATA_MODULES_DIR="${HOME}/.config/kanata"
readonly WIN_KANATA_DIR="/mnt/c/Windows/Kanata"
readonly ACTIVE_MODULES_FILE="${WIN_KANATA_DIR}/active_modules.txt"
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

# ═══════════════════════════════════════════════════════════════════════════════
# MODULE SYSTEM — Discovery, validation, merging
# ═══════════════════════════════════════════════════════════════════════════════

# Find all .kbd files with @module markers
discover_modules() {
    local modules=()
    for file in "${KANATA_MODULES_DIR}"/kanata_*.kbd; do
        [[ ! -f "$file" ]] && continue
        if head -5 "$file" | grep -q '^;; @module'; then
            modules+=("$file")
        fi
    done
    if [[ ${#modules[@]} -eq 0 ]]; then
        print_color "${COLOR_RED}" "ERROR: No module .kbd files found in ${KANATA_MODULES_DIR}"
        print_color "${COLOR_YELLOW}" "Module files must have ';; @module <name>' in the first 5 lines"

        exit 1
    fi
    printf '%s\n' "${modules[@]}"
}

# Validate a module file has required markers
validate_module() {
    local file="$1"
    local name
    name=$(grep '^;; @module' "$file" | head -1 | sed 's/;; @module //')

    local keys base
    keys=$(grep '^;; @keys' "$file" | head -1 | sed 's/;; @keys //')

    base=$(grep '^;; @base' "$file" | head -1 | sed 's/;; @base //')

    if [[ -z "$name" ]]; then
        print_color "${COLOR_RED}" "ERROR: ${file}: missing @module marker"
        return 1
    fi
    if [[ -z "$keys" ]]; then
        print_color "${COLOR_RED}" "ERROR: Module '${name}': missing @keys marker"
        return 1
    fi

    local key_count base_count
    key_count=$(echo "$keys" | wc -w)
    base_count=$(echo "$base" | wc -w)

    if [[ $key_count -ne $base_count ]]; then
        print_color "${COLOR_RED}" "ERROR: Module '${name}': @keys has ${key_count} entries but @base has ${base_count}"
        return 1
    fi

    if ! grep -q '^;; @aliases-start' "$file"; then
        print_color "${COLOR_RED}" "ERROR: Module '${name}': missing @aliases-start marker"
        return 1
    fi
    if ! grep -q '^;; @aliases-end' "$file"; then
        print_color "${COLOR_RED}" "ERROR: Module '${name}': missing @aliases-end marker"
        return 1
    fi
    if ! grep -q '^;; @layers-start' "$file"; then
        print_color "${COLOR_RED}" "ERROR: Module '${name}': missing @layers-start marker"
        return 1
    fi
    if ! grep -q '^;; @layers-end' "$file"; then
        print_color "${COLOR_RED}" "ERROR: Module '${name}': missing @layers-end marker"
        return 1
    fi

    return 0
}

# Get module metadata
get_module_name() { grep '^;; @module' "$1" | head -1 | sed 's/;; @module //'; }
get_module_desc() { grep '^;; @description' "$1" | head -1 | sed 's/;; @description //'; }
get_module_keys() { grep '^;; @keys' "$1" | head -1 | sed 's/;; @keys //'; }
get_module_base() { grep '^;; @base' "$1" | head -1 | sed 's/;; @base //'; }

# Resolve module args (--remaps --german) to file paths
parse_module_args() {
    local -a mod_files
    IFS=$'\n' read -r -d '' -a mod_files <<<"$(discover_modules)" || true
    local -a result=()

    for arg in "$@"; do
        local mod_name="${arg#--}"
        local found=0

        for mod_file in "${mod_files[@]}"; do
            local name
            name=$(get_module_name "$mod_file")
            if [[ "$name" == "$mod_name" ]]; then
                result+=("$mod_file")
                found=1
                break
            fi
        done

        if [[ $found -eq 0 ]]; then
            print_color "${COLOR_RED}" "ERROR: Unknown module: ${mod_name}"
            echo ""
            echo "Available modules:"
            for mod_file in "${mod_files[@]}"; do
                local name desc
                name=$(get_module_name "$mod_file")
                desc=$(get_module_desc "$mod_file")
                echo "  --${name}    ${desc}"
            done
            exit 1
        fi
    done

    printf '%s\n' "${result[@]}"
}

# ── Interactive module picker (TUI) ─────────────────────────────────────────

show_module_picker() {
    local -a mod_files=("$@")
    local count=${#mod_files[@]}
    local cursor=0
    local -a selected
    local -a mod_names
    local -a mod_descs

    # Read metadata
    for ((i = 0; i < count; i++)); do
        mod_names[i]=$(get_module_name "${mod_files[i]}")
        mod_descs[i]=$(get_module_desc "${mod_files[i]}")
        selected[i]=0
    done

    # Pre-select from saved selection if available
    if [[ -f "${ACTIVE_MODULES_FILE}" ]]; then
        while IFS= read -r saved_mod; do
            for ((i = 0; i < count; i++)); do
                if [[ "${mod_names[i]}" == "$saved_mod" ]]; then
                    selected[i]=1
                fi
            done
        done <"${ACTIVE_MODULES_FILE}"
    fi

    # Hide cursor, save terminal state
    printf '\e[?25l' >/dev/tty
    local cleanup_done=0
    cleanup_picker() {
        if [[ $cleanup_done -eq 0 ]]; then
            cleanup_done=1
            printf '\e[?25h' >/dev/tty
        fi
    }
    trap cleanup_picker EXIT INT TERM

    # Find longest module name for alignment
    local max_name_len=0
    for ((i = 0; i < count; i++)); do
        [[ ${#mod_names[$i]} -gt $max_name_len ]] && max_name_len=${#mod_names[$i]}
    done

    while true; do
        # Clear screen and draw menu — all UI goes to /dev/tty
        {
            printf '\e[H\e[2J'
            echo ""
            print_color "${COLOR_BLUE}" "  ╭──────────────────────────────────────────╮"
            print_color "${COLOR_BLUE}" "  │       Kanata Module Installer            │"
            print_color "${COLOR_BLUE}" "  ╰──────────────────────────────────────────╯"
            echo ""
            echo "  Select modules to install:"
            echo ""

            for ((i = 0; i < count; i++)); do
                local marker="[ ]"
                [[ ${selected[$i]} -eq 1 ]] && marker="[x]"

                local prefix="    "
                [[ $i -eq $cursor ]] && prefix="  > "

                local name="${mod_names[$i]}"
                local desc="${mod_descs[$i]}"
                local padding=$((max_name_len - ${#name} + 3))

                if [[ $i -eq $cursor ]]; then
                    printf "  %b%s%s %b%s%b" "${COLOR_CYAN}" "${prefix}" "${marker}" "${COLOR_BOLD}" "${name}" "${COLOR_RESET}"
                    printf "%b%*s%s%b\n" "${COLOR_DIM}" "$padding" "" "${desc}" "${COLOR_RESET}"
                else
                    printf "  %s%s %s" "${prefix}" "${marker}" "${name}"
                    printf "%b%*s%s%b\n" "${COLOR_DIM}" "$padding" "" "${desc}" "${COLOR_RESET}"

                fi
            done

            echo ""
            print_color "${COLOR_DIM}" "  ↑/↓ Navigate   Space Toggle   Enter Confirm   q Quit"
        } >/dev/tty

        # Read keypress from terminal directly
        IFS= read -rsn1 key </dev/tty
        if [[ "$key" == $'\e' ]]; then
            IFS= read -rsn2 -t 0.1 rest </dev/tty 2>/dev/null || rest=""
            key="${key}${rest}"
        fi

        case "$key" in
        $'\e[A') ((cursor > 0)) && ((cursor--)) || true ;;
        $'\e[B') ((cursor < count - 1)) && ((cursor++)) || true ;;
        ' ') selected[cursor]=$((1 - selected[cursor])) ;;
        '')
            # Enter — confirm selection
            cleanup_picker
            trap - EXIT INT TERM

            # Collect selected modules
            local -a result=()
            for ((i = 0; i < count; i++)); do
                [[ ${selected[$i]} -eq 1 ]] && result+=("${mod_files[$i]}")
            done

            if [[ ${#result[@]} -eq 0 ]]; then
                printf '\e[H\e[2J' >/dev/tty
                print_color "${COLOR_RED}" "  No modules selected!" >/dev/tty
                exit 1
            fi

            printf '\e[H\e[2J' >/dev/tty

            # Only this goes to stdout (captured by command substitution)
            printf '%s\n' "${result[@]}"
            return 0
            ;;
        q | Q)
            cleanup_picker
            trap - EXIT INT TERM
            printf '\e[H\e[2J' >/dev/tty
            print_color "${COLOR_YELLOW}" "  Cancelled." >/dev/tty
            exit 1
            ;;
        esac
    done
}

# ── Config merging ───────────────────────────────────────────────────────────

# Expand a module's layer entries to the full combined defsrc width

expand_layer_entries() {
    local mod_keys_str="$1"
    local entries_str="$2"
    local all_keys_str="$3"

    local -a mod_keys entries all_keys
    IFS=' ' read -r -a mod_keys <<<"$mod_keys_str"
    IFS=' ' read -r -a entries <<<"$entries_str"
    IFS=' ' read -r -a all_keys <<<"$all_keys_str"
    local -a result=()

    for key in "${all_keys[@]}"; do
        local found=0
        for i in "${!mod_keys[@]}"; do
            if [[ "${mod_keys[$i]}" == "$key" ]]; then
                result+=("${entries[$i]}")
                found=1
                break
            fi
        done
        [[ $found -eq 0 ]] && result+=("_")
    done

    echo "${result[*]}"
}

# Merge selected modules into a single kanata_config.kbd
generate_merged_config() {
    local output_file="$1"
    shift
    local -a selected_modules=("$@")

    # Validate all modules first
    for mod_file in "${selected_modules[@]}"; do
        validate_module "$mod_file" || exit 1
    done

    # Collect all keys + track ownership (for comments & conflict detection)
    local -a all_keys=()
    local -a key_owners=()
    local -a mod_names_list=()

    for mod_file in "${selected_modules[@]}"; do
        local mod_name mod_keys_str
        mod_name=$(get_module_name "$mod_file")
        mod_keys_str=$(get_module_keys "$mod_file")
        mod_names_list+=("$mod_name")

        for key in $mod_keys_str; do
            # Check for key conflicts between modules
            for j in "${!all_keys[@]}"; do
                if [[ "${all_keys[$j]}" == "$key" ]]; then
                    print_color "${COLOR_RED}" "ERROR: Key '${key}' is claimed by both '${key_owners[$j]}' and '${mod_name}'"
                    exit 1
                fi
            done
            all_keys+=("$key")
            key_owners+=("$mod_name")
        done
    done

    local all_keys_str="${all_keys[*]}"
    local module_list
    module_list=$(
        IFS=', '
        echo "${mod_names_list[*]}"
    )

    # ── Write merged config ──────────────────────────────

    : >"$output_file"

    cat >>"$output_file" <<EOF
;; Kanata Config — Auto-generated by kanata_setup.sh
;; Modules: ${module_list}

;; Generated: $(date -Iseconds)
;; DO NOT EDIT — regenerate with: kanata_setup.sh install

(defcfg
  danger-enable-cmd yes

  process-unmapped-keys yes
  windows-altgr cancel-lctl-press

)

(defvirtualkeys
  caps-on XX
)

(defsrc
  ${all_keys_str}
)

EOF

    # ── defalias ──
    echo "(defalias" >>"$output_file"
    for mod_file in "${selected_modules[@]}"; do
        local mod_name
        mod_name=$(get_module_name "$mod_file")
        echo "  ;; ── ${mod_name} ──" >>"$output_file"
        sed -n '/^;; @aliases-start$/,/^;; @aliases-end$/p' "$mod_file" |
            grep -v '@aliases' \
                >>"$output_file"

    done
    echo ")" >>"$output_file"
    echo "" >>"$output_file"

    # ── deflayer base ──
    local -a base_entries=()
    for i in "${!all_keys[@]}"; do
        base_entries[i]="_"
    done

    for mod_file in "${selected_modules[@]}"; do
        local mod_keys_str mod_base_str
        mod_keys_str=$(get_module_keys "$mod_file")
        mod_base_str=$(get_module_base "$mod_file")
        local -a mk mb
        IFS=' ' read -r -a mk <<<"$mod_keys_str"
        IFS=' ' read -r -a mb <<<"$mod_base_str"

        for i in "${!mk[@]}"; do
            for j in "${!all_keys[@]}"; do

                if [[ "${all_keys[j]}" == "${mk[i]}" ]]; then
                    base_entries[j]="${mb[i]}"
                    break
                fi
            done

        done
    done

    # Find max entry length for alignment
    local max_entry_len=0

    for entry in "${base_entries[@]}"; do
        [[ ${#entry} -gt $max_entry_len ]] && max_entry_len=${#entry}
    done
    ((max_entry_len += 2))

    echo "(deflayer base" >>"$output_file"
    for i in "${!all_keys[@]}"; do
        local entry="${base_entries[$i]}"
        local padding=$((max_entry_len - ${#entry}))
        printf '  %s%*s;; %s (%s)\n' "$entry" "$padding" "" "${all_keys[$i]}" "${key_owners[$i]}" >>"$output_file"
    done
    echo ")" >>"$output_file"

    # ── Extra layers (from each module) ──
    for mod_file in "${selected_modules[@]}"; do
        local mod_keys_str
        mod_keys_str=$(get_module_keys "$mod_file")

        local in_layers=0 in_deflayer=0
        local layer_name="" layer_entries=""

        while IFS= read -r line; do
            if [[ "$line" =~ @layers-start ]]; then
                in_layers=1
                continue
            fi
            if [[ "$line" =~ @layers-end ]]; then
                in_layers=0
                continue

            fi

            [[ $in_layers -eq 0 ]] && continue

            # Strip comments, trim
            local clean="${line%%;;*}"
            clean=$(echo "$clean" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -z "$clean" ]] && continue

            if [[ "$clean" =~ ^\(deflayer ]]; then
                layer_name=$(echo "$clean" | awk '{print $2}')
                layer_entries=""
                in_deflayer=1
                continue
            fi

            if [[ $in_deflayer -eq 1 ]]; then
                if [[ "$clean" == ")" ]]; then
                    # Expand entries to full width and write
                    local expanded
                    expanded=$(expand_layer_entries "$mod_keys_str" "$layer_entries" "$all_keys_str")

                    echo "" >>"$output_file"
                    echo "(deflayer ${layer_name}" >>"$output_file"
                    local -a exp_arr
                    IFS=' ' read -r -a exp_arr <<<"$expanded"
                    for i in "${!exp_arr[@]}"; do
                        local e="${exp_arr[$i]}"
                        local pad=$((max_entry_len - ${#e}))
                        printf '  %s%*s;; %s\n' "$e" "$pad" "" "${all_keys[$i]}" >>"$output_file"
                    done
                    echo ")" >>"$output_file"

                    in_deflayer=0
                    layer_name=""
                    layer_entries=""
                else
                    layer_entries="${layer_entries} ${clean}"

                fi
            fi
        done <"$mod_file"
    done

    # Validate the generated config

    local defsrc_count=${#all_keys[@]}
    local valid=true
    local check_layer="" check_count=0 in_check=0

    while IFS= read -r line; do
        local clean="${line%%;;*}"
        clean=$(echo "$clean" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$clean" ]] && continue

        if [[ "$clean" =~ ^\(deflayer ]]; then
            check_layer=$(echo "$clean" | awk '{print $2}')
            check_count=0
            in_check=1
            continue
        fi
        if [[ "$clean" == ")" ]] && [[ $in_check -eq 1 ]]; then

            if [[ $check_count -ne $defsrc_count ]]; then
                print_color "${COLOR_RED}" "ERROR: deflayer '${check_layer}' has ${check_count} entries but defsrc has ${defsrc_count}"
                valid=false
            fi
            in_check=0
            continue
        fi
        if [[ $in_check -eq 1 ]]; then
            local wc
            wc=$(echo "$clean" | wc -w)
            ((check_count += wc))
        fi
    done <"$output_file"

    if [[ "$valid" != "true" ]]; then
        print_color "${COLOR_RED}" "ERROR: Generated config has layer/defsrc mismatch!"
        exit 1
    fi

    print_color "${COLOR_GREEN}" "[OK] Config generated (${module_list})"
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
        print_color "${COLOR_GREEN}" "  ✓ kanata_config.kbd deployed"
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

    # Active modules
    echo ""
    print_color "${COLOR_CYAN}" "Active Modules:"
    if [[ -f "${ACTIVE_MODULES_FILE}" ]]; then
        while IFS= read -r mod_name; do
            print_color "${COLOR_GREEN}" "  ✓ ${mod_name}"
        done <"${ACTIVE_MODULES_FILE}"
    else
        print_color "${COLOR_YELLOW}" "  ? No module selection saved"
    fi

    # Available modules
    echo ""
    print_color "${COLOR_CYAN}" "Available Modules:"
    local -a mod_files
    IFS=$'\n' read -r -d '' -a mod_files <<<"$(discover_modules 2>/dev/null)" || true
    if [[ ${#mod_files[@]} -gt 0 ]]; then
        for mod_file in "${mod_files[@]}"; do
            [[ -z "$mod_file" ]] && continue
            local name desc
            name=$(get_module_name "$mod_file")
            desc=$(get_module_desc "$mod_file")
            print_color "${COLOR_BLUE}" "  - ${name}   ${desc}"
        done
    else
        print_color "${COLOR_YELLOW}" "  No modules found"
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
    # ── Module selection ─────────────────────────────────
    local -a selected_modules=()
    local -a mod_files
    IFS=$'\n' read -r -d '' -a mod_files <<<"$(discover_modules)" || true

    if [[ ${#INSTALL_ARGS[@]} -gt 0 ]]; then

        # CLI args: --remaps --german etc.
        local -a selected_paths
        IFS=$'\n' read -r -d '' -a selected_paths <<<"$(parse_module_args "${INSTALL_ARGS[@]}")" || true
        selected_modules=("${selected_paths[@]}")

    elif [[ -t 0 ]]; then
        # Interactive: show picker
        local -a picked
        IFS=$'\n' read -r -d '' -a picked <<<"$(show_module_picker "${mod_files[@]}")" || true
        # Check if picker was cancelled (empty output alone isn't enough, check content)
        if [[ ${#picked[@]} -eq 0 && -z "${picked[0]:-}" ]]; then
            # If picker returned nothing, it means user cancelled via 'q' (exit 1)
            # But since it's in a subshell $() we can't see the exit code easily without
            # pipefail or checking emptiness. The picker prints nothing on cancel.
            # So empty result = cancel.
            print_color "${COLOR_YELLOW}" "[INFO] Selection cancelled."
            exit 0
        fi
        selected_modules=("${picked[@]}")

    else
        # Non-interactive, no args: use saved selection or error
        if [[ -f "${ACTIVE_MODULES_FILE}" ]]; then

            print_color "${COLOR_YELLOW}" "[INFO] Using saved module selection"
            local -a saved_paths
            # shellcheck disable=SC2046
            IFS=$'\n' read -r -d '' -a saved_paths <<<"$(parse_module_args $(cat "${ACTIVE_MODULES_FILE}" | sed 's/^/--/'))" || true
            selected_modules=("${saved_paths[@]}")
        else
            print_color "${COLOR_RED}" "ERROR: No modules specified and stdin is not a terminal"
            echo "Use: $0 install --module1 --module2"
            exit 1
        fi
    fi

    # ── Generate merged config ───────────────────────────
    local temp_config temp_active_modules
    temp_config=$(mktemp /tmp/kanata_config.XXXXXX.kbd)
    temp_active_modules=$(mktemp /tmp/kanata_active.XXXXXX)

    # shellcheck disable=SC2064
    trap "rm -f '${temp_config}' '${temp_active_modules}'" EXIT

    # Create active modules list
    : >"$temp_active_modules"
    for mod_file in "${selected_modules[@]}"; do
        get_module_name "$mod_file" >>"$temp_active_modules"
    done

    generate_merged_config "$temp_config" "${selected_modules[@]}"

    # ── Dependencies (only needed for deploy) ────────────
    check_dependencies

    # ── Binary version check ─────────────────────────────
    print_color "${COLOR_BLUE}" "Fetching latest Kanata version..."
    local latest_version
    latest_version=$(curl -s "${GITHUB_API_URL}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "${latest_version}" ]]; then
        print_color "${COLOR_RED}" "ERROR: Failed to get latest version from GitHub"
        exit 1
    fi
    print_color "${COLOR_YELLOW}" "[INFO] Latest version: ${latest_version}"

    # Check if binary is already up to date
    local binary_up_to_date=false
    if [[ -f "${VERSION_FILE}" ]] && [[ -f "${WIN_KANATA_DIR}/kanata.exe" ]]; then
        local installed_version
        installed_version=$(cat "${VERSION_FILE}")
        if [[ "${installed_version}" == "${latest_version}" ]]; then
            binary_up_to_date=true
            print_color "${COLOR_GREEN}" "[OK] Binary already up to date (${latest_version})"
        else
            print_color "${COLOR_YELLOW}" "[INFO] Binary: ${installed_version} → ${latest_version}"
        fi
    fi

    if [[ "$binary_up_to_date" == "true" ]]; then
        # ── Quick path: just deploy config + restart ─────
        # Same pattern as original: stop → cp → start (no elevation)
        print_color "${COLOR_BLUE}" "Deploying config..."

        if is_kanata_running; then
            cmd_stop
        fi

        # Try direct copy first
        if cp "${temp_config}" "${WIN_KANATA_DIR}/kanata_config.kbd" 2>/dev/null &&
            cp "${temp_active_modules}" "${ACTIVE_MODULES_FILE}" 2>/dev/null; then
            print_color "${COLOR_GREEN}" "[OK] Config & module list deployed"

            # Always build UmlautTyper.exe (gets moved after deploy)
            local script_dir="$(dirname "${BASH_SOURCE[0]}")"
            if [[ -f "${script_dir}/build_umlaut.sh" ]]; then
                print_color "${COLOR_YELLOW}" "[INFO] Building UmlautTyper.exe..."
                (cd "${script_dir}" && ./build_umlaut.sh)
            fi

            if [[ -f "${script_dir}/UmlautTyper.exe" ]]; then
                if mv "${script_dir}/UmlautTyper.exe" "${WIN_KANATA_DIR}/UmlautTyper.exe" 2>/dev/null; then
                    print_color "${COLOR_GREEN}" "[OK] UmlautTyper.exe deployed"

                fi
            fi
        else
            print_color "${COLOR_YELLOW}" "[WARN] Direct copy failed, elevating..."
            local WIN_SRC_CFG WIN_SRC_MOD WIN_DEST_MOD
            WIN_SRC_CFG=$(wslpath -w "${temp_config}")
            WIN_SRC_MOD=$(wslpath -w "${temp_active_modules}")
            WIN_DEST_MOD=$(wslpath -w "${ACTIVE_MODULES_FILE}")

            local deploy_script="${temp_active_modules}.ps1"
            cat >"${deploy_script}" <<PSEOF
param(
    [string]\$ConfigSrc,
    [string]\$ModuleSrc,
    [string]\$ModuleDest
)
\$ErrorActionPreference = "Stop"


try {
    Write-Host "Deploying config..." -ForegroundColor Cyan
    Copy-Item -Path \$ConfigSrc -Destination "C:\Windows\Kanata\kanata_config.kbd" -Force

    Write-Host "[OK] Copied kanata_config.kbd" -ForegroundColor Green

    Write-Host "Deploying module list..." -ForegroundColor Cyan
    Get-Content -Path \$ModuleSrc -Encoding UTF8 | Set-Content -Path \$ModuleDest -Encoding UTF8
    Write-Host "[OK] Saved active_modules.txt" -ForegroundColor Green
} catch {
    Write-Host "ERROR: \$_" -ForegroundColor Red

}
    Write-Host ""
    Read-Host "Press Enter to close"
PSEOF

            local WIN_DEPLOY_SCRIPT
            WIN_DEPLOY_SCRIPT=$(wslpath -w "${deploy_script}")

            "${PWSH_EXE}" -NoProfile -Command "Start-Process pwsh.exe -Verb RunAs -Wait -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', '${WIN_DEPLOY_SCRIPT}', '-ConfigSrc', '${WIN_SRC_CFG}', '-ModuleSrc', '${WIN_SRC_MOD}', '-ModuleDest', '${WIN_DEST_MOD}'"
            rm -f "${deploy_script}"
            print_color "${COLOR_GREEN}" "[OK] Config & module list deployed (elevated)"
        fi

        cmd_start

        # Ensure startup registered
        local status

        status=$(get_startup_status)
        if [[ "${status}" != "registered" ]]; then
            print_color "${COLOR_YELLOW}" "[INFO] Registering startup..."
            cmd_enable
        fi

        print_color "${COLOR_GREEN}" "✓ All good!"
        return 0
    fi

    # ── Full install path: download binary + deploy everything ──

    local temp_dir
    temp_dir=$(mktemp -d)

    # Auto-detect the actual zip filename from GitHub API
    print_color "${COLOR_BLUE}" "Checking available binaries..."
    local asset_name
    asset_name=$(curl -s "${GITHUB_API_URL}" | grep -o '"name": *"[^"]*windows[^"]*x64[^"]*\.zip"' | head -1 | sed 's/"name": *"\([^"]*\)"/\1/')

    if [[ -z "${asset_name}" ]]; then
        print_color "${COLOR_RED}" "ERROR: Could not find Windows x64 binary in release"
        print_color "${COLOR_YELLOW}" "Check releases manually: https://github.com/jtroo/kanata/releases/tag/${latest_version}"
        rm -rf "${temp_dir}"
        exit 1
    fi

    print_color "${COLOR_BLUE}" "Downloading Kanata ${latest_version} (${asset_name})..."
    local download_url="https://github.com/jtroo/kanata/releases/download/${latest_version}/${asset_name}"

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
    local WIN_TEMP_BINARY WIN_CONFIG WIN_ACTIVE WIN_DEST_ACTIVE
    WIN_TEMP_BINARY=$(wslpath -w "${temp_dir}/${BINARY_VARIANT}")
    WIN_CONFIG=$(wslpath -w "${temp_config}")
    WIN_ACTIVE=$(wslpath -w "${temp_active_modules}")
    WIN_DEST_ACTIVE=$(wslpath -w "${ACTIVE_MODULES_FILE}")

    # Always build UmlautTyper.exe (gets moved after deploy)
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local WIN_UMLAUT=""

    if [[ -f "${script_dir}/build_umlaut.sh" ]]; then
        print_color "${COLOR_YELLOW}" "[INFO] Building UmlautTyper.exe..."
        (cd "${script_dir}" && ./build_umlaut.sh)
    fi

    if [[ -f "${script_dir}/UmlautTyper.exe" ]]; then
        WIN_UMLAUT=$(wslpath -w "${script_dir}/UmlautTyper.exe")
    fi

    # Create PowerShell install script
    local ps_script="${temp_dir}/install_kanata.ps1"
    cat >"${ps_script}" <<PSEOF
param(
    [string]\$TempBinary,
    [string]\$ConfigPath,
    [string]\$ActiveModulesPath,
    [string]\$DestActiveModulesPath,
    [string]\$Version,
    [string]\$UmlautPath = ""
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

    Get-Content -Path \$ActiveModulesPath -Encoding UTF8 | Set-Content -Path \$DestActiveModulesPath -Encoding UTF8
    Write-Host "[OK] Saved active_modules.txt" -ForegroundColor Green

    # Deploy UmlautTyper.exe if provided
    if (\$UmlautPath -and (Test-Path \$UmlautPath)) {
        Copy-Item \$UmlautPath "C:\Windows\Kanata\UmlautTyper.exe" -Force
        Write-Host "[OK] Copied UmlautTyper.exe" -ForegroundColor Green
        
        # Delete source after deployment (move operation)
        Remove-Item \$UmlautPath -Force -ErrorAction SilentlyContinue
    }

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

    "${PWSH_EXE}" -NoProfile -Command "Start-Process pwsh.exe -Verb RunAs -Wait -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', '${WIN_PS_SCRIPT}', '-TempBinary', '${WIN_TEMP_BINARY}', '-ConfigPath', '${WIN_CONFIG}', '-ActiveModulesPath', '${WIN_ACTIVE}', '-DestActiveModulesPath', '${WIN_DEST_ACTIVE}', '-Version', '${latest_version}', '-UmlautPath', '${WIN_UMLAUT}'"

    rm -rf "${temp_dir}"
    print_color "${COLOR_GREEN}" "✓ Setup complete"
}

# ═══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE MAIN MENU
# ═══════════════════════════════════════════════════════════════════════════════

show_main_menu() {
    local -a menu_items=(
        "install    Select modules and deploy Kanata"
        "update     Rebuild config from last selection + update binary"
        "status     Show installation, modules, and process status"
        "start      Start Kanata headless"
        "stop       Stop Kanata process"
        "enable     Register Kanata to start on login"
        "disable    Remove startup registration (keeps files)"
        "uninstall  Remove everything (files + startup)"
    )
    local count=${#menu_items[@]}
    local cursor=0

    printf '\e[?25l' >/dev/tty
    local cleanup_done=0
    cleanup_menu() {
        if [[ $cleanup_done -eq 0 ]]; then
            cleanup_done=1
            printf '\e[?25h' >/dev/tty
        fi
    }
    trap cleanup_menu EXIT INT TERM

    while true; do
        # All UI rendering goes to /dev/tty (bypasses command substitution)
        {
            printf '\e[H\e[2J'
            echo ""
            print_color "${COLOR_BLUE}" "  ╭──────────────────────────────────────────╮"
            print_color "${COLOR_BLUE}" "  │          Kanata Setup Script             │"
            print_color "${COLOR_BLUE}" "  ╰──────────────────────────────────────────╯"
            echo ""

            # Show active modules if any
            if [[ -f "${ACTIVE_MODULES_FILE}" ]]; then
                local mods
                mods=$(paste -sd', ' "${ACTIVE_MODULES_FILE}")
                print_color "${COLOR_DIM}" "  Active modules: ${mods}"
                echo ""
            fi

            for ((i = 0; i < count; i++)); do
                local item="${menu_items[$i]}"
                local cmd_name="${item%%  *}"
                local cmd_desc="${item#*  }"
                cmd_desc="${cmd_desc#"${cmd_desc%%[![:space:]]*}"}"

                if [[ $i -eq $cursor ]]; then
                    printf "  ${COLOR_CYAN}  > ${COLOR_BOLD}%-12s${COLOR_RESET} ${COLOR_CYAN}%s${COLOR_RESET}\n" "$cmd_name" "$cmd_desc"
                else
                    printf "    %-12s ${COLOR_DIM}%s${COLOR_RESET}\n" "$cmd_name" "$cmd_desc"
                fi
            done

            echo ""
            print_color "${COLOR_DIM}" "  ↑/↓ Navigate   Enter Select   q Quit"
        } >/dev/tty

        # Read keypress from terminal directly
        IFS= read -rsn1 key </dev/tty
        if [[ "$key" == $'\e' ]]; then
            IFS= read -rsn2 -t 0.1 rest </dev/tty 2>/dev/null || rest=""
            key="${key}${rest}"
        fi

        case "$key" in
        $'\e[A') ((cursor > 0)) && ((cursor--)) || true ;;
        $'\e[B') ((cursor < count - 1)) && ((cursor++)) || true ;;
        '')
            cleanup_menu
            trap - EXIT INT TERM
            printf '\e[H\e[2J' >/dev/tty

            local selected
            selected="${menu_items[$cursor]}"
            local cmd="${selected%%  *}"
            # Only this goes to stdout (captured by command substitution)
            echo "$cmd"
            return 0
            ;;
        q | Q)
            cleanup_menu
            trap - EXIT INT TERM
            printf '\e[H\e[2J' >/dev/tty
            exit 0
            ;;
        esac
    done
}

show_help() {
    echo "Kanata Setup Script — Modular Configuration System"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  (no args)             Interactive menu"
    echo "  install [--mod ...]   Select modules, merge config, and deploy"
    echo "  update                Rebuild from last selection + update binary"
    echo "  start                 Start Kanata headless"
    echo "  stop                  Stop Kanata process"
    echo "  enable                Register Kanata to start on login"
    echo "  disable               Remove startup registration (keeps files)"
    echo "  status                Check installation, modules, and startup"
    echo "  uninstall             Remove everything (files + startup)"
    echo "  help                  Show this help"
    echo ""

    # Show available modules
    local -a mod_files
    IFS=$'\n' read -r -d '' -a mod_files <<<"$(discover_modules 2>/dev/null)" || true
    if [[ ${#mod_files[@]} -gt 0 ]]; then
        echo "Available modules:"
        for mod_file in "${mod_files[@]}"; do
            [[ -z "$mod_file" ]] && continue
            local name desc
            name=$(get_module_name "$mod_file")
            desc=$(get_module_desc "$mod_file")
            echo "  --${name}    ${desc}"
        done
        echo ""
        echo "Examples:"
        echo "  $0 install                         # Interactive module picker"
        echo "  $0 install --remaps --german        # Install both modules"
        echo "  $0 install --german                 # Only German characters"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

run_command() {
    local command="$1"
    shift

    case "${command}" in
    install)
        INSTALL_ARGS=("$@")
        cmd_install
        ;;
    update)
        if [[ ! -f "${ACTIVE_MODULES_FILE}" ]]; then
            print_color "${COLOR_RED}" "ERROR: No modules previously installed. Use 'install' first."
            exit 1
        fi
        INSTALL_ARGS=()
        while IFS= read -r mod_name; do
            INSTALL_ARGS+=("--${mod_name}")
        done <"${ACTIVE_MODULES_FILE}"
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
    help | --help | -h)
        show_help
        ;;
    *)
        print_color "${COLOR_RED}" "Unknown command: ${command}"
        echo ""
        show_help
        exit 1
        ;;
    esac
}

# Main entry point
if [[ $# -eq 0 ]] && [[ -t 0 ]]; then
    # No args + interactive terminal → show main menu
    selected_command=$(show_main_menu)
    run_command "$selected_command"
else
    command="${1:-help}"
    shift 2>/dev/null || true
    run_command "$command" "$@"
fi
