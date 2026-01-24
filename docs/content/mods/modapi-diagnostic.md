---
title: "ModAPI Diagnostic Tool"
date: 2026-01-20
draft: false
mod_id: "modapi-diagnostic"
author: "CJFWeatherhead"
status: "Active Development"
game_version: "beta"
---

# ModAPI Diagnostic Tool

Comprehensive diagnostic and inspection tool for TNI game engine callbacks and API endpoints.

## Features
- **Engine Event Logging**: Tracks engine load, mod reload, and game lifecycle events
- **Device Spawn Inspection**: Logs detailed device properties and network configuration
- **User Spawn Analysis**: Comprehensive user property inspection with network/DNS details
- **Re-inspection Capability**: Press Shift+R to re-inspect all spawned users
- **Network Configuration Monitoring**: Track DHCP settings, IP addresses, and DNS servers
- **Safe Error Handling**: Protected table dumps and property access
- **Console Integration**: Call `reinspect_all_users()` from Lua console

## Use Cases
- Debug mod development issues
- Understand game object structures
- Inspect network configurations
- Track user and device properties
- Test API endpoints and callbacks
- Learn the game engine's behavior

## Logged Events
- `on_engine_load()` - Initial engine startup
- `on_mod_reload()` - When F11 is pressed
- `on_device_spawned()` - Device creation with full network config
- `on_user_spawned()` - User creation with location and network details
- `on_day_start()` / `on_day_end()` - Day cycle events
- Input events (Shift+R hotkey)

## Output
All diagnostic information is printed to the game console. Use the in-game console
to view detailed logs and object structures.


## Mod Information

- **Author**: CJFWeatherhead
- **Development Status**: Active Development
- **Game Version**: beta
- **Last Updated**: 2026-01-20
- **Website**: [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/modapi-diagnostic](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/modapi-diagnostic)

## Download

**[Download ModAPI Diagnostic Tool](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/modapi-diagnostic)**

### Installation Instructions

#### Option 1: Using Mod Manager (Recommended)

1. Download and run the [Mod Manager](/mods/tools/modmanager/)
2. Find **ModAPI Diagnostic Tool** in the Available mods list
3. Click **Download** to automatically install from GitHub releases
4. Configure parameters using the graphical interface

#### Option 2: Manual Installation

1. Download the mod from the [GitHub releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)
2. Extract to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed
4. (Optional) Use [Mod Manager](/mods/tools/modmanager/) to configure

---

## Detailed Documentation

# ModAPI Diagnostic Tool

THIS MOD IS FOR MOD DEVELOPERS!

This mod provides comprehensive diagnostic capabilities for The Network Inc's mod system, including detailed inspection of spawned objects and their properties.

## Purpose

- Enumerate all methods available on ModApiV1
- Test various possible callback function names
- Inspect user network configurations in detail
- Track spawned users for re-inspection after manual changes
- Determine when game world and PlayOptions become accessible
- Discover the correct timing to modify game settings

## Usage

1. Place in `lua/modapi-diagnostic/`
2. Load the game and check console output
3. Look for `[DIAGNOSTIC]` prefixed messages
4. Note which callbacks are actually invoked

### Keyboard Shortcuts

- **Shift+R**: Re-inspect all spawned users (useful after manually setting DNS or other network configs)

### Console Commands

You can also use the Lua console to manually trigger inspection:

- `reinspect_all_users()` - Re-inspects all tracked users and displays their current network configuration

## What It Tests

### Callbacks Tested:

- on_engine_load()
- on_mod_reload()
- on_world_ready()
- on_world_created()
- on_game_start()
- on_scenario_start()
- on_world_init()
- on_playoptions_init()
- on_play_options_created()
- before_world_create()
- on_device_spawned()
- on_user_spawned()
- on_day_start()
- on_day_end()
- on_player_input() (for keyboard shortcuts)

### User Network Inspection

When users spawn, the tool automatically inspects:

- User hardware address
- DHCP mode setting
- Network address
- DNS server array (attempts multiple read methods)
- Location properties (floor number, etc.)

Users are tracked in memory, allowing re-inspection after manual configuration changes via console commands like `net dns set @f0/dns1 @f0/dns2 on <hwaddr>`.

### API Methods Checked:

- ModApiV1 availability and methods
- Mod global
- Engine global
- When get_game_world() returns valid data
- When play_options becomes accessible


---

## Additional Notes

This is a developer tool for mod creators. No gameplay impact.

---

[← Back to All Mods](/mods/)
