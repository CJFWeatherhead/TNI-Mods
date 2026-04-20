---
title: "TARDIS - Time Controller"
date: 2026-04-18
draft: false
mod_id: "tardis"
author: "CJFWeatherhead"
version: "0.1.16"
status: "Active Development"
game_version: "beta"
---

# TARDIS - Time Controller

Control game time like a Time Lord! This mod provides keyboard shortcuts to manipulate game speed and skip time.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 0.1.16 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-04-18 |

</div>

---

## Download

<div class="download-section">

**[Download tardis-0.1.16.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/tardis-v0.1.16/tardis-0.1.16.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **TARDIS - Time Controller** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `tardis/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Speed Change Step** | number (0.1-2.0) | `0.5` | Amount to change the speed multiplier when pressing SHIFT+> or SHIFT+< |
| **Minimum Speed** | number (0.125-1.0) | `0.125` | Minimum allowed game speed multiplier (game hard limit is 0.125x) |
| **Maximum Speed** | number (2.0-8.0) | `8.0` | Maximum allowed game speed multiplier (game hard limit is 8x) |
| **Default Speed** | number (0.25-5.0) | `1.0` | Default game speed to use (for reference) |
| **Skip To Time (hours)** | number (0.0-23.99) | `23.99` | Time of day to skip to when pressing SHIFT++ (24-hour format, e.g., 23.99 = 23:59) |
| **Show In-Game Notifications** | boolean | `True` | Display on-screen notifications when speed changes or time skips |
| **Enable Debug Logging** | boolean | `False` | Show detailed debug messages in the console |

---

## About This Mod

Control game time like a Time Lord! This mod provides keyboard shortcuts to manipulate game speed and skip time.

## Features
- **Speed Up**: Press SHIFT+> to increase game speed
- **Slow Down**: Press SHIFT+< to decrease game speed  
- **Skip Day**: Press SHIFT++ to skip to end of current day (23:59)
- **Visual Feedback**: On-screen notifications for all actions
- **Configurable**: Adjust speed step, min/max speed, and more

## Why "TARDIS"?
Like the Doctor's famous time machine, this mod gives you control over the flow of time!

## Usage
- SHIFT+> : Speed up time (like drinking coffee)
- SHIFT+< : Slow down time (like drinking tea)
- SHIFT++ : Skip to end of day

## Configuration
- **Speed Step**: How much to change speed per keypress (default: 0.5x)
- **Min Speed**: Minimum speed multiplier (default: 0.25x)
- **Max Speed**: Maximum speed multiplier (default: 10x)
- **Skip To Time**: What time to skip to (default: 23:59)
- **Show Notifications**: Toggle in-game notifications
- **Debug Logging**: Enable detailed console output

---

<details>
<summary><strong>Full Documentation</strong></summary>

# TARDIS - Time Controller

Control game time like a Time Lord! This mod provides debug console commands to manipulate game speed and skip time in Tower Networking Inc.

## Description

Just like the Doctor's famous time machine (Time And Relative Dimension In Space), this mod gives you control over the flow of time. Speed up boring moments, slow down critical situations, or skip straight to the end of the day.

The game already allows you to speed up time with coffee and slow it down with tea - this mod takes that concept and puts it in the debug console for easy access.

## Features

- **Speed Control**: Increase or decrease game speed via debug console commands
- **Day Skip**: Jump straight to 23:59 (end of day)
- **Visual Feedback**: On-screen notifications for all actions
- **Fully Configurable**: Adjust all parameters via Mod Manager
- **Cooldown Protection**: Prevents accidental rapid-fire key presses

## Installation

1. Place the `tardis` folder in your `Mods/` directory
2. Load or reload the game (F11 to reload mods)
3. You should see "TARDIS mod loaded!" in the console
4. Use debug console commands during gameplay (press `~` to open the console)

## Console Commands

Press `~` to open the debug console, then type a command:

| Command | Action |
|---------|--------|
| **m_speed_up** | Increase game speed by configured step |
| **m_speed_down** | Decrease game speed by configured step |
| **m_speed_reset** | Reset game speed to default |
| **m_day_skip** | Skip to end of day (23:59) |

## Configuration

All settings can be configured through the Mod Manager UI or by editing `entry.lua` directly.

### Speed Settings

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| **Speed Step** | 0.5 | 0.1 - 2.0 | Amount to change speed per keypress |
| **Min Speed** | 0.25 | 0.1 - 1.0 | Minimum speed multiplier |
| **Max Speed** | 10.0 | 2.0 - 50.0 | Maximum speed multiplier |
| **Default Speed** | 1.0 | 0.25 - 5.0 | Reference default speed |

### Time Skip Settings

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| **Skip To Time** | 23.99 | 0.0 - 23.99 | Hour to skip to (24h format) |

### Notification Settings

| Setting | Default | Description |
|---------|---------|-------------|
| **Show Notifications** | true | Display on-screen notifications |
| **Debug Logging** | false | Show detailed console output |

## Examples

### Quick Time Passing
Need to wait for something? Type `m_speed_up` a few times to speed up to 5x or 10x speed, then `m_speed_reset` to return to normal.

### End of Day Skip
Need to close out the day? Type `m_day_skip` to instantly jump to 23:59.

### Slow Motion Analysis
Want to carefully observe something? Type `m_speed_down` to slow down to 0.25x speed.

## Technical Details

- Uses `GameWorld.update_server_timescale()` for speed control
- Uses `DayCycleController.force_day_clock()` for time manipulation
- Speed changes persist until manually changed or game restart
- Console commands registered via `DebugLayer.register_cmd()` (activated automatically on game load)
- Commands: `m_speed_up`, `m_speed_down`, `m_speed_reset`, `m_day_skip`, `m_speed`

## Compatibility

- **Game Version**: Beta
- **Dependencies**: None
- **Conflicts**: May interact unexpectedly with other mods that manipulate game time

## Troubleshooting

### Speed changes don't work
- Ensure the mod is properly loaded (check console for "TARDIS mod loaded!")
- Press `~` to open the debug console and try typing `speed_up`
- Check if another mod might be conflicting

### Day skip doesn't work
- The day skip relies on `DayCycleController` which may not be available in all game modes
- Check the console for error messages
- Try enabling debug logging to see more details

### Notifications don't appear
- Ensure "Show Notifications" is enabled in config
- Some game states may not support notifications

## Changelog

### v0.1.0 (2026-01-31)
- Initial release
- Speed up/down/reset via debug console commands (m_speed_up, m_speed_down, m_speed_reset)
- Day skip via debug console (m_day_skip)
- Configurable parameters
- In-game notifications

## Credits

- **Author**: CJFWeatherhead
- **Inspiration**: Doctor Who's TARDIS, and the in-game tea/coffee time mechanics
- **Thanks**: The TNI modding community

## License

This mod is released under the same license as the TNI-Mods repository.


</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

Uses GameWorld.update_server_timescale() for speed control and DayCycleController.force_day_clock() for time skipping.
Speed changes persist until manually changed or game restart.


</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `tardis` |
| Creation Date | 2026-01-31 |
| Last Updated | 2026-04-18 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/tardis](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/tardis) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/tardis-v0.1.16)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/tardis-v0.1.16/tardis-0.1.16.zip)

</details>

---

[Back to All Mods](/mods/)
