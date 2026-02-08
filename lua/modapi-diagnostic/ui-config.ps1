# ui-config.ps1 - ModAPI Diagnostic Tool v3.0
# Extended UI Configuration Script with JSON Export & API Test Suite

<#
.SYNOPSIS
    Generates UI configuration for the ModAPI Diagnostic Tool.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    The diagnostic tool is a comprehensive development/debugging tool with:
    - Event logging (device/user spawn, day events)
    - JSON game state export (Shift+J)
    - API test suite (Shift+Q)
    - Network configuration inspection
    
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
    Label       = "About ModAPI Diagnostic Tool v3.0"
    Description = "Developer tool for inspecting game engine callbacks, exporting game state, and testing API endpoints"
}

$parameters += @{
    Type  = "info"
    Label = "Purpose"
    Text  = @"
This is a comprehensive diagnostic tool for mod developers. Features include:

• Engine lifecycle events (load, reload)
• Device spawns with network configuration
• User spawns with location and network details  
• Day start/end events
• JSON game state export (Shift+J)
• API endpoint test suite (Shift+Q)

All output goes to the game console. Use this tool to understand game object structures, export game state for external tools, and debug your mods.
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
# JSON Export Options (Shift+J)
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "JSON Export Options (Shift+J)"
    Description = "Configure what data is included in JSON exports for external tools (Terraform, REST API, etc.)"
}

$parameters += @{
    Name        = "json_export_enabled"
    Label       = "Enable JSON Export"
    Type        = "boolean"
    Default     = $true
    Description = "Enable the Shift+J JSON export feature"
}

$parameters += @{
    Name        = "json_export_path"
    Label       = "JSON Export Filename"
    Type        = "string"
    Default     = "game_state.json"
    Description = "Filename for JSON export (saved in mod directory)"
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
    Description = "Include device merchant data (vendors, prices)"
}

# ============================================================================
# API Test Suite Options (Shift+Q)
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "API Test Suite Options (Shift+Q)"
    Description = "Configure which API endpoints to test for documentation and debugging"
}

$parameters += @{
    Name        = "test_suite_enabled"
    Label       = "Enable API Test Suite"
    Type        = "boolean"
    Default     = $true
    Description = "Enable the Shift+Q API test suite feature"
}

$parameters += @{
    Name        = "test_mod_api"
    Label       = "Test Mod API (ModApiV1, Mod global)"
    Type        = "boolean"
    Default     = $true
    Description = "Test core mod API endpoints: sanity(), get_game_world(), get_devices(), get_users(), etc."
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
    Label       = "Test Network API"
    Type        = "boolean"
    Default     = $true
    Description = "Test NetworkControlModule: hardware_address, network_address, dhcp_enabled, etc."
}

$parameters += @{
    Name        = "test_filesystem_api"
    Label       = "Test FileSystem API"
    Type        = "boolean"
    Default     = $true
    Description = "Test ModFileSystem: get_files_at(), get_directories_at(), open(), etc."
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
    Description = "Keep references to spawned users for Shift+R re-inspection feature"
}

$parameters += @{
    Name        = "show_notification"
    Label       = "Show In-Game Notifications"
    Type        = "boolean"
    Default     = $true
    Description = @"
Display in-game notifications when using keyboard shortcuts.

When enabled:
• Shows notification for user re-inspection (Shift+R)
• Shows notification for device dump (Shift+D)
• Shows notification for JSON export (Shift+J)
• Shows notification for API test results (Shift+Q)

Console messages will always be shown regardless of this setting.
"@
}

# ============================================================================
# Keyboard Shortcuts
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Keyboard Shortcuts"
    Description = "Available hotkeys while in-game"
}

$parameters += @{
    Type  = "info"
    Label = "Hotkeys"
    Text  = @"
Shift+R - Re-inspect all spawned users (network configuration)
Shift+D - Dump all devices in the world (finds phones/CCTV)
Shift+J - Export game state to JSON file
Shift+Q - Run API test suite (Query endpoints)

You can also call these functions directly from the Lua console:
• reinspect_all_users()
• dump_all_world_devices()
• inspect_scenes()
• export_to_json_file()
• run_api_test_suite()
• export_test_results_json()
"@
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
2. Open the game console to view diagnostic output
3. Watch for [DIAGNOSTIC] prefixed messages
4. Spawn devices and users to see detailed inspection logs
5. Press Shift+R to re-check user network configurations

JSON Export (for external tools like Terraform):
• Press Shift+J to export current game state
• JSON file is saved to the mod directory
• Configure which data to include in options above
• Use for REST API integration or state analysis

API Test Suite (for mod developers):
• Press Shift+Q to run comprehensive API tests
• Tests all documented ModApiV1 endpoints
• Reports which APIs are available vs. nil
• Use to improve documentation and find missing features

Common Use Cases:
• Understanding device properties and network config
• Debugging DNS server assignments
• Learning game object structure
• Testing mod API callbacks
• Exporting game state for external automation
• Validating API endpoint availability
"@
}

# Return the configuration
return $parameters
