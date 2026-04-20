-- TARDIS Mod (Time And Relative Dimension In Space)
-- Purpose: Control game time via debug console commands and clickable UI panel
-- Author: CJFWeatherhead
-- Version: 2.1.0
-- Description: Preset-based speed control and time skip via debug console
--              and an optional floating UI panel with clickable buttons.
--              Uses fixed presets (0.125x-8x) instead of arithmetic steps
--              to avoid float drift and inconsistent speed changes.
-- Usage: Press ~ to open the debug console, then type a command.
--        Type m_panel to toggle the clickable UI overlay.
--
-- Console commands:
--   m_faster     Step up to next speed preset
--   m_slower     Step down to previous speed preset
--   m_normal     Reset to default speed (1x)
--   m_skip       Skip to end of day
--   m_pause      Toggle day cycle pause/resume
--   m_time       Show current speed, day, time, and pause state
--   m_panel      Toggle the clickable UI panel

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

    -- Display on-screen notifications for speed/time changes
    show_notifications = true,

    -- Show detailed messages in the console for troubleshooting
    debug_logging = false
}

-- ===== MOD CONFIGURATION END =====

-- Speed presets (sorted ascending, matching game hard limits 0.125x–8x).
-- Using fixed presets eliminates the float-drift problem that step-based
-- arithmetic (e.g. current + 0.5) caused in the previous implementation.
local SPEED_PRESETS = { 0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0 }

-- Internal state
local current_preset_idx = 4        -- index into SPEED_PRESETS (default 1.0x)
local dbg_layer          = nil      -- cached DebugLayer reference

-- UI panel state
local panel_overlay      = nil      -- CanvasLayer for the floating panel
local panel_status_label = nil      -- Label showing current speed/time
local panel_visible      = false    -- whether the panel is currently shown
local panel_callbacks     = {}      -- prevent GC of signal callback closures

-- =========================================================================
-- Utilities
-- =========================================================================

local function log(msg)
    print("[tardis] " .. msg)
end

local function debug_log(msg)
    if config.debug_logging then
        log(msg)
    end
end

local function notify(message, tone)
    if not config.show_notifications then return end
    pcall(function()
        local base_ui = ModApiV1.get_base_ui()
        if base_ui then
            base_ui.display_notification(message, tone or 0)
        end
    end)
end

local function get_world()
    if not ModApiV1 then return nil end
    return ModApiV1.get_game_world()
end

--- Return the preset index whose value is closest to `speed`.
local function find_nearest_preset(speed)
    local best_idx  = 1
    local best_diff = math.abs(SPEED_PRESETS[1] - speed)
    for i = 2, #SPEED_PRESETS do
        local diff = math.abs(SPEED_PRESETS[i] - speed)
        if diff < best_diff then
            best_diff = diff
            best_idx  = i
        end
    end
    return best_idx
end

--- Sync `current_preset_idx` from the live game timescale so the next
--- step up/down is always relative to the real engine value.
local function sync_preset_from_game(world)
    local ok = pcall(function()
        if world.time_mult then
            current_preset_idx = find_nearest_preset(world.time_mult)
        end
    end)
    if ok then
        debug_log(string.format("Synced preset index %d (%.3fx)",
            current_preset_idx, SPEED_PRESETS[current_preset_idx]))
    end
end

--- Apply a speed multiplier to the game engine.
--- Returns true on success.
local function apply_speed(multiplier)
    local world = get_world()
    if not world then
        log("ERROR: Game world not available")
        return false
    end
    local ok, err = pcall(function()
        world.update_server_timescale(multiplier)
    end)
    if not ok then
        log("ERROR: Failed to set timescale — " .. tostring(err))
        return false
    end
    debug_log(string.format("Applied timescale %.3fx", multiplier))
    return true
end

-- =========================================================================
-- UI Panel
-- =========================================================================

--- Build a simple status string for the panel label.
local function get_status_text()
    local world = get_world()
    if not world then return "No game world" end

    local parts = {}
    pcall(function()
        table.insert(parts, string.format("Speed: %.3fx", world.time_mult or 0))
    end)
    pcall(function()
        if world.game_time_str then
            table.insert(parts, "Time: " .. world.game_time_str)
        end
    end)
    pcall(function()
        table.insert(parts, "Day " .. tostring(world.n_days or "?"))
    end)
    pcall(function()
        local dc = world.daycycle_controller
        if dc and dc.paused then
            table.insert(parts, "[PAUSED]")
        end
    end)
    if #parts == 0 then return "..." end
    return table.concat(parts, "  |  ")
end

--- Refresh the panel status label (call after any command).
local function update_panel_status()
    if panel_status_label then
        pcall(function()
            panel_status_label.text = get_status_text()
        end)
    end
