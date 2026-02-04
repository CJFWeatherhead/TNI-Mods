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

# Individual user randomization toggles
$enableSatietySlaRand = if ($CurrentConfig.ContainsKey('enable_satiety_sla_randomization')) { $CurrentConfig['enable_satiety_sla_randomization'] } else { $true }
$enableEagernessRand = if ($CurrentConfig.ContainsKey('enable_eagerness_randomization')) { $CurrentConfig['enable_eagerness_randomization'] } else { $true }
$enableUsePeriodRand = if ($CurrentConfig.ContainsKey('enable_use_period_randomization')) { $CurrentConfig['enable_use_period_randomization'] } else { $true }
$enableGraceDaysRand = if ($CurrentConfig.ContainsKey('enable_grace_days_randomization')) { $CurrentConfig['enable_grace_days_randomization'] } else { $true }
$enableSatietyDecayRand = if ($CurrentConfig.ContainsKey('enable_satiety_decay_randomization')) { $CurrentConfig['enable_satiety_decay_randomization'] } else { $true }

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
    Name        = "enable_initial_floor_randomization"
    Label       = "Randomize Initial Floors"
    Type        = "boolean"
    Default     = $false
    Description = @"
Randomize the 3 initial floors when starting a new game session.

Instead of the pre-defined starting floors, 3 random floors 
will be generated using the same logic as SHIFT+F.

Note: This happens during game initialization and may result 
in unexpected starting conditions!
"@
}

