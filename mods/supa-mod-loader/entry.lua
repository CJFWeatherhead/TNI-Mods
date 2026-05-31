-- Supa Mod Loader v4.1.0
-- Marker mod for ModManagerGUI.
-- Previously hosted a shared ModPanels framework; reverted because the
-- sandbox callable bridge cannot reliably dispatch across sandboxes.
-- Each mod now hosts its own panel to avoid cross-sandbox issues.

local MOD_ID      = "supa-mod-loader"
local MOD_VERSION = "4.1.0"

print(string.format("[%s] v%s loaded", MOD_ID, MOD_VERSION))

if Mod then
    Mod.loader_version = MOD_VERSION
    Mod.installed_by   = "ModManagerGUI"
end

function on_engine_load()
    print(string.format("[%s] v%s ready", MOD_ID, MOD_VERSION))
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
end

function on_game_state_ready()
end

function on_mod_reload()
    print(string.format("[%s] Reloaded (F11)", MOD_ID))
end

function on_tick(delta) end
