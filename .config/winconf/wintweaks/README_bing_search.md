### Windows 11 Bing Search Toggle

Disable or enable Bing web search results in Windows 11 Search.

**Usage:**

```bash

# Disable Bing search (local results only)
./bing_search.sh disable

# Enable Bing search (restore web results)
./bing_search.sh enable

# Check current status
./bing_search.sh status
```

**What it does:**

Sets registry keys to disable/enable web search suggestions:

- `HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions`

- `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\BingSearchEnabled`

**Requirements:**

- Windows 11 (any edition)
- PowerShell (pwsh.exe)
- Admin privileges (will prompt for UAC)

**Side effects:**

- Disabling Bing search also removes the Copilot button from the taskbar
- Windows Explorer will restart to apply changes

**Note:**
The Windows Settings toggles for search don't actually work - registry editing is required.
