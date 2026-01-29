# ui-config.ps1 - Random Drops Mod
# UI Configuration Script with conditional parameter visibility

<#
.SYNOPSIS
    Generates UI configuration for the Random Drops mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    It demonstrates conditional parameter visibility based on feature toggles.
    Each of the three main features can be expanded when enabled.
    
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
$enableRandomSpawns = if ($CurrentConfig.ContainsKey('enable_random_spawns')) { $CurrentConfig['enable_random_spawns'] } else { $true }
$enableExtraUsers = if ($CurrentConfig.ContainsKey('enable_extra_users')) { $CurrentConfig['enable_extra_users'] } else { $true }
$enablePurchaseMultiplier = if ($CurrentConfig.ContainsKey('enable_purchase_multiplier')) { $CurrentConfig['enable_purchase_multiplier'] } else { $true }
$spawnAllItems = if ($CurrentConfig.ContainsKey('spawn_all_items')) { $CurrentConfig['spawn_all_items'] } else { $true }

# ============================================================================
# Feature 1: Random Item Spawning
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Feature 1: Random Item Spawning"
    Description = "Periodically spawn random devices at configurable intervals"
}

$parameters += @{
    Name        = "enable_random_spawns"
    Label       = "Enable Random Item Spawning"
    Type        = "boolean"
    Default     = $true
    Description = @"
When enabled, random devices will spawn at regular intervals.

This adds variety to your gameplay by providing unexpected resources.
"@
}

# Show spawn configuration only when feature is enabled
if ($enableRandomSpawns) {
    $parameters += @{
        Name        = "spawn_interval_seconds"
        Label       = "Spawn Interval (Seconds)"
        Type        = "integer"
        Default     = 60
        Min         = 10
        Max         = 600
        Step        = 10
        Description = @"
Time in seconds between random spawn events.

Examples:
- 30 seconds = Very frequent spawns
- 60 seconds = Regular spawns (default)
- 300 seconds = Rare spawns (every 5 minutes)
"@
    }

    $parameters += @{
        Name        = "spawn_count_min"
        Label       = "Minimum Items Per Spawn"
        Type        = "integer"
        Default     = 1
        Min         = 1
        Max         = 10
        Description = "Minimum number of items to spawn each interval"
    }

    $parameters += @{
        Name        = "spawn_count_max"
        Label       = "Maximum Items Per Spawn"
        Type        = "integer"
        Default     = 3
        Min         = 1
        Max         = 20
        Description = "Maximum number of items to spawn each interval. A random value between min and max will be chosen."
    }

    $parameters += @{
        Type        = "section"
        Label       = "Item Type Filters"
        Description = "Control which device types can spawn"
    }

    $parameters += @{
        Name        = "spawn_all_items"
        Label       = "Spawn All Item Types"
        Type        = "boolean"
        Default     = $true
        Description = @"
When enabled, all available device types can spawn.
When disabled, only the device types selected below will spawn.
"@
    }

    # Show individual device type filters only when not spawning all
    if (-not $spawnAllItems) {
        $parameters += @{
            Type    = "info"
            Message = "Select which device types can spawn:"
        }

        $parameters += @{
            Name        = "spawn_switches"
            Label       = "Network Switches"
            Type        = "boolean"
            Default     = $true
            Description = "Allow network switches to spawn"
        }

        $parameters += @{
            Name        = "spawn_routers"
            Label       = "Routers"
            Type        = "boolean"
            Default     = $true
            Description = "Allow routers to spawn"
        }

        $parameters += @{
            Name        = "spawn_firewalls"
            Label       = "Firewalls"
            Type        = "boolean"
            Default     = $true
            Description = "Allow firewalls to spawn"
        }

        $parameters += @{
            Name        = "spawn_servers"
            Label       = "Servers"
            Type        = "boolean"
            Default     = $true
            Description = "Allow compute servers to spawn"
        }

        $parameters += @{
            Name        = "spawn_workstations"
            Label       = "Workstations/Monitors"
            Type        = "boolean"
            Default     = $false
            Description = "Allow workstations and monitors to spawn"
        }

        $parameters += @{
            Name        = "spawn_misc"
            Label       = "Miscellaneous Devices"
            Type        = "boolean"
            Default     = $false
            Description = "Allow other device types (UPS, surge protectors, etc.)"
        }
    }
}

# ============================================================================
# Feature 2: Extra Users on Floor Creation
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Feature 2: Extra Users on Floor Creation"
    Description = "Automatically add extra users when new floors are created"
}

$parameters += @{
    Name        = "enable_extra_users"
    Label       = "Enable Extra Users"
    Type        = "boolean"
    Default     = $true
    Description = @"
When enabled, additional random users will be added whenever a new floor is created.

This provides more customers and activity on each floor.
"@
}

# Show user configuration only when feature is enabled
if ($enableExtraUsers) {
    $parameters += @{
        Name        = "extra_users_min"
        Label       = "Minimum Extra Users"
        Type        = "integer"
        Default     = 1
        Min         = 1
        Max         = 10
        Description = "Minimum number of extra users to add when a floor is created"
    }

    $parameters += @{
        Name        = "extra_users_max"
        Label       = "Maximum Extra Users"
        Type        = "integer"
        Default     = 3
        Min         = 1
        Max         = 20
        Description = @"
Maximum number of extra users to add when a floor is created.

A random number between min and max will be chosen for each new floor.
"@
    }
}

# ============================================================================
# Feature 3: Purchase Multiplier
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Feature 3: Purchase Multiplier"
    Description = "Receive multiple items when purchasing from the shop"
}

$parameters += @{
    Name        = "enable_purchase_multiplier"
    Label       = "Enable Purchase Multiplier"
    Type        = "boolean"
    Default     = $true
    Description = @"
When enabled, purchasing an item from the shop will give you multiple copies.

Great for quickly building out your infrastructure!
"@
}

# Show multiplier configuration only when feature is enabled
if ($enablePurchaseMultiplier) {
    $parameters += @{
        Name        = "purchase_multiplier"
        Label       = "Purchase Multiplier"
        Type        = "integer"
        Default     = 2
        Min         = 1
        Max         = 10
        Description = @"
Number of items you receive per purchase.

Examples:
- 1 = Normal (no duplication)
- 2 = Double (buy 1 get 2)
- 5 = Quintuple (buy 1 get 5)

Note: You still only pay for one item!
"@
    }

    $parameters += @{
        Type    = "warning"
        Message = "High multiplier values may affect game balance significantly."
    }
}

# ============================================================================
# General Settings
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "General Settings"
    Description = "General mod configuration options"
}

$parameters += @{
    Name        = "debug_logging"
    Label       = "Enable Debug Logging"
    Type        = "boolean"
    Default     = $true
    Description = @"
Show detailed log messages in the console.

Useful for troubleshooting or seeing exactly what the mod is doing.
Disable for cleaner console output.
"@
}

# Return parameters
return $parameters
