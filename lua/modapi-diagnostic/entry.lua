-- ModAPI Diagnostic Tool
-- Comprehensive diagnostic and inspection tool for TNI game engine callbacks and API endpoints
-- Use this to debug mods and understand game object structures

print("=== ModAPI Diagnostic Tool v2.0 Loaded ===")

-- Load configuration
local config = {}
if Mod and Mod.config then
    config = Mod.config
    print("[DIAGNOSTIC] Configuration loaded:")
    print("  enable_device_logging = " .. tostring(config.enable_device_logging))
    print("  enable_user_logging = " .. tostring(config.enable_user_logging))
    print("  enable_day_events = " .. tostring(config.enable_day_events))
    print("  max_dump_depth = " .. tostring(config.max_dump_depth))
    print("  enable_network_inspection = " .. tostring(config.enable_network_inspection))
    print("  track_users_for_reinspection = " .. tostring(config.track_users_for_reinspection))
else
    print("[DIAGNOSTIC] No config found, using defaults")
    config.enable_device_logging = true
    config.enable_user_logging = true
    config.enable_day_events = true
    config.max_dump_depth = 2
    config.enable_network_inspection = true
    config.track_users_for_reinspection = true
    config.show_notification = true
end

-- Track spawned users for re-inspection
local spawned_users = {}
local inspection_counter = 0
local shift_r_pressed = false -- Track Shift+R key state to prevent repeated triggers
local shift_d_pressed = false -- Track Shift+D key state to prevent repeated triggers

-- Device class names for identification
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

-- Helper to safely get property
local function safe_get(obj, prop)
    local success, result = pcall(function() return obj[prop] end)
    if success then
        return result
    else
        return nil, result
    end
end

-- Helper function to dump detailed device info
local function dump_device_detailed(device, prefix)
    prefix = prefix or "  "

    print(prefix .. "product_name: " .. tostring(safe_get(device, "product_name")))
    print(prefix .. "device_hardware_class: " .. tostring(safe_get(device, "device_hardware_class")))
    print(prefix .. "base_cost_dollars: " .. tostring(safe_get(device, "base_cost_dollars")))
    print(prefix .. "base_warranty_days: " .. tostring(safe_get(device, "base_warranty_days")))
    print(prefix .. "base_warranty_cycles: " .. tostring(safe_get(device, "base_warranty_cycles")))

    local logic_controller = safe_get(device, "logic_controller")
    if logic_controller then
        print(prefix .. "logic_controller exists:")
        print(prefix .. "  installed_nbw: " .. tostring(safe_get(logic_controller, "installed_nbw")))
        print(prefix .. "  cpu_power: " .. tostring(safe_get(logic_controller, "cpu_power")))
        print(prefix .. "  installed_ram: " .. tostring(safe_get(logic_controller, "installed_ram")))
        print(prefix .. "  installed_storage: " .. tostring(safe_get(logic_controller, "installed_storage")))

        local networkctl = safe_get(logic_controller, "networkctl")
        if networkctl then
            print(prefix .. "  networkctl exists:")
            print(prefix .. "    network_address: " .. tostring(safe_get(networkctl, "network_address")))
            print(prefix .. "    hardware_address: " .. tostring(safe_get(networkctl, "hardware_address")))
        end
    else
        print(prefix .. "logic_controller: nil")
    end

    -- Try to find scene/template info
    local scene_path = safe_get(device, "filename")
    if scene_path then
        print(prefix .. "scene file: " .. tostring(scene_path))
    end
end

