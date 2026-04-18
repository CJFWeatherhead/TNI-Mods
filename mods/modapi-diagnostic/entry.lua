-- ModAPI Diagnostic Tool v3.0
-- Comprehensive diagnostic, JSON export, and API test suite for TNI game engine
-- Features: JSON export (Shift+J), API test suite (Shift+Q), device/user inspection
-- Use this to debug mods, understand game object structures, and export game state

print("=== ModAPI Diagnostic Tool v3.0 Loaded ===")

-- ===== MOD CONFIGURATION START =====
local config = {}
if Mod and Mod.config then
    config = Mod.config
    print("[DIAGNOSTIC] Configuration loaded from mod config")
else
    print("[DIAGNOSTIC] No config found, using defaults")
    -- Logging Options
    config.enable_device_logging = true
    config.enable_user_logging = true
    config.enable_day_events = true
    config.enable_loan_events = true
    config.enable_transaction_events = true
    
    -- Network Inspection
    config.enable_network_inspection = true
    config.track_users_for_reinspection = true
    
    -- JSON Export Options
    config.json_export_enabled = true
    config.json_include_devices = true
    config.json_include_users = true
    config.json_include_locations = true
    config.json_include_finances = true
    config.json_include_network = true
    config.json_include_play_options = true
    config.json_include_statistics = true
    config.json_include_loans = true
    config.json_include_hostings = true
    config.json_include_merchants = true
    config.json_include_programs = true
    
    -- API Test Suite Options
    config.test_suite_enabled = true
    config.test_mod_api = true
    config.test_game_world = true
    config.test_devices_api = true
    config.test_users_api = true
    config.test_network_api = true
    config.test_filesystem_api = true
    
    -- Advanced
    config.max_dump_depth = 2
    config.show_notification = true
    config.verbose_mode = false
end
-- ===== MOD CONFIGURATION END =====

-- Track spawned objects for re-inspection
local spawned_users = {}
local spawned_devices = {}
local inspection_counter = 0

-- Key state tracking to prevent repeated triggers
local key_states = {
    shift_r = false,
    shift_d = false,
    shift_j = false,
    shift_q = false
}

-- API Test Results storage
local test_results = {
    timestamp = nil,
    tests = {},
    summary = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0
    }
}

-- Device class names for identification
local device_class_names = {
    [0] = "DEFAULT",
    [1] = "NETWORK_SWITCH",
    [2] = "NETWORK_ROUTER",
    [3] = "NETWORK_TAP",
    [4] = "NETWORK_FIREWALL",
    [5] = "MEDIA_LINE_SIMPLEX",
    [6] = "MEDIA_LINE_DUPLEX",
    [7] = "COMPUTE_SERVER",
    [8] = "DISPLAY_MONITOR",
    [9] = "DEBUGGER",
    [10] = "LOAD_TESTER",
    [11] = "POWER_EXPANSION",
    [12] = "DECENTRO_RIGS",
    [13] = "SURGE_PROTECTOR",
    [14] = "UPS",
    [15] = "INERT",
    [16] = "CCTV",
    [17] = "PHONE",
    [18] = "PRINTER",
    [19] = "NETWORK_LOAD_BALANCER"
}

-- Transaction category names
local transaction_categories = {
    [0] = "UNKNOWN",
    [1] = "INCOME",
    [2] = "CAPEX",
    [3] = "OPEX",
    [4] = "PETTY",
    [5] = "LOAN",
    [6] = "INTEREST",
    [7] = "INVESTMENT",
    [8] = "DONATION",
    [9] = "PROPOSAL_PROCESSING",
    [10] = "TRADING",
    [11] = "AGGREGATED",
    [12] = "PENALTY"
}

