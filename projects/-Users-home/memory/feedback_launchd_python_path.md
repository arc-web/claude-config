---
name: LaunchAgent Python path - always Homebrew
description: macOS LaunchAgents must use /opt/homebrew/bin/python3, not /usr/bin/python3, and need explicit PATH + PYTHONUNBUFFERED in EnvironmentVariables
type: feedback
originSessionId: 81ee8d7e-2ff0-4254-bfdd-600ece6e1edd
---
Always use `/opt/homebrew/bin/python3` in any LaunchAgent plist. `/usr/bin/python3` is the macOS system shim - it has no third-party packages installed.

Every LaunchAgent plist that calls Python must include:

```xml
<key>EnvironmentVariables</key>
<dict>
    <key>PYTHONUNBUFFERED</key>
    <string>1</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
</dict>
```

**Why:** launchd inherits almost no environment. Without `PATH`, CLIs like `op` (1Password) are not found even if they work fine in the terminal. Without `PYTHONUNBUFFERED`, `print()` output never appears in the log file because stdout is block-buffered.

**How to apply:** Any time a new LaunchAgent is created for a Python script - check ProgramArguments path AND add the EnvironmentVariables block above. Apply retroactively when editing existing plists if the block is missing.
