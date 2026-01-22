# ui-config.ps1 - Device Tweaker Mod
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the Device Tweaker mod.

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
$enableBandwidth = if ($CurrentConfig.ContainsKey('enable_bandwidth')) { $CurrentConfig['enable_bandwidth'] } else { $false }
$enableWarranty = if ($CurrentConfig.ContainsKey('enable_warranty')) { $CurrentConfig['enable_warranty'] } else { $false }
$enableCost = if ($CurrentConfig.ContainsKey('enable_cost')) { $CurrentConfig['enable_cost'] } else { $false }
$enableCpu = if ($CurrentConfig.ContainsKey('enable_cpu')) { $CurrentConfig['enable_cpu'] } else { $false }
$enableMemory = if ($CurrentConfig.ContainsKey('enable_memory')) { $CurrentConfig['enable_memory'] } else { $false }
$enableStorage = if ($CurrentConfig.ContainsKey('enable_storage')) { $CurrentConfig['enable_storage'] } else { $false }
$warrantyMode = if ($CurrentConfig.ContainsKey('warranty_mode')) { $CurrentConfig['warranty_mode'] } else { "fixed" }

# ============================================================================
# Feature Toggles Section
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Feature Toggles"
    Description = "Enable or disable specific modification types"
}

$parameters += @{
    Name        = "enable_bandwidth"
    Label       = "Enable Bandwidth Modification"
    Type        = "boolean"
    Default     = $false
    Description = "Multiply device network bandwidth capacity"
}

$parameters += @{
    Name        = "enable_warranty"
    Label       = "Enable Warranty Modification"
    Type        = "boolean"
    Default     = $false
    Description = "Modify device warranty periods (fixed or random)"
}

$parameters += @{
    Name        = "enable_cost"
    Label       = "Enable Cost Modification"
    Type        = "boolean"
    Default     = $false
    Description = "Multiply device purchase costs"
}

$parameters += @{
    Name        = "enable_cpu"
    Label       = "Enable CPU Modification"
    Type        = "boolean"
    Default     = $false
    Description = "Multiply device CPU power"
}

$parameters += @{
    Name        = "enable_memory"
    Label       = "Enable Memory Modification"
    Type        = "boolean"
    Default     = $false
    Description = "Multiply device RAM capacity"
}

$parameters += @{
    Name        = "enable_storage"
    Label       = "Enable Storage Modification"
    Type        = "boolean"
    Default     = $false
    Description = "Multiply device storage capacity"
}

# ============================================================================
# Bandwidth Settings (Only visible when enabled)
# ============================================================================

if ($enableBandwidth) {
    $parameters += @{
        Type        = "section"
        Label       = "Bandwidth Settings"
        Description = "Configure network bandwidth multipliers"
    }
    
    $parameters += @{
        Name        = "bandwidth_multiplier"
        Label       = "Bandwidth Multiplier"
        Type        = "number"
        Default     = 2.0
        Min         = 0.1
        Max         = 100.0
        Step        = 0.1
        Description = @"
Multiplier for device network bandwidth capacity.

Examples:
• 2.0 = Double bandwidth (10 Gbps → 20 Gbps)
• 0.5 = Half bandwidth (10 Gbps → 5 Gbps)
• 10.0 = Ten times bandwidth

Applies to all devices with network interfaces.
"@
    }
}

# ============================================================================
# Warranty Settings (Only visible when enabled)
# ============================================================================

if ($enableWarranty) {
    $parameters += @{
        Type        = "section"
        Label       = "Warranty Settings"
        Description = "Configure device warranty modifications"
    }
    
    $parameters += @{
        Name        = "warranty_mode"
        Label       = "Warranty Mode"
        Type        = "select"
        Default     = "fixed"
        Options     = @("fixed", "random")
        Description = @"
Warranty modification mode:

• fixed: Apply a constant multiplier to all devices
• random: Apply a random multiplier (within range) to each device

Use random for more varied gameplay, fixed for predictable results.
"@
    }
    
    # Show fixed multiplier only in fixed mode
    if ($warrantyMode -eq "fixed") {
        $parameters += @{
            Name        = "warranty_multiplier_fixed"
            Label       = "Fixed Warranty Multiplier"
            Type        = "number"
            Default     = 1.0
            Min         = 0.1
            Max         = 100.0
            Step        = 0.1
            Description = @"
Fixed multiplier applied to all device warranties.

Example: A device with 30 day warranty × 2.0 = 60 days
"@
        }
    }
    
    # Show min/max range only in random mode
    if ($warrantyMode -eq "random") {
        $parameters += @{
            Name        = "warranty_multiplier_min"
            Label       = "Minimum Random Multiplier"
            Type        = "number"
            Default     = 2.0
            Min         = 0.1
            Max         = 100.0
            Step        = 0.1
            Description = "Lower bound for random warranty multiplier"
        }
        
        $parameters += @{
            Name        = "warranty_multiplier_max"
            Label       = "Maximum Random Multiplier"
            Type        = "number"
            Default     = 25.0
            Min         = 0.1
            Max         = 100.0
            Step        = 0.1
            Description = "Upper bound for random warranty multiplier. Each device gets a random value between min and max."
        }
    }
    
    $parameters += @{
        Name        = "warranty_apply_cycles"
        Label       = "Apply to Warranty Cycles"
        Type        = "boolean"
        Default     = $true
        Description = "Whether to also multiply warranty cycles (in addition to days)"
    }
    
    $parameters += @{
        Name        = "warranty_apply_remaining"
        Label       = "Apply to Remaining Warranty"
        Type        = "boolean"
        Default     = $true
        Description = "Whether to apply multiplier to remaining warranty period on already-placed devices"
    }
}

