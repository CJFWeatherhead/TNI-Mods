-- Device Tweaker Mod
-- A comprehensive mod for tweaking device properties in Tower Networking Inc.
--
-- Author: Chris
-- Version: 4.0.0
-- Description: Allows configurable modifications to device properties including bandwidth,
--              warranties, costs, and hardware specifications (CPU/memory/storage).
--              Supports selective application by device class.
--              Purely passive — modifies devices on spawn, no user interaction needed.
--              Restock functionality moved to money-cheat (SHIFT+R).
--
-- Usage: Configure multipliers and filters in the Mod Loader menu.
--        Device modifications are applied automatically on spawn.
--
-- No keyboard shortcuts, no panels, no register_cmd.
-- This mod has zero on_player_input overhead.
--
-- Device Hardware Classes (DeviceUnit.DeviceHardwareClass enum):
--   0  = DEFAULT              11 = POWER_EXPANSION
--   1  = NETWORK_SWITCH       12 = DECENTRO_RIGS
--   2  = NETWORK_ROUTER       13 = SURGE_PROTECTOR
--   3  = NETWORK_TAP          14 = UPS
--   4  = NETWORK_FIREWALL     15 = INERT
--   5  = MEDIA_LINE_SIMPLEX   16 = CCTV
--   6  = MEDIA_LINE_DUPLEX    17 = PHONE
--   7  = COMPUTE_SERVER       18 = PRINTER
--   8  = DISPLAY_MONITOR      19 = NETWORK_LOAD_BALANCER
--   9  = DEBUGGER             20 = NETWORK_STORAGE
--   10 = LOAD_TESTER

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
    bandwidth_mode = "fixed",   -- "fixed" or "random"
    bandwidth_multiplier = 2.0,
    bandwidth_multiplier_min = 1.5,
    bandwidth_multiplier_max = 4.0,

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
    memory_mode = "fixed",     -- "fixed" or "random"
    memory_multiplier = 4.0,
    memory_multiplier_min = 2.0,
    memory_multiplier_max = 8.0,
    storage_mode = "fixed",    -- "fixed" or "random"
    storage_multiplier = 8.0,
    storage_multiplier_min = 4.0,
    storage_multiplier_max = 16.0,

    -- Device class filters (keyed by DeviceHardwareClass enum names)
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
    enable_network_storage = true
}

-- ===== MOD CONFIGURATION END =====

-- Device class names for logging
local device_class_names = {
    [0]  = "default",
    [1]  = "network_switch",
    [2]  = "network_router",
    [3]  = "network_tap",
    [4]  = "network_firewall",
    [5]  = "media_line_simplex",
    [6]  = "media_line_duplex",
    [7]  = "compute_server",
    [8]  = "display_monitor",
    [9]  = "debugger",
    [10] = "load_tester",
    [11] = "power_expansion",
    [12] = "decentro_rigs",
    [13] = "surge_protector",
    [14] = "ups",
    [15] = "inert",
    [16] = "cctv",
    [17] = "phone",
    [18] = "printer",
    [19] = "network_load_balancer",
    [20] = "network_storage"
}

