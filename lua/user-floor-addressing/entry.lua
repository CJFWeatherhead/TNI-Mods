-- User Floor-Based Addressing Mod
-- Sets DHCP mode, DNS servers, and assigns network addresses based on floor number + increment
--
-- DHCP Modes: "disabled", "boot_dhcp", "periodic_dhcp"
-- Version: 2.0 - Now with configurable parameters via modloader

local mod_id = "user-floor-addressing"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Network addressing
    dhcp_mode = "boot_dhcp", -- "disabled", "boot_dhcp", or "periodic_dhcp"
    address_format = "@f%d/usr%d",

    -- DNS configuration
    dns_format = "@f%d/dns",
    fallback_dns_1 = "@f0/dns1",
    fallback_dns_2 = "@f0/dns2",

    -- Hardware address configuration
    disable_hw_refresh = true,
    predictable_hw_address = false,

    -- Device addressing
    phone_address_format = "@voice/f%d/%d",
    cctv_address_format = "@cam/f%d/%d",

    -- Advanced options
    debug_logging = true,
    strict_validation = false
}

-- ===== MOD CONFIGURATION END =====

-- Helper to convert table to string for logging
local function params_to_string(t)
    if type(t) ~= "table" then return tostring(t) end
    local parts = {}
    for k, v in pairs(t) do
        table.insert(parts, tostring(k) .. "=" .. tostring(v))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

