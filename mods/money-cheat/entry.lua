-- Money Cheat Mod
-- Purpose: Adds money and restocks merchants via keyboard shortcuts
-- Author: CJFWeatherhead
-- Version: 5.0.0
-- Description: Keyboard-driven mod using on_player_input (proven working in v0.1.8).
--              SHIFT+M = add money, SHIFT+R = restock merchants.
--              Single pcall wrapper, early returns on non-key events.
--              No panels, no register_cmd, no signal connect.
--
-- Keyboard shortcuts:
--   SHIFT+M    Add configured amount of money
--   SHIFT+R    Restock all merchants
--
-- ARCHITECTURE:
--   on_player_input is a native lifecycle hook (not Callable dispatch).
--   Proven to work reliably and repeatedly in v0.1.8.
--   One pcall wraps the entire handler. Early return on non-keyboard events
--   means zero overhead for mouse/gamepad input. Keycode checks are simple
--   integer comparisons — no allocations, no GC pressure.

local mod_id = "money-cheat"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Amount of money to add when SHIFT+M is pressed
    money_amount = 10000,

    -- Advanced options
    debug_logging = false
}

-- ===== MOD CONFIGURATION END =====

-- =========================================================================
-- Core logic
-- =========================================================================

local function log(msg) print("[money-cheat] " .. msg) end

local function add_money()
    local amount = config.money_amount or 10000
    local world = ModApiV1.get_game_world()
    if not world then log("No game world"); return end
    world.modify_player_cash(amount, "Money Cheat", 1)
    log("Added $" .. tostring(amount))
end

local function restock_merchants()
    local merchants = ModApiV1.get_merchants()
    if not merchants then log("get_merchants() returned nil"); return end
    local count = 0
    local size = merchants:size()
    for i = 0, size - 1 do
        local m = merchants:get(i)
        if m then
            local ok = pcall(function() m.restock() end)
            if ok then count = count + 1 end
        end
    end
    log("Restocked " .. tostring(count) .. "/" .. tostring(size) .. " merchants")
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    log("Money Cheat v5.0.0 loaded (keyboard: SHIFT+M = money, SHIFT+R = restock)")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
    log(string.format("Config: Amount=$%d", config.money_amount or 10000))
end

function on_game_state_ready()
    log("Ready")
end

function on_mod_reload()
    log("Reloaded (F11)")
end

-- =========================================================================
-- Input handler (single pcall, early returns, minimal overhead)
-- =========================================================================

function on_player_input(event)
    pcall(function()
        if event:get_class() ~= "InputEventKey" then return end
        if not event:is_pressed() then return end
        if event:is_echo() then return end
        if not event:is_shift_pressed() then return end
        local key = event:get_keycode()
        if key == 77 then add_money()             -- SHIFT+M
        elseif key == 82 then restock_merchants() -- SHIFT+R
        end
    end)
end
