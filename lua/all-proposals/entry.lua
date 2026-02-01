-- All Proposals Mod
-- Purpose: This mod allows players to view all available proposals in the game by pressing Shift+P,
--          excluding only those with unmet dependencies. It temporarily increases the proposal batch size
--          to display all eligible proposals and provides a way to restore normal proposal display with Shift+O.
-- Author: CJFWeatherhead
-- Version: 0.1.6
-- Description: The mod hooks into the game's proposal system to override the default batch size,
--              making all available proposals visible at once. It safely checks for dependencies and
--              adhoc requirements before including proposals in the display.
-- Usage: Press Shift+P to activate and show all available proposals.
--        Press Shift+O to restore the normal proposal batch size and reroll proposals.
-- Notes: This mod uses the ModApiV1 to access game world and proposal controller.
--        It stores the original batch size on first use and restores it when deactivating.
--        Proposals with unmet dependencies or failed adhoc requirements are excluded from display.

print("=== All Proposals Mod v0.1.6 Loaded ===")

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Display options
    show_notification = true
}

-- ===== MOD CONFIGURATION END =====

local shift_p_pressed = false
local original_batch_size = nil
local all_proposals_active = false

-- Helper function to safely check if a proposal has unmet dependencies
local function has_unmet_dependencies(proposal)
    if not proposal then
        return true
    end

    -- Check if proposal has a dependency
    local depends_on = nil
    local success = pcall(function()
        depends_on = proposal.depends_on
    end)

    if not success or not depends_on then
        -- No dependency means this proposal is available
        return false
    end

    -- Check if the dependency is met (submitted)
    local dep_submitted = false
    pcall(function()
        dep_submitted = depends_on.submitted
    end)

    if not dep_submitted then
        -- Dependency exists but is not submitted, so unmet
        return true
    end

    -- Check the disallow_proposal_if_depends_submitted flag
    local disallow_if_submitted = false
    pcall(function()
        disallow_if_submitted = proposal.disallow_proposal_if_depends_submitted
    end)

    if disallow_if_submitted and dep_submitted then
        -- If this flag is set and dependency is submitted, this proposal cannot be shown
        return true
    end

    -- Dependency is met
    return false
end

-- Helper function to safely check adhoc requirements
local function check_adhoc_requirements(proposal)
    if not proposal or not proposal.test_adhoc_requirements then
        return true -- If we can't test, assume it's ok
    end

    local success, result = pcall(function()
        return proposal:test_adhoc_requirements()
    end)

    if not success then
        return true -- If test fails, assume it's ok
    end

    -- If result is nil or a truthy value, requirements are met
    -- If result is a string or error object, requirements are not met
    if result == nil then
        return true
    end

    if type(result) == "string" and result ~= "" then
        return false -- Error message means requirements not met
    end

    return true
end

-- Helper function to get dependency name safely
local function get_dependency_name(proposal)
    local dep_name = nil
    pcall(function()
        if proposal.depends_on then
            -- Try get_proposal_name() first
            dep_name = proposal.depends_on:get_proposal_name()
            -- If that fails or is empty, try name property
            if not dep_name or dep_name == "" then
                dep_name = proposal.depends_on.name
            end
        end
    end)
    return dep_name
end

