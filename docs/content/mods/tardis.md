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

Control game time like a Time Lord! Preset-based speed control and time manipulation via the debug console — plus an optional floating UI panel with clickable buttons — in Tower Networking Inc.

## Description

Just like the Doctor's famous time machine (Time And Relative Dimension In Space), this mod gives you control over the flow of time. Speed up boring moments, slow down critical situations, skip straight to the end of the day, or freeze time entirely.

v2.1 adds a **clickable UI panel** — type `m_panel` once and you get a floating overlay with buttons for every action. No more typing commands repeatedly.

v2.0 was a cleanroom rewrite. Speed changes use **fixed presets** (0.125x – 8x) instead of arithmetic steps, eliminating the float-drift inconsistencies that affected v1. The hotkey-based input approach from earlier versions was replaced with debug console commands — hotkeys required per-frame or per-input callbacks that caused garbage-collection exhaustion over time.

## Features

- **Speed Presets**: Cycle through 0.125x, 0.25x, 0.5x, 1x, 2x, 4x, 8x
- **Clickable UI Panel**: Floating overlay with buttons — toggle with `m_panel`
- **Day Skip**: Jump to a configurable time of day (default 23:59)
- **Pause / Resume**: Freeze and unfreeze the day cycle
- **Auto-Reset**: Optionally reset speed to default at the start of each day
- **Visual Feedback**: On-screen notifications for all actions
- **Fully Configurable**: Adjust settings via Mod Manager

## Installation

1. Place the `tardis` folder in your `Mods/` directory
2. Load or reload the game (F11 to reload mods)
3. You should see `[tardis] TARDIS mod loaded` in the console
4. Press **~** to open the debug console and type a command

## Console Commands

Press **~** to open the debug console, then type a command:

| Command | Action |
|-------------|----------------------------------------------|
| `m_faster`  | Step up to the next speed preset             |
| `m_slower`  | Step down to the previous speed preset       |
| `m_normal`  | Reset to default speed (1x)                  |
| `m_skip`    | Skip to end of day (configurable)            |
| `m_pause`   | Toggle day-cycle pause / resume              |
| `m_time`    | Show current speed, day, time, and pause state |
| `m_panel`   | Toggle the clickable UI panel                  |

### Global Aliases

These work as direct Lua calls in the console as well:

| Alias | Equivalent |
|---------------|------------|
| `faster()`    | m_faster   |
| `slower()`    | m_slower   |
| `normal()`    | m_normal   |
| `skip()`      | m_skip     |
| `time_pause()`| m_pause    |
| `time_status()`| m_time    |
| `panel()`   | m_panel    |

Legacy v1 aliases (`speed_up`, `speed_down`, `speed_reset`, `day_skip`, `speed`) are still supported.

## Configuration

All settings can be configured through the Mod Manager UI or by editing the `config` table in `entry.lua`.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| **Default Speed** | 1.0 | 0.125 – 8.0 | Speed to reset to with `m_normal` (snapped to nearest preset) |
| **Skip To Time** | 23.99 | 0.0 – 23.99 | Hour to skip to in 24h decimal format |
| **Auto Reset On Day Start** | false | — | Reset speed to default at the start of each new day |
| **Show Notifications** | true | — | Display on-screen notifications |
| **Debug Logging** | false | — | Show detailed console output |

### Speed Presets

The mod uses a fixed set of speed multipliers that match the game engine's hard limits:

```
0.125x → 0.25x → 0.5x → 1x → 2x → 4x → 8x
```

`m_faster` steps right, `m_slower` steps left. The current preset is synced from the live game timescale before each operation, so it always reflects the real engine state even if another mod or the game itself changed the speed.

## Examples

### Quick Time Passing
Type `m_faster` a few times to reach 4x or 8x speed, then `m_normal` to return to 1x.

### End of Day Skip
Type `m_skip` to jump straight to 23:59.

### Freeze Time
Type `m_pause` to freeze the day cycle. Type `m_pause` again to resume.

