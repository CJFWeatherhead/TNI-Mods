-- Random Drops Mod
-- Purpose: Adds randomness to game spawning with three configurable modifiers.
-- Author: CJFWeatherhead
-- Version: 0.1.0
-- Description: This mod provides three features:
--              1. Periodically spawns random items/devices at configurable intervals
--              2. Adds extra random users when a floor is created
--              3. Multiplies purchased items from the shop (duplicates on purchase)
-- Usage: Configure each feature independently in Mod Manager. All features can be toggled on/off.
-- Notes: Uses on_device_spawned, on_user_spawned, on_location_spawned, and on_tick callbacks.

local mod_id = "random-drops"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Feature 1: Random Item Spawning
    enable_random_spawns = true,
    spawn_interval_seconds = 60,
    spawn_count_min = 1,
    spawn_count_max = 3,
    spawn_all_items = true,       -- If false, use subset defined below
    spawn_switches = true,
    spawn_routers = true,
    spawn_firewalls = true,
    spawn_servers = true,
    spawn_workstations = false,
    spawn_misc = false,

    -- Feature 2: Extra Users on Floor Creation
    enable_extra_users = true,
    extra_users_min = 1,
    extra_users_max = 3,

    -- Feature 3: Purchase Multiplier (Duplicates)
    enable_purchase_multiplier = true,
    purchase_multiplier = 2,      -- Number of total items (1 = normal, 2 = double, etc.)

    -- General settings
    debug_logging = true
}

-- ===== MOD CONFIGURATION END =====

-- Track time for periodic spawning
local time_since_last_spawn = 0
local world_ref = nil

-- Track recently spawned devices to detect player purchases (for multiplier)
-- Format: { [device_id] = { device = device_ref, time = spawn_time, processed = bool } }
local recent_spawns = {}
local PURCHASE_DETECTION_WINDOW = 2.0  -- Seconds to track new spawns

-- Track devices we've already processed (to prevent infinite loops)
local processed_devices = {}

-- Device class mapping
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

-- Helper function to safely get property
local function safe_get(obj, prop)
    local success, result = pcall(function() return obj[prop] end)
    if success then
        return result
    else
        return nil
    end
end

-- Log function that respects debug setting
local function log(message)
    if config.debug_logging then
        print("[random-drops] " .. message)
    end
end

-- Log function for important messages (always shown)
local function log_important(message)
    print("[random-drops] " .. message)
end

-- Check if a device class should be spawned based on config
local function should_spawn_device_class(device_class)
    if config.spawn_all_items then
        return true
    end

    -- Map device classes to config flags
    if device_class == 1 then -- network_switch
        return config.spawn_switches
    elseif device_class == 2 then -- network_router
        return config.spawn_routers
    elseif device_class == 4 then -- network_firewall
        return config.spawn_firewalls
    elseif device_class == 7 then -- compute_server
        return config.spawn_servers
    elseif device_class == 8 then -- display_monitor (workstation)
        return config.spawn_workstations
    else
        return config.spawn_misc
    end
end