-- Helper to dump a table for debugging
local function dump_table(t, indent)
    if type(t) ~= 'table' then
        return tostring(t)
    end
    indent = indent or 0
    local result = {}
    for k, v in pairs(t) do
        local key = tostring(k)
        if type(v) == 'table' and indent < 2 then
            result[#result + 1] = string.rep("  ", indent) .. key .. " = " .. dump_table(v, indent + 1)
        else
            result[#result + 1] = string.rep("  ", indent) .. key .. " = " .. tostring(v)
        end
    end
    return "{\n" .. table.concat(result, "\n") .. "\n" .. string.rep("  ", indent - 1) .. "}"
end

function on_engine_load()
    print("User Floor-Based Addressing mod loaded!")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        print("ModApiV1 is not available!")
    end

    -- Log current configuration
    local addr_fmt = config.address_format or "@f%d/usr%d"
    local dhcp = config.dhcp_mode or "boot_dhcp"
    local dns_fmt = config.dns_format or "@f%d/dns"
    local disable_hw_refresh = config.disable_hw_refresh or false
    local predictable_hw = config.predictable_hw_address or false
    local phone_addr_fmt = config.phone_address_format or "@voice/f%d/%d"
    local cctv_addr_fmt = config.cctv_address_format or "@cam/f%d/%d"

    print(string.format(
        "[user-floor-addressing] Config: AddressFmt='%s', DHCP='%s', DNSFmt='%s', DisableHWRefresh=%s, PredictableHW=%s",
        tostring(addr_fmt), tostring(dhcp), tostring(dns_fmt), tostring(disable_hw_refresh), tostring(predictable_hw)))
    print(string.format(
        "[user-floor-addressing] Device Config: Phone='%s', CCTV='%s'",
        tostring(phone_addr_fmt), tostring(cctv_addr_fmt)))
    -- Quick sanity check on format strings
    local ok_addr = pcall(function() return string.format(addr_fmt, 1, 1) end)
    local ok_dns = pcall(function() return string.format(dns_fmt, 1) end)
    local ok_phone = pcall(function() return string.format(phone_addr_fmt, 1, 1) end)
    local ok_cctv = pcall(function() return string.format(cctv_addr_fmt, 1, 1) end)
    if not ok_addr then
        print("[user-floor-addressing] WARNING: address_format invalid, reverting to default '@f%d/usr%d'")
    end
    if not ok_dns then
        print("[user-floor-addressing] WARNING: dns_format invalid, reverting to default '@f%d/dns'")
    end
    if not ok_phone then
        print("[user-floor-addressing] WARNING: phone_address_format invalid, reverting to default '@voice/f%d/%d'")
    end
    if not ok_cctv then
        print("[user-floor-addressing] WARNING: cctv_address_format invalid, reverting to default '@cam/f%d/%d'")
    end
end

function on_mod_reload()
    print("Pressed the reload action key (F11), reloading User Floor-Based Addressing mod...")
    print("[user-floor-addressing] Reloaded configuration.")
end

-- Track user count per floor to generate incremental addresses
local floor_user_counts = {}

-- Track device counts per floor per type
local floor_device_counts = {
    phone = {},
    cctv = {}
}

---@param user User
function on_user_spawned(user)
    print("========================================")
    print("[user-floor-addressing] USER SPAWNED")
    print("  Type: " .. type(user))
    print("========================================")
    print("[user-floor-addressing] User spawned, configuring network settings...")

    -- Get the user's logic controller
    local logic_controller = user.logic_controller
    if not logic_controller then
        print("[user-floor-addressing] ERROR: User has no logic_controller!")
        return
    end

    -- Get the network control module
    local networkctl = logic_controller.networkctl
    if not networkctl then
        print("[user-floor-addressing] ERROR: Logic controller has no networkctl!")
        return
    end

    -- Get the user's location (floor)
    local location = user.location
    if not location then
        print("[user-floor-addressing] ERROR: User has no location!")
        return
    end

    -- Get the floor number
    local floor_num = location.floor_num
    if not floor_num then
        print("[user-floor-addressing] WARNING: Location has no floor_num, using 0")
        floor_num = 0
    end

    -- Initialize counter for this floor if needed
    if not floor_user_counts[floor_num] then
        floor_user_counts[floor_num] = 1
    else
        floor_user_counts[floor_num] = floor_user_counts[floor_num] + 1
    end

    local user_increment = floor_user_counts[floor_num]

    -- Get configuration parameters
    local address_format = config.address_format or "@f%d/usr%d"
    local dhcp_mode = config.dhcp_mode or "boot_dhcp"
    local dns_format = config.dns_format or "@f%d/dns"
    local fallback_dns_1 = config.fallback_dns_1 or "@f0/dns1"
    local fallback_dns_2 = config.fallback_dns_2 or "@f0/dns2"
    local disable_hw_refresh = config.disable_hw_refresh or false

    -- Note: Hardware addresses are assigned by RNG at device creation and cannot be modified
    -- The disable_hw_refresh option is kept for backward compatibility but has no effect
    if disable_hw_refresh then
        print(
            "[user-floor-addressing] WARNING: disable_hw_refresh has no effect - hardware addresses cannot be controlled via mod API")
    end

    -- Generate the network address based on configured format
    local network_address
    do
        local ok, result = pcall(function()
            return string.format(address_format, floor_num, user_increment)
        end)
        if ok then
            network_address = result
        else
            print("[user-floor-addressing] WARNING: address_format mismatch -> " .. tostring(result) .. "; using default")
            network_address = string.format("@f%d/usr%d", floor_num, user_increment)
        end
    end

    -- Set DHCP mode from configuration
    -- Important: We need to disable DHCP first, set the static address, then re-enable DHCP
    -- Otherwise DHCP mode might clear the static address
    networkctl.set_dhcp_mode("disabled")

    -- Set the network address
    networkctl.set_network_address(network_address)

    -- Now set the desired DHCP mode (after address is set)
    if dhcp_mode ~= "disabled" then
        networkctl.set_dhcp_mode(dhcp_mode)
    end

    -- Set DNS servers: floor-specific DNS first, then fallbacks
    local dns1
    do
        local ok, result = pcall(function()
            return string.format(dns_format, floor_num)
        end)
        if ok then
            dns1 = result
        else
            print("[user-floor-addressing] WARNING: dns_format mismatch -> " .. tostring(result) .. "; using default")
            dns1 = string.format("@f%d/dns", floor_num)
        end
    end
    local success, err = pcall(function()
        local dns_array = Array.create()
        dns_array:append(dns1)
        dns_array:append(fallback_dns_1)
        dns_array:append(fallback_dns_2)
        networkctl.set_designated_dns_servers(dns_array)
    end)

    if success then
        print("[user-floor-addressing] DNS servers set successfully")
    else
        print("[user-floor-addressing] WARNING: Failed to set DNS servers: " .. tostring(err))
        print(string.format("[user-floor-addressing] Manual command: net dns set %s %s %s on %s",
            dns1, fallback_dns_1, fallback_dns_2, tostring(networkctl.hardware_address)))
    end

    print(string.format(
        "[user-floor-addressing] Configured user on floor %d (increment %d):",
        floor_num,
        user_increment
    ))
    print(string.format("  Address: %s", network_address))
    print(string.format("  DHCP: %s", dhcp_mode))
    print(string.format("  DNS: %s, %s, %s", dns1, fallback_dns_1, fallback_dns_2))
    -- Hardware addresses are RNG-generated at device creation and cannot be controlled by mods
end

---@param device DeviceUnit
function on_device_spawned(device)
    -- Log device spawns
    print("========================================")
    print("[user-floor-addressing] DEVICE SPAWNED")
    print("  Type: " .. type(device))

    -- Try to get device class
    local device_class = nil
    local device_class_success, device_class_result = pcall(function() return device.device_hardware_class end)
    if device_class_success then
        device_class = device_class_result
        print("  device_hardware_class: " .. tostring(device_class))
    else
        print("  device_hardware_class: ERROR - " .. tostring(device_class_result))
    end

    -- Try to get floor number
    local floor_num_success, floor_num_result = pcall(function() return device.current_floor_num end)
    if floor_num_success then
        print("  current_floor_num: " .. tostring(floor_num_result))
    else
        print("  current_floor_num: ERROR - " .. tostring(floor_num_result))
    end
    print("========================================")

    -- Check if this is a device type we care about (PHONE or CCTV)
    -- DeviceUnit.DeviceHardwareClass.PHONE = 17, CCTV = 16
    local device_type = nil
    local device_type_name = nil
    if device_class == 17 then -- PHONE
        device_type = "phone"
        device_type_name = "Phone"
        print("[user-floor-addressing] *** IDENTIFIED AS PHONE ***")
    elseif device_class == 16 then -- CCTV
        device_type = "cctv"
        device_type_name = "CCTV"
        print("[user-floor-addressing] *** IDENTIFIED AS CCTV ***")
    else
        -- Not a device we want to configure
        print(string.format("[user-floor-addressing] Skipping device with class %s (not PHONE=17 or CCTV=16)",
            tostring(device_class)))
        return
    end

    print(string.format("[user-floor-addressing] %s device spawned, configuring network settings...", device_type_name))

    -- Get the device's logic controller
    local logic_controller = device.logic_controller
    if not logic_controller then
        print(string.format("[user-floor-addressing] ERROR: %s device has no logic_controller!", device_type_name))
        return
    end

    -- Get the network control module
    local networkctl = logic_controller.networkctl
    if not networkctl then
        print(string.format("[user-floor-addressing] ERROR: %s logic controller has no networkctl!", device_type_name))
        return
    end

    -- Get the device's floor number
    local floor_num = device.current_floor_num
    if not floor_num then
        print(string.format("[user-floor-addressing] WARNING: %s has no current_floor_num, using 0", device_type_name))
        floor_num = 0
    end

    -- Initialize counter for this device type on this floor if needed
    if not floor_device_counts[device_type][floor_num] then
        floor_device_counts[device_type][floor_num] = 1
    else
        floor_device_counts[device_type][floor_num] = floor_device_counts[device_type][floor_num] + 1
    end

    local device_increment = floor_device_counts[device_type][floor_num]

    -- Get configuration parameters
    local address_format
    if device_type == "phone" then
        address_format = config.phone_address_format or "@voice/f%d/%d"
    else -- cctv
        address_format = config.cctv_address_format or "@cam/f%d/%d"
    end

    local dhcp_mode = config.dhcp_mode or "boot_dhcp"
    local dns_format = config.dns_format or "@f%d/dns"
    local fallback_dns_1 = config.fallback_dns_1 or "@f0/dns1"
    local fallback_dns_2 = config.fallback_dns_2 or "@f0/dns2"
    local disable_hw_refresh = config.disable_hw_refresh or false

    -- Note: Hardware addresses are assigned by RNG at device creation and cannot be modified
    -- The disable_hw_refresh option is kept for backward compatibility but has no effect
    if disable_hw_refresh then
        print(string.format("[user-floor-addressing] WARNING: disable_hw_refresh has no effect for %s", device_type_name))
    end

    -- Generate the network address based on configured format
    local network_address
    do
        local ok, result = pcall(function()
            return string.format(address_format, floor_num, device_increment)
        end)
        if ok then
            network_address = result
        else
            print(string.format("[user-floor-addressing] WARNING: %s address_format mismatch -> %s; using default",
                device_type_name, tostring(result)))
            if device_type == "phone" then
                network_address = string.format("@voice/f%d/%d", floor_num, device_increment)
            else
                network_address = string.format("@cam/f%d/%d", floor_num, device_increment)
            end
        end
    end

    -- Set DHCP mode from configuration
    -- Important: We need to disable DHCP first, set the static address, then re-enable DHCP
    -- Otherwise DHCP mode might clear the static address
    networkctl.set_dhcp_mode("disabled")

    -- Set the network address
    networkctl.set_network_address(network_address)

    -- Now set the desired DHCP mode (after address is set)
    if dhcp_mode ~= "disabled" then
        networkctl.set_dhcp_mode(dhcp_mode)
    end

    -- Set DNS servers: floor-specific DNS first, then fallbacks
    local dns1
    do
        local ok, result = pcall(function()
            return string.format(dns_format, floor_num)
        end)
        if ok then
            dns1 = result
        else
            print(string.format("[user-floor-addressing] WARNING: dns_format mismatch -> %s; using default",
                tostring(result)))
            dns1 = string.format("@f%d/dns", floor_num)
        end
    end

    local success, err = pcall(function()
        local dns_array = Array.create()
        dns_array:append(dns1)
        dns_array:append(fallback_dns_1)
        dns_array:append(fallback_dns_2)
        networkctl.set_designated_dns_servers(dns_array)
    end)

    if success then
        print(string.format("[user-floor-addressing] %s DNS servers set successfully", device_type_name))
    else
        print(string.format("[user-floor-addressing] WARNING: Failed to set %s DNS servers: %s",
            device_type_name, tostring(err)))
    end

    print(string.format(
        "[user-floor-addressing] Configured %s on floor %d (increment %d):",
        device_type_name,
        floor_num,
        device_increment
    ))
    print(string.format("  Address: %s", network_address))
    print(string.format("  DHCP: %s", dhcp_mode))
    print(string.format("  DNS: %s, %s, %s", dns1, fallback_dns_1, fallback_dns_2))
    -- Hardware addresses are RNG-generated at device creation and cannot be controlled by mods
end

---@param location Location
function on_location_spawned(location)
    print("========================================")
    print("[user-floor-addressing] LOCATION SPAWNED")
    print("  Type: " .. type(location))

    -- Try to get location properties
    local floor_num_success, floor_num_result = pcall(function() return location.floor_num end)
    if floor_num_success then
        print("  floor_num: " .. tostring(floor_num_result))
    else
        print("  floor_num: ERROR - " .. tostring(floor_num_result))
    end

    local display_name_success, display_name = pcall(function() return location.display_name end)
    if display_name_success then
        print("  display_name: " .. tostring(display_name))
    else
        print("  display_name: ERROR - " .. tostring(display_name))
    end

    print("========================================")

    -- Note: Devices and users spawn separately via on_device_spawned and on_user_spawned
    -- This callback is just for location creation tracking
end
