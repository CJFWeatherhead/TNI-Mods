-- Chaos Engine Mod
-- Purpose: Introduces controlled chaos into Tower Networking Inc gameplay through
--          keyboard-triggered events and automatic stat randomization.
-- Author: CJFWeatherhead
-- Version: 0.1.0
-- Description: This mod provides keyboard shortcuts to trigger chaos events:
--              - SHIFT+F: Force spawn a random floor
--              - SHIFT+D: Toggle disaster mode (increased event rates)
--              - SHIFT+X: Reset all chaos settings to defaults
--              Additionally, user stats are randomized on spawn for varied gameplay.
-- Usage: Use keyboard shortcuts during gameplay. Configure features in Mod Manager.
-- Notes: Uses SHIFT combinations for easy access during gameplay.

local mod_id = "chaos-engine"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Feature toggles
    enable_random_floors = true,
    enable_disaster_mode = true,
    enable_user_randomization = true,

    -- Disaster mode settings
    disaster_event_multiplier = 5.0,  -- How much to multiply event rates in disaster mode

    -- User randomization settings (excludes daily_rate)
    user_satiety_sla_min = 0.3,
    user_satiety_sla_max = 0.9,
    user_eagerness_min = 1,
    user_eagerness_max = 10,
    user_use_period_min = 0.5,
    user_use_period_max = 2.0,
    user_grace_days_min = 1,
    user_grace_days_max = 7,
    user_max_satiety_decay_min = 0.1,
    user_max_satiety_decay_max = 0.5,

    -- UI settings
    show_notifications = true,
    debug_logging = true
}

-- ===== MOD CONFIGURATION END =====

-- State tracking
local world_ref = nil
local disaster_mode_active = false

-- Store original event rates for reset
local original_event_rates = {
    device_failure = nil,
    power_outage = nil,
    power_surge = nil,
    worm_spawn = nil
}

-- Key state tracking (for detecting key combinations)
local keys_pressed = {
    ctrl = false,
    shift = false
}

-- Cooldown tracking to prevent double-activation
local last_action_time = 0
local COOLDOWN_SECONDS = 0.5

-- Log function that respects debug setting
local function log(message)
    if config.debug_logging then
        print("[chaos-engine] " .. message)
    end
end

-- Log function for important messages (always shown)
local function log_important(message)
    print("[chaos-engine] " .. message)
end

-- Show in-game notification
local function notify(message, tone)
    if config.show_notifications then
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui and base_ui.display_notification then
                base_ui:display_notification(message, tone or 0)
            end
        end)
    end
    log_important(message)
end

-- Store original event rates on first load
local function store_original_rates()
    if not world_ref then return end

    local function store_rate(controller, key)
        if controller and original_event_rates[key] == nil then
            pcall(function()
                original_event_rates[key] = {
                    occurence_rate = controller.occurence_rate,
                    enabled = controller.enabled
                }
                log(string.format("Stored original %s rate: %.4f (enabled: %s)",
                    key, controller.occurence_rate, tostring(controller.enabled)))
            end)
        end
    end

    store_rate(world_ref.device_failure_controller, "device_failure")
    store_rate(world_ref.power_outage_controller, "power_outage")
    store_rate(world_ref.power_surge_controller, "power_surge")
    store_rate(world_ref.worm_spawn_controller, "worm_spawn")
end

-- Trigger random floor spawn
local function trigger_random_floor()
    if not world_ref then
        log("Cannot spawn floor: world_ref is nil")
        return false
    end

    local floor_builders = world_ref.floor_builders
    if not floor_builders then
        log("Cannot spawn floor: no floor_builders")
        return false
    end

    local success = false
    pcall(function()
        local size = floor_builders:size()
        if size > 0 then
            -- Pick a random floor builder
            local builder_idx = math.random(0, size - 1)
            local builder = floor_builders:get(builder_idx)
            if builder then
                builder:execute_random_build_option(true)  -- force_spawn = true
                success = true
                log(string.format("Triggered random floor from builder %d", builder_idx))
            end
        else
            log("No floor builders available")
        end
    end)

    return success
