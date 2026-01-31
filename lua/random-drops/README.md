# Random Drops

A comprehensive randomness mod for Tower Networking Inc that adds variety and unpredictability to your gameplay through configurable features.

## Description

Random Drops enhances your gameplay experience by introducing controlled randomness to item spawning and purchases. Each feature can be independently enabled or disabled, allowing you to customize the experience to your liking.

## Features

### Feature 1: Random Item Spawning

Periodically spawns random devices at configurable intervals.

- **Customizable Interval**: Set how often items spawn (10-600 seconds)
- **Variable Quantity**: Configure min/max items per spawn event
- **Device Filters**: Choose to spawn all device types or select specific categories:
  - Network Switches
  - Routers
  - Firewalls
  - Servers
  - Workstations
  - Miscellaneous devices (UPS, surge protectors, etc.)

### Feature 2: Extra Users on Floor Creation ⚠️ *Limited*

**Note**: This feature has limited functionality due to mod API restrictions. The game's `all_possible_users` array contains user type names (strings) rather than spawnable PackedScenes, and ResourceLoader access is blocked by the sandbox. This feature will show a warning and not spawn users until the mod API is extended.

### Feature 3: Purchase Multiplier

Receive multiple copies of items when purchasing from the shop.

- **Configurable Multiplier**: Get 2x, 3x, up to 10x items per purchase
- **Single Payment**: Only pay for one item, receive multiple
- **All Devices**: Works with any purchasable device

## Installation

1. Place the `random-drops` folder in your `Mods/` directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
2. Load or reload the game (F11 to reload mods)
3. You should see "Random Drops mod loaded!" in the console
4. Configure features using the Mod Manager

## Usage

### Quick Start

By default, all three features are enabled with reasonable settings:
- Random spawns every 60 seconds (1-3 items)
- 1-3 extra users per floor
- 2x purchase multiplier

### Configuration

Access the Mod Manager to configure each feature:

#### Random Item Spawning
| Setting | Default | Description |
|---------|---------|-------------|
| Enable Random Spawns | On | Master toggle for this feature |
| Spawn Interval | 60s | Time between spawn events |
| Min Items | 1 | Minimum items per spawn |
| Max Items | 3 | Maximum items per spawn |
| Spawn All Items | On | Include all device types |

#### Extra Users on Floor Creation
| Setting | Default | Description |
|---------|---------|-------------|
| Enable Extra Users | On | Master toggle for this feature |
| Min Extra Users | 1 | Minimum users added per floor |
| Max Extra Users | 3 | Maximum users added per floor |

#### Purchase Multiplier
| Setting | Default | Description |
|---------|---------|-------------|
| Enable Purchase Multiplier | On | Master toggle for this feature |
| Purchase Multiplier | 2 | Items received per purchase |

#### General
| Setting | Default | Description |
|---------|---------|-------------|
| Debug Logging | On | Show detailed console output |

## Examples

### Chaos Mode
Maximum randomness for a wild experience:
- Random Spawns: Every 10 seconds, 5-10 items
- Extra Users: 5-10 per floor
- Purchase Multiplier: 10x

### Subtle Enhancement
Gentle additions without overwhelming:
- Random Spawns: Every 300 seconds, 1 item (servers only)
- Extra Users: 1-2 per floor
- Purchase Multiplier: Disabled

### Builder's Paradise
Focus on infrastructure:
- Random Spawns: Every 30 seconds, 2-5 items (switches, routers, firewalls)
- Extra Users: Disabled
- Purchase Multiplier: 5x

## Technical Details

### Hooks Used
- `on_engine_load()` - Initialization
- `on_mod_reload()` - Configuration reload (F11)
- `on_device_spawned()` - Purchase multiplier detection
- `on_user_spawned()` - User tracking
- `on_location_spawned()` - Floor creation detection
- `on_tick()` - Periodic spawn timer
- `on_day_start()` / `on_day_end()` - Day cycle events

### Configuration Storage
Configuration is embedded in `entry.lua` within marked sections and is parsed/modified by the ModManager.

### Compatibility
- Game Version: Beta
- Requires: LuaJIT mod loader

## Troubleshooting

### Items not spawning
- Check console for log messages
- Ensure `enable_random_spawns` is set to `true`
- Verify spawn interval hasn't elapsed yet
- Some spawn functionality depends on game API availability

### Extra users not appearing
- Ensure `enable_extra_users` is set to `true`
- Check console for spawn attempts
- User spawning depends on location's available user pool

### Purchase multiplier not working
- Ensure `enable_purchase_multiplier` is set to `true`
- Set multiplier > 1 (1 = normal behavior)
- Check console for purchase detection messages

### Console spam
- Disable `debug_logging` for cleaner output
- Only important messages will be shown

## Changelog

### v0.1.0 (2026-01-27)
- Initial release
- Three configurable features: random spawns, extra users, purchase multiplier
- Full Mod Manager integration with conditional UI
- Comprehensive logging system

## License

See the main repository LICENSE file.

## Credits

- Author: CJFWeatherhead
- Part of the TNI-Mods collection
