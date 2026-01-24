---
title: "Money Cheat"
date: 2026-01-21
draft: false
mod_id: "money-cheat"
author: "CJFWeatherhead"
status: "Active Development"
game_version: "beta"
---

# Money Cheat

Simple money cheat mod that adds a configurable amount of money when you press SHIFT+M.

## Features
- Instant money injection via keyboard shortcut (SHIFT+M)
- Configurable amount (default: $10,000)
- Console feedback on activation
- Optional in-game notifications
- Cooldown protection to prevent accidental double-activation

## Usage
Press SHIFT+M during gameplay to add money to your balance.
Configure the amount in the Mod Manager settings.

## Configuration
- **Money Amount**: The amount to add when activated (default: $10,000)
- **Debug Logging**: Show detailed console messages
- **Show Notification**: Attempt to display in-game notification


## Mod Information

- **Author**: CJFWeatherhead
- **Development Status**: Active Development
- **Game Version**: beta
- **Last Updated**: 2026-01-21
- **Website**: [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/money-cheat](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/money-cheat)

## Download

**[Download Money Cheat](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/money-cheat)**

### Installation Instructions

#### Option 1: Using Mod Manager (Recommended)

1. Download and run the [Mod Manager](/mods/tools/modmanager/)
2. Find **Money Cheat** in the Available mods list
3. Click **Download** to automatically install from GitHub releases
4. Configure parameters using the graphical interface

#### Option 2: Manual Installation

1. Download the mod from the [GitHub releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)
2. Extract to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed
4. (Optional) Use [Mod Manager](/mods/tools/modmanager/) to configure

## Configuration Parameters

This mod can be configured using the [Mod Manager](/mods/tools/modmanager/). Available parameters:

### Money Amount

- **Parameter Name**: `money_amount`
- **Type**: integer
- **Default**: `10000`
- **Min**: 100
- **Max**: 10000000

Amount of money to add when SHIFT+M is pressed

### Enable Debug Logging

- **Parameter Name**: `debug_logging`
- **Type**: boolean
- **Default**: `True`

Log detailed information to console when cheat is activated

### Show In-Game Notification

- **Parameter Name**: `show_notification`
- **Type**: boolean
- **Default**: `True`

Attempt to show an in-game notification when money is added (may not be supported by all game versions)

---

## Detailed Documentation

# Money Cheat

Simple money cheat mod for The Network Inc that adds configurable amounts of money via keyboard shortcut.

## Description

This mod provides a quick and easy way to add money to your balance during gameplay. Simply press SHIFT+M to instantly receive a configurable amount of money. Perfect for testing, experimenting with game mechanics, or just having fun without financial constraints.

## Features

- **Keyboard Shortcut**: Press SHIFT+M to activate the cheat
- **Configurable Amount**: Set any amount from $100 to $10,000,000 (default: $10,000)
- **Console Feedback**: Confirmation messages when cheat is activated
- **In-Game Notifications**: Optional visual notifications (if supported)
- **Cooldown Protection**: 0.5-second cooldown prevents accidental double-activation
- **Debug Logging**: Optional detailed logging for troubleshooting

## Installation

1. Place the `money-cheat` folder in your `Mods/` directory
2. Load or reload the game (F11 to reload mods)
3. You should see "Money Cheat mod loaded!" in the console
4. Press SHIFT+M during gameplay to activate

## Usage

### Activating the Cheat

During gameplay, simply press and hold **SHIFT** then press **M**. You'll see a confirmation message in the console and receive the configured amount of money.

### Configuration

The mod can be configured through the Mod Manager UI or by editing the `entry.lua` file directly.

#### Available Settings

- **Money Amount** (default: 10000)
  
  - Amount of money to add when SHIFT+M is pressed
  - Range: $100 to $10,000,000
  - Recommended: $10,000 for moderate funding, $1,000,000 for unlimited gameplay

- **Debug Logging** (default: true)
  
  - Enable detailed console messages
  - Shows confirmation when cheat is activated
  - Displays configuration on mod load

- **Show Notification** (default: true)
  
  - Attempts to show in-game notification when money is added
  - Falls back to console messages if not supported by game version

### Examples

**Small boost for tight situations:**

- Set Money Amount to $1,000

**Moderate funding (default):**

- Set Money Amount to $10,000

**Major financial injection:**

- Set Money Amount to $100,000

**Essentially unlimited funds:**

- Set Money Amount to $1,000,000+

## Technical Details

### Hooks Used

- `on_engine_load()`: Initialize mod and display configuration
- `on_mod_reload()`: Reload configuration when F11 is pressed
- `on_key_pressed()`: Detect SHIFT+M keyboard combination
- `on_tick()`: Reserved for future input polling if needed

### How It Works

The mod tracks the state of the SHIFT key and listens for the M key press. When both are detected simultaneously, it uses the game's `modify_player_cash()` API to add money to the player's balance with the category set to INCOME.

A 0.5-second cooldown prevents accidental double-activation if you hold the keys too long.

### Configuration System

This mod uses the standardized `===== MOD CONFIGURATION START/END =====` marker system, making it compatible with automated Mod Manager tools for graphical configuration.

## Compatibility

- **Game Version**: 0.10.0
- **Dependencies**: None
- **API Requirements**: ModApiV1, on_key_pressed hook

## Troubleshooting

### Cheat doesn't activate when pressing SHIFT+M

1. Check that the mod is loaded (look for "Money Cheat mod loaded!" in console)
2. Ensure you're in-game, not in menus
3. Try pressing the keys separately: hold SHIFT, then tap M once
4. Enable debug logging to see if key presses are being detected

### No confirmation message appears

1. Check that debug_logging is enabled in configuration
2. Verify the console is visible and not filtered
3. Look for error messages that might indicate API issues

### Money isn't being added

1. Verify the game world is active (you're in a game, not menu)
2. Check for error messages in console
3. Ensure the ModApiV1 is available (should show on mod load)

## Author

CJFWeatherhead

## Development Status

Active Development

## License

See LICENSE file in the root directory.

## Notes

This mod is intended for fun and experimentation. Using cheats may impact your gameplay experience and sense of achievement. Use responsibly!


---

## Additional Notes

Uses on_key_pressed hook to detect SHIFT+M keyboard combination. Includes 0.5s cooldown to prevent accidental double-activation.

---

[← Back to All Mods](/mods/)
