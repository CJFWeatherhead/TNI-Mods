-- TARDIS Mod (Time And Relative Dimension In Space)
-- Purpose: Control game time via debug console commands and standalone UI panel
-- Author: CJFWeatherhead
-- Version: 3.0.0
-- Description: Preset-based speed control and time skip via debug console.
--              Own floating panel with toggle-mode buttons polled via on_tick.
--              Uses fixed presets (0.125x-8x) instead of arithmetic steps.
-- Usage: Press ~ to open the debug console, then type a command.
--        Type m_panel to toggle the TARDIS control panel.
--
-- Console commands:
--   m_faster     Step up to next speed preset
--   m_slower     Step down to previous speed preset
--   m_normal     Reset to default speed (1x)
--   m_skip       Skip to end of day
--   m_pause      Toggle day cycle pause/resume
--   m_resume     Alias for m_pause
--   m_time       Show current speed, day, time, and pause state
--   m_panel      Toggle the TARDIS floating panel
--
-- ARCHITECTURE NOTES:
--   All command functions are GLOBAL (pinned in _G, GC-safe).
--   Panel buttons use toggle_mode=true polled in on_tick — avoids the
--   sandbox callable bridge which crashes on signal dispatch.
--   Every Godot API call is wrapped in pcall with step-by-step logging.

local mod_id = "tardis"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Speed to reset to with m_normal (snapped to nearest preset)
    default_speed = 1.0,

    -- Time of day to skip to in 24h decimal format (23.99 ≈ 23:59)
    skip_to_time = 23.99,

    -- Automatically reset speed to default at the start of each new day
    auto_reset_on_day_start = false,

    -- Show detailed messages in the console for troubleshooting
    debug_logging = false
}

-- ===== MOD CONFIGURATION END =====

-- Speed presets (sorted ascending, matching game hard limits 0.125x-8x).
local SPEED_PRESETS = { 0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0 }

-- Internal state
local current_preset_idx = 4
local _panel             = nil    -- CanvasLayer ref
local _panel_visible     = false
local _panel_btns        = {}     -- button refs for on_tick polling
local _panel_close       = nil    -- close button ref
local _status_label      = nil    -- status label ref

-- =========================================================================
-- Utilities
-- =========================================================================

local function log(msg) print("[tardis] " .. msg) end

local function debug_log(msg)
    if config.debug_logging then log(msg) end
end

local function step(tag, msg)
    log(tag .. ": " .. msg)
end

local function find_nearest_preset(speed)
    local best_idx, best_diff = 1, math.abs(SPEED_PRESETS[1] - speed)
    for i = 2, #SPEED_PRESETS do
        local diff = math.abs(SPEED_PRESETS[i] - speed)
        if diff < best_diff then best_diff = diff; best_idx = i end
    end
    return best_idx
end

local function sync_from_game()
    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if world and world.time_mult then
            current_preset_idx = find_nearest_preset(world.time_mult)
        end
    end)
    if not ok then debug_log("sync_from_game error: " .. tostring(err)) end
end

local function get_status_text()
    local world = ModApiV1 and ModApiV1.get_game_world()
    if not world then return "No game world" end
    local parts = {}
    pcall(function() table.insert(parts, string.format("%.3fx", world.time_mult or 0)) end)
    pcall(function()
        if world.game_time_str then table.insert(parts, world.game_time_str) end
    end)
    pcall(function() table.insert(parts, "Day " .. tostring(world.n_days or "?")) end)
    pcall(function()
        local dc = world.daycycle_controller
        if dc and dc.paused then table.insert(parts, "PAUSED") end
    end)
    return #parts > 0 and table.concat(parts, " | ") or "..."
end

local function refresh_status()
    if _status_label then
        pcall(function() _status_label.text = get_status_text() end)
    end
end

-- =========================================================================
-- Panel (standalone — own CanvasLayer, parented to /root)
-- =========================================================================

