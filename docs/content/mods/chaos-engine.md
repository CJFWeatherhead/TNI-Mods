---
title: "Chaos Engine"
date: 2026-04-18
draft: false
mod_id: "chaos-engine"
author: "CJFWeatherhead"
version: "0.1.19"
status: "Active Development"
game_version: "beta"
---

# Chaos Engine

A controlled chaos mod that introduces randomness and unpredictability to Tower Networking Inc

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 0.1.19 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-04-18 |

</div>

---

## Download

<div class="download-section">

**[Download chaos-engine-0.1.19.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/chaos-engine-v0.1.19/chaos-engine-0.1.19.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **Chaos Engine** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `chaos-engine/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Enable Random Floor Spawning** | boolean | `True` | Allow CTRL+SHIFT+F to spawn random floors |
| **Enable Disaster Mode** | boolean | `True` | Allow CTRL+SHIFT+D to toggle disaster mode |
| **Enable User Stat Randomization** | boolean | `True` | Randomize user stats when they spawn |
| **Disaster Event Rate Multiplier** | number (1.5-20.0) | `5.0` | How much to multiply event rates when disaster mode is active |
| **Min Satiety SLA Ratio** | number (0.1-0.9) | `0.3` | Minimum satisfaction threshold users will accept |
| **Max Satiety SLA Ratio** | number (0.2-1.0) | `0.9` | Maximum satisfaction threshold users will accept |
| **Min Eagerness Factor** | integer (1-5) | `1` | Minimum eagerness (lower = more patient) |
| **Max Eagerness Factor** | integer (5-20) | `10` | Maximum eagerness (higher = more demanding) |
| **Min Use Period Multiplier** | number (0.1-1.0) | `0.5` | Minimum multiplier for base use period (lower = more frequent usage) |
| **Max Use Period Multiplier** | number (1.0-5.0) | `2.0` | Maximum multiplier for base use period (higher = less frequent usage) |
| **Min Grace Days** | integer (0-3) | `1` | Minimum initial grace period in days |
| **Max Grace Days** | integer (3-14) | `7` | Maximum initial grace period in days |
| **Min Satiety Decay Ratio** | number (0.05-0.3) | `0.1` | Minimum decay rate (lower = slower satisfaction drop) |
| **Max Satiety Decay Ratio** | number (0.2-1.0) | `0.5` | Maximum decay rate (higher = faster satisfaction drop) |
| **Show In-Game Notifications** | boolean | `True` | Display toast notifications when chaos events trigger |
| **Enable Debug Logging** | boolean | `True` | Show detailed log messages in the console |

---

## About This Mod

A controlled chaos mod that introduces randomness and unpredictability to Tower Networking Inc 
through keyboard-triggered events and automatic stat randomization.

## Features

### Keyboard Shortcuts
All shortcuts use SHIFT combinations:

- **SHIFT+F**: Force spawn a random floor immediately
- **SHIFT+D**: Toggle Disaster Mode (increases event rates)
- **SHIFT+X**: Reset all chaos settings to defaults

### Disaster Mode
When activated, all random event rates (device failures, power outages, power surges, 
worm spawns) are multiplied by a configurable factor. Toggle it off or press reset to 
restore original rates.

### User Stat Randomization
When users spawn, their stats are randomized within configurable ranges:
- Satiety SLA ratio (satisfaction threshold)
- Eagerness factor (how demanding they are)
- Base use period (how often they use services)
- Initial grace days (forgiveness period)
- Max satiety decay ratio (how fast satisfaction drops)

Note: Daily rate is NOT modified as it may conflict with other mods.

## Usage

1. Load the mod and start a game
2. Press SHIFT+D to activate Disaster Mode for intense chaos
3. Press SHIFT+F to spawn random floors
4. Press SHIFT+X to reset everything back to normal

---

<details>
<summary><strong>Full Documentation</strong></summary>

# Chaos Engine

A controlled chaos mod that introduces randomness and unpredictability to Tower Networking Inc through keyboard-triggered events and automatic stat randomization.

## Description

Chaos Engine lets you shake things up in your tower with debug console commands that trigger random events, plus automatic randomization of user stats for unpredictable gameplay.

## Features

### Console Commands

Press `~` to open the debug console, then type a command:

| Command | Action |
|---------|--------|
| **m_random_floor** | Force spawn a random floor immediately |
| **m_disaster** | Toggle Disaster Mode on/off |
| **m_chaos_reset** | Reset all chaos settings to defaults |

### Disaster Mode

When activated (`m_disaster`), all random event rates are multiplied:

- Device failures
- Power outages
- Power surges  
- Worm spawns

The multiplier is configurable (default 5x). Run `m_chaos_reset` to restore original rates.

### User Stat Randomization

When users spawn, their stats are randomized within configurable ranges:

| Stat | Description | Default Range |
|------|-------------|---------------|
| Satiety SLA Ratio | Satisfaction threshold | 0.3 - 0.9 |
| Eagerness Factor | How demanding they are | 1 - 10 |
| Base Use Period | Service usage frequency | 0.5x - 2.0x |
| Grace Days | Initial forgiveness period | 1 - 7 days |
| Satiety Decay | Satisfaction drop rate | 0.1 - 0.5 |

**Note**: Daily rate is intentionally NOT modified to avoid conflicts with other mods.

## Installation

1. Place the `chaos-engine` folder in your `Mods/` directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
2. Load or reload the game (F11 to reload mods)
3. You should see "Chaos Engine mod loaded!" in the console

## Usage

### Quick Start

1. Start a game
2. Press `~` to open the debug console, type **m_disaster** - watch events increase!
3. Type **m_random_floor** to spawn a random new floor
4. Type **m_chaos_reset** to calm things down

### Gameplay Modes

#### Survival Mode
- Enable Disaster Mode with high multiplier (10-20x)
- See how long you can keep your tower running

#### Expansion Challenge
- Run `m_random_floor` repeatedly to rapidly expand
- Try to manage the influx of random floors

#### Pure Chaos
- Enable everything with extreme settings
- Sit back and watch the mayhem

## Configuration

Access the Mod Manager to configure each feature:

### Feature Toggles
| Setting | Default | Description |
|---------|---------|-------------|
| Enable Random Floors | On | Enable m_random_floor command |
| Enable Disaster Mode | On | Enable m_disaster command |
| Enable User Randomization | On | Randomize user stats |

### Disaster Mode
| Setting | Default | Description |
|---------|---------|-------------|
| Event Rate Multiplier | 5.0 | How much to multiply rates |

### User Randomization
All user stats have configurable min/max ranges.

## Technical Details

### Hooks Used
- `on_engine_load()` - Initialization and storing original rates
- `on_mod_reload()` - Re-initialization on F11
- `on_user_spawned()` - User stat randomization
- `on_day_start()` / `on_day_end()` - Day cycle events

Console commands registered via `DebugLayer.register_cmd()` (activated automatically on game load).

### State Management
- Original event rates are stored on first load
- Disaster mode state is tracked and can be toggled
- Reset function restores all original values

## Troubleshooting

### Commands not working
- Press `~` to open the debug console
- Check that the mod is loaded (look for "Chaos Engine mod loaded!" in console)
- Verify the feature is enabled in config

### Disaster mode not resetting
- Type `m_chaos_reset` in the console to force reset
- Reload mod with F11

### Floors not spawning
- Check console for error messages
- Some game states may prevent floor spawning
- The mod will log detailed information about available floor builders

## Changelog

### v0.1.0 (2026-01-31)
- Initial release
- Random floor spawning (`m_random_floor` console command)
- Disaster mode toggle (`m_disaster` console command)
- Reset function (`m_chaos_reset` console command)
- User stat randomization (excludes daily_rate)

## License

See the main repository LICENSE file.

## Credits

- Author: CJFWeatherhead
- Part of the TNI-Mods collection


</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

This mod uses SHIFT key combinations.
Original event rates are stored and can be restored with the reset function.


</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `chaos-engine` |
| Creation Date | 2026-01-31 |
| Last Updated | 2026-04-18 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/chaos-engine](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/chaos-engine) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/chaos-engine-v0.1.19)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/chaos-engine-v0.1.19/chaos-engine-0.1.19.zip)

</details>

---

[Back to All Mods](/mods/)
