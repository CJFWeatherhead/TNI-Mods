# ui-config.ps1 - Chaos Engine Mod
# UI Configuration Script with conditional parameter visibility

<#
.SYNOPSIS
    Generates UI configuration for the Chaos Engine mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    It demonstrates conditional parameter visibility based on feature toggles.
    
.PARAMETER CurrentConfig
    The current configuration values for this mod.
    Used to determine which parameters to show based on previous selections.
#>

param(
    [hashtable]$CurrentConfig = @{}
)

# Initialize parameters array
$parameters = @()

# Get current configuration values
$enableRandomFloors = if ($CurrentConfig.ContainsKey('enable_random_floors')) { $CurrentConfig['enable_random_floors'] } else { $true }
$enableDisasterMode = if ($CurrentConfig.ContainsKey('enable_disaster_mode')) { $CurrentConfig['enable_disaster_mode'] } else { $true }
$enableUserRandomization = if ($CurrentConfig.ContainsKey('enable_user_randomization')) { $CurrentConfig['enable_user_randomization'] } else { $true }

# ============================================================================
# Keyboard Shortcuts Overview
# ============================================================================

$parameters += @{
    Type    = "info"
    Message = @"
**Keyboard Shortcuts (SHIFT combinations):**
- **SHIFT+F** - Spawn a random floor
- **SHIFT+D** - Toggle Disaster Mode
- **SHIFT+X** - Reset all chaos settings to defaults
"@
}

# ============================================================================
# Feature Toggles
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Feature Toggles"
    Description = "Enable or disable chaos features"
    Collapsed   = $false
}

$parameters += @{
    Name        = "enable_random_floors"
    Label       = "Enable Random Floor Spawning"
    Type        = "boolean"
    Default     = $true
    Description = @"
Allow SHIFT+F to spawn random floors.

When pressed, a random floor builder will be triggered to 
create a new floor immediately.
"@
}

$parameters += @{
    Name        = "enable_disaster_mode"
    Label       = "Enable Disaster Mode"
    Type        = "boolean"
    Default     = $true
    Description = @"
Allow SHIFT+D to toggle Disaster Mode.

When active, all random event rates (device failures, power 
outages, power surges, worm spawns) are multiplied.
"@
}

$parameters += @{
    Name        = "enable_user_randomization"
    Label       = "Enable User Stat Randomization"
    Type        = "boolean"
    Default     = $true
    Description = @"
Randomize user stats when they spawn.

Affects: Satiety SLA, Eagerness, Use Period, Grace Days, 
and Satiety Decay. Does NOT affect daily rate.
"@
}

# ============================================================================
# Disaster Mode Settings
# ============================================================================

if ($enableDisasterMode) {
    $parameters += @{
        Type        = "section"
        Label       = "Disaster Mode Settings"
        Description = "Configure how intense disaster mode is"
        Collapsed   = $false
    }

    $parameters += @{
        Name        = "disaster_event_multiplier"
        Label       = "Event Rate Multiplier"
        Type        = "number"
        Default     = 5.0
        Min         = 1.5
        Max         = 20.0
        Step        = 0.5
        Description = @"
How much to multiply event rates when Disaster Mode is active.

Examples:
- 2.0 = Double the normal rate of disasters
- 5.0 = 5x more frequent (default)
- 10.0 = Absolute chaos
- 20.0 = Near-constant disasters

Event rates are capped at 1.0 (100% chance).
"@
    }

    $parameters += @{
        Type    = "warning"
        Message = "High multiplier values will cause very frequent disasters!"
    }
}

# ============================================================================
# User Randomization Settings
# ============================================================================

