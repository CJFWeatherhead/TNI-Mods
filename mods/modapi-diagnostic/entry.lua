-- ModAPI Diagnostic Tool v4.6
-- Development tool for TNI game engine modding (game version 0.10.11+)
--
-- CHANGES from v4.5:
--   * Added inspect_fixture_outlets command for PHONE/CCTV investigation.
--     Phones and CCTVs are fixture outlets (DeviceOutlet), NOT DeviceUnit
--     instances, so on_device_spawned never fires for them.
--
-- CHANGES from v4.4:
--   * Removed standalone panel + on_tick polling (Callable bridge crash).
--   * All functionality via console commands only (press ~ to open).
--
-- CHANGES from v4.3:
--   * Debug console activation: sets DebugLayer.enabled=true, visible=true
--     so the ~ key opens the console (disabled by default in the game).
--   * Removed all probe code (findings documented in README).
--
-- CHANGES from v4.2:
--   * All console commands registered with DebugLayer.register_cmd()
--     so they appear in the debug console (~).
--   * Globals kept as fallback for direct Lua calls.
--
-- CHANGES from v3.x:
--   * REMOVED on_player_input entirely — eliminates the per-frame pcall/GC
--     overhead that was the root cause of memory issues.  All functionality
--     is available through console commands and automatic lifecycle hooks.
--   * Added every known callback: on_mod_load, on_mods_loaded,
--     on_game_state_ready, on_game_host_eod, on_location_spawned.
--   * on_game_state_ready runs a full initial diagnostic automatically.
--   * Auto-export JSON on day-end when config.auto_export_on_day_end = true.
--   * Expanded API coverage: get_locations, get_merchants,
--     get_game_version, has_mods_reloaded, new PlayOptions fields,
--     LogicControllerUser fields, NETWORK_STORAGE device class,
--     all control modules (dhcpctl, filesysctl, packetctl, vlanctl,
--     firewallctl, routectl), GameWorld new fields and methods.
--   * Updated device hardware class enum (added NETWORK_STORAGE = 20).
--   * Tracks lifecycle callback order for diagnosing init timing issues.
--
-- Console commands (debug console ~ or global Lua call):
--   dump_world_overview         reinspect_all_users
--   inspect_locations           dump_all_world_devices
--   inspect_fixture_outlets     export_to_json
--   run_api_test_suite          export_test_results_json
--   show_lifecycle_log

print("=== ModAPI Diagnostic Tool v4.5 Loading ===")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local config = {}
if Mod and Mod.config then
    config = Mod.config
    print("[DIAG] Configuration loaded from mod config")
else
    print("[DIAG] No config found, using defaults")

    -- Logging
    config.enable_device_logging    = true
    config.enable_user_logging      = true
    config.enable_location_logging  = true
    config.enable_day_events        = true
    config.enable_loan_events       = true
    config.enable_transaction_events = true

    -- Network Inspection
    config.enable_network_inspection       = true
    config.track_users_for_reinspection    = true

    -- Auto-triggers
    config.auto_diag_on_ready        = true   -- run diagnostics on game_state_ready
    config.auto_export_on_day_end    = false  -- JSON export every day end

    -- JSON Export Sections
    config.json_include_devices      = true
    config.json_include_users        = true
    config.json_include_locations    = true
    config.json_include_finances     = true
    config.json_include_network      = true
    config.json_include_play_options = true
    config.json_include_statistics   = true
    config.json_include_loans        = true
    config.json_include_hostings     = true
    config.json_include_merchants    = true
    config.json_include_programs     = true
    config.json_include_floor_builders = true
    config.json_include_messages     = true
    config.json_include_link_controller = true
    config.json_include_acquired_techs = true

    -- API Test Suite Sections
    config.test_mod_api        = true
    config.test_game_world     = true
    config.test_devices_api    = true
    config.test_users_api      = true
    config.test_network_api    = true
    config.test_filesystem_api = true
    config.test_locations_api  = true
    config.test_merchants_api  = true
    config.test_programs_api   = true
    config.test_world_methods  = true

    -- Advanced
    config.max_dump_depth      = 2
    config.show_notification   = true
    config.verbose_mode        = false
end

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================

local spawned_users     = {}
local spawned_devices   = {}
local spawned_locations = {}
local inspection_counter = 0

-- Lifecycle event log: records callback name + timestamp for debugging init order
local lifecycle_log = {}

local test_results = {
    timestamp = nil,
    tests     = {},
    summary   = { total = 0, passed = 0, failed = 0, skipped = 0 }
}

-- ============================================================================
-- CONSTANTS / ENUMS (updated for 0.10.11)
-- ============================================================================

local DEVICE_HW_CLASS = {
    [0]  = "DEFAULT",
    [1]  = "NETWORK_SWITCH",
    [2]  = "NETWORK_ROUTER",
    [3]  = "NETWORK_TAP",
    [4]  = "NETWORK_FIREWALL",
    [5]  = "MEDIA_LINE_SIMPLEX",
    [6]  = "MEDIA_LINE_DUPLEX",
    [7]  = "COMPUTE_SERVER",
    [8]  = "DISPLAY_MONITOR",
    [9]  = "DEBUGGER",
    [10] = "LOAD_TESTER",
    [11] = "POWER_EXPANSION",
    [12] = "DECENTRO_RIGS",
    [13] = "SURGE_PROTECTOR",
    [14] = "UPS",
    [15] = "INERT",
    [16] = "CCTV",
    [17] = "PHONE",
    [18] = "PRINTER",
    [19] = "NETWORK_LOAD_BALANCER",
    [20] = "NETWORK_STORAGE",
}

local TRANSACTION_CATEGORY = {
    [0]  = "UNKNOWN",
    [1]  = "INCOME",
    [2]  = "CAPEX",
    [3]  = "OPEX",
    [4]  = "PETTY",
    [5]  = "LOAN",
    [6]  = "INTEREST",
    [7]  = "INVESTMENT",
    [8]  = "DONATION",
    [9]  = "PROPOSAL_PROCESSING",
    [10] = "TRADING",
    [11] = "AGGREGATED",
    [12] = "PENALTY",
}

