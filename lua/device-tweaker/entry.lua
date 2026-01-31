-- Device Tweaker Mod
-- A comprehensive mod for tweaking device properties in Tower Networking Inc.
--
-- Author: Chris
-- Version: 1.0
-- Description: Allows configurable modifications to device properties including bandwidth,
--              warranties, costs, and hardware specifications (CPU/memory/storage).
--              Supports selective application by device class.
--
-- Usage: Configure multipliers and filters in the Mod Loader menu.
--
-- Device Classes:
--   0 = server
--   1 = switch
--   2 = router
--   3 = firewall
--   4 = workstation
--   5 = other/misc

local mod_id = "device-tweaker"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Feature toggles
    enable_bandwidth = true,
    enable_warranty = true,
    enable_cost = false,
    enable_cpu = false,
    enable_memory = false,
    enable_storage = false,

    -- Bandwidth settings
    bandwidth_multiplier = 2.0,

    -- Warranty settings
    warranty_mode = "random", -- "fixed" or "random"
    warranty_multiplier_fixed = 1.0,
    warranty_multiplier_min = 5.0,
    warranty_multiplier_max = 100.0,
    warranty_apply_cycles = true,
    warranty_apply_remaining = true,

    -- Cost settings
    cost_multiplier = 1.0,

    -- Hardware settings
    cpu_multiplier = 2.0,
    memory_multiplier = 4.0,
    storage_multiplier = 8.0,

    -- Device class filters
    enable_default = true,
    enable_network_switch = true,
    enable_network_router = true,
    enable_network_tap = true,
    enable_network_firewall = true,
    enable_media_line_simplex = true,
    enable_media_line_duplex = true,
    enable_compute_server = true,
    enable_display_monitor = true,
    enable_debugger = true,
    enable_load_tester = true,
    enable_power_expansion = true,
    enable_decentro_rigs = true,
    enable_surge_protector = true,
    enable_ups = true,
    enable_inert = true,
    enable_cctv = true,
    enable_phone = true,
    enable_printer = true,
    enable_network_load_balancer = true,

    -- Merchant restock settings
    enable_restock_hotkey = true,
    show_restock_notification = true
}

-- ===== MOD CONFIGURATION END =====

-- Device class names for logging (from DeviceHardwareClass enum)
local device_class_names = {
    [0] = "default",
    [1] = "network_switch",
    [2] = "network_router",
    [3] = "network_tap",
    [4] = "network_firewall",
    [5] = "media_line_simplex",
    [6] = "media_line_duplex",
    [7] = "compute_server",
    [8] = "display_monitor",
    [9] = "debugger",
    [10] = "load_tester",
    [11] = "power_expansion",
    [12] = "decentro_rigs",
    [13] = "surge_protector",
    [14] = "ups",
    [15] = "inert",
    [16] = "cctv",
    [17] = "phone",
    [18] = "printer",
    [19] = "network_load_balancer"
}

-- Check if a device class is enabled for modifications
local function is_class_enabled(device_class)
    local class_name = device_class_names[device_class] or "other"
    return config["enable_" .. class_name] ~= false
end

