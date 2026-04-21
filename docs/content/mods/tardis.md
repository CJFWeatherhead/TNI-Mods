---
title: "TARDIS - Time Controller"
date: 2026-04-21
draft: false
mod_id: "tardis"
author: "CJFWeatherhead"
version: "4.0.1"
status: "Active Development"
game_version: "beta"
---

# TARDIS - Time Controller

Control game time like a Time Lord! Preset-based speed control and time manipulation via keyboard shortcuts.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 4.0.1 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-04-21 |

</div>

---

## Download

<div class="download-section">

**[Download tardis-4.0.1.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/tardis-v4.0.1/tardis-4.0.1.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

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
| **Default Speed** | number (0.125-8.0) | `1.0` | Speed preset to reset to when pressing SHIFT+N (snapped to nearest preset in the ladder) |
| **Skip To Time (decimal hours)** | number (0.0-23.99) | `23.99` | Time of day to skip to when pressing SHIFT+K (24-hour decimal, e.g. 23.99 = 23:59) |
| **Auto Reset Speed On Day Start** | boolean | `False` | Automatically reset game speed to the default preset at the start of each new day |
| **Enable Debug Logging** | boolean | `False` | Show detailed debug messages in the console when shortcuts are used |

---

## About This Mod

Control game time like a Time Lord! Preset-based speed control and time manipulation via keyboard shortcuts.

## Keyboard Shortcuts (hold SHIFT)
- **SHIFT+>** : Step up to next speed preset
- **SHIFT+<** : Step down to previous speed preset
- **SHIFT+N** : Reset to default speed
- **SHIFT+K** : Skip to end of day (configurable time)
- **SHIFT+P** : Toggle day cycle pause / resume
- **SHIFT+T** : Print current speed, day number, and time to console

## Speed Presets
Fixed preset ladder: 0.125x, 0.25x, 0.5x, 1x, 2x, 4x, 8x (game hard limits)

## Configuration
- **Default Speed**: preset to snap to when pressing SHIFT+N (default: 1x)
- **Skip To Time**: decimal hour to skip to with SHIFT+K (default: 23.99 = 23:59)
- **Auto Reset On Day Start**: automatically reset speed each new day
- **Debug Logging**: enable detailed console output

## Why "TARDIS"?
Like the Doctor's famous time machine, this mod gives you control over the flow of time!

## Notes
- No panels, no console commands — keyboard shortcuts only
- Speed preset is synced from the game on load

---

<details>
<summary><strong>Full Documentation</strong></summary>

# TARDIS - Time Controller

Control game time like a Time Lord! Preset-based speed control and time manipulation via the debug console and shared ModPanels UI in Tower Networking Inc.

## Description

Just like the Doctor's famous time machine (Time And Relative Dimension In Space), this mod gives you control over the flow of time. Speed up boring moments, slow down critical situations, skip straight to the end of the day, or freeze time entirely.

v2.3 migrates to the **shared ModPanels framework** (provided by supa-mod-loader). Type `m_panels` to open a sidebar with buttons for every mod that supports it. TARDIS adds speed, pause, reset, and skip-day controls.

v2.0 was a cleanroom rewrite. Speed changes use **fixed presets** (0.125x – 8x) instead of arithmetic steps, eliminating the float-drift inconsistencies that affected v1. The hotkey-based input approach from earlier versions was replaced with debug console commands — hotkeys required per-frame or per-input callbacks that caused garbage-collection exhaustion over time.

## Features

- **Speed Presets**: Cycle through 0.125x, 0.25x, 0.5x, 1x, 2x, 4x, 8x
- **Shared Panel UI**: Buttons in the ModPanels sidebar — toggle with `m_panels`
- **Day Skip**: Jump to a configurable time of day (default 23:59)
- **Pause / Resume**: Freeze and unfreeze the day cycle
- **Auto-Reset**: Optionally reset speed to default at the start of each day
- **Fully Configurable**: Adjust settings via Mod Manager

## Installation

1. Place the `tardis` folder in your `Mods/` directory
2. Install `supa-mod-loader` for the shared panel sidebar (optional but recommended)
3. Load or reload the game (F11 to reload mods)
4. You should see `[tardis] TARDIS mod loaded` in the console
5. Press **~** to open the debug console and type a command

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
| `m_panels`  | Toggle the shared mod panels sidebar         |
| `m_tardis`  | Alias for m_panels                           |

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

Legacy v1 aliases (`speed_up`, `speed_down`, `speed_reset`, `day_skip`, `speed`) are still supported.

## Configuration

All settings can be configured through the Mod Manager UI or by editing the `config` table in `entry.lua`.

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| **Default Speed** | 1.0 | 0.125 – 8.0 | Speed to reset to with `m_normal` (snapped to nearest preset) |
| **Skip To Time** | 23.99 | 0.0 – 23.99 | Hour to skip to in 24h decimal format |
| **Auto Reset On Day Start** | false | — | Reset speed to default at the start of each new day |
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

### Shared Panel
Type `m_panels` in the debug console (or `m_tardis`) to open the shared mod panels sidebar. TARDIS adds buttons for Slower, Faster, Pause, Reset, and Skip Day, plus a live status line showing speed, time, day, and pause state.

## Technical Details

- Uses `GameWorld.update_server_timescale()` for speed control
- Uses `DayCycleController.force_day_clock()` for time skip
- Uses `DayCycleController.pause_timer()` / `resume_timer()` for pause
- Reads `DayCycleController.paused` for live pause state (no internal tracking)
- Syncs `current_preset_idx` from `world.time_mult` before each step operation
- Console commands registered via `DebugLayer.register_cmd()` in `on_game_state_ready`
- Auto-reset uses `on_day_start` callback — zero per-frame cost
- Panel section added to shared `/root/ModPanels` overlay (built by supa-mod-loader)
- Button signals (`"pressed"`) connected to GLOBAL Lua functions — GC-safe because `_G` pins them
- No `display_notification()` calls — they cause sandbox timeout cascades
- Graceful degradation: if supa-mod-loader is not installed, console commands still work

## Compatibility

- **Game Version**: 0.10.7+
- **Dependencies**: `luajit-support ~0.2.0`
- **Optional**: `supa-mod-loader >=4.0.0` (for shared panel sidebar)
- **Conflicts**: May interact unexpectedly with other mods that manipulate game time

## Troubleshooting

### Speed changes don't seem to apply
- Ensure the mod loaded (check console for `[tardis] TARDIS mod loaded`)
- Press ~ and type `m_time` to see the live engine state
- Enable debug logging to see detailed sync and apply messages

### Day skip doesn't work
- The day skip relies on `DayCycleController` which may not be available in all game modes
- Check the console for error messages after typing `m_skip`

### Panel doesn't appear
- Install `supa-mod-loader` (v4.0.0+) for the shared ModPanels sidebar
- Type `m_panels` to toggle the sidebar
- All console commands still work regardless of whether the panel loads

### Commands not registered
- If `m_faster` etc. don't work in the debug console, the global aliases (`faster()`, `slower()`, etc.) should still work as direct Lua calls

## Changelog

### v2.3.0
- Migrated to **shared ModPanels framework** (supa-mod-loader v4.0.0)
- Removed custom standalone panel — buttons now appear in the shared sidebar
- Removed `display_notification()` calls (caused sandbox timeout cascades)
- Removed `show_notifications` config option (no longer applicable)
- Replaced `m_panel` command with `m_panels` (shared) and `m_tardis` (alias)
- Panel status auto-refreshes after each command action
- Graceful degradation: if supa-mod-loader is absent, console commands work normally

### v2.1.0
- Added **clickable UI panel** — floating overlay with buttons, toggled via `m_panel`
- Panel shows live status (speed, time, day, pause state) updated after each action
- Panel built with Godot UI nodes (CanvasLayer, PanelContainer, VBoxContainer, Button)
- Button press signals wired to Lua functions — experimental, first Lua mod to do this

### v2.0.0
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

### v0.1.0
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

Uses world.time_mult for speed reads and world.update_server_timescale() for writes.
Day skip uses DayCycleController.force_day_clock(). Speed preset ladder is fixed at
0.125x / 0.25x / 0.5x / 1x / 2x / 4x / 8x to match game hard limits.


</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `tardis` |
| Creation Date | 2026-01-31 |
| Last Updated | 2026-04-21 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/mods/tardis](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/mods/tardis) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/tardis-v4.0.1)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/tardis-v4.0.1/tardis-4.0.1.zip)

</details>

---

[Back to All Mods](/mods/)
