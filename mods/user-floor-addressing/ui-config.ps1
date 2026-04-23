# ui-config.ps1 - User Floor-Based Addressing Mod
# UI Configuration Script

<#
.SYNOPSIS
    Generates UI configuration for the User Floor-Based Addressing mod.

.DESCRIPTION
    This script defines the configuration parameters for the mod.
    Configures network addressing and DNS for users based on floor number.

    Note: Hardware (MAC) address configuration is not available -- the mod
    API does not expose hardware address control. Phone and CCTV devices are
    not configurable -- they are fixture outlets not exposed by the mod API.

.PARAMETER CurrentConfig
    The current configuration values for this mod.
#>

param(
    [hashtable]$CurrentConfig = @{}
)

# Initialize parameters array
$parameters = @()

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

- disabled: Manual configuration only, users must set addresses manually
- boot_dhcp: DHCP requests on boot only, then static address
- periodic_dhcp: Periodic DHCP requests, addresses may change

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
- "f%d/usr%d" -> f0/usr1, f0/usr2, f1/usr1, ...
- "floor-%d/u%d" -> floor-0/u1, floor-0/u2, ...
- "%d.%d" -> 0.1, 0.2, 1.1, 1.2, ...

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
- "@f%d/dns" -> @f0/dns, @f1/dns, ...
- "dns-floor%d" -> dns-floor0, dns-floor1, ...
- "10.0.%d.1" -> 10.0.0.1, 10.0.1.1, ...

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

# ============================================================================
# Return the parameter definitions
# ============================================================================

return $parameters
