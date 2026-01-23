---
title: "Inverse Prices"
date: 2026-01-17
draft: false
mod_id: "inverse-prices"
author: "CJFWeatherhead"
status: "Active Development"
game_version: "beta"
---

# Inverse Prices

This mod inverts the game's economy by making purchases pay the player instead of costing money.

## Features
- Device purchases refund money based on configured multiplier
- Proposal costs are refunded when submitted
- Tower link and socket costs are refunded
- Configurable refund amounts (Free/Double/Custom)
- Selectively enable/disable effects on devices, sockets, and proposals
- Uses proper transaction system for refunds
- Real-time monitoring of expenses and proposals


## Mod Information

- **Author**: CJFWeatherhead
- **Development Status**: Active Development
- **Game Version**: beta
- **Last Updated**: 2026-01-17
- **Website**: [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/inverse-prices](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/inverse-prices)

## Download

**[Download Inverse Prices](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/inverse-prices)**

### Installation Instructions

1. Download or clone this repository
2. Copy the `lua/inverse-prices/` folder to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed
4. Enable and configure using [ModManagerGUI.ps1](/mods/tools/modmanager/)

## Configuration Parameters

This mod can be configured using the [Mod Manager](/mods/tools/modmanager/). Available parameters:

### Refund Amount

- **Parameter Name**: `refund_type`
- **Type**: select
- **Default**: `Double`
- **Options**: `Free`, `Double`, `Custom`

Choose the refund multiplier:
- Free (1x Refund): Get back what you paid, making purchases free
- Double (2x Refund): Get back double what you paid, earning profit
- Custom: Set your own multiplier value


### Custom Refund Multiplier

- **Parameter Name**: `custom_refund_amount`
- **Type**: integer
- **Default**: `2`
- **Min**: 1
- **Max**: 100

Custom refund multiplier (only used when Refund Amount is set to "Custom")

### Affect Devices

- **Parameter Name**: `effects_devices`
- **Type**: boolean
- **Default**: `True`

Whether to refund device purchases

### Affect Sockets

- **Parameter Name**: `effects_sockets`
- **Type**: boolean
- **Default**: `True`

Whether to refund socket and link expenses

### Affect Proposals

- **Parameter Name**: `effects_proposals`
- **Type**: boolean
- **Default**: `True`

Whether to refund proposal costs when submitting proposals

---

## Detailed Documentation

# Inverse Prices Mod

A chaotic mod for The Network Inc that inverts all prices - you get PAID when you buy things!

## Overview

This mod turns the game's economy completely upside down:

- **Buying devices pays you money** instead of costing money
- **Tower links pay you** for setup and daily costs
- **Recycling costs you money** instead of giving you money back

## How It Works

The mod hooks into the game's spawn callbacks and inverts prices as things are created:

### Device Prices

- Intercepts `on_device_spawned()` callback
- Inverts the `price` field to negative
- Also modifies merchant price multipliers to ensure consistency

### Tower Link Costs

- Intercepts `on_user_spawned()` callback (runs early enough to catch link setup)
- Inverts all LinkCosting fields:
  - `setup_fixed`, `setup_per_floor`, `setup_per_distance_samefloor`
  - `daily_fixed`, `daily_per_floor`, `daily_per_distance_samefloor`

### Recycle Prices

- Inverts recycle prices so you pay to recycle devices

## Gameplay Impact

This mod makes the game **extremely easy** by turning all expenses into income:

- **Unlimited money glitch**: Buy expensive devices to gain money
- **Links generate profit**: Creating tower links increases your balance
- **Economic chaos**: The normal gameplay loop is completely broken

### Strategy Tips

- Buy the most expensive devices to maximize profit
- Create as many tower links as possible
- Recycling now costs money, so keep your devices!

## Limitations

Due to mod API limitations:

- **Proposals cannot be modified** before they're created, so proposal costs remain normal
- Some prices may be cached before the mod runs
- Prices are modified per-instance, not at the template level

## Installation

1. Place this folder in the `lua/` directory
2. Ensure the folder structure is: `lua/inverse-prices/entry.lua`
3. Launch the game - the mod will load automatically

## Compatibility

- Game Version: 0.10.0+
- Requires: ModApiV1
- Compatible with other mods (like 2x-bandwidth-switches)
- May conflict with mods that also modify device prices

## Technical Details

The mod uses:

- `on_device_spawned(device)` - Modifies device prices as they spawn
- `on_user_spawned(user)` - Used to trigger link cost modifications
- Direct field manipulation on `DeviceUnit`, `DeviceMerchant`, and `LinkCosting` objects

## Troubleshooting

If prices aren't inverted:

1. Check console output for `[inverse-prices]` messages
2. Verify the mod loaded with "Inverse Prices mod loaded" message
3. Make sure you're buying newly spawned devices (not existing ones from before mod loaded)

## Notes

This is a fun/experimental mod that breaks game balance completely. It's great for:

- Testing game mechanics without financial constraints
- Sandbox/creative play
- Seeing how far you can push the economy

## License

Same as TNI-Mods project


---

## Additional Notes

Configure refund multiplier and what to affect via Mod Manager settings. Uses on_device_spawned and on_tick hooks for real-time monitoring.

---

[← Back to All Mods](/mods/)
