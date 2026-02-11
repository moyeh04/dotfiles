#!/usr/bin/env bash
################################################################################
# UmlautTyper Build Script
# Compiles C program (deployment handled by kanata_setup.sh)
################################################################################

set -euo pipefail

readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RESET='\033[0m'

readonly SOURCE_FILE="UmlautTyper.c"
readonly OUTPUT_FILE="UmlautTyper.exe"
readonly COMPILER="x86_64-w64-mingw32-gcc"

print_color() {
    echo -e "${1}${2}${COLOR_RESET}"
}

# Check if source exists
if [[ ! -f "${SOURCE_FILE}" ]]; then
    print_color "${COLOR_RED}" "ERROR: ${SOURCE_FILE} not found!"
    exit 1
fi

# Check compiler
if ! command -v "${COMPILER}" &>/dev/null; then
    print_color "${COLOR_RED}" "ERROR: ${COMPILER} not found. Install mingw-w64:"
    echo "  sudo apt install mingw-w64"
    exit 1
fi

# Compile
print_color "${COLOR_BLUE}" "=== Compiling UmlautTyper ==="
print_color "${COLOR_YELLOW}" "Source: ${SOURCE_FILE}"

if ${COMPILER} "${SOURCE_FILE}" -o "${OUTPUT_FILE}" -O3 -s -luser32 -static; then
    print_color "${COLOR_GREEN}" "✓ Compilation successful"

    # Show file size
    if [[ -f "${OUTPUT_FILE}" ]]; then
        SIZE=$(stat -c%s "${OUTPUT_FILE}" 2>/dev/null || stat -f%z "${OUTPUT_FILE}" 2>/dev/null)
        SIZE_KB=$((SIZE / 1024))
        print_color "${COLOR_YELLOW}" "Size: ${SIZE_KB} KB"
        print_color "${COLOR_BLUE}" "Output: ${OUTPUT_FILE}"
    fi
else
    print_color "${COLOR_RED}" "✗ Compilation failed"
    exit 1
fi

print_color "${COLOR_GREEN}" "✓ Build complete!"
print_color "${COLOR_YELLOW}" "Run './kanata_setup.sh install' to deploy"

