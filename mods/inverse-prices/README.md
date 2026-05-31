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
