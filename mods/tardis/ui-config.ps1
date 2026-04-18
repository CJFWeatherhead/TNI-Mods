# ui-config.ps1 - TARDIS Mod
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the TARDIS time controller mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    It provides an interface to configure game speed controls and
    time skip functionality.

.PARAMETER CurrentConfig
    The current configuration values for this mod.
    Used to determine which parameters to show based on previous selections.
#>

param(
    [hashtable]$CurrentConfig = @{}
)

# Initialize parameters array
$parameters = @()

# ============================================================================
# Speed Control Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Speed Control"
    Description = "Configure how game speed changes work"
    Collapsed   = $false
}

$parameters += @{
    Name        = "speed_step"
    Label       = "Speed Change Step"
    Type        = "number"
    Default     = 0.5
    Min         = 0.1
    Max         = 2.0
    Step        = 0.1
    Description = @"
Amount to change the speed multiplier per speed_up / speed_down command.

Default: 0.5x per command

Examples:
- 0.1 = Fine control (10 steps to go from 1x to 2x)
- 0.5 = Moderate steps (2 steps to go from 1x to 2x)
- 1.0 = Large jumps (double/halve with each command)

The game enforces hard limits of 0.125x to 8x regardless of this setting.

Usage: Press ~ to open the debug console, then type: speed_up  speed_down  speed_reset  day_skip  speed
"@
    Section     = "Speed Control"
}

$parameters += @{
    Name        = "min_speed"
    Label       = "Minimum Speed"
    Type        = "number"
    Default     = 0.125
    Min         = 0.125
    Max         = 1.0
    Step        = 0.125
    Description = @"
Minimum allowed game speed multiplier.

Default: 0.125x (game's minimum limit)

Note: The game enforces a hard minimum of 0.125x.
Setting this higher than 0.125 can be useful if you don't
want to accidentally slow the game down too much.
"@
    Section     = "Speed Control"
}

$parameters += @{
    Name        = "max_speed"
    Label       = "Maximum Speed"
    Type        = "number"
    Default     = 8.0
    Min         = 2.0
    Max         = 8.0
    Step        = 0.5
    Description = @"
Maximum allowed game speed multiplier.

Default: 8x (game's maximum limit)

Note: The game enforces a hard maximum of 8x.
Setting this lower can be useful if you want to limit
how fast you can speed up the game.
"@
    Section     = "Speed Control"
}

$parameters += @{
    Name        = "default_speed"
    Label       = "Default Speed (Reference)"
    Type        = "number"
    Default     = 1.0
    Min         = 0.125
    Max         = 8.0
    Step        = 0.25
    Description = @"
Reference value for normal game speed.

Default: 1.0x

This is for reference only - the mod doesn't automatically
reset to this value. Type speed_reset in the debug console to
return to 1x speed.
"@
    Section     = "Speed Control"
}

# ============================================================================
# Time Skip Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Time Skip"
    Description = "Configure the day_skip console command"
    Collapsed   = $false
}

$parameters += @{
    Name        = "skip_to_time"
    Label       = "Skip To Time (24h format)"
    Type        = "number"
    Default     = 23.99
    Min         = 0.0
    Max         = 23.99
    Step        = 0.5
    Description = @"
Time of day to skip to when the day_skip console command is run.

Default: 23.99 (23:59, end of day)

Uses 24-hour decimal format:
- 0.0 = 00:00 (midnight)
- 6.0 = 06:00 (morning)
- 12.0 = 12:00 (noon)
- 18.0 = 18:00 (evening)
- 23.99 = 23:59 (just before midnight)

Setting to 23.99 effectively skips to end of day.
"@
    Section     = "Time Skip"
}

# ============================================================================
# Notification Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Notifications"
    Description = "Configure feedback and logging options"
    Collapsed   = $true
}

$parameters += @{
    Name        = "show_notifications"
    Label       = "Show In-Game Notifications"
    Type        = "boolean"
    Default     = $true
    Description = @"
Display on-screen notifications when speed changes or time skips.

When enabled:
- Shows current speed multiplier when changed
- Shows confirmation when time is skipped

Console messages are always shown regardless of this setting.
"@
    Section     = "Notifications"
}

$parameters += @{
    Name        = "debug_logging"
    Label       = "Enable Debug Logging"
    Type        = "boolean"
    Default     = $false
    Description = @"
Show detailed debug messages in the console.

When enabled:
- Shows cooldown status
- Displays internal clock values
- Reports detailed error information

Recommended: Keep disabled unless troubleshooting issues.
"@
    Section     = "Notifications"
}

# ============================================================================
# Return the parameter definitions
# ============================================================================

return $parameters
