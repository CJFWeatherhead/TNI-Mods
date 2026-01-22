-- Inverse Prices Mod
-- Purpose: Inverts the game's economy by making purchases pay the player instead of costing money.
-- Author: Unknown
-- Version: 2.0
-- Description: This mod turns buying devices and creating links into profit-generating activities.
--              When devices spawn, players receive a refund. Expenses like tower links are also refunded,
--              effectively making all purchases free or profitable. Configurable via mod parameters.
-- Usage: The mod works automatically. Buy devices or create links to receive refunds.
--        Check console for refund confirmations. Configure settings in Mod Manager.
-- Notes: Uses on_device_spawned and on_user_spawned hooks. Monitors cash balance for undetected expenses.
--        Refund multiplier and what to affect (devices, sockets, proposals) are configurable.

-- Load mod configuration system
local mod_id = "inverse-prices"
local config = nil

-- Try to load modloader config if available
local function load_config()
    local success, ModConfig = pcall(require, "modloader.config")
    if success then
        config = ModConfig
        print("[inverse-prices] Using modloader configuration system")
    else
        print("[inverse-prices] Modloader not available, using defaults")
    end
end

-- Get parameter value with fallback to default
local function get_param(name, default)
    if config then
        return config.get_parameter(mod_id, name, default)
    end
    return default
end

-- Get refund multiplier based on settings
local function get_refund_multiplier()
    local refund_type = get_param("refund_type", "Double")

    if refund_type == "Free" then
        return 1.0
    elseif refund_type == "Double" then
        return 2.0
    elseif refund_type == "Custom" then
        return get_param("custom_refund_amount", 2)
    end

    return 2.0 -- Default fallback
end

function on_engine_load()
    print("Inverse Prices mod loaded!")
    if ModApiV1 and ModApiV1.sanity then
        ModApiV1.sanity()
    else
        print("ModApiV1 is not available!")
    end

    load_config()

    -- Log current configuration
    local refund_type = get_param("refund_type", "Double")
    local custom_amount = get_param("custom_refund_amount", 2)
    local effects_devices = get_param("effects_devices", true)
    local effects_sockets = get_param("effects_sockets", true)
    local effects_proposals = get_param("effects_proposals", true)

    print(string.format("[inverse-prices] Config: Refund=%s%s, Devices:%s, Sockets:%s, Proposals:%s",
        refund_type,
        refund_type == "Custom" and string.format("(%dx)", custom_amount) or "",
        tostring(effects_devices),
        tostring(effects_sockets),
        tostring(effects_proposals)))
end

function on_mod_reload()
    print("Pressed the reload action key (F11), reloading Inverse Prices mod...")
    load_config()
end

-- Track player cash to detect purchases and refund them
local last_known_balance = nil

---@param device DeviceUnit
function on_device_spawned(device)
    -- Check if devices are affected
    if not get_param("effects_devices", true) then
        return
    end

    -- Give the player a refund based on the device price
    -- This simulates getting paid for buying, without modifying prices

    local world = ModApiV1.get_game_world()
    if not world then
        return
    end

    if device.price and device.price > 0 then
        local refund_multiplier = get_refund_multiplier()
        local refund_amount = math.ceil(device.price * refund_multiplier)

        -- Use the proper transaction system to add money
        world.modify_player_cash(refund_amount, "Device Purchase Refund: " .. device.product_name, 1) -- Category 1 = INCOME
        print("[inverse-prices] " ..
            device.product_name .. " purchased! Refund: +" .. refund_amount .. " (price was " .. device.price .. ")")
    end
end

-- Track cash balance for detecting expenses
local previous_balance = nil
local last_proposal_check = 0


-- Track cash balance for detecting expenses
local previous_balance = nil
local last_proposal_check = 0

-- Track submitted proposals to detect their costs
local known_proposals = {}

-- Monitor for proposal submissions
function on_tick(delta)
    local world = ModApiV1.get_game_world()
    if not world or not world.player_cash_balance then
        return
    end

    -- Check for proposal-related expenses
    if get_param("effects_proposals", true) then
        -- Try to access the proposal controller
        local success, prop_controller = pcall(function()
            return world.proposal_controller
        end)

        if success and prop_controller then
            -- Check if any proposals have been submitted and refund their cost
            local mods = prop_controller.mods
            if mods then
                for i = 0, #mods - 1 do
                    local prop = mods[i]
                    if prop and prop.submitted then
                        local prop_name = tostring(prop)

                        -- Check if this is a newly submitted proposal
                        if not known_proposals[prop_name] then
                            known_proposals[prop_name] = true

                            -- Get the cost and refund it
                            local cost = 0
                            pcall(function()
                                cost = prop.cost or 0
                            end)

                            if cost > 0 then
                                local refund_multiplier = get_refund_multiplier()
                                local refund = math.ceil(cost * refund_multiplier)
                                world.modify_player_cash(refund, "Proposal Refund", 1) -- Category 1 = INCOME

                                local prop_display_name = "Proposal"
                                pcall(function()
                                    prop_display_name = prop:get_proposal_name() or "Proposal"
                                end)

                                print(string.format("[inverse-prices] %s submitted! Refund: +%d (cost was %d)",
                                    prop_display_name, refund, cost))
                            end
                        end
                    end
                end
            end
        end
    end

    -- Check for socket/link expenses
    if get_param("effects_sockets", true) then
        if previous_balance and world.player_cash_balance < previous_balance then
            local loss = previous_balance - world.player_cash_balance

            -- Heuristic: if loss is between 50-5000 and not a multiple of 5 (to avoid admin expenses),
            -- it's probably a tower link or socket cost
            if loss >= 50 and loss <= 5000 and loss % 5 ~= 0 then
                local refund_multiplier = get_refund_multiplier()
                local refund = math.ceil(loss * refund_multiplier)
                world.modify_player_cash(refund, "Socket/Link Refund", 1) -- Category 1 = INCOME
                print("[inverse-prices] Detected socket/link expense of " .. loss .. ", refunding " .. refund)
            end
        end
    end

    previous_balance = world.player_cash_balance
end

-- We'll keep the user_spawned hook for compatibility but it's less important now
---@param user User
function on_user_spawned(user)
    -- Initialize balance tracking
    local world = ModApiV1.get_game_world()
    if world and world.player_cash_balance then
        previous_balance = world.player_cash_balance
    end
end
