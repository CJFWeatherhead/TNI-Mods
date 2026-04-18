-- Money Cheat Mod
-- Purpose: Adds configurable amount of money when SHIFT+M is pressed
-- Author: Unknown
-- Version: 1.4
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
    debug_logging = false,
    show_notification = true
}

-- ===== MOD CONFIGURATION END =====

-- Track key states to detect SHIFT+M combination
local shift_m_pressed = false
local last_cheat_time = 0
local COOLDOWN_SECONDS = 0.5 -- Prevent accidental double-activation

function on_engine_load()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 400)

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

-- Named helpers — see device-tweaker for explanation
local function _ev_get_class(e)         return e:get_class() end
local function _ev_get_keycode(e)       return e:get_keycode() end
local function _ev_is_pressed(e)        return e:is_pressed() end
local function _ev_is_shift_pressed(e)  return e:is_shift_pressed() end

-- Counter for rate-limited GC in the input hot path
local _input_gc_counter = 0

-- Keyboard input handler for Shift+M shortcut
function on_player_input(event)
    _input_gc_counter = _input_gc_counter + 1
    if _input_gc_counter >= 100 then
        _input_gc_counter = 0
        collectgarbage("step")
    end

    local ok, event_class = pcall(_ev_get_class, event)
    if not ok or event_class ~= "InputEventKey" then return end

    do
        -- Get keycode and check if it's the M key (ASCII 77)
        local ok1, keycode    = pcall(_ev_get_keycode, event)
        local ok2, is_pressed = pcall(_ev_is_pressed, event)
        local ok3, is_shift   = pcall(_ev_is_shift_pressed, event)
        if not (ok1 and ok2 and ok3) then return end

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
                        local base_ui = ModApiV1.get_base_ui()
                        if base_ui and base_ui.display_notification then
                            -- tone_enum: 0 = neutral, 1 = positive, 2 = negative
                            base_ui.display_notification(string.format("Added $%d", money_amount), 1)
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
