# ui-config.ps1 - ModAPI Diagnostic Tool v4.4
# Enables the game debug console (~) and provides developer inspection tools

<#
.SYNOPSIS
    Generates UI configuration for the ModAPI Diagnostic Tool.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    The diagnostic tool is a zero-overhead development/debugging tool with:
    - Event logging (device/user/location spawn, day events)
    - Lifecycle callback tracker (init order and timing)
    - JSON game state export (console command or auto on day-end)
    - Comprehensive API test suite (console command)
    - Network configuration inspection
    
    NOTE: on_player_input has been removed. All features are available
    via Lua console commands and automatic lifecycle hooks.
    
.PARAMETER CurrentConfig
    The current configuration values for this mod.
#>

param(
    [hashtable]$CurrentConfig = @{}
)

# Initialize parameters array
$parameters = @()

# ============================================================================
# Diagnostic Tool Information
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "About ModAPI Diagnostic Tool v4.4"
    Description = "Developer tool for inspecting game engine callbacks, exporting game state, and testing API endpoints"
}

$parameters += @{
    Type  = "info"
    Label = "Purpose"
    Text  = @"
Diagnostic tool for mod developers (game version 0.10.11+).
Also enables the game's built-in debug console (~ key, disabled by default).

Features:
• All 16 lifecycle callbacks registered (on_game_state_ready, on_location_spawned, on_game_host_eod, etc.)
• Lifecycle callback tracker — shows exact init order and timing
• Device, user, and location spawn logging with network configuration
• Day start/end events with auto-export option
• JSON game state export (console command or auto on day-end)
• Comprehensive API endpoint test suite

Usage: Press ~ to open the debug console, then type a command name:
  dump_world_overview      inspect_locations
  dump_all_world_devices   reinspect_all_users
  export_to_json           run_api_test_suite
  show_lifecycle_log       export_test_results_json
"@
}

# ============================================================================
# Event Logging Options
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Event Logging Options"
    Description = "Control what events are logged to the console"
}

$parameters += @{
    Name        = "enable_device_logging"
    Label       = "Enable Device Spawn Logging"
    Type        = "boolean"
    Default     = $true
    Description = "Log detailed information when devices are spawned (on_device_spawned callback)"
}

$parameters += @{
    Name        = "enable_user_logging"
    Label       = "Enable User Spawn Logging"
    Type        = "boolean"
    Default     = $true
    Description = "Log detailed information when users are spawned (on_user_spawned callback)"
}

$parameters += @{
    Name        = "enable_location_logging"
    Label       = "Enable Location Spawn Logging"
    Type        = "boolean"
    Default     = $true
    Description = "Log when floors/locations are spawned (on_location_spawned callback)"
}

$parameters += @{
    Name        = "enable_day_events"
    Label       = "Enable Day Event Logging"
    Type        = "boolean"
    Default     = $true
    Description = "Log day start/end events (on_day_start and on_day_end callbacks)"
}

$parameters += @{
    Name        = "enable_network_inspection"
    Label       = "Enable Network Configuration Inspection"
    Type        = "boolean"
    Default     = $true
    Description = "Inspect network settings, DHCP, DNS servers for devices and users"
}

# ============================================================================
# Auto-trigger Options
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Auto-trigger Options"
    Description = "Control when diagnostics run automatically"
}

$parameters += @{
    Name        = "auto_diag_on_ready"
    Label       = "Auto-diagnostics on Game State Ready"
    Type        = "boolean"
    Default     = $true
    Description = "Run dump_world_overview(), inspect_locations(), and device breakdown automatically when on_game_state_ready fires (world is guaranteed valid at this point)"
}

$parameters += @{
    Name        = "auto_export_on_day_end"
    Label       = "Auto-export JSON on Day End"
    Type        = "boolean"
    Default     = $false
    Description = "Automatically export full game state to JSON at the end of each in-game day. Useful for continuous external tool integration. Writes to mod dir via ModFileSystem, falls back to log output."
}

# ============================================================================
# JSON Export Options
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "JSON Export Options"
    Description = "Configure what data is included in JSON export (export_to_json() console command)"
}

