-- Random Device Warranties Mod
-- This mod randomizes the warranty periods of all spawned devices.
--
-- Author: Chris
-- Version: 2.0
-- Description: When devices are spawned, their base warranty days and cycles are multiplied by a random factor.
--              Multiplier range is configurable via mod parameters.
--
-- Usage: Place this mod in the lua/random-warranties/ folder and load the game.
--        Configure multiplier ranges in the Mod Loader menu.
--
-- Notes: The multiplier is randomly chosen for each device individually.

-- Load mod configuration system
local mod_id = "random-warranties"
local config = nil

-- Try to load modloader config if available
local function load_config()
    local success, ModConfig = pcall(require, "modloader.config")
    if success then
        config = ModConfig
        print("[random-warranties] Using modloader configuration system")
    else
        print("[random-warranties] Modloader not available, using defaults")
    end
end

-- Get parameter value with fallback to default
local function get_param(name, default)
    if config then
        return config.get_parameter(mod_id, name, default)
    end
    return default
end

function on_engine_load()
    print("Random Device Warranties Mod loaded!")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        print("ModApiV1 is not available!")
    end

    load_config()

    -- Log current configuration
    local min_mult = get_param("warranty_multiplier_min", 2)
    local max_mult = get_param("warranty_multiplier_max", 25)
    local apply_cycles = get_param("apply_to_cycles", true)
    local apply_remaining = get_param("apply_to_remaining", true)

    print(string.format("[random-warranties] Config: Multiplier range %dx-%dx, Cycles: %s, Remaining: %s",
        min_mult, max_mult, tostring(apply_cycles), tostring(apply_remaining)))
end

function on_mod_reload()
    print("Pressed the reload action key (F11), reloading mod...")
    load_config()
end

---@param device DeviceUnit
function on_device_spawned(device)
    -- Get configuration parameters
    local min_multiplier = get_param("warranty_multiplier_min", 2)
    local max_multiplier = get_param("warranty_multiplier_max", 25)
    local apply_to_cycles = get_param("apply_to_cycles", true)
    local apply_to_remaining = get_param("apply_to_remaining", true)

    -- Generate a random multiplier within the configured range
    local multiplier = math.random(min_multiplier, max_multiplier)

    -- Multiply the base warranty days and cycles by the random multiplier
    local original_days = device.base_warranty_days
    local original_cycles = device.base_warranty_cycles

    device.base_warranty_days = math.ceil(original_days * multiplier)

    if apply_to_cycles then
        device.base_warranty_cycles = math.ceil(original_cycles * multiplier)
    end

    -- Also apply the same multiplier to warranty_period_remaining if configured
    if apply_to_remaining and device.warranty_period_remaining > 0 then
        device.warranty_period_remaining = math.ceil(device.warranty_period_remaining * multiplier)
    end

    print(string.format(
        "[random-warranties] Modified warranty of %s: days %d -> %d (x%d)%s%s",
        device.product_name,
        original_days,
        device.base_warranty_days,
        multiplier,
        apply_to_cycles and string.format(", cycles %d -> %d", original_cycles, device.base_warranty_cycles) or "",
        apply_to_remaining and device.warranty_period_remaining > 0 and " [remaining applied]" or ""
    ))
end
