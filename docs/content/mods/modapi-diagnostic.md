---
title: "ModAPI Diagnostic Tool"
date: 2026-04-18
draft: false
mod_id: "modapi-diagnostic"
author: "CJFWeatherhead"
version: "4.0.4"
status: "Active Development"
game_version: "beta"
---

# ModAPI Diagnostic Tool

Zero-overhead development tool for TNI game engine modding (0.10.11+).

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 4.0.4 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-04-18 |

</div>

---

## Download

<div class="download-section">

**[Download modapi-diagnostic-4.0.4.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/modapi-diagnostic-v4.0.4/modapi-diagnostic-4.0.4.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

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

Zero-overhead development tool for TNI game engine modding (0.10.11+).

## v4.0 — Zero-overhead rewrite

### Architecture
- **REMOVED on_player_input** — eliminates per-frame pcall/GC memory pressure
- All functionality via console commands and automatic lifecycle hooks
- Lifecycle callback tracker shows exact init order and timing

### All Lifecycle Callbacks
- on_mod_load, on_mods_loaded, on_engine_load
- **on_game_state_ready** (auto-diagnostic on game init)
- on_game_host_eod, on_mod_reload
- on_device_spawned, on_user_spawned, **on_location_spawned**
- on_day_start, on_day_end, on_tick
- on_world_ready, on_world_created, on_game_start, on_scenario_start

### JSON Game State Export
- All 0.10.11 fields: PlayOptions, LogicControllerUser, FloorBuilders
- New sections: player_messages, link_controller, acquired_techs
- File write via ModFileSystem + log fallback
- Auto-export on day end (configurable)

### API Test Suite
- Tests get_locations(), get_merchants(), get_game_version()
- Tests all control modules: networkctl, routectl, firewallctl, vlanctl, dhcpctl, filesysctl, packetctl
- Tests GameWorld methods, Programs API, Merchants API
- NETWORK_STORAGE (class 20) device support

### Console Commands
- `dump_world_overview()` — quick world summary
- `inspect_locations()` — list all floors
- `dump_all_world_devices()` — list all devices
- `reinspect_all_users()` — re-inspect tracked users
- `export_to_json()` — export full game state
- `run_api_test_suite()` — test all API endpoints
- `export_test_results_json()` — export test results
- `show_lifecycle_log()` — show callback order and timing

## Use Cases
- Debug mod development issues
- Export game state for external automation tools
- Test and document API endpoint availability
- Diagnose callback init order and timing
- Build Terraform/OpenTofu providers

---

<details>
<summary><strong>Full Documentation</strong></summary>

# ModAPI Diagnostic Tool v4.4

Development tool for TNI game engine modding (0.10.11+).

**FOR MOD DEVELOPERS AND EXTERNAL TOOL INTEGRATION**

## What's New in v4.4

- **Debug console activation** — the game ships with `DebugLayer.enabled = false`. This mod sets it to `true` on startup, making the `~` key open the debug console
- **All commands in debug console** — type command names directly (no parentheses)
- **Netsh terminal documented** — 23 built-in terminal routines mapped (see [Netsh Terminal Reference](#netsh-terminal-reference))

### What was new in v4.3

- **Debug console integration** — all commands registered with `DebugLayer.register_cmd()`
- **Removed sandbox probes** — findings documented below in [Sandbox API Reference](#sandbox-api-reference)

### What was new in v4.0

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

Open the debug console with `~` and type the command name (no parentheses needed):

```
dump_world_overview       -- Quick world summary (day, cash, counts)
inspect_locations         -- List all floors with user counts
dump_all_world_devices    -- List all devices with class/condition
reinspect_all_users       -- Re-inspect tracked users' network configs
export_to_json            -- Export full game state to JSON
run_api_test_suite        -- Test all API endpoints
export_test_results_json  -- Export test results as JSON
show_lifecycle_log        -- Show callback order and timing
```

Commands are also available as `globals()` for direct Lua calls.

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

v3.x used `on_player_input` for Shift+R/D/J/Q shortcuts. This callback fires on **every input event** including mouse movement, and the C++ bridge crashes (`bad_cast: Variant is not an Object for Variant of type 0 (Nil)`) when pushing InputEvent userdata to the Lua stack. This happens *before* any Lua code executes, making it unfixable from Lua. Even without the crash, the per-frame pcall/GC overhead caused OOM in the ~1800-byte Lua arena.

v4.4 enables the game's built-in debug console (`DebugLayer`) and registers commands with `register_cmd()`. Commands only run when explicitly invoked — zero per-frame overhead.

## Sandbox API Reference

Tested on game version 0.10.15. These findings document what the RISC-V mod sandbox permits.

### BLOCKED — Will Not Work

| API | Result | Notes |
|-----|--------|-------|
| `Engine.get_singleton(name)` | **BANNED** | "Banned property accessed: get_singleton" — applies to ALL singletons |
| `on_player_input(event)` | **CRASH** | C++ `bad_cast` in `push_gd_object_metatable` before Lua runs |
| Direct `Input` access | Impossible | Requires `Engine.get_singleton("Input")` which is banned |
| Direct `InputMap` access | Impossible | Same reason |
| Key polling in `on_tick` | Impossible | No way to obtain `Input` singleton |

### WORKS — Safe to Use

| API | How to Access | Notes |
|-----|---------------|-------|
| `DebugLayer` | `world.get_node("/root/DebugLayer")` | Game's debug console overlay |
| `DebugLayer.enabled = true` | Property set | **Required** — disabled by default, enables `~` key |
| `DebugLayer.visible = true` | Property set | **Required** — hidden by default |
| `DebugLayer.register_cmd(name, func)` | On the node above | Registers commands in `~` console |
| `DebugLayer.print_console(msg)` | On the node above | Writes to debug console display |
| `Engine.has_singleton(name)` | Direct call | Returns true/false, not banned |
| `create_node("InputEventKey")` | Direct call | Can create and configure input events |
| `InputEventKey` properties | `.keycode`, `.pressed`, `.shift_pressed` | All settable |
| `MobileOSLayer` | `world.mobile_os_cvl` | Game state layer (16 children) |
| `MobileOSLayer.at_netshell_screen` | On above | Boolean — is netsh terminal open? |
| `MobileOSLayer.safe_to_use_keyboard` | On above | Boolean — can type? |
| `MobileOSLayer.find_child("*Shell*")` | Recursive search | Finds `NetShell` (VBoxContainer) |
| `NetShell.terminal_routines` | Array property | 23 built-in routines (read-only) |
| `NetShell.has_terminal_routine(name)` | Method call | Check if routine exists |
| `NetShell.exec_command(cmdstr, stdout)` | Method call | Execute existing terminal commands |
| `world.get_node(path)` | Scene tree traversal | Arbitrary scene tree access works |
| `ModApiV1.get_game_world()` | Direct call | Game world reference |
| `ModApiV1.get_base_ui()` | Direct call | UI reference for notifications |

### Command Registration Pattern

The recommended pattern for exposing mod commands:

```lua
-- 1. Define as global (fallback for direct Lua calls)
function my_command()
    print("Hello from my mod!")
end

-- 2. Enable debug console and register in on_game_state_ready
function on_game_state_ready()
    local world = ModApiV1.get_game_world()
    if not world then return end

    local ok, dbg = pcall(function()
        return world.get_node("/root/DebugLayer")
    end)
    if not ok or not dbg then
        print("[my-mod] DebugLayer not found")
        return
    end

    -- Enable the debug console (disabled by default)
    pcall(function() dbg.enabled = true end)
    pcall(function() dbg.visible = true end)

    pcall(function() dbg.register_cmd("my_command", my_command) end)
end
```

Players can then open the debug console with `~` and type `my_command`.

## Netsh Terminal Reference

The in-game "netsh" terminal (the pseudo gameplay terminal on the player's monitor) is
separate from the debug console. It is a `NetShell` (VBoxContainer) found via
`world.mobile_os_cvl.find_child("*Shell*")`.

### Built-in Terminal Routines (23)

| # | Name | Description |
|---|------|-------------|
| 0 | `man` | Manual / help |
| 1 | `alias` | Command aliases |
| 2 | `quit` | Exit terminal |
| 3 | `clear` | Clear screen |
| 4 | `lstdbg` | List debuggers |
| 5 | `god` | God mode |
| 6 | `scan` | Network scan |
| 7 | `trace` | Packet trace |
| 8 | `watch` | Watch mode |
| 9 | `program` | Program management |
| 10 | `always` | Always-on rules |
| 11 | `ping` | Ping host |
| 12 | `route` | Routing table |
| 13 | `pcap` | Packet capture |
| 14 | `net` | Network config |
| 15 | `dns` | DNS lookup |
| 16 | `firewall` | Firewall rules |
| 17 | `dhcp` | DHCP config |
| 18 | `echo` | Echo text |
| 19 | `dstat` | Device status |
| 20 | `vlan` | VLAN config |
| 21 | `stp` | Spanning tree |
| 22 | `middlebox` | Middlebox config |

### Netsh Injection — Not Currently Possible

Custom commands **cannot** be injected into the netsh terminal because:
- `TerminalRoutine` subclasses are not registered in `create_node()` — they cannot be instantiated from Lua
- The `terminal_routines` array can be read but appending requires a valid `TerminalRoutine` instance
- `AliasRoutine.alias_expand()` only does string→string substitution between existing commands
- The netsh reports `unknown routine` for any unregistered command name

Use the debug console (`~`) for mod commands instead.

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
| Last Updated | 2026-04-18 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/modapi-diagnostic](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/modapi-diagnostic) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/modapi-diagnostic-v4.0.4)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/modapi-diagnostic-v4.0.4/modapi-diagnostic-4.0.4.zip)

</details>

---

[Back to All Mods](/mods/)
