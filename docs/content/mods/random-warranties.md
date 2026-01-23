---
title: "Random Device Warranties"
date: 2026-01-01
draft: false
mod_id: "random-warranties"
author: "CJFWeatherhead"
status: "Active Development"
game_version: "beta"
---

# Random Device Warranties

This mod randomizes the warranty periods of all devices in The Network Inc game.

## Features
- Randomizes warranty periods for all device types
- Multiplier ranges from 2x to 25x
- Affects both base warranty days and cycles
- Also modifies remaining warranty period if applicable
- Provides console logging of changes


## Mod Information

- **Author**: CJFWeatherhead
- **Development Status**: Active Development
- **Game Version**: beta
- **Last Updated**: 2026-01-01
- **Website**: [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/random-warranties](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/random-warranties)

## Download

**[Download Random Device Warranties](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/random-warranties)**

### Installation Instructions

1. Download or clone this repository
2. Copy the `lua/random-warranties/` folder to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed
4. Enable and configure using [ModManagerGUI.ps1](/mods/tools/modmanager/)

## Configuration Parameters

This mod can be configured using the [Mod Manager](/mods/tools/modmanager/). Available parameters:

### Minimum Warranty Multiplier

- **Parameter Name**: `warranty_multiplier_min`
- **Type**: integer
- **Default**: `2`
- **Min**: 1
- **Max**: 100

Minimum multiplier for device warranties (e.g., 2 = 2x base warranty)

### Maximum Warranty Multiplier

- **Parameter Name**: `warranty_multiplier_max`
- **Type**: integer
- **Default**: `25`
- **Min**: 1
- **Max**: 100

Maximum multiplier for device warranties (e.g., 25 = 25x base warranty)

### Apply to Warranty Cycles

- **Parameter Name**: `apply_to_cycles`
- **Type**: boolean
- **Default**: `True`

Whether to also multiply warranty cycles (in addition to days)

### Apply to Remaining Warranty

- **Parameter Name**: `apply_to_remaining`
- **Type**: boolean
- **Default**: `True`

Whether to also apply multiplier to warranty_period_remaining

---

## Detailed Documentation

# Random Device Warranties

This mod randomizes the warranty periods of all devices in The Tower Network Inc game.

## Description

Device warranties in the game have fixed periods. This mod introduces randomness by multiplying the base warranty days and cycles by a random factor between 2x and 25x for each spawned device.

## Features

- Randomizes warranty periods for all device types
- Multiplier ranges from 2x to 25x
- Affects both base warranty days and cycles
- Also modifies remaining warranty period if applicable
- Provides console logging of changes

## Installation

1. Place the `random-warranties` folder in your `lua/` directory
2. Load or reload the game
3. All newly spawned devices will have randomized warranties

## Usage

No additional configuration required. The mod activates automatically when devices are spawned.

## Compatibility

- Game Version: beta
- Dependencies: None

## Author

CJFWeatherhead

## Notes

Each device gets its own random multiplier, so warranties vary widely. Some devices may have very short warranties, others extremely long ones.

---

## Additional Notes

Each device gets its own random multiplier, so warranties vary widely.

---

[← Back to All Mods](/mods/)
