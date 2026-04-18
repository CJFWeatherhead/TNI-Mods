-- Chaos Engine Mod
-- Purpose: Introduces controlled chaos into Tower Networking Inc gameplay through
--          console commands and automatic stat randomization.
-- Author: CJFWeatherhead
-- Version: 1.2.0
-- Description: This mod provides console commands to trigger chaos events:
--              - random_floor: Force spawn a random floor
--              - disaster: Toggle disaster mode (increased event rates)
--              - chaos_reset: Reset all chaos settings to defaults
--              Additionally, user stats are randomized on spawn for varied gameplay.
-- Usage: Open the debug console (~) and type a command name.

local mod_id = "chaos-engine"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Feature toggles
    enable_random_floors = true,
    enable_disaster_mode = true,
    enable_initial_floor_randomization = false,

    -- Disaster mode settings
    disaster_event_multiplier = 5.0,  -- How much to multiply event rates in disaster mode

    -- User randomization toggles (individual control)
    enable_satiety_sla_randomization = true,
    enable_eagerness_randomization = true,
    enable_use_period_randomization = true,
    enable_grace_days_randomization = true,
    enable_satiety_decay_randomization = true,

    -- User randomization settings
    -- Satiety SLA: minimum satisfaction % required (0-100% scale, stored as 0.0-1.0)
    user_satiety_sla_min = 0.3,   -- 30% minimum satisfaction threshold
    user_satiety_sla_max = 0.9,   -- 90% maximum satisfaction threshold

    -- Eagerness: how quickly users demand service (higher = more impatient)
    user_eagerness_min = 1,
    user_eagerness_max = 10,

    -- Use Period Multiplier: scales time between service requests
    -- Values >1.0 = longer waits = LESS frequent usage
    -- Values <1.0 = shorter waits = MORE frequent usage
    user_use_period_min = 0.5,    -- 0.5x = half the wait time = 2x more frequent
    user_use_period_max = 2.0,    -- 2.0x = double the wait time = half as frequent

    -- Grace Days: initial forgiveness period before SLA penalties apply
    user_grace_days_min = 1,
    user_grace_days_max = 7,

    -- Satiety Decay: % satisfaction lost per game tick when not served
    user_max_satiety_decay_min = 0.1,   -- 10% per tick minimum
    user_max_satiety_decay_max = 0.5,   -- 50% per tick maximum

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
                -- Use dot notation (function call), not colon (method call)
                base_ui.display_notification(message, tone or 0)
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
    local method_used = "none"

    -- Method 1: Try to get spawn_paths from floor builders and use add_location directly
    pcall(function()
        local size = floor_builders:size()
        log(string.format("Found %d floor builders", size))
        
        -- Collect all available spawn paths from all builders
        local all_spawn_paths = {}
        for i = 0, size - 1 do
            local builder = floor_builders:get(i)
            if builder then
                local disabled = builder.disabled
                log(string.format("Builder %d: disabled=%s", i, tostring(disabled)))
                
                -- Get spawn_paths from this builder
                local paths = builder.spawn_paths
                if paths then
                    local path_size = paths:size()
                    log(string.format("Builder %d has %d spawn paths", i, path_size))
                    for j = 0, path_size - 1 do
                        local path = paths:get(j)
                        if path then
                            table.insert(all_spawn_paths, path)
                            log(string.format("  Path %d: %s", j, tostring(path)))
                        end
                    end
                end
            end
        end
        
        -- If we found spawn paths, pick a random one and use add_location
        if #all_spawn_paths > 0 then
            local random_path = all_spawn_paths[math.random(1, #all_spawn_paths)]
            log(string.format("Attempting add_location with path: %s", tostring(random_path)))
            world_ref.add_location(random_path)
            success = true
            method_used = "add_location"
        end
    end)

    if success then
        log(string.format("Floor spawned using %s", method_used))
        return true
    end

    -- Method 2: Try execute_random_build_option on a non-disabled builder
    pcall(function()
        local size = floor_builders:size()
        for i = 0, size - 1 do
            local builder = floor_builders:get(i)
            if builder and not builder.disabled then
                log(string.format("Trying execute_random_build_option on builder %d", i))
                builder.execute_random_build_option(true)  -- force_spawn = true
                success = true
                method_used = "execute_random_build_option"
                break
            end
        end
    end)

    if success then
        log(string.format("Floor spawned using %s", method_used))
        return true
    end

    log("All floor spawn methods failed")
    return false
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
    if config.enable_initial_floor_randomization then
        table.insert(features, "InitialFloorRandom")
    end
    if config.enable_disaster_mode then
        table.insert(features, string.format("DisasterMode(SHIFT+D, x%.1f)", config.disaster_event_multiplier))
    end
    -- Count enabled user randomization features
    local user_rand_count = 0
    if config.enable_satiety_sla_randomization then user_rand_count = user_rand_count + 1 end
    if config.enable_eagerness_randomization then user_rand_count = user_rand_count + 1 end
    if config.enable_use_period_randomization then user_rand_count = user_rand_count + 1 end
    if config.enable_grace_days_randomization then user_rand_count = user_rand_count + 1 end
    if config.enable_satiety_decay_randomization then user_rand_count = user_rand_count + 1 end
    if user_rand_count > 0 then
        table.insert(features, string.format("UserRandomization(%d/5)", user_rand_count))
    end

    if #features > 0 then
        log_important("Active features: " .. table.concat(features, ", "))
    else
        log_important("No features enabled")
    end

    log_important("Console: random_floor  disaster  chaos_reset")

    -- Randomize initial floors if enabled
    if config.enable_initial_floor_randomization and world_ref then
        log_important("Attempting to randomize initial floors...")
        -- Spawn 3 random floors to replace the initial ones
        for i = 1, 3 do
            if trigger_random_floor() then
                log(string.format("Randomized initial floor %d/3", i))
            else
                log(string.format("Failed to randomize initial floor %d/3", i))
            end
        end
    end
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

-- Console commands (exposed as globals for the game console)
function random_floor()
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end
    if trigger_random_floor() then
        notify("Random floor spawned!", 1)
    else
        notify("Could not spawn floor", 2)
    end
end

function disaster()
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end
    local is_active = toggle_disaster_mode()
    if is_active then
        notify("DISASTER MODE ACTIVATED!", 2)
    else
        notify("Disaster mode deactivated", 1)
    end
end

function chaos_reset()
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end
    reset_to_defaults()
    notify("Chaos settings reset", 0)
end

-- Register commands with the debug console when game is fully loaded
function on_game_state_ready()
    local world = ModApiV1.get_game_world()
    if not world then return end
    world_ref = world

    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if not ok or not dbg then
        log_important("DebugLayer not found, commands available as globals only")
        return
    end

    -- Enable the debug console (disabled by default in the game)
    pcall(function() dbg.enabled = true end)
    pcall(function() dbg.visible = true end)

    pcall(function() dbg.register_cmd("random_floor", random_floor) end)
    pcall(function() dbg.register_cmd("disaster", disaster) end)
    pcall(function() dbg.register_cmd("chaos_reset", chaos_reset) end)
    log_important("Debug console enabled. Registered: random_floor disaster chaos_reset")
end

---@param user User
function on_user_spawned(user)
    -- Update world reference if needed
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end

    local username = "Unknown"
    pcall(function() username = user.username end)

    local modifications = {}

    -- Randomize satiety_sla_ratio (minimum satisfaction % required)
    if config.enable_satiety_sla_randomization then
        pcall(function()
            local min_val = config.user_satiety_sla_min or 0.3
            local max_val = config.user_satiety_sla_max or 0.9
            local original = user.satiety_sla_ratio
            user.satiety_sla_ratio = min_val + math.random() * (max_val - min_val)
            table.insert(modifications, string.format("SLA: %.0f%%->%.0f%%", original * 100, user.satiety_sla_ratio * 100))
        end)
    end

    -- Randomize eagerness_factor (how impatient the user is)
    if config.enable_eagerness_randomization then
        pcall(function()
            local min_val = config.user_eagerness_min or 1
            local max_val = config.user_eagerness_max or 10
            local original = user.eagerness_factor
            user.eagerness_factor = math.random(min_val, max_val)
            table.insert(modifications, string.format("eager: %d->%d", original, user.eagerness_factor))
        end)
    end

    -- Randomize base_use_period (time between service requests)
    -- Multiplier >1 = longer wait = less frequent usage
    -- Multiplier <1 = shorter wait = more frequent usage
    if config.enable_use_period_randomization then
        pcall(function()
            local min_mult = config.user_use_period_min or 0.5
            local max_mult = config.user_use_period_max or 2.0
            local multiplier = min_mult + math.random() * (max_mult - min_mult)
            local original = user.base_use_period
            user.base_use_period = original * multiplier
            table.insert(modifications, string.format("period: %.1f->%.1f (x%.2f)", original, user.base_use_period, multiplier))
        end)
    end

    -- Randomize init_grace_days (forgiveness period before penalties)
    if config.enable_grace_days_randomization then
        pcall(function()
            local min_val = config.user_grace_days_min or 1
            local max_val = config.user_grace_days_max or 7
            local original = user.init_grace_days
            user.init_grace_days = math.random(min_val, max_val)
            table.insert(modifications, string.format("grace: %dd->%dd", original, user.init_grace_days))
        end)
    end

    -- Randomize max_satiety_decay_ratio (% satisfaction lost per tick)
    if config.enable_satiety_decay_randomization then
        pcall(function()
            local min_val = config.user_max_satiety_decay_min or 0.1
            local max_val = config.user_max_satiety_decay_max or 0.5
            local original = user.max_satiety_decay_ratio
            user.max_satiety_decay_ratio = min_val + math.random() * (max_val - min_val)
            table.insert(modifications, string.format("decay: %.0f%%->%.0f%%/tick", original * 100, user.max_satiety_decay_ratio * 100))
        end)
    end

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
