---
title: "2x Bandwidth Switches"
date: 2025-12-29
draft: false
mod_id: "2x-bandwidth-switches"
author: "treefarmer741"
status: "Active Development"
game_version: "beta"
---

# 2x Bandwidth Switches

This mod doubles the bandwidth capacity of all switches in The Network Inc game.

## Mod Information

- **Author**: treefarmer741
- **Development Status**: Active Development
- **Game Version**: beta
- **Last Updated**: 2025-12-29
- **Website**: [https://github.com/treefarmer741/Tower-Networking-Inc-modding-kit/tree/beta/lua/2x-bandwidth-switches](https://github.com/treefarmer741/Tower-Networking-Inc-modding-kit/tree/beta/lua/2x-bandwidth-switches)

## Download

**[Download 2x Bandwidth Switches](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/2x-bandwidth-switches)**

### Installation Instructions

1. Download or clone this repository
2. Copy the `lua/2x-bandwidth-switches/` folder to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed
4. Enable and configure using [ModManagerGUI.ps1](/mods/tools/modmanager/)

---

## Detailed Documentation

# 2x Bandwidth Switches

This mod doubles the bandwidth capacity of all switches in The Network Inc game.

## Description

This mod was originally a template mod by [treefarmer741](https://github.com/treefarmer741). I've made a few small adjustments. Switches in the game have a limited network bandwidth capacity. This mod increases that capacity by 2x, allowing switches to handle more network traffic without bottlenecks.

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

---

## Additional Notes

This mod only affects switches and does not modify other device types.

---

[← Back to All Mods](/mods/)
