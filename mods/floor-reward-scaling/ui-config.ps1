# ui-config.ps1 - Floor Reward Scaling Mod
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the Floor Reward Scaling mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    It demonstrates conditional parameter visibility based on the selected scaling type.
    
    When scaling_type is "Randomised", it shows min_factor and max_factor.
    When scaling_type is anything else, it shows the factor parameter.

.PARAMETER CurrentConfig
    The current configuration values for this mod.
    Used to determine which parameters to show based on previous selections.
#>

param(
    [hashtable]$CurrentConfig = @{}
)

# Initialize parameters array
$parameters = @()

# Get current scaling type (default to Logarithmic if not set)
$scalingType = if ($CurrentConfig.ContainsKey('scaling_type')) {
    $CurrentConfig['scaling_type']
}
else {
    "Logarithmic"
}

# ============================================================================
# Scaling Type Selection (Always Visible)
# ============================================================================

$parameters += @{
    Name            = "scaling_type"
    Label           = "Scaling Type"
    Type            = "select"
    Default         = "Logarithmic"
    Options         = @("Logarithmic", "Linear", "Exponential", "Randomised")
    RefreshOnChange = $true  # Triggers UI refresh when changed to show/hide conditional parameters
    Description     = @"
Choose the reward scaling method:

• Logarithmic: Diminishing returns, balanced growth
  Formula: 1 + log₂(floor+2) × factor
  Example: Factor 2.0 gives ~4x at floor 5

• Linear: Constant rate increase per floor
  Formula: 1 + floor × factor
  Example: Factor 2.0 gives 11x at floor 5

• Exponential: Rapid compound growth
  Formula: factor ^ floor
  Example: Factor 2.0 gives 32x at floor 5

• Randomised: Random multiplier per user between min and max
  Each user gets a different random reward multiplier
"@
    Section     = "Core Settings"
}

# ============================================================================
# Standard Scaling Factor (Visible for non-Randomised modes)
# ============================================================================

if ($scalingType -ne "Randomised") {
    $parameters += @{
        Name        = "factor"
        Label       = "Scaling Factor"
        Type        = "number"
        Default     = 2.0
        Min         = 1.0
        Max         = 5.0
        Step        = 0.1
        Description = @"
Multiplier factor for scaling calculations.
Higher values = stronger scaling effect.

Impact by mode:
• Logarithmic (factor 2.0): ~4x at floor 5
• Linear (factor 2.0): 11x at floor 5  
• Exponential (factor 2.0): 32x at floor 5

Adjust based on desired game balance.
"@
        Section     = "Scaling Configuration"
    }
}

# ============================================================================
# Randomised Mode Settings (Only visible when mode is Randomised)
# ============================================================================

if ($scalingType -eq "Randomised") {
    # Add section header
    $parameters += @{
        Type        = "section"
        Label       = "Randomised Mode Settings"
        Description = "Configure the random multiplier range for user rewards"
    }
    
    $parameters += @{
        Name        = "min_factor"
        Label       = "Minimum Random Factor"
        Type        = "number"
        Default     = 1.0
        Min         = 1.0
        Max         = 100.0
        Step        = 0.1
        Description = @"
Minimum multiplier for Randomised mode.
Each user will receive a random multiplier between min and max.

Setting this to 1.0 means some users might get standard rewards,
while others get enhanced rewards up to the maximum factor.
"@
    }
    
    $parameters += @{
        Name        = "max_factor"
        Label       = "Maximum Random Factor"
        Type        = "number"
        Default     = 5.0
        Min         = 1.0
        Max         = 100.0
        Step        = 0.1
        Description = @"
Maximum multiplier for Randomised mode.
Each user will receive a random multiplier between min and max.

Higher values create more variance in player rewards.
Example: min=1.0, max=5.0 means rewards vary from 1x to 5x base rate.
"@
    }
    
    # Optional: Add validation to ensure max > min
    # This would be checked when saving configuration
}

# ============================================================================
# Advanced Options (Always visible but collapsed by default)
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
    Default     = $false
    Description = "Log detailed scaling calculations to console for debugging"
}

$parameters += @{
    Name        = "apply_to_new_users_only"
    Label       = "Apply to New Users Only"
    Type        = "boolean"
    Default     = $false
    Description = @"
If enabled, only newly spawned users will have scaled rewards.
Existing users will keep their current reward rates.

If disabled (default), scaling applies to all users including existing ones.
"@
}

# ============================================================================
# Return the parameter definitions
# ============================================================================

return $parameters