-- Helper function to safely dump table contents
local function dump_table(tbl, prefix, max_depth, current_depth)
    prefix = prefix or ""
    max_depth = max_depth or config.max_dump_depth or 2
    current_depth = current_depth or 0

    if current_depth >= max_depth then
        return
    end

    if type(tbl) ~= "table" and type(tbl) ~= "userdata" then
        print(prefix .. tostring(tbl) .. " (" .. type(tbl) .. ")")
        return
    end

    -- Handle userdata (Godot objects) differently
    if type(tbl) == "userdata" then
        print(prefix .. "<userdata: " .. tostring(tbl) .. ">")

        -- Try to get methods via metatable
        local mt = getmetatable(tbl)
        if mt and type(mt) == "table" then
            print(prefix .. "Metatable methods:")
            local method_count = 0
            for k, v in pairs(mt) do
                if type(v) == "function" and not k:match("^__") then
                    print(prefix .. "  " .. tostring(k) .. "()")
                    method_count = method_count + 1
                    if method_count >= 20 then
                        print(prefix .. "  ... (truncated, >20 methods)")
                        break
                    end
                end
            end
        else
            print(prefix .. "(userdata with no accessible metatable)")
        end
        return
    end

    -- Handle regular Lua tables
    local success, result = pcall(function()
        for k, v in pairs(tbl) do
            local key_str = tostring(k)
            local value_type = type(v)

            if value_type == "function" then
                print(prefix .. key_str .. " = <function>")
            elseif value_type == "table" then
                print(prefix .. key_str .. " = <table>")
                if current_depth < max_depth - 1 then
                    dump_table(v, prefix .. "  ", max_depth, current_depth + 1)
                end
            elseif value_type == "userdata" then
                print(prefix .. key_str .. " = <userdata: " .. tostring(v) .. ">")
            else
                print(prefix .. key_str .. " = " .. tostring(v) .. " (" .. value_type .. ")")
            end
        end
    end)

    if not success then
        print(prefix .. "<error iterating table: " .. tostring(result) .. ">")
    end
end

-- Helper to inspect DNS array in detail
local function inspect_dns_array(dns, prefix)
    prefix = prefix or "      "
    print(prefix .. "type = " .. type(dns))

    if not dns then
        print(prefix .. "<nil>")
        return
    end

    if type(dns) == "userdata" then
        print(prefix .. "Attempting to read as Godot Array...")

        -- Try size() method
        local success, size = pcall(function() return dns:size() end)
        if success and size then
            print(prefix .. "Array size() = " .. tostring(size))

            if size > 0 then
                print(prefix .. "Array contents:")
                for i = 0, size - 1 do
                    local val_success, val = pcall(function() return dns:get(i) end)
                    if val_success and val then
                        print(prefix .. "  [" .. i .. "] = " .. tostring(val))
                    end
                end
            else
                print(prefix .. "Array is empty (size = 0)")
            end
        else
            print(prefix .. "Could not get size: " .. tostring(size))
        end
    elseif type(dns) == "table" then
        print(prefix .. "Lua table contents:")
        for k, v in pairs(dns) do
            print(prefix .. "  [" .. tostring(k) .. "] = " .. tostring(v))
        end
    end
end

