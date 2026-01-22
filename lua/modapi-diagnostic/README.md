# ModAPI Diagnostic Tool

THIS MOD IS FOR MOD DEVELOPERS!

This mod provides comprehensive diagnostic capabilities for The Network Inc's mod system, including detailed inspection of spawned objects and their properties.

## Purpose

- Enumerate all methods available on ModApiV1
- Test various possible callback function names
- Inspect user network configurations in detail
- Track spawned users for re-inspection after manual changes
- Determine when game world and PlayOptions become accessible
- Discover the correct timing to modify game settings

## Usage

1. Place in `lua/modapi-diagnostic/`
2. Load the game and check console output
3. Look for `[DIAGNOSTIC]` prefixed messages
4. Note which callbacks are actually invoked

### Keyboard Shortcuts

- **Shift+R**: Re-inspect all spawned users (useful after manually setting DNS or other network configs)

### Console Commands

You can also use the Lua console to manually trigger inspection:

- `reinspect_all_users()` - Re-inspects all tracked users and displays their current network configuration

## What It Tests

### Callbacks Tested:

- on_engine_load()
- on_mod_reload()
- on_world_ready()
- on_world_created()
- on_game_start()
- on_scenario_start()
- on_world_init()
- on_playoptions_init()
- on_play_options_created()
- before_world_create()
- on_device_spawned()
- on_user_spawned()
- on_day_start()
- on_day_end()
- on_player_input() (for keyboard shortcuts)

### User Network Inspection

When users spawn, the tool automatically inspects:

- User hardware address
- DHCP mode setting
- Network address
- DNS server array (attempts multiple read methods)
- Location properties (floor number, etc.)

Users are tracked in memory, allowing re-inspection after manual configuration changes via console commands like `net dns set @f0/dns1 @f0/dns2 on <hwaddr>`.

### API Methods Checked:

- ModApiV1 availability and methods
- Mod global
- Engine global
- When get_game_world() returns valid data
- When play_options becomes accessible
