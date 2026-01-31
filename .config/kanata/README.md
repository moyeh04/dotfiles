### Kanata Setup

**Directory structure:**

```
~/.config/
└── kanata/
│   └── kanata_config.kbd     # Shared config (works for both Linux & Windows)
│
└── winconf/kanata_windows
    └── kanata_setup.sh
```

**Requirements:**

- `kanata_config.kbd` in the same directory as the script
- Internet connection (script downloads latest kanata.exe automatically)

**Setup:**

1. Place your `kanata_config.kbd` configuration file in:
   `~/.config/kanata/kanata_config.kbd`

2. Run the setup script from WSL:
   ```bash
   cd ~/.config/winconf/kanata_windows
   ./setup_kanata.sh
   ```

**What the script does:**

- Downloads the latest `kanata_winIOv2_cmd_allowed.exe` from GitHub releases
- Extracts it to `C:\Windows\Kanata\kanata.exe`
- Copies your config file to `C:\Windows\Kanata\kanata_config.kbd`
- Registers Kanata to start automatically on login (using conhost --headless)
- Checks versions to avoid re-downloading if already up to date

**Binary variant used:**

- `kanata_winIOv2_cmd_allowed.exe` (TTY variant)
- Uses Windows hooks (no driver installation required)
- Runs in headless console via conhost
- Supports `cmd` actions in config

**Manual start (for testing):**

```powershell
C:\Windows\system32\conhost.exe --headless C:\Windows\Kanata\kanata.exe --cfg C:\Windows\Kanata\kanata_config.kbd
```

**Startup location:**
Registry key: `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`