$parameters += @{
    Name            = "enable_disaster_mode"
    Label           = "Enable Disaster Mode"
    Type            = "boolean"
    Default         = $true
    RefreshOnChange = $true
    Description     = @"
Allow SHIFT+D to toggle Disaster Mode.

When active, all random event rates (device failures, power 
outages, power surges, worm spawns) are multiplied.
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

$parameters += @{
    Type        = "section"
    Label       = "User Randomization Toggles"
    Description = "Enable or disable individual stat randomizations"
    Collapsed   = $false
}

$parameters += @{
    Name            = "enable_satiety_sla_randomization"
    Label           = "Randomize Satisfaction SLA"
    Type            = "boolean"
    Default         = $true
    RefreshOnChange = $true
    Description     = @"
Randomize the minimum satisfaction % threshold each user requires.

This is the percentage shown in-game as the user's satisfaction bar.
Lower threshold = user is easier to keep happy.
"@
}

$parameters += @{
    Name            = "enable_eagerness_randomization"
    Label           = "Randomize Eagerness"
    Type            = "boolean"
    Default         = $true
    RefreshOnChange = $true
    Description     = @"
Randomize how impatient/demanding each user is.

Higher eagerness = user complains faster when unsatisfied.
"@
}

$parameters += @{
    Name            = "enable_use_period_randomization"
    Label           = "Randomize Service Request Frequency"
    Type            = "boolean"
    Default         = $true
    RefreshOnChange = $true
    Description     = @"
Randomize how often users request service.

Applies a multiplier to the base time between requests.
"@
}

$parameters += @{
    Name            = "enable_grace_days_randomization"
    Label           = "Randomize Grace Period"
    Type            = "boolean"
    Default         = $true
    RefreshOnChange = $true
    Description     = @"
Randomize the initial forgiveness period for new users.

During grace days, users won't penalize you for poor service.
"@
}

$parameters += @{
    Name            = "enable_satiety_decay_randomization"
    Label           = "Randomize Satisfaction Decay Rate"
    Type            = "boolean"
    Default         = $true
    RefreshOnChange = $true
    Description     = @"
Randomize how fast user satisfaction drops when not being served.

Measured as % of satisfaction lost per game tick.
"@
}

# Satiety SLA Settings
if ($enableSatietySlaRand) {
    $parameters += @{
        Type        = "section"
        Label       = "Satisfaction SLA Range"
        Description = "Minimum satisfaction % threshold the user requires (shown as satisfaction bar in-game)"
        Collapsed   = $true
    }

    $parameters += @{
        Name        = "user_satiety_sla_min"
        Label       = "Minimum SLA Threshold"
        Type        = "number"
        Default     = 0.3
        Min         = 0.1
        Max         = 0.9
        Step        = 0.1
        Description = @"
Lowest possible satisfaction threshold (as decimal: 0.3 = 30%)

A user with 30% SLA only needs their satisfaction bar at 30% 
to be considered 'satisfied'.
"@
    }

    $parameters += @{
        Name        = "user_satiety_sla_max"
        Label       = "Maximum SLA Threshold"
        Type        = "number"
        Default     = 0.9
        Min         = 0.2
        Max         = 1.0
        Step        = 0.1
        Description = @"
Highest possible satisfaction threshold (as decimal: 0.9 = 90%)

A user with 90% SLA needs their satisfaction bar at 90%+ 
to be considered 'satisfied'. Much harder to please!
"@
    }
}

# Eagerness Settings
if ($enableEagernessRand) {
    $parameters += @{
        Type        = "section"
        Label       = "Eagerness Range"
        Description = "How demanding/impatient users are (higher = more demanding)"
        Collapsed   = $true
    }

    $parameters += @{
        Name        = "user_eagerness_min"
        Label       = "Minimum Eagerness"
        Type        = "integer"
        Default     = 1
        Min         = 1
        Max         = 5
        Description = "Most patient possible user (1 = very patient)"
    }

    $parameters += @{
        Name        = "user_eagerness_max"
        Label       = "Maximum Eagerness"
        Type        = "integer"
        Default     = 10
        Min         = 5
        Max         = 20
        Description = "Most demanding possible user (10+ = very impatient)"
    }
}

# Use Period Settings
if ($enableUsePeriodRand) {
    $parameters += @{
        Type        = "section"
        Label       = "Service Request Frequency Range"
        Description = "Multiplier on time between service requests"
        Collapsed   = $true
    }

    $parameters += @{
        Type    = "info"
        Message = @"
**How the multiplier works:**
- **< 1.0** = Shorter wait between requests = MORE frequent usage
- **= 1.0** = Normal frequency (no change)
- **> 1.0** = Longer wait between requests = LESS frequent usage

Example: 0.5x multiplier = half the wait time = user requests service twice as often
"@
    }

    $parameters += @{
        Name        = "user_use_period_min"
        Label       = "Minimum Period Multiplier"
        Type        = "number"
        Default     = 0.5
        Min         = 0.1
        Max         = 1.0
        Step        = 0.1
        Description = @"
Lowest multiplier (0.5 = half the normal wait time)

Results in MORE frequent service requests.
0.5x = requests come 2x as often as normal.
"@
    }

    $parameters += @{
        Name        = "user_use_period_max"
        Label       = "Maximum Period Multiplier"
        Type        = "number"
        Default     = 2.0
        Min         = 1.0
        Max         = 5.0
        Step        = 0.5
        Description = @"
Highest multiplier (2.0 = double the normal wait time)

Results in LESS frequent service requests.
2.0x = requests come half as often as normal.
"@
    }
}

# Grace Days Settings
if ($enableGraceDaysRand) {
    $parameters += @{
        Type        = "section"
        Label       = "Grace Period Range"
        Description = "Initial forgiveness period before SLA penalties apply (in game days)"
        Collapsed   = $true
    }

    $parameters += @{
        Name        = "user_grace_days_min"
        Label       = "Minimum Grace Days"
        Type        = "integer"
        Default     = 1
        Min         = 0
        Max         = 3
        Description = "Shortest possible forgiveness period (in game days)"
    }

    $parameters += @{
        Name        = "user_grace_days_max"
        Label       = "Maximum Grace Days"
        Type        = "integer"
        Default     = 7
        Min         = 3
        Max         = 14
        Description = "Longest possible forgiveness period (in game days)"
    }
}

# Satiety Decay Settings
if ($enableSatietyDecayRand) {
    $parameters += @{
        Type        = "section"
        Label       = "Satisfaction Decay Rate Range"
        Description = "How fast satisfaction drops when user is not being served"
        Collapsed   = $true
    }

    $parameters += @{
        Type    = "info"
        Message = @"
**Decay Rate:** Percentage of satisfaction lost per game tick when the user's 
service needs are not being met. Higher values = satisfaction drops faster.
"@
    }

    $parameters += @{
        Name        = "user_max_satiety_decay_min"
        Label       = "Minimum Decay Rate"
        Type        = "number"
        Default     = 0.1
        Min         = 0.05
        Max         = 0.3
        Step        = 0.05
        Description = @"
Slowest decay rate (as decimal: 0.1 = 10% per tick)

Users with low decay are more forgiving when service is slow.
"@
    }

    $parameters += @{
        Name        = "user_max_satiety_decay_max"
        Label       = "Maximum Decay Rate"
        Type        = "number"
        Default     = 0.5
        Min         = 0.2
        Max         = 1.0
        Step        = 0.1
        Description = @"
Fastest decay rate (as decimal: 0.5 = 50% per tick)

Users with high decay become unhappy very quickly!
"@
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
