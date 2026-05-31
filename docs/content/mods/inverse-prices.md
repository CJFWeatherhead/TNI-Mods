---
title: "Inverse Prices"
date: 2026-04-16
draft: false
mod_id: "inverse-prices"
author: "CJFWeatherhead"
version: "0.1.5"
status: "Active Development"
game_version: "beta"
---

# Inverse Prices

This mod inverts the game's economy by making purchases pay the player instead of costing money.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 0.1.5 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-04-16 |

</div>

---

## Download

<div class="download-section">

**[Download inverse-prices-0.1.5.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/inverse-prices-v0.1.5/inverse-prices-0.1.5.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **Inverse Prices** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `inverse-prices/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Refund Amount** | select: Free, Double, Custom | `Double` | Choose the refund multiplier:
- Free (1x Refund): Get back what you paid, making purchases free
- Double (2x Refund): Get back double what you paid, earning profit
- Custom: Set your own multiplier value
 |
| **Custom Refund Multiplier** | integer (1-100) | `2` | Custom refund multiplier (only used when Refund Amount is set to "Custom") |
| **Affect Devices** | boolean | `True` | Whether to refund device purchases |
| **Affect Sockets** | boolean | `True` | Whether to refund socket and link expenses |
| **Affect Proposals** | boolean | `True` | Whether to refund proposal costs when submitting proposals |

---

## About This Mod

This mod inverts the game's economy by making purchases pay the player instead of costing money.

## Features
- Device purchases refund money based on configured multiplier
- Proposal costs are refunded when submitted
- Tower link and socket costs are refunded
- Configurable refund amounts (Free/Double/Custom)
- Selectively enable/disable effects on devices, sockets, and proposals
- Uses proper transaction system for refunds
- Real-time monitoring of expenses and proposals

---

<details>
<summary><strong>Full Documentation</strong></summary>

# Inverse Prices Mod

A chaotic mod for Tower Networking Inc that inverts all prices - you get PAID when you buy things!

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


</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

Configure refund multiplier and what to affect via Mod Manager settings. Uses on_device_spawned and on_tick hooks for real-time monitoring.

</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `inverse-prices` |
| Creation Date | 2026-01-01 |
| Last Updated | 2026-04-16 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/inverse-prices](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/inverse-prices) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/inverse-prices-v0.1.5)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/inverse-prices-v0.1.5/inverse-prices-0.1.5.zip)

</details>

---

[Back to All Mods](/mods/)