if ($enableUserRandomization) {
    $parameters += @{
        Type        = "section"
        Label       = "User Randomization - Satiety SLA"
        Description = "How satisfied users need to be (lower = easier to please)"
        Collapsed   = $true
    }

    $parameters += @{
        Name        = "user_satiety_sla_min"
        Label       = "Minimum Satiety SLA Ratio"
        Type        = "number"
        Default     = 0.3
        Min         = 0.1
        Max         = 0.9
        Step        = 0.1
        Description = "Minimum satisfaction threshold (lower = easier to satisfy)"
    }

    $parameters += @{
        Name        = "user_satiety_sla_max"
        Label       = "Maximum Satiety SLA Ratio"
        Type        = "number"
        Default     = 0.9
        Min         = 0.2
        Max         = 1.0
        Step        = 0.1
        Description = "Maximum satisfaction threshold (higher = harder to satisfy)"
    }

    # Eagerness
    $parameters += @{
        Type        = "section"
        Label       = "User Randomization - Eagerness"
        Description = "How demanding users are (higher = more demanding)"
        Collapsed   = $true
    }

    $parameters += @{
        Name        = "user_eagerness_min"
        Label       = "Minimum Eagerness"
        Type        = "integer"
        Default     = 1
        Min         = 1
        Max         = 5
        Description = "Minimum eagerness factor (lower = more patient)"
    }

    $parameters += @{
        Name        = "user_eagerness_max"
        Label       = "Maximum Eagerness"
        Type        = "integer"
        Default     = 10
        Min         = 5
        Max         = 20
        Description = "Maximum eagerness factor (higher = more demanding)"
    }

    # Use Period
    $parameters += @{
        Type        = "section"
        Label       = "User Randomization - Use Period"
        Description = "How often users request services (multiplier on base period)"
        Collapsed   = $true
    }

    $parameters += @{
        Name        = "user_use_period_min"
        Label       = "Min Use Period Multiplier"
        Type        = "number"
        Default     = 0.5
        Min         = 0.1
        Max         = 1.0
        Step        = 0.1
        Description = "Minimum multiplier (0.5 = twice as frequent)"
    }

    $parameters += @{
        Name        = "user_use_period_max"
        Label       = "Max Use Period Multiplier"
        Type        = "number"
        Default     = 2.0
        Min         = 1.0
        Max         = 5.0
        Step        = 0.5
        Description = "Maximum multiplier (2.0 = half as frequent)"
    }

    # Grace Days
    $parameters += @{
        Type        = "section"
        Label       = "User Randomization - Grace Period"
        Description = "Initial forgiveness period for new users"
        Collapsed   = $true
    }

    $parameters += @{
        Name        = "user_grace_days_min"
        Label       = "Minimum Grace Days"
        Type        = "integer"
        Default     = 1
        Min         = 0
        Max         = 3
        Description = "Minimum initial grace period in days"
    }

    $parameters += @{
        Name        = "user_grace_days_max"
        Label       = "Maximum Grace Days"
        Type        = "integer"
        Default     = 7
        Min         = 3
        Max         = 14
        Description = "Maximum initial grace period in days"
    }

    # Satiety Decay
    $parameters += @{
        Type        = "section"
        Label       = "User Randomization - Satiety Decay"
        Description = "How fast user satisfaction drops"
        Collapsed   = $true
    }

    $parameters += @{
        Name        = "user_max_satiety_decay_min"
        Label       = "Min Satiety Decay Rate"
        Type        = "number"
        Default     = 0.1
        Min         = 0.05
        Max         = 0.3
        Step        = 0.05
        Description = "Minimum decay rate (lower = slower drop)"
    }

    $parameters += @{
        Name        = "user_max_satiety_decay_max"
        Label       = "Max Satiety Decay Rate"
        Type        = "number"
        Default     = 0.5
        Min         = 0.2
        Max         = 1.0
        Step        = 0.1
        Description = "Maximum decay rate (higher = faster drop)"
    }
}

# ============================================================================
# UI Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Display Settings"
    Description = "Configure notifications and logging"
    Collapsed   = $true
}

$parameters += @{
    Name        = "show_notifications"
    Label       = "Show In-Game Notifications"
    Type        = "boolean"
    Default     = $true
    Description = @"
Display toast notifications when chaos events trigger.

Useful for confirming that hotkeys are working.
"@
}

$parameters += @{
    Name        = "debug_logging"
    Label       = "Enable Debug Logging"
    Type        = "boolean"
    Default     = $true
    Description = @"
Show detailed log messages in the console.

Useful for troubleshooting or seeing what the mod is doing.
Disable for cleaner console output.
"@
}

# Return parameters
return $parameters
