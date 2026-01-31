# Windows Configuration Scripts

Manage Windows settings and applications from WSL.

## Directory Structure

```
~/.config/
├── alacritty/
│   └── alacritty.toml          # Shared config (Linux & Windows)
├── kanata/
│   └── kanata_config.kbd       # Shared config (Linux & Windows)
└── winconf/
    ├── setup_alacritty.sh      # Setup Alacritty on Windows
    ├── kanata_windows/
    │   ├── setup_kanata.sh     # Setup Kanata keyboard remapper
    └── wintweaks/
        └── bing_search.sh      # Toggle Bing search
```

## Scripts

### setup_alacritty.sh

Downloads latest ConPTY files and sets up Alacritty configuration.
Location: `~/.config/winconf/setup_alacritty.sh`

```bash
cd ~/.config/winconf
./setup_alacritty.sh
```

### setup_kanata.sh

Downloads latest Kanata release and registers it for auto-start.
Location: `~/.config/winconf/kanata_windows/setup_kanata.sh`

```bash
cd ~/.config/winconf/kanata_windows
./setup_kanata.sh
```

### bing_search.sh

Toggle Bing web search results in Windows 11 Search.
Location: `~/.config/winconf/wintweaks/bing_search.sh`

```bash
cd ~/.config/winconf/wintweaks
./bing_search.sh disable    # Local search only
./bing_search.sh enable     # Enable web results
./bing_search.sh status     # Check current state
```

## Requirements

- WSL (Windows Subsystem for Linux)

- PowerShell (pwsh.exe)
- Internet connection (for downloading latest releases)

## Notes

- Alacritty uses the shared config from `~/.config/alacritty/` (same for Linux & Windows)
- Kanata config is Windows-specific and lives in `kanata_windows/` subdirectory
- Scripts check versions to avoid re-downloading
- Admin privileges required (UAC prompts will appear)
- Run each script from its own directory (they use relative/absolute paths appropriately)

- See individual README files for detailed documentation
