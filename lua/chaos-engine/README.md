# Chaos Engine

A controlled chaos mod that introduces randomness and unpredictability to Tower Networking Inc through keyboard-triggered events and automatic stat randomization.

## Description

Chaos Engine lets you shake things up in your tower with keyboard shortcuts that trigger random events, plus automatic randomization of user stats for unpredictable gameplay.

## Features

### Keyboard Shortcuts

All shortcuts use **CTRL+SHIFT** combinations to avoid clashing with other mods:

| Shortcut | Action |
|----------|--------|
| **CTRL+SHIFT+F** | Force spawn a random floor immediately |
| **CTRL+SHIFT+D** | Toggle Disaster Mode on/off |
| **CTRL+SHIFT+X** | Reset all chaos settings to defaults |

### Disaster Mode

When activated (CTRL+SHIFT+D), all random event rates are multiplied:

- Device failures
- Power outages
- Power surges  
- Worm spawns

The multiplier is configurable (default 5x). Toggle off or press CTRL+SHIFT+X to restore original rates.

### User Stat Randomization

When users spawn, their stats are randomized within configurable ranges:

| Stat | Description | Default Range |
|------|-------------|---------------|
| Satiety SLA Ratio | Satisfaction threshold | 0.3 - 0.9 |
| Eagerness Factor | How demanding they are | 1 - 10 |
| Base Use Period | Service usage frequency | 0.5x - 2.0x |
| Grace Days | Initial forgiveness period | 1 - 7 days |
| Satiety Decay | Satisfaction drop rate | 0.1 - 0.5 |

**Note**: Daily rate is intentionally NOT modified to avoid conflicts with other mods.

## Installation

1. Place the `chaos-engine` folder in your `Mods/` directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
2. Load or reload the game (F11 to reload mods)
3. You should see "Chaos Engine mod loaded!" in the console

## Usage

### Quick Start

1. Start a game
2. Press **CTRL+SHIFT+D** to activate Disaster Mode - watch events increase!
3. Press **CTRL+SHIFT+F** to spawn a random new floor
4. Press **CTRL+SHIFT+X** to calm things down

### Gameplay Modes

#### Survival Mode
- Enable Disaster Mode with high multiplier (10-20x)
- See how long you can keep your tower running

#### Expansion Challenge
- Spam CTRL+SHIFT+F to rapidly expand
- Try to manage the influx of random floors

#### Pure Chaos
- Enable everything with extreme settings
- Sit back and watch the mayhem

## Configuration

Access the Mod Manager to configure each feature:

### Feature Toggles
| Setting | Default | Description |
|---------|---------|-------------|
| Enable Random Floors | On | Allow CTRL+SHIFT+F |
| Enable Disaster Mode | On | Allow CTRL+SHIFT+D |
| Enable User Randomization | On | Randomize user stats |

### Disaster Mode
| Setting | Default | Description |
|---------|---------|-------------|
| Event Rate Multiplier | 5.0 | How much to multiply rates |

### User Randomization
All user stats have configurable min/max ranges.

## Technical Details

### Hooks Used
- `on_engine_load()` - Initialization and storing original rates
- `on_mod_reload()` - Re-initialization on F11
- `on_player_input()` - Keyboard shortcut handling
- `on_user_spawned()` - User stat randomization
- `on_day_start()` / `on_day_end()` - Day cycle events

### State Management
- Original event rates are stored on first load
- Disaster mode state is tracked and can be toggled
- Reset function restores all original values

### Hotkey Design
CTRL+SHIFT combinations were chosen because:
- SHIFT+letter is used by other mods (money-cheat, all-proposals)
- CTRL+letter may be used by game UI
- CTRL+SHIFT+letter is uncommon and distinctive

## Troubleshooting

### Hotkeys not working
- Ensure the game window has focus
- Check that CTRL and SHIFT are both held
- Verify the feature is enabled in config

### Disaster mode not resetting
- Press CTRL+SHIFT+X to force reset
- Reload mod with F11

### Floors not spawning
- Check console for error messages
- Some game states may prevent floor spawning

## Changelog

### v0.1.0 (2026-01-31)
- Initial release
- Random floor spawning (CTRL+SHIFT+F)
- Disaster mode toggle (CTRL+SHIFT+D)
- Reset function (CTRL+SHIFT+X)
- User stat randomization (excludes daily_rate)

## License

See the main repository LICENSE file.

## Credits

- Author: CJFWeatherhead
- Part of the TNI-Mods collection