local function is_class_enabled(device_class)
    local class_name = device_class_names[device_class]
    if not class_name then return false end
    return config["enable_" .. class_name] ~= false
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    print("[device-tweaker] Device Tweaker v4.0.0 loaded (passive — no input)")
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end

    local active = {}
    if config.enable_bandwidth then
        active[#active + 1] = string.format("BW x%.1f", config.bandwidth_multiplier)
    end
    if config.enable_warranty then
        if config.warranty_mode == "random" then
            active[#active + 1] = string.format("Warranty x%.1f-%.1f",
                config.warranty_multiplier_min, config.warranty_multiplier_max)
        else
            active[#active + 1] = string.format("Warranty x%.1f", config.warranty_multiplier_fixed)
        end
    end
    if config.enable_cost then active[#active + 1] = string.format("Cost x%.1f", config.cost_multiplier) end
    if config.enable_cpu then active[#active + 1] = string.format("CPU x%.1f", config.cpu_multiplier) end
    if config.enable_memory then active[#active + 1] = string.format("MEM x%.1f", config.memory_multiplier) end
    if config.enable_storage then active[#active + 1] = string.format("STO x%.1f", config.storage_multiplier) end

    if #active > 0 then
        print("[device-tweaker] Active: " .. table.concat(active, ", "))
    else
        print("[device-tweaker] No modifications enabled")
    end
    print("[device-tweaker] Restock moved to money-cheat (SHIFT+R)")
end

function on_game_state_ready()
    print("[device-tweaker] Ready")
end

function on_mod_reload()
    print("[device-tweaker] Reloaded (F11)")
end

-- =========================================================================
-- Device modification (fires on each device spawn — no user input needed)
-- =========================================================================

---@param device DeviceUnit
function on_device_spawned(device)
    if not is_class_enabled(device.device_hardware_class) then return end

    local class_name = device_class_names[device.device_hardware_class] or "unknown"
    local modifications = {}

    -- Bandwidth (LogicController.installed_nbw)
    if config.enable_bandwidth and device.logic_controller then
        local mult
        if config.bandwidth_mode == "random" then
            local mn = config.bandwidth_multiplier_min or 1.5
            local mx = config.bandwidth_multiplier_max or 4.0
            mult = mn + math.random() * (mx - mn)
        else
            mult = config.bandwidth_multiplier or 1.0
        end
        if mult ~= 1.0 then
            local cur = device.logic_controller.installed_nbw
            if cur and cur > 0 then
                local new = math.ceil(cur * mult)
                device.logic_controller.installed_nbw = new
                modifications[#modifications + 1] = string.format("BW:%d->%d", cur, new)
            end
        end
    end

    -- Warranty
    if config.enable_warranty then
        local mult
        if config.warranty_mode == "random" then
            local mn = config.warranty_multiplier_min or 2.0
            local mx = config.warranty_multiplier_max or 25.0
            mult = mn + math.random() * (mx - mn)
        else
            mult = config.warranty_multiplier_fixed or 1.0
        end
        if mult ~= 1.0 then
            local orig = device.base_warranty_days
            device.base_warranty_days = math.ceil(orig * mult)
            modifications[#modifications + 1] = string.format("WRN:%d->%dd", orig, device.base_warranty_days)
            if config.warranty_apply_cycles then
                device.base_warranty_cycles = math.ceil(device.base_warranty_cycles * mult)
            end
            if config.warranty_apply_remaining and device.warranty_period_remaining > 0 then
                device.warranty_period_remaining = math.ceil(device.warranty_period_remaining * mult)
            end
        end
    end

    -- Price
    if config.enable_cost then
        local mult = config.cost_multiplier or 1.0
        if mult ~= 1.0 and device.price and device.price > 0 then
            local orig = device.price
            device.price = math.ceil(orig * mult)
            modifications[#modifications + 1] = string.format("$%d->$%d", orig, device.price)
        end
    end

    -- CPU / Memory / Storage
    if device.logic_controller then
        if config.enable_cpu then
            local mult = config.cpu_multiplier or 1.0
            if mult ~= 1.0 then
                local cur = device.logic_controller.installed_cpu
                if cur and cur > 0 then
                    local new = math.ceil(cur * mult)
                    device.logic_controller.installed_cpu = new
                    modifications[#modifications + 1] = string.format("CPU:%d->%d", cur, new)
                end
            end
        end
        if config.enable_memory then
            local mult
            if config.memory_mode == "random" then
                local mn = config.memory_multiplier_min or 2.0
                local mx = config.memory_multiplier_max or 8.0
                mult = mn + math.random() * (mx - mn)
            else
                mult = config.memory_multiplier or 1.0
            end
            if mult ~= 1.0 then
                local cur = device.logic_controller.installed_mem
                if cur and cur > 0 then
                    local new = math.ceil(cur * mult)
                    device.logic_controller.installed_mem = new
                    modifications[#modifications + 1] = string.format("MEM:%d->%d", cur, new)
                end
            end
        end
        if config.enable_storage then
            local mult
            if config.storage_mode == "random" then
                local mn = config.storage_multiplier_min or 4.0
                local mx = config.storage_multiplier_max or 16.0
                mult = mn + math.random() * (mx - mn)
            else
                mult = config.storage_multiplier or 1.0
            end
            if mult ~= 1.0 then
                local cur = device.logic_controller.installed_sto
                if cur and cur > 0 then
                    local new = math.ceil(cur * mult)
                    device.logic_controller.installed_sto = new
                    modifications[#modifications + 1] = string.format("STO:%d->%d", cur, new)
                end
            end
        end
    end

    if #modifications > 0 then
        print(string.format("[device-tweaker] %s (%s): %s",
            device.product_name, class_name, table.concat(modifications, " | ")))
    end
end
