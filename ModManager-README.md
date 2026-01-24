# The Network Inc - Mod Manager v3.0

A modern WPF-based graphical mod manager for Tower Network Inc that can download mods directly from GitHub releases and manage local mod installations.

## Features

🌐 **GitHub Integration**
- Browse and download mods directly from the TNI-Mods repository
- Automatic version checking for installed mods
- One-click updates when new versions are available
- Progress bar during downloads

🎮 **Full Mod Management**
- View all installed and available mods
- Visual distinction between mod sources (Downloaded, Manual, Available)
- Enable/disable manually installed mods
- Remove downloaded mods with one click
- Configure all mod parameters with validation

📁 **Smart Mod Handling**
- **Downloaded mods**: Installed from GitHub releases, removed completely when uninstalled
- **Manual mods**: Installed by hand, moved to disabled folder when disabled

⌨️ **Command Aliases**
- Create and manage in-game command shortcuts
- Edit existing aliases or add new ones
- Saved to game settings

## Requirements

- Windows with PowerShell 5.1+ (built into Windows 10/11)
- OR PowerShell Core 7+ (cross-platform)
- .NET Framework 4.5+ (for WPF GUI)
- Internet connection (for downloading mods from GitHub)

## Quick Start

1. **Double-click** `ModManager.bat` to launch
2. The manager will fetch available mods from GitHub
3. **Browse** the mod list - use filters (All/Installed/Available)
4. **Click** on any mod to see details
5. **Download** available mods or **configure** installed ones
6. **Launch** the game directly from the manager

## Mod Sources

The manager distinguishes between three types of mods:

| Source | Color | Description |
|--------|-------|-------------|
| **Downloaded** | Blue | Installed from GitHub releases. Removed completely when uninstalled. |
| **Manual** | Purple | Installed manually by copying files. Moved to disabled folder when disabled. |
| **Available** | Gray | Not installed yet. Can be downloaded from GitHub. |

## Configuration

### Mod Parameters

Each installed mod may have configurable parameters. The manager:

1. Reads current values from the mod's `entry.lua` file
2. Displays controls based on parameter type (boolean, number, select, etc.)
3. Saves changes back to the `entry.lua` configuration section

Changes update the configuration section between the markers:

```lua
-- ===== MOD CONFIGURATION START =====
local config = { ... }
-- ===== MOD CONFIGURATION END =====
```

### Mod Cache

The manager tracks which mods were downloaded vs manually installed in:

```
%APPDATA%\Godot\app_userdata\Tower Networking Inc\mod_cache.json
```

### Game Settings

Command aliases are stored in the game's settings file:

```
%APPDATA%\Godot\app_userdata\Tower Networking Inc\settings.json
```

## Directory Structure

```
%APPDATA%\Godot\app_userdata\Tower Networking Inc\
├── Mods/                    # Enabled mods
│   ├── money-cheat/
│   ├── 2x-bandwidth-switches/
│   └── ...
├── Mods_Disabled/           # Disabled manual mods
│   └── ...
├── mod_cache.json           # Tracks mod sources and versions
└── settings.json            # Game settings including aliases
```

## Parameter Types

| Type | Control | Description |
|------|---------|-------------|
| `boolean` | Checkbox | True/false toggle |
| `integer` | Slider + TextBox | Whole numbers with min/max |
| `number` | Slider + TextBox | Decimal numbers with step |
| `string` | TextBox | Free-form text |
| `select` | Dropdown | Choose from predefined options |

## Troubleshooting

### Mods not showing up
- Make sure mods are in the correct directory
- Each mod needs a valid `metadata.yaml` file
- Click "Refresh Mods" to rescan

### Download fails
- Check your internet connection
- GitHub API may have rate limits - wait a few minutes
- Check the console output for error details

### Parameters not saving
- Ensure the mod's `entry.lua` has the configuration markers
- Check that the file is not read-only

### GUI doesn't launch
- Verify PowerShell version: `$PSVersionTable.PSVersion`
- Try running directly: `powershell -File ModManagerGUI.ps1`
- Check for error messages in the console

## Support

For issues, questions, or suggestions:
- Check the console output for detailed error messages
- Verify mod metadata files are valid YAML
- Report issues on the GitHub repository

## Credits

Created for The Network Inc modding community.
Compatible with modloader v1.0+.

## License

Free to use, modify, and distribute with your mod packs!
