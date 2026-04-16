-- Supa Mod Loader v3.5.4
-- Automatically added by ModManagerGUI.ps1 when mods are installed via the mod manager.
-- Presence of this mod indicates the mod collection was set up using the ModManager GUI.
-- No gameplay changes are made by this mod.

local MOD_ID      = "supa-mod-loader"
local MOD_VERSION = "3.7.2"

-- Report that the mod manager installer is present.
-- Other mods can check for supa-mod-loader via the optional dependency system
-- to determine whether they were installed manually or through the GUI.
print(string.format("[%s] v%s loaded — installed via ModManager GUI", MOD_ID, MOD_VERSION))

-- Expose version information for mods that query it at runtime.
if Mod then
    Mod.loader_version = MOD_VERSION
    Mod.installed_by   = "ModManagerGUI"
end