end

--- Destroy the panel and free all its nodes.
local function destroy_panel()
    if panel_overlay then
        pcall(function() panel_overlay.queue_free() end)
        panel_overlay      = nil
        panel_status_label = nil
        panel_visible      = false
        panel_callbacks    = {}   -- release pinned callbacks
        debug_log("Panel destroyed")
    end
end

--- Create a styled button and wire its pressed signal.
--- The callback is stored in panel_callbacks to prevent GC collection.
--- Returns the Button node (or nil on failure).
local function make_button(text, callback, parent)
    -- Pin callback so Lua GC won't collect the closure while Godot
    -- holds a signal reference the GC can't see.
    table.insert(panel_callbacks, callback)

    local ok, btn = pcall(function()
        local b = create_node("Button", "")
        b.text = text
        pcall(function() b.add_theme_font_size_override("font_size", 13) end)
        pcall(function() b.custom_minimum_size = Vector2(90, 28) end)
        parent.add_child(b)
        b.connect("pressed", callback)
        return b
    end)
    if ok then return btn end
    log("WARNING: Failed to create button '" .. text .. "'")
    return nil
end

--- Build the floating UI panel.
--- Layout:
---   CanvasLayer (layer 100)
---     PanelContainer  (anchored top-right, offset inward)
---       VBoxContainer
---         HBoxContainer  [header: title label + close button]
---         Label          [status: speed / time / day / paused]
---         HBoxContainer  [row 1: Slower  Faster]
---         HBoxContainer  [row 2: Pause   Reset]
---         Button         [Skip Day — full width]
local function build_panel()
    -- Tear down any existing panel first
    destroy_panel()

    local ok, err = pcall(function()
        -- Root overlay — high layer so it renders on top of the game
        panel_overlay = create_node("CanvasLayer", "")
        panel_overlay.layer = 100

        -- Panel container — this gets the theme background
        local panel_ctn = create_node("PanelContainer", "")
        panel_overlay.add_child(panel_ctn)

        -- Position: top-right corner with some margin
        -- anchor top-right (1,0)–(1,0), then offset left/down
        pcall(function()
            panel_ctn.anchor_left   = 1.0
            panel_ctn.anchor_top    = 0.0
            panel_ctn.anchor_right  = 1.0
            panel_ctn.anchor_bottom = 0.0
        end)
        pcall(function()
            panel_ctn.offset_left   = -260
            panel_ctn.offset_top    = 10
            panel_ctn.offset_right  = -10
            panel_ctn.offset_bottom = 200
        end)

        -- Semi-transparent background via a ColorRect behind content
        -- (PanelContainer itself uses the theme StyleBox; this is a fallback)
        pcall(function()
            panel_ctn.self_modulate = Color(1, 1, 1, 0.92)
        end)

        -- Main vertical layout
        local vbox = create_node("VBoxContainer", "")
        panel_ctn.add_child(vbox)

        -- ── Header row ──────────────────────────────────────────────
        local header = create_node("HBoxContainer", "")
        vbox.add_child(header)

        local title = create_node("Label", "")
        title.text = "TARDIS"
        pcall(function() title.add_theme_font_size_override("font_size", 15) end)
        pcall(function()
            title.size_flags_horizontal = 3   -- SIZE_EXPAND_FILL
        end)
        header.add_child(title)

        local close_btn = create_node("Button", "")
        close_btn.text = "X"
        close_btn.flat = true
        pcall(function() close_btn.custom_minimum_size = Vector2(28, 28) end)
        header.add_child(close_btn)

        -- ── Status label ────────────────────────────────────────────
        panel_status_label = create_node("Label", "")
        panel_status_label.text = get_status_text()
        pcall(function() panel_status_label.add_theme_font_size_override("font_size", 12) end)
        pcall(function()
            panel_status_label.autowrap_mode = 1  -- AUTOWRAP_WORD
        end)
        vbox.add_child(panel_status_label)

        -- ── Speed row ───────────────────────────────────────────────
        local speed_row = create_node("HBoxContainer", "")
        vbox.add_child(speed_row)

        -- Forward-declare cmd_* wrappers (the actual locals are defined
        -- further down in the file, but we need closures here).  We
        -- wrap through the global aliases which are always available.
        -- Note: update_panel_status() is already called inside each cmd_*
        -- function, so we don't need to call it again here.
        make_button("Slower",   function() slower()     end, speed_row)
        make_button("Faster",   function() faster()     end, speed_row)

        -- ── Control row ─────────────────────────────────────────────
        local ctrl_row = create_node("HBoxContainer", "")
        vbox.add_child(ctrl_row)

        make_button("Pause",    function() time_pause() end, ctrl_row)
        make_button("Reset",    function() normal()     end, ctrl_row)

        -- ── Skip button (full width) ────────────────────────────────
        make_button("Skip Day", function() skip()       end, vbox)

        -- ── Wire close button ───────────────────────────────────────
        local close_cb = function()
            if panel_overlay then
                panel_overlay.visible = false
                panel_visible = false
                log("Panel hidden (click X to close, m_panel to reopen)")
            end
        end
        table.insert(panel_callbacks, close_cb)
        close_btn.connect("pressed", close_cb)

        -- Attach the overlay to the mod's own node so it lives in the
        -- scene tree and gets cleaned up automatically with the mod.
        Mod.add_child(panel_overlay)
        panel_visible = true
    end)

    if not ok then
        log("WARNING: Failed to build UI panel — " .. tostring(err))
        destroy_panel()
        return false
    end

    debug_log("Panel built successfully")
    return true
