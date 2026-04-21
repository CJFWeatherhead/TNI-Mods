-- All Proposals Mod
-- Shows all available proposals by overriding the batch size.
--
-- Author: Chris
-- Version: 2.0.0
-- Description: Lean keyboard-only mod. SHIFT+O shows all eligible proposals,
--              SHIFT+U restores normal proposal display.
--              No panels, no register_cmd, no on_tick.
--
-- Keyboard shortcuts:
--   SHIFT + O   Show all available proposals
--   SHIFT + U   Restore normal proposal batch size

local mod_id = "all-proposals"

-- ===== MOD CONFIGURATION START =====
local config = {
    show_notification = true
}
-- ===== MOD CONFIGURATION END =====

local original_batch_size = nil
local all_proposals_active = false

-- =========================================================================
-- Proposal analysis helpers
-- =========================================================================

local function has_unmet_dependencies(proposal)
    if not proposal then return true end

    local depends_on = nil
    local success = pcall(function() depends_on = proposal.depends_on end)
    if not success or not depends_on then return false end

    local dep_submitted = false
    pcall(function() dep_submitted = depends_on.submitted end)

    if not dep_submitted then return true end

    local disallow_if_submitted = false
    pcall(function() disallow_if_submitted = proposal.disallow_proposal_if_depends_submitted end)

    if disallow_if_submitted and dep_submitted then return true end

    return false
end

local function check_adhoc_requirements(proposal)
    if not proposal or not proposal.test_adhoc_requirements then return true end

    local success, result = pcall(function() return proposal:test_adhoc_requirements() end)
    if not success then return true end
    if result == nil then return true end
    if type(result) == "string" and result ~= "" then return false end
    return true
end

local function get_dependency_name(proposal)
    local dep_name = nil
    pcall(function()
        if proposal.depends_on then
            dep_name = proposal.depends_on:get_proposal_name()
            if not dep_name or dep_name == "" then
                dep_name = proposal.depends_on.name
            end
        end
    end)
    return dep_name
end

-- =========================================================================
-- Core functions
-- =========================================================================

local function show_all_proposals()
    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if not world then print("[all-proposals] ERROR: no game world"); return end

        local propmod = world.propmod_controller
        if not propmod then print("[all-proposals] ERROR: no propmod_controller"); return end

        if not original_batch_size then
            original_batch_size = propmod.proposals_per_batch
        end

        local all_mods = propmod.mods
        if not all_mods then print("[all-proposals] ERROR: no mods array"); return end

        local available = 0
        local blocked = 0
        local submitted = 0

        local size = all_mods:size()
        for i = 0, size - 1 do
            local proposal = all_mods:get(i)
            if proposal then
                local is_submitted = false
                pcall(function() is_submitted = proposal.submitted end)

                if is_submitted then
                    submitted = submitted + 1
                elseif has_unmet_dependencies(proposal) then
                    blocked = blocked + 1
                elseif not check_adhoc_requirements(proposal) then
                    blocked = blocked + 1
                else
                    available = available + 1
                end
            end
        end

        local new_batch = math.max(available, 50)
        propmod.proposals_per_batch = new_batch
        propmod:reroll_proposals()

        all_proposals_active = true
        print(string.format("[all-proposals] Showing all: %d available, %d blocked, %d submitted (batch=%d)",
            available, blocked, submitted, new_batch))
    end)
    if not ok then print("[all-proposals] show ERROR: " .. tostring(err)) end
end

local function restore_normal_proposals()
    if not all_proposals_active or not original_batch_size then
        print("[all-proposals] Already in normal mode")
        return
    end

    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if not world then return end
        local propmod = world.propmod_controller
        if not propmod then return end

        propmod.proposals_per_batch = original_batch_size
        propmod:reroll_proposals()
    end)
    if not ok then print("[all-proposals] restore ERROR: " .. tostring(err)) end

    all_proposals_active = false
    print("[all-proposals] Restored normal proposals (batch=" .. tostring(original_batch_size) .. ")")
end

-- =========================================================================
-- Lean input handler — single pcall, early exits, zero allocs on non-match
-- =========================================================================

function on_player_input(event)
    if event:get_class() ~= "InputEventKey" then return end
    if not event:is_pressed() then return end
    if not event:get_shift_pressed() then return end

    local key = event:get_keycode()

    -- SHIFT+O (79) = show all proposals
    if key == 79 then
        show_all_proposals()
        return
    end

    -- SHIFT+U (85) = restore normal
    if key == 85 then
        restore_normal_proposals()
        return
    end
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    print("[all-proposals] v2.0.0 loaded | SHIFT+O show | SHIFT+U restore")
end

function on_game_state_ready()
    print("[all-proposals] Ready")
end

function on_mod_reload()
    print("[all-proposals] Reloaded")
end
