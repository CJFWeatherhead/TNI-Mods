# ui-config.ps1 - ModAPI Diagnostic Tool
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the ModAPI Diagnostic Tool.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    The diagnostic tool is primarily a development/debugging tool with minimal configuration needs.
    
.PARAMETER CurrentConfig
    The current configuration values for this mod.
#>

param(
    [hashtable]$CurrentConfig = @{}
)

# Initialize parameters array
$parameters = @()

# Get current configuration values
$enableDeviceLogging = if ($CurrentConfig.ContainsKey('enable_device_logging')) { $CurrentConfig['enable_device_logging'] } else { $true }
$enableUserLogging = if ($CurrentConfig.ContainsKey('enable_user_logging')) { $CurrentConfig['enable_user_logging'] } else { $true }
$enableDayEvents = if ($CurrentConfig.ContainsKey('enable_day_events')) { $CurrentConfig['enable_day_events'] } else { $true }
$maxDumpDepth = if ($CurrentConfig.ContainsKey('max_dump_depth')) { $CurrentConfig['max_dump_depth'] } else { 2 }

# ============================================================================
# Diagnostic Tool Information
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "About ModAPI Diagnostic Tool"
    Description = "Developer tool for inspecting game engine callbacks and API endpoints"
}

$parameters += @{
    Type  = "info"
    Label = "Purpose"
    Text  = @"
This is a comprehensive diagnostic tool for mod developers. It logs detailed information about:

• Engine lifecycle events (load, reload)
• Device spawns with network configuration
• User spawns with location and network details
• Day start/end events
• Keyboard input events

All output goes to the game console. Use this tool to understand game object structures and debug your mods.
"@
}

# ============================================================================
# Logging Options
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Logging Options"
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
    Name        = "enable_network_inspection"
    Label       = "Enable Network Configuration Inspection"
    Type        = "boolean"
    Default     = $true
    Description = "Inspect network settings, DHCP, DNS servers for devices and users"
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
• Shows a notification when re-inspecting users (Shift+R)
• Shows a notification when dumping devices (Shift+D)

Note: This feature depends on the game's notification system.
If not supported, only console messages will appear.

Console messages will always be shown regardless of this setting.
"@
}

# ============================================================================
# Hotkeys Information
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

You can also call these functions directly from the Lua console:
• reinspect_all_users()
• dump_all_world_devices()
• inspect_scenes()
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

Common Use Cases:
• Understanding device properties and network config
• Debugging DNS server assignments
• Learning game object structure
• Testing mod API callbacks
• Inspecting user locations and profiles
"@
}

# Return the configuration
return @{
    Parameters = $parameters
    Version    = "2.0"
}
