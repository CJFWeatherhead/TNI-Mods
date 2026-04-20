-- TARDIS Mod (Time And Relative Dimension In Space)
-- Purpose: Control game time via debug console commands and shared ModPanels UI
-- Author: CJFWeatherhead
-- Version: 2.3.0
-- Description: Preset-based speed control and time skip via debug console.
--              Registers a section in the shared ModPanels overlay (supa-mod-loader).
--              Uses fixed presets (0.125x-8x) instead of arithmetic steps.
-- Usage: Press ~ to open the debug console, then type a command.
--        Type m_panels to open the shared panel, or m_tardis to open it
--        directly to the TARDIS section.
--
-- Console commands:
--   m_faster     Step up to next speed preset
--   m_slower     Step down to previous speed preset
--   m_normal     Reset to default speed (1x)
--   m_skip       Skip to end of day
--   m_pause      Toggle day cycle pause/resume
--   m_time       Show current speed, day, time, and pause state
--   m_tardis     Open shared panel (alias for m_panels)
--
-- IMPORTANT: All functions connected to Godot APIs (register_cmd, button
-- signals) are GLOBAL.  Never call display_notification() synchronously
-- inside a command handler — it causes sandbox timeout cascades.

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
local status_label_ref   = nil    -- panel status label (if framework available)

-- =========================================================================
-- Utilities
-- =========================================================================

local function log(msg) print("[tardis] " .. msg) end

local function debug_log(msg)
    if config.debug_logging then log(msg) end
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
    pcall(function()
        local world = ModApiV1.get_game_world()
        if world and world.time_mult then
            current_preset_idx = find_nearest_preset(world.time_mult)
        end
    end)
end

local function get_status_text()
    local world = ModApiV1 and ModApiV1.get_game_world()
    if not world then return "No game world" end
    local parts = {}
    pcall(function() table.insert(parts, string.format("Speed: %.3fx", world.time_mult or 0)) end)
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
    if status_label_ref then
        pcall(function() status_label_ref.text = get_status_text() end)
    end
end

-- =========================================================================
-- Command functions (ALL GLOBAL — GC safe for register_cmd + signals)
-- =========================================================================

