# ui-config.ps1 - TARDIS Mod
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the TARDIS time controller mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    It provides an interface to configure speed presets, time skip,
    automation, and notification settings.

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
    Description = "Configure the default speed preset"
    Collapsed   = $false
}

$parameters += @{
    Name        = "default_speed"
    Label       = "Default Speed"
    Type        = "number"
    Default     = 1.0
    Min         = 0.125
    Max         = 8.0
    Step        = 0.125
    Description = @"
Speed multiplier to reset to when using the m_normal command.

Default: 1.0x

The value is snapped to the nearest preset:
  0.125x  0.25x  0.5x  1x  2x  4x  8x

These match the game's hard limits (0.125x – 8x).

Usage: Press ~ to open the debug console, then type:
  m_faster  m_slower  m_normal  m_skip  m_pause  m_time
"@
    Section     = "Speed Control"
}

# ============================================================================
# Time Skip Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Time Skip"
    Description = "Configure the m_skip console command"
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
Time of day to skip to when the m_skip console command is used.

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
# Automation Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Automation"
    Description = "Automatic speed management options"
    Collapsed   = $false
}

$parameters += @{
    Name        = "auto_reset_on_day_start"
    Label       = "Auto-Reset Speed On Day Start"
    Type        = "boolean"
    Default     = $false
    Description = @"
Automatically reset the game speed to the default at the
start of each new in-game day.

When enabled:
- Speed returns to the configured default (1x) at dawn
- Useful if you speed up to skip a day but want normal
  speed when the next day begins

Uses the on_day_start lifecycle hook — zero per-frame cost.
"@
    Section     = "Automation"
}

# ============================================================================
# Debug Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Debug"
    Description = "Troubleshooting and logging options"
    Collapsed   = $true
}

$parameters += @{
    Name        = "debug_logging"
    Label       = "Enable Debug Logging"
    Type        = "boolean"
    Default     = $false
    Description = @"
Show detailed debug messages in the console.

When enabled:
- Logs preset sync operations
- Reports internal clock values
- Shows detailed error information

Recommended: Keep disabled unless troubleshooting issues.
"@
    Section     = "Debug"
}

# ============================================================================
# Return the parameter definitions
# ============================================================================

return $parameters
