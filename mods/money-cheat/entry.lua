-- Money Cheat Mod
-- Purpose: Adds configurable amount of money via console command
-- Author: Unknown
-- Version: 2.2
-- Description: This mod provides a simple money cheat accessible via console command.
--              Type money in the debug console (~) to add money.
--              Configure the amount in Mod Manager.
-- Usage: Open the debug console (~) and type: money
--
-- Console commands:
--   money        Add configured amount of money
--   money(50000) Add specific amount (globals only)

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

local _mc_status = nil
local setup_panel   -- forward-declared; defined after money()

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

    print("[money-cheat] Console: money")
end

function on_mod_reload()
    print("[money-cheat] Reloaded (F11)")
    _mc_status = nil
    if setup_panel then setup_panel() end
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

    -- Update panel status (no display_notification — causes sandbox timeouts)
    if _mc_status then
        pcall(function() _mc_status.text = string.format("Last: +$%d", money_amount) end)
    end
end

-- Panel section builder (shared ModPanels framework)
setup_panel = function()
    local world = ModApiV1 and ModApiV1.get_game_world()
    if not world then return end
    local ok, content = pcall(function()
        return world.get_node("/root/ModPanels/Panel/Layout/Scroll/Content")
    end)
    if not ok or not content then return end

    pcall(function()
        local old = content.get_node("mp_money_cheat")
        if old then old.queue_free() end
    end)

    local section = create_node("VBoxContainer", "")
    section.name = "mp_money_cheat"

    local sep = create_node("HSeparator", "")
    section.add_child(sep)
    local title = create_node("Label", "")
    title.text = "Money Cheat"
    pcall(function() title.add_theme_font_size_override("font_size", 14) end)
    section.add_child(title)

    _mc_status = create_node("Label", "")
    _mc_status.text = string.format("Amount: $%d", config.money_amount or 10000)
    pcall(function() _mc_status.add_theme_font_size_override("font_size", 11) end)
    section.add_child(_mc_status)

    local btn = create_node("Button", "")
    btn.text = "Add Money"
    pcall(function() btn.custom_minimum_size = Vector2(110, 28) end)
    section.add_child(btn)
    btn.connect("pressed", money)

    content.add_child(section)
    print("[money-cheat] Panel section registered with ModPanels")
end

-- Register commands with the debug console when game is fully loaded
function on_game_state_ready()
    local world = ModApiV1.get_game_world()
    if not world then return end

    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if not ok or not dbg then
        print("[money-cheat] DebugLayer not found, commands available as globals only")
        return
    end

    -- Enable the debug console (disabled by default in the game)
    pcall(function() dbg.enabled = true end)

    pcall(function() dbg.register_cmd("m_money", money) end)
    print("[money-cheat] Debug console enabled. Registered: m_money")

    setup_panel()
end

function on_tick(delta) end