local STAT_NAME = {
    [0]  = "TOTAL_SERVICE_FLOORS",
    [1]  = "TOTAL_DATACENTERS",
    [2]  = "TOTAL_USERS",
    [3]  = "USER_MAJORITY",
    [4]  = "DAILY_SAT_AVG",
    [5]  = "DAILY_INCOME_AVG",
    [6]  = "TOTAL_SCHEDULED_OUTAGES_EXP",
    [7]  = "TOTAL_UNSCHEDULED_OUTAGES_EXP",
    [8]  = "TOTAL_SURGES_EXP",
    [9]  = "TOTAL_DEVS_FAILED",
    [10] = "TOTAL_LOANS_TAKEN",
    [11] = "TOTAL_DAYS_IN_DEBT",
    [12] = "TOTAL_PROPOSALS_SUBMITTED",
    [13] = "TOTAL_COFFEE_DRANK",
    [14] = "TOTAL_TEA_DRANK",
    [15] = "TOTAL_NETWORK_OUTAGES_SCHEDULED",
    [16] = "TOTAL_DEVS_SURGED",
    [17] = "TOTAL_CYBERATTACKS_ENCOUNTERED",
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function lifecycle(event_name, detail)
    local ts = nil
    pcall(function() ts = os.clock() end)
    lifecycle_log[#lifecycle_log + 1] = {
        event  = event_name,
        detail = detail,
        time   = ts,
    }
    print("[DIAG] >> " .. event_name .. (detail and (" -- " .. detail) or ""))
end

local function safe_get(obj, prop)
    if obj == nil then return nil end
    local ok, val = pcall(function() return obj[prop] end)
    return ok and val or nil
end

local function safe_call(obj, method, ...)
    if obj == nil then return nil, "object is nil" end
    local args = {...}
    local ok, result = pcall(function() return obj[method](obj, unpack(args)) end)
    if ok then return result, nil end
    return nil, result
end

local function array_to_table(arr)
    if arr == nil then return {} end
    if type(arr) == "table" then return arr end
    if type(arr) == "userdata" then
        local ok, size = pcall(function() return arr:size() end)
        if not ok or not size then return {} end
        local t = {}
        for i = 0, size - 1 do
            local vok, v = pcall(function() return arr:get(i) end)
            if vok then t[#t + 1] = v end
        end
        return t
    end
    return {}
end

local function count_table(t)
    if not t then return 0 end
    if type(t) == "table" then
        local n = 0
        for _ in pairs(t) do n = n + 1 end
        return n
    end
    -- userdata array
    local ok, size = pcall(function() return t:size() end)
    return (ok and size) or 0
end

local function notify(msg, tone)
    pcall(function()
        if not config.show_notification then return end
        local ui = ModApiV1 and ModApiV1.get_base_ui()
        if ui then ui:display_notification(msg, tone or 0) end
    end)
end

-- ============================================================================
-- JSON SERIALIZATION
-- ============================================================================

local function escape_json(s)
    if type(s) ~= "string" then return tostring(s) end
    return (s:gsub('\\', '\\\\')
             :gsub('"',  '\\"')
             :gsub('\n', '\\n')
             :gsub('\r', '\\r')
             :gsub('\t', '\\t'))
end

local function to_json(value, indent, depth)
    indent = indent or 2
    depth  = depth  or 0
    local max_d = config.max_dump_depth or 3

    if depth > max_d then return '"<max depth>"' end

    local pad  = string.rep(" ", indent * depth)
    local pad1 = string.rep(" ", indent * (depth + 1))

    if value == nil then return "null" end
    local t = type(value)
    if t == "boolean" then return value and "true" or "false" end
    if t == "number"  then
        if value ~= value then return "null" end                -- NaN
        if value == math.huge or value == -math.huge then return "null" end
        return tostring(value)
    end
    if t == "string"   then return '"' .. escape_json(value) .. '"' end
    if t == "function" then return '"<function>"' end
    if t == "userdata" then return '"<userdata: ' .. escape_json(tostring(value)) .. '>"' end

    if t == "table" then
        -- detect array
        local is_arr, mx = true, 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then is_arr = false; break end
            if k > mx then mx = k end
        end
        if is_arr and mx > 0 then
            local items = {}
            for i = 1, mx do items[i] = pad1 .. to_json(value[i], indent, depth + 1) end
            return "[\n" .. table.concat(items, ",\n") .. "\n" .. pad .. "]"
        end
        local items = {}
        for k, v in pairs(value) do
            local key = type(k) == "string" and k or tostring(k)
            items[#items + 1] = pad1 .. '"' .. escape_json(key) .. '": ' .. to_json(v, indent, depth + 1)
        end
        if #items == 0 then return "{}" end
        return "{\n" .. table.concat(items, ",\n") .. "\n" .. pad .. "}"
    end

    return '"<' .. t .. '>"'
end

-- ============================================================================
-- DATA EXTRACTION (expanded for 0.10.11)
-- ============================================================================

local function extract_program_data(prog)
    if not prog then return nil end
    return {
        release_name   = safe_get(prog, "release_name"),
        description    = safe_get(prog, "description"),
        is_running     = safe_get(prog, "is_running"),
        cpu_load       = safe_get(prog, "cpu_load"),
        code_size      = safe_get(prog, "code_size"),
        stack_size     = safe_get(prog, "stack_size"),
        data_size      = safe_get(prog, "data_size"),
        install_size   = safe_get(prog, "install_size"),
        pkt_processing_priority = safe_get(prog, "pkt_processing_priority"),
    }
end

local function extract_network_ctl(netctl)
    if not netctl then return nil end
    local data = {
        hardware_address   = safe_get(netctl, "hardware_address"),
        network_address    = safe_get(netctl, "network_address"),
        dhcp_enabled       = safe_get(netctl, "dhcp_enabled"),
        is_dhcp_enabled    = safe_get(netctl, "is_dhcp_enabled"),
        stp_enabled        = safe_get(netctl, "stp_enabled"),
        local_dns_mapping  = safe_get(netctl, "local_dns_mapping"),
        designated_dns_servers = {},
    }
    local dns_arr = safe_get(netctl, "designated_dns_servers")
    if dns_arr then
        local dt = array_to_table(dns_arr)
        for i, v in ipairs(dt) do data.designated_dns_servers[i] = tostring(v) end
    end
    -- etc_hosts
    local etc = safe_get(netctl, "etc_hosts")
    if etc and type(etc) == "table" then
        data.etc_hosts = {}
        for k, v in pairs(etc) do data.etc_hosts[tostring(k)] = tostring(v) end
    end
    return data
end

local function extract_route_ctl(routectl)
    if not routectl then return nil end
    return {
        default_route_port_id = safe_get(routectl, "default_route_port_id"),
        broadcast_forwarding  = safe_get(routectl, "broadcast_forwarding"),
        rip_enabled           = safe_get(routectl, "rip_enabled"),
        routing_table_size    = count_table(safe_get(routectl, "routing_table")),
    }
end

local function extract_firewall_ctl(fwctl)
    if not fwctl then return nil end
    local fw_table = safe_get(fwctl, "firewall_table")
    return {
        default_policy_allows = safe_get(fwctl, "default_firewall_policy_allows"),
        rule_count            = fw_table and count_table(fw_table) or 0,
    }
end

local function extract_vlan_ctl(vlanctl)
    if not vlanctl then return nil end
    return {
        port_tags_count = count_table(safe_get(vlanctl, "vlan_port_tags")),
        subif_count     = count_table(safe_get(vlanctl, "subif_cfg")),
    }
end

local function extract_dhcp_ctl(dhcpctl)
    if not dhcpctl then return nil end
    return { exists = true }
end

local function extract_filesys_ctl(fsctl)
    if not fsctl then return nil end
    return { exists = true }
end

local function extract_packet_ctl(pktctl)
    if not pktctl then return nil end
    return { exists = true }
end

local function extract_logic_controller(lc)
    if not lc then return nil end
    local data = {
        hardware_address    = safe_get(lc, "hardware_address"),
        network_address     = safe_get(lc, "network_address"),
        print_name          = safe_get(lc, "print_name"),
        installed_cpu       = safe_get(lc, "installed_cpu"),
        installed_mem       = safe_get(lc, "installed_mem"),
        installed_sto       = safe_get(lc, "installed_sto"),
        installed_nbw       = safe_get(lc, "installed_nbw"),
        power_load          = safe_get(lc, "power_load"),
        os_running          = safe_get(lc, "os_running"),
        cpu_load            = safe_get(lc, "cpu_load"),
        free_memory         = safe_get(lc, "free_memory"),
        free_storage        = safe_get(lc, "free_storage"),
        free_nbw            = safe_get(lc, "free_nbw"),
        is_virtual          = safe_get(lc, "is_virtual"),
        is_network_switch   = safe_get(lc, "is_network_switch"),
        is_network_router   = safe_get(lc, "is_network_router"),
        is_network_middlebox = safe_get(lc, "is_network_middlebox"),
        is_hardware_nlb     = safe_get(lc, "is_hardware_nlb"),
        is_network_lb       = safe_get(lc, "is_network_lb"),
        is_dns_server       = safe_get(lc, "is_dns_server"),
        is_dhcp_server      = safe_get(lc, "is_dhcp_server"),
        is_network_tap      = safe_get(lc, "is_network_tap"),
        is_network_filter   = safe_get(lc, "is_network_filter"),
        is_ha_enabled       = safe_get(lc, "is_ha_enabled"),
        is_vlan_enabled     = safe_get(lc, "is_vlan_enabled"),
        is_stp_enabled      = safe_get(lc, "is_stp_enabled"),
        is_user_host        = safe_get(lc, "is_user_host"),
        is_link_host        = safe_get(lc, "is_link_host"),
        is_device_host      = safe_get(lc, "is_device_host"),
    }

    -- Control modules
    data.networkctl  = extract_network_ctl(safe_get(lc, "networkctl"))
    data.routectl    = extract_route_ctl(safe_get(lc, "routectl"))
    data.firewallctl = extract_firewall_ctl(safe_get(lc, "firewallctl"))
    data.vlanctl     = extract_vlan_ctl(safe_get(lc, "vlanctl"))
    data.dhcpctl     = extract_dhcp_ctl(safe_get(lc, "dhcpctl"))
    data.filesysctl  = extract_filesys_ctl(safe_get(lc, "filesysctl"))
    data.packetctl   = extract_packet_ctl(safe_get(lc, "packetctl"))

    -- Installed programs
    local progs = safe_get(lc, "installed_programs")
    if progs then
        data.installed_programs = {}
        local pt = array_to_table(progs)
        for i, p in ipairs(pt) do data.installed_programs[i] = extract_program_data(p) end
    end

    return data
end

local function extract_power_controller(pc)
    if not pc then return nil end
    return {
        charges           = safe_get(pc, "charges"),
        charge_capacity   = safe_get(pc, "charge_capacity"),
        charge_ratio      = safe_get(pc, "charge_ratio"),
        charge_rate       = safe_get(pc, "charge_rate"),
        current_load      = safe_get(pc, "current_load"),
        functional        = safe_get(pc, "functional"),
        can_supply_power  = safe_get(pc, "can_supply_power"),
        surge_blocker     = safe_get(pc, "surge_blocker"),
        sus_enabled       = safe_get(pc, "sus_enabled"),
        propagate_charges = safe_get(pc, "propagate_charges"),
    }
end

local function extract_device_data(device)
    if not device then return nil end
    local hw = safe_get(device, "device_hardware_class")
    return {
        product_name               = safe_get(device, "product_name"),
        description                = safe_get(device, "description"),
        device_hardware_class      = hw,
        device_hardware_class_name = DEVICE_HW_CLASS[hw] or "UNKNOWN",
        price                      = safe_get(device, "price"),
        base_warranty_days         = safe_get(device, "base_warranty_days"),
        base_warranty_cycles       = safe_get(device, "base_warranty_cycles"),
        warranty_period_remaining  = safe_get(device, "warranty_period_remaining"),
        condition                  = safe_get(device, "condition"),
        current_floor_num          = safe_get(device, "current_floor_num"),
        bw_per_second              = safe_get(device, "bw_per_second"),
        reliability_flt            = safe_get(device, "reliability_flt"),
        auto_servicing_enabled     = safe_get(device, "auto_servicing_enabled"),
        custom_user_note           = safe_get(device, "custom_user_note"),
        obtained_from              = safe_get(device, "obtained_from"),
        asset_registration_day     = safe_get(device, "asset_registration_day"),
        logic_controller           = extract_logic_controller(safe_get(device, "logic_controller")),
        power_controller           = extract_power_controller(safe_get(device, "power_controller")),
    }
end

local function extract_user_data(user)
    if not user then return nil end
    local loc = safe_get(user, "location")
    local data = {
        username                         = safe_get(user, "username"),
        user_profile_name                = safe_get(user, "user_profile_name"),
        description                      = safe_get(user, "description"),
        daily_rate                       = safe_get(user, "daily_rate"),
        satiety_ratio                    = safe_get(user, "satiety_ratio"),
        is_active                        = safe_get(user, "is_active"),
        average_satiety_ratio_last_tick  = safe_get(user, "average_satiety_ratio_last_tick"),
        lowest_satiety_ratio             = safe_get(user, "lowest_satiety_ratio"),
        usage_fulfilment_today           = safe_get(user, "usage_fulfilment_today"),
        grace_days_left                  = safe_get(user, "grace_days_left"),
        downtime_sla_seconds             = safe_get(user, "downtime_sla_seconds"),
        eagerness_factor                 = safe_get(user, "eagerness_factor"),
        base_use_period                  = safe_get(user, "base_use_period"),
        use_period_variance              = safe_get(user, "use_period_variance"),
        init_grace_days                  = safe_get(user, "init_grace_days"),
        max_satiety_decay_ratio          = safe_get(user, "max_satiety_decay_ratio"),
        satiety_sla_ratio                = safe_get(user, "satiety_sla_ratio"),
        unknown_user                     = safe_get(user, "unknown_user"),
    }

    -- LogicControllerUser extended fields
    data.payment_calculation_method    = safe_get(user, "payment_calculation_method")
    data.consumption_payment_scaling   = safe_get(user, "consumption_payment_scaling")
    data.bandwidth_used_last_tick      = safe_get(user, "bandwidth_used_last_tick")
    data.consumption_total_this_tick   = safe_get(user, "consumption_total_this_tick")
    data.consumption_satiety_this_tick = safe_get(user, "consumption_satiety_this_tick")
    data.visitation_satiety_last_tick  = safe_get(user, "visitation_satiety_last_tick")
    data.payment_today                 = safe_get(user, "payment_today")
    data.csr                           = safe_get(user, "csr")
    data.vsr                           = safe_get(user, "vsr")

    if loc then
        data.location = {
            floor_num    = safe_get(loc, "floor_num"),
            display_name = safe_get(loc, "display_name"),
        }
    end

    -- Logic controller (users are LogicControllerUser)
    data.logic_controller = extract_logic_controller(safe_get(user, "logic_controller"))

    return data
end

local function extract_location_data(location)
    if not location then return nil end
    local users = safe_get(location, "users")
    local ut = users and array_to_table(users)
    return {
        display_name              = safe_get(location, "display_name"),
        floor_num                 = safe_get(location, "floor_num"),
        description               = safe_get(location, "description"),
        width                     = safe_get(location, "width"),
        height                    = safe_get(location, "height"),
        is_datacenter             = safe_get(location, "is_datacenter"),
        surge_immunity            = safe_get(location, "surge_immunity"),
        outage_immunity           = safe_get(location, "outage_immunity"),
        network_outage_flag       = safe_get(location, "network_outage_flag"),
        spawn_limit               = safe_get(location, "spawn_limit"),
        will_not_spawn_before_day = safe_get(location, "will_not_spawn_before_day"),
        slot_index                = safe_get(location, "slot_index"),
        builder_weight            = safe_get(location, "builder_weight"),
        user_count                = ut and #ut or 0,
    }
end

local function extract_transaction_data(tx)
    if not tx then return nil end
    local cat = safe_get(tx, "category")
    return {
        amount        = safe_get(tx, "amount"),
        details       = safe_get(tx, "details"),
        date          = safe_get(tx, "date"),
        category      = cat,
        category_name = TRANSACTION_CATEGORY[cat] or "UNKNOWN",
    }
end

local function extract_loan_data(loan)
    if not loan then return nil end
    return {
        title          = safe_get(loan, "title"),
        amount         = safe_get(loan, "amount"),
        daily_interest = safe_get(loan, "daily_interest"),
        date           = safe_get(loan, "date"),
        description    = safe_get(loan, "description"),
    }
end

local function extract_hosting_data(h)
    if not h then return nil end
    return {
        fqdn                   = safe_get(h, "fqdn"),
        ppu                    = safe_get(h, "ppu"),
        today_visit_count      = safe_get(h, "today_visit_count"),
        historical_visit_count = safe_get(h, "historical_visit_count"),
        today_payment          = safe_get(h, "today_payment"),
        registered_on_day      = safe_get(h, "registered_on_day"),
        payment_today          = safe_get(h, "payment_today"),
    }
end

local function extract_merchant_data(m)
    if not m then return nil end
    local listings = safe_get(m, "listings")
    local lt = listings and array_to_table(listings)
    local listing_data = nil
    if lt and #lt > 0 then
        listing_data = {}
        for i, l in ipairs(lt) do
            listing_data[i] = {
                listing_title = safe_get(l, "listing_title"),
                price         = safe_get(l, "price"),
                stock         = safe_get(l, "stock"),
                max_stock     = safe_get(l, "max_stock"),
                available     = safe_get(l, "available"),
                warranty_period = safe_get(l, "warranty_period"),
            }
        end
    end
    return {
        display_name          = safe_get(m, "display_name"),
        description           = safe_get(m, "description"),
        price_multiplier      = safe_get(m, "price_multiplier"),
        warranty_multiplier   = safe_get(m, "warranty_multiplier"),
        restock_period        = safe_get(m, "restock_period"),
        restock_mode          = safe_get(m, "restock_mode"),
        price_add_constant    = safe_get(m, "price_add_constant"),
        warranty_add_constant = safe_get(m, "warranty_add_constant"),
        listings_count        = lt and #lt or 0,
        listings              = listing_data,
    }
end

local function extract_message_data(msg)
    if not msg then return nil end
    return {
        msgid   = safe_get(msg, "msgid"),
        title   = safe_get(msg, "title"),
        content = safe_get(msg, "content"),
        date    = safe_get(msg, "date"),
        read    = safe_get(msg, "read"),
    }
end

local function extract_floor_builder_data(fb)
    if not fb then return nil end
    local opts = safe_get(fb, "build_options")
    return {
        disabled             = safe_get(fb, "disabled"),
        skip_interval_builds = safe_get(fb, "skip_interval_builds"),
        min_date             = safe_get(fb, "min_date"),
        max_date             = safe_get(fb, "max_date"),
        build_interval       = safe_get(fb, "build_interval"),
        build_options_count  = opts and count_table(opts) or 0,
    }
end

local function extract_link_controller_data(lc)
    if not lc then return nil end
    local links = safe_get(lc, "links")
    return {
        link_count = links and count_table(links) or 0,
    }
end

-- ============================================================================
-- GAME STATE EXPORT (JSON)
-- ============================================================================

local function build_game_state()
    local world = ModApiV1 and ModApiV1.get_game_world()
    if not world then
        print("[DIAG] Cannot export: world is nil")
        return nil
    end

    local ts, ds = nil, nil
    pcall(function() ts = os.time(); ds = os.date("%Y-%m-%dT%H:%M:%S") end)

    -- Game version
    local game_ver = nil
    if ModApiV1.get_game_version then
        pcall(function()
            local v = ModApiV1.get_game_version()
            if v then game_ver = tostring(v) end
        end)
    end

    local state = {
        _metadata = {
            tool_version     = "4.4",
            game_version     = game_ver,
            export_timestamp = ts,
            export_date      = ds,
        },
        world = {
            scenario_name        = safe_get(world, "scenario_name"),
            n_days               = safe_get(world, "n_days"),
            days_in_debt         = safe_get(world, "days_in_debt"),
            player_cash_balance  = safe_get(world, "player_cash_balance"),
            day_opening_balance  = safe_get(world, "day_opening_balance"),
            payment_due_today    = safe_get(world, "payment_due_today"),
            time_mult            = safe_get(world, "time_mult"),
            game_time_str        = safe_get(world, "game_time_str"),
            game_dt_str          = safe_get(world, "game_dt_str"),
            difficulty_level     = safe_get(world, "difficulty_level"),
            rng_seed             = safe_get(world, "rng_seed"),
            autosave_enabled     = safe_get(world, "autosave_enabled"),
        },
    }

    -- Play Options (expanded for 0.10.11)
    if config.json_include_play_options then
        local po = safe_get(world, "play_options")
        if po then
            state.play_options = {
                starting_cash                     = safe_get(po, "starting_cash"),
                day_period                        = safe_get(po, "day_period"),
                freeplay                          = safe_get(po, "freeplay"),
                waive_power_fee                   = safe_get(po, "waive_power_fee"),
                infinite_bandwidth_mode           = safe_get(po, "infinite_bandwidth_mode"),
                max_days_in_debt                  = safe_get(po, "max_days_in_debt"),
                user_fee_payment_multiplier       = safe_get(po, "user_fee_payment_multiplier"),
                daily_admin_expenses              = safe_get(po, "daily_admin_expenses"),
                device_malfunction_occurrence_rate = safe_get(po, "device_malfunction_occurrence_rate"),
                power_outage_occurrence_rate       = safe_get(po, "power_outage_occurrence_rate"),
                power_surge_occurrence_rate        = safe_get(po, "power_surge_occurrence_rate"),
                device_warranty_period_multiplier  = safe_get(po, "device_warranty_period_multiplier"),
                floor_build_maximum_floors         = safe_get(po, "floor_build_maximum_floors"),
                proposal_batch_size                = safe_get(po, "proposal_batch_size"),
                lab_mode                           = safe_get(po, "lab_mode"),
                -- New in 0.10.11
                auto_create_dns_mappings           = safe_get(po, "auto_create_dns_mappings"),
                device_collisions                  = safe_get(po, "device_collisions"),
                local_dns_mapping                  = safe_get(po, "local_dns_mapping"),
                program_autostart                  = safe_get(po, "program_autostart"),
                cybattack_occurrence_rate           = safe_get(po, "cybattack_occurrence_rate"),
                user_hwreset_probability           = safe_get(po, "user_hwreset_probability"),
                tower_wide_user_dhcp_default       = safe_get(po, "tower_wide_user_dhcp_default"),
                tower_wide_device_dhcp_default     = safe_get(po, "tower_wide_device_dhcp_default"),
                user_grace_days_multiplier         = safe_get(po, "user_grace_days_multiplier"),
                user_sla_breach_time_factor_multiplier = safe_get(po, "user_sla_breach_time_factor_multiplier"),
                proposal_refresh                   = safe_get(po, "proposal_refresh"),
                socket_installation_cost           = safe_get(po, "socket_installation_cost"),
                admin_fee_scaling_multiplier       = safe_get(po, "admin_fee_scaling_multiplier"),
                floor_build_period_multiplier      = safe_get(po, "floor_build_period_multiplier"),
                tenabolt_penalty                   = safe_get(po, "tenabolt_penalty"),
                memento_daily_rate_per_device      = safe_get(po, "memento_daily_rate_per_device"),
                memento_replacement_rate           = safe_get(po, "memento_replacement_rate"),
                ppu_change_fee                     = safe_get(po, "ppu_change_fee"),
            }
            print("[DIAG] + play_options")
        end
    end

    -- Devices (try ModApiV1.get_devices first)
    if config.json_include_devices then
        state.devices = {}
        local devs = nil
        if ModApiV1 and ModApiV1.get_devices then
            pcall(function() devs = ModApiV1.get_devices() end)
        end
        if devs then
            local dt = array_to_table(devs)
            for i, d in ipairs(dt) do state.devices[i] = extract_device_data(d) end
            print("[DIAG] + " .. #dt .. " devices")
        end
    end

    -- Users
    if config.json_include_users then
        state.users = {}
        local users = nil
        if ModApiV1 and ModApiV1.get_users then
            pcall(function() users = ModApiV1.get_users() end)
        end
        if not users then users = safe_get(world, "users") end
        if users then
            local ut = array_to_table(users)
            for i, u in ipairs(ut) do state.users[i] = extract_user_data(u) end
            print("[DIAG] + " .. #ut .. " users")
        end
    end

    -- Locations (try new ModApiV1.get_locations first)
    if config.json_include_locations then
        state.locations = {}
        local locs = nil
        if ModApiV1 and ModApiV1.get_locations then
            pcall(function() locs = ModApiV1.get_locations() end)
        end
        if not locs then locs = safe_get(world, "locations") end
        if locs then
            local lt = array_to_table(locs)
            for i, l in ipairs(lt) do state.locations[i] = extract_location_data(l) end
            print("[DIAG] + " .. #lt .. " locations")
        end
    end

    -- Finances
    if config.json_include_finances then
        state.finances = {
            cash_balance       = safe_get(world, "player_cash_balance"),
            day_opening_balance = safe_get(world, "day_opening_balance"),
            payment_due_today  = safe_get(world, "payment_due_today"),
            transaction_count  = safe_get(world, "player_transaction_count"),
        }
        local txs = safe_get(world, "player_transactions")
        if txs then
            state.finances.recent_transactions = {}
            local tt = array_to_table(txs)
            local start = math.max(1, #tt - 19)
            for i = start, #tt do
                state.finances.recent_transactions[#state.finances.recent_transactions + 1] =
                    extract_transaction_data(tt[i])
            end
            print("[DIAG] + " .. #state.finances.recent_transactions .. " recent transactions")
        end
        local ok, bd = pcall(function() return world:calculate_payment_due_breakdown(true) end)
        if ok and bd then state.finances.payment_breakdown = bd end
    end

    -- Loans
    if config.json_include_loans then
        state.loans = {}
        local loans = safe_get(world, "player_loans")
        if loans then
            local lt = array_to_table(loans)
            for i, l in ipairs(lt) do state.loans[i] = extract_loan_data(l) end
            print("[DIAG] + " .. #lt .. " loans")
        end
    end

    -- Player Hostings
    if config.json_include_hostings then
        state.player_hostings = {}
        local hs = safe_get(world, "player_hostings")
        if hs then
            local ht = array_to_table(hs)
            for i, h in ipairs(ht) do state.player_hostings[i] = extract_hosting_data(h) end
            print("[DIAG] + " .. #ht .. " player hostings")
        end
    end

    -- Merchants (try new ModApiV1.get_merchants first)
    if config.json_include_merchants then
        state.merchants = {}
        local ms = nil
        if ModApiV1 and ModApiV1.get_merchants then
            pcall(function() ms = ModApiV1.get_merchants() end)
        end
        if not ms then ms = safe_get(world, "device_merchants") end
        if ms then
            local mt = array_to_table(ms)
            for i, m in ipairs(mt) do state.merchants[i] = extract_merchant_data(m) end
            print("[DIAG] + " .. #mt .. " merchants")
        end
    end

    -- Statistics
    if config.json_include_statistics then
        local gs = safe_get(world, "game_stats")
        if gs then
            state.statistics = {}
            local sd = safe_get(gs, "data")
            if sd and type(sd) == "table" then
                for k, v in pairs(sd) do
                    state.statistics[STAT_NAME[k] or tostring(k)] = v
                end
            end
            print("[DIAG] + statistics")
        end
    end

    -- Daycycle Controller
    local dc = safe_get(world, "daycycle_controller")
    if dc then
        state.daycycle = {
            day_period          = safe_get(dc, "day_period"),
            day_clock           = safe_get(dc, "day_clock"),
            normal_clock        = safe_get(dc, "normal_clock"),
            paused              = safe_get(dc, "paused"),
            sunrise_time_float  = safe_get(dc, "sunrise_time_float"),
            sunset_time_float   = safe_get(dc, "sunset_time_float"),
        }
    end

    -- Network lookups
    if config.json_include_network then
        local dns = safe_get(world, "dns_lookup")
        if dns and type(dns) == "table" then
            state.dns_lookup = {}
            for k, v in pairs(dns) do state.dns_lookup[tostring(k)] = tostring(v) end
            print("[DIAG] + DNS lookup table")
        end
        local nw = safe_get(world, "nwaddr_lookup")
        if nw and type(nw) == "table" then
            state.nwaddr_lookup = {}
            for k, v in pairs(nw) do state.nwaddr_lookup[tostring(k)] = tostring(v) end
            print("[DIAG] + network address lookup")
        end
    end

    -- Player Messages
    if config.json_include_messages then
        local msgs = safe_get(world, "player_messages")
        if msgs then
            state.player_messages = {}
            local mt = array_to_table(msgs)
            for i, m in ipairs(mt) do state.player_messages[i] = extract_message_data(m) end
            print("[DIAG] + " .. #mt .. " player messages")
        end
    end

    -- Floor Builders
    if config.json_include_floor_builders then
        local fbs = safe_get(world, "floor_builders")
        if fbs then
            state.floor_builders = {}
            local ft = array_to_table(fbs)
            for i, fb in ipairs(ft) do state.floor_builders[i] = extract_floor_builder_data(fb) end
            print("[DIAG] + " .. #ft .. " floor builders")
        end
    end

    -- Link Controller
    if config.json_include_link_controller then
        local lc = safe_get(world, "link_controller")
        if lc then
            state.link_controller = extract_link_controller_data(lc)
            print("[DIAG] + link controller")
        end
    end

    -- Acquired Techs
    if config.json_include_acquired_techs then
        local techs = safe_get(world, "acquired_techs")
        if techs then
            state.acquired_techs = {}
            local tt = array_to_table(techs)
            for i, t in ipairs(tt) do state.acquired_techs[i] = tostring(t) end
            print("[DIAG] + " .. #tt .. " acquired techs")
        end
    end

    -- Lifecycle log snapshot
    state.lifecycle_log = lifecycle_log

    print("[DIAG] Game state extraction complete")
    return state
end

function export_to_json()
    print("\n[DIAG] ========== Exporting Game State to JSON ==========")
    local state = build_game_state()
    if not state then
        notify("JSON Export Failed -- check logs", 1)
        return false
    end

    local json = to_json(state, 2, 0)
    local size = #json

    print("[DIAG] === JSON GAME STATE START ===")
    local chunk = 4000
    for i = 1, math.ceil(size / chunk) do
        local s = (i - 1) * chunk + 1
        print(json:sub(s, math.min(i * chunk, size)))
    end
    print("[DIAG] === JSON GAME STATE END ===")
    print("[DIAG] JSON size: " .. size .. " bytes")

    -- Also try writing via ModFileSystem
    local wrote_file = false
    if Mod and Mod.filesystem then
        pcall(function()
            local fs = Mod.filesystem
            local fh = fs:open("/diagnostic-export.json", 2)  -- WRITE mode
            if fh then
                fh:store_string(json)
                fh:close()
                wrote_file = true
                print("[DIAG] Written to mod dir: diagnostic-export.json")
            end
        end)
    end

    if wrote_file then
        notify("JSON exported to file (" .. size .. " bytes)", 0)
    else
        notify("JSON exported to logs (" .. size .. " bytes)", 0)
    end
    return true
end

-- Backwards compat alias
export_to_json_file = export_to_json

-- ============================================================================
-- API TEST SUITE (expanded for 0.10.11)
-- ============================================================================

local function reset_tests()
    test_results = {
        timestamp = nil,
        tests     = {},
        summary   = { total = 0, passed = 0, failed = 0, skipped = 0 },
    }
    pcall(function() test_results.timestamp = os.time() end)
end

local function add_result(cat, name, passed, details, err)
    test_results.tests[#test_results.tests + 1] = {
        category = cat, name = name, passed = passed,
        details  = details, error = err,
    }
    test_results.summary.total = test_results.summary.total + 1
    if passed then
        test_results.summary.passed = test_results.summary.passed + 1
    else
        test_results.summary.failed = test_results.summary.failed + 1
    end
end

local function run_test(cat, name, fn)
    local ok, res = pcall(fn)
    if ok then
        if type(res) == "table" then
            add_result(cat, name, res.passed, res.details, res.error)
        else
            add_result(cat, name, res ~= nil and res ~= false, tostring(res), nil)
        end
    else
        add_result(cat, name, false, nil, tostring(res))
    end
end

function run_api_test_suite()
    print("\n[DIAG] ========== API Test Suite ==========")
    reset_tests()

    -- == ModApiV1 =============================================================
    if config.test_mod_api then
        print("[DIAG] Testing ModApiV1...")

        run_test("ModApiV1", "exists", function()
            return { passed = ModApiV1 ~= nil, details = ModApiV1 ~= nil and "available" or "nil" }
        end)

        run_test("ModApiV1", "sanity()", function()
            if not ModApiV1 then return { passed = false, error = "nil" } end
            ModApiV1.sanity()
            return { passed = true, details = "OK" }
        end)

        run_test("ModApiV1", "get_game_world()", function()
            local w = ModApiV1.get_game_world()
            return { passed = w ~= nil, details = w ~= nil and "returned" or "nil" }
        end)

        run_test("ModApiV1", "get_game_version()", function()
            if not ModApiV1.get_game_version then
                return { passed = false, details = "method missing" }
            end
            local v = ModApiV1.get_game_version()
            return { passed = v ~= nil, details = "version = " .. tostring(v) }
        end)

        run_test("ModApiV1", "has_mods_reloaded()", function()
            if not ModApiV1.has_mods_reloaded then
                return { passed = false, details = "method missing" }
            end
            local r = ModApiV1.has_mods_reloaded()
            return { passed = true, details = "reloaded = " .. tostring(r) }
        end)

        run_test("ModApiV1", "get_player_camera()", function()
            local c = ModApiV1.get_player_camera()
            return { passed = true, details = c ~= nil and "returned" or "nil (may be normal)" }
        end)

        run_test("ModApiV1", "get_base_ui()", function()
            local ui = ModApiV1.get_base_ui()
            return { passed = ui ~= nil, details = ui ~= nil and "returned" or "nil" }
        end)

        run_test("ModApiV1", "get_devices()", function()
            local d = ModApiV1.get_devices()
            local n = d and #array_to_table(d) or 0
            return { passed = d ~= nil, details = n .. " devices" }
        end)

        run_test("ModApiV1", "get_users()", function()
            local u = ModApiV1.get_users()
            local n = u and #array_to_table(u) or 0
            return { passed = u ~= nil, details = n .. " users" }
        end)

        run_test("ModApiV1", "get_locations()", function()
            if not ModApiV1.get_locations then
                return { passed = false, details = "method missing" }
            end
            local l = ModApiV1.get_locations()
            local n = l and #array_to_table(l) or 0
            return { passed = l ~= nil, details = n .. " locations" }
        end)

        run_test("ModApiV1", "get_merchants()", function()
            if not ModApiV1.get_merchants then
                return { passed = false, details = "method missing" }
            end
            local m = ModApiV1.get_merchants()
            local n = m and #array_to_table(m) or 0
            return { passed = m ~= nil, details = n .. " merchants" }
        end)
    end

    -- == Mod global ===========================================================
    if config.test_mod_api then
        print("[DIAG] Testing Mod global...")

        run_test("Mod", "exists", function()
            return { passed = Mod ~= nil, details = Mod ~= nil and "available" or "nil" }
        end)

        run_test("Mod", "mod_dir", function()
            local d = safe_get(Mod, "mod_dir")
            return { passed = d ~= nil, details = "mod_dir = " .. tostring(d) }
        end)

        run_test("Mod", "mod_type", function()
            local t = safe_get(Mod, "mod_type")
            return { passed = t ~= nil, details = "mod_type = " .. tostring(t) }
        end)

        run_test("Mod", "manifest", function()
            local m = safe_get(Mod, "manifest")
            if not m then return { passed = false, details = "nil" } end
            return { passed = true, details = "id=" .. tostring(safe_get(m, "id")) ..
                " v=" .. tostring(safe_get(m, "version")) }
        end)

        run_test("Mod", "filesystem", function()
            local fs = safe_get(Mod, "filesystem")
            return { passed = fs ~= nil, details = fs ~= nil and "available" or "nil" }
        end)

        run_test("Mod", "config", function()
            local c = safe_get(Mod, "config")
            return { passed = true, details = c ~= nil and "available" or "nil (using defaults)" }
        end)
    end

    -- == GameWorld =============================================================
    if config.test_game_world then
        print("[DIAG] Testing GameWorld...")
        local world = ModApiV1 and ModApiV1.get_game_world()

        local world_props = {
            "scenario_name", "n_days", "player_cash_balance", "play_options",
            "game_stats", "locations", "users", "player_loans", "player_hostings",
            "device_merchants", "daycycle_controller", "loan_controller",
            "link_controller", "floor_builders", "player_messages",
            "acquired_techs", "dns_lookup",
        }

        for _, prop in ipairs(world_props) do
            run_test("GameWorld", "world." .. prop, function()
                if not world then return { passed = false, error = "world nil" } end
                local v = safe_get(world, prop)
                local detail
                if v == nil then
                    detail = "nil"
                elseif type(v) == "userdata" or type(v) == "table" then
                    detail = type(v) .. " (count=" .. count_table(v) .. ")"
                else
                    detail = tostring(v)
                end
                -- dns_lookup may be empty early game, still a pass
                local pass = v ~= nil or prop == "dns_lookup"
                return { passed = pass, details = detail }
            end)
        end

        run_test("GameWorld", "calculate_payment_due_breakdown()", function()
            if not world then return { passed = false, error = "world nil" } end
            local ok, r = pcall(function() return world:calculate_payment_due_breakdown(true) end)
            return { passed = ok, details = ok and "callable" or "failed", error = not ok and tostring(r) or nil }
        end)

        -- Test new world methods existence
        local world_methods = {
            "send_player_message", "put_dns_entry", "lookup_domain",
            "add_location", "try_add_merchant", "try_release_program",
            "submit_user_complaint", "modify_player_cash",
        }
        for _, m in ipairs(world_methods) do
            run_test("GameWorld", "method: " .. m, function()
                if not world then return { passed = false, error = "world nil" } end
                local fn = safe_get(world, m)
                return { passed = fn ~= nil, details = fn ~= nil and "present" or "missing" }
            end)
        end
    end

    -- == Device API ============================================================
    if config.test_devices_api then
        print("[DIAG] Testing Device API...")
        local devices = ModApiV1 and ModApiV1.get_devices()
        local first = nil
        if devices then
            local dt = array_to_table(devices)
            if #dt > 0 then first = dt[1] end
        end

        if first then
            local dev_props = {
                "product_name", "device_hardware_class", "price",
                "base_warranty_days", "base_warranty_cycles",
                "warranty_period_remaining", "condition", "bw_per_second",
                "reliability_flt", "current_floor_num",
            }
            for _, prop in ipairs(dev_props) do
                run_test("DeviceUnit", "device." .. prop, function()
                    local v = safe_get(first, prop)
                    return { passed = v ~= nil, details = tostring(v) }
                end)
            end

            run_test("DeviceUnit", "logic_controller", function()
                local lc = safe_get(first, "logic_controller")
                return { passed = true, details = lc ~= nil and "present" or "nil (normal for some)" }
            end)

            run_test("DeviceUnit", "power_controller", function()
                local pc = safe_get(first, "power_controller")
                return { passed = true, details = pc ~= nil and "present" or "nil (normal for some)" }
            end)

            run_test("DeviceUnit", "method: apply_autoconfig", function()
                local fn = safe_get(first, "apply_autoconfig")
                return { passed = fn ~= nil, details = fn ~= nil and "present" or "missing" }
            end)
        else
            add_result("DeviceUnit", "no devices", true, "skipped -- no devices in world", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end

    -- == User API ==============================================================
    if config.test_users_api then
        print("[DIAG] Testing User API...")
        local users = ModApiV1 and ModApiV1.get_users()
        local first = nil
        if users then
            local ut = array_to_table(users)
            if #ut > 0 then first = ut[1] end
        end

        if first then
            local user_props = {
                "username", "user_profile_name", "daily_rate", "satiety_ratio",
                "is_active", "usage_fulfilment_today", "grace_days_left",
                "location", "downtime_sla_seconds", "eagerness_factor",
            }
            for _, prop in ipairs(user_props) do
                run_test("User", "user." .. prop, function()
                    local v = safe_get(first, prop)
                    return { passed = v ~= nil, details = tostring(v) }
                end)
            end

            -- LogicControllerUser extended fields
            local lcu_props = {
                "logic_controller", "payment_calculation_method",
                "consumption_payment_scaling", "bandwidth_used_last_tick",
                "payment_today", "csr", "vsr",
            }
            for _, prop in ipairs(lcu_props) do
                run_test("LogicControllerUser", "user." .. prop, function()
                    local v = safe_get(first, prop)
                    return { passed = true, details = v ~= nil and tostring(v) or "nil (may be normal)" }
                end)
            end
        else
            add_result("User", "no users", true, "skipped -- no users in world", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end

    -- == Locations API =========================================================
    if config.test_locations_api then
        print("[DIAG] Testing Locations API...")
        local locs = nil
        if ModApiV1 and ModApiV1.get_locations then
            pcall(function() locs = ModApiV1.get_locations() end)
        end
        if not locs then
            local w = ModApiV1 and ModApiV1.get_game_world()
            if w then locs = safe_get(w, "locations") end
        end

        local first = nil
        if locs then
            local lt = array_to_table(locs)
            if #lt > 0 then first = lt[1] end
        end

        if first then
            local loc_props = {
                "display_name", "floor_num", "is_datacenter", "width", "height",
                "surge_immunity", "outage_immunity", "spawn_limit",
                "will_not_spawn_before_day", "builder_weight",
            }
            for _, prop in ipairs(loc_props) do
                run_test("Location", "location." .. prop, function()
                    local v = safe_get(first, prop)
                    return { passed = v ~= nil, details = tostring(v) }
                end)
            end
        else
            add_result("Location", "no locations", true, "skipped", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end

    -- == Network / Control Modules ============================================
    if config.test_network_api then
        print("[DIAG] Testing Network/Control Modules...")
        local devices = ModApiV1 and ModApiV1.get_devices()
        local net_dev = nil
        if devices then
            local dt = array_to_table(devices)
            for _, d in ipairs(dt) do
                local lc = safe_get(d, "logic_controller")
                if lc and safe_get(lc, "networkctl") then net_dev = d; break end
            end
        end

        if net_dev then
            local lc = safe_get(net_dev, "logic_controller")
            local netctl = safe_get(lc, "networkctl")

            local net_props = { "hardware_address", "network_address", "dhcp_enabled",
                                "is_dhcp_enabled", "stp_enabled", "designated_dns_servers" }
            for _, prop in ipairs(net_props) do
                run_test("NetworkCtl", "networkctl." .. prop, function()
                    local v = safe_get(netctl, prop)
                    return { passed = true, details = tostring(v) }
                end)
            end

            -- Other control modules
            local modules = { "routectl", "firewallctl", "vlanctl", "dhcpctl", "filesysctl", "packetctl" }
            for _, mod_name in ipairs(modules) do
                run_test("ControlModules", mod_name, function()
                    local m = safe_get(lc, mod_name)
                    return { passed = true, details = m ~= nil and "present" or "nil (normal for device type)" }
                end)
            end
        else
            add_result("NetworkCtl", "no network devices", true, "skipped", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end

    -- == Merchants API =========================================================
    if config.test_merchants_api then
        print("[DIAG] Testing Merchants API...")
        local ms = nil
        if ModApiV1 and ModApiV1.get_merchants then
            pcall(function() ms = ModApiV1.get_merchants() end)
        end
        if not ms then
            local w = ModApiV1 and ModApiV1.get_game_world()
            if w then ms = safe_get(w, "device_merchants") end
        end

        local first = nil
        if ms then
            local mt = array_to_table(ms)
            if #mt > 0 then first = mt[1] end
        end

        if first then
            local m_props = { "display_name", "price_multiplier", "warranty_multiplier",
                              "restock_period", "listings" }
            for _, prop in ipairs(m_props) do
                run_test("Merchant", "merchant." .. prop, function()
                    local v = safe_get(first, prop)
                    return { passed = v ~= nil, details = tostring(v) }
                end)
            end

            run_test("Merchant", "method: restock", function()
                local fn = safe_get(first, "restock")
                return { passed = fn ~= nil, details = fn ~= nil and "present" or "missing" }
            end)

            run_test("Merchant", "method: submit_order", function()
                local fn = safe_get(first, "submit_order")
                return { passed = fn ~= nil, details = fn ~= nil and "present" or "missing" }
            end)
        else
            add_result("Merchant", "no merchants", true, "skipped", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end

    -- == Programs API ==========================================================
    if config.test_programs_api then
        print("[DIAG] Testing Programs API...")
        local found_prog = nil
        local devices = ModApiV1 and ModApiV1.get_devices()
        if devices then
            local dt = array_to_table(devices)
            for _, d in ipairs(dt) do
                local lc = safe_get(d, "logic_controller")
                if lc then
                    local progs = safe_get(lc, "installed_programs")
                    if progs then
                        local pt = array_to_table(progs)
                        if #pt > 0 then found_prog = pt[1]; break end
                    end
                end
            end
        end

        if found_prog then
            local p_props = { "release_name", "is_running", "cpu_load", "install_size",
                              "code_size", "stack_size", "data_size", "description" }
            for _, prop in ipairs(p_props) do
                run_test("Program", "program." .. prop, function()
                    local v = safe_get(found_prog, prop)
                    return { passed = v ~= nil, details = tostring(v) }
                end)
            end
        else
            add_result("Program", "no programs", true, "skipped -- no installed programs found", nil)
            test_results.summary.skipped = test_results.summary.skipped + 1
        end
    end

    -- == FileSystem API ========================================================
    if config.test_filesystem_api then
        print("[DIAG] Testing FileSystem API...")

        run_test("FileSystem", "ModFileSystem global", function()
            return { passed = ModFileSystem ~= nil, details = ModFileSystem ~= nil and "available" or "nil" }
        end)

        run_test("FileSystem", "Mod.filesystem", function()
            local fs = Mod and safe_get(Mod, "filesystem")
            return { passed = fs ~= nil, details = fs ~= nil and "available" or "nil" }
        end)

        if Mod and Mod.filesystem then
            run_test("FileSystem", "get_files_at('/')", function()
                local fs = Mod.filesystem
                local ok, files = pcall(function() return fs:get_files_at("/") end)
                local n = 0
                if ok and files then n = #array_to_table(files) end
                return { passed = ok, details = n .. " files", error = not ok and tostring(files) or nil }
            end)

            run_test("FileSystem", "get_directories_at('/')", function()
                local fs = Mod.filesystem
                local ok, dirs = pcall(function() return fs:get_directories_at("/") end)
                local n = 0
                if ok and dirs then n = #array_to_table(dirs) end
                return { passed = ok, details = n .. " directories", error = not ok and tostring(dirs) or nil }
            end)

            run_test("FileSystem", "open + read (entry.lua)", function()
                local fs = Mod.filesystem
                local fh = fs:open("/entry.lua", 1)  -- READ mode
                if not fh then return { passed = false, details = "open failed" } end
                local len = fh:get_length()
                fh:close()
                return { passed = true, details = "entry.lua = " .. tostring(len) .. " bytes" }
            end)

            run_test("FileSystem", "mod_path_to_real('/')", function()
                local fs = Mod.filesystem
                local ok, real = pcall(function() return fs:mod_path_to_real("/") end)
                return { passed = ok, details = ok and tostring(real) or tostring(real) }
            end)
        end
    end

    -- == GameWorld methods (safe, read-only) ===================================
    if config.test_world_methods then
        print("[DIAG] Testing GameWorld methods...")
        local world = ModApiV1 and ModApiV1.get_game_world()
        if world then
            run_test("WorldMethods", "lookup_domain('test.local')", function()
                local ok, r = pcall(function() return world:lookup_domain("test.local") end)
                return { passed = ok, details = ok and ("result=" .. tostring(r)) or tostring(r) }
            end)

            run_test("WorldMethods", "get_loc_index(0)", function()
                local ok, r = pcall(function() return world:get_loc_index(0) end)
                return { passed = ok, details = ok and ("result=" .. tostring(r)) or tostring(r) }
            end)
        end
    end

    -- == Engine ================================================================
    run_test("Engine", "Engine global", function()
        return { passed = Engine ~= nil, details = Engine ~= nil and "available" or "nil" }
    end)

    -- == Print summary =========================================================
    local s = test_results.summary
    print(string.format("\n[DIAG] ===== Results: %d total | %d passed | %d failed | %d skipped =====",
        s.total, s.passed, s.failed, s.skipped))

    if s.failed > 0 then
        print("[DIAG] Failed:")
        for _, t in ipairs(test_results.tests) do
            if not t.passed then
                print(string.format("[DIAG]   X %s.%s: %s", t.category, t.name, t.error or t.details or "?"))
            end
        end
    end

    if config.verbose_mode then
        print("\n[DIAG] All results:")
        for _, t in ipairs(test_results.tests) do
            print(string.format("[DIAG]   %s [%s] %s: %s",
                t.passed and "+" or "X", t.category, t.name, t.details or t.error or ""))
        end
    end

    notify(string.format("API Tests: %d/%d passed", s.passed, s.total),
           s.failed > 0 and 2 or 0)

    return test_results
end

function export_test_results_json()
    local json = to_json(test_results, 2, 0)
    print("\n[DIAG] ===== Test Results JSON =====")
    print(json)
    print("[DIAG] " .. string.rep("=", 40))
    return json
end

-- ============================================================================
-- INSPECTION / DUMP COMMANDS
-- ============================================================================

local function dump_table(tbl, prefix, max_depth, depth)
    prefix    = prefix    or ""
    max_depth = max_depth or config.max_dump_depth or 2
    depth     = depth     or 0
    if depth >= max_depth then return end

    if type(tbl) == "userdata" then
        print(prefix .. "<userdata: " .. tostring(tbl) .. ">")
        local mt = getmetatable(tbl)
        if mt and type(mt) == "table" then
            local n = 0
            for k, v in pairs(mt) do
                if type(v) == "function" and not k:match("^__") then
                    print(prefix .. "  " .. tostring(k) .. "()")
                    n = n + 1
                    if n >= 20 then print(prefix .. "  ... (truncated)"); break end
                end
            end
        end
        return
    end

    if type(tbl) ~= "table" then
        print(prefix .. tostring(tbl) .. " (" .. type(tbl) .. ")")
        return
    end

    pcall(function()
        for k, v in pairs(tbl) do
            local vt = type(v)
            if vt == "function" then
                print(prefix .. tostring(k) .. " = <function>")
            elseif vt == "table" then
                print(prefix .. tostring(k) .. " = <table>")
                if depth < max_depth - 1 then dump_table(v, prefix .. "  ", max_depth, depth + 1) end
            elseif vt == "userdata" then
                print(prefix .. tostring(k) .. " = <userdata: " .. tostring(v) .. ">")
            else
                print(prefix .. tostring(k) .. " = " .. tostring(v) .. " (" .. vt .. ")")
            end
        end
    end)
end

function inspect_locations()
    print("\n[DIAG] ========== Locations ==========")
    local locs = nil
    if ModApiV1 and ModApiV1.get_locations then
        pcall(function() locs = ModApiV1.get_locations() end)
    end
    if not locs then
        local w = ModApiV1 and ModApiV1.get_game_world()
        if w then locs = safe_get(w, "locations") end
    end
    if locs then
        local lt = array_to_table(locs)
        for i, loc in ipairs(lt) do
            local is_dc = safe_get(loc, "is_datacenter")
            print(string.format("[DIAG]   Floor %s: %s%s (users: %d)",
                tostring(safe_get(loc, "floor_num")),
                tostring(safe_get(loc, "display_name")),
                is_dc and " [DC]" or "",
                count_table(safe_get(loc, "users"))))
        end
    else
        print("[DIAG] No locations available")
    end
    print("[DIAG] " .. string.rep("=", 40))
end

-- Backwards compat alias
inspect_scenes = inspect_locations

function dump_all_world_devices()
    print("\n[DIAG] ========== All World Devices ==========")
    if not ModApiV1 then print("[DIAG] ModApiV1 not available"); return end
    local devs = ModApiV1.get_devices()
    if not devs then print("[DIAG] No devices returned"); return end

    local dt = array_to_table(devs)
    print("[DIAG] Device count: " .. #dt)
    for i, d in ipairs(dt) do
        local name = safe_get(d, "product_name")
        local hw   = safe_get(d, "device_hardware_class")
        local cls  = DEVICE_HW_CLASS[hw] or "UNKNOWN"
        local cond = safe_get(d, "condition")
        print(string.format("[DIAG]   [%d] %s (%s) cond=%s floor=%s",
            i, tostring(name), cls, tostring(cond),
            tostring(safe_get(d, "current_floor_num"))))
    end
    print("[DIAG] " .. string.rep("=", 40))
    notify(string.format("Devices: %d -- see logs", #dt), 0)
end

function inspect_fixture_outlets()
    print("\n[DIAG] ========== Fixture Outlets & PHONE/CCTV Deep Scan ==========")
    if not ModApiV1 then print("[DIAG] ModApiV1 not available"); return end
    local world = ModApiV1.get_game_world()
    if not world then print("[DIAG] World is nil"); return end

    -- Safe node-info helper: extracts info without crashing if node methods
    -- are unavailable in the sandbox (API wrappers vs raw Godot Nodes differ).
    local function node_info(n)
        local info = {}
        pcall(function() info.class = n:get_class() end)
        pcall(function() info.name  = n:get_name() end)
        pcall(function() info.path  = tostring(n:get_path()) end)
        info.hw_class     = safe_get(n, "device_hardware_class")
        info.outlet_name  = safe_get(n, "outlet_name")
        info.floor_num    = safe_get(n, "floor_num")
        info.product_name = safe_get(n, "product_name")
        local lc = safe_get(n, "logic_controller")
        if lc then
            info.has_lc = true
            local netctl = safe_get(lc, "networkctl")
            if netctl then
                info.hw_addr = safe_get(netctl, "hardware_address")
                info.nw_addr = safe_get(netctl, "network_address")
            end
        end
        return info
    end

    -- Recursive scene tree walker on raw Node objects (not API wrappers).
    -- Must only be called on objects that support get_child_count / get_child.
    local function walk_node(node, depth, max_depth, results)
        if depth > max_depth then return end
        local ok_count, count = pcall(function() return node:get_child_count() end)
        if not ok_count or type(count) ~= "number" then return end
        for i = 0, count - 1 do
            local ok_c, child = pcall(function() return node:get_child(i) end)
            if ok_c and child ~= nil then
                local ok_info, info = pcall(node_info, child)
                if ok_info then
                    info.depth = depth
                    results[#results + 1] = info
                end
                -- Only recurse if child itself is a Node (has get_child_count)
                local ok_r = pcall(walk_node, child, depth + 1, max_depth, results)
                if not ok_r then end  -- swallow; recursion failed for this branch
            end
        end
    end

    -- 1) Location subtree scan via fixture_nodes / device_unit_nodes.
    --    Location API wrapper objects are NOT raw Godot Nodes in the sandbox,
    --    so we cannot call get_child_count on them directly.  Instead, find
    --    the actual scene node via get_node_or_null using the fixture name.
    print("[DIAG] --- World container scan (fixture_nodes, device_unit_nodes, component_nodes) ---")
    local containers = {"fixture_nodes", "device_unit_nodes", "component_nodes"}
    for _, cname in ipairs(containers) do
        local container = safe_get(world, cname)
        if container then
            local ok_count, count = pcall(function() return container:get_child_count() end)
            if ok_count and type(count) == "number" then
                print(string.format("[DIAG]   %s: %d direct children", cname, count))
                for ci = 0, count - 1 do
                    local ok_c, child = pcall(function() return container:get_child(ci) end)
                    if ok_c and child ~= nil then
                        local ok_i, info = pcall(node_info, child)
                        if ok_i then
                            local hw_name = info.hw_class and (DEVICE_HW_CLASS[info.hw_class] or tostring(info.hw_class)) or nil
                            -- Always print for fixture_nodes; only when hw_class present for others
                            if cname == "fixture_nodes" or hw_name then
                                print(string.format("[DIAG]     [%d] class=%s name=%s hw=%s outlet=%s",
                                    ci, tostring(info.class), tostring(info.name),
                                    tostring(hw_name), tostring(info.outlet_name)))
                            end
                            -- Recurse into this container child
                            local deep = {}
                            pcall(walk_node, child, 1, 4, deep)
                            for _, r in ipairs(deep) do
                                local rhw = r.hw_class and (DEVICE_HW_CLASS[r.hw_class] or tostring(r.hw_class)) or nil
                                if rhw or (r.class and (r.class:find("Phone") or r.class:find("CCTV")
                                           or r.class == "DeviceOutlet" or r.class == "PoweredDeviceOutlet")) then
                                    print(string.format("[DIAG]       +[d=%d] class=%s name=%s hw=%s outlet=%s nw=%s",
                                        r.depth, tostring(r.class), tostring(r.name),
                                        tostring(rhw), tostring(r.outlet_name), tostring(r.nw_addr)))
                                end
                            end
                        end
                    end
                end
            else
                print(string.format("[DIAG]   %s: exists but get_child_count failed", cname))
            end
        else
            print(string.format("[DIAG]   %s: nil", cname))
        end
    end

    -- 2) find_children scan from scene root — searches the full tree by name/class pattern.
    print("[DIAG] --- Root tree find_children scan ---")
    local root = nil
    pcall(function() root = world:get_tree():get_root() end)
    if not root then
        print("[DIAG]   Could not access scene root")
    else
        -- Helper: safely iterate a find_children result and log each node
        local function dump_found(label, arr)
            if not arr then
                print(string.format("[DIAG]   %s: find_children not available/failed", label))
                return
            end
            local ft = array_to_table(arr)
            print(string.format("[DIAG]   %s: %d results", label, #ft))
            for j = 1, #ft do
                local f = ft[j]
                if f ~= nil then
                    local ok_i, info = pcall(node_info, f)
                    if ok_i then
                        local hw_name = info.hw_class and (DEVICE_HW_CLASS[info.hw_class] or tostring(info.hw_class)) or nil
                        print(string.format("[DIAG]     [%d] class=%s name=%s hw=%s outlet=%s path=%s nw=%s",
                            j, tostring(info.class), tostring(info.name),
                            tostring(hw_name), tostring(info.outlet_name),
                            tostring(info.path), tostring(info.nw_addr)))
                    else
                        print(string.format("[DIAG]     [%d] (node_info failed)", j))
                    end
                end
            end
        end

        local r1 = nil; pcall(function() r1 = root:find_children("*Phone*",          "", true, false) end)
        dump_found("find_children('*Phone*')", r1)

        local r2 = nil; pcall(function() r2 = root:find_children("*CCTV*",           "", true, false) end)
        dump_found("find_children('*CCTV*')", r2)

        local r3 = nil; pcall(function() r3 = root:find_children("*", "DeviceOutlet",        true, false) end)
        dump_found("find_children(class='DeviceOutlet')", r3)

        local r4 = nil; pcall(function() r4 = root:find_children("*", "PoweredDeviceOutlet", true, false) end)
        dump_found("find_children(class='PoweredDeviceOutlet')", r4)

        -- Also try FixtureOutlet as base class
        local r5 = nil; pcall(function() r5 = root:find_children("*", "FixtureOutlet", true, false) end)
        dump_found("find_children(class='FixtureOutlet')", r5)
    end

    print("[DIAG] " .. string.rep("=", 40))
    notify("Fixture scan complete -- see logs", 0)
end

function reinspect_all_users()
    print("\n[DIAG] ========== Re-inspect Tracked Users ==========")
    print("[DIAG] Tracked: " .. #spawned_users)
    for _, entry in ipairs(spawned_users) do
        local u = entry.user
        inspection_counter = inspection_counter + 1
        print(string.format("[DIAG] --- User #%d: %s ---", inspection_counter, tostring(entry.username)))
        local lc = safe_get(u, "logic_controller")
        if lc then
            local netctl = safe_get(lc, "networkctl")
            if netctl then
                print("[DIAG]   hw_addr  = " .. tostring(safe_get(netctl, "hardware_address")))
                print("[DIAG]   nw_addr  = " .. tostring(safe_get(netctl, "network_address")))
                print("[DIAG]   dhcp     = " .. tostring(safe_get(netctl, "dhcp_enabled")))
                local dns = safe_get(netctl, "designated_dns_servers")
                if dns then
                    local dt = array_to_table(dns)
                    for i, v in ipairs(dt) do print("[DIAG]   dns[" .. i .. "] = " .. tostring(v)) end
                end
            else
                print("[DIAG]   (no networkctl)")
            end
        else
            print("[DIAG]   (no logic_controller)")
        end
    end
    notify(string.format("Re-inspected %d users", #spawned_users), 0)
end

function dump_world_overview()
    print("\n[DIAG] ========== World Overview ==========")
    local world = ModApiV1 and ModApiV1.get_game_world()
    if not world then print("[DIAG] World is nil"); return end

    print("[DIAG] Scenario:  " .. tostring(safe_get(world, "scenario_name")))
    print("[DIAG] Day:       " .. tostring(safe_get(world, "n_days")))
    print("[DIAG] Cash:      $" .. tostring(safe_get(world, "player_cash_balance")))
    print("[DIAG] Debt days: " .. tostring(safe_get(world, "days_in_debt")))
    print("[DIAG] Time mult: " .. tostring(safe_get(world, "time_mult")))
    print("[DIAG] Difficulty: " .. tostring(safe_get(world, "difficulty_level")))

    if ModApiV1.get_game_version then
        pcall(function()
            print("[DIAG] Game ver:  " .. tostring(ModApiV1.get_game_version()))
        end)
    end

    local devices = ModApiV1.get_devices()
    local users   = ModApiV1.get_users()
    print("[DIAG] Devices:   " .. (devices and #array_to_table(devices) or "?"))
    print("[DIAG] Users:     " .. (users and #array_to_table(users) or "?"))

    local locs = safe_get(world, "locations")
    print("[DIAG] Locations: " .. (locs and #array_to_table(locs) or "?"))

    local loans = safe_get(world, "player_loans")
    print("[DIAG] Loans:     " .. (loans and #array_to_table(loans) or "?"))

    local hostings = safe_get(world, "player_hostings")
    print("[DIAG] Hostings:  " .. (hostings and #array_to_table(hostings) or "?"))

    local techs = safe_get(world, "acquired_techs")
    print("[DIAG] Techs:     " .. (techs and #array_to_table(techs) or "?"))

    print("[DIAG] " .. string.rep("=", 40))
end

function show_lifecycle_log()
    print("\n[DIAG] ========== Lifecycle Event Log ==========")
    if #lifecycle_log == 0 then
        print("[DIAG] (empty)")
    else
        for i, entry in ipairs(lifecycle_log) do
            print(string.format("[DIAG]   %2d. [%.4fs] %s%s",
                i,
                entry.time or 0,
                entry.event,
                entry.detail and (" -- " .. entry.detail) or ""))
        end
    end
    print("[DIAG] " .. string.rep("=", 40))
end

-- ============================================================================
-- MOD LIFECYCLE CALLBACKS (complete set for 0.10.11)
-- ============================================================================

function on_mod_load()
    lifecycle("on_mod_load", "mod binary/script loaded")
end

function on_mods_loaded()
    lifecycle("on_mods_loaded", "all mods finished loading")
end

function on_engine_load()
    lifecycle("on_engine_load")

    if ModApiV1 then
        print("[DIAG] + ModApiV1 available")
        local world = ModApiV1.get_game_world()
        if world then
            print("[DIAG] + World exists (scenario=" ..
                tostring(safe_get(world, "scenario_name")) .. ")")
            local po = safe_get(world, "play_options")
            if po then
                print("[DIAG] + PlayOptions accessible (starting_cash=" ..
                    tostring(safe_get(po, "starting_cash")) .. ")")
            end
        else
            print("[DIAG] - World is nil at engine_load (normal -- use on_game_state_ready)")
        end
    else
        print("[DIAG] - ModApiV1 not available")
    end

    if Mod then
        print("[DIAG] + Mod global (dir=" .. tostring(safe_get(Mod, "mod_dir")) ..
              ", type=" .. tostring(safe_get(Mod, "mod_type")) .. ")")
    end

    if Engine then print("[DIAG] + Engine global available") end
end

-- Panel code removed (Callable bridge crash — see v4.0 notes)



function on_game_state_ready()
    lifecycle("on_game_state_ready", "game fully initialized -- world is guaranteed valid")

    local world = ModApiV1.get_game_world()
    if world then
        local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
        if ok and dbg then
            -- Enable the debug console (disabled by default in the game)
            pcall(function() dbg.enabled = true end)
            pcall(function() dbg.visible = true end)

            -- Register all console commands
            local cmds = {
                {"dump_world_overview",      dump_world_overview},
                {"inspect_locations",        inspect_locations},
                {"dump_all_world_devices",   dump_all_world_devices},
                {"inspect_fixture_outlets",  inspect_fixture_outlets},
                {"reinspect_all_users",      reinspect_all_users},
                {"export_to_json",           export_to_json},
                {"run_api_test_suite",       run_api_test_suite},
                {"export_test_results_json", export_test_results_json},
                {"show_lifecycle_log",       show_lifecycle_log},
            }
            for _, cmd in ipairs(cmds) do
                pcall(function() dbg.register_cmd(cmd[1], cmd[2]) end)
            end
            print("[DIAG] Debug console enabled. Registered " .. #cmds .. " commands. Press ~ to open.")
        else
            print("[DIAG] DebugLayer not found, commands available as globals only")
        end
    end

    -- This is the reliable point where world + all objects are available
    if config.auto_diag_on_ready then
        print("[DIAG] Running automatic diagnostics...")
        dump_world_overview()
        inspect_locations()

        -- Count device types
        if ModApiV1 then
            local devs = ModApiV1.get_devices()
            if devs then
                local dt = array_to_table(devs)
                local by_class = {}
                for _, d in ipairs(dt) do
                    local hw = safe_get(d, "device_hardware_class") or -1
                    local name = DEVICE_HW_CLASS[hw] or "UNKNOWN"
                    by_class[name] = (by_class[name] or 0) + 1
                end
                print("[DIAG] Device breakdown:")
                for cls, n in pairs(by_class) do
                    print("[DIAG]   " .. cls .. ": " .. n)
                end
            end
        end

        notify("Diagnostic Tool ready -- use console commands", 0)
    end
end

function on_game_host_eod()
    lifecycle("on_game_host_eod", "end-of-day host processing")
end

function on_mod_reload()
    lifecycle("on_mod_reload", "mods reloaded (F11)")
end

function on_world_ready(world)
    lifecycle("on_world_ready", "world=" .. tostring(world))
end

function on_world_created(world)
    lifecycle("on_world_created", "world=" .. tostring(world))
end

function on_game_start(world)
    lifecycle("on_game_start", "world=" .. tostring(world))
end

function on_scenario_start(world)
    lifecycle("on_scenario_start", "world=" .. tostring(world))
end

-- ============================================================================
-- SPAWN CALLBACKS
-- ============================================================================

function on_device_spawned(device)
    if not config.enable_device_logging then return end
    local name = safe_get(device, "product_name")
    local hw   = safe_get(device, "device_hardware_class")
    local cls  = DEVICE_HW_CLASS[hw] or "UNKNOWN"

    lifecycle("on_device_spawned", tostring(name) .. " (" .. cls .. ")")

    spawned_devices[#spawned_devices + 1] = { device = device, product_name = name }

    if config.enable_network_inspection then
        local lc = safe_get(device, "logic_controller")
        if lc then
            local netctl = safe_get(lc, "networkctl")
            if netctl then
                print("[DIAG]   hw_addr=" .. tostring(safe_get(netctl, "hardware_address")) ..
                      " nw_addr=" .. tostring(safe_get(netctl, "network_address")))
            end
        end
    end
end

function on_user_spawned(user)
    if not config.enable_user_logging then return end
    local username = safe_get(user, "username")
    local profile  = safe_get(user, "user_profile_name")
    local rate     = safe_get(user, "daily_rate")
    local loc      = safe_get(user, "location")

    lifecycle("on_user_spawned", tostring(username) .. " ($" .. tostring(rate) .. "/day)")
    print("[DIAG]   profile=" .. tostring(profile) ..
          " floor=" .. tostring(loc and safe_get(loc, "floor_num")))

    if config.track_users_for_reinspection then
        spawned_users[#spawned_users + 1] = { user = user, username = username }
    end

    if config.enable_network_inspection then
        local lc = safe_get(user, "logic_controller")
        if lc then
            local netctl = safe_get(lc, "networkctl")
            if netctl then
                print("[DIAG]   nw_addr=" .. tostring(safe_get(netctl, "network_address")) ..
                      " dhcp=" .. tostring(safe_get(netctl, "dhcp_enabled")))
            end
        end
    end
end

function on_location_spawned(location)
    if not config.enable_location_logging then return end
    local name  = safe_get(location, "display_name")
    local floor = safe_get(location, "floor_num")
    local is_dc = safe_get(location, "is_datacenter")

    lifecycle("on_location_spawned", "Floor " .. tostring(floor) .. ": " ..
              tostring(name) .. (is_dc and " [DC]" or ""))

    spawned_locations[#spawned_locations + 1] = { location = location, name = name }
end

-- ============================================================================
-- DAY CYCLE CALLBACKS
-- ============================================================================

function on_day_start()
    if not config.enable_day_events then return end
    local world = ModApiV1 and ModApiV1.get_game_world()
    local day  = world and safe_get(world, "n_days") or "?"
    local cash = world and safe_get(world, "player_cash_balance") or "?"
    lifecycle("on_day_start", "Day " .. tostring(day) .. " Cash=$" .. tostring(cash))
end

function on_day_end()
    if not config.enable_day_events then return end
    local world = ModApiV1 and ModApiV1.get_game_world()
    local day = world and safe_get(world, "n_days") or "?"
    lifecycle("on_day_end", "Day " .. tostring(day))

    if config.auto_export_on_day_end then
        print("[DIAG] Auto-exporting game state...")
        export_to_json()
    end
end

-- on_tick removed: panel polling no longer needed (Callable bridge crash)

-- ============================================================================
-- NOTE: on_player_input INTENTIONALLY REMOVED
--
-- The on_player_input callback fires on EVERY input event including mouse
-- movement, causing unavoidable per-frame overhead (pcall allocations, GC
-- pressure).  All functionality previously behind keyboard shortcuts is
-- available via console commands:
--
--   export_to_json()          -- was Shift+J
--   run_api_test_suite()      -- was Shift+Q
--   reinspect_all_users()     -- was Shift+R
--   dump_all_world_devices()  -- was Shift+D
--   dump_world_overview()     -- NEW
--   show_lifecycle_log()      -- NEW
--   inspect_locations()       -- was inspect_scenes()
--   inspect_fixture_outlets() -- NEW (PHONE/CCTV investigation)
--   export_test_results_json()
--
-- For automated exports, set config.auto_export_on_day_end = true.
-- ============================================================================

-- ============================================================================
-- STARTUP
-- ============================================================================

print("=== ModAPI Diagnostic Tool v4.6 Ready ===")
print("    Press ~ to open the debug console")
print("")
print("    Console commands:")
print("      dump_world_overview       -- quick world summary")
print("      inspect_locations         -- list all floors")
print("      dump_all_world_devices    -- list all devices")
print("      inspect_fixture_outlets   -- PHONE/CCTV fixture investigation")
print("      reinspect_all_users       -- re-inspect tracked users")
print("      export_to_json            -- export full game state")
print("      run_api_test_suite        -- test all API endpoints")
print("      export_test_results_json  -- export test results")
print("      show_lifecycle_log        -- show callback order")
print("")
print("    Lifecycle callbacks registered:")
print("      on_mod_load  on_mods_loaded  on_engine_load")
print("      on_game_state_ready  on_game_host_eod  on_mod_reload")
print("      on_device_spawned  on_user_spawned  on_location_spawned")
print("      on_day_start  on_day_end  on_tick")
print("      on_world_ready  on_world_created")
print("      on_game_start  on_scenario_start")
print("===")
