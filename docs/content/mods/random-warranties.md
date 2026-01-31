---
title: "Random Device Warranties"
date: 2026-01-31
draft: false
mod_id: "random-warranties"
author: "CJFWeatherhead"
version: "0.1.3"
status: "Discontinued"
game_version: "beta"
---

# Random Device Warranties

A simple example mod that randomizes warranty periods of all devices in Tower Networking Inc. Superseded by Device Tweaker, but kept as a useful demonstration mod for new developers.

## Mod Information

- **Author**: CJFWeatherhead
- **Version**: 0.1.3
- **Development Status**: Discontinued
- **Game Version**: beta
- **Last Updated**: 2026-01-31
- **Website**: [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/random-warranties](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/random-warranties)

## Download

### Latest Release: v0.1.3

**[Download random-warranties-0.1.3.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/random-warranties-v0.1.3/random-warranties-0.1.3.zip)**

[View all releases on GitHub →](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/random-warranties-v0.1.3)

### Installation Options

#### Option 1: Using Mod Manager (Recommended)

1. Download the [TNI Mod Manager](/mods/tools/modmanager/)
2. Run the Mod Manager application
3. Find **Random Device Warranties** in the Available mods list
4. Click **Download** to automatically install
5. Configure parameters using the graphical interface

#### Option 2: Manual Installation

1. Download the zip file above
2. Extract the `random-warranties/` folder to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed in the mods directory
4. (Optional) Use [Mod Manager](/mods/tools/modmanager/) to configure parameters

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

A simple example mod that randomizes the warranty periods of all devices in Tower Networking Inc.

> **Note**: This mod has been superseded by the [Device Tweaker](../device-tweaker/) mod which offers more comprehensive device customization. However, this mod remains available as a simple, feature-complete example that's useful for developers learning to create mods.

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