-- Function to inspect available scenes and their unlock status
local function inspect_available_scenes()
    print("\n[DIAGNOSTIC] ========== Available Scenes Inspection ==========")

    -- Try to get floor unlocks from settings/API
    if ModApiV1 then
        local success, settings = pcall(function() return ModApiV1.get_game_settings() end)
        if success and settings then
            print("[DIAGNOSTIC] ✓ Settings accessible")

            -- Check for floor_unlocks
            local floor_unlocks = safe_get(settings, "floor_unlocks")
            if floor_unlocks then
                print("[DIAGNOSTIC] Floor Unlocks:")
                dump_table(floor_unlocks, "[DIAGNOSTIC]   ", 1)
            else
                print("[DIAGNOSTIC] ✗ No floor_unlocks in settings")
            end

            -- Check for user_stampbook (discovered user types)
            local user_stampbook = safe_get(settings, "user_stampbook")
            if user_stampbook then
                print("[DIAGNOSTIC] User Stampbook (Discovered User Types):")
                local count = 0
                for scene_path, unlocked in pairs(user_stampbook) do
                    if unlocked then
                        count = count + 1
                        -- Extract just the filename for readability
                        local filename = scene_path:match("([^/]+)%.tscn$") or scene_path
                        print("[DIAGNOSTIC]   ✓ " .. filename)
                    end
                end
                print("[DIAGNOSTIC] Total discovered user types: " .. count)
            else
                print("[DIAGNOSTIC] ✗ No user_stampbook in settings")
            end
        else
            print("[DIAGNOSTIC] ✗ Could not access settings: " .. tostring(settings))
        end

        -- Try to get available scenes from world/catalog
        local world = ModApiV1.get_game_world()
        if world then
            -- Check for catalog or scene registry
            local catalog = safe_get(world, "catalog")
            if catalog then
                print("[DIAGNOSTIC] World Catalog:")
                dump_table(catalog, "[DIAGNOSTIC]   ", 2)
            end

            -- Check for available floors
            local locations = safe_get(world, "locations")
            if locations then
                print("[DIAGNOSTIC] World Locations:")
                if type(locations) == "table" then
                    for i, loc in ipairs(locations) do
                        local display_name = safe_get(loc, "display_name")
                        local floor_num = safe_get(loc, "floor_num")
                        local scene_path = safe_get(loc, "scene_file_path")
                        print("[DIAGNOSTIC]   Floor " .. tostring(floor_num) .. ": " .. tostring(display_name))
                        if scene_path then
                            print("[DIAGNOSTIC]     Scene: " .. tostring(scene_path))
                        end
                    end
                elseif type(locations) == "userdata" then
                    -- Try to iterate as Godot array
                    local size_success, size = pcall(function() return locations:size() end)
                    if size_success and size then
                        for i = 0, size - 1 do
                            local loc = safe_get(locations, i)
                            if loc then
                                local display_name = safe_get(loc, "display_name")
                                local floor_num = safe_get(loc, "floor_num")
                                print("[DIAGNOSTIC]   Floor " .. tostring(floor_num) .. ": " .. tostring(display_name))
                            end
                        end
                    end
                end
            end
        end
    else
        print("[DIAGNOSTIC] ✗ ModApiV1 not available")
    end

    print("[DIAGNOSTIC] ================================================\n")
end

-- Function to inspect a user's network configuration
local function inspect_user_network(user, context)
    if not config.enable_network_inspection then
        return
    end

    context = context or "unknown"
    inspection_counter = inspection_counter + 1

    print("\n[DIAGNOSTIC] ========== User Network Inspection #" ..
        inspection_counter .. " (" .. context .. ") ==========")

    local username = safe_get(user, "username")
    print("[DIAGNOSTIC] User: " .. tostring(username))

    local logic_controller = safe_get(user, "logic_controller")
    if not logic_controller then
        print("[DIAGNOSTIC] ✗ No logic_controller")
        return
    end

    local networkctl = safe_get(logic_controller, "networkctl")
    if not networkctl then
        print("[DIAGNOSTIC] ✗ No networkctl")
        return
    end

    print("[DIAGNOSTIC] Network Configuration:")
    print("[DIAGNOSTIC]   dhcp_enabled = " .. tostring(safe_get(networkctl, "dhcp_enabled")))
    print("[DIAGNOSTIC]   is_dhcp_enabled = " .. tostring(safe_get(networkctl, "is_dhcp_enabled")))
    print("[DIAGNOSTIC]   network_address = " .. tostring(safe_get(networkctl, "network_address")))
    print("[DIAGNOSTIC]   hardware_address = " .. tostring(safe_get(networkctl, "hardware_address")))

    local dns = safe_get(networkctl, "designated_dns_servers")
    print("[DIAGNOSTIC]   designated_dns_servers:")
    inspect_dns_array(dns, "[DIAGNOSTIC]     ")

    print("[DIAGNOSTIC] " .. string.rep("=", 60) .. "\n")
