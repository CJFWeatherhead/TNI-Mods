---
title: "Money Cheat"
date: 2026-01-31
draft: false
mod_id: "money-cheat"
author: "CJFWeatherhead"
version: "0.1.5"
status: "Active Development"
game_version: "beta"
---

# Money Cheat

Simple money cheat mod that adds a configurable amount of money when you press SHIFT+M.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 0.1.5 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-01-31 |

</div>

---

## Download

<div class="download-section">

**[Download money-cheat-0.1.5.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/money-cheat-v0.1.5/money-cheat-0.1.5.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **Money Cheat** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `money-cheat/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Money Amount** | integer (100-10000000) | `10000` | Amount of money to add when SHIFT+M is pressed |
| **Enable Debug Logging** | boolean | `True` | Log detailed information to console when cheat is activated |
| **Show In-Game Notification** | boolean | `True` | Attempt to show an in-game notification when money is added (may not be supported by all game versions) |

---

## About This Mod

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

---

<details>
<summary><strong>Full Documentation</strong></summary>

# Money Cheat

Simple money cheat mod for Tower Networking Inc that adds configurable amounts of money via keyboard shortcut.

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

This mod uses the standardized `===== MOD CONFIGURATION START/END =====` marker system, making it compatible with automated Mod Manager tools. The `ui-config.ps1` file provides UI parameter definitions for graphical configuration interfaces.

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


</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

Uses on_key_pressed hook to detect SHIFT+M keyboard combination. Includes 0.5s cooldown to prevent accidental double-activation.

</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `money-cheat` |
| Creation Date | 2026-01-21 |
| Last Updated | 2026-01-31 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/money-cheat](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/money-cheat) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/money-cheat-v0.1.5)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/money-cheat-v0.1.5/money-cheat-0.1.5.zip)

</details>

---

[Back to All Mods](/mods/)