function m_faster()
    sync_from_game()
    if current_preset_idx >= #SPEED_PRESETS then
        log(string.format("Already at maximum (%.3fx)", SPEED_PRESETS[#SPEED_PRESETS]))
        return
    end
    current_preset_idx = current_preset_idx + 1
    local spd = SPEED_PRESETS[current_preset_idx]
    local world = ModApiV1.get_game_world()
    if world then world.update_server_timescale(spd) end
    log(string.format("Speed: %.3fx", spd))
    refresh_status()
end

function m_slower()
    sync_from_game()
    if current_preset_idx <= 1 then
        log(string.format("Already at minimum (%.3fx)", SPEED_PRESETS[1]))
        return
    end
    current_preset_idx = current_preset_idx - 1
    local spd = SPEED_PRESETS[current_preset_idx]
    local world = ModApiV1.get_game_world()
    if world then world.update_server_timescale(spd) end
    log(string.format("Speed: %.3fx", spd))
    refresh_status()
end

function m_normal()
    current_preset_idx = find_nearest_preset(config.default_speed)
    local spd = SPEED_PRESETS[current_preset_idx]
    local world = ModApiV1.get_game_world()
    if world then world.update_server_timescale(spd) end
    log(string.format("Speed: %.3fx (reset)", spd))
    refresh_status()
end

function m_skip()
    local world = ModApiV1.get_game_world()
    if not world then log("ERROR: Game world not available"); return end
    local dc = world.daycycle_controller
    if not dc then log("ERROR: Day cycle controller not available"); return end
    local target = config.skip_to_time / 24.0
    local ok = false
    pcall(function()
        if dc.force_day_clock then dc.force_day_clock(target); ok = true
        elseif dc.force_normal_clock then dc.force_normal_clock(target); ok = true
        end
    end)
    local h = math.floor(config.skip_to_time)
    local m = math.floor((config.skip_to_time - h) * 60)
    log(ok and string.format("Skipped to %02d:%02d", h, m) or "Time skip failed")
    refresh_status()
end

function m_pause()
    local world = ModApiV1.get_game_world()
    if not world then log("ERROR: Game world not available"); return end
    local dc = world.daycycle_controller
    if not dc then log("ERROR: Day cycle controller not available"); return end
    local is_paused = false
    pcall(function() is_paused = dc.paused or false end)
    pcall(function()
        if is_paused then dc.resume_timer() else dc.pause_timer() end
    end)
    log(is_paused and "Day cycle RESUMED" or "Day cycle PAUSED")
    refresh_status()
end

function m_time()
    local world = ModApiV1.get_game_world()
    if not world then log("ERROR: Game world not available"); return end
    pcall(function() log(string.format("Speed   : %.3fx", world.time_mult or 0)) end)
    pcall(function() log(string.format("Day     : %d", world.n_days or 0)) end)
    pcall(function()
        if world.game_time_str then log("Time    : " .. world.game_time_str) end
    end)
    pcall(function()
        local dc = world.daycycle_controller
        if dc then
            log(string.format("Clock   : %.4f", dc.day_clock or 0))
            log("Paused  : " .. tostring(dc.paused or false))
        end
    end)
end

function m_tardis()
    -- Open the shared panel (same as m_panels)
    if m_panels then m_panels() end
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
-- Panel section (registered with shared ModPanels framework)
-- =========================================================================

local function setup_panel(world)
    local ok, content = pcall(function()
        return world.get_node("/root/ModPanels/Panel/Layout/Scroll/Content")
    end)
    if not ok or not content then
        debug_log("ModPanels framework not available — console commands only")
        return
    end

    -- Remove old section if it exists (F11 reload)
    pcall(function()
        local old = content.find_child("mp_tardis", false, false)
        if old then old.queue_free() end
    end)

    local section = create_node("VBoxContainer", "")
    section.name = "mp_tardis"

    -- Section header
    local sep = create_node("HSeparator", "")
    section.add_child(sep)
    local title = create_node("Label", "")
    title.text = "TARDIS - Time Controller"
    pcall(function() title.add_theme_font_size_override("font_size", 14) end)
    section.add_child(title)

    -- Status
    status_label_ref = create_node("Label", "")
    status_label_ref.text = get_status_text()
    pcall(function() status_label_ref.add_theme_font_size_override("font_size", 11) end)
    pcall(function() status_label_ref.autowrap_mode = 1 end)
    section.add_child(status_label_ref)

    -- Speed row
    local row1 = create_node("HBoxContainer", "")
    section.add_child(row1)
    local btn_slower = create_node("Button", "")
    btn_slower.text = "Slower"
    pcall(function() btn_slower.custom_minimum_size = Vector2(110, 28) end)
    row1.add_child(btn_slower)
    btn_slower.connect("pressed", Mod.callable_args_to_array(m_slower))

    local btn_faster = create_node("Button", "")
    btn_faster.text = "Faster"
    pcall(function() btn_faster.custom_minimum_size = Vector2(110, 28) end)
    row1.add_child(btn_faster)
    btn_faster.connect("pressed", Mod.callable_args_to_array(m_faster))

    -- Control row
    local row2 = create_node("HBoxContainer", "")
    section.add_child(row2)
    local btn_pause = create_node("Button", "")
    btn_pause.text = "Pause"
    pcall(function() btn_pause.custom_minimum_size = Vector2(110, 28) end)
    row2.add_child(btn_pause)
    btn_pause.connect("pressed", Mod.callable_args_to_array(m_pause))

    local btn_reset = create_node("Button", "")
    btn_reset.text = "Reset"
    pcall(function() btn_reset.custom_minimum_size = Vector2(110, 28) end)
    row2.add_child(btn_reset)
    btn_reset.connect("pressed", Mod.callable_args_to_array(m_normal))

    -- Skip button (full width)
    local btn_skip = create_node("Button", "")
    btn_skip.text = "Skip Day"
    pcall(function() btn_skip.custom_minimum_size = Vector2(0, 28) end)
    section.add_child(btn_skip)
    btn_skip.connect("pressed", Mod.callable_args_to_array(m_skip))

    content.add_child(section)
    log("Panel section registered with ModPanels")
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    log("TARDIS mod loaded — time manipulation via debug console")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
    log(string.format("Config: default=%.1fx  skip_to=%.2f  auto_reset=%s",
        config.default_speed, config.skip_to_time,
        tostring(config.auto_reset_on_day_start)))
    log("Console (~): m_faster  m_slower  m_normal  m_skip  m_pause  m_time  m_panels")
end

function on_game_state_ready()
    local world = ModApiV1.get_game_world()
    if not world then return end

    sync_from_game()

    -- Register console commands
    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if ok and dbg then
        pcall(function() dbg.enabled = true end)
        pcall(function() dbg.register_cmd("m_faster",  m_faster)  end)
        pcall(function() dbg.register_cmd("m_slower",  m_slower)  end)
        pcall(function() dbg.register_cmd("m_normal",  m_normal)  end)
        pcall(function() dbg.register_cmd("m_skip",    m_skip)    end)
        pcall(function() dbg.register_cmd("m_pause",   m_pause)   end)
        pcall(function() dbg.register_cmd("m_time",    m_time)    end)
        pcall(function() dbg.register_cmd("m_tardis",  m_tardis)  end)
        log("Console commands registered")
    end

    -- Register panel section with shared framework
    setup_panel(world)
end

function on_mod_reload()
    log("Reloaded (F11)")
    status_label_ref = nil
    local world = ModApiV1 and ModApiV1.get_game_world()
    if world then setup_panel(world) end
    m_time()
end

function on_day_start()
    debug_log("Day started")
    if config.auto_reset_on_day_start then m_normal() end
end

function on_day_end()
    debug_log("Day ended")
end

function on_tick(delta) end
