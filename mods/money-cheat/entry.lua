-- Money Cheat Mod
-- Purpose: Adds configurable amount of money via console command
-- Author: CJFWeatherhead
-- Version: 3.1.0
-- Description: Adds money via debug console or panel button.
--              Own floating panel with toggle-mode button polled via on_tick.
--
-- CRITICAL FIX (v3.1):
--   register_cmd wraps the Lua callback into a Godot Callable. When that
--   Callable returns, the bridge (_ZL15gd_callable_luam5Array) crashes.
--   v0.1.8 worked because it ran from on_player_input (a native lifecycle
--   hook), not from a Callable dispatch.
--
--   Solution: register_cmd callbacks ONLY set a pending-action flag.
--   The actual game-state-modifying work runs in on_tick (native lifecycle).
--   This avoids the broken Callable return path entirely.
--
-- Usage: Open the debug console (~) and type: m_money
--
-- Console commands:
--   m_money        Add configured amount of money (deferred to on_tick)
--   m_mc_panel     Toggle the Money Cheat panel (deferred to on_tick)
--
-- Also supports: SHIFT+M keyboard shortcut (via on_player_input, like v0.1.8)

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

-- Deferred action flags (set by register_cmd callbacks, consumed by on_tick)
local _pending_money   = false
local _pending_panel   = false

-- Keyboard shortcut state
local _shift_m_pressed = false

-- Tick counter for periodic button-state diagnostics
local _tick_count = 0

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
-- Actual logic (runs ONLY from on_tick / on_player_input — native context)
-- =========================================================================

local function do_money()
    step("do_money", ">>> begin (native lifecycle context)")
    local money_amount = config.money_amount or 10000
    step("do_money", "amount = " .. tostring(money_amount))

    local ok, err = pcall(function()
        step("do_money", "getting game world...")
        local world = ModApiV1.get_game_world()
        if not world then step("do_money", "ERROR: no game world"); return end
        step("do_money", "calling modify_player_cash...")
        world.modify_player_cash(money_amount, "Money Cheat", 1)
        step("do_money", "modify_player_cash returned OK")
    end)
    if not ok then step("do_money", "ERROR: " .. tostring(err)) end

    step("do_money", "added $" .. tostring(money_amount))
    if _status_label then
        pcall(function() _status_label.text = string.format("Last: +$%d", money_amount) end)
    end
    step("do_money", "<<< end")
end

local function do_toggle_panel()
    if not _panel then step("do_toggle_panel", "panel not built yet"); return end
    _panel_visible = not _panel_visible
    pcall(function() _panel.visible = _panel_visible end)
    step("do_toggle_panel", _panel_visible and "shown" or "hidden")
end

-- =========================================================================
-- Console command stubs (register_cmd callbacks — SET FLAG ONLY, NO WORK)
-- The Callable bridge crashes on return if we do real work here.
-- =========================================================================

function m_money()
    log("m_money: setting pending flag (will execute in on_tick)")
    _pending_money = true
    -- DO NOT call modify_player_cash or any Godot API here
end

function m_mc_panel()
    log("m_mc_panel: setting pending flag (will execute in on_tick)")
    _pending_panel = true
    -- DO NOT call any Godot API here
end

-- Legacy alias
function money(amount)
    if type(amount) == "number" then
        -- Direct call with custom amount — only safe from native context
        log("money(" .. tostring(amount) .. "): direct call, deferring")
    end
    _pending_money = true
end

-- =========================================================================
-- Keyboard shortcut (SHIFT+M) — same as working v0.1.8
-- on_player_input is a native lifecycle hook, not a Callable dispatch,
-- so modify_player_cash works safely here.
-- =========================================================================

function on_player_input(event)
    local keycode, is_pressed, is_shift
    pcall(function() keycode = event:get_keycode() end)
    pcall(function() is_pressed = event:is_pressed() end)
    pcall(function() is_shift = event:is_shift_pressed() end)

    -- Shift+M (keycode 77)
    if keycode == 77 and is_shift then
        if is_pressed and not _shift_m_pressed then
            _shift_m_pressed = true
            log("SHIFT+M pressed — adding money (native lifecycle context)")
            do_money()
        elseif not is_pressed then
            _shift_m_pressed = false
        end
    end
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    log("Money Cheat v3.1.0 loaded")
    log("FIX: register_cmd callbacks now deferred to on_tick")
    log("FIX: SHIFT+M shortcut restored (native lifecycle, like v0.1.8)")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
    log(string.format("Config: Amount=$%d", config.money_amount or 10000))
    log("Console (~): m_money  m_mc_panel  |  Keyboard: SHIFT+M")
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
        log("on_game_state_ready: registered " .. #cmds .. " commands (flag-only stubs)")
    else
        log("on_game_state_ready: DebugLayer not found")
    end

    build_panel(world)
end

function on_mod_reload()
    log("Reloaded (F11)")
    destroy_panel()
    _pending_money = false
    _pending_panel = false
    local world = ModApiV1 and ModApiV1.get_game_world()
    if world then build_panel(world) end
end

function on_tick(delta)
    _tick_count = _tick_count + 1

    -- 1. Execute deferred console commands (safe — native lifecycle context)
    if _pending_money then
        _pending_money = false
        log("on_tick: executing deferred m_money")
        do_money()
    end
    if _pending_panel then
        _pending_panel = false
        log("on_tick: executing deferred m_mc_panel")
        do_toggle_panel()
    end

    -- 2. Poll close button
    if _panel_close then
        local close_ok, close_err = pcall(function()
            if _panel_close.button_pressed then
                log("on_tick: close button pressed!")
                _panel_close.button_pressed = false
                _panel_visible = false
                _panel.visible = false
            end
        end)
        if not close_ok then log("on_tick: close poll error: " .. tostring(close_err)) end
    end

    -- 3. Poll Add Money button
    if _panel_btns.add then
        local btn_ok, btn_err = pcall(function()
            if _panel_btns.add.button_pressed then
                log("on_tick: Add Money button pressed!")
                _panel_btns.add.button_pressed = false
                do_money()
            end
        end)
        if not btn_ok then log("on_tick: btn poll error: " .. tostring(btn_err)) end
    end

    -- 4. Periodic diagnostics (every ~5 seconds at 60fps)
    if _tick_count % 300 == 0 and _panel_visible then
        local diag_ok = pcall(function()
            local btn = _panel_btns.add
            if btn then
                log(string.format("DIAG tick=%d btn_exists=true pressed=%s visible=%s disabled=%s",
                    _tick_count,
                    tostring(btn.button_pressed),
                    tostring(btn.visible),
                    tostring(btn.disabled)))
            end
        end)
        if not diag_ok then log("DIAG: failed to read button state") end
    end
end
