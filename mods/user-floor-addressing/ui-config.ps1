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
    Name = "use_random_suffix"
    Label = "Use Randomised Suffix"
    Type = "boolean"
    Default = $false
    Description = @"
How the per-user part of the address is generated:

- false (off): Incremental counter per floor (usr1, usr2, usr3, ...)
- true (on):   Random 4-character lowercase suffix (usrabcd, usrxyze, ...)

Random suffixes avoid predictable addressing but may collide on very busy floors.
"@
}

$parameters += @{
    Name = "address_format"
    Label = "Network Address Format"
    Type = "string"
    Default = "@f%d/usr%s"
    Description = @"
Format string for network addresses.
Uses C-style printf format with one %d and one %s placeholder:
  %d = floor number
  %s = user suffix (incremental number or random 4-char string, depending on the toggle above)

Examples:
- "@f%d/usr%s" -> @f0/usr1, @f0/usr2 or @f0/usrabcd, @f0/usrxyze
- "floor-%d/u%s" -> floor-0/u1 or floor-0/uabcd
- "%d-%s" -> 0-1, 0-2 or 0-abcd

Must contain exactly one %d placeholder and one %s placeholder.
"@
    Validate = {
        param(`$Value)
        `$dMatches = [regex]::Matches(`$Value, "%d")
        `$sMatches = [regex]::Matches(`$Value, "%s")
        if (`$dMatches.Count -ne 1 -or `$sMatches.Count -ne 1) {
            return "Address format must contain exactly one %d placeholder and one %s placeholder"
        }
        return `$null
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
