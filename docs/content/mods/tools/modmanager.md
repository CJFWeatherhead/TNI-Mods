---
title: "Mod Manager - TNI Mod Manager"
date: 2026-01-24
draft: false
---

# Tower Networking Inc - Mod Manager v3.5.3

A modern Windows application with a graphical interface for managing Tower Networking Inc mods. Browse, download, install, configure, and manage all your mods in one place!

## Features

🌐 **GitHub Integration**

- Browse and download mods directly from GitHub releases
- Automatic version checking for installed mods
- One-click updates when new versions are available
- Real-time download progress with status updates

🎮 **Full Mod Management**

- View all installed and available mods in one place
- Visual distinction between mod sources (Downloaded, Manual, Available)
- Enable/disable manually installed mods
- Remove downloaded mods with one click
- Configure all mod parameters with validation

📁 **Smart Mod Handling**

- **Downloaded mods**: Installed from GitHub releases, removed completely when uninstalled
- **Manual mods**: Installed by hand, moved to disabled folder when disabled
- Automatic tracking of mod sources and versions

⌨️ **Command Aliases**

- Create and manage in-game command shortcuts
- Edit existing aliases or add new ones
- Saved directly to game settings

🎨 **Modern WPF Interface**

- Clean, intuitive graphical interface
- Color-coded mod status indicators
- Progress bars for downloads
- Instant feedback on all actions

## Requirements

- Windows 10/11
- .NET Framework 4.5+ (included in Windows)
- Internet connection (for downloading mods from GitHub)

## Download

### Latest Release: v3.5.3

**[[U+1F4E6] Download TNI-ModManager-v3.5.3.exe](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/mod-manager-v3.5.3/TNI-ModManager-v3.5.3.exe)** *(Recommended)*

**Windows Application** - Double-click to run. No PowerShell knowledge required!

---

**Alternative: PowerShell Script**

