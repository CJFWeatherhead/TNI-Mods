-- Money Cheat Mod
-- Purpose: Adds configurable amount of money via panel button
-- Author: CJFWeatherhead
-- Version: 4.1.0
-- Description: Adds money via floating panel button.
--              Panel auto-shows on game load. Close hides it. F11 re-shows it.
--
-- ARCHITECTURE (matching proven TARDIS v2.1.0 pattern a5ce472):
--   - Panel parented to Mod.add_child() (stays within sandbox context)
--   - Buttons use connect("pressed", closure) — NOT toggle_mode polling
--   - Closures pinned in _callbacks table to prevent GC
--   - No register_cmd (Callable bridge crashes on return)
--   - No on_player_input (fires per mouse-move, GC pressure)
--
-- Usage: Panel appears automatically. Click "Add Money" to add money.
--        Close panel with X. Reopen with F11 (mod reload).

local mod_id = "money-cheat"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Amount of money to add when cheat is activated
    money_amount = 10000,

    -- Advanced options
    debug_logging = false
}

-- ===== MOD CONFIGURATION END =====

-- Panel state
local _panel         = nil   -- CanvasLayer
local _panel_visible = false
local _status_label  = nil
local _callbacks     = {}    -- prevent GC of signal closures

-- =========================================================================
-- Utilities
-- =========================================================================

local function log(msg) print("[money-cheat] " .. msg) end

-- =========================================================================
-- Core logic
-- =========================================================================

-- Global so closures can reference it and it survives GC
function do_add_money()
    log("do_add_money: begin")
    local money_amount = config.money_amount or 10000
    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if not world then log("do_add_money: no game world"); return end
        world.modify_player_cash(money_amount, "Money Cheat", 1)
    end)
    if ok then
        log("do_add_money: added $" .. tostring(money_amount))
        if _status_label then
            pcall(function() _status_label.text = string.format("Added $%d!", money_amount) end)
        end
    else
        log("do_add_money: ERROR: " .. tostring(err))
    end
end

-- =========================================================================
-- Panel (CanvasLayer parented to Mod — within sandbox context)
-- Matches proven pattern from TARDIS v2.1.0 (a5ce472)
-- =========================================================================

local function destroy_panel()
    if _panel then pcall(function() _panel.queue_free() end) end
    _panel = nil; _panel_visible = false; _status_label = nil; _callbacks = {}
end

local function build_panel()
    destroy_panel()
    local ok, err = pcall(function()
        _panel = create_node("CanvasLayer", "")
        _panel.layer = 100

        local container = create_node("PanelContainer", "")
        _panel.add_child(container)
        pcall(function()
            container.anchor_left = 1.0; container.anchor_top = 0.0
            container.anchor_right = 1.0; container.anchor_bottom = 0.0
        end)
        pcall(function()
            container.offset_left = -260; container.offset_top = 10
            container.offset_right = -10;  container.offset_bottom = 140
        end)
        pcall(function() container.self_modulate = Color(1, 1, 1, 0.92) end)

        local vbox = create_node("VBoxContainer", "")
        container.add_child(vbox)

        -- Header row
        local header = create_node("HBoxContainer", "")
        vbox.add_child(header)
        local title = create_node("Label", "")
        title.text = "Money Cheat"
        pcall(function() title.add_theme_font_size_override("font_size", 15) end)
        pcall(function() title.size_flags_horizontal = 3 end)
        header.add_child(title)

        -- Close button (signal connected, not toggle_mode)
        local close_btn = create_node("Button", "")
        close_btn.text = "X"
        close_btn.flat = true
        pcall(function() close_btn.custom_minimum_size = Vector2(28, 28) end)
        header.add_child(close_btn)

        local close_cb = function()
            if _panel then
                pcall(function() _panel.visible = false end)
                _panel_visible = false
                log("Panel hidden (F11 to reopen)")
            end
        end
        table.insert(_callbacks, close_cb)
        close_btn.connect("pressed", close_cb)

        -- Status label
        _status_label = create_node("Label", "")
        _status_label.text = string.format("Click to add $%d", config.money_amount or 10000)
        pcall(function() _status_label.add_theme_font_size_override("font_size", 12) end)
        vbox.add_child(_status_label)

        -- Add Money button (signal connected, not toggle_mode)
        local money_btn = create_node("Button", "")
        money_btn.text = "Add Money"
        pcall(function() money_btn.add_theme_font_size_override("font_size", 13) end)
        pcall(function() money_btn.custom_minimum_size = Vector2(0, 32) end)
        vbox.add_child(money_btn)

        local money_cb = function() do_add_money() end
        table.insert(_callbacks, money_cb)
        money_btn.connect("pressed", money_cb)

        -- Parent to Mod (within sandbox context — proven pattern)
        Mod.add_child(_panel)
        _panel_visible = true
        log("Panel built (Mod.add_child, signal connect, auto-shown)")
    end)
    if not ok then
        log("build_panel ERROR: " .. tostring(err))
        destroy_panel()
    end
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    log("Money Cheat v4.1.0 loaded")
    log("Panel-only (Mod.add_child + connect pattern from TARDIS v2.1.0)")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
    log(string.format("Config: Amount=$%d", config.money_amount or 10000))
end

function on_game_state_ready()
    log("on_game_state_ready: begin")
    local world = ModApiV1.get_game_world()
    if not world then log("on_game_state_ready: no game world"); return end
    build_panel()
    log("on_game_state_ready: done")
end

function on_mod_reload()
    log("Reloaded (F11)")
    destroy_panel()
    build_panel()
end
