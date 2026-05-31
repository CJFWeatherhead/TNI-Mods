# ui-config.ps1 - Supa Mod Loader v3.7.2
# UI Configuration script — automatically managed by ModManagerGUI.ps1.

<#
.SYNOPSIS
    Generates UI configuration for the Supa Mod Loader.

.DESCRIPTION
    This mod is a marker automatically added by ModManagerGUI.ps1.
    It has no user-configurable settings. The configuration panel simply
    displays information about the ModManager GUI installation.

.PARAMETER CurrentConfig
    The current configuration values for this mod (unused).
#>

param(
    [hashtable]$CurrentConfig = @{}
)

$parameters = @()

$parameters += @{
    Type        = "section"
    Label       = "Supa Mod Loader v3.7.2"
    Description = "Automatically added by ModManagerGUI.ps1 — no user configuration required"
}

$parameters += @{
    Type  = "info"
    Label = "Purpose"
    Text  = @"
This mod is added automatically by the ModManager GUI when mods are installed.

Its presence signals to other mods that this installation was set up via
ModManagerGUI.ps1 rather than being manually installed.

No gameplay changes are made. You do not need to configure anything here.
"@
}

$parameters += @{
    Type  = "info"
    Label = "Version Tracking"
    Text  = @"
The version of this mod corresponds to the ModManager GUI version that was
used to install your mods. This allows other mods to tailor guidance or
update reminders based on the installation method.

Current mod manager version tracked: 3.7.2
"@
}

$parameters += @{
    Type  = "info"
    Label = "Manual Installation"
    Text  = @"
If you installed mods manually and want other mods to recognise the
mod manager integration, you can add this mod to your mods folder.

To keep things consistent, use the ModManager GUI for future installs.
"@
}

# Return the configuration
return $parameters
