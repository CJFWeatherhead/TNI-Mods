---
title: "Money Cheat"
date: 2026-04-21
draft: false
mod_id: "money-cheat"
author: "CJFWeatherhead"
version: "5.0.1"
status: "Active Development"
game_version: "beta"
---

# Money Cheat

Instantly add money and restock merchants via keyboard shortcuts.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 5.0.1 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-04-21 |

</div>

---

## Download

<div class="download-section">

**[Download money-cheat-5.0.1.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/money-cheat-v5.0.1/money-cheat-5.0.1.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

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
| **Enable Debug Logging** | boolean | `False` | Log detailed information to console when shortcuts are activated |

---

## About This Mod

Instantly add money and restock merchants via keyboard shortcuts.

## Keyboard Shortcuts
- **SHIFT+M**: Add a configurable amount of money to your cash balance
- **SHIFT+R**: Instantly restock all merchants

## Features
- Configurable money amount (default: $10,000)
- Console feedback on every activation
- No panels, no console commands — keyboard shortcuts only

## Configuration
- **Money Amount**: The amount to add per SHIFT+M press (default: $10,000)
- **Debug Logging**: Show detailed console messages

---

<details>
<summary><strong>Full Documentation</strong></summary>

# Money Cheat

Simple money cheat mod for Tower Networking Inc that adds configurable amounts of money via debug console command.

## Description

This mod provides a quick and easy way to add money to your balance during gameplay. Simply type `money` in the debug console (press `~`) to instantly receive a configurable amount of money. Perfect for testing, experimenting with game mechanics, or just having fun without financial constraints.

## Features

- **Debug Console Command**: Type `m_money` in the debug console to activate the cheat
- **Configurable Amount**: Set any amount from $100 to $10,000,000 (default: $10,000)
- **Console Feedback**: Confirmation messages when cheat is activated
- **In-Game Notifications**: Optional visual notifications (if supported)
- **Cooldown Protection**: 0.5-second cooldown prevents accidental double-activation
- **Debug Logging**: Optional detailed logging for troubleshooting

## Installation

1. Place the `money-cheat` folder in your `Mods/` directory
2. Load or reload the game (F11 to reload mods)
3. You should see "Money Cheat mod loaded!" in the console
4. Press `~` during gameplay to open the debug console, then type `money`

## Usage

### Activating the Cheat

During gameplay, press `~` to open the debug console, then type `money` and press Enter. You'll see a confirmation message in the console and receive the configured amount of money.

### Configuration

The mod can be configured through the Mod Manager UI or by editing the `entry.lua` file directly.

#### Available Settings

- **Money Amount** (default: 10000)
  
  - Amount of money to add when the money console command is run

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

### How It Works

The mod registers a `m_money` command via `DebugLayer.register_cmd()`. When the command is run it uses the game's `modify_player_cash()` API to add money to the player's balance with the category set to INCOME.

### Configuration System

This mod uses the standardized `===== MOD CONFIGURATION START/END =====` marker system, making it compatible with automated Mod Manager tools. The `ui-config.ps1` file provides UI parameter definitions for graphical configuration interfaces.

## Compatibility

- **Game Version**: 0.10.0
- **Dependencies**: None
- **API Requirements**: ModApiV1, DebugLayer (activated automatically)

## Troubleshooting

### Cheat doesn't activate

1. Check that the mod is loaded (look for "Money Cheat mod loaded!" in console)
2. Press `~` to open the debug console — it should appear on screen
3. Type `m_money` and press Enter
4. Enable debug logging to see more detail if needed

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

Uses on_player_input hook to detect SHIFT+M (money) and SHIFT+R (restock) keyboard combinations. Restock functionality was moved here from device-tweaker in v5.0.0.

</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `money-cheat` |
| Creation Date | 2026-01-21 |
| Last Updated | 2026-04-21 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/mods/money-cheat](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/mods/money-cheat) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/money-cheat-v5.0.1)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/money-cheat-v5.0.1/money-cheat-5.0.1.zip)

</details>

---

[Back to All Mods](/mods/)