function on_engine_load()
    print("Device Tweaker Mod loaded!")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        print("ModApiV1 is not available!")
    end

    -- Log active modifications
    local active_mods = {}
    if config.enable_bandwidth then
        active_mods[#active_mods + 1] = string.format("Bandwidth x%.2f", config.bandwidth_multiplier)
    end
    if config.enable_warranty then
        if config.warranty_mode == "random" then
            active_mods[#active_mods + 1] = string.format("Warranty x%.2f-%.2f (random)",
                config.warranty_multiplier_min, config.warranty_multiplier_max)
        else
            active_mods[#active_mods + 1] = string.format("Warranty x%.2f", config.warranty_multiplier_fixed)
        end
    end
    if config.enable_cost then
        active_mods[#active_mods + 1] = string.format("Cost x%.2f", config.cost_multiplier)
    end
    if config.enable_cpu then
        active_mods[#active_mods + 1] = string.format("CPU x%.2f", config.cpu_multiplier)
    end
    if config.enable_memory then
        active_mods[#active_mods + 1] = string.format("Memory x%.2f", config.memory_multiplier)
    end
    if config.enable_storage then
        active_mods[#active_mods + 1] = string.format("Storage x%.2f", config.storage_multiplier)
    end

    if #active_mods > 0 then
        print("[device-tweaker] Active modifications: " .. table.concat(active_mods, ", "))
    else
        print("[device-tweaker] No modifications enabled")
    end

    -- Log enabled device classes
    local enabled_classes = {}
    for class, name in pairs(device_class_names) do
        if is_class_enabled(class) then
            enabled_classes[#enabled_classes + 1] = name
        end
    end
    if #enabled_classes > 0 then
        print("[device-tweaker] Enabled device classes: " .. table.concat(enabled_classes, ", "))
    end
end

function on_mod_reload()
    print("[device-tweaker] Reloading configuration...")
end

-- Merchant restock functionality
local last_restock_time = 0
local RESTOCK_COOLDOWN = 1.0

local function restock_all_merchants()
    local world = ModApiV1.get_game_world()
    if not world then
        print("[device-tweaker] Cannot restock: world not available")
        return false
    end

    local merchants = world.device_merchants
    if not merchants then
        print("[device-tweaker] Cannot restock: no merchants available")
        return false
    end

    local restock_count = 0
    pcall(function()
        local size = merchants:size()
        for i = 0, size - 1 do
            local merchant = merchants:get(i)
            if merchant and merchant.restock then
                merchant:restock()
                restock_count = restock_count + 1
            end
        end
    end)

    print(string.format("[device-tweaker] Restocked %d merchants", restock_count))
    return restock_count > 0
end

-- Keyboard input handler for SHIFT+R (restock)
function on_player_input(event)
    if not config.enable_restock_hotkey then
        return
    end

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

    -- SHIFT+R (82) - Restock all merchants
    if keycode == 82 and is_pressed and is_shift then
        local current_time = os.clock()
        if current_time - last_restock_time < RESTOCK_COOLDOWN then
            return
        end
        last_restock_time = current_time

        if restock_all_merchants() then
            if config.show_restock_notification then
                pcall(function()
                    local base_ui = ModApiV1.get_base_ui()
                    if base_ui and base_ui.display_notification then
                        base_ui.display_notification("All merchants restocked!", 1)
                    end
                end)
            end
        end
    end
end

-- Helper function to dump device properties for debugging
local function dump_device_properties(device, device_name)
    print(string.format("[device-tweaker] === DEBUG: %s ===", device_name))
    print(string.format("  device_hardware_class: %s", tostring(device.device_hardware_class)))
    print(string.format("  product_name: %s", tostring(device.product_name)))
    print(string.format("  base_cost_dollars: %s", tostring(device.base_cost_dollars)))
    print(string.format("  base_warranty_days: %s", tostring(device.base_warranty_days)))
    print(string.format("  base_warranty_cycles: %s", tostring(device.base_warranty_cycles)))

    if device.logic_controller then
        print("  logic_controller exists:")
        print(string.format("    installed_nbw: %s", tostring(device.logic_controller.installed_nbw)))
        print(string.format("    cpu_power: %s", tostring(device.logic_controller.cpu_power)))
        print(string.format("    installed_ram: %s", tostring(device.logic_controller.installed_ram)))
        print(string.format("    installed_storage: %s", tostring(device.logic_controller.installed_storage)))
    else
        print("  logic_controller: nil")
    end
    print("[device-tweaker] === END DEBUG ===")
end

-- Track if we've already done a debug dump (to avoid spam)
local debug_dump_done = {}

---@param device DeviceUnit
function on_device_spawned(device)
    -- Check if this device class is enabled
    if not is_class_enabled(device.device_hardware_class) then
        return
    end

    -- Debug dump for first device of each class
    local class_name = device_class_names[device.device_hardware_class] or "unknown"
    if not debug_dump_done[device.device_hardware_class] then
        dump_device_properties(device, class_name)
        debug_dump_done[device.device_hardware_class] = true
    end

    -- Apply all enabled modifications
    local modifications = {}

    -- Bandwidth modification
    if config.enable_bandwidth and device.logic_controller then
        local multiplier = config.bandwidth_multiplier or 1.0
        if multiplier ~= 1.0 then
            local current_bw = device.logic_controller.installed_nbw
            if current_bw and current_bw > 0 then
                local new_bw = math.ceil(current_bw * multiplier)
                device.logic_controller.installed_nbw = new_bw
                modifications[#modifications + 1] = string.format("BW: %d -> %d (x%.2f)", current_bw, new_bw, multiplier)
            end
        end
    end

    -- Warranty modification
    if config.enable_warranty then
        local multiplier

        if config.warranty_mode == "random" then
            local min_mult = config.warranty_multiplier_min or 2.0
            local max_mult = config.warranty_multiplier_max or 25.0
            multiplier = min_mult + math.random() * (max_mult - min_mult)
        else
            multiplier = config.warranty_multiplier_fixed or 1.0
        end

        if multiplier ~= 1.0 then
            local original_days = device.base_warranty_days
            device.base_warranty_days = math.ceil(original_days * multiplier)
            modifications[#modifications + 1] = string.format("warranty: %d -> %d days (x%.2f)",
                original_days, device.base_warranty_days, multiplier)

            if config.warranty_apply_cycles then
                local original_cycles = device.base_warranty_cycles
                device.base_warranty_cycles = math.ceil(original_cycles * multiplier)
            end

            if config.warranty_apply_remaining and device.warranty_period_remaining > 0 then
                device.warranty_period_remaining = math.ceil(device.warranty_period_remaining * multiplier)
            end
        end
    end

    -- Price modification
    if config.enable_cost then
        local multiplier = config.cost_multiplier or 1.0
        if multiplier ~= 1.0 then
            local original_cost = device.base_cost_dollars
            if original_cost and original_cost > 0 then
                device.base_cost_dollars = math.ceil(original_cost * multiplier)
                modifications[#modifications + 1] = string.format("cost: $%d -> $%d", original_cost,
                    device.base_cost_dollars)
            end
        end
    end

    -- Hardware modifications (CPU, RAM, Storage)
    if device.logic_controller then
        if config.enable_cpu then
            local multiplier = config.cpu_multiplier or 1.0
            if multiplier ~= 1.0 then
                local original = device.logic_controller.cpu_power
                if original and original > 0 then
                    local new_value = math.ceil(original * multiplier)
                    device.logic_controller.cpu_power = new_value
                    modifications[#modifications + 1] = string.format("CPU: %d -> %d", original, new_value)
                end
            end
        end

        if config.enable_memory then
            local multiplier = config.memory_multiplier or 1.0
            if multiplier ~= 1.0 then
                local original = device.logic_controller.installed_ram
                if original and original > 0 then
                    local new_value = math.ceil(original * multiplier)
                    device.logic_controller.installed_ram = new_value
                    modifications[#modifications + 1] = string.format("RAM: %d -> %d", original, new_value)
                end
            end
        end

        if config.enable_storage then
            local multiplier = config.storage_multiplier or 1.0
            if multiplier ~= 1.0 then
                local original = device.logic_controller.installed_storage
                if original and original > 0 then
                    local new_value = math.ceil(original * multiplier)
                    device.logic_controller.installed_storage = new_value
                    modifications[#modifications + 1] = string.format("storage: %d -> %d", original, new_value)
                end
            end
        end
    end

    -- Log modifications if any were made
    if #modifications > 0 then
        local class_name = device_class_names[device.device_hardware_class] or "unknown"
        print(string.format("[device-tweaker] %s (%s): %s",
            device.product_name,
            class_name,
            table.concat(modifications, " | ")))
    end
end
