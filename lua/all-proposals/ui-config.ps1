# ui-config.ps1 - All Proposals Mod
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the All Proposals mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    It provides a simple interface to configure notification display
    when showing all available proposals or restoring normal mode.

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
# About Section
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "About All Proposals Mod"
    Description = "View all available proposals at once"
}

$parameters += @{
    Type  = "info"
    Label = "Purpose"
    Text  = @"
This mod allows you to view all available proposals in the game by pressing Shift+P.
Only proposals with unmet dependencies are excluded.

It temporarily increases the proposal batch size to display all eligible proposals.

Keyboard Shortcuts:
- Shift+P - Show all available proposals
- Shift+O - Restore normal proposal batch size

The mod safely checks for dependencies and adhoc requirements before including proposals.
"@
}

# ============================================================================
# Display Options
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Display Options"
    Description = "Configure visual feedback"
}

$parameters += @{
    Name        = "show_notification"
    Label       = "Show In-Game Notifications"
    Type        = "boolean"
    Default     = $true
    Description = @"
Display in-game notifications when activating or deactivating the mod.

When enabled:
- Shows a notification when all proposals are displayed (Shift+P)
- Shows a notification when normal mode is restored (Shift+O)

Note: This feature depends on the game's notification system.
If not supported, only console messages will appear.

Console messages will always be shown regardless of this setting.
"@
}

# ============================================================================
# Return the parameter definitions
# ============================================================================

return $parameters
