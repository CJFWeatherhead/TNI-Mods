# The Network Inc - PowerShell Mod Manager

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



## Configuration Location

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

## ## Parameter Types Supported

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

### Run Without GUI (Command Line)

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
Set-ModParameter $config "tweaktower" "starting_cash_multiplier" 20.0

# Save changes
Save-ModConfig $config
```

### Custom Config Location

Edit these lines at the top of `ModManager.ps1`:

```powershell
$script:ConfigDirectory = "C:\Your\Custom\Path"
$script:ConfigFile = Join-Path $script:ConfigDirectory "mod_config.json"
```





## Support

For issues, questions, or suggestions:

- Check your mod's `metadata.yaml` is valid
- Verify PowerShell version: `$PSVersionTable`
- Look at console output for errors

## Credits

Created for The Network Inc modding community.
Compatible with modloader v1.0+.

## License

Free to use, modify, and distribute with your mod packs!