local function destroy_panel()
    if _panel then
        pcall(function() _panel.queue_free() end)
    end
    _panel = nil
    _panel_visible = false
    _panel_btns = {}
    _panel_close = nil
    _status_label = nil
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
            container.offset_left = -270; container.offset_top = 10
            container.offset_right = -10; container.offset_bottom = 230
        end)
        pcall(function() container.self_modulate = Color(1, 1, 1, 0.92) end)

        local vbox = create_node("VBoxContainer", "")
        container.add_child(vbox)

        -- Header
        local header = create_node("HBoxContainer", "")
        vbox.add_child(header)
        local title = create_node("Label", "")
        title.text = "TARDIS"
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
        _status_label.text = get_status_text()
        pcall(function() _status_label.add_theme_font_size_override("font_size", 11) end)
        pcall(function() _status_label.autowrap_mode = 1 end)
        vbox.add_child(_status_label)

        -- Speed row
        local row1 = create_node("HBoxContainer", "")
        vbox.add_child(row1)
        local btn_slower = create_node("Button", "")
        btn_slower.text = "Slower"
        btn_slower.toggle_mode = true
        pcall(function() btn_slower.custom_minimum_size = Vector2(120, 28) end)
        row1.add_child(btn_slower)
        _panel_btns.slower = btn_slower

        local btn_faster = create_node("Button", "")
        btn_faster.text = "Faster"
        btn_faster.toggle_mode = true
        pcall(function() btn_faster.custom_minimum_size = Vector2(120, 28) end)
        row1.add_child(btn_faster)
        _panel_btns.faster = btn_faster

        -- Control row
        local row2 = create_node("HBoxContainer", "")
        vbox.add_child(row2)
        local btn_pause = create_node("Button", "")
        btn_pause.text = "Pause/Resume"
        btn_pause.toggle_mode = true
        pcall(function() btn_pause.custom_minimum_size = Vector2(120, 28) end)
        row2.add_child(btn_pause)
        _panel_btns.pause = btn_pause

        local btn_reset = create_node("Button", "")
        btn_reset.text = "Reset 1x"
        btn_reset.toggle_mode = true
        pcall(function() btn_reset.custom_minimum_size = Vector2(120, 28) end)
        row2.add_child(btn_reset)
        _panel_btns.reset = btn_reset

        -- Skip
        local btn_skip = create_node("Button", "")
        btn_skip.text = "Skip Day"
        btn_skip.toggle_mode = true
        pcall(function() btn_skip.custom_minimum_size = Vector2(0, 28) end)
        vbox.add_child(btn_skip)
        _panel_btns.skip = btn_skip

        root.add_child(_panel)
        log("Panel built (standalone CanvasLayer at /root)")
    end)
    if not ok then log("build_panel ERROR: " .. tostring(err)) end
end

-- =========================================================================
-- Command functions (ALL GLOBAL — GC safe for register_cmd)
-- =========================================================================

