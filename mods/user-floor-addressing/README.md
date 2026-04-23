# User Floor-Based Addressing Mod

This mod automatically configures network settings for users when they spawn in the game.

## Features

- **DHCP Configuration**: Sets DHCP mode per configuration (`boot_dhcp` by default)
- **Floor-Based Addressing**: Assigns predictable network addresses based on floor number and user count
  - Format is configurable, default: `@f<floor>/usr<increment>`
  - Example: User #5 on floor 3 gets address `@f3/usr5`
  - Example: User #1 on floor 10 gets address `@f10/usr1`
- **Automatic DNS Setup**: Configures a floor-specific primary DNS plus two fallback DNS servers

## How It Works

The mod hooks into the `on_user_spawned` callback, triggered whenever a new user is created:

1. Retrieves the user's logic controller and network control module
2. Gets the floor number from the user's location
3. Maintains a counter of users per floor
4. Generates a predictable network address based on floor and user count
5. Sets DHCP mode (default: `boot_dhcp`)
6. Configures DNS servers: floor-specific primary, then two configurable fallbacks

## Limitations

**Hardware (MAC) Addresses**: The mod API does not expose any method to set or
refresh hardware addresses. Hardware addresses are assigned by the game engine
and cannot be controlled by mods.

**Phone / CCTV Devices**: Phones and CCTVs are fixture outlets
(`DeviceOutlet`/`PoweredDeviceOutlet`) instantiated by `MultiplayerSpawner`
nodes in the scene tree. They are not accessible via the Lua mod API — there
is no `on_fixture_spawned` callback and no API method to enumerate them.

## Installation

1. Copy the `user-floor-addressing` folder to your `mods/` directory
2. The mod will be automatically loaded when the game starts
3. Press F11 to reload the mod without restarting the game

## Technical Details

### DHCP Modes

The game supports three DHCP modes:

- `"disabled"` - DHCP disabled, manual configuration required
- `"boot_dhcp"` - Request DHCP address on boot
- `"periodic_dhcp"` - Periodically request DHCP updates

### DNS Configuration

DNS servers are set using a Godot Array. By default:

- Floor-specific: `@f<floor>/dns`
- Fallback 1: `@srv/dns1`
- Fallback 2: `@srv/dns2`

All three are configurable via format strings.

### Address Format

Addresses use a configurable `printf`-style format with two `%d` placeholders
(floor number, user increment). Default: `@f%d/usr%d`.

## Compatibility

- Tested with game version: 0.10.11+
- Compatible with other mods that don't modify user network settings
- Works alongside device modification mods and reward scaling mods (e.g. `floor-reward-scaling`)
