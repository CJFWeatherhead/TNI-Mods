# ui-config.ps1 - User Floor-Based Addressing Mod
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the User Floor-Based Addressing mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    It demonstrates advanced conditional logic where hardware address options
    are only shown when certain prerequisites are met.

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
$disableHwRefresh = if ($CurrentConfig.ContainsKey('disable_hw_refresh')) {
    $CurrentConfig['disable_hw_refresh']
} else {
    $false
}

# ============================================================================
# Network Addressing Configuration
# ============================================================================

$parameters += @{
    Type = "section"
    Label = "User Network Configuration"
    Description = "Configure how users get their network settings"
}

$parameters += @{
    Name = "dhcp_mode"
    Label = "DHCP Mode"
    Type = "select"
    Default = "boot_dhcp"
    Options = @("disabled", "boot_dhcp", "periodic_dhcp")
    Description = @"
DHCP mode for user computers:

• disabled: Manual configuration only, users must set addresses manually
• boot_dhcp: DHCP requests on boot only, then static address
• periodic_dhcp: Periodic DHCP requests, addresses may change

Recommended: boot_dhcp for stable addressing after initial setup
"@
}

$parameters += @{
    Name = "address_format"
    Label = "Network Address Format"
    Type = "string"
    Default = "f%d/usr%d"
    Description = @"
Format string for network addresses.
Uses C-style printf format with two %d placeholders:
  1st %d = floor number
  2nd %d = user increment (counter per floor)

Examples:
• "f%d/usr%d" → f0/usr1, f0/usr2, f1/usr1, ...
• "floor-%d/u%d" → floor-0/u1, floor-0/u2, ...
• "%d.%d" → 0.1, 0.2, 1.1, 1.2, ...

Must contain exactly two %d placeholders.
"@
    Validate = {
        param($Value)
        $matches = [regex]::Matches($Value, "%d")
        if ($matches.Count -ne 2) {
            return "Address format must contain exactly two %d placeholders"
        }
        return $null
    }
}

# ============================================================================
# DNS Configuration
# ============================================================================

$parameters += @{
    Type = "section"
    Label = "DNS Configuration"
    Description = "Configure DNS servers for users"
}

$parameters += @{
    Name = "dns_format"
    Label = "Floor DNS Server Format"
    Type = "string"
    Default = "@f%d/dns"
    Description = @"
Format string for floor-specific DNS servers.
One %d placeholder is replaced with floor number.

Examples:
• "@f%d/dns" → @f0/dns, @f1/dns, ...
• "dns-floor%d" → dns-floor0, dns-floor1, ...
• "10.0.%d.1" → 10.0.0.1, 10.0.1.1, ...

Must contain exactly one %d placeholder.
"@
    Validate = {
        param($Value)
        $matches = [regex]::Matches($Value, "%d")
        if ($matches.Count -ne 1) {
            return "DNS format must contain exactly one %d placeholder"
        }
        return $null
    }
}

$parameters += @{
    Name = "fallback_dns_1"
    Label = "Fallback DNS Server 1"
    Type = "string"
    Default = "@f0/dns1"
    Description = @"
First fallback DNS server if floor-specific DNS is unavailable.
Usually points to a central/ground floor DNS server.
"@
}

$parameters += @{
    Name = "fallback_dns_2"
    Label = "Fallback DNS Server 2"
    Type = "string"
    Default = "@f0/dns2"
    Description = @"
Second fallback DNS server.
Provides redundancy if both floor-specific and first fallback fail.
"@
}

# ============================================================================
# Hardware Address Configuration
# ============================================================================

$parameters += @{
    Type = "section"
    Label = "Hardware Address Configuration"
    Description = "Configure MAC address behavior"
}

$parameters += @{
    Name = "disable_hw_refresh"
    Label = "Disable Hardware Address Refresh"
    Type = "boolean"
    Default = $false
    Description = @"
Control whether users refresh their hardware (MAC) addresses.

• Disabled (false): Users will periodically refresh hardware addresses (game default)
• Enabled (true): Users keep static hardware addresses (required for predictable addressing)

⚠️ Enable this to use predictable hardware addresses below.
"@
}