end

-- Toggle disaster mode
local function toggle_disaster_mode()
    if not world_ref then
        log("Cannot toggle disaster mode: world_ref is nil")
        return
    end

    -- Store original rates if not already stored
    store_original_rates()

    disaster_mode_active = not disaster_mode_active

    local multiplier = config.disaster_event_multiplier or 5.0

    local function set_event_rate(controller, key)
        if not controller then return end

        pcall(function()
            if disaster_mode_active then
                -- Increase rate and ensure enabled
                local base_rate = original_event_rates[key] and original_event_rates[key].occurence_rate or controller.occurence_rate
                controller.occurence_rate = math.min(base_rate * multiplier, 1.0)  -- Cap at 1.0
                controller.enabled = true
                log(string.format("  %s: rate -> %.4f (enabled)", key, controller.occurence_rate))
            else
                -- Restore original rate
                if original_event_rates[key] then
                    controller.occurence_rate = original_event_rates[key].occurence_rate
                    controller.enabled = original_event_rates[key].enabled
                    log(string.format("  %s: rate -> %.4f (enabled: %s)",
                        key, controller.occurence_rate, tostring(controller.enabled)))
                end
            end
        end)
    end

    log(string.format("Disaster mode: %s (multiplier: %.1fx)", disaster_mode_active and "ACTIVE" or "OFF", multiplier))
    set_event_rate(world_ref.device_failure_controller, "device_failure")
    set_event_rate(world_ref.power_outage_controller, "power_outage")
    set_event_rate(world_ref.power_surge_controller, "power_surge")
    set_event_rate(world_ref.worm_spawn_controller, "worm_spawn")

    return disaster_mode_active
end

-- Reset all chaos settings to defaults
local function reset_to_defaults()
    if not world_ref then
        log("Cannot reset: world_ref is nil")
        return
    end

    -- Disable disaster mode if active
    if disaster_mode_active then
        disaster_mode_active = false

        local function restore_rate(controller, key)
            if not controller then return end
            pcall(function()
                if original_event_rates[key] then
                    controller.occurence_rate = original_event_rates[key].occurence_rate
                    controller.enabled = original_event_rates[key].enabled
                    log(string.format("Restored %s to original: %.4f", key, controller.occurence_rate))
                end
            end)
        end

        restore_rate(world_ref.device_failure_controller, "device_failure")
        restore_rate(world_ref.power_outage_controller, "power_outage")
        restore_rate(world_ref.power_surge_controller, "power_surge")
        restore_rate(world_ref.worm_spawn_controller, "worm_spawn")
    end

    log("All chaos settings reset to defaults")
end

function on_engine_load()
    log_important("Chaos Engine mod loaded!")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        log_important("ModApiV1 is not available!")
        return
    end

    -- Get world reference
    world_ref = ModApiV1.get_game_world()

    -- Store original event rates
    if world_ref then
        store_original_rates()
    end

    -- Log configuration
    local features = {}
    if config.enable_random_floors then
        table.insert(features, "RandomFloors(SHIFT+F)")
    end
    if config.enable_disaster_mode then
        table.insert(features, string.format("DisasterMode(SHIFT+D, x%.1f)", config.disaster_event_multiplier))
    end
    if config.enable_user_randomization then
        table.insert(features, "UserRandomization")
    end

    if #features > 0 then
        log_important("Active features: " .. table.concat(features, ", "))
    else
        log_important("No features enabled")
    end

    log_important("Reset hotkey: SHIFT+X")
end

function on_mod_reload()
    log_important("Chaos Engine reloaded (F11)")
    world_ref = ModApiV1.get_game_world()

    -- Re-store original rates
    if world_ref then
        store_original_rates()
    end

    -- Reset disaster mode state
    disaster_mode_active = false
end