$parameters += @{
    Name        = "json_include_devices"
    Label       = "Include Devices"
    Type        = "boolean"
    Default     = $true
    Description = "Include all device data (switches, routers, servers, etc.)"
}

$parameters += @{
    Name        = "json_include_users"
    Label       = "Include Users"
    Type        = "boolean"
    Default     = $true
    Description = "Include all user data (profiles, locations, network config)"
}

$parameters += @{
    Name        = "json_include_locations"
    Label       = "Include Locations/Floors"
    Type        = "boolean"
    Default     = $true
    Description = "Include all floor/location data"
}

$parameters += @{
    Name        = "json_include_finances"
    Label       = "Include Financial Data"
    Type        = "boolean"
    Default     = $true
    Description = "Include cash balance, transactions, payment breakdowns"
}

$parameters += @{
    Name        = "json_include_network"
    Label       = "Include Network Tables"
    Type        = "boolean"
    Default     = $true
    Description = "Include DNS lookup table and network address mappings"
}

$parameters += @{
    Name        = "json_include_play_options"
    Label       = "Include Play Options"
    Type        = "boolean"
    Default     = $true
    Description = "Include game play options (difficulty settings, freeplay mode, etc.)"
}

$parameters += @{
    Name        = "json_include_statistics"
    Label       = "Include Game Statistics"
    Type        = "boolean"
    Default     = $true
    Description = "Include game statistics (user counts, device counts, bandwidth, etc.)"
}

$parameters += @{
    Name        = "json_include_loans"
    Label       = "Include Loans"
    Type        = "boolean"
    Default     = $true
    Description = "Include player loan data"
}

$parameters += @{
    Name        = "json_include_hostings"
    Label       = "Include Hosting Contracts"
    Type        = "boolean"
    Default     = $true
    Description = "Include player hosting contract data"
}

$parameters += @{
    Name        = "json_include_merchants"
    Label       = "Include Merchants"
    Type        = "boolean"
    Default     = $true
    Description = "Include device merchant data with full listing inventory (price, stock, availability)"
}

$parameters += @{
    Name        = "json_include_messages"
    Label       = "Include Player Messages"
    Type        = "boolean"
    Default     = $true
    Description = "Include in-game player messages/emails"
}

$parameters += @{
    Name        = "json_include_floor_builders"
    Label       = "Include Floor Builders"
    Type        = "boolean"
    Default     = $true
    Description = "Include floor builder configuration (build options, intervals, dates)"
}

$parameters += @{
    Name        = "json_include_link_controller"
    Label       = "Include Link Controller"
    Type        = "boolean"
    Default     = $true
    Description = "Include network link controller data (active links count)"
}

$parameters += @{
    Name        = "json_include_acquired_techs"
    Label       = "Include Acquired Technologies"
    Type        = "boolean"
    Default     = $true
    Description = "Include list of unlocked technologies"
}

# ============================================================================
# API Test Suite Options
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "API Test Suite Options"
    Description = "Configure which API endpoints are tested by run_api_test_suite()"
}

$parameters += @{
    Name        = "test_mod_api"
    Label       = "Test Mod API (ModApiV1, Mod global)"
    Type        = "boolean"
    Default     = $true
    Description = "Test all ModApiV1 endpoints: sanity(), get_game_world(), get_devices(), get_users(), get_locations(), get_merchants(), get_game_version(), has_mods_reloaded(). Also tests Mod global fields (mod_dir, manifest, filesystem, config)."
}

$parameters += @{
    Name        = "test_game_world"
    Label       = "Test GameWorld Properties"
    Type        = "boolean"
    Default     = $true
    Description = "Test GameWorld properties: scenario_name, n_days, play_options, locations, etc."
}

$parameters += @{
    Name        = "test_devices_api"
    Label       = "Test Device API"
    Type        = "boolean"
    Default     = $true
    Description = "Test DeviceUnit properties: product_name, logic_controller, power_controller, etc."
}

$parameters += @{
    Name        = "test_users_api"
    Label       = "Test User API"
    Type        = "boolean"
    Default     = $true
    Description = "Test User properties: username, daily_rate, satiety_ratio, location, etc."
}

