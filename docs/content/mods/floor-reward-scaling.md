---
title: "Floor Reward Scaling"
date: 2026-01-31
draft: false
mod_id: "floor-reward-scaling"
author: "CJFWeatherhead"
version: "0.1.4"
status: "Active Development"
game_version: "beta"
---

# Floor Reward Scaling

**Floor Reward Scaling Mod** automatically scales user daily payment rates based on their floor number using configurable progression systems. Choo...

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 0.1.4 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-01-31 |

</div>

---

## Download

<div class="download-section">

**[Download floor-reward-scaling-0.1.4.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/floor-reward-scaling-v0.1.4/floor-reward-scaling-0.1.4.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **Floor Reward Scaling** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `floor-reward-scaling/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Scaling Type** | select: Logarithmic, Linear, Exponential, Randomised | `Logarithmic` | Choose the reward scaling method:
- Logarithmic: Diminishing returns, balanced growth (1 + log₂(floor+2) × factor)
- Linear: Constant rate increase per floor (1 + floor × factor)
- Exponential: Rapid compound growth (factor ^ floor)
- Randomised: Random multiplier per user (between min and max)
 |
| **Scaling Factor** | number (1.0-5.0) | `2.0` | Multiplier factor for scaling (not used in Randomised mode).
Higher values = stronger scaling effect.
Logarithmic: Factor of 2.0 gives ~4x at floor 5
Linear: Factor of 2.0 gives 11x at floor 5
Exponential: Factor of 2.0 gives 32x at floor 5
 |
| **Minimum Random Factor** | number (1.0-100.0) | `1.0` | Minimum multiplier for Randomised mode (only used when Scaling Type is "Randomised") |
| **Maximum Random Factor** | number (1.0-100.0) | `5.0` | Maximum multiplier for Randomised mode (only used when Scaling Type is "Randomised") |

---

## About This Mod

**Floor Reward Scaling Mod** automatically scales user daily payment rates based on their floor number using configurable progression systems. Choose from logarithmic, linear, exponential, or randomised scaling to customize reward progression.

## Scaling Types
- **Logarithmic**: Diminishing returns - higher floors get better rewards but growth slows (recommended for balance)
- **Linear**: Constant growth rate - each floor adds the same amount
- **Exponential**: Rapid growth - rewards increase dramatically on higher floors
- **Randomised**: Unpredictable rewards - each user gets a random multiplier within configured range

---

<details>
<summary><strong>Full Documentation</strong></summary>

# Floor Reward Scaling Mod

Automatically scales user daily payment rates based on their floor number using a configurable progression system.

## Features

- **Logarithmic Reward Scaling**: Daily user payments increase with floor number using a logarithmic scale
  - Floor 0: ~2.0x multiplier
  - Floor 1: ~2.58x multiplier
  - Floor 5: ~3.81x multiplier
  - Floor 10: ~4.58x multiplier
  - Floor 20: ~5.46x multiplier
- **Balanced Progression**: Higher floors = better rewards, but not overwhelming
- **Automatic Application**: Rewards are scaled when users spawn

## How It Works

The mod hooks into the `on_user_spawned` callback and applies a multiplier to the user's `daily_rate` property:

1. Gets the floor number from the user's location
2. Calculates multiplier using: `multiplier = 1 + log₂(floor + 2)`
3. Applies the multiplier to the user's daily rate (rounded up to nearest integer)

## Reward Formula

The multiplier formula `1 + log₂(floor + 2)` provides:

- **Meaningful rewards** at higher floors to encourage tower progression
- **Diminishing returns** to prevent exponential growth that could break game balance
- **Smooth progression** that scales naturally with game difficulty

### Example Progression

| Floor | Multiplier | $400 Base → | $50 Base → |
| ----- | ---------- | ----------- | ---------- |
| 0     | 2.00x      | $800        | $100       |
| 1     | 2.58x      | $1,033      | $129       |
| 2     | 3.00x      | $1,200      | $150       |
| 5     | 3.81x      | $1,523      | $191       |
| 10    | 4.58x      | $1,834      | $229       |
| 20    | 5.46x      | $2,185      | $273       |

## Installation

1. Copy the `floor-reward-scaling` folder to your `lua/` directory
2. The mod will be automatically loaded when the game starts
3. Press F11 to reload the mod without restarting the game

## Usage

The mod works automatically. When a user spawns, their daily rate is scaled based on their floor number. No manual intervention required. Check the console for scaling confirmation messages.

## Compatibility

- Compatible with other mods
- Can be used independently or alongside address/network configuration mods

## Author

CJFWeatherhead

## Notes

- Uses logarithmic scaling to prevent exponential reward growth
- Multiplier is calculated as `1 + log₂(floor + 2)`
- Daily rates are rounded up to the nearest integer
- Console logs show the scaling applied for each user


</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

- Tested with game version 0.10.0
- Compatible with other mods
- Automatic application on user spawn
- Console logging for scaling confirmation


</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `floor-reward-scaling` |
| Creation Date | 2026-01-01 |
| Last Updated | 2026-01-31 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/floor-reward-scaling](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/floor-reward-scaling) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/floor-reward-scaling-v0.1.4)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/floor-reward-scaling-v0.1.4/floor-reward-scaling-0.1.4.zip)

</details>

---

[Back to All Mods](/mods/)
