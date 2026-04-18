-- Money Cheat Mod
-- Purpose: Adds configurable amount of money via console command
-- Author: Unknown
-- Version: 2.0
-- Description: This mod provides a simple money cheat accessible via console command.
--              Type money() in the game console to add money.
--              Configure the amount in Mod Manager.
-- Usage: Type money() in the game console. Check console for confirmation.
--
-- Console commands:
--   money()        Add configured amount of money
--   money(50000)   Add specific amount of money

local mod_id = "money-cheat"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Amount of money to add when cheat is activated
    money_amount = 10000,

    -- Advanced options
    debug_logging = false,
    show_notification = true
}

-- ===== MOD CONFIGURATION END =====

function on_engine_load()
    print("Money Cheat mod loaded!")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        print("ModApiV1 is not available!")
    end

    -- Log current configuration
    local money_amount = config.money_amount or 10000
    local debug_logging = config.debug_logging

    print(string.format("[money-cheat] Config: Amount=$%d, Debug:%s, Notifications:%s",
        money_amount,
        tostring(debug_logging),
        tostring(config.show_notification)))

    print("[money-cheat] Console: money() or money(50000)")
end

function on_mod_reload()
    print("Pressed the reload action key (F11), reloading Money Cheat mod...")
    print(string.format("[money-cheat] Current amount: $%d", config.money_amount or 10000))
end

-- Console command: add money
-- Usage: money() or money(50000)
function money(amount)
    local money_amount = amount or config.money_amount or 10000

    local world = ModApiV1.get_game_world()
    if not world then
        print("[money-cheat] ERROR: Could not get game world!")
        return
    end

    world.modify_player_cash(money_amount, "Money Cheat Activated", 1)

    local message = string.format("[money-cheat] Added $%d to your balance!", money_amount)
    print(message)

    if config.show_notification then
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui and base_ui.display_notification then
                base_ui.display_notification(string.format("Added $%d", money_amount), 1)
            end
        end)
    end
end
