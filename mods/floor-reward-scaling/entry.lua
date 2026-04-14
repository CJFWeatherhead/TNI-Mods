-- Floor Reward Scaling Mod
-- Purpose: Automatically scales user daily payment rates based on their floor number using various scaling methods.
-- Author: Unknown
-- Version: 2.0
-- Description: This mod applies a configurable multiplier to user daily rates when they spawn. Choose from
--              logarithmic, linear, exponential, or randomised scaling for balanced or chaotic progression.
-- Usage: The mod works automatically on user spawn. Configure scaling type and factors in Mod Manager.
-- Notes: Hooks into on_user_spawned callback. Logs scaling information to console. Compatible with game version 0.10.0.

local mod_id = "floor-reward-scaling"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Scaling type selection
    scaling_type = "Logarithmic", -- "Logarithmic", "Linear", "Exponential", or "Randomised"

    -- Standard scaling factor (for non-Randomised modes)
    factor = 2.0,

    -- Randomised mode settings
    min_factor = 1.0,
    max_factor = 5.0,

    -- Advanced options
    debug_logging = false,
    apply_to_new_users_only = false
}

-- ===== MOD CONFIGURATION END =====

-- Maximum multiplier to prevent integer overflow
local MAX_MULTIPLIER = 20000

-- Calculate multiplier based on floor and scaling type
local function calculate_multiplier(floor_num)
    local scaling_type = config.scaling_type or "Logarithmic"
    local factor = config.factor or 2.0
    local multiplier

    if scaling_type == "Linear" then
        -- Linear: multiplier = 1 + (floor * factor)
        -- Simple linear growth: floor 0 = 1x, floor 5 = 11x (with factor 2)
        multiplier = 1 + (floor_num * factor)
    elseif scaling_type == "Exponential" then
        -- Exponential: multiplier = factor ^ floor
        -- Rapid growth: floor 0 = 1x, floor 5 = 32x (with factor 2)
        multiplier = math.pow(factor, floor_num)
    elseif scaling_type == "Randomised" then
        -- Randomised: multiplier = random between min and max
        local min_factor = config.min_factor or 1.0
        local max_factor = config.max_factor or 5.0
        multiplier = min_factor + (math.random() * (max_factor - min_factor))
    else -- "Logarithmic" (default)
        -- Logarithmic: multiplier = 1 + (log2(floor + 2) * factor)
        -- Diminishing returns: floor 0 = 2x, floor 5 = 3.8x, floor 10 = 4.6x (with factor 1)
        multiplier = 1 + (math.log(floor_num + 2, 2) * factor)
    end

    -- Apply hardcap to prevent overflow causing negative values
    if multiplier > MAX_MULTIPLIER then
        multiplier = MAX_MULTIPLIER
    end

    return multiplier
end

function on_engine_load()
    print("Floor Reward Scaling mod loaded!")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        print("ModApiV1 is not available!")
    end

    -- Log current configuration
    local scaling_type = config.scaling_type or "Logarithmic"
    local factor = config.factor or 2.0

    if scaling_type == "Randomised" then
        local min_factor = config.min_factor or 1.0
        local max_factor = config.max_factor or 5.0
        print(string.format("[floor-reward-scaling] Config: Type=%s, Range=%.1fx-%.1fx",
            scaling_type, min_factor, max_factor))
    else
        print(string.format("[floor-reward-scaling] Config: Type=%s, Factor=%.1fx",
            scaling_type, factor))
    end
end

function on_mod_reload()
    print("Pressed the reload action key (F11), reloading Floor Reward Scaling mod...")
end

---@param user User
function on_user_spawned(user)
    -- Get the user's location (floor)
    local location = user.location
    if not location then
        print("[floor-reward-scaling] ERROR: User has no location!")
        return
    end

    -- Get the floor number
    local floor_num = location.floor_num
    if not floor_num then
        print("[floor-reward-scaling] WARNING: Location has no floor_num, using 0")
        floor_num = 0
    end

    -- Apply configured floor-based multiplier to daily_rate
    local original_daily_rate = user.daily_rate
    local floor_multiplier = calculate_multiplier(floor_num)
    user.daily_rate = math.ceil(original_daily_rate * floor_multiplier)

    local scaling_type = config.scaling_type or "Logarithmic"
    local cap_message = (floor_multiplier >= MAX_MULTIPLIER) and " [CAPPED]" or ""
    print(string.format(
        "[floor-reward-scaling] Floor %d user (%s): Daily Rate %d -> %d (%.2fx multiplier%s)",
        floor_num,
        scaling_type,
        original_daily_rate,
        user.daily_rate,
        floor_multiplier,
        cap_message
    ))
end
