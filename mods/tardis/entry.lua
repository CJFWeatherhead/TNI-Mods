-- TARDIS Mod (Time And Relative Dimension In Space)
-- Purpose: Control game time via console commands
-- Author: CJFWeatherhead
-- Version: 1.2.0
-- Description: This mod provides console commands to control game speed and skip time.
--              Like the TARDIS, it manipulates time!
-- Usage: Open the debug console (~) and type a command name.
--
-- Console commands:
--   speed_up      Increase game speed
--   speed_down    Decrease game speed
--   speed_reset   Reset to normal speed (1x)
--   day_skip      Skip to end of day
--   speed         Show current speed

local mod_id = "tardis"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Speed control settings
    speed_step = 0.5,           -- Amount to change speed multiplier per keypress
    min_speed = 0.125,          -- Minimum game speed multiplier (game hard limit)
    max_speed = 8.0,            -- Maximum game speed multiplier (game hard limit)
    default_speed = 1.0,        -- Default game speed to reset to
    
    -- Day skip settings
    skip_to_time = 23.99,       -- Time to skip to (23.99 = 23:59:24)
    
    -- Notification settings
    show_notifications = true,  -- Show in-game notifications
    debug_logging = false       -- Show detailed console messages
}

-- ===== MOD CONFIGURATION END =====

-- Godot key codes (retained for reference)
local KEY_PERIOD = 46   -- '.' key
local KEY_COMMA = 44    -- ',' key
local KEY_EQUAL = 61    -- '=' key
local KEY_MINUS = 45    -- '-' key

-- Current speed multiplier tracking
local current_speed = 1.0

-- Helper function to display notification
local function show_notification(message, tone)
    if config.show_notifications then
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui and base_ui.display_notification then
                -- tone_enum: 0 = neutral, 1 = positive, 2 = negative
                base_ui.display_notification(message, tone or 0)
            end
        end)
    end
end

-- Helper function for debug logging
local function debug_log(message)
    if config.debug_logging then
        print("[tardis] " .. message)
    end
end

-- Helper function to get game world
local function get_world()
    if not ModApiV1 then
        return nil
    end
    return ModApiV1.get_game_world()
end

-- Increase game speed
local function increase_speed()
    local world = get_world()
    if not world then
        print("[tardis] ERROR: Could not get game world!")
        return
    end
    
    -- Get current time multiplier
    local current_mult = world.time_mult or current_speed
    local new_mult = current_mult + config.speed_step
    
    -- Clamp to max speed
    if new_mult > config.max_speed then
        new_mult = config.max_speed
    end
    
    -- Apply the new speed
    pcall(function()
        world.update_server_timescale(new_mult)
    end)
    
    -- Read back actual speed from game (may be clamped by game engine)
    pcall(function()
        if world.time_mult then
            current_speed = world.time_mult
        else
            current_speed = new_mult
        end
    end)
    
    local message = string.format("Speed: %.2fx", current_speed)
    print("[tardis] " .. message)
    show_notification(message, 1) -- positive tone
end

-- Decrease game speed
local function decrease_speed()
    local world = get_world()
    if not world then
        print("[tardis] ERROR: Could not get game world!")
        return
    end
    
    -- Get current time multiplier
    local current_mult = world.time_mult or current_speed
    local new_mult = current_mult - config.speed_step
    
    -- Clamp to min speed
    if new_mult < config.min_speed then
        new_mult = config.min_speed
    end
    
    -- Apply the new speed
    pcall(function()
        world.update_server_timescale(new_mult)
    end)
    
    -- Read back actual speed from game (may be clamped by game engine)
    pcall(function()
        if world.time_mult then
            current_speed = world.time_mult
        else
            current_speed = new_mult
        end
    end)
    
    local message = string.format("Speed: %.2fx", current_speed)
    print("[tardis] " .. message)
    show_notification(message, 0) -- neutral tone
end