-- Statistics stat names
local stat_names = {
    [0] = "TOTAL_SERVICE_FLOORS",
    [1] = "TOTAL_DATACENTERS",
    [2] = "TOTAL_USERS",
    [3] = "USER_MAJORITY",
    [4] = "DAILY_SAT_AVG",
    [5] = "DAILY_INCOME_AVG",
    [6] = "TOTAL_SCHEDULED_OUTAGES_EXP",
    [7] = "TOTAL_UNSCHEDULED_OUTAGES_EXP",
    [8] = "TOTAL_SURGES_EXP",
    [9] = "TOTAL_DEVS_FAILED",
    [10] = "TOTAL_LOANS_TAKEN",
    [11] = "TOTAL_DAYS_IN_DEBT",
    [12] = "TOTAL_PROPOSALS_SUBMITTED",
    [13] = "TOTAL_COFFEE_DRANK",
    [14] = "TOTAL_TEA_DRANK",
    [15] = "TOTAL_NETWORK_OUTAGES_SCHEDULED",
    [16] = "TOTAL_DEVS_SURGED",
    [17] = "TOTAL_CYBERATTACKS_ENCOUNTERED"
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Helper to safely get property
local function safe_get(obj, prop)
    if obj == nil then return nil end
    local success, result = pcall(function() return obj[prop] end)
    if success then
        return result
    else
        return nil
    end
end

-- Helper to safely call method with no arguments
local function safe_call(obj, method)
    if obj == nil then return nil, "object is nil" end
    local success, result = pcall(function() return obj[method](obj) end)
    if success then
        return result, nil
    else
        return nil, result
    end
end

-- Convert Godot Array to Lua table
local function array_to_table(arr)
    if arr == nil then return nil end
    local result = {}
    
    if type(arr) == "table" then
        return arr
    end
    
    if type(arr) == "userdata" then
        local size_success, size = pcall(function() return arr:size() end)
        if size_success and size then
            for i = 0, size - 1 do
                local val_success, val = pcall(function() return arr:get(i) end)
                if val_success then
                    result[i + 1] = val
                end
            end
        end
    end
    
    return result
end

-- ============================================================================
-- JSON SERIALIZATION
-- ============================================================================

local function escape_json_string(s)
    if type(s) ~= "string" then return tostring(s) end
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"', '\\"')
    s = s:gsub('\n', '\\n')
    s = s:gsub('\r', '\\r')
    s = s:gsub('\t', '\\t')
    return s
end

local function to_json(value, indent, current_depth)
    indent = indent or 2
    current_depth = current_depth or 0
    local max_depth = config.max_dump_depth or 3
    
    if current_depth > max_depth then
        return '"<max depth exceeded>"'
    end
    
    local spaces = string.rep(" ", indent * current_depth)
    local next_spaces = string.rep(" ", indent * (current_depth + 1))
    
    if value == nil then
        return "null"
    end
    
    local t = type(value)
    
    if t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        if value ~= value then -- NaN check
            return "null"
        elseif value == math.huge or value == -math.huge then
            return "null"
        end
        return tostring(value)
    elseif t == "string" then
        return '"' .. escape_json_string(value) .. '"'
    elseif t == "table" then
        -- Check if array or object
        local is_array = true
        local max_idx = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                is_array = false
                break
            end
            if k > max_idx then max_idx = k end
        end
        
        if is_array and max_idx > 0 then
            local items = {}
            for i = 1, max_idx do
                items[i] = next_spaces .. to_json(value[i], indent, current_depth + 1)
            end
            return "[\n" .. table.concat(items, ",\n") .. "\n" .. spaces .. "]"
        else
            local items = {}
            for k, v in pairs(value) do
                local key = type(k) == "string" and k or tostring(k)
                table.insert(items, next_spaces .. '"' .. escape_json_string(key) .. '": ' .. to_json(v, indent, current_depth + 1))
            end
            if #items == 0 then
                return "{}"
            end
            return "{\n" .. table.concat(items, ",\n") .. "\n" .. spaces .. "}"
        end
    elseif t == "userdata" then
        return '"<userdata: ' .. escape_json_string(tostring(value)) .. '>"'
    elseif t == "function" then
        return '"<function>"'
    else
        return '"<' .. t .. '>"'
    end
end

-- ============================================================================
-- DATA EXTRACTION FUNCTIONS
-- ============================================================================

local function extract_device_data(device)
    if not device then return nil end
    
    local data = {
        product_name = safe_get(device, "product_name"),
        description = safe_get(device, "description"),
        device_hardware_class = safe_get(device, "device_hardware_class"),
        device_hardware_class_name = device_class_names[safe_get(device, "device_hardware_class")] or "UNKNOWN",
        price = safe_get(device, "price"),
        base_warranty_days = safe_get(device, "base_warranty_days"),
        warranty_period_remaining = safe_get(device, "warranty_period_remaining"),
        condition = safe_get(device, "condition"),
        current_floor_num = safe_get(device, "current_floor_num"),
        bw_per_second = safe_get(device, "bw_per_second"),
        reliability_flt = safe_get(device, "reliability_flt"),
        auto_servicing_enabled = safe_get(device, "auto_servicing_enabled"),
        custom_user_note = safe_get(device, "custom_user_note"),
        obtained_from = safe_get(device, "obtained_from"),
        asset_registration_day = safe_get(device, "asset_registration_day")
    }
    
    -- Logic Controller info
    local logic_controller = safe_get(device, "logic_controller")
    if logic_controller then
        data.logic_controller = {
            hardware_address = safe_get(logic_controller, "hardware_address"),
            network_address = safe_get(logic_controller, "network_address"),
            installed_cpu = safe_get(logic_controller, "installed_cpu"),
            installed_mem = safe_get(logic_controller, "installed_mem"),
            installed_sto = safe_get(logic_controller, "installed_sto"),
            installed_nbw = safe_get(logic_controller, "installed_nbw"),
            power_load = safe_get(logic_controller, "power_load"),
            os_running = safe_get(logic_controller, "os_running"),
            cpu_load = safe_get(logic_controller, "cpu_load"),
            free_memory = safe_get(logic_controller, "free_memory"),
            free_storage = safe_get(logic_controller, "free_storage"),
            free_nbw = safe_get(logic_controller, "free_nbw"),
            is_network_switch = safe_get(logic_controller, "is_network_switch"),
            is_network_router = safe_get(logic_controller, "is_network_router"),
            is_dns_server = safe_get(logic_controller, "is_dns_server"),
            is_dhcp_server = safe_get(logic_controller, "is_dhcp_server"),
            is_network_tap = safe_get(logic_controller, "is_network_tap"),
            is_network_filter = safe_get(logic_controller, "is_network_filter"),
            is_ha_enabled = safe_get(logic_controller, "is_ha_enabled"),
            is_vlan_enabled = safe_get(logic_controller, "is_vlan_enabled"),
            is_stp_enabled = safe_get(logic_controller, "is_stp_enabled")
        }
        
        -- Network control module
        local networkctl = safe_get(logic_controller, "networkctl")
        if networkctl then
            data.logic_controller.networkctl = {
                dhcp_enabled = safe_get(networkctl, "dhcp_enabled"),
                is_dhcp_enabled = safe_get(networkctl, "is_dhcp_enabled"),
                stp_enabled = safe_get(networkctl, "stp_enabled"),
                designated_dns_servers = {}
            }
            
            -- Extract DNS servers
            local dns_arr = safe_get(networkctl, "designated_dns_servers")
            if dns_arr then
                local dns_table = array_to_table(dns_arr)
                if dns_table then
                    for i, v in ipairs(dns_table) do
                        data.logic_controller.networkctl.designated_dns_servers[i] = tostring(v)
                    end
                end
            end
        end
        
        -- Installed programs
        local programs = safe_get(logic_controller, "installed_programs")
        if programs then
            data.logic_controller.installed_programs = {}
            local prog_table = array_to_table(programs)
            if prog_table then
                for i, prog in ipairs(prog_table) do
                    data.logic_controller.installed_programs[i] = {
                        release_name = safe_get(prog, "release_name"),
                        is_running = safe_get(prog, "is_running"),
                        cpu_load = safe_get(prog, "cpu_load"),
                        install_size = safe_get(prog, "install_size")
                    }
                end
            end
        end
    end
    
    -- Power Controller info
    local power_controller = safe_get(device, "power_controller")
    if power_controller then
        data.power_controller = {
            charges = safe_get(power_controller, "charges"),
            charge_capacity = safe_get(power_controller, "charge_capacity"),
            charge_ratio = safe_get(power_controller, "charge_ratio"),
            current_load = safe_get(power_controller, "current_load"),
            functional = safe_get(power_controller, "functional"),
            can_supply_power = safe_get(power_controller, "can_supply_power"),
            surge_blocker = safe_get(power_controller, "surge_blocker")
        }
    end
    
    return data
end

local function extract_user_data(user)
    if not user then return nil end
    
    local data = {
        username = safe_get(user, "username"),
        user_profile_name = safe_get(user, "user_profile_name"),
        description = safe_get(user, "description"),
        daily_rate = safe_get(user, "daily_rate"),
        satiety_ratio = safe_get(user, "satiety_ratio"),
        is_active = safe_get(user, "is_active"),
        average_satiety_ratio_last_tick = safe_get(user, "average_satiety_ratio_last_tick"),
        lowest_satiety_ratio = safe_get(user, "lowest_satiety_ratio"),
        usage_fulfilment_today = safe_get(user, "usage_fulfilment_today"),
        grace_days_left = safe_get(user, "grace_days_left"),
        downtime_sla_seconds = safe_get(user, "downtime_sla_seconds"),
        eagerness_factor = safe_get(user, "eagerness_factor")
    }
    
    -- Location info
    local location = safe_get(user, "location")
    if location then
        data.location = {
            floor_num = safe_get(location, "floor_num"),
            display_name = safe_get(location, "display_name")
        }
    end
    
    return data
end

local function extract_location_data(location)
    if not location then return nil end
    
    local data = {
        display_name = safe_get(location, "display_name"),
        floor_num = safe_get(location, "floor_num"),
        description = safe_get(location, "description"),
        width = safe_get(location, "width"),
        height = safe_get(location, "height"),
        is_datacenter = safe_get(location, "is_datacenter"),
        surge_immunity = safe_get(location, "surge_immunity"),
        outage_immunity = safe_get(location, "outage_immunity"),
        network_outage_flag = safe_get(location, "network_outage_flag"),
        spawn_limit = safe_get(location, "spawn_limit"),
        will_not_spawn_before_day = safe_get(location, "will_not_spawn_before_day"),
        slot_index = safe_get(location, "slot_index")
    }
    
    -- Count users in location
    local users = safe_get(location, "users")
    if users then
        local user_table = array_to_table(users)
        data.user_count = user_table and #user_table or 0
    end
    
    return data
end

local function extract_transaction_data(transaction)
    if not transaction then return nil end
    
    return {
        amount = safe_get(transaction, "amount"),
        details = safe_get(transaction, "details"),
        date = safe_get(transaction, "date"),
        category = safe_get(transaction, "category"),
        category_name = transaction_categories[safe_get(transaction, "category")] or "UNKNOWN"
    }
end

local function extract_loan_data(loan)
    if not loan then return nil end
    
    return {
        title = safe_get(loan, "title"),
        amount = safe_get(loan, "amount"),
        daily_interest = safe_get(loan, "daily_interest"),
        date = safe_get(loan, "date"),
        description = safe_get(loan, "description")
    }
end

local function extract_hosting_data(hosting)
    if not hosting then return nil end
    
    return {
        fqdn = safe_get(hosting, "fqdn"),
        ppu = safe_get(hosting, "ppu"),
        today_visit_count = safe_get(hosting, "today_visit_count"),
        historical_visit_count = safe_get(hosting, "historical_visit_count"),
        today_payment = safe_get(hosting, "today_payment"),
        registered_on_day = safe_get(hosting, "registered_on_day")
    }
end

local function extract_merchant_data(merchant)
    if not merchant then return nil end
    
    local data = {
        display_name = safe_get(merchant, "display_name"),
        description = safe_get(merchant, "description"),
        price_multiplier = safe_get(merchant, "price_multiplier"),
        warranty_multiplier = safe_get(merchant, "warranty_multiplier"),
        restock_period = safe_get(merchant, "restock_period")
    }
    
    -- Listings count
    local listings = safe_get(merchant, "listings")
    if listings then
        local listings_table = array_to_table(listings)
        data.listings_count = listings_table and #listings_table or 0
    end
    
    return data
end

-- ============================================================================
-- GAME STATE EXPORT (JSON)
-- ============================================================================

local function export_game_state_json()
    print("\n[DIAGNOSTIC] ========== Exporting Game State to JSON ==========")
    
    if not config.json_export_enabled then
        print("[DIAGNOSTIC] ✗ JSON export is disabled in config")
        return nil
    end
    
    -- Safe timestamp (os.time/os.date may be restricted in sandbox)
    local timestamp = nil
    local datestr = nil
    pcall(function()
        timestamp = os.time()
        datestr = os.date("%Y-%m-%dT%H:%M:%S")
    end)
    
    local game_state = {
        _metadata = {
            mod_version = "3.4",
            export_timestamp = timestamp,
            export_date = datestr
        }
    }
    
    local world = nil
    if ModApiV1 then
        world = ModApiV1.get_game_world()
    end
    
    if not world then
        print("[DIAGNOSTIC] ✗ Cannot export: World is nil")
        game_state._error = "World not available"
        return game_state
    end
    
    -- Basic world info
    game_state.world = {
        scenario_name = safe_get(world, "scenario_name"),
        n_days = safe_get(world, "n_days"),
        days_in_debt = safe_get(world, "days_in_debt"),
        player_cash_balance = safe_get(world, "player_cash_balance"),
        day_opening_balance = safe_get(world, "day_opening_balance"),
        payment_due_today = safe_get(world, "payment_due_today"),
        time_mult = safe_get(world, "time_mult"),
        game_time_str = safe_get(world, "game_time_str"),
        game_dt_str = safe_get(world, "game_dt_str"),
        difficulty_level = safe_get(world, "difficulty_level"),
        rng_seed = safe_get(world, "rng_seed"),
        autosave_enabled = safe_get(world, "autosave_enabled")
    }
    
    -- Play Options
    if config.json_include_play_options then
        local play_options = safe_get(world, "play_options")
        if play_options then
            game_state.play_options = {
                starting_cash = safe_get(play_options, "starting_cash"),
                day_period = safe_get(play_options, "day_period"),
                freeplay = safe_get(play_options, "freeplay"),
                waive_power_fee = safe_get(play_options, "waive_power_fee"),
                infinite_bandwidth_mode = safe_get(play_options, "infinite_bandwidth_mode"),
                max_days_in_debt = safe_get(play_options, "max_days_in_debt"),
                user_fee_payment_multiplier = safe_get(play_options, "user_fee_payment_multiplier"),
                daily_admin_expenses = safe_get(play_options, "daily_admin_expenses"),
                device_malfunction_occurrence_rate = safe_get(play_options, "device_malfunction_occurrence_rate"),
                power_outage_occurrence_rate = safe_get(play_options, "power_outage_occurrence_rate"),
                power_surge_occurrence_rate = safe_get(play_options, "power_surge_occurrence_rate"),
                device_warranty_period_multiplier = safe_get(play_options, "device_warranty_period_multiplier"),
                floor_build_maximum_floors = safe_get(play_options, "floor_build_maximum_floors"),
                proposal_batch_size = safe_get(play_options, "proposal_batch_size"),
                lab_mode = safe_get(play_options, "lab_mode")
            }
            print("[DIAGNOSTIC] ✓ Included play_options")
        end
    end
    
    -- Devices
    if config.json_include_devices then
        game_state.devices = {}
        local devices = nil
        
        -- Try ModApiV1.get_devices() first
        if ModApiV1 and ModApiV1.get_devices then
            local success, result = pcall(function() return ModApiV1.get_devices() end)
            if success then devices = result end
        end
        
        if devices then
            local devices_table = array_to_table(devices)
            if devices_table then
                for i, device in ipairs(devices_table) do
                    game_state.devices[i] = extract_device_data(device)
                end
                print("[DIAGNOSTIC] ✓ Included " .. #devices_table .. " devices")
            end
        else
            print("[DIAGNOSTIC] ✗ Could not get devices")
        end
    end
    
    -- Users
    if config.json_include_users then
        game_state.users = {}
        local users = nil
        
        -- Try ModApiV1.get_users() first
        if ModApiV1 and ModApiV1.get_users then
            local success, result = pcall(function() return ModApiV1.get_users() end)
            if success then users = result end
        end
        
        -- Fall back to world.users
        if not users then
            users = safe_get(world, "users")
        end
        
        if users then
            local users_table = array_to_table(users)
            if users_table then
                for i, user in ipairs(users_table) do
                    game_state.users[i] = extract_user_data(user)
                end
                print("[DIAGNOSTIC] ✓ Included " .. #users_table .. " users")
            end
        else
            print("[DIAGNOSTIC] ✗ Could not get users")
        end
    end
    
    -- Locations
    if config.json_include_locations then
        game_state.locations = {}
        local locations = safe_get(world, "locations")
        if locations then
            local locations_table = array_to_table(locations)
            if locations_table then
                for i, location in ipairs(locations_table) do
                    game_state.locations[i] = extract_location_data(location)
                end
                print("[DIAGNOSTIC] ✓ Included " .. #locations_table .. " locations")
            end
        end
    end
    
    -- Financial Data
    if config.json_include_finances then
        game_state.finances = {
            cash_balance = safe_get(world, "player_cash_balance"),
            day_opening_balance = safe_get(world, "day_opening_balance"),
            payment_due_today = safe_get(world, "payment_due_today"),
            transaction_count = safe_get(world, "player_transaction_count")
        }
        
        -- Recent transactions (last 20)
        local transactions = safe_get(world, "player_transactions")
        if transactions then
            game_state.finances.recent_transactions = {}
            local trans_table = array_to_table(transactions)
            if trans_table then
                local start_idx = math.max(1, #trans_table - 19)
                for i = start_idx, #trans_table do
                    table.insert(game_state.finances.recent_transactions, extract_transaction_data(trans_table[i]))
                end
                print("[DIAGNOSTIC] ✓ Included " .. #game_state.finances.recent_transactions .. " recent transactions")
            end
        end
        
        -- Payment breakdown
        local breakdown_success, breakdown = pcall(function()
            return world:calculate_payment_due_breakdown(true)
        end)
        if breakdown_success and breakdown then
            game_state.finances.payment_breakdown = breakdown
        end
    end
    
    -- Loans
    if config.json_include_loans then
        game_state.loans = {}
        local loans = safe_get(world, "player_loans")
        if loans then
            local loans_table = array_to_table(loans)
            if loans_table then
                for i, loan in ipairs(loans_table) do
                    game_state.loans[i] = extract_loan_data(loan)
                end
                print("[DIAGNOSTIC] ✓ Included " .. #loans_table .. " loans")
            end
        end
    end
    
    -- Player Hostings
    if config.json_include_hostings then
        game_state.player_hostings = {}
        local hostings = safe_get(world, "player_hostings")
        if hostings then
            local hostings_table = array_to_table(hostings)
            if hostings_table then
                for i, hosting in ipairs(hostings_table) do
                    game_state.player_hostings[i] = extract_hosting_data(hosting)
                end
                print("[DIAGNOSTIC] ✓ Included " .. #hostings_table .. " player hostings")
            end
        end
    end
    
    -- Merchants
    if config.json_include_merchants then
        game_state.merchants = {}
        local merchants = safe_get(world, "device_merchants")
        if merchants then
            local merchants_table = array_to_table(merchants)
            if merchants_table then
                for i, merchant in ipairs(merchants_table) do
                    game_state.merchants[i] = extract_merchant_data(merchant)
                end
                print("[DIAGNOSTIC] ✓ Included " .. #merchants_table .. " merchants")
            end
        end
    end
    
    -- Statistics
    if config.json_include_statistics then
        local game_stats = safe_get(world, "game_stats")
        if game_stats then
            game_state.statistics = {}
            local stats_data = safe_get(game_stats, "data")
            if stats_data and type(stats_data) == "table" then
                for k, v in pairs(stats_data) do
                    local stat_name = stat_names[k] or tostring(k)
                    game_state.statistics[stat_name] = v
                end
            end
            print("[DIAGNOSTIC] ✓ Included statistics")
        end
    end
    
    -- Daycycle Controller
    local daycycle = safe_get(world, "daycycle_controller")
    if daycycle then
        game_state.daycycle = {
            day_period = safe_get(daycycle, "day_period"),
            day_clock = safe_get(daycycle, "day_clock"),
            normal_clock = safe_get(daycycle, "normal_clock"),
            paused = safe_get(daycycle, "paused"),
            sunrise_time_float = safe_get(daycycle, "sunrise_time_float"),
            sunset_time_float = safe_get(daycycle, "sunset_time_float")
        }
    end
    
    -- DNS Lookup table
    if config.json_include_network then
        local dns_lookup = safe_get(world, "dns_lookup")
        if dns_lookup and type(dns_lookup) == "table" then
            game_state.dns_lookup = {}
            for k, v in pairs(dns_lookup) do
                game_state.dns_lookup[tostring(k)] = tostring(v)
            end
            print("[DIAGNOSTIC] ✓ Included DNS lookup table")
        end
        
        local nwaddr_lookup = safe_get(world, "nwaddr_lookup")
        if nwaddr_lookup and type(nwaddr_lookup) == "table" then
            game_state.nwaddr_lookup = {}
            for k, v in pairs(nwaddr_lookup) do
                game_state.nwaddr_lookup[tostring(k)] = tostring(v)
            end
            print("[DIAGNOSTIC] ✓ Included network address lookup table")
        end
    end
    
    print("[DIAGNOSTIC] ✓ Game state extraction complete")
    return game_state
end

function export_to_json_file()
    local game_state = export_game_state_json()
    if not game_state then
        print("[DIAGNOSTIC] ✗ Failed to export game state")
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui then
                base_ui:display_notification("JSON Export Failed - check logs", 1)
            end
        end)
        return false
    end
    
    local json_str = to_json(game_state, 2, 0)
    local json_size = #json_str
    
    -- Output JSON to logs (file writing causes sandbox protection fault)
    print("[DIAGNOSTIC] ✓ JSON Export Complete (" .. json_size .. " bytes)")
    print("[DIAGNOSTIC] === JSON GAME STATE START ===")
    
    -- Print in chunks to avoid any line length issues
    local chunk_size = 4000
    local num_chunks = math.ceil(json_size / chunk_size)
    
    for i = 1, num_chunks do
        local start_pos = (i - 1) * chunk_size + 1
        local end_pos = math.min(i * chunk_size, json_size)
        print(json_str:sub(start_pos, end_pos))
    end
    
    print("[DIAGNOSTIC] === JSON GAME STATE END ===")
    print("[DIAGNOSTIC] Total JSON size: " .. json_size .. " bytes (" .. num_chunks .. " chunks)")
    
    -- Show notification
    pcall(function()
        local base_ui = ModApiV1.get_base_ui()
        if base_ui then
            base_ui:display_notification("JSON exported to logs (" .. json_size .. " bytes)", 0)
        end
    end)
    
    return true
end

-- ============================================================================
-- API TEST SUITE
-- ============================================================================

local function add_test_result(category, test_name, passed, details, error_msg)
    local result = {
        category = category,
        name = test_name,
        passed = passed,
        details = details,
        error = error_msg
    }
    
    table.insert(test_results.tests, result)
    test_results.summary.total = test_results.summary.total + 1
    
    if passed then
        test_results.summary.passed = test_results.summary.passed + 1
    else
        test_results.summary.failed = test_results.summary.failed + 1
    end
end

local function run_test(category, test_name, test_func)
    local success, result = pcall(test_func)
    if success then
        if type(result) == "table" then
            add_test_result(category, test_name, result.passed, result.details, result.error)
        else
            add_test_result(category, test_name, result ~= nil and result ~= false, tostring(result), nil)
        end
    else
        add_test_result(category, test_name, false, nil, tostring(result))
    end
end

function run_api_test_suite()
    print("\n[DIAGNOSTIC] ========== Running API Test Suite ==========")
    
    if not config.test_suite_enabled then
        print("[DIAGNOSTIC] ✗ Test suite is disabled in config")
        return
    end
    
    -- Reset test results
    test_results = {
        timestamp = os.time(),
        tests = {},
        summary = {
            total = 0,
            passed = 0,
            failed = 0,
            skipped = 0
        }
    }
    
    -- ========== ModApiV1 Tests ==========
    if config.test_mod_api then
        print("[DIAGNOSTIC] Testing ModApiV1...")
        
        run_test("ModApiV1", "ModApiV1 exists", function()
            return { passed = ModApiV1 ~= nil, details = "ModApiV1 global is " .. (ModApiV1 ~= nil and "available" or "nil") }
        end)
        
        run_test("ModApiV1", "sanity()", function()
            if not ModApiV1 then return { passed = false, error = "ModApiV1 is nil" } end
            ModApiV1.sanity()
            return { passed = true, details = "sanity() called successfully" }
        end)
        
        run_test("ModApiV1", "get_game_world()", function()
            if not ModApiV1 then return { passed = false, error = "ModApiV1 is nil" } end
            local world = ModApiV1.get_game_world()
            return { passed = world ~= nil, details = world ~= nil and "World returned" or "World is nil" }
        end)
        
        run_test("ModApiV1", "get_player_camera()", function()
            if not ModApiV1 then return { passed = false, error = "ModApiV1 is nil" } end
            local camera = ModApiV1.get_player_camera()
            return { passed = true, details = camera ~= nil and "Camera returned" or "Camera is nil (may be normal)" }
        end)
        
        run_test("ModApiV1", "get_base_ui()", function()
            if not ModApiV1 then return { passed = false, error = "ModApiV1 is nil" } end
            local ui = ModApiV1.get_base_ui()
            return { passed = ui ~= nil, details = ui ~= nil and "BaseUI returned" or "BaseUI is nil" }
        end)
        
        run_test("ModApiV1", "get_devices()", function()
            if not ModApiV1 then return { passed = false, error = "ModApiV1 is nil" } end
            local devices = ModApiV1.get_devices()
            local count = 0
            if devices then
                local tbl = array_to_table(devices)
                count = tbl and #tbl or 0
            end
            return { passed = devices ~= nil, details = "Returned " .. count .. " devices" }
        end)
        
        run_test("ModApiV1", "get_users()", function()
            if not ModApiV1 then return { passed = false, error = "ModApiV1 is nil" } end
            local users = ModApiV1.get_users()
            local count = 0
            if users then
                local tbl = array_to_table(users)
                count = tbl and #tbl or 0
            end
            return { passed = users ~= nil, details = "Returned " .. count .. " users" }
        end)
    end
    
    -- ========== Mod Global Tests ==========
    if config.test_mod_api then
        print("[DIAGNOSTIC] Testing Mod global...")
        
        run_test("Mod", "Mod exists", function()
            return { passed = Mod ~= nil, details = "Mod global is " .. (Mod ~= nil and "available" or "nil") }
        end)
        
        run_test("Mod", "Mod.mod_dir", function()
            if not Mod then return { passed = false, error = "Mod is nil" } end
            local dir = safe_get(Mod, "mod_dir")
            return { passed = dir ~= nil, details = "mod_dir = " .. tostring(dir) }
        end)
        
        run_test("Mod", "Mod.mod_type", function()
            if not Mod then return { passed = false, error = "Mod is nil" } end
            local t = safe_get(Mod, "mod_type")
            return { passed = t ~= nil, details = "mod_type = " .. tostring(t) }
        end)
        
        run_test("Mod", "Mod.filesystem", function()
            if not Mod then return { passed = false, error = "Mod is nil" } end
            local fs = safe_get(Mod, "filesystem")
            return { passed = fs ~= nil, details = fs ~= nil and "filesystem available" or "filesystem is nil" }
        end)
        
        run_test("Mod", "Mod.config", function()
            if not Mod then return { passed = false, error = "Mod is nil" } end
            local cfg = safe_get(Mod, "config")
            return { passed = true, details = cfg ~= nil and "config table available" or "config is nil (using defaults)" }
        end)
    end
    
    -- ========== GameWorld Tests ==========
    if config.test_game_world then
        print("[DIAGNOSTIC] Testing GameWorld...")
        
        local world = ModApiV1 and ModApiV1.get_game_world() or nil
        
        run_test("GameWorld", "world.scenario_name", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "scenario_name")
            return { passed = val ~= nil, details = "scenario_name = " .. tostring(val) }
        end)
        
        run_test("GameWorld", "world.n_days", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "n_days")
            return { passed = val ~= nil, details = "n_days = " .. tostring(val) }
        end)
        
        run_test("GameWorld", "world.player_cash_balance", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "player_cash_balance")
            return { passed = val ~= nil, details = "player_cash_balance = $" .. tostring(val) }
        end)
        
        run_test("GameWorld", "world.play_options", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "play_options")
            return { passed = val ~= nil, details = val ~= nil and "PlayOptions available" or "PlayOptions is nil" }
        end)
        
        run_test("GameWorld", "world.game_stats", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "game_stats")
            return { passed = val ~= nil, details = val ~= nil and "GameStatistics available" or "GameStatistics is nil" }
        end)
        
        run_test("GameWorld", "world.locations", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "locations")
            local count = 0
            if val then
                local tbl = array_to_table(val)
                count = tbl and #tbl or 0
            end
            return { passed = val ~= nil, details = "locations count = " .. count }
        end)
        
        run_test("GameWorld", "world.users", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "users")
            local count = 0
            if val then
                local tbl = array_to_table(val)
                count = tbl and #tbl or 0
            end
            return { passed = val ~= nil, details = "users count = " .. count }
        end)
        
        run_test("GameWorld", "world.player_loans", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "player_loans")
            local count = 0
            if val then
                local tbl = array_to_table(val)
                count = tbl and #tbl or 0
            end
            return { passed = val ~= nil, details = "loans count = " .. count }
        end)
        
        run_test("GameWorld", "world.player_hostings", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "player_hostings")
            local count = 0
            if val then
                local tbl = array_to_table(val)
                count = tbl and #tbl or 0
            end
            return { passed = val ~= nil, details = "player_hostings count = " .. count }
        end)
        
        run_test("GameWorld", "world.device_merchants", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "device_merchants")
            local count = 0
            if val then
                local tbl = array_to_table(val)
                count = tbl and #tbl or 0
            end
            return { passed = val ~= nil, details = "device_merchants count = " .. count }
        end)
        
        run_test("GameWorld", "world.daycycle_controller", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "daycycle_controller")
            return { passed = val ~= nil, details = val ~= nil and "DayCycleController available" or "DayCycleController is nil" }
        end)
        
        run_test("GameWorld", "world.loan_controller", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "loan_controller")
            return { passed = val ~= nil, details = val ~= nil and "LoanController available" or "LoanController is nil" }
        end)
        
        run_test("GameWorld", "world.dns_lookup", function()
            if not world then return { passed = false, error = "World is nil" } end
            local val = safe_get(world, "dns_lookup")
            local count = 0
            if val and type(val) == "table" then
                for _ in pairs(val) do count = count + 1 end
            end
            -- dns_lookup existing (even if empty) is a pass - it may be empty early in game
            return { passed = true, details = "dns_lookup entries = " .. count .. (count == 0 and " (normal if early in game)" or "") }
        end)
        
        run_test("GameWorld", "calculate_payment_due_breakdown()", function()
            if not world then return { passed = false, error = "World is nil" } end
            local success, result = pcall(function() return world:calculate_payment_due_breakdown(true) end)
            return { passed = success, details = success and "Method callable" or "Method failed", error = not success and tostring(result) or nil }
        end)
    end
    
    -- ========== Device API Tests ==========
    if config.test_devices_api then
        print("[DIAGNOSTIC] Testing Device API...")
        
        local devices = ModApiV1 and ModApiV1.get_devices() or nil
        local first_device = nil
        if devices then
            local tbl = array_to_table(devices)
            if tbl and #tbl > 0 then
                first_device = tbl[1]
            end
        end
        
        if first_device then
            run_test("DeviceUnit", "device.product_name", function()
                local val = safe_get(first_device, "product_name")
                return { passed = val ~= nil, details = "product_name = " .. tostring(val) }
            end)
            
            run_test("DeviceUnit", "device.device_hardware_class", function()
                local val = safe_get(first_device, "device_hardware_class")
                local name = device_class_names[val] or "UNKNOWN"
                return { passed = val ~= nil, details = "device_hardware_class = " .. tostring(val) .. " (" .. name .. ")" }
            end)
            
            run_test("DeviceUnit", "device.logic_controller", function()
                local val = safe_get(first_device, "logic_controller")
                return { passed = true, details = val ~= nil and "LogicController available" or "LogicController is nil (may be normal for some devices)" }
            end)
            
            run_test("DeviceUnit", "device.power_controller", function()
                local val = safe_get(first_device, "power_controller")
                return { passed = true, details = val ~= nil and "PowerController available" or "PowerController is nil (may be normal)" }
            end)
        else
            add_test_result("DeviceUnit", "No devices available", true, "Skipped device tests - no devices in world", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end
    
    -- ========== User API Tests ==========
    if config.test_users_api then
        print("[DIAGNOSTIC] Testing User API...")
        
        local users = ModApiV1 and ModApiV1.get_users() or nil
        local first_user = nil
        if users then
            local tbl = array_to_table(users)
            if tbl and #tbl > 0 then
                first_user = tbl[1]
            end
        end
        
        if first_user then
            run_test("User", "user.username", function()
                local val = safe_get(first_user, "username")
                return { passed = val ~= nil, details = "username = " .. tostring(val) }
            end)
            
            run_test("User", "user.user_profile_name", function()
                local val = safe_get(first_user, "user_profile_name")
                return { passed = val ~= nil, details = "user_profile_name = " .. tostring(val) }
            end)
            
            run_test("User", "user.daily_rate", function()
                local val = safe_get(first_user, "daily_rate")
                return { passed = val ~= nil, details = "daily_rate = $" .. tostring(val) }
            end)
            
            run_test("User", "user.satiety_ratio", function()
                local val = safe_get(first_user, "satiety_ratio")
                return { passed = val ~= nil, details = "satiety_ratio = " .. tostring(val) }
            end)
            
            run_test("User", "user.location", function()
                local val = safe_get(first_user, "location")
                return { passed = val ~= nil, details = val ~= nil and "Location available" or "Location is nil" }
            end)
        else
            add_test_result("User", "No users available", true, "Skipped user tests - no users in world", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end
    
    -- ========== Network API Tests ==========
    if config.test_network_api then
        print("[DIAGNOSTIC] Testing Network API...")
        
        -- Find a device with network controller
        local devices = ModApiV1 and ModApiV1.get_devices() or nil
        local network_device = nil
        if devices then
            local tbl = array_to_table(devices)
            if tbl then
                for _, dev in ipairs(tbl) do
                    local lc = safe_get(dev, "logic_controller")
                    if lc and safe_get(lc, "networkctl") then
                        network_device = dev
                        break
                    end
                end
            end
        end
        
        if network_device then
            local lc = safe_get(network_device, "logic_controller")
            local netctl = safe_get(lc, "networkctl")
            
            run_test("NetworkControlModule", "networkctl.hardware_address", function()
                local val = safe_get(netctl, "hardware_address")
                return { passed = val ~= nil, details = "hardware_address = " .. tostring(val) }
            end)
            
            run_test("NetworkControlModule", "networkctl.network_address", function()
                local val = safe_get(netctl, "network_address")
                return { passed = val ~= nil, details = "network_address = " .. tostring(val) }
            end)
            
            run_test("NetworkControlModule", "networkctl.dhcp_enabled", function()
                local val = safe_get(netctl, "dhcp_enabled")
                return { passed = true, details = "dhcp_enabled = " .. tostring(val) }
            end)
            
            run_test("NetworkControlModule", "networkctl.designated_dns_servers", function()
                local val = safe_get(netctl, "designated_dns_servers")
                local count = 0
                if val then
                    local tbl = array_to_table(val)
                    count = tbl and #tbl or 0
                end
                return { passed = val ~= nil, details = "DNS server count = " .. count }
            end)
        else
            add_test_result("NetworkControlModule", "No network devices available", true, "Skipped network tests - no devices with network controller", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end
    
    -- ========== FileSystem API Tests ==========
    if config.test_filesystem_api then
        print("[DIAGNOSTIC] Testing FileSystem API...")
        
        run_test("ModFileSystem", "ModFileSystem exists", function()
            return { passed = ModFileSystem ~= nil, details = "ModFileSystem global is " .. (ModFileSystem ~= nil and "available" or "nil") }
        end)
        
        run_test("ModFileSystem", "Mod.filesystem", function()
            if not Mod then return { passed = false, error = "Mod is nil" } end
            local fs = safe_get(Mod, "filesystem")
            return { passed = fs ~= nil, details = fs ~= nil and "filesystem available" or "filesystem is nil" }
        end)
        
        if Mod and Mod.filesystem then
            run_test("ModFileSystem", "get_files_at('/')", function()
                local fs = Mod.filesystem
                local success, files = pcall(function() return fs:get_files_at("/") end)
                local count = 0
                if success and files then
                    local tbl = array_to_table(files)
                    count = tbl and #tbl or 0
                end
                return { passed = success, details = "Found " .. count .. " files at root", error = not success and tostring(files) or nil }
            end)
            
            run_test("ModFileSystem", "get_directories_at('/')", function()
                local fs = Mod.filesystem
                local success, dirs = pcall(function() return fs:get_directories_at("/") end)
                local count = 0
                if success and dirs then
                    local tbl = array_to_table(dirs)
                    count = tbl and #tbl or 0
                end
                return { passed = success, details = "Found " .. count .. " directories at root", error = not success and tostring(dirs) or nil }
            end)
        end
    end
    
    -- ========== Engine Global Tests ==========
    run_test("Engine", "Engine exists", function()
        return { passed = Engine ~= nil, details = "Engine global is " .. (Engine ~= nil and "available" or "nil") }
    end)
    
    -- Print results summary
    print("\n[DIAGNOSTIC] ========== Test Results Summary ==========")
    print(string.format("[DIAGNOSTIC] Total: %d | Passed: %d | Failed: %d | Skipped: %d",
        test_results.summary.total,
        test_results.summary.passed,
        test_results.summary.failed,
        test_results.summary.skipped))
    
    -- Print failed tests
    if test_results.summary.failed > 0 then
        print("\n[DIAGNOSTIC] Failed Tests:")
        for _, test in ipairs(test_results.tests) do
            if not test.passed then
                print(string.format("[DIAGNOSTIC]   ✗ %s.%s: %s",
                    test.category, test.name,
                    test.error or test.details or "Unknown error"))
            end
        end
    end
    
    -- Print all tests with details
    if config.verbose_mode then
        print("\n[DIAGNOSTIC] All Test Results:")
        for _, test in ipairs(test_results.tests) do
            local status = test.passed and "✓" or "✗"
            print(string.format("[DIAGNOSTIC]   %s [%s] %s: %s",
                status, test.category, test.name,
                test.details or test.error or ""))
        end
    end
    
    print("[DIAGNOSTIC] " .. string.rep("=", 50))
    
    -- Show notification
    if config.show_notification then
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui then
                local msg = string.format("API Tests: %d/%d passed",
                    test_results.summary.passed, test_results.summary.total)
                local tone = test_results.summary.failed > 0 and 2 or 0
                base_ui:display_notification(msg, tone)
            end
        end)
    end
    
    return test_results
end

-- Export test results as JSON
function export_test_results_json()
    local json_str = to_json(test_results, 2, 0)
    print("\n[DIAGNOSTIC] ========== Test Results JSON ==========")
    print(json_str)
    print("[DIAGNOSTIC] " .. string.rep("=", 50))
    return json_str
end

-- ============================================================================
-- TABLE DUMP UTILITIES
-- ============================================================================

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

    if type(tbl) == "userdata" then
        print(prefix .. "<userdata: " .. tostring(tbl) .. ">")
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

local function dump_device_detailed(device, prefix)
    prefix = prefix or "  "
    print(prefix .. "product_name: " .. tostring(safe_get(device, "product_name")))
    print(prefix .. "device_hardware_class: " .. tostring(safe_get(device, "device_hardware_class")))
    print(prefix .. "price: " .. tostring(safe_get(device, "price")))
    print(prefix .. "base_warranty_days: " .. tostring(safe_get(device, "base_warranty_days")))
    print(prefix .. "warranty_period_remaining: " .. tostring(safe_get(device, "warranty_period_remaining")))

    local logic_controller = safe_get(device, "logic_controller")
    if logic_controller then
        print(prefix .. "logic_controller exists:")
        print(prefix .. "  hardware_address: " .. tostring(safe_get(logic_controller, "hardware_address")))
        print(prefix .. "  network_address: " .. tostring(safe_get(logic_controller, "network_address")))
        print(prefix .. "  installed_nbw: " .. tostring(safe_get(logic_controller, "installed_nbw")))
        print(prefix .. "  installed_cpu: " .. tostring(safe_get(logic_controller, "installed_cpu")))
        print(prefix .. "  installed_mem: " .. tostring(safe_get(logic_controller, "installed_mem")))
        print(prefix .. "  installed_sto: " .. tostring(safe_get(logic_controller, "installed_sto")))
    else
        print(prefix .. "logic_controller: nil")
    end
end

-- ============================================================================
-- INSPECTION FUNCTIONS
-- ============================================================================

local function inspect_user_network(user, context)
    if not config.enable_network_inspection then return end

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
    if dns then
        print("[DIAGNOSTIC]   designated_dns_servers:")
        local dns_table = array_to_table(dns)
        if dns_table then
            for i, v in ipairs(dns_table) do
                print("[DIAGNOSTIC]     [" .. i .. "] = " .. tostring(v))
            end
        end
    end

    print("[DIAGNOSTIC] " .. string.rep("=", 60) .. "\n")
end

local function inspect_available_scenes()
    print("\n[DIAGNOSTIC] ========== Available Scenes Inspection ==========")

    if ModApiV1 then
        local world = ModApiV1.get_game_world()
        if world then
            local locations = safe_get(world, "locations")
            if locations then
                print("[DIAGNOSTIC] World Locations:")
                local loc_table = array_to_table(locations)
                if loc_table then
                    for i, loc in ipairs(loc_table) do
                        local display_name = safe_get(loc, "display_name")
                        local floor_num = safe_get(loc, "floor_num")
                        local is_dc = safe_get(loc, "is_datacenter")
                        print(string.format("[DIAGNOSTIC]   Floor %s: %s%s",
                            tostring(floor_num),
                            tostring(display_name),
                            is_dc and " [DATACENTER]" or ""))
                    end
                end
            end
        end
    end

    print("[DIAGNOSTIC] ================================================\n")
end

-- ============================================================================
-- PUBLIC COMMANDS
-- ============================================================================

function reinspect_all_users()
    print("\n[DIAGNOSTIC] ========== Re-inspecting All Users ==========")
    print("[DIAGNOSTIC] Total users tracked: " .. #spawned_users)

    for _, user_data in ipairs(spawned_users) do
        inspect_user_network(user_data.user, "manual_reinspection")
    end

    -- Always try to show notification
    pcall(function()
        local base_ui = ModApiV1.get_base_ui()
        if base_ui then
            base_ui:display_notification(string.format("Re-inspected %d users - see logs", #spawned_users), 0)
        end
    end)
end

function inspect_scenes()
    inspect_available_scenes()
end

function dump_all_world_devices()
    print("\n[DIAGNOSTIC] ========== Dumping All World Devices ==========")

    if not ModApiV1 then
        print("[DIAGNOSTIC] ✗ ModApiV1 not available")
        return
    end

    local devices = ModApiV1.get_devices()
    if not devices then
        print("[DIAGNOSTIC] ✗ No devices returned")
        return
    end

    local devices_table = array_to_table(devices)
    if devices_table then
        print("[DIAGNOSTIC] Device count: " .. #devices_table)
        for i, device in ipairs(devices_table) do
            local product_name = safe_get(device, "product_name")
            local hw_class = safe_get(device, "device_hardware_class")
            local class_name = device_class_names[hw_class] or "UNKNOWN"
            print(string.format("[DIAGNOSTIC]   [%d] %s (class=%s)", i, tostring(product_name), class_name))
            
            -- If it's a phone or CCTV, dump detailed info
            if hw_class == 16 or hw_class == 17 then
                print("[DIAGNOSTIC]     ⚠️ PHONE/CCTV - Detailed dump:")
                dump_device_detailed(device, "[DIAGNOSTIC]       ")
            end
        end
    end

    print("[DIAGNOSTIC] " .. string.rep("=", 60) .. "\n")

    -- Always try to show notification
    local device_count = devices_table and #devices_table or 0
    pcall(function()
        local base_ui = ModApiV1.get_base_ui()
        if base_ui then
            base_ui:display_notification(string.format("Device dump: %d devices - see logs", device_count), 0)
        end
    end)
end

-- ============================================================================
-- CALLBACK FUNCTIONS
-- ============================================================================

function on_engine_load()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 400)

    print("\n[DIAGNOSTIC] ========== on_engine_load() ==========")

    if ModApiV1 then
        print("[DIAGNOSTIC] ✓ ModApiV1 is available")
        
        local world = ModApiV1.get_game_world()
        if world then
            print("[DIAGNOSTIC] ✓ World exists in on_engine_load!")
            local play_options = safe_get(world, "play_options")
            if play_options then
                print("[DIAGNOSTIC] ✓ PlayOptions accessible")
                print("[DIAGNOSTIC]   starting_cash = " .. tostring(safe_get(play_options, "starting_cash")))
            end
        else
            print("[DIAGNOSTIC] ✗ World is nil in on_engine_load")
        end
    else
        print("[DIAGNOSTIC] ✗ ModApiV1 is NOT available")
    end

    if Mod then
        print("[DIAGNOSTIC] ✓ Mod global is available")
        print("[DIAGNOSTIC]   mod_dir = " .. tostring(safe_get(Mod, "mod_dir")))
        print("[DIAGNOSTIC]   mod_type = " .. tostring(safe_get(Mod, "mod_type")))
    end

    if Engine then
        print("[DIAGNOSTIC] ✓ Engine global is available")
    end

    print("[DIAGNOSTIC] ========================================\n")
    inspect_available_scenes()
end

function on_mod_reload()
    print("[DIAGNOSTIC] on_mod_reload() called - Mod was reloaded (F11)")
end

function on_device_spawned(device)
    if not config.enable_device_logging then return end

    print("\n[DIAGNOSTIC] ========== on_device_spawned() ==========")
    local product_name = safe_get(device, "product_name")
    local hw_class = safe_get(device, "device_hardware_class")
    local class_name = device_class_names[hw_class] or "UNKNOWN"
    
    print("[DIAGNOSTIC] Device spawned: " .. tostring(product_name) .. " (" .. class_name .. ")")
    
    -- Track device
    table.insert(spawned_devices, { device = device, product_name = product_name })

    if config.enable_network_inspection then
        local logic_controller = safe_get(device, "logic_controller")
        if logic_controller then
            local netctl = safe_get(logic_controller, "networkctl")
            if netctl then
                print("[DIAGNOSTIC]   hardware_address = " .. tostring(safe_get(netctl, "hardware_address")))
                print("[DIAGNOSTIC]   network_address = " .. tostring(safe_get(netctl, "network_address")))
            end
        end
    end

    print("[DIAGNOSTIC] =======================================\n")
end

function on_user_spawned(user)
    if not config.enable_user_logging then return end

    print("\n[DIAGNOSTIC] ========== on_user_spawned() ==========")

    local username = safe_get(user, "username")
    local user_profile = safe_get(user, "user_profile_name")
    local daily_rate = safe_get(user, "daily_rate")

    print("[DIAGNOSTIC]   username = " .. tostring(username))
    print("[DIAGNOSTIC]   user_profile_name = " .. tostring(user_profile))
    print("[DIAGNOSTIC]   daily_rate = $" .. tostring(daily_rate))

    local location = safe_get(user, "location")
    if location then
        print("[DIAGNOSTIC]   floor_num = " .. tostring(safe_get(location, "floor_num")))
    end

    print("[DIAGNOSTIC] =======================================\n")

    if config.track_users_for_reinspection then
        table.insert(spawned_users, { user = user, username = username })
    end

    inspect_user_network(user, "on_spawn")
end

function on_day_start()
    if config.enable_day_events then
        print("[DIAGNOSTIC] on_day_start() - New day started")
        
        if ModApiV1 then
            local world = ModApiV1.get_game_world()
            if world then
                print("[DIAGNOSTIC]   Day: " .. tostring(safe_get(world, "n_days")))
                print("[DIAGNOSTIC]   Cash: $" .. tostring(safe_get(world, "player_cash_balance")))
            end
        end
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

-- ============================================================================
-- KEYBOARD INPUT HANDLER
-- ============================================================================

-- Named helpers — see device-tweaker for explanation
local function _ev_get_class(e)         return e:get_class() end
local function _ev_get_keycode(e)       return e:get_keycode() end
local function _ev_is_pressed(e)        return e:is_pressed() end
local function _ev_is_shift_pressed(e)  return e:is_shift_pressed() end

local _input_gc_counter = 0

function on_player_input(event)
    _input_gc_counter = _input_gc_counter + 1
    if _input_gc_counter >= 100 then
        _input_gc_counter = 0
        collectgarbage("step")
    end

    local ok, event_class = pcall(_ev_get_class, event)
    if not ok or event_class ~= "InputEventKey" then return end

    do
        local ok1, keycode    = pcall(_ev_get_keycode, event)
        local ok2, is_pressed = pcall(_ev_is_pressed, event)
        local ok3, is_shift   = pcall(_ev_is_shift_pressed, event)
        if not (ok1 and ok2 and ok3) then return end

        -- Shift+R: Re-inspect users (keycode 82)
        if keycode == 82 and is_shift then
            if is_pressed and not key_states.shift_r then
                key_states.shift_r = true
                print("[DIAGNOSTIC] Shift+R detected - Running reinspect_all_users()...")
                reinspect_all_users()
            elseif not is_pressed then
                key_states.shift_r = false
            end
        end

        -- Shift+D: Dump devices (keycode 68)
        if keycode == 68 and is_shift then
            if is_pressed and not key_states.shift_d then
                key_states.shift_d = true
                print("[DIAGNOSTIC] Shift+D detected - Running dump_all_world_devices()...")
                dump_all_world_devices()
            elseif not is_pressed then
                key_states.shift_d = false
            end
        end

        -- Shift+J: Export JSON (keycode 74)
        if keycode == 74 and is_shift then
            if is_pressed and not key_states.shift_j then
                key_states.shift_j = true
                print("[DIAGNOSTIC] Shift+J detected - Exporting game state to JSON...")
                export_to_json_file()
            elseif not is_pressed then
                key_states.shift_j = false
            end
        end

        -- Shift+Q: Run API test suite (keycode 81)
        if keycode == 81 and is_shift then
            if is_pressed and not key_states.shift_q then
                key_states.shift_q = true
                print("[DIAGNOSTIC] Shift+Q detected - Running API test suite...")
                run_api_test_suite()
            elseif not is_pressed then
                key_states.shift_q = false
            end
        end
    end
end

-- ============================================================================
-- STARTUP MESSAGE
-- ============================================================================

print("=== ModAPI Diagnostic Tool v3.0 Setup Complete ===")
print("    Features:")
print("    - Engine load, device spawn, user spawn logging")
print("    - Network configuration inspection")
print("    - JSON game state export")
print("    - Comprehensive API test suite")
print("")
print("    Keyboard Shortcuts:")
print("    - Shift+R: Re-inspect all spawned users")
print("    - Shift+D: Dump all devices in the world")
print("    - Shift+J: Export game state to JSON")
print("    - Shift+Q: Run API test suite (Query)")
print("")
print("    Lua console commands:")
print("    - reinspect_all_users()")
print("    - dump_all_world_devices()")
print("    - inspect_scenes()")
print("    - export_to_json_file()")
print("    - run_api_test_suite()")
print("    - export_test_results_json()")
print("===")