Download [ModManagerGUI.ps1](https://raw.githubusercontent.com/CJFWeatherhead/TNI-Mods/beta/ModManagerGUI.ps1) and run:
```powershell
powershell.exe -ExecutionPolicy Bypass -File ModManagerGUI.ps1
```

Or use [ModManager.bat](https://raw.githubusercontent.com/CJFWeatherhead/TNI-Mods/beta/ModManager.bat) for easy launching.

[View all releases on GitHub [U+2192]](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/mod-manager-v3.5.3)

## Quick Start

1. **Download** the latest release (see Download section above)
2. **Run** the executable - it will automatically detect your game installation
3. **Browse** available mods fetched from GitHub
4. **Download** mods with one click
5. **Configure** parameters using the graphical interface
6. **Launch** your game directly from the manager

## How to Use the Mod Manager

### Main Interface

The mod manager opens with a clean interface showing:

- **Mod List** (left side): All available and installed mods
  - Color-coded by source (Blue=Downloaded, Purple=Manual, Gray=Available)
  - Update badges when new versions are available
  - Filter tabs: All / Installed / Available
  
- **Mod Details** (right side): Information about the selected mod
  - Description and features
  - Version information
  - Configuration parameters
  - Action buttons (Download/Update/Remove/Enable/Disable)

### Browsing and Downloading Mods

1. **Browse Available Mods**
   - Click the "Available" filter to see mods you can download
   - Gray entries show mods from GitHub releases
   
2. **Download a Mod**
   - Select any available mod from the list
   - Click the **Download** button
   - Watch the progress bar as it downloads
   - The mod will be automatically installed and ready to configure

3. **Update Installed Mods**
   - Mods with updates show an "⚠ Update Available" badge
   - Select the mod and click **Update**
   - The latest version will be downloaded and installed

### Managing Installed Mods

#### Viewing Mod Sources

The manager distinguishes three types of mods:

| Source | Color | Description |
|--------|-------|-------------|
| **Downloaded** | Blue | Installed from GitHub releases. Can be updated or removed completely. |
| **Manual** | Purple | Installed manually by copying files. Can be disabled (moved to Mods_Disabled folder). |
| **Available** | Gray | Not installed yet. Can be downloaded from GitHub. |

#### Enabling/Disabling Manual Mods

For mods you installed manually:

1. Select the mod from the list
2. Click **Disable** to move it to the disabled folder
3. Click **Enable** to move it back to the active mods folder

*Note: Downloaded mods cannot be disabled, only removed completely.*

#### Removing Downloaded Mods

To completely remove a mod that was downloaded:

1. Select the mod from the list
2. Click **Remove**
3. Confirm the removal
4. All mod files will be deleted

### Configuring Mod Parameters

Each mod may have configurable parameters that appear when you select an installed mod:

1. **Select an installed mod** from the list
2. **View parameters** in the Configuration panel on the right
3. **Edit values** using the provided controls:
   - **Boolean**: Checkboxes for true/false
   - **Integer/Number**: Text boxes with validation
   - **String**: Text input fields
   - **Select**: Dropdown menus with predefined options
4. **Click Save** to write changes to the mod's configuration
5. **Click Save All** to save all modified mods at once
6. **Click Reset** to restore default values

### Configuration Location

The mod manager reads/writes configuration directly in each mod's `entry.lua` file:

```
%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\<mod-name>\entry.lua
```

Changes update the configuration section between the markers:

```lua
-- ===== MOD CONFIGURATION START =====
local config = { ... }
-- ===== MOD CONFIGURATION END =====
```

## Parameter Types Supported

### Boolean
- Simple yes/no toggles
- Displays as `true` or `false`

### Integer
- Whole numbers only
- Validates against Min/Max if specified
- Example: `warranty_multiplier_min: 2`

### Number (Float)
- Decimal numbers
- Validates against Min/Max if specified
- Example: `starting_cash_multiplier: 10.5`

### String
- Free-form text input
- Example: `address_format: "f%d/usr%d"`

### Select (Dropdown)
- Choose from predefined options
- Example: `dhcp_mode: ["disabled", "boot_dhcp", "periodic_dhcp"]`

### Managing Command Aliases

The Aliases tab lets you create shortcuts for in-game commands:

1. Click the **Aliases** tab
2. Click **New Alias** to add one
3. Enter:
   - **Alias Name**: The shortcut command (e.g., `money`)
   - **Command**: The full command (e.g., `debug_add_cash 1000000`)
4. Click **Apply** to save
5. Use **Delete** to remove aliases
6. Click **Save Aliases** to write changes to game settings

Your aliases will be available in-game in the console!

### Launching the Game

Click the **Launch Game** button to start Tower Networking Inc directly from the mod manager. The manager will close, and your game will start with all enabled mods loaded.

## Troubleshooting

### Common Issues

**Problem**: Executable won't run / Security warning
- **Solution**: Windows may show a SmartScreen warning for new executables. Click "More info" then "Run anyway". The app is safe.
- **Alternative**: Use the PowerShell script version (see Download section)

**Problem**: Can't connect to GitHub / Download fails
- **Solution**: Check your internet connection and firewall settings. The app needs access to `api.github.com`.

**Problem**: Mods not detected
- **Solution**: The manager looks in `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`. If your game uses a different location, manually install mods there first.

**Problem**: Configuration changes not saving
- **Solution**: Ensure the mod has a proper configuration section in its `entry.lua` file between the config markers. Check file permissions.

**Problem**: Invalid parameter values
- **Solution**: The mod manager validates all inputs. Check the error message and the parameter's min/max values.

**Problem**: Update shows but can't download
- **Solution**: Make sure the mod was originally downloaded through the manager. Manual mods can't be auto-updated.

## Support

For issues, questions, or suggestions:

- Check your mod's `metadata.yaml` is valid
- Review the [main README](https://github.com/CJFWeatherhead/TNI-Mods/blob/main/README.md)
- Look at console output for errors
- Report issues on [GitHub](https://github.com/CJFWeatherhead/TNI-Mods/issues)

## Technical Details

### File Locations

The mod manager uses these directories:

- **Mods**: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\Mods\`
- **Disabled Mods**: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\Mods_Disabled\`
- **Game Settings**: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\settings.json`
- **Mod Cache**: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mod_cache.json`

### Configuration Storage

Mod configurations are stored directly in each mod's `entry.lua` file:

```lua
-- ===== MOD CONFIGURATION START =====
local config = {
    enabled = true,
    parameter1 = 10,
    parameter2 = "value"
}
-- ===== MOD CONFIGURATION END =====
```

The manager parses and updates this section while preserving all other mod code.

### Mod Cache

The `mod_cache.json` file tracks which mods were downloaded vs manually installed:

```json
{
  "money-cheat": {
    "source": "Downloaded",
    "version": "0.1.1",
    "download_date": "2026-01-24"
  },
  "custom-mod": {
    "source": "Manual"
  }
}
```

This allows the manager to handle updates and removals appropriately.

### LuaJIT Support

All Lua mods require LuaJIT support. The mod manager can download this automatically, or you can:

1. Download `luajit.elf` from the [releases page](https://github.com/CJFWeatherhead/TNI-Mods/releases)
2. Place it directly in the `mods/` directory as `luajit.elf`
3. The game will automatically load LuaJIT before all other mods

### PowerShell Script Alternative

If you prefer running the PowerShell script directly (cross-platform, no compilation):

1. Download [ModManagerGUI.ps1](https://raw.githubusercontent.com/CJFWeatherhead/TNI-Mods/beta/ModManagerGUI.ps1)
2. Run: `powershell.exe -ExecutionPolicy Bypass -File ModManagerGUI.ps1`
3. Or use [ModManager.bat](https://raw.githubusercontent.com/CJFWeatherhead/TNI-Mods/beta/ModManager.bat) for easy launching

The PowerShell version has identical features and works on Windows, Linux, and macOS with PowerShell Core.

## Credits

Created for the Tower Networking Inc modding community.
Compatible with modloader v1.0+.

## License

Free to use, modify, and distribute with your mod packs!
