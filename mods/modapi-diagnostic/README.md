# ModAPI Diagnostic Tool v4.0

Development tool for TNI game engine modding (0.10.11+).

**FOR MOD DEVELOPERS AND EXTERNAL TOOL INTEGRATION**

## What's New in v4.0

- **Removed `on_player_input` entirely** — eliminates the per-frame pcall/GC memory pressure that caused the memory leak in v3.x
- **Added `on_game_state_ready`** — the correct entrypoint for post-init diagnostics (world guaranteed valid)
- **Added all missing callbacks**: `on_mod_load`, `on_mods_loaded`, `on_game_host_eod`, `on_location_spawned`
- **Lifecycle tracker** — records exact callback order and timing for debugging init issues
- **Expanded API coverage** for game version 0.10.11: new PlayOptions fields, LogicControllerUser fields, all control modules, NETWORK_STORAGE device class, GameWorld methods
- **New API getters tested**: `get_locations()`, `get_merchants()`, `get_game_version()`, `has_mods_reloaded()`
- **File write support** — JSON export tries `ModFileSystem` before falling back to log output

## Usage

1. Place in `mods/modapi-diagnostic/`
2. Load the game — `on_game_state_ready` runs automatic diagnostics
3. Use console commands for interactive features
4. Check `[DIAG]` prefixed messages in the game console

### Console Commands

```lua
dump_world_overview()       -- Quick world summary (day, cash, counts)
inspect_locations()         -- List all floors with user counts
dump_all_world_devices()    -- List all devices with class/condition
reinspect_all_users()       -- Re-inspect tracked users' network configs
export_to_json()            -- Export full game state to JSON
run_api_test_suite()        -- Test all API endpoints
export_test_results_json()  -- Export test results as JSON
show_lifecycle_log()        -- Show callback order and timing
```

### Auto-triggers

| Trigger | Config Key | Default |
|---------|-----------|---------|
| Diagnostics on game ready | `auto_diag_on_ready` | `true` |
| JSON export on day end | `auto_export_on_day_end` | `false` |

## Lifecycle Callbacks

All 16 known callbacks are registered. Use `show_lifecycle_log()` to see the exact order they fired:

```
[DIAG]    1. [0.0012s] on_mod_load -- mod binary/script loaded
[DIAG]    2. [0.0015s] on_mods_loaded -- all mods finished loading
[DIAG]    3. [0.0340s] on_engine_load
[DIAG]    4. [0.1200s] on_game_state_ready -- game fully initialized
[DIAG]    5. [0.1500s] on_location_spawned -- Floor 1: Lobby
[DIAG]    6. [0.1800s] on_device_spawned -- Switch-8 (NETWORK_SWITCH)
...
```

### Complete Callback List

| Callback | When | v3.x? |
|----------|------|-------|
| `on_mod_load()` | Mod script loaded | NEW |
| `on_mods_loaded()` | All mods loaded | NEW |
| `on_engine_load()` | Engine startup | Yes |
| `on_game_state_ready()` | World fully initialized | NEW |
| `on_game_host_eod()` | End-of-day host processing | NEW |
| `on_mod_reload()` | F11 mod reload | Yes |
| `on_device_spawned(device)` | Device placed | Yes |
| `on_user_spawned(user)` | Customer appears | Yes |
| `on_location_spawned(location)` | Floor spawned | NEW |
| `on_day_start()` | Day begins | Yes |
| `on_day_end()` | Day ends | Yes |
| `on_tick(delta)` | Every frame (empty) | Yes |
| `on_world_ready(world)` | World ready | Yes |
| `on_world_created(world)` | World created | Yes |
| `on_game_start(world)` | Game session starts | Yes |
| `on_scenario_start(world)` | Scenario begins | Yes |

## JSON Export

`export_to_json()` outputs a comprehensive game state snapshot. Tries writing to `diagnostic-export.json` via ModFileSystem, falls back to log output between `=== JSON GAME STATE START ===` / `=== JSON GAME STATE END ===` markers.

### Data Sections

| Section | Config Key | Content |
|---------|-----------|---------|
| World | always | Day, cash, scenario, difficulty |
| Play Options | `json_include_play_options` | All PlayOptions fields (expanded in 0.10.11) |
| Devices | `json_include_devices` | Full device tree with logic/power controllers |
| Users | `json_include_users` | LogicControllerUser fields, visitor stats |
| Locations | `json_include_locations` | Floors with user counts |
| Finances | `json_include_finances` | Transactions, payment breakdown |
| Network | `json_include_network` | DNS lookup, network address tables |
| Statistics | `json_include_statistics` | Game statistics |
| Loans | `json_include_loans` | Player loans |
| Hostings | `json_include_hostings` | Player hosting contracts |
| Merchants | `json_include_merchants` | Merchants with full listing data |
| Messages | `json_include_messages` | Player messages |
| Floor Builders | `json_include_floor_builders` | Floor build config |
| Link Controller | `json_include_link_controller` | Network links |
| Acquired Techs | `json_include_acquired_techs` | Unlocked technologies |

## API Test Suite

`run_api_test_suite()` tests all documented API endpoints:

- **ModApiV1**: sanity, get_game_world, get_devices, get_users, get_locations, get_merchants, get_game_version, has_mods_reloaded
- **Mod Global**: mod_dir, mod_type, manifest, filesystem, config
- **GameWorld**: 17 properties + 8 methods (send_player_message, put_dns_entry, lookup_domain, etc.)
- **DeviceUnit**: 10 properties + methods
- **User/LogicControllerUser**: Base + extended fields (payment_calculation_method, csr, vsr, etc.)
- **Locations**: display_name, floor_num, is_datacenter, surge/outage immunity, etc.
- **Network/Control Modules**: networkctl, routectl, firewallctl, vlanctl, dhcpctl, filesysctl, packetctl
- **Merchants**: Properties + restock/submit_order methods
- **Programs**: release_name, cpu_load, install_size, etc.
- **FileSystem**: get_files_at, get_directories_at, open/read, mod_path_to_real
- **GameWorld Methods**: lookup_domain, get_loc_index (safe read-only calls)

## Why No Keyboard Shortcuts?

v3.x used `on_player_input` for Shift+R/D/J/Q shortcuts. This callback fires on **every input event** including mouse movement, requiring pcall overhead on every frame. Even with named function helpers and incremental GC steps, this caused measurable memory pressure.

v4.0 removes input handling entirely. All functionality is available through console commands (which only run when you explicitly call them) and automatic lifecycle hooks (`on_game_state_ready`, `on_day_end`).

## Device Hardware Classes (0.10.11)

| ID | Name |
|----|------|
| 0 | DEFAULT |
| 1 | NETWORK_SWITCH |
| 2 | NETWORK_ROUTER |
| 3 | NETWORK_TAP |
| 4 | NETWORK_FIREWALL |
| 5 | MEDIA_LINE_SIMPLEX |
| 6 | MEDIA_LINE_DUPLEX |
| 7 | COMPUTE_SERVER |
| 8 | DISPLAY_MONITOR |
| 9 | DEBUGGER |
| 10 | LOAD_TESTER |
| 11 | POWER_EXPANSION |
| 12 | DECENTRO_RIGS |
| 13 | SURGE_PROTECTOR |
| 14 | UPS |
| 15 | INERT |
| 16 | CCTV |
| 17 | PHONE |
| 18 | PRINTER |
| 19 | NETWORK_LOAD_BALANCER |
| 20 | NETWORK_STORAGE |
