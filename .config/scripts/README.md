# Shell Bootstrap Scripts

This directory contains shell environment setup scripts that run automatically
on shell startup via the bootstrap system.

## Structure

```
scripts/
├── bootstrap              # Main orchestrator (sourced by .zshrc)
├── README.md              # This file
├── lib/
│   └── common             # Shared utility functions
└── setup/
    ├── antigravity-launcher-setup
    └── pythons-are-python3-brew
```

## How It Works

1. `.zshrc` sources `bootstrap`
2. `bootstrap` sources `lib/common` (shared utilities)
3. `bootstrap` ensures `~/bin` exists
4. `bootstrap` sources every script in `setup/` directory

Scripts are **idempotent** - they check if work is needed before doing anything,
making shell startup fast after the first run.

## Adding a New Setup Script

1. Create a new file in `setup/`:
   ```bash
   touch ~/.config/scripts/setup/my-new-setup
   chmod +x ~/.config/scripts/setup/my-new-setup
   ```

2. Use this template:
   ```zsh
   #!/bin/zsh
   # --- my-new-setup ---
   #
   # Purpose:
   #   What this script does
   #
   # How to Undo:
   #   Commands to reverse the changes

   # Your setup logic here
   # Use utilities from lib/common:
   #   - debug_echo "message"
   #   - ensure_dir "/path/to/dir"
   #   - ensure_symlink "/link/path" "/target/path" "name"
   #   - needs_update "/file/path" "VERSION=1.0.0"
   ```

3. Reload your shell or run:
   ```bash
   source ~/.zshrc
   ```

## Debugging

Enable debug output to see what each script is doing:

```bash
DEBUG=1 source ~/.zshrc
```

Or for a specific script:

```bash
DEBUG=1 source ~/.config/scripts/setup/pythons-are-python3-brew
```

## Available Utilities (lib/common)

| Function | Description |
|----------|-------------|
| `debug_echo "msg"` | Print message only if `DEBUG=1` |
| `ensure_dir "/path"` | Create directory if it doesn't exist |
| `ensure_symlink "/link" "/target" "name"` | Create symlink if missing or wrong |
| `needs_update "/file" "VERSION=x.x.x"` | Check if file needs updating (returns 0 if yes) |

## Current Setup Scripts

### pythons-are-python3-brew

Creates symlinks so `python` and `python3` point to Homebrew's Python 3.

**Creates:**
- `~/bin/python` → `/home/linuxbrew/.linuxbrew/bin/python3`
- `~/bin/python3` → `/home/linuxbrew/.linuxbrew/bin/python3`

**Undo:** `rm ~/bin/python ~/bin/python3`

### antigravity-launcher-setup

Creates `avg` command to launch Google Antigravity IDE from WSL.

**Creates:**
- `~/bin/avg` - Launcher script

**Undo:** `rm ~/bin/avg`