# Conditional: Predictable Hardware Addresses
# Only show this option if disable_hw_refresh is enabled
if ($disableHwRefresh) {
    $parameters += @{
        Name = "predictable_hw_address"
        Label = "Use Predictable Hardware Addresses"
        Type = "boolean"
        Default = $false
        Description = @"
Generate predictable hardware addresses based on floor and user number.
Requires "Disable Hardware Address Refresh" to be enabled.

Address format: {floor}{user_increment} (zero-padded)

Examples:
• Floor 0, User 1 → 0001
• Floor 5, User 3 → 5003
• Floor 12, User 25 → 12025
• Floor 113, User 321 → 113321

⚠️ Useful for debugging and consistent network behavior.
"@
    }
    
    # Show warning if predictable addresses are enabled but refresh isn't disabled
    if ($CurrentConfig.ContainsKey('predictable_hw_address') -and 
        $CurrentConfig['predictable_hw_address'] -and 
        -not $disableHwRefresh) {
        $parameters += @{
            Type = "warning"
            Message = "⚠️ Predictable hardware addresses require 'Disable Hardware Address Refresh' to be enabled!"
        }
    }
} else {
    # Show info message about enabling predictable addresses
    $parameters += @{
        Type = "info"
        Message = "💡 Enable 'Disable Hardware Address Refresh' above to unlock predictable hardware addressing"
    }
}

# ============================================================================
# Device Addressing (Phones, CCTV)
# ============================================================================

$parameters += @{
    Type = "section"
    Label = "Device Network Configuration"
    Description = "Configure network addresses for phones and CCTV cameras"
}

$parameters += @{
    Name = "phone_address_format"
    Label = "Phone Address Format"
    Type = "string"
    Default = "@voice/f%d/%d"
    Description = @"
Format string for phone network addresses.
Uses C-style printf format with two %d placeholders:
  1st %d = floor number
  2nd %d = device increment (counter per floor)

Examples:
• "@voice/f%d/%d" → @voice/f0/1, @voice/f0/2, ...
• "phone-%d-%d" → phone-0-1, phone-0-2, ...

Must contain exactly two %d placeholders.
"@
    Validate = {
        param($Value)
        $matches = [regex]::Matches($Value, "%d")
        if ($matches.Count -ne 2) {
            return "Phone address format must contain exactly two %d placeholders"
        }
        return $null
    }
}

$parameters += @{
    Name = "cctv_address_format"
    Label = "CCTV Address Format"
    Type = "string"
    Default = "@cam/f%d/%d"
    Description = @"
Format string for CCTV camera network addresses.
Uses C-style printf format with two %d placeholders:
  1st %d = floor number
  2nd %d = device increment (counter per floor)

Examples:
• "@cam/f%d/%d" → @cam/f0/1, @cam/f0/2, ...
• "camera-%d-%d" → camera-0-1, camera-0-2, ...

Must contain exactly two %d placeholders.
"@
    Validate = {
        param($Value)
        $matches = [regex]::Matches($Value, "%d")
        if ($matches.Count -ne 2) {
            return "CCTV address format must contain exactly two %d placeholders"
        }
        return $null
    }
}

# ============================================================================
# Advanced Options
# ============================================================================

$parameters += @{
    Type = "section"
    Label = "Advanced Options"
    Description = "Additional configuration and debugging"
    Collapsed = $true
}

$parameters += @{
    Name = "debug_logging"
    Label = "Enable Debug Logging"
    Type = "boolean"
    Default = $false
    Description = "Log detailed address assignment information to console"
}

$parameters += @{
    Name = "strict_validation"
    Label = "Strict Format Validation"
    Type = "boolean"
    Default = $true
    Description = @"
Validate address formats strictly before applying.
If validation fails, mod will not apply settings and log an error.

Disable only if you know what you're doing.
"@
}

# ============================================================================
# Return the parameter definitions
# ============================================================================

return $parameters
