---
title: "All Proposals"
date: 2026-01-01
draft: false
mod_id: "all-proposals"
author: "CJFWeatherhead"
status: "Active Development"
game_version: "beta"
---

# All Proposals

All Proposals Mod: enhances the game's proposal system by allowing players to view all available proposals at once. Press Shift+P to temporarily increase the proposal batch size and display all eligible proposals, excluding those with unmet dependencies or failed adhoc requirements. Press Shift+O to restore normal proposal display.


## Mod Information

- **Author**: CJFWeatherhead
- **Development Status**: Active Development
- **Game Version**: beta
- **Last Updated**: 2026-01-01
- **Website**: [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/all-proposals](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/all-proposals)

## Download

**[Download All Proposals](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/all-proposals)**

### Installation Instructions

1. Download or clone this repository
2. Copy the `lua/all-proposals/` folder to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed
4. Enable and configure using [ModManagerGUI.ps1](/mods/tools/modmanager/)

---

## Detailed Documentation

# All Proposals Mod

## Description
This mod enhances the proposal system in the game by allowing players to view all available proposals at once. When activated, it temporarily increases the proposal batch size to display all eligible proposals, excluding only those with unmet dependencies or failed adhoc requirements.

## Features
- View all available proposals with Shift+P
- Automatically excludes proposals with unmet dependencies
- Checks adhoc requirements before displaying proposals
- Restore normal proposal display with Shift+O
- Provides detailed logging of proposal status

## Installation
1. Place the `all-proposals` folder in your game's `lua` mods directory.
2. Ensure the mod is enabled in your mod configuration.
3. Restart the game or reload mods.

## Usage
- **Activate All Proposals**: Press `Shift+P` to show all available proposals.
- **Restore Normal Mode**: Press `Shift+O` to return to the default proposal batch size and reroll proposals.

The mod will log detailed information about the proposal status in the console, including counts of total, available, blocked, and submitted proposals.

## Compatibility
- Compatible with TNI game version beta
- Uses ModApiV1 for game integration
- No known conflicts with other mods

## Author
Unknown

## Notes
- The mod safely stores and restores the original proposal batch size.
- Proposals are filtered to ensure only truly available ones are displayed.
- Detailed console output helps with debugging proposal availability.

---

## Additional Notes

- Uses ModApiV1 for game integration
- Safely checks proposal dependencies and requirements
- Provides detailed console logging
- No known conflicts with other mods

---

[← Back to All Mods](/mods/)
