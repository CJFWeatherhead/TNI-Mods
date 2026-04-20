-- Money Cheat Mod
-- Purpose: Adds configurable amount of money via panel button
-- Author: CJFWeatherhead
-- Version: 4.0.0
-- Description: Adds money via floating panel button.
--              Panel auto-shows on game load. Close hides it. F11 re-shows it.
--
-- CONSTRAINTS (TNI mod sandbox limitations):
--   register_cmd  — BROKEN. The Callable bridge (_ZL15gd_callable_luam5Array)
--                   crashes on every return, even if the function body is empty.
--                   Corrupts sandbox state, stops on_tick from running.
--   on_player_input — fires on EVERY input event (including mouse movement).
--                     pcall overhead per call causes GC pressure → OOM.
--
--   ONLY SAFE INTERACTION: on_tick (native lifecycle, ~60Hz, no bridge dispatch)
--     → Panel buttons with toggle_mode=true, polled in on_tick.
--
-- Usage: Panel appears automatically. Click "Add Money" to add $10,000.
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
local _panel         = nil
local _panel_visible = false
local _panel_close   = nil
local _panel_btns    = {}
local _status_label  = nil
local _tick_count    = 0

-- =========================================================================
-- Utilities
-- =========================================================================

local function log(msg) print("[money-cheat] " .. msg) end

-- =========================================================================
-- Panel (standalone CanvasLayer at /root, auto-shown)
-- =========================================================================

local function destroy_panel()
    if _panel then pcall(function() _panel.queue_free() end) end
    _panel = nil; _panel_visible = false; _panel_close = nil
    _panel_btns = {}; _status_label = nil
end

local function build_panel(world)
    destroy_panel()
    local ok, err = pcall(function()
        local root = world.get_node("/root")
        if not root then log("build_panel: /root not found"); return end

        _panel = create_node("CanvasLayer", "")
        _panel.layer = 100
        _panel.visible = true  -- auto-show
        _panel_visible = true

        local container = create_node("PanelContainer", "")
        _panel.add_child(container)
        pcall(function()
            container.anchor_left = 1.0; container.anchor_top = 0.0
            container.anchor_right = 1.0; container.anchor_bottom = 0.0
        end)
        pcall(function()
            container.offset_left = -270; container.offset_top = 10
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

        _panel_close = create_node("Button", "")
        _panel_close.text = "X"
        _panel_close.flat = true
        _panel_close.toggle_mode = true
        pcall(function() _panel_close.custom_minimum_size = Vector2(28, 28) end)
        header.add_child(_panel_close)

        -- Status label
        _status_label = create_node("Label", "")
        _status_label.text = string.format("Click to add $%d", config.money_amount or 10000)
        pcall(function() _status_label.add_theme_font_size_override("font_size", 11) end)
        vbox.add_child(_status_label)

        -- Add Money button
        local btn = create_node("Button", "")
        btn.text = "Add Money"
        btn.toggle_mode = true
        pcall(function() btn.custom_minimum_size = Vector2(0, 32) end)
        vbox.add_child(btn)
        _panel_btns.add = btn

        root.add_child(_panel)
        log("Panel built and auto-shown")
    end)
    if not ok then log("build_panel ERROR: " .. tostring(err)) end
end

-- =========================================================================
-- Core logic (runs ONLY from on_tick — native lifecycle context)
-- =========================================================================

local function do_money()
    log("do_money: begin")
    local money_amount = config.money_amount or 10000

    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if not world then log("do_money: no game world"); return end
        world.modify_player_cash(money_amount, "Money Cheat", 1)
    end)

    if ok then
        log("do_money: added $" .. tostring(money_amount))
        if _status_label then
            pcall(function() _status_label.text = string.format("Added $%d!", money_amount) end)
        end
    else
        log("do_money: ERROR: " .. tostring(err))
        if _status_label then
            pcall(function() _status_label.text = "ERROR — see console" end)
        end
    end
end

-- =========================================================================
-- Lifecycle (NO register_cmd, NO on_player_input)
-- =========================================================================

function on_engine_load()
    log("Money Cheat v4.0.0 loaded")
    log("Panel-only mode (no register_cmd, no keyboard shortcuts)")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
    log(string.format("Config: Amount=$%d", config.money_amount or 10000))
end

function on_game_state_ready()
    log("on_game_state_ready: begin")
    local world = ModApiV1.get_game_world()
    if not world then log("on_game_state_ready: no game world"); return end

    -- Enable debug console for other mods/built-in commands only
    pcall(function()
        local dbg = world.get_node("/root/DebugLayer")
        if dbg then dbg.enabled = true end
    end)

    build_panel(world)
    log("on_game_state_ready: panel ready — click Add Money to use")
end

function on_mod_reload()
    log("Reloaded (F11)")
    destroy_panel()
    local world = ModApiV1 and ModApiV1.get_game_world()
    if world then build_panel(world) end
end

function on_tick(delta)
    _tick_count = _tick_count + 1

    -- Poll close button
    if _panel_close then
        pcall(function()
            if _panel_close.button_pressed then
                _panel_close.button_pressed = false
                _panel_visible = false
                _panel.visible = false
                log("Panel hidden (F11 to reopen)")
            end
        end)
    end

    -- Poll Add Money button
    if _panel_btns.add then
        pcall(function()
            if _panel_btns.add.button_pressed then
                _panel_btns.add.button_pressed = false
                do_money()
            end
        end)
    end

    -- Periodic diagnostics (every ~5 seconds when panel visible)
    if _tick_count % 300 == 0 and _panel_visible then
        pcall(function()
            local btn = _panel_btns.add
            if btn then
                log(string.format("DIAG tick=%d pressed=%s visible=%s disabled=%s",
                    _tick_count,
                    tostring(btn.button_pressed),
                    tostring(btn.visible),
                    tostring(btn.disabled)))
            else
                log("DIAG tick=" .. _tick_count .. " btn=nil")
            end
        end)
    end
end