$parameters += @{
    Name        = "test_network_api"
    Label       = "Test Network/Control Modules"
    Type        = "boolean"
    Default     = $true
    Description = "Test all LogicController control modules: networkctl, routectl, firewallctl, vlanctl, dhcpctl, filesysctl, packetctl"
}

$parameters += @{
    Name        = "test_locations_api"
    Label       = "Test Locations API"
    Type        = "boolean"
    Default     = $true
    Description = "Test Location properties: display_name, floor_num, is_datacenter, surge/outage immunity, spawn_limit, builder_weight"
}

$parameters += @{
    Name        = "test_merchants_api"
    Label       = "Test Merchants API"
    Type        = "boolean"
    Default     = $true
    Description = "Test DeviceMerchant properties and methods: display_name, price_multiplier, listings, restock(), submit_order()"
}

$parameters += @{
    Name        = "test_programs_api"
    Label       = "Test Programs API"
    Type        = "boolean"
    Default     = $true
    Description = "Test Program properties on installed programs: release_name, is_running, cpu_load, code_size, stack_size, install_size"
}

$parameters += @{
    Name        = "test_world_methods"
    Label       = "Test GameWorld Methods"
    Type        = "boolean"
    Default     = $true
    Description = "Test safe, read-only GameWorld methods: lookup_domain(), get_loc_index(). Also verifies method presence for: send_player_message, put_dns_entry, modify_player_cash, etc."
}

$parameters += @{
    Name        = "test_filesystem_api"
    Label       = "Test FileSystem API"
    Type        = "boolean"
    Default     = $true
    Description = "Test ModFileSystem: get_files_at(), get_directories_at(), open() for read, mod_path_to_real()"
}

$parameters += @{
    Name        = "verbose_mode"
    Label       = "Verbose Test Output"
    Type        = "boolean"
    Default     = $false
    Description = "Show detailed results for all tests (not just failures)"
}

# ============================================================================
# Advanced Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Advanced Settings"
    Description = "Control diagnostic behavior"
}

$parameters += @{
    Name        = "max_dump_depth"
    Label       = "Maximum Table Dump Depth"
    Type        = "integer"
    Default     = 2
    Min         = 1
    Max         = 5
    Description = "How deep to recursively dump table contents (higher = more detail, more spam)"
}

$parameters += @{
    Name        = "track_users_for_reinspection"
    Label       = "Track Users for Re-inspection"
    Type        = "boolean"
    Default     = $true
    Description = "Keep references to spawned users for the reinspect_all_users console command"
}

$parameters += @{
    Name        = "show_notification"
    Label       = "Show In-Game Notifications"
    Type        = "boolean"
    Default     = $true
    Description = "Display in-game notifications when auto-diagnostics complete. Console messages are always shown."
}

# ============================================================================
# Usage Information
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Usage Tips"
    Description = "How to use this diagnostic tool effectively"
}

$parameters += @{
    Type  = "info"
    Label = "Getting Started"
    Text  = @"
1. Enable this mod and start a game
2. The debug console (~) is automatically enabled on startup
3. Press ~ to open the console and type a command name (no parentheses needed)
4. Watch [DIAG] prefixed messages in the game log for spawn events

Console Commands:
  dump_world_overview       Quick summary: day, cash, counts
  inspect_locations         List all floors with user counts
  dump_all_world_devices    List devices with class/condition
  reinspect_all_users       Re-inspect tracked user network configs
  export_to_json            Export full game state to JSON
  run_api_test_suite        Test all API endpoints (reports pass/fail)
  export_test_results_json  Export test results as JSON
  show_lifecycle_log        Show callback order and timing

Lifecycle Tracker:
  Type show_lifecycle_log to see exactly which callbacks fired,
  in what order, and at what time. Essential for diagnosing init
  timing issues in your own mods.

JSON Export:
  Writes to diagnostic-export.json via ModFileSystem if available,
  otherwise outputs between JSON GAME STATE START/END log markers.
  Enable auto_export_on_day_end for continuous state capture.
"@
}

# Return the configuration
return $parameters