### Automatic Reset
Enable **Auto Reset On Day Start** in the config. Speed returns to 1x at the start of each new day — useful when you speed up to skip a day but want normal speed the next morning.

### UI Panel
Type `m_panel` in the debug console to open a floating panel with buttons for Slower, Faster, Pause, Reset, and Skip Day. The panel shows a live status line (speed, time, day, pause state) that updates after each action. Click **X** to hide it, or type `m_panel` again to toggle.

## Technical Details

- Uses `GameWorld.update_server_timescale()` for speed control
- Uses `DayCycleController.force_day_clock()` for time skip
- Uses `DayCycleController.pause_timer()` / `resume_timer()` for pause
- Reads `DayCycleController.paused` for live pause state (no internal tracking)
- Syncs `current_preset_idx` from `world.time_mult` before each step operation
- Console commands registered via `DebugLayer.register_cmd()` in `on_game_state_ready`
- Auto-reset uses `on_day_start` callback — zero per-frame cost
- No `on_player_input` or `on_tick` callbacks — avoids GC pressure entirely
- UI panel built with `create_node()` — CanvasLayer > PanelContainer > VBoxContainer > Buttons
- Button signals (`"pressed"`) connected directly to Lua functions via `Object.connect()`
- Panel attached to `Mod` node (sandbox) for automatic cleanup; also destroyed on F11 reload

## Compatibility

- **Game Version**: 0.10.7+
- **Dependencies**: `luajit-support ~0.2.0`
- **Conflicts**: May interact unexpectedly with other mods that manipulate game time

## Troubleshooting

### Speed changes don't seem to apply
- Ensure the mod loaded (check console for `[tardis] TARDIS mod loaded`)
- Press ~ and type `m_time` to see the live engine state
- Enable debug logging to see detailed sync and apply messages

### Day skip doesn't work
- The day skip relies on `DayCycleController` which may not be available in all game modes
- Check the console for error messages after typing `m_skip`

### Notifications don't appear
- Ensure **Show Notifications** is enabled in config
- Some game states may not support the notification UI

### Commands not registered
- If `m_faster` etc. don't work in the debug console, the global aliases (`faster()`, `slower()`, etc.) should still work as direct Lua calls

### UI panel doesn't appear
- The panel uses `create_node()` to build Godot UI nodes at runtime — this is experimental
- If `m_panel` reports a failure, check the console error for details
- All console commands still work regardless of whether the panel loads
- Try enabling debug logging to see the panel build status

## Changelog

### v2.1.0 (2026-04-20)
- Added **clickable UI panel** — floating overlay with buttons, toggled via `m_panel`
- Panel shows live status (speed, time, day, pause state) updated after each action
- Panel built with Godot UI nodes (CanvasLayer, PanelContainer, VBoxContainer, Button)
- Button press signals wired to Lua functions — experimental, first Lua mod to do this
- Added `panel()` global alias
- Panel cleaned up on mod reload (F11) and closeable via X button

### v2.0.0 (2026-04-20)
- **Cleanroom rewrite** — all logic reimplemented from scratch
- Replaced arithmetic step-based speed (source of float-drift inconsistencies) with fixed preset cycling
- Removed `on_player_input` / hotkey approach (caused GC exhaustion)
- Added `m_pause` command (day-cycle pause/resume via `DayCycleController`)
- Added `m_time` command (full status display)
- Added **auto-reset on day start** option using `on_day_start` callback
- Syncs preset index from live `world.time_mult` before each operation
- Renamed commands: `m_speed_up` → `m_faster`, `m_speed_down` → `m_slower`, `m_speed_reset` → `m_normal`, `m_day_skip` → `m_skip`
- Legacy v1 global aliases preserved for backward compatibility
- Reduced config surface: removed `speed_step`, `min_speed`, `max_speed` (presets cover the full game range)

### v0.1.0 (2026-01-31)
- Initial release

## Credits

- **Author**: CJFWeatherhead
- **Inspiration**: Doctor Who's TARDIS, and the in-game tea/coffee time mechanics

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
