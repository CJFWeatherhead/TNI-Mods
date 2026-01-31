---
title: "Random Drops"
date: 2026-01-31
draft: false
mod_id: "random-drops"
author: "CJFWeatherhead"
version: "0.1.2"
status: "Active Development"
game_version: "beta"
---

# Random Drops

A comprehensive randomness mod that adds three configurable features to enhance gameplay variety:

## Features

### 1. Random Item Spawning
Periodically spawns random devices/items at configurable intervals. Control how many items spawn 
and how often. Filter which device types can spawn (switches, routers, firewalls, servers, etc.).

### 2. Extra Users on Floor Creation
When a new floor is created, additional random users are automatically added. Configure the 
minimum and maximum number of extra users per floor.

### 3. Purchase Multiplier
When you purchase an item from the shop (dmarket), receive multiple copies instead of just one.
Set the multiplier to control how many items you get per purchase.

## Usage

All features can be independently enabled or disabled through the Mod Manager interface.
Configure each feature's parameters to customize the experience.

## Configuration

- **Random Spawns**: Toggle on/off, set interval (seconds), item count range, device type filters
- **Extra Users**: Toggle on/off, set min/max users per floor
- **Purchase Multiplier**: Toggle on/off, set multiplier value
- **Debug Logging**: Enable for detailed console output


## Mod Information

- **Author**: CJFWeatherhead
- **Version**: 0.1.2
- **Development Status**: Active Development
- **Game Version**: beta
- **Last Updated**: 2026-01-31
- **Website**: [https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/random-drops](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/random-drops)

## Download

### Latest Release: v0.1.2

**[Download random-drops-0.1.2.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/random-drops-v0.1.2/random-drops-0.1.2.zip)**

[View all releases on GitHub →](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/random-drops-v0.1.2)

### Installation Options

#### Option 1: Using Mod Manager (Recommended)

1. Download the [TNI Mod Manager](/mods/tools/modmanager/)
2. Run the Mod Manager application
3. Find **Random Drops** in the Available mods list
4. Click **Download** to automatically install
5. Configure parameters using the graphical interface

#### Option 2: Manual Installation

1. Download the zip file above
2. Extract the `random-drops/` folder to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed in the mods directory
4. (Optional) Use [Mod Manager](/mods/tools/modmanager/) to configure parameters

## Configuration Parameters

This mod can be configured using the [Mod Manager](/mods/tools/modmanager/). Available parameters:

### Enable Random Item Spawning

- **Parameter Name**: `enable_random_spawns`
- **Type**: boolean
- **Default**: `True`

Periodically spawn random devices at configurable intervals

### Spawn Interval (Seconds)

- **Parameter Name**: `spawn_interval_seconds`
- **Type**: integer
- **Default**: `60`
- **Min**: 10
- **Max**: 600

Time in seconds between random spawn events

### Minimum Items Per Spawn

- **Parameter Name**: `spawn_count_min`
- **Type**: integer
- **Default**: `1`
- **Min**: 1
- **Max**: 10

Minimum number of items to spawn each interval

### Maximum Items Per Spawn

- **Parameter Name**: `spawn_count_max`
- **Type**: integer
- **Default**: `3`
- **Min**: 1
- **Max**: 20

Maximum number of items to spawn each interval

### Spawn All Item Types

- **Parameter Name**: `spawn_all_items`
- **Type**: boolean
- **Default**: `True`

If enabled, all device types can spawn. If disabled, use the filters below.

### Include Network Switches

- **Parameter Name**: `spawn_switches`
- **Type**: boolean
- **Default**: `True`

Allow network switches to spawn (when not using all items)

### Include Routers

- **Parameter Name**: `spawn_routers`
- **Type**: boolean
- **Default**: `True`

Allow routers to spawn (when not using all items)

### Include Firewalls

- **Parameter Name**: `spawn_firewalls`
- **Type**: boolean
- **Default**: `True`

Allow firewalls to spawn (when not using all items)

### Include Servers

- **Parameter Name**: `spawn_servers`
- **Type**: boolean
- **Default**: `True`

Allow compute servers to spawn (when not using all items)

### Include Workstations

- **Parameter Name**: `spawn_workstations`
- **Type**: boolean
- **Default**: `False`

Allow workstations/monitors to spawn (when not using all items)

### Include Miscellaneous Devices

- **Parameter Name**: `spawn_misc`
- **Type**: boolean
- **Default**: `False`

Allow other device types to spawn (UPS, surge protectors, etc.)

### Enable Extra Users on Floor Creation

- **Parameter Name**: `enable_extra_users`
- **Type**: boolean
- **Default**: `True`

Automatically add extra random users when a new floor is created

### Minimum Extra Users

- **Parameter Name**: `extra_users_min`
- **Type**: integer
- **Default**: `1`
- **Min**: 1
- **Max**: 10

Minimum number of extra users to add per floor

### Maximum Extra Users

- **Parameter Name**: `extra_users_max`
- **Type**: integer
- **Default**: `3`
- **Min**: 1
- **Max**: 20

Maximum number of extra users to add per floor

### Enable Purchase Multiplier

- **Parameter Name**: `enable_purchase_multiplier`
- **Type**: boolean
- **Default**: `True`

Receive multiple copies when purchasing items from the shop

### Purchase Multiplier

- **Parameter Name**: `purchase_multiplier`
- **Type**: integer
- **Default**: `2`
- **Min**: 1
- **Max**: 10

Number of items received per purchase (1 = normal, 2 = double, etc.)

### Enable Debug Logging

- **Parameter Name**: `debug_logging`
- **Type**: boolean
- **Default**: `True`

Show detailed log messages in the console

---

## Detailed Documentation

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


---

## Additional Notes

This mod uses on_device_spawned, on_user_spawned, on_location_spawned, and on_tick callbacks.
Some features depend on game API availability and may have limited functionality in certain game versions.


---

[← Back to All Mods](/mods/)
