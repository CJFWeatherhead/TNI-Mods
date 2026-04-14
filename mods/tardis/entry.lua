-- TARDIS Mod (Time And Relative Dimension In Space)
-- Purpose: Control game time via keyboard shortcuts
-- Author: CJFWeatherhead
-- Version: 0.1.0
-- Description: This mod provides keyboard shortcuts to control game speed and skip time.
--              SHIFT+> increases game speed, SHIFT+< decreases game speed,
--              SHIFT++ skips to end of day. Like the TARDIS, it manipulates time!
-- Usage: Use keyboard shortcuts during gameplay to control time.
-- Notes: Uses on_player_input hook to detect keyboard input.

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

-- Godot key codes
local KEY_PERIOD = 46   -- '.' key (Shift+. = '>')
local KEY_COMMA = 44    -- ',' key (Shift+, = '<')
local KEY_EQUAL = 61    -- '=' key (Shift+= = '+')
local KEY_MINUS = 45    -- '-' key (Shift+- = '_')

-- Track key states to prevent repeated triggers
local key_states = {
    speed_up = false,
    speed_down = false,
    skip_day = false,
    reset_speed = false
}

-- Cooldown tracking
local last_action_time = 0
local COOLDOWN_SECONDS = 0.1

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
    
    print("[tardis] Controls:")
    print("[tardis]   SHIFT+> : Increase game speed")
    print("[tardis]   SHIFT+< : Decrease game speed")
    print("[tardis]   SHIFT+_ : Reset to normal speed (1x)")
    print("[tardis]   SHIFT++ : Skip to end of day")
    
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

-- Keyboard input handler
function on_player_input(event)
    -- Check if this is a keyboard event
    local event_class = nil
    pcall(function() event_class = event:get_class() end)
    
    if event_class ~= "InputEventKey" then
        return
    end
    
    -- Get keycode and modifiers
    local keycode = nil
    local is_pressed = false
    local is_shift = false
    
    pcall(function() keycode = event:get_keycode() end)
    pcall(function() is_pressed = event:is_pressed() end)
    pcall(function() is_shift = event:is_shift_pressed() end)
    
    -- Only process if Shift is held
    if not is_shift then
        return
    end
    
    -- Check cooldown
    local current_time = os.clock()
    local cooldown_active = (current_time - last_action_time) < COOLDOWN_SECONDS
    
    -- SHIFT+> (SHIFT+PERIOD) - Increase speed
    if keycode == KEY_PERIOD then
        if is_pressed and not key_states.speed_up then
            key_states.speed_up = true
            if not cooldown_active then
                last_action_time = current_time
                increase_speed()
            else
                debug_log("Cooldown active for speed up")
            end
        elseif not is_pressed then
            key_states.speed_up = false
        end
    end
    
    -- SHIFT+< (SHIFT+COMMA) - Decrease speed
    if keycode == KEY_COMMA then
        if is_pressed and not key_states.speed_down then
            key_states.speed_down = true
            if not cooldown_active then
                last_action_time = current_time
                decrease_speed()
            else
                debug_log("Cooldown active for speed down")
            end
        elseif not is_pressed then
            key_states.speed_down = false
        end
    end
    
    -- SHIFT+_ (SHIFT+MINUS) - Reset speed
    if keycode == KEY_MINUS then
        if is_pressed and not key_states.reset_speed then
            key_states.reset_speed = true
            if not cooldown_active then
                last_action_time = current_time
                reset_speed()
            else
                debug_log("Cooldown active for reset speed")
            end
        elseif not is_pressed then
            key_states.reset_speed = false
        end
    end
    
    -- SHIFT++ (SHIFT+EQUAL) - Skip day
    if keycode == KEY_EQUAL then
        if is_pressed and not key_states.skip_day then
            key_states.skip_day = true
            if not cooldown_active then
                last_action_time = current_time
                skip_day()
            else
                debug_log("Cooldown active for day skip")
            end
        elseif not is_pressed then
            key_states.skip_day = false
        end
    end
end
