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
