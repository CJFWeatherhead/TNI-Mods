---
title: "Random Device Warranties"
date: 2026-05-31
draft: false
mod_id: "random-warranties"
author: "CJFWeatherhead"
version: "0.1.8"
status: "Discontinued"
game_version: "stable"
---

# Random Device Warranties

A simple example mod that randomizes warranty periods of all devices in Tower Networking Inc. Superseded by Device Tweaker, but kept as a useful de...

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 0.1.8 |
| **Author** | CJFWeatherhead |
| **Status** | 🔴 Discontinued |
| **Game Version** | stable |
| **Last Updated** | 2026-05-31 |

</div>

---

## Download

<div class="download-section">

**[Download random-warranties-0.1.8.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/random-warranties-v0.1.8/random-warranties-0.1.8.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **Random Device Warranties** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `random-warranties/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Minimum Warranty Multiplier** | integer (1-100) | `2` | Minimum multiplier for device warranties (e.g., 2 = 2x base warranty) |
| **Maximum Warranty Multiplier** | integer (1-100) | `25` | Maximum multiplier for device warranties (e.g., 25 = 25x base warranty) |
| **Apply to Warranty Cycles** | boolean | `True` | Whether to also multiply warranty cycles (in addition to days) |
| **Apply to Remaining Warranty** | boolean | `True` | Whether to also apply multiplier to warranty_period_remaining |

---

## About This Mod

A simple example mod that randomizes warranty periods of all devices in Tower Networking Inc. Superseded by Device Tweaker, but kept as a useful demonstration mod for new developers.

---

<details>
<summary><strong>Full Documentation</strong></summary>

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

- Game Version: stable
- Dependencies: None

## Author

CJFWeatherhead

## Notes

Each device gets its own random multiplier, so warranties vary widely. Some devices may have very short warranties, others extremely long ones.

</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

Each device gets its own random multiplier, so warranties vary widely.

</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `random-warranties` |
| Creation Date | 2026-01-01 |
| Last Updated | 2026-05-31 |
| Game Version | stable |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/random-warranties](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/random-warranties) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/random-warranties-v0.1.8)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/random-warranties-v0.1.8/random-warranties-0.1.8.zip)

</details>

---

[Back to All Mods](/mods/)
