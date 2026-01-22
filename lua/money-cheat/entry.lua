-- Money Cheat Mod
-- Purpose: Adds configurable amount of money when SHIFT+M is pressed
-- Author: Unknown
-- Version: 1.0
-- Description: This mod provides a simple money cheat accessible via keyboard shortcut.
--              Press SHIFT+M to instantly add a configurable amount of money to your balance.
--              Configure the amount in Mod Manager.
-- Usage: Press SHIFT+M during gameplay to receive money. Check console for confirmation.
-- Notes: Uses on_player_input hook to detect keyboard input. Amount is configurable via MOD CONFIGURATION section.

local mod_id = "money-cheat"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Amount of money to add when cheat is activated
    money_amount = 10000,

    -- Advanced options
    debug_logging = true,
    show_notification = true
}

-- ===== MOD CONFIGURATION END =====

-- Track key states to detect SHIFT+M combination
local shift_m_pressed = false
local last_cheat_time = 0
local COOLDOWN_SECONDS = 0.5 -- Prevent accidental double-activation

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

    print("[money-cheat] Press SHIFT+M to add money")
end

function on_mod_reload()
    print("Pressed the reload action key (F11), reloading Money Cheat mod...")
    print(string.format("[money-cheat] Current amount: $%d", config.money_amount or 10000))
end

-- Keyboard input handler for Shift+M shortcut
function on_player_input(event)
    -- Check if this is a keyboard event
    local event_class = nil
    pcall(function() event_class = event:get_class() end)

    if event_class == "InputEventKey" then
        -- Get keycode and check if it's the M key (ASCII 77)
        local keycode = nil
        local is_pressed = false
        local is_shift = false

        pcall(function() keycode = event:get_keycode() end)
        pcall(function() is_pressed = event:is_pressed() end)
        pcall(function() is_shift = event:is_shift_pressed() end)

        -- Shift+M combination (77 is the keycode for 'M')
        if keycode == 77 and is_shift then
            if is_pressed and not shift_m_pressed then
                -- Key was just pressed down
                shift_m_pressed = true

                -- Check cooldown to prevent accidental double-activation
                local current_time = os.clock()
                if current_time - last_cheat_time < COOLDOWN_SECONDS then
                    if config.debug_logging then
                        print("[money-cheat] Cooldown active, ignoring key press")
                    end
                    return
                end

                last_cheat_time = current_time

                -- Add money to player
                local world = ModApiV1.get_game_world()
                if not world then
                    print("[money-cheat] ERROR: Could not get game world!")
                    return
                end

                local money_amount = config.money_amount or 10000

                -- Use the proper transaction system to add money
                world.modify_player_cash(money_amount, "Money Cheat Activated", 1) -- Category 1 = INCOME

                -- Show confirmation message
                local message = string.format("[money-cheat] Added $%d to your balance!", money_amount)
                print(message)

                -- Optional: Show in-game notification if available
                if config.show_notification then
                    pcall(function()
                        if world.show_notification then
                            world.show_notification("Money Added", string.format("$%d", money_amount), "success")
                        end
                    end)
                end
            elseif not is_pressed and shift_m_pressed then
                -- Key was released
                shift_m_pressed = false
            end
        end
    end
end