-- Reset to normal speed
local function reset_speed()
    local world = get_world()
    if not world then
        print("[tardis] ERROR: Could not get game world!")
        return
    end
    
    local new_mult = config.default_speed
    
    -- Apply the new speed
    pcall(function()
        world.update_server_timescale(new_mult)
    end)
    
    -- Read back actual speed from game (may be clamped by game engine)
    pcall(function()
        if world.time_mult then
            current_speed = world.time_mult
        else
            current_speed = new_mult
        end
    end)
    
    local message = string.format("Speed: %.2fx (Reset)", current_speed)
    print("[tardis] " .. message)
    show_notification(message, 0) -- neutral tone
end

-- Skip to end of day
local function skip_day()
    local world = get_world()
    if not world then
        print("[tardis] ERROR: Could not get game world!")
        return
    end
    
    -- Try to access daycycle controller
    local daycycle = world.daycycle_controller
    if not daycycle then
        print("[tardis] ERROR: Could not access daycycle controller!")
        show_notification("Cannot skip time", 2) -- negative tone
        return
    end
    
    -- Get current day clock
    local current_clock = nil
    pcall(function()
        current_clock = daycycle.day_clock or daycycle.normal_clock
    end)
    
    debug_log(string.format("Current clock: %s", tostring(current_clock)))
    
    -- Skip to end of day (23:59 approximately)
    -- Day clock typically runs 0-1 where 1 is a full day
    -- So 23:59 would be approximately 0.9996 (23.99/24)
    local target_time = config.skip_to_time / 24.0
    
    local success = false
    pcall(function()
        -- Try force_day_clock first
        if daycycle.force_day_clock then
            daycycle.force_day_clock(target_time)
            success = true
        -- Fallback to force_normal_clock
        elseif daycycle.force_normal_clock then
            daycycle.force_normal_clock(target_time)
            success = true
        end
    end)
    
    if success then
        local message = string.format("Skipped to %02d:%02d", 
            math.floor(config.skip_to_time), 
            math.floor((config.skip_to_time % 1) * 60))
        print("[tardis] " .. message)
        show_notification(message, 1) -- positive tone
    else
        print("[tardis] WARNING: Time skip may not have worked")
        show_notification("Time skip attempted", 0) -- neutral tone
    end
end

function on_engine_load()
    print("TARDIS mod loaded! Time manipulation at your fingertips.")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        print("ModApiV1 is not available!")
    end
    
    -- Log current configuration
    print(string.format("[tardis] Config: Speed step=%.2f, Min=%.2f, Max=%.2f",
        config.speed_step,
        config.min_speed,
        config.max_speed))
    
    print("[tardis] Console: speed_up  speed_down  speed_reset  day_skip  speed")
    
    -- Initialize current speed from game if possible
    pcall(function()
        local world = get_world()
        if world and world.time_mult then
            current_speed = world.time_mult
        end
    end)
end

function on_mod_reload()
    print("Pressed the reload action key (F11), reloading TARDIS mod...")
    print(string.format("[tardis] Current speed: %.2fx", current_speed))
end

-- Console commands (exposed as globals for the game console)
function speed_up()    increase_speed() end
function speed_down()  decrease_speed() end
function speed_reset() reset_speed() end
function day_skip()    skip_day() end

function speed()
    print(string.format("[tardis] Current speed: %.2fx", current_speed))
end

-- Register commands with the debug console when game is fully loaded
function on_game_state_ready()
    local world = ModApiV1.get_game_world()
    if not world then return end

    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if not ok or not dbg then
        print("[tardis] DebugLayer not found, commands available as globals only")
        return
    end

    -- Enable the debug console (disabled by default in the game)
    pcall(function() dbg.enabled = true end)
    pcall(function() dbg.visible = true end)

    pcall(function() dbg.register_cmd("speed_up", speed_up) end)
    pcall(function() dbg.register_cmd("speed_down", speed_down) end)
    pcall(function() dbg.register_cmd("speed_reset", speed_reset) end)
    pcall(function() dbg.register_cmd("day_skip", day_skip) end)
    pcall(function() dbg.register_cmd("speed", speed) end)
    print("[tardis] Debug console enabled. Registered: speed_up speed_down speed_reset day_skip speed")
end
