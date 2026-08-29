-- User Floor-Based Addressing Mod
-- Sets DHCP mode, DNS servers, and assigns network addresses based on floor number + increment
--
-- DHCP Modes: "disabled", "boot_dhcp", "periodic_dhcp"
-- Version: 3.1 - Removed DHCP mode control (now native); added randomised suffix support
--
-- LIMITATIONS:
--   Hardware (MAC) address control: not supported -- the mod API does not expose
--   any method to set or refresh hardware addresses.
--   Phone / CCTV addressing: not supported -- these are fixture outlets
--   (DeviceOutlet/PoweredDeviceOutlet) instantiated by MultiplayerSpawner nodes
--   and are not accessible via the Lua sandbox.

local mod_id = "user-floor-addressing"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Network addressing
    use_random_suffix = false, -- false = incremental (usr1, usr2...), true = random 4-char (usrabcd, usrxyze...)
    address_format = "@f%d/usr%s",

    -- DNS configuration
    dns_format = "@f%d/dns",
    fallback_dns_1 = "@srv/dns1",
    fallback_dns_2 = "@srv/dns2",

    -- Advanced options
    debug_logging = false,
}

-- ===== MOD CONFIGURATION END =====

-- Generate a random lowercase alphabetic string of the given length
local function random_suffix(len)
    local chars = "abcdefghijklmnopqrstuvwxyz"
    local result = {}
    for i = 1, len do
        local idx = math.random(1, #chars)
        result[i] = chars:sub(idx, idx)
    end
    return table.concat(result)
end

function on_engine_load()
    math.randomseed(os.time())
    print("[user-floor-addressing] Mod loaded")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        print("[user-floor-addressing] WARNING: ModApiV1 is not available!")
        return
    end

    -- Validate format strings at load time
    local addr_fmt = config.address_format or "@f%d/usr%s"
    local dns_fmt = config.dns_format or "@f%d/dns"
    if not pcall(function() return string.format(addr_fmt, 1, "x") end) then
        print("[user-floor-addressing] WARNING: address_format invalid, will use default '@f%d/usr%s'")
    end
    if not pcall(function() return string.format(dns_fmt, 1) end) then
        print("[user-floor-addressing] WARNING: dns_format invalid, will use default '@f%d/dns'")
    end

    print(string.format("[user-floor-addressing] Config: RandomSuffix=%s, AddrFmt='%s', DNSFmt='%s'",
        tostring(config.use_random_suffix or false), addr_fmt, dns_fmt))
end

function on_mod_reload()
    print("[user-floor-addressing] Reloaded (F11)")
end

-- Track user count per floor to generate incremental addresses
local floor_user_counts = {}

---@param user User
function on_user_spawned(user)

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
    local address_format = config.address_format or "@f%d/usr%s"
    local dns_format = config.dns_format or "@f%d/dns"
    local fallback_dns_1 = config.fallback_dns_1 or "@srv/dns1"
    local fallback_dns_2 = config.fallback_dns_2 or "@srv/dns2"

    -- Determine the user suffix (incremental number or random 4-char string)
    local user_suffix
    if config.use_random_suffix then
        user_suffix = random_suffix(4)
    else
        user_suffix = tostring(user_increment)
    end

    -- Generate the network address based on configured format
    local network_address
    do
        local ok, result = pcall(function()
            return string.format(address_format, floor_num, user_suffix)
        end)
        if ok then
            network_address = result
        else
            print("[user-floor-addressing] WARNING: address_format mismatch -> " .. tostring(result) .. "; using default")
            network_address = string.format("@f%d/usr%s", floor_num, user_suffix)
        end
    end

    -- Set the network address
    networkctl.set_network_address(network_address)

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
    
    -- Format fallback DNS servers (supports %d placeholders)
    local fb_dns1, fb_dns2
    do
        local ok, result = pcall(function()
            return string.format(fallback_dns_1, floor_num)
        end)
        fb_dns1 = ok and result or fallback_dns_1
    end
    do
        local ok, result = pcall(function()
            return string.format(fallback_dns_2, floor_num)
        end)
        fb_dns2 = ok and result or fallback_dns_2
    end
    
    local success, err = pcall(function()
        local dns_array = Array.create()
        dns_array:append(dns1)
        dns_array:append(fb_dns1)
        dns_array:append(fb_dns2)
        networkctl.set_designated_dns_servers(dns_array)
    end)

    if success then
        if config.debug_logging then
            print(string.format("[user-floor-addressing] DNS set: %s, %s, %s", dns1, fb_dns1, fb_dns2))
        end
    else
        print("[user-floor-addressing] WARNING: Failed to set DNS servers: " .. tostring(err))
    end

    print(string.format("[user-floor-addressing] Floor %d user %d: addr=%s",
        floor_num, user_increment, network_address))
end