# ============================================================================
# Cost Settings (Only visible when enabled)
# ============================================================================

if ($enableCost) {
    $parameters += @{
        Type        = "section"
        Label       = "Cost Settings"
        Description = "Configure device purchase cost multipliers"
    }
    
    $parameters += @{
        Name        = "cost_multiplier"
        Label       = "Cost Multiplier"
        Type        = "number"
        Default     = 1.0
        Min         = 0.01
        Max         = 100.0
        Step        = 0.01
        Description = @"
Multiplier for device purchase costs.

Examples:
• 0.5 = Half price (make devices cheaper)
• 1.0 = Normal price (no change)
• 2.0 = Double price (make devices more expensive)

Useful for difficulty adjustments.
"@
    }
}

# ============================================================================
# Hardware Settings (Only visible when at least one is enabled)
# ============================================================================

if ($enableCpu -or $enableMemory -or $enableStorage) {
    $parameters += @{
        Type        = "section"
        Label       = "Hardware Settings"
        Description = "Configure CPU, memory, and storage multipliers"
    }
    
    if ($enableCpu) {
        $parameters += @{
            Name        = "cpu_multiplier"
            Label       = "CPU Power Multiplier"
            Type        = "number"
            Default     = 1.0
            Min         = 0.1
            Max         = 100.0
            Step        = 0.1
            Description = "Multiplier for device CPU power. Higher values = more processing capacity."
        }
    }
    
    if ($enableMemory) {
        $parameters += @{
            Name        = "memory_multiplier"
            Label       = "Memory (RAM) Multiplier"
            Type        = "number"
            Default     = 1.0
            Min         = 0.1
            Max         = 100.0
            Step        = 0.1
            Description = "Multiplier for device installed RAM. Higher values = more memory available."
        }
    }
    
    if ($enableStorage) {
        $parameters += @{
            Name        = "storage_multiplier"
            Label       = "Storage Multiplier"
            Type        = "number"
            Default     = 1.0
            Min         = 0.1
            Max         = 100.0
            Step        = 0.1
            Description = "Multiplier for device storage capacity. Higher values = more disk space."
        }
    }
}

# ============================================================================
# Device Class Filters Section
# ============================================================================

$parameters += @{
    Type        = "section"
    Label       = "Device Class Filters"
    Description = "Choose which device types will be affected by modifications. Disable specific classes to exclude them."
}

$parameters += @{
    Type    = "warning"
    Message = "If all device classes are disabled, no modifications will be applied regardless of other settings."
}

# Network device classes
$parameters += @{
    Name        = "enable_network_switch"
    Label       = "Network Switches"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to network switch devices"
}

$parameters += @{
    Name        = "enable_network_router"
    Label       = "Network Routers"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to network router devices"
}

$parameters += @{
    Name        = "enable_network_firewall"
    Label       = "Network Firewalls"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to network firewall devices"
}

$parameters += @{
    Name        = "enable_network_load_balancer"
    Label       = "Network Load Balancers"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to network load balancer devices"
}

$parameters += @{
    Name        = "enable_network_tap"
    Label       = "Network Taps"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to network tap devices"
}

# Compute devices
$parameters += @{
    Name        = "enable_compute_server"
    Label       = "Compute Servers"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to compute server devices"
}

# Media devices
$parameters += @{
    Name        = "enable_media_line_simplex"
    Label       = "Media Line Simplex"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to media line simplex devices"
}

$parameters += @{
    Name        = "enable_media_line_duplex"
    Label       = "Media Line Duplex"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to media line duplex devices"
}

# Peripheral devices
$parameters += @{
    Name        = "enable_display_monitor"
    Label       = "Display Monitors"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to display monitor devices"
}

$parameters += @{
    Name        = "enable_printer"
    Label       = "Printers"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to printer devices"
}

$parameters += @{
    Name        = "enable_phone"
    Label       = "Phones"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to phone devices"
}

$parameters += @{
    Name        = "enable_cctv"
    Label       = "CCTV Cameras"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to CCTV camera devices"
}

# Diagnostic devices
$parameters += @{
    Name        = "enable_debugger"
    Label       = "Debuggers"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to debugger devices"
}

$parameters += @{
    Name        = "enable_load_tester"
    Label       = "Load Testers"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to load tester devices"
}

# Power devices
$parameters += @{
    Name        = "enable_power_expansion"
    Label       = "Power Expansion"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to power expansion devices"
}

$parameters += @{
    Name        = "enable_surge_protector"
    Label       = "Surge Protectors"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to surge protector devices"
}

$parameters += @{
    Name        = "enable_ups"
    Label       = "UPS Devices"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to UPS (uninterruptible power supply) devices"
}

# Crypto devices
$parameters += @{
    Name        = "enable_decentro_rigs"
    Label       = "Decentro Rigs"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to decentro mining rig devices"
}

# Other devices
$parameters += @{
    Name        = "enable_default"
    Label       = "Default Devices"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to default/unknown device types"
}

$parameters += @{
    Name        = "enable_inert"
    Label       = "Inert Devices"
    Type        = "boolean"
    Default     = $true
    Description = "Apply modifications to inert/decorative devices"
}

# Return parameters
return $parameters