function m_faster()
    step("m_faster", "begin")
    local ok, err = pcall(function()
        sync_from_game()
        step("m_faster", "preset_idx=" .. tostring(current_preset_idx) .. "/" .. tostring(#SPEED_PRESETS))
        if current_preset_idx >= #SPEED_PRESETS then
            step("m_faster", "already at maximum " .. tostring(SPEED_PRESETS[#SPEED_PRESETS]) .. "x")
            return
        end
        current_preset_idx = current_preset_idx + 1
        local spd = SPEED_PRESETS[current_preset_idx]
        step("m_faster", "setting timescale to " .. tostring(spd))
        local world = ModApiV1.get_game_world()
        world.update_server_timescale(spd)
        step("m_faster", "timescale set OK")
    end)
    if not ok then step("m_faster", "ERROR: " .. tostring(err)) end
    step("m_faster", "speed is now " .. tostring(SPEED_PRESETS[current_preset_idx]) .. "x")
    refresh_status()
end

function m_slower()
    step("m_slower", "begin")
    local ok, err = pcall(function()
        sync_from_game()
        step("m_slower", "preset_idx=" .. tostring(current_preset_idx) .. "/" .. tostring(#SPEED_PRESETS))
        if current_preset_idx <= 1 then
            step("m_slower", "already at minimum " .. tostring(SPEED_PRESETS[1]) .. "x")
            return
        end
        current_preset_idx = current_preset_idx - 1
        local spd = SPEED_PRESETS[current_preset_idx]
        step("m_slower", "setting timescale to " .. tostring(spd))
        local world = ModApiV1.get_game_world()
        world.update_server_timescale(spd)
        step("m_slower", "timescale set OK")
    end)
    if not ok then step("m_slower", "ERROR: " .. tostring(err)) end
    step("m_slower", "speed is now " .. tostring(SPEED_PRESETS[current_preset_idx]) .. "x")
    refresh_status()
end

function m_normal()
    step("m_normal", "begin")
    local ok, err = pcall(function()
        current_preset_idx = find_nearest_preset(config.default_speed)
        local spd = SPEED_PRESETS[current_preset_idx]
        step("m_normal", "resetting to " .. tostring(spd) .. "x")
        local world = ModApiV1.get_game_world()
        world.update_server_timescale(spd)
        step("m_normal", "timescale set OK")
    end)
    if not ok then step("m_normal", "ERROR: " .. tostring(err)) end
    step("m_normal", "done")
    refresh_status()
end

function m_skip()
    step("m_skip", "begin")
    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if not world then step("m_skip", "no game world"); return end
        local dc = world.daycycle_controller
        if not dc then step("m_skip", "no daycycle controller"); return end
        local target = config.skip_to_time / 24.0
        step("m_skip", "target clock = " .. tostring(target))
        if dc.force_day_clock then
            dc.force_day_clock(target)
            step("m_skip", "force_day_clock OK")
        elseif dc.force_normal_clock then
            dc.force_normal_clock(target)
            step("m_skip", "force_normal_clock OK")
        else
            step("m_skip", "no skip method available")
        end
    end)
    if not ok then step("m_skip", "ERROR: " .. tostring(err)) end
    local h = math.floor(config.skip_to_time)
    local m = math.floor((config.skip_to_time - h) * 60)
    step("m_skip", string.format("done (target %02d:%02d)", h, m))
    refresh_status()
end

function m_pause()
    step("m_pause", "begin")
    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if not world then step("m_pause", "no game world"); return end
        local dc = world.daycycle_controller
        if not dc then step("m_pause", "no daycycle controller"); return end
        local is_paused = false
        pcall(function() is_paused = dc.paused or false end)
        step("m_pause", "currently paused = " .. tostring(is_paused))
        if is_paused then
            dc.resume_timer()
            step("m_pause", "resume_timer called — RESUMED")
        else
            dc.pause_timer()
            step("m_pause", "pause_timer called — PAUSED")
        end
    end)
    if not ok then step("m_pause", "ERROR: " .. tostring(err)) end
    step("m_pause", "done")
    refresh_status()
end

function m_resume() m_pause() end

function m_time()
    step("m_time", "begin")
    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if not world then step("m_time", "no game world"); return end
        step("m_time", "time_mult = " .. tostring(world.time_mult))
        step("m_time", "n_days    = " .. tostring(world.n_days))
        pcall(function() step("m_time", "game_time = " .. tostring(world.game_time_str)) end)
        pcall(function()
            local dc = world.daycycle_controller
            if dc then
                step("m_time", "day_clock = " .. tostring(dc.day_clock))
                step("m_time", "paused    = " .. tostring(dc.paused))
            end
        end)
    end)
    if not ok then step("m_time", "ERROR: " .. tostring(err)) end
    step("m_time", "done")
end

function m_panel()
    if not _panel then
        step("m_panel", "panel not built yet")
        return
    end
    _panel_visible = not _panel_visible
    pcall(function() _panel.visible = _panel_visible end)
    step("m_panel", _panel_visible and "shown" or "hidden")
    if _panel_visible then refresh_status() end
end

-- Aliases
function faster()       m_faster()  end
function slower()       m_slower()  end
function normal()       m_normal()  end
function skip()         m_skip()    end
function time_pause()   m_pause()   end
function time_status()  m_time()    end
function speed_up()     m_faster()  end
function speed_down()   m_slower()  end
function speed_reset()  m_normal()  end
function day_skip()     m_skip()    end
function speed()        m_time()    end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    log("TARDIS v3.0.0 loaded — time manipulation via debug console + panel")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
    log(string.format("Config: default=%.1fx  skip_to=%.2f  auto_reset=%s",
        config.default_speed, config.skip_to_time,
        tostring(config.auto_reset_on_day_start)))
    log("Console (~): m_faster m_slower m_normal m_skip m_pause m_resume m_time m_panel")
end

function on_game_state_ready()
    log("on_game_state_ready: begin")
    local world = ModApiV1.get_game_world()
    if not world then log("on_game_state_ready: no game world"); return end

    sync_from_game()
    log("on_game_state_ready: synced preset_idx=" .. tostring(current_preset_idx))

    -- Register console commands
    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if ok and dbg then
        pcall(function() dbg.enabled = true end)
        local cmds = {
            {"m_faster",  m_faster},  {"m_slower",  m_slower},
            {"m_normal",  m_normal},  {"m_skip",    m_skip},
            {"m_pause",   m_pause},   {"m_resume",  m_resume},
            {"m_time",    m_time},    {"m_panel",   m_panel},
        }
        for _, cmd in ipairs(cmds) do
            pcall(function() dbg.register_cmd(cmd[1], cmd[2]) end)
        end
        log("on_game_state_ready: registered " .. #cmds .. " console commands")
    else
        log("on_game_state_ready: DebugLayer not found")
    end

    -- Build standalone panel
    build_panel(world)
end

function on_mod_reload()
    log("Reloaded (F11)")
    destroy_panel()
    local world = ModApiV1 and ModApiV1.get_game_world()
    if world then build_panel(world) end
    m_time()
end

function on_day_start()
    debug_log("Day started")
    if config.auto_reset_on_day_start then m_normal() end
end

function on_day_end()
    debug_log("Day ended")
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
    pcall(function()
        local b = _panel_btns
        if b.slower and b.slower.button_pressed then b.slower.button_pressed = false; m_slower() end
        if b.faster and b.faster.button_pressed then b.faster.button_pressed = false; m_faster() end
        if b.pause  and b.pause.button_pressed  then b.pause.button_pressed  = false; m_pause()  end
        if b.reset  and b.reset.button_pressed  then b.reset.button_pressed  = false; m_normal() end
        if b.skip   and b.skip.button_pressed   then b.skip.button_pressed   = false; m_skip()   end
    end)
end