-- Keyboard input handler
function on_player_input(event)
    local event_class = nil
    pcall(function() event_class = event:get_class() end)

    if event_class ~= "InputEventKey" then
        return
    end

    local keycode = nil
    local is_pressed = false
    local is_shift = false

    pcall(function() keycode = event:get_keycode() end)
    pcall(function() is_pressed = event:is_pressed() end)
    pcall(function() is_shift = event:is_shift_pressed() end)

    -- We need SHIFT+<key> combinations
    if not is_shift then
        return
    end

    -- Check cooldown
    local current_time = os.clock()
    if current_time - last_action_time < COOLDOWN_SECONDS then
        return
    end

    -- Update world reference
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end

    -- SHIFT+F (70) - Random Floor
    if keycode == 70 and is_pressed and config.enable_random_floors then
        last_action_time = current_time
        if trigger_random_floor() then
            notify("Random floor spawned!", 1)  -- tone 1 = positive
        else
            notify("Could not spawn floor", 2)  -- tone 2 = negative
        end
        return
    end

    -- SHIFT+D (68) - Disaster Mode Toggle
    if keycode == 68 and is_pressed and config.enable_disaster_mode then
        last_action_time = current_time
        local is_active = toggle_disaster_mode()
        if is_active then
            notify("DISASTER MODE ACTIVATED!", 2)  -- tone 2 = negative/warning
        else
            notify("Disaster mode deactivated", 1)  -- tone 1 = positive
        end
        return
    end

    -- SHIFT+X (88) - Reset to Defaults
    if keycode == 88 and is_pressed then
        last_action_time = current_time
        reset_to_defaults()
        notify("Chaos settings reset", 0)  -- tone 0 = neutral
        return
    end
end

---@param user User
function on_user_spawned(user)
    if not config.enable_user_randomization then
        return
    end

    -- Update world reference if needed
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end

    local username = "Unknown"
    pcall(function() username = user.username end)

    local modifications = {}

    -- Randomize satiety_sla_ratio (how satisfied they need to be)
    pcall(function()
        local min_val = config.user_satiety_sla_min or 0.3
        local max_val = config.user_satiety_sla_max or 0.9
        local original = user.satiety_sla_ratio
        user.satiety_sla_ratio = min_val + math.random() * (max_val - min_val)
        table.insert(modifications, string.format("SLA: %.2f->%.2f", original, user.satiety_sla_ratio))
    end)

    -- Randomize eagerness_factor
    pcall(function()
        local min_val = config.user_eagerness_min or 1
        local max_val = config.user_eagerness_max or 10
        local original = user.eagerness_factor
        user.eagerness_factor = math.random(min_val, max_val)
        table.insert(modifications, string.format("eager: %d->%d", original, user.eagerness_factor))
    end)

    -- Randomize base_use_period (multiply original)
    pcall(function()
        local min_mult = config.user_use_period_min or 0.5
        local max_mult = config.user_use_period_max or 2.0
        local multiplier = min_mult + math.random() * (max_mult - min_mult)
        local original = user.base_use_period
        user.base_use_period = original * multiplier
        table.insert(modifications, string.format("period: %.1f->%.1f", original, user.base_use_period))
    end)

    -- Randomize init_grace_days
    pcall(function()
        local min_val = config.user_grace_days_min or 1
        local max_val = config.user_grace_days_max or 7
        local original = user.init_grace_days
        user.init_grace_days = math.random(min_val, max_val)
        table.insert(modifications, string.format("grace: %d->%d", original, user.init_grace_days))
    end)

    -- Randomize max_satiety_decay_ratio
    pcall(function()
        local min_val = config.user_max_satiety_decay_min or 0.1
        local max_val = config.user_max_satiety_decay_max or 0.5
        local original = user.max_satiety_decay_ratio
        user.max_satiety_decay_ratio = min_val + math.random() * (max_val - min_val)
        table.insert(modifications, string.format("decay: %.2f->%.2f", original, user.max_satiety_decay_ratio))
    end)

    if #modifications > 0 then
        log(string.format("User %s randomized: %s", username, table.concat(modifications, " | ")))
    end
end

function on_day_start()
    if disaster_mode_active then
        log("Day started - Disaster mode is ACTIVE")
    end
end

function on_day_end()
    log("Day ended")
end
