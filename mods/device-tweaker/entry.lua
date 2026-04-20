-- Device Tweaker Mod
-- A comprehensive mod for tweaking device properties in Tower Networking Inc.
--
-- Author: Chris
-- Version: 3.1.0
-- Description: Allows configurable modifications to device properties including bandwidth,
--              warranties, costs, and hardware specifications (CPU/memory/storage).
--              Supports selective application by device class.
--              Own floating panel with toggle-mode buttons polled via on_tick.
--
-- Usage: Configure multipliers and filters in the Mod Loader menu.
--        Open the debug console (~) and type a command name.
--
-- Console commands:
--   m_restock      Restock all merchants
--   m_dt_panel     Toggle the Device Tweaker panel
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
--
-- API Property Reference (game version 0.10.11):
--   DeviceUnit.price                       (integer)
--   DeviceUnit.base_warranty_days          (integer)
--   DeviceUnit.base_warranty_cycles        (integer)
--   DeviceUnit.warranty_period_remaining   (integer)
--   DeviceUnit.device_hardware_class       (enum)
--   LogicController.installed_nbw          (integer) - network bandwidth
--   LogicController.installed_cpu          (integer) - CPU power
--   LogicController.installed_mem          (integer) - memory/RAM
--   LogicController.installed_sto          (integer) - storage

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
    enable_network_storage = true,

    -- Merchant restock settings
    show_restock_notification = true
}

-- ===== MOD CONFIGURATION END =====

local _dt_btn = nil
local _dt_panel       = nil
local _dt_panel_visible = false
local _dt_panel_close = nil
local _dt_status      = nil

-- Device class names for logging (from DeviceHardwareClass enum, game 0.10.11)
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

-- Check if a device class is enabled for modifications
local function is_class_enabled(device_class)
    local class_name = device_class_names[device_class]
    if not class_name then return false end
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

    print("[device-tweaker] Console: m_restock  m_dt_panel")
end

-- =========================================================================
-- Panel (standalone CanvasLayer at /root)
-- =========================================================================

local function destroy_dt_panel()
    if _dt_panel then pcall(function() _dt_panel.queue_free() end) end
    _dt_panel = nil; _dt_panel_visible = false; _dt_panel_close = nil
    _dt_btn = nil; _dt_status = nil
end

local function build_dt_panel(world)
    destroy_dt_panel()
    local ok, err = pcall(function()
        local root = world.get_node("/root")
        if not root then print("[device-tweaker] build_panel: /root not found"); return end

        _dt_panel = create_node("CanvasLayer", "")
        _dt_panel.layer = 100
        _dt_panel.visible = false

        local container = create_node("PanelContainer", "")
        _dt_panel.add_child(container)
        pcall(function()
            container.anchor_left = 1.0; container.anchor_top = 0.0
            container.anchor_right = 1.0; container.anchor_bottom = 0.0
        end)
        pcall(function()
            container.offset_left = -270; container.offset_top = 380
            container.offset_right = -10;  container.offset_bottom = 500
        end)
        pcall(function() container.self_modulate = Color(1, 1, 1, 0.92) end)

        local vbox = create_node("VBoxContainer", "")
        container.add_child(vbox)

        -- Header
        local header = create_node("HBoxContainer", "")
        vbox.add_child(header)
        local title = create_node("Label", "")
        title.text = "Device Tweaker"
        pcall(function() title.add_theme_font_size_override("font_size", 15) end)
        pcall(function() title.size_flags_horizontal = 3 end)
        header.add_child(title)

        _dt_panel_close = create_node("Button", "")
        _dt_panel_close.text = "X"
        _dt_panel_close.flat = true
        _dt_panel_close.toggle_mode = true
        pcall(function() _dt_panel_close.custom_minimum_size = Vector2(28, 28) end)
        header.add_child(_dt_panel_close)

        -- Status
        _dt_status = create_node("Label", "")
        _dt_status.text = "Ready"
        pcall(function() _dt_status.add_theme_font_size_override("font_size", 11) end)
        vbox.add_child(_dt_status)

        -- Restock button
        local btn = create_node("Button", "")
        btn.text = "Restock Merchants"
        btn.toggle_mode = true
        pcall(function() btn.custom_minimum_size = Vector2(0, 28) end)
        vbox.add_child(btn)
        _dt_btn = btn

        root.add_child(_dt_panel)
        print("[device-tweaker] Panel built (standalone CanvasLayer at /root)")
    end)
    if not ok then print("[device-tweaker] build_panel ERROR: " .. tostring(err)) end
