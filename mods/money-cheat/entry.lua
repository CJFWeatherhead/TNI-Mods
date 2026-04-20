-- Money Cheat Mod
-- Purpose: Adds configurable amount of money via console command
-- Author: CJFWeatherhead
-- Version: 3.0.0
-- Description: Adds money via debug console. Own floating panel with
--              toggle-mode button polled via on_tick.
-- Usage: Open the debug console (~) and type: m_money
--
-- Console commands:
--   m_money        Add configured amount of money
--   m_mc_panel     Toggle the Money Cheat panel
--
-- ARCHITECTURE NOTES:
--   Panel is a standalone CanvasLayer parented to /root.
--   Buttons use toggle_mode=true polled in on_tick — no signal connect.
--   Every Godot API call wrapped in pcall with step-by-step logging.

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

-- =========================================================================
-- Utilities
-- =========================================================================

local function log(msg) print("[money-cheat] " .. msg) end
local function step(tag, msg) log(tag .. ": " .. msg) end

-- =========================================================================
-- Panel (standalone CanvasLayer at /root)
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
        _panel.visible = false

        local container = create_node("PanelContainer", "")
        _panel.add_child(container)
        pcall(function()
            container.anchor_left = 1.0; container.anchor_top = 0.0
            container.anchor_right = 1.0; container.anchor_bottom = 0.0
        end)
        pcall(function()
            container.offset_left = -270; container.offset_top = 240
            container.offset_right = -10;  container.offset_bottom = 370
        end)
        pcall(function() container.self_modulate = Color(1, 1, 1, 0.92) end)

        local vbox = create_node("VBoxContainer", "")
        container.add_child(vbox)

        -- Header
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

        -- Status
        _status_label = create_node("Label", "")
        _status_label.text = string.format("Amount: $%d", config.money_amount or 10000)
        pcall(function() _status_label.add_theme_font_size_override("font_size", 11) end)
        vbox.add_child(_status_label)

        -- Add Money button
        local btn = create_node("Button", "")
        btn.text = "Add Money"
        btn.toggle_mode = true
        pcall(function() btn.custom_minimum_size = Vector2(0, 28) end)
        vbox.add_child(btn)
        _panel_btns.add = btn

        root.add_child(_panel)
        log("Panel built (standalone CanvasLayer at /root)")
    end)
    if not ok then log("build_panel ERROR: " .. tostring(err)) end
end

-- =========================================================================
-- Commands (ALL GLOBAL — GC safe)
-- =========================================================================

function money(amount)
    step("money", "begin")
    -- amount may be userdata (Array) when called via signal dispatch; coerce
    if type(amount) ~= "number" then amount = nil end
    local money_amount = amount or config.money_amount or 10000
    step("money", "amount = " .. tostring(money_amount))

    local ok, err = pcall(function()
        step("money", "getting game world...")
        local world = ModApiV1.get_game_world()
        if not world then step("money", "ERROR: no game world"); return end
        step("money", "calling modify_player_cash...")
        world.modify_player_cash(money_amount, "Money Cheat", 1)
        step("money", "modify_player_cash done")
    end)
    if not ok then step("money", "ERROR: " .. tostring(err)) end

    step("money", "added $" .. tostring(money_amount))
    if _status_label then
        pcall(function() _status_label.text = string.format("Last: +$%d", money_amount) end)
    end
    step("money", "end")
end

function m_money(amount) money(amount) end

function m_mc_panel()
    if not _panel then step("m_mc_panel", "panel not built yet"); return end
    _panel_visible = not _panel_visible
    pcall(function() _panel.visible = _panel_visible end)
    step("m_mc_panel", _panel_visible and "shown" or "hidden")
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    log("Money Cheat v3.0.0 loaded")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
    log(string.format("Config: Amount=$%d", config.money_amount or 10000))
    log("Console (~): m_money  m_mc_panel")
end

function on_game_state_ready()
    log("on_game_state_ready: begin")
    local world = ModApiV1.get_game_world()
    if not world then log("on_game_state_ready: no game world"); return end

    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if ok and dbg then
        pcall(function() dbg.enabled = true end)
        local cmds = {
            {"m_money",    m_money},
            {"m_mc_panel", m_mc_panel},
        }
        for _, cmd in ipairs(cmds) do
            pcall(function() dbg.register_cmd(cmd[1], cmd[2]) end)
        end
        log("on_game_state_ready: registered " .. #cmds .. " console commands")
    else
        log("on_game_state_ready: DebugLayer not found")
    end

    build_panel(world)
end

function on_mod_reload()
    log("Reloaded (F11)")
    destroy_panel()
    local world = ModApiV1 and ModApiV1.get_game_world()
    if world then build_panel(world) end
end

function on_tick(delta)
    -- Poll close button
    if _panel_close then
        pcall(function()
            if _panel_close.button_pressed then
                _panel_close.button_pressed = false
                _panel_visible = false
                _panel.visible = false
            end
        end)
    end
    -- Poll action buttons
    if _panel_btns.add then
        pcall(function()
            if _panel_btns.add.button_pressed then
                _panel_btns.add.button_pressed = false
                money()
            end
        end)
    end
end