end

function on_engine_load()
    print("\n[DIAGNOSTIC] ========== on_engine_load() ==========")

    if ModApiV1 then
        print("[DIAGNOSTIC] ✓ ModApiV1 is available")
        print("[DIAGNOSTIC] ModApiV1 methods and properties:")
        dump_table(ModApiV1, "    ")

        local world = ModApiV1.get_game_world()
        if world then
            print("[DIAGNOSTIC] ✓ World exists in on_engine_load!")
            if world.play_options then
                print("[DIAGNOSTIC] ✓ PlayOptions accessible")
                print("[DIAGNOSTIC]   starting_cash = " .. tostring(world.play_options.starting_cash))
                print("[DIAGNOSTIC]   proposal_batch_size = " .. tostring(world.play_options.proposal_batch_size))
            end
        else
            print("[DIAGNOSTIC] ✗ World is nil in on_engine_load")
        end
    else
        print("[DIAGNOSTIC] ✗ ModApiV1 is NOT available")
    end

    if Mod then
        print("[DIAGNOSTIC] ✓ Mod global is available")
        dump_table(Mod, "    ", 1)
    end

    if Engine then
        print("[DIAGNOSTIC] ✓ Engine global is available")
    end

    print("[DIAGNOSTIC] ========================================\n")

    -- Inspect available scenes
    inspect_available_scenes()
end

function on_mod_reload()
    print("[DIAGNOSTIC] on_mod_reload() called - Mod was reloaded (F11)")
end

