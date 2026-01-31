---
title: "2x Bandwidth Switches"
date: 2026-01-31
draft: false
mod_id: "2x-bandwidth-switches"
author: "treefarmer741"
version: "0.1.2"
status: "Active Development"
game_version: "beta"
---

# 2x Bandwidth Switches

This mod doubles the bandwidth capacity of all switches in the Tower Networking Inc game.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 0.1.2 |
| **Author** | treefarmer741 |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-01-31 |

</div>

---

## Download

<div class="download-section">

**[Download 2x-bandwidth-switches-0.1.2.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/2x-bandwidth-switches-v0.1.2/2x-bandwidth-switches-0.1.2.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **2x Bandwidth Switches** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `2x-bandwidth-switches/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

<details>
<summary><strong>Full Documentation</strong></summary>

# 2x Bandwidth Switches

A simple example mod that doubles the bandwidth capacity of all switches in the Tower Networking Inc game.

> **Note**: This functionality is also available in the [Device Tweaker](../device-tweaker/) mod which offers more comprehensive device customization. However, this mod remains available as a simple, feature-complete example - it was originally a template mod by [treefarmer741](https://github.com/treefarmer741) and makes an excellent starting point for new mod developers.

## Description

Switches in the game have a limited network bandwidth capacity. This mod increases that capacity by 2x, allowing switches to handle more network traffic without bottlenecks.

## Features

- Automatically doubles the installed network bandwidth (nbw) of all switch devices
- Works on all types of switches (device_hardware_class == 1)
- Modification applies when devices are spawned

## Installation

1. Place the `2x-bandwidth-switches` folder in your `lua/` directory
2. Load or reload the game
3. All newly spawned switches will have doubled bandwidth

## Usage

No additional configuration required. The mod activates automatically when devices are spawned.

## Compatibility

- Game Version: beta
- Dependencies: None

## Author

[treefarmer741](https://github.com/treefarmer741)

## Notes

This mod only affects switches and does not modify other device types.

</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

This mod only affects switches and does not modify other device types.

</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `2x-bandwidth-switches` |
| Creation Date | 2025-11-20 |
| Last Updated | 2026-01-31 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/2x-bandwidth-switches](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/2x-bandwidth-switches) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/2x-bandwidth-switches-v0.1.2)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/2x-bandwidth-switches-v0.1.2/2x-bandwidth-switches-0.1.2.zip)

</details>

---

[Back to All Mods](/mods/)
