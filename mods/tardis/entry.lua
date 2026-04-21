-- TARDIS Mod (Time And Relative Dimension In Space)
-- Purpose: Control game time via keyboard shortcuts
-- Author: CJFWeatherhead
-- Version: 4.0.0
-- Description: Preset-based speed control and time skip via keyboard.
--              Uses fixed presets (0.125x-8x) instead of arithmetic steps.
--              Lean on_player_input with single pcall and early returns.
--              No panels, no register_cmd, no signal connect.
--
-- Keyboard shortcuts:
--   SHIFT+PERIOD (>)   Step up to next speed preset (faster)
--   SHIFT+COMMA  (<)   Step down to previous speed preset (slower)
--   SHIFT+N            Reset to default speed (1x)
--   SHIFT+K            Skip to end of day
--   SHIFT+P            Toggle day cycle pause/resume
--   SHIFT+T            Show current speed/time in console
--
-- ARCHITECTURE:
--   on_player_input is a native lifecycle hook (not Callable dispatch).
--   One pcall wraps the entire handler. Early return on non-keyboard events.
--   Keycode checks are integer comparisons — no allocations, no GC pressure.

local mod_id = "tardis"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Speed to reset to with SHIFT+N (snapped to nearest preset)
    default_speed = 1.0,

    -- Time of day to skip to in 24h decimal format (23.99 = 23:59)
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

-- =========================================================================
-- Utilities
-- =========================================================================

local function log(msg) print("[tardis] " .. msg) end

local function find_nearest_preset(speed)
    local best_idx, best_diff = 1, math.abs(SPEED_PRESETS[1] - speed)
    for i = 2, #SPEED_PRESETS do
        local diff = math.abs(SPEED_PRESETS[i] - speed)
        if diff < best_diff then best_diff = diff; best_idx = i end
    end
    return best_idx
end

local function sync_from_game()
    local world = ModApiV1.get_game_world()
    if world and world.time_mult then
        current_preset_idx = find_nearest_preset(world.time_mult)
    end
end

-- =========================================================================
-- Commands
-- =========================================================================

local function cmd_faster()
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
end

local function cmd_slower()
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
end

local function cmd_normal()
    current_preset_idx = find_nearest_preset(config.default_speed)
    local spd = SPEED_PRESETS[current_preset_idx]
    local world = ModApiV1.get_game_world()
    if world then world.update_server_timescale(spd) end
    log(string.format("Speed: %.3fx (reset)", spd))
end

local function cmd_skip()
    local world = ModApiV1.get_game_world()
    if not world then log("No game world"); return end
    local dc = world.daycycle_controller
    if not dc then log("No daycycle controller"); return end
    local target = config.skip_to_time / 24.0
    if dc.force_day_clock then
        dc.force_day_clock(target)
    elseif dc.force_normal_clock then
        dc.force_normal_clock(target)
    else
        log("No skip method available"); return
    end
    local h = math.floor(config.skip_to_time)
    local m = math.floor((config.skip_to_time - h) * 60)
    log(string.format("Skipped to %02d:%02d", h, m))
end

local function cmd_pause()
    local world = ModApiV1.get_game_world()
    if not world then log("No game world"); return end
    local dc = world.daycycle_controller
    if not dc then log("No daycycle controller"); return end
    local is_paused = dc.paused or false
    if is_paused then
        dc.resume_timer()
        log("Day cycle RESUMED")
    else
        dc.pause_timer()
        log("Day cycle PAUSED")
    end
end

local function cmd_time()
    local world = ModApiV1.get_game_world()
    if not world then log("No game world"); return end
    log(string.format("Speed: %.3fx | Day: %d | Paused: %s",
        world.time_mult or 0,
        world.n_days or 0,
        tostring(world.daycycle_controller and world.daycycle_controller.paused or false)))
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    log("TARDIS v4.0.0 loaded (keyboard shortcuts)")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
    log(string.format("Config: default=%.1fx  skip_to=%.2f  auto_reset=%s",
        config.default_speed, config.skip_to_time,
        tostring(config.auto_reset_on_day_start)))
    log("Keys: SHIFT+> faster | SHIFT+< slower | SHIFT+N reset | SHIFT+K skip | SHIFT+P pause | SHIFT+T time")
end

function on_game_state_ready()
    sync_from_game()
    log("Ready (preset " .. tostring(current_preset_idx) .. " = " ..
        string.format("%.3fx", SPEED_PRESETS[current_preset_idx]) .. ")")
end

function on_mod_reload()
    log("Reloaded (F11)")
    sync_from_game()
    cmd_time()
end

function on_day_start()
    if config.auto_reset_on_day_start then cmd_normal() end
end

function on_day_end() end

-- =========================================================================
-- Input handler (single pcall, early returns, minimal overhead)
-- Keycodes: Period=46, Comma=44, N=78, K=75, P=80, T=84
-- =========================================================================

function on_player_input(event)
    pcall(function()
        if event:get_class() ~= "InputEventKey" then return end
        if not event:is_pressed() then return end
        if event:is_echo() then return end
        if not event:is_shift_pressed() then return end
        local key = event:get_keycode()
        if     key == 46 then cmd_faster()  -- SHIFT+.  (>)
        elseif key == 44 then cmd_slower()  -- SHIFT+,  (<)
        elseif key == 78 then cmd_normal()  -- SHIFT+N
        elseif key == 75 then cmd_skip()    -- SHIFT+K
        elseif key == 80 then cmd_pause()   -- SHIFT+P
        elseif key == 84 then cmd_time()    -- SHIFT+T
        end
    end)
end
