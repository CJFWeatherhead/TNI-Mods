# ui-config.ps1 - Money Cheat Mod
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the Money Cheat mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    It provides a simple interface to configure the amount of money
    added when the SHIFT+M keyboard shortcut is pressed.

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
# Core Settings
# ============================================================================

$parameters += @{
    Name        = "money_amount"
    Label       = "Money Amount"
    Type        = "number"
    Default     = 10000
    Min         = 100
    Max         = 10000000
    Step        = 100
    Description = @"
Amount of money to add when SHIFT+M is pressed.

Default: $10,000

Recommended values:
• $1,000 - Small boost for tight situations
• $10,000 - Moderate funding (default)
• $100,000 - Major financial injection
• $1,000,000 - Essentially unlimited funds

Press SHIFT+M during gameplay to activate the cheat.
A confirmation message will appear in the console.
"@
    Section     = "Cheat Settings"
}

# ============================================================================
# Advanced Options
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Advanced Options"
    Description = "Additional configuration options"
    Collapsed   = $true  # UI hint: render this section collapsed
}

$parameters += @{
    Name        = "debug_logging"
    Label       = "Enable Debug Logging"
    Type        = "boolean"
    Default     = $true
    Description = @"
Log detailed information to console when cheat is activated.

When enabled:
• Shows confirmation when money is added
• Displays current configuration on load
• Reports errors if cheat fails

Recommended: Keep enabled for feedback when using the cheat.
"@
}

$parameters += @{
    Name        = "show_notification"
    Label       = "Show In-Game Notification"
    Type        = "boolean"
    Default     = $true
    Description = @"
Attempt to show an in-game notification when money is added.

Note: This feature depends on the game's notification system.
If not supported, only console messages will appear.

Console messages will always be shown regardless of this setting.
"@
}

# ============================================================================
# Return the parameter definitions
# ============================================================================

return $parameters
