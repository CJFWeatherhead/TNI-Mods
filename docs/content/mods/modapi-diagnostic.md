---
title: "ModAPI Diagnostic Tool"
date: 2026-02-08
draft: false
mod_id: "modapi-diagnostic"
author: "CJFWeatherhead"
version: "3.0.6"
status: "Active Development"
game_version: "beta"
---

# ModAPI Diagnostic Tool

Comprehensive diagnostic, inspection, and API testing tool for TNI game engine.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 3.0.6 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-02-08 |

</div>

---

## Download

<div class="download-section">

**[Download modapi-diagnostic-3.0.6.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/modapi-diagnostic-v3.0.6/modapi-diagnostic-3.0.6.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **ModAPI Diagnostic Tool** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `modapi-diagnostic/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## About This Mod

Comprehensive diagnostic, inspection, and API testing tool for TNI game engine.

## Features v3.0

### Event Logging
- **Engine Event Logging**: Tracks engine load, mod reload, and game lifecycle events
- **Device Spawn Inspection**: Logs detailed device properties and network configuration
- **User Spawn Analysis**: Comprehensive user property inspection with network/DNS details
- **Network Configuration Monitoring**: Track DHCP settings, IP addresses, and DNS servers

### JSON Game State Export (Shift+J)
- Export complete game state to JSON file
- Configurable data sections (devices, users, finances, network, etc.)
- Designed for external tool integration (Terraform, REST APIs)
- Human-readable formatted output

### API Test Suite (Shift+Q)
- Comprehensive testing of all ModApiV1 endpoints
- Tests GameWorld, DeviceUnit, User, NetworkControl APIs
- Reports passed/failed/skipped with detailed output
- Export test results as JSON for documentation

### Keyboard Shortcuts
- **Shift+R**: Re-inspect all spawned users
- **Shift+D**: Dump all devices in the world
- **Shift+J**: Export game state to JSON
- **Shift+Q**: Run API test suite (Query)

### Lua Console Commands
- `reinspect_all_users()` - Re-inspect user network configs
- `dump_all_world_devices()` - List all devices
- `inspect_scenes()` - Inspect available floors
- `export_to_json_file()` - Export JSON state
- `run_api_test_suite()` - Run API tests
- `export_test_results_json()` - Export test results

## Use Cases
- Debug mod development issues
- Export game state for external automation tools
- Test and document API endpoint availability
- Understand game object structures
- Track network configurations
- Build Terraform/OpenTofu providers

## Output
All diagnostic information is printed to the game console. JSON exports are
saved to files in the mod directory.

---

<details>
<summary><strong>Full Documentation</strong></summary>

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


</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

This is a developer tool for mod creators and external tool integrations.
No gameplay impact. Ideal for:
- Mod developers learning the API
- Building REST API bridges
- Terraform/OpenTofu provider development
- Game state analysis and automation


</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `modapi-diagnostic` |
| Creation Date | 2026-01-20 |
| Last Updated | 2026-02-08 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/modapi-diagnostic](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/modapi-diagnostic) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/modapi-diagnostic-v3.0.6)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/modapi-diagnostic-v3.0.6/modapi-diagnostic-3.0.6.zip)

</details>

---

[Back to All Mods](/mods/)
