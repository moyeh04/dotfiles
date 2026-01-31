### Alacritty Setup

**Directory structure:**

```
~/.config/
├── alacritty/
│   └── alacritty.toml        # Shared config (works for both Linux & Windows)
└── winconf/
    └── setup_alacritty.sh
```

**Requirements:**

- Alacritty installed at `C:\Program Files\Alacritty\`
- `alacritty.toml` in `~/.config/alacritty/`

**Setup:**

1. Make sure your `alacritty.toml` is at:
   `~/.config/alacritty/alacritty.toml`

2. Run the setup script from WSL:
   ```bash
   cd ~/.config/winconf
   ./setup_alacritty.sh
   ```

**What the script does:**

- Downloads the latest ConPTY files (`conpty.dll` and `OpenConsole.exe`) from Windows Terminal releases
- Copies them to `C:\Program Files\Alacritty\`
- Copies your `alacritty.toml` to `C:\Users\User\AppData\Roaming\alacritty\`
- Checks versions to avoid re-downloading if already up to date

**Manual alternative:**
If you prefer to manually place files:

1. Download the latest Windows Terminal ConPTY package from:
   https://github.com/microsoft/terminal/releases
2. Extract `conpty.dll` and `OpenConsole.exe` from the NuGet package
3. Place them in: `C:\Program Files\Alacritty\`

4. Place `alacritty.toml` in: `C:\Users\User\AppData\Roaming\alacritty\`
