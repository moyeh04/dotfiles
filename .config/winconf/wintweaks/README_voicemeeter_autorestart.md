### Voicemeeter Auto-Restart

Automatically restarts Voicemeeter's audio engine when Bluetooth/USB audio devices reconnect.

**The Problem:**
When Bluetooth headphones disconnect and reconnect, Voicemeeter doesn't detect the reconnection. It keeps trying to use the old broken connection, resulting in red flashing indicators and no audio. You have to manually restart the audio engine to fix it.

**The Solution:**
Uses Windows Task Scheduler to monitor audio device events. When EventID 65 (device state changed) is logged in the Microsoft-Windows-Audio/Operational channel, it automatically runs `voicemeeter.exe -R` to restart the audio engine.

**Usage:**

```bash

# Enable auto-restart
./voicemeeter_autorestart.sh enable

# Disable auto-restart
./voicemeeter_autorestart.sh disable

# Check status
./voicemeeter_autorestart.sh status
```

**How it works:**

1. **Event-driven (not polling)**: Zero CPU usage when idle
2. **Monitors Windows Event Log**: Watches for audio device state changes
3. **Instant response**: Triggers immediately when device reconnects
4. **Auto-detects Voicemeeter variant**: Works with standard/Banana/Potato

**Technical Details:**

- **Event Channel**: `Microsoft-Windows-Audio/Operational`
- **Event ID**: `65` (device state changed)
- **XPath Query**: `*[System[Provider[@Name='Microsoft-Windows-Audio'] and EventID=65]]`
- **Action**: Runs `voicemeeter.exe -R` (restart audio engine flag)

**Why Event-Driven vs Polling:**

Polling (checking every 3 seconds):

- ❌ Uses CPU continuously (even if tiny)
- ❌ 28,800 checks per day
- ❌ Might miss fast reconnections

Event-Driven (this solution):

- ✅ Zero CPU when idle
- ✅ Instant response
- ✅ Built into Windows, auto-starts

**Requirements:**

- Voicemeeter, Voicemeeter Banana, or Voicemeeter Potato
- Admin privileges (UAC prompt)

**Supported Versions:**

- Voicemeeter (standard)
- Voicemeeter Banana (Pro)
- Voicemeeter Potato (8/8x64)

Script automatically detects which version you have installed.