-- Get list of available device listings from merchants
local function get_available_device_listings()
    local listings_list = {}

    if not world_ref then
        log("get_available_device_listings: world_ref is nil")
        return listings_list
    end

    -- Try to get device merchants
    local merchants = safe_get(world_ref, "device_merchants")
    if not merchants then
        log("Could not access device_merchants")
        return listings_list
    end

    -- Debug: Check type of merchants
    log(string.format("device_merchants type: %s", type(merchants)))

    -- Try to iterate merchants as Godot Array
    local merchant_count = 0
    local success, size = pcall(function() return merchants:size() end)
    if success and size then
        merchant_count = size
        log(string.format("Found %d merchants", merchant_count))

        for i = 0, size - 1 do
            local merchant = nil
            pcall(function() merchant = merchants:get(i) end)
            if merchant then
                local merchant_name = safe_get(merchant, "display_name") or "Unknown"
                log(string.format("  Merchant %d: %s", i, merchant_name))

                -- Try to get listings from merchant
                local listings = safe_get(merchant, "listings")
                if listings then
                    local listings_size = 0
                    pcall(function() listings_size = listings:size() end)
                    log(string.format("    %d listings available", listings_size))

                    for j = 0, listings_size - 1 do
                        local listing = nil
                        pcall(function() listing = listings:get(j) end)
                        if listing then
                            local device_scn = safe_get(listing, "device_scn")
                            local listing_title = safe_get(listing, "listing_title") or "Unknown"
                            local price = safe_get(listing, "price") or 0
                            local stock = safe_get(listing, "stock") or 0
                            local available = safe_get(listing, "available")

                            log(string.format("      [%d] %s - $%d, stock: %d, available: %s (type: %s), has_scene: %s",
                                j, listing_title, price, stock, tostring(available), type(available), tostring(device_scn ~= nil)))

                            -- Note: stock can be 0 for unlimited items - destock() will handle it
                            -- Only check that the listing has a device scene
                            -- available might be boolean, nil, or other type - consider nil/true as available
                            local is_available = (available == nil or available == true)
                            if device_scn and is_available then
                                table.insert(listings_list, {
                                    listing = listing,
                                    merchant = merchant,
                                    title = listing_title,
                                    price = price,
                                    device_scn = device_scn
                                })
                                log(string.format("        -> ADDED to available listings"))
                            else
                                log(string.format("        -> SKIPPED (scene: %s, available check: %s)",
                                    tostring(device_scn ~= nil), tostring(is_available)))
                            end
                        end
                    end
                else
                    log("    No listings property")
                end
            end
        end
    else
        log("Could not get merchant count")
    end

    log(string.format("Total available listings: %d", #listings_list))
    return listings_list
end

-- Get list of available user scenes from a location
-- NOTE: This feature is currently not possible - all_possible_users contains
-- display names (strings) not PackedScenes, and ResourceLoader is sandbox-blocked
local extra_users_warning_shown = false

local function get_available_user_scenes(target_location)
    local scenes = {}

    if not world_ref then
        log("get_available_user_scenes: world_ref is nil")
        return scenes
    end

    -- If no target location, try to get from first location
    local location = target_location
    if not location then
        local locations = safe_get(world_ref, "locations")
        if not locations then
            log("get_available_user_scenes: No locations in world")
            return scenes
        end

        local success, size = pcall(function() return locations:size() end)
        if success and size and size > 0 then
            pcall(function() location = locations:get(0) end)
        end
    end

    if not location then
        log("get_available_user_scenes: Could not get any location")
        return scenes
    end

    -- Get all_possible_users from location
    local all_users = safe_get(location, "all_possible_users")
    if not all_users then
        log("get_available_user_scenes: Location has no all_possible_users")
        return scenes
    end

    -- Check what we have - the API returns user type names, not PackedScenes
    local success, size = pcall(function() return all_users:size() end)
    if success and size and size > 0 then
        local first_item = nil
        pcall(function() first_item = all_users:get(0) end)
        
        -- If first item is a string, this API returns names not scenes
        if type(first_item) == "string" then
            if not extra_users_warning_shown then
                log_important("Extra users feature unavailable: all_possible_users contains user type names, not spawnable scenes")
                log_important("This is a mod API limitation - user spawning requires features not exposed to mods")
                extra_users_warning_shown = true
            end
            return scenes
        end
        
        -- If we get here, it might be PackedScenes
        for i = 0, size - 1 do
            local user_scene = nil
            pcall(function() user_scene = all_users:get(i) end)
            if user_scene and type(user_scene) == "userdata" then
                local can_inst = false
                pcall(function() can_inst = user_scene:can_instantiate() end)
                if can_inst then
                    table.insert(scenes, user_scene)
                end
            end
        end
    end

    return scenes
end

-- Attempt to spawn a random device using the merchant system
local function spawn_random_device()
    if not world_ref then
        log("Cannot spawn device: world_ref is nil")
        return false
    end

    local listings = get_available_device_listings()
    if #listings == 0 then
        log("No available device listings to spawn")
        return false
    end

    -- Pick a random listing
    local selected = listings[math.random(1, #listings)]

    log(string.format("Attempting to spawn device: %s ($%d, stock: %d)",
        selected.title, selected.price, safe_get(selected.listing, "stock") or 0))

    -- Method 1: Use DeviceListing.destock(n) - returns Array<Node2D> of spawned devices!
    local spawn_success = false
    pcall(function()
        if selected.listing and selected.listing.destock then
            local spawned_devices = selected.listing:destock(1)
            if spawned_devices then
                -- Check if we got any devices back
                local count = 0
                pcall(function() count = spawned_devices:size() end)
                if count and count > 0 then
                    spawn_success = true
                    log(string.format("Device spawned via destock: %s (got %d items)", selected.title, count))
                else
                    log("destock returned empty array")
                end
            else
                log("destock returned nil")
            end
        else
            log("listing.destock not available")
        end
    end)

    if spawn_success then
        return true
    end

    -- Method 2: Try merchant.submit_order() as fallback
    pcall(function()
        if selected.merchant and selected.merchant.submit_order then
            -- Create order list (array with the listing)
            local delivery_floor = 0
            local result = selected.merchant:submit_order({ selected.listing }, delivery_floor)
            if result then
                spawn_success = true
                log(string.format("Device ordered via merchant.submit_order: %s", selected.title))
            end
        end
    end)

    if spawn_success then
        return true
    end

    log("Could not spawn device - no API method succeeded")
    return false
end

-- Attempt to spawn extra users on a location
-- NOTE: This feature is not currently possible due to API limitations
local function spawn_extra_users_on_location(location)
    if not location then
        return 0
    end

    local user_scenes = get_available_user_scenes(location)
    if #user_scenes == 0 then
        -- Warning already shown in get_available_user_scenes
        return 0
    end

    -- If we somehow get valid scenes, try to spawn them
    local min_users = config.extra_users_min or 1
    local max_users = config.extra_users_max or 3
    local users_to_spawn = math.random(min_users, max_users)
    local spawned_count = 0

    for i = 1, users_to_spawn do
        local selected = user_scenes[math.random(1, #user_scenes)]
        local spawn_success = false

        pcall(function()
            local user_instance = selected:instantiate()
            if user_instance then
                pcall(function() user_instance.location = location end)
                pcall(function()
                    location:add_child(user_instance)
                    spawn_success = true
                end)
                if spawn_success then
                    pcall(function()
                        if user_instance.finish_setup then
                            user_instance:finish_setup()
                        end
                    end)
                end
            end
        end)

        if spawn_success then
            spawned_count = spawned_count + 1
        end
    end

    return spawned_count
end

function on_engine_load()
    log_important("Random Drops mod loaded!")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        log_important("ModApiV1 is not available!")
        return
    end

    -- Get world reference
    world_ref = ModApiV1.get_game_world()

    -- Log current configuration
    local features_enabled = {}
    if config.enable_random_spawns then
        table.insert(features_enabled, string.format("RandomSpawns(every %ds, %d-%d items)",
            config.spawn_interval_seconds,
            config.spawn_count_min,
            config.spawn_count_max))
    end
    if config.enable_extra_users then
        table.insert(features_enabled, string.format("ExtraUsers(%d-%d per floor)",
            config.extra_users_min,
            config.extra_users_max))
    end
    if config.enable_purchase_multiplier then
        table.insert(features_enabled, string.format("PurchaseMultiplier(x%d)",
            config.purchase_multiplier))
    end

    if #features_enabled > 0 then
        log_important("Active features: " .. table.concat(features_enabled, ", "))
    else
        log_important("No features enabled")
    end
end

function on_mod_reload()
    log_important("Mod reloaded (F11)")
    world_ref = ModApiV1.get_game_world()

    -- Reset timers
    time_since_last_spawn = 0
end

-- Track spawned devices for purchase multiplier
local spawn_tracking = {}

---@param device DeviceUnit
function on_device_spawned(device)
    -- Update world reference if needed
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end

    -- Feature 3: Purchase Multiplier
    if config.enable_purchase_multiplier then
        local multiplier = config.purchase_multiplier or 2

        -- Only process if multiplier > 1
        if multiplier > 1 then
            -- Track this spawn
            local device_name = safe_get(device, "product_name") or "Unknown"
            local device_price = safe_get(device, "price") or 0

            -- Create a unique identifier for this device
            local device_id = tostring(device)

            -- Check if this device was already processed (to prevent infinite loops)
            if processed_devices[device_id] then
                log(string.format("Skipping already-processed device: %s", device_name))
                return
            end

            -- Mark as processed
            processed_devices[device_id] = true

            log(string.format("Device purchased: %s (price: %d)", device_name, device_price))

            -- Try to find the listing for this device to spawn duplicates
            local listings = get_available_device_listings()
            local matching_listing = nil

            log(string.format("Searching for matching listing among %d available...", #listings))
            for _, listing_info in ipairs(listings) do
                -- Try exact match first, then contains match
                if listing_info.title == device_name then
                    matching_listing = listing_info
                    log(string.format("Found exact match: %s from %s", listing_info.title, safe_get(listing_info.merchant, "display_name") or "Unknown"))
                    break
                end
            end

            -- If no exact match, try partial match
            if not matching_listing then
                for _, listing_info in ipairs(listings) do
                    if string.find(listing_info.title, device_name, 1, true) or
                       string.find(device_name, listing_info.title, 1, true) then
                        matching_listing = listing_info
                        log(string.format("Found partial match: %s (searching for %s)", listing_info.title, device_name))
                        break
                    end
                end
            end

            if matching_listing then
                -- Spawn duplicates
                local duplicates_spawned = 0
                for i = 2, multiplier do
                    local dup_success = false

                    -- Method 1: Try direct instantiation of device_scn
                    pcall(function()
                        if matching_listing.device_scn then
                            log(string.format("Attempting direct instantiation for duplicate %d...", i - 1))
                            local can_inst = matching_listing.device_scn:can_instantiate()
                            log(string.format("device_scn can_instantiate: %s", tostring(can_inst)))
                            
                            if can_inst then
                                local new_device = matching_listing.device_scn:instantiate()
                                if new_device then
                                    log(string.format("Instantiated device: %s (type: %s)", tostring(new_device), type(new_device)))
                                    
                                    -- Set warranty from listing
                                    pcall(function()
                                        if matching_listing.listing then
                                            local warranty = safe_get(matching_listing.listing, "warranty_period") or 0
                                            new_device.warranty_period_remaining = warranty
                                        end
                                    end)
                                    
                                    -- Set position near the original device
                                    pcall(function()
                                        local orig_pos = device.global_position
                                        if orig_pos then
                                            -- Offset each duplicate slightly (50 pixels per duplicate)
                                            local offset_x = 50 * (i - 1)
                                            local offset_y = 30 * (i - 1)
                                            new_device.global_position.x = orig_pos.x + offset_x
                                            new_device.global_position.y = orig_pos.y + offset_y
                                            log(string.format("Set position to (%d, %d)", orig_pos.x + offset_x, orig_pos.y + offset_y))
                                        else
                                            log("Could not get original device position")
                                        end
                                    end)
                                    
                                    -- Set the floor number to match the original device
                                    pcall(function()
                                        local floor_num = safe_get(device, "current_floor_num")
                                        if floor_num then
                                            new_device.current_floor_num = floor_num
                                        end
                                    end)
                                    
                                    -- Add to the world's device_unit_nodes using call_deferred
                                    -- This is important for RigidBody2D to avoid physics server conflicts
                                    if world_ref and world_ref.device_unit_nodes then
                                        -- Try call_deferred first (safer for physics bodies)
                                        local add_success = false
                                        pcall(function()
                                            world_ref.device_unit_nodes:call_deferred("add_child", new_device)
                                            add_success = true
                                        end)
                                        
                                        if not add_success then
                                            -- Fallback to direct add_child
                                            pcall(function()
                                                world_ref.device_unit_nodes:add_child(new_device)
                                                add_success = true
                                            end)
                                        end
                                        
                                        if add_success then
                                            dup_success = true
                                            log(string.format("Duplicate %d added to device_unit_nodes", i - 1))
                                            
                                            -- Mark as processed
                                            processed_devices[tostring(new_device)] = true
                                            
                                            -- Call apply_autoconfig if available
                                            pcall(function()
                                                if new_device.apply_autoconfig then
                                                    new_device:apply_autoconfig()
                                                end
                                            end)
                                        end
                                    else
                                        log("world_ref.device_unit_nodes not available")
                                    end
                                else
                                    log("instantiate() returned nil")
                                end
                            end
                        else
                            log("matching_listing.device_scn is nil")
                        end
                    end)

                    -- Method 2: Try destock() as fallback
                    if not dup_success then
                        pcall(function()
                            if matching_listing.listing and matching_listing.listing.destock then
                                log(string.format("Trying destock fallback for duplicate %d...", i - 1))
                                local spawned = matching_listing.listing:destock(1)
                                if spawned then
                                    local count = 0
                                    pcall(function() count = spawned:size() end)
                                    if count and count > 0 then
                                        dup_success = true
                                        for j = 0, count - 1 do
                                            local spawned_device = nil
                                            pcall(function() spawned_device = spawned:get(j) end)
                                            if spawned_device then
                                                processed_devices[tostring(spawned_device)] = true
                                            end
                                        end
                                        log(string.format("Duplicate %d spawned via destock", i - 1))
                                    end
                                end
                            end
                        end)
                    end

                    -- Method 3: Try submit_order as last resort
                    if not dup_success then
                        pcall(function()
                            if matching_listing.merchant and matching_listing.merchant.submit_order then
                                log("Trying submit_order fallback...")
                                local delivery_floor = safe_get(device, "current_floor_num") or 0
                                local order_array = Array.create()
                                order_array:append(matching_listing.listing)
                                local result = matching_listing.merchant:submit_order(order_array, delivery_floor)
                                if result then
                                    dup_success = true
                                    log(string.format("Duplicate %d ordered via submit_order", i - 1))
                                end
                            end
                        end)
                    end

                    if dup_success then
                        duplicates_spawned = duplicates_spawned + 1
                    else
                        log(string.format("Failed to spawn duplicate %d", i - 1))
                    end
                end

                if duplicates_spawned > 0 then
                    log_important(string.format("Spawned %d duplicate(s) of %s", duplicates_spawned, device_name))
                else
                    log(string.format("Could not spawn duplicates for %s - out of stock or API not available", device_name))
                end
            else
                log(string.format("No matching listing found for %s - cannot duplicate", device_name))
            end
        end
    end
end

---@param user User
function on_user_spawned(user)
    -- Update world reference if needed
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end

    local username = safe_get(user, "username") or "Unknown"
    local floor_num = nil

    -- Try to get floor number from user's location
    local location = safe_get(user, "location")
    if location then
        floor_num = safe_get(location, "floor_num")
    end

    log(string.format("User spawned: %s on floor %s",
        username, tostring(floor_num)))
end

---@param location Location
function on_location_spawned(location)
    -- Update world reference if needed
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
    end

    local floor_num = safe_get(location, "floor_num") or "?"
    local display_name = safe_get(location, "display_name") or "Unknown"

    log(string.format("Location spawned: %s (Floor %s)", display_name, tostring(floor_num)))

    -- Feature 2: Extra Users on Floor Creation
    if config.enable_extra_users then
        local min_users = config.extra_users_min or 1
        local max_users = config.extra_users_max or 3
        local users_to_add = math.random(min_users, max_users)

        log(string.format("Attempting to add %d extra users to floor %s", users_to_add, tostring(floor_num)))

        local spawned = spawn_extra_users_on_location(location)
        if spawned > 0 then
            log_important(string.format("Added %d extra users to floor %s", spawned, tostring(floor_num)))
        else
            log(string.format("Extra users feature active but spawn API not available for floor %s", tostring(floor_num)))
        end
    end
end

function on_tick(delta)
    -- Update world reference if needed
    if not world_ref then
        world_ref = ModApiV1.get_game_world()
        if not world_ref then
            return
        end
    end

    -- Feature 1: Random Item Spawning at intervals
    if config.enable_random_spawns then
        time_since_last_spawn = time_since_last_spawn + delta

        local interval = config.spawn_interval_seconds or 60

        if time_since_last_spawn >= interval then
            time_since_last_spawn = 0

            local min_count = config.spawn_count_min or 1
            local max_count = config.spawn_count_max or 3
            local spawn_count = math.random(min_count, max_count)

            log(string.format("Random spawn triggered: attempting to spawn %d items", spawn_count))

            local success_count = 0
            for i = 1, spawn_count do
                if spawn_random_device() then
                    success_count = success_count + 1
                end
            end

            if success_count > 0 then
                log_important(string.format("Spawned %d random items", success_count))
            else
                log("Random spawn interval elapsed but spawn API not fully available")
            end
        end
    end

    -- Clean up old spawn tracking entries (for purchase multiplier)
    local current_time = os.clock()
    for id, entry in pairs(spawn_tracking) do
        if current_time - entry.time > PURCHASE_DETECTION_WINDOW then
            spawn_tracking[id] = nil
        end
    end

    -- Periodically clean up processed_devices table to prevent memory growth
    -- (every ~60 seconds, clear entries older than 5 minutes)
    if time_since_last_spawn < delta then  -- Reset just happened
        local count = 0
        for _ in pairs(processed_devices) do count = count + 1 end
        if count > 100 then
            log(string.format("Clearing processed_devices table (%d entries)", count))
            processed_devices = {}
        end
    end
end

function on_day_start()
    log("New day started")
end

function on_day_end()
    log("Day ended")
end