function on_device_spawned(device)
    if not config.enable_device_logging then
        return
    end

    print("\n[DIAGNOSTIC] ========== on_device_spawned() ==========")
    print("[DIAGNOSTIC] Device spawned:")
    print("[DIAGNOSTIC]   product_name = " .. tostring(device.product_name))
    print("[DIAGNOSTIC]   device_hardware_class = " .. tostring(device.device_hardware_class))

    if config.enable_network_inspection and device.logic_controller then
        print("[DIAGNOSTIC] ✓ Device has logic_controller")
        if device.logic_controller.networkctl then
            local netctl = device.logic_controller.networkctl
            print("[DIAGNOSTIC]   Network Configuration:")
            print("[DIAGNOSTIC]     dhcp_enabled = " .. tostring(netctl.dhcp_enabled))
            print("[DIAGNOSTIC]     is_dhcp_enabled = " .. tostring(netctl.is_dhcp_enabled))
            print("[DIAGNOSTIC]     network_address = " .. tostring(netctl.network_address))
            print("[DIAGNOSTIC]     hardware_address = " .. tostring(netctl.hardware_address))

            local dns = safe_get(netctl, "designated_dns_servers")
            if dns then
                print("[DIAGNOSTIC]     designated_dns_servers type = " .. type(dns))
                if type(dns) == "userdata" then
                    -- Try to iterate as array
                    local success, count = pcall(function() return #dns end)
                    if success then
                        print("[DIAGNOSTIC]     designated_dns_servers count = " .. tostring(count))
                        for i = 0, count - 1 do
                            local srv = safe_get(dns, i)
                            print("[DIAGNOSTIC]       [" .. i .. "] = " .. tostring(srv))
                        end
                    end
                end
            end
        end
    end

    print("[DIAGNOSTIC] =======================================\n")
end

function on_user_spawned(user)
    if not config.enable_user_logging then
        return
    end

    print("\n[DIAGNOSTIC] ========== on_user_spawned() ==========")

    -- Basic user info
    local username = safe_get(user, "username")
    local user_profile = safe_get(user, "user_profile_name")
    local daily_rate = safe_get(user, "daily_rate")

    print("[DIAGNOSTIC]   username = " .. tostring(username))
    print("[DIAGNOSTIC]   user_profile_name = " .. tostring(user_profile))
    print("[DIAGNOSTIC]   daily_rate = " .. tostring(daily_rate))

    -- Location info
    local location = safe_get(user, "location")
    if location then
        print("[DIAGNOSTIC] ✓ User has location")
        local floor_num = safe_get(location, "floor_num")
        local display_name = safe_get(location, "display_name")
        print("[DIAGNOSTIC]   floor_num = " .. tostring(floor_num))
        print("[DIAGNOSTIC]   display_name = " .. tostring(display_name))
    end

    print("[DIAGNOSTIC] =======================================\n")

    -- Store user for later re-inspection
    if config.track_users_for_reinspection then
        table.insert(spawned_users, { user = user, username = username })
    end

    -- Do initial network inspection
    inspect_user_network(user, "on_spawn")
end

-- Command to re-inspect all spawned users (useful after manual DNS changes)
function reinspect_all_users()
    print("\n[DIAGNOSTIC] ========== Re-inspecting All Users ==========")
    print("[DIAGNOSTIC] Total users tracked: " .. #spawned_users)

    for i, user_data in ipairs(spawned_users) do
        inspect_user_network(user_data.user, "manual_reinspection")
    end

    -- Show in-game notification if enabled
    if config.show_notification then
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui and base_ui.display_notification then
                -- tone_enum: 0 = neutral, 1 = positive, 2 = negative
                base_ui.display_notification(
                    string.format("Re-inspected %d users", #spawned_users),
                    0
                )
            end
        end)
    end
end

-- Command to manually inspect scenes
function inspect_scenes()
    inspect_available_scenes()
end

-- Function to dump all devices currently in the world
function dump_all_world_devices()
    print("\n[DIAGNOSTIC] ========== Dumping All World Devices ==========")

    if not ModApiV1 then
        print("[DIAGNOSTIC] ✗ ModApiV1 not available")
        return
    end

    local world = ModApiV1.get_game_world()
    if not world then
        print("[DIAGNOSTIC] ✗ World is nil")
        return
    end

    print("[DIAGNOSTIC] Searching for device collections in world...")

    -- Try different possible properties for device lists
    local device_sources = {
        "devices",
        "all_devices",
        "device_list",
        "spawned_devices",
        "active_devices"
    }

    for _, prop_name in ipairs(device_sources) do
        local devices = safe_get(world, prop_name)
        if devices then
            print("[DIAGNOSTIC] ✓ Found world." .. prop_name)

            if type(devices) == "table" then
                print("[DIAGNOSTIC] Device count: " .. #devices)
                for i, device in ipairs(devices) do
                    local product_name = safe_get(device, "product_name")
                    local hw_class = safe_get(device, "device_hardware_class")
                    local class_name = device_class_names[hw_class] or "unknown"
                    print(string.format("[DIAGNOSTIC]   [%d] %s (class=%d/%s)",
                        i, tostring(product_name), hw_class, class_name))

                    -- If it's a phone or CCTV, dump detailed info
                    if hw_class == 17 or hw_class == 16 then
                        print("[DIAGNOSTIC]     ⚠️ FOUND PHONE/CCTV - Detailed dump:")
                        dump_device_detailed(device, "      ")
                    end
                end
            elseif type(devices) == "userdata" then
                -- Try as Godot Array
                local size_success, size = pcall(function() return devices:size() end)
                if size_success and size then
                    print("[DIAGNOSTIC] Device count (Godot Array): " .. tostring(size))
                    for i = 0, size - 1 do
                        local device = safe_get(devices, i)
                        if device then
                            local product_name = safe_get(device, "product_name")
                            local hw_class = safe_get(device, "device_hardware_class")
                            local class_name = device_class_names[hw_class] or "unknown"
                            print(string.format("[DIAGNOSTIC]   [%d] %s (class=%d/%s)",
                                i, tostring(product_name), hw_class, class_name))

                            -- If it's a phone or CCTV, dump detailed info
                            if hw_class == 17 or hw_class == 16 then
                                print("[DIAGNOSTIC]     ⚠️ FOUND PHONE/CCTV - Detailed dump:")
                                dump_device_detailed(device, "      ")
                            end
                        end
                    end
                else
                    print("[DIAGNOSTIC]   Could not get size of userdata")
                end
            end

            print("[DIAGNOSTIC] " .. string.rep("=", 60))
            return -- Found devices, exit
        end
    end

    print("[DIAGNOSTIC] ✗ No device collection found in world")
    print("[DIAGNOSTIC] World properties:")
    dump_table(world, "[DIAGNOSTIC]   ", 1)

    print("[DIAGNOSTIC] " .. string.rep("=", 60) .. "\n")

    -- Show in-game notification if enabled
    if config.show_notification then
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui and base_ui.display_notification then
                -- tone_enum: 0 = neutral, 1 = positive, 2 = negative
                base_ui.display_notification("Device dump complete", 0)
            end
        end)
    end
end

function on_day_start()
    if config.enable_day_events then
        print("[DIAGNOSTIC] on_day_start() - New day started")
    end
end

function on_day_end()
    if config.enable_day_events then
        print("[DIAGNOSTIC] on_day_end() - Day ended")
    end
end

function on_tick(delta)
    -- Silent - would spam too much
end

-- Experimental callbacks
function on_world_ready(world)
    print("[DIAGNOSTIC] on_world_ready() called")
end

function on_world_created(world)
    print("[DIAGNOSTIC] on_world_created() called")
end

function on_game_start(world)
    print("[DIAGNOSTIC] on_game_start() called")
end

function on_scenario_start(world)
    print("[DIAGNOSTIC] on_scenario_start() called")
end

-- Keyboard input handler for Shift+R shortcut
function on_player_input(event)
    -- Check if this is a keyboard event
    local event_class = nil
    pcall(function() event_class = event:get_class() end)

    if event_class == "InputEventKey" then
        -- Get keycode and check if it's the R key (ASCII 82)
        local keycode = nil
        local is_pressed = false
        local is_shift = false

        pcall(function() keycode = event:get_keycode() end)
        pcall(function() is_pressed = event:is_pressed() end)
        pcall(function() is_shift = event:is_shift_pressed() end)

        -- Shift+R combination (82 is the keycode for 'R')
        if keycode == 82 and is_shift then
            if is_pressed and not shift_r_pressed then
                -- Key was just pressed down
                shift_r_pressed = true
                print("[DIAGNOSTIC] Shift+R detected - Running reinspect_all_users()...")
                reinspect_all_users()
            elseif not is_pressed and shift_r_pressed then
                -- Key was released
                shift_r_pressed = false
            end
        end

        -- Shift+D combination (68 is the keycode for 'D')
        if keycode == 68 and is_shift then
            if is_pressed and not shift_d_pressed then
                -- Key was just pressed down
                shift_d_pressed = true
                print("[DIAGNOSTIC] Shift+D detected - Running dump_all_world_devices()...")
                dump_all_world_devices()
            elseif not is_pressed and shift_d_pressed then
                -- Key was released
                shift_d_pressed = false
            end
        end
    end
end

print("=== ModAPI Diagnostic Tool Setup Complete ===")
print("    This tool will log detailed information about:")
print("    - Engine load events")
print("    - Device spawns (with network config)")
print("    - User spawns (with full network/DNS inspection)")
print("    - Day start/end events")
print("    - Available scenes (floors, users) and unlock status")
print("")
print("    Keyboard Shortcuts:")
print("    - Shift+R: Re-inspect all spawned users")
print("    - Shift+D: Dump all devices in the world (finds phones/CCTV)")
print("")
print("    Lua console commands:")
print("    - reinspect_all_users()")
print("    - dump_all_world_devices()")
print("    - inspect_scenes()")
print("===")