-- Function to show all available proposals
local function show_all_proposals()
    print("")
    print("[All Proposals] ========================================")
    print("[All Proposals] Activating all available proposals...")
    print("[All Proposals] ========================================")

    local world = ModApiV1.get_game_world()
    if not world then
        print("[All Proposals] ERROR - Could not get game world!")
        return
    end

    local propmod_controller = world.propmod_controller
    if not propmod_controller then
        print("[All Proposals] ERROR - Could not get proposal controller!")
        return
    end

    -- Store original batch size if not already stored
    if not original_batch_size then
        pcall(function()
            original_batch_size = propmod_controller.proposals_per_batch
            print("[All Proposals] Stored original batch size: " .. original_batch_size)
        end)
    end

    local all_mods = propmod_controller.mods
    if not all_mods then
        print("[All Proposals] ERROR - Could not get mods array!")
        return
    end

    local total_proposals = 0
    local available_proposals = 0
    local blocked_proposals = 0
    local submitted_proposals = 0

    -- Lists for organized output
    local available_list = {}
    local blocked_list = {}
    local submitted_list = {}

    -- Count available proposals (not submitted, no unmet dependencies)
    pcall(function()
        local size = all_mods:size()
        total_proposals = size

        for i = 0, size - 1 do
            local proposal = all_mods:get(i)
            if proposal then
                local proposal_name = "Unknown"
                pcall(function()
                    -- Try get_proposal_name() first
                    local name = proposal:get_proposal_name()
                    if name and name ~= "" then
                        proposal_name = name
                    else
                        -- Fall back to name property
                        name = proposal.name
                        if name and name ~= "" then
                            proposal_name = name
                        end
                    end
                end)

                -- Check if already submitted
                local is_submitted = false
                pcall(function()
                    is_submitted = proposal.submitted
                end)

                if is_submitted then
                    submitted_proposals = submitted_proposals + 1
                    table.insert(submitted_list, proposal_name)
                    goto continue
                end

                -- Check for unmet dependencies
                if has_unmet_dependencies(proposal) then
                    local dep_name = get_dependency_name(proposal)
                    local block_reason = "unmet dependency"
                    if dep_name then
                        block_reason = "requires: " .. dep_name
                    end
                    blocked_proposals = blocked_proposals + 1
                    table.insert(blocked_list, {name = proposal_name, reason = block_reason})
                    goto continue
                end

                -- Check adhoc requirements
                if not check_adhoc_requirements(proposal) then
                    blocked_proposals = blocked_proposals + 1
                    table.insert(blocked_list, {name = proposal_name, reason = "adhoc requirement not met"})
                    goto continue
                end

                -- This proposal is available
                available_proposals = available_proposals + 1
                table.insert(available_list, proposal_name)
            end

            ::continue::
        end
    end)

    -- Print organized output
    print("")
    print("[All Proposals] --- AVAILABLE PROPOSALS (" .. #available_list .. ") ---")
    for _, name in ipairs(available_list) do
        print("[All Proposals]   [OK] " .. name)
    end

    print("")
    print("[All Proposals] --- BLOCKED PROPOSALS (" .. #blocked_list .. ") ---")
    for _, item in ipairs(blocked_list) do
        print("[All Proposals]   [X] " .. item.name .. " (" .. item.reason .. ")")
    end

    print("")
    print("[All Proposals] --- SUBMITTED PROPOSALS (" .. #submitted_list .. ") ---")
    for _, name in ipairs(submitted_list) do
        print("[All Proposals]   [DONE] " .. name)
    end

    -- Set the batch size to show all available proposals
    local new_batch_size = math.max(available_proposals, 50) -- At least 50 to be safe
    print("")
    print("[All Proposals] Setting batch size from " ..
        tostring(original_batch_size or "?") .. " to " .. new_batch_size)

    pcall(function()
        propmod_controller.proposals_per_batch = new_batch_size
    end)

    -- Trigger a reroll to regenerate the proposal list
    print("[All Proposals] Triggering proposal reroll...")
    pcall(function()
        propmod_controller:reroll_proposals()
    end)

    -- Emit signals to refresh the Secretariat UI
    -- Try both direct call and emit_signal approaches
    pcall(function()
        if propmod_controller.emit_signal then
            propmod_controller:emit_signal("new_proposals_updated")
            print("[All Proposals] Emitted new_proposals_updated signal via emit_signal")
        else
            propmod_controller:new_proposals_updated()
            print("[All Proposals] Called new_proposals_updated directly")
        end
    end)

    pcall(function()
        if propmod_controller.emit_signal then
            propmod_controller:emit_signal("ex_proposals_updated")
            print("[All Proposals] Emitted ex_proposals_updated signal via emit_signal")
        else
            propmod_controller:ex_proposals_updated()
            print("[All Proposals] Called ex_proposals_updated directly")
        end
    end)

    -- Try to find and refresh the Secretariat app if it's open
    pcall(function()
        local base_ui = ModApiV1.get_base_ui()
        if base_ui and base_ui.get_node then
            -- Try to find the Secretariat node in the scene tree
            local secretariat = base_ui:get_node_or_null("/root/BaseUI/TheSecretariat")
            if not secretariat then
                secretariat = base_ui:get_node_or_null("TheSecretariat")
            end
            
            if secretariat then
                print("[All Proposals] Found Secretariat, attempting refresh...")
                -- Try various refresh methods
                if secretariat.clear_dynamic then
                    secretariat:clear_dynamic()
                    print("[All Proposals] Called clear_dynamic()")
                end
                if secretariat.launch then
                    secretariat:launch()
                    print("[All Proposals] Called launch() to refresh")
                end
            else
                print("[All Proposals] Secretariat not found in scene tree (may not be open)")
            end
        end
    end)

    all_proposals_active = true

    print("")
    print("[All Proposals] ========================================")
    print("[All Proposals] SUMMARY")
    print("[All Proposals]   Total proposals: " .. total_proposals)
    print("[All Proposals]   Available: " .. available_proposals)
    print("[All Proposals]   Blocked: " .. blocked_proposals)
    print("[All Proposals]   Submitted: " .. submitted_proposals)
    print("[All Proposals] ========================================")
    print("")

    -- Show in-game notification if enabled
    if config.show_notification then
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui and base_ui.display_notification then
                -- tone_enum: 0 = neutral, 1 = positive, 2 = negative
                base_ui.display_notification(
                    string.format("Showing all %d proposals (Blocked: %d, Submitted: %d)", 
                        available_proposals, blocked_proposals, submitted_proposals), 
                    1
                )
            end
        end)
    end
end

-- Function to restore normal proposal display
local function restore_normal_proposals()
    if not all_proposals_active or not original_batch_size then
        print("[All Proposals] Already in normal mode or no original batch size stored")
        return
    end

    print("")
    print("[All Proposals] ========================================")
    print("[All Proposals] Restoring normal proposal batch size...")
    print("[All Proposals] ========================================")

    local world = ModApiV1.get_game_world()
    if not world then
        print("[All Proposals] ERROR - Could not get game world!")
        return
    end

    local propmod_controller = world.propmod_controller
    if not propmod_controller then
        print("[All Proposals] ERROR - Could not get proposal controller!")
        return
    end

    pcall(function()
        propmod_controller.proposals_per_batch = original_batch_size
        print("[All Proposals] Restored batch size to: " .. original_batch_size)
    end)

    pcall(function()
        propmod_controller:reroll_proposals()
        print("[All Proposals] Rerolled proposals")
    end)

    -- Emit signals to refresh the Secretariat UI
    pcall(function()
        if propmod_controller.emit_signal then
            propmod_controller:emit_signal("new_proposals_updated")
            print("[All Proposals] Emitted new_proposals_updated signal via emit_signal")
        else
            propmod_controller:new_proposals_updated()
            print("[All Proposals] Called new_proposals_updated directly")
        end
    end)

    pcall(function()
        if propmod_controller.emit_signal then
            propmod_controller:emit_signal("ex_proposals_updated")
            print("[All Proposals] Emitted ex_proposals_updated signal via emit_signal")
        else
            propmod_controller:ex_proposals_updated()
            print("[All Proposals] Called ex_proposals_updated directly")
        end
    end)

    -- Try to refresh Secretariat if open
    pcall(function()
        local base_ui = ModApiV1.get_base_ui()
        if base_ui and base_ui.get_node then
            local secretariat = base_ui:get_node_or_null("/root/BaseUI/TheSecretariat")
            if not secretariat then
                secretariat = base_ui:get_node_or_null("TheSecretariat")
            end
            if secretariat and secretariat.clear_dynamic then
                secretariat:clear_dynamic()
                if secretariat.launch then
                    secretariat:launch()
                end
                print("[All Proposals] Refreshed Secretariat UI")
            end
        end
    end)

    all_proposals_active = false
    print("[All Proposals] Normal mode restored")
    print("[All Proposals] ========================================")
    print("")

    -- Show in-game notification if enabled
    if config.show_notification then
        pcall(function()
            local base_ui = ModApiV1.get_base_ui()
            if base_ui and base_ui.display_notification then
                -- tone_enum: 0 = neutral, 1 = positive, 2 = negative
                base_ui.display_notification("Normal proposal mode restored", 0)
            end
        end)
    end
end

-- Keyboard input handler for Shift+P shortcut
function on_player_input(event)
    -- Check if this is a keyboard event
    local event_class = nil
    pcall(function() event_class = event:get_class() end)

    if event_class == "InputEventKey" then
        -- Get keycode and check if it's the P key (ASCII 80)
        local keycode = nil
        local is_pressed = false
        local is_shift = false

        pcall(function() keycode = event:get_keycode() end)
        pcall(function() is_pressed = event:is_pressed() end)
        pcall(function() is_shift = event:is_shift_pressed() end)

        -- Shift+P combination (80 is the keycode for 'P')
        if keycode == 80 and is_shift then
            if is_pressed and not shift_p_pressed then
                -- Key was just pressed down
                shift_p_pressed = true
                print("[All Proposals] Shift+P detected - Showing all proposals...")
                show_all_proposals()
            elseif not is_pressed and shift_p_pressed then
                -- Key was released
                shift_p_pressed = false
            end
        end

        -- Shift+O combination (79 is the keycode for 'O') - restore normal mode
        if keycode == 79 and is_shift then
            if is_pressed then
                print("[All Proposals] Shift+O detected - Restoring normal mode...")
                restore_normal_proposals()
            end
        end
    end
end

function on_engine_load()
    print("[All Proposals] Mod initialized")
end

function on_mod_reload()
    print("[All Proposals] Mod reloaded (F11)")
end

print("=== All Proposals Mod Setup Complete ===")
print("    Press Shift+P to show all available proposals")
print("    Press Shift+O to restore normal proposal count")
print("    (excludes proposals with unmet dependencies)")
print("===")
