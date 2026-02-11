# Kanata Setup — Modular Configuration System

A unified installer script for [Kanata](https://github.com/jtroo/kanata) on Windows (via WSL) that uses a **modular configuration system**. Build custom keyboard layouts by mixing and matching self-contained modules.

---

## Table of Contents

1. [Overview](#overview)
2. [How It Works](#how-it-works)
3. [Directory Structure](#directory-structure)
4. [Quick Start](#quick-start)
5. [Commands](#commands)
6. [Available Modules](#available-modules)
7. [Creating Custom Modules](#creating-custom-modules)
8. [Module System Details](#module-system-details)
9. [Requirements](#requirements)
10. [Troubleshooting](#troubleshooting)
11. [Migration from Old Setup](#migration-from-old-setup)
12. [Technical Details](#technical-details)

---

## Overview

### What is this?

This setup script provides a **modular approach** to Kanata configuration on Windows. Instead of maintaining one giant config file, you create **self-contained modules** for different features (key remaps, language layers, macros, etc.), then mix and match them as needed.

### Key Features

- **Modular design**: Each `.kbd` file is a standalone module with its own keys, aliases, and layers
- **Interactive TUI**: Checkbox-style picker for selecting modules
- **CLI mode**: Non-interactive installation with `--module` flags
- **Smart merging**: Automatically combines selected modules into one config
- **Conflict detection**: Validates that modules don't fight over the same keys
- **Version tracking**: Checks GitHub for updates, skips download if already current
- **Startup integration**: Registers Kanata to run on Windows login

---

## How It Works

### The Module System

Kanata reads **ONE** config file at a time. This setup uses a **build system**:

1. **Modules live in WSL** at `~/.config/kanata/*.kbd`
2. Each module declares which keys it manages (e.g., `caps lctl rctl`)
3. The script **merges** selected modules into a single `kanata_config.kbd`
4. The merged config is deployed to `C:\Windows\Kanata\` and Kanata runs it

### What Happens During Install

1. **Module Discovery**: Script scans `~/.config/kanata/` for `.kbd` files with `@module` markers
2. **Selection**: You pick modules via interactive TUI or CLI args
3. **Validation**: Script checks for:
   - Missing required markers (`@keys`, `@base`, `@aliases-start`, etc.)
   - Mismatched key counts between `@keys` and `@base`
   - Key conflicts between modules (same key claimed by multiple modules)
4. **Merging**:
   - Combines all `@keys` into one `defsrc`
   - Merges all `@aliases` into one `defalias` block
   - Builds a `deflayer base` from each module's `@base` entries
   - Expands any extra layers to match the full `defsrc` width
5. **Binary Check**: Downloads latest `kanata.exe` only if version changed
6. **Deployment**: Copies merged config and binary to `C:\Windows\Kanata\`

7. **Startup**: Registers Kanata in Windows registry to auto-start on login

---

## Directory Structure

```
~/.config/
├── kanata/
│   ├── kanata_remaps.kbd       # Module: Caps→Esc/Ctrl, LCtrl→Caps, RCtrl→AltShift
│   └── kanata_german.kbd       # Module: German umlauts & Eszett (ä ö ü ß)

│
└── winconf/kanata_windows/

    └── kanata_setup.sh         # This installer script
```

**After installation:**

```
C:\Windows\Kanata\
├── kanata.exe                  # The Kanata binary
├── kanata_config.kbd           # Auto-generated merged config
├── active_modules.txt          # List of currently active modules
└── version.txt                 # Installed version (e.g., v1.7.0)
```

---

## Quick Start

### Installation

```bash
cd ~/.config/winconf/kanata_windows

# Interactive mode — shows checkbox picker
./kanata_setup.sh install

# Non-interactive — specify modules via CLI
./kanata_setup.sh install --remaps --german    # Both modules
./kanata_setup.sh install --german              # Only German
./kanata_setup.sh install --remaps              # Only remaps
```

### Common Operations

```bash
# Rebuild config with same modules + update binary if needed
./kanata_setup.sh update

# Start/stop Kanata
./kanata_setup.sh start
./kanata_setup.sh stop

# Check what's installed
./kanata_setup.sh status

# Manage Windows startup registration
./kanata_setup.sh enable      # Register for auto-start
./kanata_setup.sh disable     # Remove from startup (keeps files)

# Complete removal

./kanata_setup.sh uninstall
```

### Interactive Menu

Run the script without arguments to see the main menu:

```bash
./kanata_setup.sh
```

---

## Commands

| Command               | Description                                                   |
| --------------------- | ------------------------------------------------------------- |
| `install [--mod ...]` | Select modules (interactive or via flags), merge, and deploy  |
| `update`              | Rebuild config from last selection + check for binary updates |
| `start`               | Start Kanata headless (via conhost)                           |
| `stop`                | Stop Kanata process                                           |
| `enable`              | Register Kanata to start on Windows login                     |
| `disable`             | Remove startup registration (keeps files)                     |
| `status`              | Show installation, active modules, and process status         |
| `uninstall`           | Remove everything (files + startup registration)              |
| `help`                | Show available commands and modules                           |

---

## Available Modules

### `remaps` — Core Key Remaps

**File**: `~/.config/kanata/kanata_remaps.kbd`

**What it does**:

- **Caps Lock**: Tap → Esc, Hold → Left Ctrl
- **Left Ctrl**: Tap → Caps Lock (with toggle tracking), Hold → Left Ctrl
- **Right Ctrl**: Tap → Alt+Shift (for language switching), Hold → Right Ctrl

**Keys managed**: `caps`, `lctl`, `rctl`

---

### `german` — German Characters

**File**: `~/.config/kanata/kanata_german.kbd`

**What it does**:

- **RAlt + a** → `ä` (Shift/Caps: `Ä`)
- **RAlt + s** → `ß` (Shift/Caps: `ẞ`)
- **RAlt + o** → `ö` (Shift/Caps: `Ö`)
- **RAlt + u** → `ü` (Shift/Caps: `Ü`)

Uses `switch` logic to handle Shift and Caps Lock combinations properly.

**Keys managed**: `ralt`, `a`, `s`, `o`, `u`

---

## Creating Custom Modules

### Module File Structure

Create a new file in `~/.config/kanata/` named `kanata_<name>.kbd`:

```kbd

;; @module <name>
;; @description <what this module does>
;; @keys <key1> <key2> <key3>
;; @base <entry1> <entry2> <entry3>


;; @aliases-start
  alias1  (tap-hold 200 200 key1 lctl)
  alias2  key2
;; @aliases-end


;; @layers-start
;; Optional: Add extra deflayer blocks here
;; Entries must match @keys order
;; @layers-end
```

### Required Markers

Every module **must** have these markers (in the first ~50 lines):

| Marker           | Purpose                              | Example                              |
| ---------------- | ------------------------------------ | ------------------------------------ |
| `@module`        | Module name (used in CLI args)       | `@module mykeys`                     |
| `@description`   | Short description for UI             | `@description Custom arrow keys`     |
| `@keys`          | Physical keys this module intercepts | `@keys caps lctl rctl`               |
| `@base`          | What each key does in base layer     | `@base @escctl @lctlcaps @rctrllang` |
| `@aliases-start` | Start of alias definitions           | —                                    |
| `@aliases-end`   | End of alias definitions             | —                                    |
| `@layers-start`  | Start of optional extra layers       | —                                    |
| `@layers-end`    | End of optional extra layers         | —                                    |

### Important Rules

1. **Key counts must match**: Number of entries in `@keys` must equal number in `@base`
2. **No conflicts**: A physical key can only be claimed by **one** module
3. **Base layer required**: Every module contributes to `deflayer base`

4. **Layer expansion**: Extra layers are auto-padded with `_` for keys not in this module

### Example: Custom Numpad Module

```kbd
;; @module numpad
;; @description Right-hand numpad on home row
;; @keys j k l semicolon u i o p
;; @base @num1 @num2 @num3 @numplus @num4 @num5 @num6 @nummul

;; @aliases-start
  num1     (tap-hold 200 200 j 1)
  num2     (tap-hold 200 200 k 2)
  num3     (tap-hold 200 200 l 3)
  numplus  (tap-hold 200 200 ; +)
  num4     (tap-hold 200 200 u 4)
  num5     (tap-hold 200 200 i 5)
  num6     (tap-hold 200 200 o 6)
  nummul   (tap-hold 200 200 p *)
;; @aliases-end

;; @layers-start
;; @layers-end
```

Install it:

```bash
./kanata_setup.sh install --numpad

```

Or add it to your existing selection:

```bash
./kanata_setup.sh install --remaps --numpad
```

---

## Module System Details

### How Modules Are Merged

When you select multiple modules (e.g., `--remaps --german`), the script:

1. **Collects all keys**:

   ```
   remaps: caps lctl rctl
   german: ralt a s o u

   Combined defsrc: caps lctl rctl ralt a s o u
   ```

2. **Validates no conflicts**:
   - If both modules claim `caps` → ERROR, must fix
   - Each physical key can only belong to one module

3. **Merges aliases**:

   ```
   (defalias
     ;; ── remaps ──
     escctl    (tap-hold 100 100 esc lctl)
     lctlcaps  (tap-hold 250 250 caps lctl)
     rctrllang (tap-hold 200 200 (multi lalt lsft) rctl)

     ;; ── german ──
     de-a (switch ...)
     de-s (switch ...)
     ...
   )
   ```

4. **Builds base layer**:

   ```
   (deflayer base
     @escctl      ;; caps (remaps)
     @lctlcaps    ;; lctl (remaps)
     @rctrllang   ;; rctl (remaps)
     ralt         ;; ralt (german)
     @de-a        ;; a (german)
     @de-s        ;; s (german)
     @de-o        ;; o (german)
     @de-u        ;; u (german)
   )
   ```

5. **Expands extra layers**:
   - If a module has extra `deflayer` blocks in `@layers-start/end`
   - Script pads them with `_` for keys not in that module
   - Ensures all layers have the same width as `defsrc`

### Layer Expansion Example

If the `german` module had an extra layer:

```kbd
;; @layers-start
(deflayer german-upper
  Ä Ö Ü ẞ
)
;; @layers-end
```

The script expands it to match the full `defsrc`:

```kbd
(deflayer german-upper
  _            ;; caps (not in german module)
  _            ;; lctl (not in german module)
  _            ;; rctl (not in german module)
  _            ;; ralt (not in german module)
  Ä            ;; a (german module)
  ẞ            ;; s (german module)
  Ö            ;; o (german module)
  Ü            ;; u (german module)
)
```

This allows modules to define their own layers without needing to know about other modules' keys.

---

## Requirements

### System Requirements

- **WSL** (Windows Subsystem for Linux) — Ubuntu 20.04+ or equivalent
- **PowerShell 7** (`pwsh.exe`) accessible from WSL
- **Internet connection** (for downloading Kanata binary)

### WSL Tools

The script requires these commands (usually pre-installed):

- `curl` — Downloading binary
- `unzip` — Extracting release archive
- `wslpath` — Converting paths between WSL and Windows

Check if installed:

```bash
command -v curl unzip wslpath pwsh.exe
```

Install missing tools (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install curl unzip
```

### Kanata Binary Variant

The script uses: **`kanata_windows_tty_winIOv2_cmd_allowed_x64.exe`**

**Why this variant?**

- **No driver installation**: Uses Windows low-level keyboard hooks
- **Headless operation**: Runs via `conhost.exe --headless` (no visible window)
- **cmd support**: Allows `(cmd ...)` actions in your config
- **TTY variant**: Works from WSL/terminals without GUI dependencies

---

## Troubleshooting

### Script says "No modules found"

**Cause**: No `.kbd` files with `@module` markers in `~/.config/kanata/`

**Fix**:

```bash
# Check if files exist
ls -la ~/.config/kanata/*.kbd

# Verify @module marker (must be in first 5 lines)

head -5 ~/.config/kanata/kanata_remaps.kbd
```

Should contain: `;; @module remaps`

---

### "Key X is claimed by both Y and Z"

**Cause**: Two modules try to manage the same physical key

**Fix**: Edit one of the modules to remove the conflicting key from its `@keys` line.

Example conflict:

```
remaps: @keys caps lctl rctl
mymod:  @keys caps tab      # ❌ 'caps' conflict!
```

Solution: Remove `caps` from `mymod` or `remaps`.

---

### "@keys has 3 entries but @base has 4"

**Cause**: Mismatch between `@keys` and `@base` entry counts

**Fix**: Ensure both lines have the **same number of space-separated entries**.

```kbd
;; ❌ Wrong
;; @keys caps lctl rctl
;; @base @escctl @lctlcaps @rctrllang @extra

;; ✅ Correct
;; @keys caps lctl rctl
;; @base @escctl @lctlcaps @rctrllang
```

---

### Kanata doesn't start after install

**Check 1**: Is the process running?

```bash
./kanata_setup.sh status
```

**Check 2**: Manual start for debugging:

```powershell
# From Windows PowerShell
C:\Windows\Kanata\kanata.exe --cfg C:\Windows\Kanata\kanata_config.kbd
```

Look for errors in the output.

**Check 3**: Validate config syntax:

```bash
# Copy generated config back to WSL for inspection
cp /mnt/c/Windows/Kanata/kanata_config.kbd /tmp/test.kbd
cat /tmp/test.kbd
```

---

### Binary download fails

**Symptoms**: "ERROR: Failed to download" or "Could not fetch"

**Causes**:

1. No internet connection
2. GitHub API rate limit
3. Firewall blocking GitHub

**Fix**:

```bash
# Test GitHub connection
curl -I https://api.github.com


# Check if rate limited
curl https://api.github.com/rate_limit

# Try again later or check firewall
```

---

### PowerShell not found

**Error**: `ERROR: PowerShell (pwsh.exe) not found`

**Fix**: Install PowerShell 7+ on Windows, then ensure WSL can find it:

```bash
# Test from WSL
pwsh.exe -Version

# If not found, add to PATH or use full path
# Edit script and change PWSH_EXE to full path
```

---

### Config changes don't take effect

**Solution**: Rebuild and restart:

```bash
./kanata_setup.sh update
./kanata_setup.sh stop
./kanata_setup.sh start
```

Or simpler:

```bash
./kanata_setup.sh install --remaps --german  # Re-deploys config
```

---

### UAC prompt appears every time

This is normal for initial install. The script needs admin rights to write to `C:\Windows\Kanata\`.

After initial setup, `update`, `start`, `stop` commands don't need elevation.

---

## Migration from Old Setup

If you're coming from the old single-file setup:

### Old Structure

```
~/.config/kanata/kanata_config.kbd    # One big config
```

### Migration Steps

1. **Back up your old config**:

   ```bash
   cp ~/.config/kanata/kanata_config.kbd ~/.config/kanata/kanata_config.kbd.backup
   ```

2. **Split into modules**: Create separate `.kbd` files for each feature.

   Example: If your old config had this:

   ```kbd
   (defsrc caps lctl rctl ralt a s o u)

   (defalias
     escctl    (tap-hold 100 100 esc lctl)
     lctlcaps  (tap-hold 250 250 caps lctl)
     rctrllang (tap-hold 200 200 (multi lalt lsft) rctl)
     de-a      (switch ...)
     de-s      (switch ...)
     de-o      (switch ...)
     de-u      (switch ...)
   )

   (deflayer base
     @escctl @lctlcaps @rctrllang ralt @de-a @de-s @de-o @de-u
   )
   ```

   **Split it into two modules**:

   **`kanata_remaps.kbd`**:

   ```kbd
   ;; @module remaps
   ;; @description Core key remaps
   ;; @keys caps lctl rctl
   ;; @base @escctl @lctlcaps @rctrllang

   ;; @aliases-start
     escctl    (tap-hold 100 100 esc lctl)
     lctlcaps  (tap-hold 250 250 caps lctl)

     rctrllang (tap-hold 200 200 (multi lalt lsft) rctl)
   ;; @aliases-end

   ;; @layers-start
   ;; @layers-end
   ```

   **`kanata_german.kbd`**:

   ```kbd
   ;; @module german
   ;; @description German characters
   ;; @keys ralt a s o u
   ;; @base ralt @de-a @de-s @de-o @de-u

   ;; @aliases-start
     de-a (switch ...)

     de-s (switch ...)
     de-o (switch ...)

     de-u (switch ...)
   ;; @aliases-end

   ;; @layers-start
   ;; @layers-end
   ```

3. **Install with new script**:

   ```bash
   ./kanata_setup.sh install --remaps --german

   ```

4. **Verify**: Check that the merged config matches your old one:
   ```bash
   diff ~/.config/kanata/kanata_config.kbd.backup /mnt/c/Windows/Kanata/kanata_config.kbd
   ```

---

## Technical Details

### How Startup Works

The script registers Kanata in the Windows registry:

**Registry Key**: `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`

**Registry Value**: `Kanata` → `C:\Windows\system32\conhost.exe --headless C:\Windows\Kanata\kanata.exe --cfg C:\Windows\Kanata\kanata_config.kbd`

This runs Kanata in a **headless console** (no visible window) on every Windows login.

### Binary Download Process

1. Fetches latest release info from GitHub API: `https://api.github.com/repos/jtroo/kanata/releases/latest`
2. Extracts version tag (e.g., `v1.7.0`)
3. Checks `C:\Windows\Kanata\version.txt` — if version matches, skips download
4. Downloads: `https://github.com/jtroo/kanata/releases/download/<version>/kanata-windows-binaries-x64-<version>.zip`
5. Extracts `kanata_windows_tty_winIOv2_cmd_allowed_x64.exe` from archive
6. Copies to `C:\Windows\Kanata\kanata.exe`
7. Saves version to `version.txt`

### Deployment Flow

**Fast path** (config-only update):

1. Binary already up to date → Skip download
2. Stop Kanata if running
3. Copy merged `kanata_config.kbd` → `C:\Windows\Kanata\`
4. Start Kanata

**Full path** (new binary):

1. Download and extract binary
2. Create PowerShell install script
3. Elevate (UAC prompt)
4. Stop Kanata, copy binary + config, register startup, start Kanata

### File Permissions

- `C:\Windows\Kanata\` requires admin rights for **initial creation**
- Subsequent config updates can use direct copy (no elevation) if user has write access
- If direct copy fails, script falls back to elevated PowerShell script

### Active Modules Tracking

After install, the script saves module names to `C:\Windows\Kanata\active_modules.txt`:

```
remaps
german
```

The `update` command reads this file to rebuild config with the same modules without prompting.

---

## FAQ

### Can I use this with the Kanata driver variant?

Yes, but you'll need to modify the script's `BINARY_VARIANT` variable. The driver variant requires separate installation of the Interception driver.

The TTY variant (default) is recommended because it requires no driver installation.

### Can I have per-application configs?

Not with this script directly. The merged config is global. However, Kanata supports `defcfg` process filters if you want to add per-app logic inside modules.

### Can modules depend on each other?

No. Modules are independent. If you need shared aliases, either:

1. Duplicate the alias in each module, or
2. Create a "core" module that other modules build on

### How do I temporarily disable a module?

```bash
# Re-install without that module
./kanata_setup.sh install --remaps    # Excludes 'german'
```

### Can I use this on Linux or macOS?

The script is Windows-specific (uses PowerShell, Windows registry, etc.). But the **module format** could work anywhere — you'd just need to adapt the deployment logic.

### What if I want to edit the generated config directly?

Don't! It gets overwritten on every `install`/`update`. Instead:

1. Edit your module files in `~/.config/kanata/`
2. Re-run `./kanata_setup.sh install`

The generated config includes a warning header: `DO NOT EDIT — regenerate with: kanata_setup.sh install`

---

## Example Workflows

### Scenario 1: Just want basic remaps

```bash
./kanata_setup.sh install --remaps

```

### Scenario 2: Want everything

```bash
./kanata_setup.sh install --remaps --german

```

### Scenario 3: Testing a new module

```bash
# Create module
nano ~/.config/kanata/kanata_arrows.kbd

# Test it
./kanata_setup.sh install --arrows

# Works? Add to your regular setup
./kanata_setup.sh install --remaps --arrows --german
```

### Scenario 4: Update Kanata binary only

```bash
# Update command checks for new binary + rebuilds config
./kanata_setup.sh update
```

### Scenario 5: Temporarily stop Kanata

```bash
./kanata_setup.sh stop

# Later...
./kanata_setup.sh start
```

### Scenario 6: Remove from startup but keep installed

```bash
./kanata_setup.sh disable
```

---

## German Module — Implementation Details

### How It Works

The German umlaut module uses a **C program** to achieve blazing-fast Unicode input:

1. **User presses**: `RAlt + a`
2. **Kanata triggers**: `fork` sends command to `UmlautTyper.exe a`
3. **C program**:
   - Reads Caps Lock state via `GetKeyState(VK_CAPITAL)`
   - Reads Shift state via `GetKeyState(VK_SHIFT)`
   - Applies XOR logic: `uppercase = CapsLock XOR Shift`
   - Sends Unicode character via `SendInput(KEYEVENTF_UNICODE)`
4. **Result**: `ä` or `Ä` appears instantly (~19ms)

### Why C Instead of Kanata's Built-in Unicode?

**Performance:**

- Old approach (switch + unicode): Works, but complex config
- New approach (C program): 5.4x faster, handles Caps/Shift XOR natively

**Simplicity:**

- Config went from 50+ lines of switch logic to 4 simple fork aliases
- All complexity moved to C program (easy to update/debug)

### Building the UmlautTyper

```bash
cd ~/.config/winconf/kanata_windows

# Compile and deploy
./build_umlaut.sh
```

**What it does:**

1. Compiles `UmlautTyper.c` with mingw-w64
2. Optimizes with `-O3` (max speed)
3. Strips debug symbols `-s` (smaller binary)
4. Copies to `C:\Windows\Kanata\UmlautTyper.exe`

**Requirements:**

```bash
sudo apt install mingw-w64
```

### Updating the C Program

If you need to modify the umlaut logic:

1. Edit `UmlautTyper.c`
2. Run `./build_umlaut.sh`
3. Restart Kanata: `./kanata_setup.sh stop && ./kanata_setup.sh start`

### Performance Benchmarks

Tested on Windows 11 with 5 runs per character:

| Implementation                | Avg Time | Speedup         |
| ----------------------------- | -------- | --------------- |
| PowerShell + layout switching | 250ms    | 1.0x (baseline) |
| C# + layout switching         | 150ms    | 1.67x           |
| **C + Unicode (current)**     | **19ms** | **13.2x**       |

The new approach is **faster than human perception** (~100ms threshold).

### Character Mappings

| Keys     | Output | Unicode         |
| -------- | ------ | --------------- |
| RAlt + a | ä / Ä  | U+00E4 / U+00C4 |
| RAlt + o | ö / Ö  | U+00F6 / U+00D6 |
| RAlt + u | ü / Ü  | U+00FC / U+00DC |
| RAlt + s | ß / ẞ  | U+00DF / U+1E9E |

### Caps Lock & Shift Behavior (XOR Logic)

| Caps Lock | Shift | Result    | Example |
| --------- | ----- | --------- | ------- |
| OFF       | OFF   | lowercase | ö       |
| OFF       | ON    | uppercase | Ö       |
| ON        | OFF   | uppercase | Ö       |
| ON        | ON    | lowercase | ö       |

This matches standard keyboard behavior for all other keys.

### Technical Implementation

**C Program Structure:**

```c
int main(int argc, char *argv[]) {
    char c = argv[1][0];  // Get character (a/o/u/s)

    // XOR logic
    BOOL upper = (GetKeyState(VK_CAPITAL) & 1) ^
                 (GetKeyState(VK_SHIFT) & 0x8000);

    // Map to Unicode
    WCHAR unicode = /* ... */;

    // Send via Windows Input API
    SendInput(2, inputs, sizeof(INPUT));
    Sleep(10);  // Timing stability
}
```

**Why `Sleep(10)`?**
Ensures the input is processed before the program exits. Without it, some
applications might miss the keystroke. 10ms is imperceptible to humans but
crucial for reliability.

### Troubleshooting

**"UmlautTyper.exe not found"**

```bash
./build_umlaut.sh
```

**Umlauts not working after update**

```bash
./kanata_setup.sh stop
./build_umlaut.sh
./kanata_setup.sh start
```

**Want to add more characters?**
Edit `UmlautTyper.c`, add case to switch statement, rebuild.

## Contributing

Found a bug? Have a useful module? Suggestions for improving the merge logic?

- Open an issue
- Submit a pull request
- Share your modules in the discussions

---

## License

This setup script is provided as-is. Kanata itself is licensed under LGPL-3.0-or-later.

---

## Acknowledgments

- [Kanata](https://github.com/jtroo/kanata) by jtroo
- Modular config system inspired by QMK's keymap organization
- TUI picker inspired by fzf's interface design

---

**Happy typing!** ⌨️