end

--- Toggle the panel on/off.
local function cmd_panel()
    -- If the panel exists, toggle visibility
    if panel_overlay then
        local new_vis = not panel_visible
        pcall(function() panel_overlay.visible = new_vis end)
        panel_visible = new_vis
        if new_vis then update_panel_status() end
        log(new_vis and "Panel shown" or "Panel hidden")
        return
    end

    -- First time — try to build it
    if build_panel() then
        log("Panel opened (type m_panel to toggle, or click X to close)")
    else
        log("Panel could not be created — UI node creation may not be "
            .. "supported in this game version. Console commands still work.")
    end
end

-- =========================================================================
-- Commands
-- =========================================================================

--- Step up to the next speed preset.
local function cmd_faster()
    local world = get_world()
    if not world then log("ERROR: Game world not available") return end

    sync_preset_from_game(world)

    if current_preset_idx >= #SPEED_PRESETS then
        local msg = string.format("Already at maximum (%.3fx)", SPEED_PRESETS[#SPEED_PRESETS])
        log(msg)
        notify(msg, 2)
        return
    end

    current_preset_idx = current_preset_idx + 1
    local new_speed = SPEED_PRESETS[current_preset_idx]
    if apply_speed(new_speed) then
        local msg = string.format("Speed: %.3fx", new_speed)
        log(msg)
        notify(msg, 1)
        update_panel_status()
    end
end

--- Step down to the previous speed preset.
local function cmd_slower()
    local world = get_world()
    if not world then log("ERROR: Game world not available") return end

    sync_preset_from_game(world)

    if current_preset_idx <= 1 then
        local msg = string.format("Already at minimum (%.3fx)", SPEED_PRESETS[1])
        log(msg)
        notify(msg, 2)
        return
    end

    current_preset_idx = current_preset_idx - 1
    local new_speed = SPEED_PRESETS[current_preset_idx]
    if apply_speed(new_speed) then
        local msg = string.format("Speed: %.3fx", new_speed)
        log(msg)
        notify(msg, 0)
        update_panel_status()
    end
end

--- Reset speed to the configured default.
local function cmd_normal()
    current_preset_idx = find_nearest_preset(config.default_speed)
    local preset_speed = SPEED_PRESETS[current_preset_idx]
    if apply_speed(preset_speed) then
        local msg = string.format("Speed: %.3fx (reset)", preset_speed)
        log(msg)
        notify(msg, 0)
        update_panel_status()
    end
end

--- Skip to configured time of day.
local function cmd_skip()
    local world = get_world()
    if not world then log("ERROR: Game world not available") return end

    local daycycle = world.daycycle_controller
    if not daycycle then
        log("ERROR: Day cycle controller not available")
        notify("Cannot skip time", 2)
        return
    end

    -- day_clock is 0–1 where 1 = full day, so 23.99/24 ≈ end of day
    local target_clock = config.skip_to_time / 24.0
    local success = false

    local ok, err = pcall(function()
        if daycycle.force_day_clock then
            daycycle.force_day_clock(target_clock)
            success = true
        elseif daycycle.force_normal_clock then
            daycycle.force_normal_clock(target_clock)
            success = true
        end
    end)

    if success then
        local hours   = math.floor(config.skip_to_time)
        local minutes = math.floor((config.skip_to_time - hours) * 60)
        local msg = string.format("Skipped to %02d:%02d", hours, minutes)
        log(msg)
        notify(msg, 1)
    else
        log("WARNING: Time skip failed" .. (err and (" — " .. tostring(err)) or ""))
        notify("Time skip failed", 2)
    end
    update_panel_status()
end

--- Toggle day-cycle pause / resume.
local function cmd_pause()
    local world = get_world()
    if not world then log("ERROR: Game world not available") return end

    local daycycle = world.daycycle_controller
    if not daycycle then
        log("ERROR: Day cycle controller not available")
        notify("Cannot pause time", 2)
        return
    end

    -- Read live pause state from the engine rather than tracking internally
    local is_paused = false
    pcall(function() is_paused = daycycle.paused or false end)

    local ok, err = pcall(function()
        if is_paused then
            daycycle.resume_timer()
        else
            daycycle.pause_timer()
        end
    end)

    if ok then
        local now_paused = not is_paused
        local msg = now_paused and "Day cycle PAUSED" or "Day cycle RESUMED"
        log(msg)
        notify(msg, now_paused and 2 or 1)
    else
        log("ERROR: Pause toggle failed — " .. tostring(err))
    end
    update_panel_status()
end

--- Print current time / speed status to the console (and debug console).
local function cmd_time()
    local world = get_world()
    if not world then log("ERROR: Game world not available") return end

    local lines = {}

    pcall(function()
        table.insert(lines, string.format("Speed   : %.3fx", world.time_mult or 0))
    end)
    pcall(function()
        table.insert(lines, string.format("Day     : %d", world.n_days or 0))
    end)
    pcall(function()
        if world.game_time_str then
            table.insert(lines, "Time    : " .. world.game_time_str)
        end
    end)
    pcall(function()
        local dc = world.daycycle_controller
        if dc then
            table.insert(lines, string.format("Clock   : %.4f", dc.day_clock or 0))
            table.insert(lines, "Paused  : " .. tostring(dc.paused or false))
        end
    end)

    if #lines == 0 then
        log("Could not read time/speed state")
        return
    end

    for _, line in ipairs(lines) do
        log(line)
    end

    -- Mirror to debug console overlay
    if dbg_layer then
        pcall(function()
            for _, line in ipairs(lines) do
                dbg_layer.print_console("[tardis] " .. line)
            end
        end)
    end
end

-- =========================================================================
-- Lifecycle hooks
-- =========================================================================

function on_engine_load()
    log("TARDIS mod loaded — time manipulation via debug console")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        log("WARNING: ModApiV1 not available")
    end

    log(string.format("Config: default=%.1fx  skip_to=%.2f  auto_reset=%s",
        config.default_speed,
        config.skip_to_time,
        tostring(config.auto_reset_on_day_start)))
    log("Console (~): m_faster  m_slower  m_normal  m_skip  m_pause  m_time  m_panel")
end

function on_game_state_ready()
    local world = ModApiV1.get_game_world()
    if not world then
        log("WARNING: Game world not available in on_game_state_ready")
        return
    end

    -- Sync internal preset index from the live engine timescale
    sync_preset_from_game(world)

    -- Obtain DebugLayer and register console commands
    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if not ok or not dbg then
        log("WARNING: DebugLayer not found — commands available as globals only")
        return
    end

    dbg_layer = dbg
    pcall(function() dbg.enabled = true end)
    pcall(function() dbg.visible = true end)

    local cmds = {
        { "m_faster",  cmd_faster  },
        { "m_slower",  cmd_slower  },
        { "m_normal",  cmd_normal  },
        { "m_skip",    cmd_skip    },
        { "m_pause",   cmd_pause   },
        { "m_time",    cmd_time    },
        { "m_panel",   cmd_panel   },
    }

    local registered = {}
    for _, cmd in ipairs(cmds) do
        local r_ok = pcall(function() dbg.register_cmd(cmd[1], cmd[2]) end)
        if r_ok then table.insert(registered, cmd[1]) end
    end

    log("Debug console enabled. Registered: " .. table.concat(registered, "  "))
end

function on_mod_reload()
    log("Reloaded (F11)")
    destroy_panel()  -- clean up UI nodes before reload recreates them
    cmd_time()
end

function on_day_start()
    debug_log("Day started")
    if config.auto_reset_on_day_start then
        cmd_normal()
        debug_log("Auto-reset speed to default")
    end
end

function on_day_end()
    debug_log("Day ended")
end

-- =========================================================================
-- Global aliases (fallback for direct Lua console calls)
-- =========================================================================

-- New short names
function faster()       cmd_faster() end
function slower()       cmd_slower() end
function normal()       cmd_normal() end
function skip()         cmd_skip()   end
function time_pause()   cmd_pause()  end
function time_status()  cmd_time()   end
function panel()        cmd_panel()  end

-- Legacy aliases (v1 compatibility)
function speed_up()     cmd_faster() end
function speed_down()   cmd_slower() end
function speed_reset()  cmd_normal() end
function day_skip()     cmd_skip()   end
function speed()        cmd_time()   end
