# Chaos Engine

A controlled chaos mod that introduces randomness and unpredictability to Tower Networking Inc through keyboard-triggered events and automatic stat randomization.

## Description

Chaos Engine lets you shake things up in your tower with debug console commands that trigger random events, plus automatic randomization of user stats for unpredictable gameplay.

## Features

### Console Commands

Press `~` to open the debug console, then type a command:

| Command | Action |
|---------|--------|
| **m_random_floor** | Force spawn a random floor immediately |
| **m_disaster** | Toggle Disaster Mode on/off |
| **m_chaos_reset** | Reset all chaos settings to defaults |

### Disaster Mode

When activated (`m_disaster`), all random event rates are multiplied:

- Device failures
- Power outages
- Power surges  
- Worm spawns

The multiplier is configurable (default 5x). Run `m_chaos_reset` to restore original rates.

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
2. Press `~` to open the debug console, type **m_disaster** - watch events increase!
3. Type **m_random_floor** to spawn a random new floor
4. Type **m_chaos_reset** to calm things down

### Gameplay Modes

#### Survival Mode
- Enable Disaster Mode with high multiplier (10-20x)
- See how long you can keep your tower running

#### Expansion Challenge
- Run `m_random_floor` repeatedly to rapidly expand
- Try to manage the influx of random floors

#### Pure Chaos
- Enable everything with extreme settings
- Sit back and watch the mayhem

## Configuration

Access the Mod Manager to configure each feature:

### Feature Toggles
| Setting | Default | Description |
|---------|---------|-------------|
| Enable Random Floors | On | Enable m_random_floor command |
| Enable Disaster Mode | On | Enable m_disaster command |
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
- `on_user_spawned()` - User stat randomization
- `on_day_start()` / `on_day_end()` - Day cycle events

Console commands registered via `DebugLayer.register_cmd()` (activated automatically on game load).

### State Management
- Original event rates are stored on first load
- Disaster mode state is tracked and can be toggled
- Reset function restores all original values

## Troubleshooting

### Commands not working
- Press `~` to open the debug console
- Check that the mod is loaded (look for "Chaos Engine mod loaded!" in console)
- Verify the feature is enabled in config

### Disaster mode not resetting
- Type `m_chaos_reset` in the console to force reset
- Reload mod with F11

### Floors not spawning
- Check console for error messages
- Some game states may prevent floor spawning
- The mod will log detailed information about available floor builders

## Changelog

### v0.1.0 (2026-01-31)
- Initial release
- Random floor spawning (`m_random_floor` console command)
- Disaster mode toggle (`m_disaster` console command)
- Reset function (`m_chaos_reset` console command)
- User stat randomization (excludes daily_rate)

## License

See the main repository LICENSE file.

## Credits

- Author: CJFWeatherhead
- Part of the TNI-Mods collection
