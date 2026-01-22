-- All Proposals Mod
-- Purpose: This mod allows players to view all available proposals in the game by pressing Shift+P,
--          excluding only those with unmet dependencies. It temporarily increases the proposal batch size
--          to display all eligible proposals and provides a way to restore normal proposal display with Shift+O.
-- Author: Unknown
-- Version: 1.0
-- Description: The mod hooks into the game's proposal system to override the default batch size,
--              making all available proposals visible at once. It safely checks for dependencies and
--              adhoc requirements before including proposals in the display.
-- Usage: Press Shift+P to activate and show all available proposals.
--        Press Shift+O to restore the normal proposal batch size and reroll proposals.
-- Notes: This mod uses the ModApiV1 to access game world and proposal controller.
--        It stores the original batch size on first use and restores it when deactivating.
--        Proposals with unmet dependencies or failed adhoc requirements are excluded from display.

print("=== All Proposals Mod v1.0 Loaded ===")

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

-- Function to show all available proposals
local function show_all_proposals()
    print("\n[All Proposals] Activating all available proposals...")

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

    -- Count available proposals (not submitted, no unmet dependencies)
    pcall(function()
        local size = all_mods:size()
        total_proposals = size

        for i = 0, size - 1 do
            local proposal = all_mods:get(i)
            if proposal then
                local proposal_name = "Unknown"
                pcall(function()
                    proposal_name = proposal:get_proposal_name()
                end)

                -- Check if already submitted
                local is_submitted = false
                pcall(function()
                    is_submitted = proposal.submitted
                end)

                if is_submitted then
                    submitted_proposals = submitted_proposals + 1
                    print("[All Proposals]   - Already submitted: " .. proposal_name)
                    goto continue
                end

                -- Check for unmet dependencies
                if has_unmet_dependencies(proposal) then
                    print("[All Proposals]   ✗ Blocked (unmet dependency): " .. proposal_name)
                    blocked_proposals = blocked_proposals + 1
                    goto continue
                end

                -- Check adhoc requirements
                if not check_adhoc_requirements(proposal) then
                    print("[All Proposals]   ✗ Blocked (adhoc requirement): " .. proposal_name)
                    blocked_proposals = blocked_proposals + 1
                    goto continue
                end

                -- This proposal is available
                print("[All Proposals]   ✓ Available: " .. proposal_name)
                available_proposals = available_proposals + 1
            end

            ::continue::
        end
    end)

    -- Set the batch size to show all available proposals
    local new_batch_size = math.max(available_proposals, 50) -- At least 50 to be safe
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

    all_proposals_active = true

    print("[All Proposals] Complete!")
    print("[All Proposals]   Total proposals: " .. total_proposals)
    print("[All Proposals]   Available: " .. available_proposals)
    print("[All Proposals]   Blocked: " .. blocked_proposals)
    print("[All Proposals]   Submitted: " .. submitted_proposals)
    print("")
end

-- Function to restore normal proposal display
local function restore_normal_proposals()
    if not all_proposals_active or not original_batch_size then
        return
    end

    print("\n[All Proposals] Restoring normal proposal batch size...")

    local world = ModApiV1.get_game_world()
    if not world then
        return
    end

    local propmod_controller = world.propmod_controller
    if not propmod_controller then
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

    all_proposals_active = false
    print("[All Proposals] Normal mode restored\n")
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