end

-- Register commands with the debug console when game is fully loaded
function on_game_state_ready()
    print("[device-tweaker] on_game_state_ready: begin")
    local world = ModApiV1.get_game_world()
    if not world then return end

    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if ok and dbg then
        pcall(function() dbg.enabled = true end)
        local cmds = {
            {"m_restock",  restock},
            {"m_dt_panel", m_dt_panel},
        }
        for _, cmd in ipairs(cmds) do
            pcall(function() dbg.register_cmd(cmd[1], cmd[2]) end)
        end
        print("[device-tweaker] on_game_state_ready: registered " .. #cmds .. " console commands")
    else
        print("[device-tweaker] on_game_state_ready: DebugLayer not found")
    end

    build_dt_panel(world)
end

function on_mod_reload()
    print("[device-tweaker] Reloaded (F11)")
    debug_dump_done = {}
    destroy_dt_panel()
    local w = ModApiV1 and ModApiV1.get_game_world()
    if w then build_dt_panel(w) end
end

-- Merchant restock functionality using ModApiV1.get_merchants()
local function restock_all_merchants()
    print("[device-tweaker] restock_all_merchants: begin")
    local merchants = ModApiV1.get_merchants()
    if not merchants then
        print("[device-tweaker] restock_all_merchants: get_merchants() returned nil")
        return false
    end

    local restock_count = 0
    local success = pcall(function()
        local size = merchants:size()
        print(string.format("[device-tweaker] restock_all_merchants: found %d merchants", size))
        for i = 0, size - 1 do
            local merchant = merchants:get(i)
            if merchant then
                local merchant_name = tostring(merchant.display_name or ("Merchant " .. i))
                print(string.format("[device-tweaker] restock_all_merchants: restocking %s...", merchant_name))
                local restock_ok, restock_err = pcall(function()
                    merchant.restock()
                end)
                if restock_ok then
                    restock_count = restock_count + 1
                    print(string.format("[device-tweaker] restock_all_merchants: %s OK", merchant_name))
                else
                    print(string.format("[device-tweaker] restock_all_merchants: %s FAILED: %s",
                        merchant_name, tostring(restock_err)))
                end
            end
        end
    end)

    if not success then
        print("[device-tweaker] restock_all_merchants: error during merchant iteration")
    end

    print(string.format("[device-tweaker] restock_all_merchants: done (%d restocked)", restock_count))
    if _dt_status then
        pcall(function() _dt_status.text = string.format("Restocked %d merchants", restock_count) end)
    end
    return restock_count > 0
end

-- Console command: restock all merchants
function restock()
    print("[device-tweaker] restock: begin")
    restock_all_merchants()
    print("[device-tweaker] restock: end")
end

-- Console command: toggle panel
function m_dt_panel()
    if not _dt_panel then print("[device-tweaker] m_dt_panel: panel not built yet"); return end
    _dt_panel_visible = not _dt_panel_visible
    pcall(function() _dt_panel.visible = _dt_panel_visible end)
    print("[device-tweaker] m_dt_panel: " .. (_dt_panel_visible and "shown" or "hidden"))
end

-- Helper function to dump device properties for debugging (correct API property names)
local function dump_device_properties(device, device_name)
    print(string.format("[device-tweaker] === DEBUG: %s ===", device_name))
    print(string.format("  device_hardware_class: %s", tostring(device.device_hardware_class)))
    print(string.format("  product_name: %s", tostring(device.product_name)))
    print(string.format("  price: %s", tostring(device.price)))
    print(string.format("  base_warranty_days: %s", tostring(device.base_warranty_days)))
    print(string.format("  base_warranty_cycles: %s", tostring(device.base_warranty_cycles)))
    print(string.format("  warranty_period_remaining: %s", tostring(device.warranty_period_remaining)))

    if device.logic_controller then
        print("  logic_controller:")
        print(string.format("    installed_nbw: %s", tostring(device.logic_controller.installed_nbw)))
        print(string.format("    installed_cpu: %s", tostring(device.logic_controller.installed_cpu)))
        print(string.format("    installed_mem: %s", tostring(device.logic_controller.installed_mem)))
        print(string.format("    installed_sto: %s", tostring(device.logic_controller.installed_sto)))
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

    -- Bandwidth modification (LogicController.installed_nbw)
    if config.enable_bandwidth and device.logic_controller then
        local multiplier = config.bandwidth_multiplier or 1.0
        if multiplier ~= 1.0 then
            local current_bw = device.logic_controller.installed_nbw
            if current_bw and current_bw > 0 then
                local new_bw = math.ceil(current_bw * multiplier)
                device.logic_controller.installed_nbw = new_bw
                modifications[#modifications + 1] = string.format("BW: %d -> %d (x%.2f)",
                    current_bw, new_bw, multiplier)
            end
        end
    end

    -- Warranty modification (DeviceUnit.base_warranty_days, base_warranty_cycles, warranty_period_remaining)
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

    -- Price modification (DeviceUnit.price)
    if config.enable_cost then
        local multiplier = config.cost_multiplier or 1.0
        if multiplier ~= 1.0 then
            local original_price = device.price
            if original_price and original_price > 0 then
                device.price = math.ceil(original_price * multiplier)
                modifications[#modifications + 1] = string.format("price: $%d -> $%d",
                    original_price, device.price)
            end
        end
    end

    -- Hardware modifications (LogicController: installed_cpu, installed_mem, installed_sto)
    if device.logic_controller then
        if config.enable_cpu then
            local multiplier = config.cpu_multiplier or 1.0
            if multiplier ~= 1.0 then
                local original = device.logic_controller.installed_cpu
                if original and original > 0 then
                    local new_value = math.ceil(original * multiplier)
                    device.logic_controller.installed_cpu = new_value
                    modifications[#modifications + 1] = string.format("CPU: %d -> %d",
                        original, new_value)
                end
            end
        end

        if config.enable_memory then
            local multiplier = config.memory_multiplier or 1.0
            if multiplier ~= 1.0 then
                local original = device.logic_controller.installed_mem
                if original and original > 0 then
                    local new_value = math.ceil(original * multiplier)
                    device.logic_controller.installed_mem = new_value
                    modifications[#modifications + 1] = string.format("MEM: %d -> %d",
                        original, new_value)
                end
            end
        end

        if config.enable_storage then
            local multiplier = config.storage_multiplier or 1.0
            if multiplier ~= 1.0 then
                local original = device.logic_controller.installed_sto
                if original and original > 0 then
                    local new_value = math.ceil(original * multiplier)
                    device.logic_controller.installed_sto = new_value
                    modifications[#modifications + 1] = string.format("STO: %d -> %d",
                        original, new_value)
                end
            end
        end
    end

    -- Log modifications if any were made
    if #modifications > 0 then
        print(string.format("[device-tweaker] %s (%s): %s",
            device.product_name,
            class_name,
            table.concat(modifications, " | ")))
    end
end

function on_tick(delta)
    -- Poll close button
    if _dt_panel_close then
        pcall(function()
            if _dt_panel_close.button_pressed then
                _dt_panel_close.button_pressed = false
                _dt_panel_visible = false
                _dt_panel.visible = false
            end
        end)
    end
    -- Poll restock button
    if _dt_btn then
        pcall(function()
            if _dt_btn.button_pressed then
                _dt_btn.button_pressed = false
                restock()
            end
        end)
    end
end
