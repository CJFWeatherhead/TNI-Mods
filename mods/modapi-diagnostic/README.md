# ModAPI Diagnostic Tool v3.0

THIS MOD IS FOR MOD DEVELOPERS AND EXTERNAL TOOL INTEGRATION!

This mod provides comprehensive diagnostic capabilities for Tower Networking Inc's mod system, including detailed inspection of spawned objects, JSON game state export, and API endpoint testing.

## What's New in v3.0

- **JSON Game State Export (Shift+J)**: Export complete game state to logs for external tools
- **API Test Suite (Shift+Q)**: Comprehensive testing of all documented API endpoints
- **Enhanced Configuration**: UI config with selectable data sections and test categories
- **In-Game Notifications**: Visual feedback for all operations

## Purpose

- Enumerate all methods available on ModApiV1
- Test various possible callback function names
- Inspect user network configurations in detail
- Track spawned users for re-inspection after manual changes
- **Export game state as JSON for REST API bridges**
- **Test and document API endpoint availability**
- Determine when game world and PlayOptions become accessible
- Discover the correct timing to modify game settings

## Usage

1. Place in `mods/modapi-diagnostic/`
2. Load the game and check console output
3. Look for `[DIAGNOSTIC]` prefixed messages
4. Use keyboard shortcuts for interactive features

### Keyboard Shortcuts

| Shortcut | Function | Description |
|----------|----------|-------------|
| **Shift+R** | Re-inspect Users | Re-inspect all spawned users' network configs |
| **Shift+D** | Dump Devices | List all devices in the world |
| **Shift+J** | Export JSON | Export game state to logs (copy from console) |
| **Shift+Q** | API Test Suite | Run comprehensive API endpoint tests |

### Console Commands

You can also use the Lua console to manually trigger functions:

```lua
reinspect_all_users()      -- Re-inspect all tracked users
dump_all_world_devices()   -- List all devices with details
inspect_scenes()           -- Inspect available floors/locations
export_to_json_file()      -- Export game state to JSON
run_api_test_suite()       -- Run API endpoint tests
export_test_results_json() -- Export test results as JSON
```

## JSON Export (Shift+J)

The JSON export feature outputs a comprehensive snapshot of game state to the game logs. The output appears between `=== JSON GAME STATE START ===` and `=== JSON GAME STATE END ===` markers.

**Note**: Due to sandbox restrictions, mods cannot write files to disk. Copy the JSON from the game logs/console instead.

Includes:

- **World Info**: Day count, cash balance, scenario name, difficulty
- **Devices**: All devices with hardware class, network config, specs
- **Users**: All users with profiles, locations, network settings
- **Locations**: All floors with display names and properties
- **Finances**: Cash balance, transactions, payment breakdowns
- **Network**: DNS lookup tables, network address mappings
- **Statistics**: Game statistics (user counts, bandwidth, etc.)
- **Loans**: Player loan data
- **Hostings**: Player hosting contracts
- **Merchants**: Device merchant data

### Example JSON Output Structure

```json
{
  "_metadata": {
    "mod_version": "3.0",
    "export_timestamp": 1706745600,
    "export_date": "2026-02-01T12:00:00"
  },
  "world": {
    "scenario_name": "career_mode",
    "n_days": 15,
    "player_cash_balance": 25000.50
  },
  "devices": [...],
  "users": [...],
  "locations": [...],
  "finances": {...},
  "statistics": {...}
}
```

## API Test Suite (Shift+Q)

The test suite validates all documented API endpoints and reports:

- **ModApiV1**: sanity(), get_game_world(), get_devices(), get_users(), etc.
- **Mod Global**: mod_dir, mod_type, filesystem, config
- **GameWorld**: scenario_name, n_days, play_options, locations, etc.
- **DeviceUnit**: product_name, device_hardware_class, logic_controller
- **User**: username, daily_rate, satiety_ratio, location
- **NetworkControlModule**: hardware_address, network_address, dhcp_enabled
- **ModFileSystem**: get_files_at(), get_directories_at(), open()

### Test Output Example

```
[DIAGNOSTIC] ========== Test Results Summary ==========
[DIAGNOSTIC] Total: 45 | Passed: 42 | Failed: 2 | Skipped: 1

[DIAGNOSTIC] Failed Tests:
[DIAGNOSTIC]   ✗ GameWorld.get_game_settings: Method not available
[DIAGNOSTIC]   ✗ ModFileSystem.write: Permission denied
```

## Configuration

Use the PowerShell UI config to customize:

### Event Logging
- Enable/disable device spawn logging
- Enable/disable user spawn logging
- Enable/disable day event logging
- Enable/disable network inspection

### JSON Export Options
- Select which data sections to include
- Set custom export filename
- Toggle individual categories (devices, users, finances, etc.)

### API Test Suite Options
- Select which API categories to test
- Enable verbose mode for detailed output
- Toggle individual test groups

## What It Tests

### Callbacks Tested:

- on_engine_load()
- on_mod_reload()
- on_world_ready()
- on_world_created()
- on_game_start()
- on_scenario_start()
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
- DNS server array
- Location properties (floor number, etc.)

### API Methods Checked:

- ModApiV1 availability and all methods
- Mod global properties
- Engine global
- GameWorld properties and methods
- DeviceUnit properties
- User properties
- NetworkControlModule
- ModFileSystem operations

## External Tool Integration

This mod is designed to support external tools:

### REST API Bridge
Export game state via JSON and use a file watcher or polling mechanism to serve via HTTP.

### Terraform/OpenTofu Provider
Use the JSON export as a data source for infrastructure-as-code tooling:

```hcl
data "tni_game_state" "current" {
  json_file = "game_state.json"
}

resource "tni_device" "new_switch" {
  depends_on = [data.tni_game_state.current]
  # ...
}
```

### Log File Streaming
Combine with game log file parsing for real-time event streaming.
