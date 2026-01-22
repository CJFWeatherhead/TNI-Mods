---
title: "Mod Manager - ModManagerGUI.ps1"
date: 2026-01-22
draft: false
---

# Tower Network Inc - PowerShell Mod Manager

A standalone, interactive PowerShell-based mod manager that provides a user-friendly interface for configuring Tower Network Inc mods without needing to edit lua files manually.

## Features

✨ **Interactive Text UI**

- Color-coded menus and status indicators
- Easy keyboard navigation
- Real-time config updates

🎮 **Full Mod Management**

- View all installed mods with metadata
- Enable/disable mods
- Configure all mod parameters with validation

## Requirements

- Windows with PowerShell 5.1+ (built into Windows 10/11)
- OR PowerShell Core 7+ (cross-platform)

## How to Use ModManagerGUI.ps1

### Quick Start

1. **Locate the Mod Manager**
   - The `ModManagerGUI.ps1` file is in the root of this repository
   - Download it or clone the repository to your local machine

2. **Run the GUI**
   ```powershell
   # Navigate to the repository folder
   cd path\to\TNI-Mods
   
   # Run the GUI
   .\ModManagerGUI.ps1
   ```
   
   Or simply double-click `ModManager.bat` for a quick launch!

3. **Navigate the Interface**
   - Use arrow keys to navigate menus
   - Press Enter to select options
   - Follow on-screen prompts to configure mods

### Managing Mods

#### Viewing Installed Mods
The main screen displays all detected mods with:
- Mod name and description
- Current status (Enabled/Disabled)
- Available configuration parameters
- Version and compatibility information

#### Enabling/Disabling Mods
1. Select a mod from the list
2. Choose "Toggle Enable/Disable"
3. The mod will be activated or deactivated for your next game session

#### Configuring Mod Parameters
Each mod can have configurable parameters:

1. **Select a mod** from the main list
2. **Choose "Configure Parameters"**
3. **Set values** for each parameter:
   - **Boolean**: Toggle true/false
   - **Integer/Number**: Enter numeric values (validated against min/max)
   - **String**: Enter text values
   - **Select**: Choose from dropdown options

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

## Advanced Usage

### Command Line Mode

You can script the mod manager for automation:

```powershell
# Load the module
. .\ModManager.ps1

# Get all mods
$mods = Get-InstalledMods

# Load config
$config = Get-ModConfig

# Enable a specific mod
Set-ModEnabled $config "random-warranties" $true

# Set a parameter
Set-ModParameter $config "random-warranties" "warranty_multiplier_max" 50

# Save changes
Save-ModConfig $config
```

### Custom Config Location

Edit these lines at the top of `ModManager.ps1` to use a custom location:

```powershell
$script:ConfigDirectory = "C:\Your\Custom\Path"
$script:ConfigFile = Join-Path $script:ConfigDirectory "mod_config.json"
```

## Troubleshooting

### Common Issues

**Problem**: PowerShell script won't run
- **Solution**: Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` to allow script execution

**Problem**: Mods not detected
- **Solution**: Ensure mods are installed in the correct game directory:
  - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
  - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`

**Problem**: Configuration changes not saving
- **Solution**: Check that you have write permissions to the mods directory

**Problem**: Invalid parameter values
- **Solution**: The mod manager validates all inputs. Check the parameter's min/max values in the mod's metadata

### Checking Your Setup

Verify your PowerShell version:
```powershell
$PSVersionTable
```

Check if mods are in the correct location:
```powershell
# Windows
dir "$env:APPDATA\Godot\app_userdata\Tower Networking Inc\mods"

# Linux (PowerShell Core)
ls ~/.local/share/godot/app_userdata/Tower\ Networking\ Inc/mods/
```

## Support

For issues, questions, or suggestions:

- Check your mod's `metadata.yaml` is valid
- Review the [main README](https://github.com/CJFWeatherhead/TNI-Mods/blob/main/README.md)
- Look at console output for errors
- Report issues on [GitHub](https://github.com/CJFWeatherhead/TNI-Mods/issues)

## Installing Mods

### Using the Mod Manager

The mod manager helps you **configure** installed mods. To **install** new mods:

1. **Download** the mod from its [mod page](/mods/)
2. **Extract** the mod folder to your mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. **Run ModManagerGUI.ps1** to enable and configure the mod

### For Lua Mods

If you're using Lua mods, you'll need the LuaJIT support mod first:

1. Download `luajit.elf` from the [releases page](https://github.com/CJFWeatherhead/TNI-Mods/releases)
2. Place it directly in the `mods/` directory as `luajit.elf`
3. The game will automatically load LuaJIT before all other mods

## Credits

Created for The Tower Network Inc modding community.
Compatible with modloader v1.0+.

## License

Free to use, modify, and distribute with your mod packs!
