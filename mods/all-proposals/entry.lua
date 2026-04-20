-- All Proposals Mod
-- Purpose: This mod allows players to view all available proposals in the game,
--          excluding only those with unmet dependencies. It temporarily increases the proposal batch size
--          to display all eligible proposals and provides a way to restore normal proposal display.
-- Author: CJFWeatherhead
-- Version: 1.3.0
-- Description: The mod hooks into the game's proposal system to override the default batch size,
--              making all available proposals visible at once. Own floating panel with
--              toggle-mode buttons polled via on_tick.
-- Usage: Open the debug console (~) and type a command name.
--
-- Console commands:
--   m_show_proposals   Show all available proposals
--   m_hide_proposals   Restore normal proposal batch size
--   m_ap_panel         Toggle the All Proposals panel

print("=== All Proposals Mod v1.3.0 Loading ===")

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Display options
    show_notification = true
}

-- ===== MOD CONFIGURATION END =====

local original_batch_size = nil
local all_proposals_active = false

-- Panel state
local _ap_panel       = nil
local _ap_panel_visible = false
local _ap_panel_close = nil
local _ap_status      = nil
local _ap_btn_show    = nil
local _ap_btn_hide    = nil

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
    print("[All Proposals] show_all_proposals: begin")

    local ok_outer, err_outer = pcall(function()
        print("[All Proposals] getting game world...")
        local world = ModApiV1.get_game_world()
        if not world then
            print("[All Proposals] ERROR: no game world"); return
        end

        print("[All Proposals] getting propmod_controller...")
        local propmod_controller = world.propmod_controller
        if not propmod_controller then
            print("[All Proposals] ERROR: no propmod_controller"); return
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
    print("[All Proposals] show_all_proposals: setting batch_size " ..
        tostring(original_batch_size or "?") .. " -> " .. new_batch_size)

    pcall(function()
        propmod_controller.proposals_per_batch = new_batch_size
        print("[All Proposals] show_all_proposals: batch_size set OK")
    end)

    -- Trigger a reroll to regenerate the proposal list
    print("[All Proposals] show_all_proposals: triggering reroll...")
    pcall(function()
        propmod_controller:reroll_proposals()
        print("[All Proposals] show_all_proposals: reroll done")
    end)

    print("[All Proposals] Note: close/reopen Secretariat if proposals don't refresh")

    all_proposals_active = true

    print(string.format("[All Proposals] SUMMARY: total=%d available=%d blocked=%d submitted=%d",
        total_proposals, available_proposals, blocked_proposals, submitted_proposals))

    end) -- end pcall wrapper
    if not ok_outer then print("[All Proposals] show_all_proposals ERROR: " .. tostring(err_outer)) end
    print("[All Proposals] show_all_proposals: end")
end

-- Function to restore normal proposal display
local function restore_normal_proposals()
    print("[All Proposals] restore_normal_proposals: begin")
    if not all_proposals_active or not original_batch_size then
        print("[All Proposals] restore_normal_proposals: already in normal mode")
        return
    end

    local ok, err = pcall(function()
        local world = ModApiV1.get_game_world()
        if not world then print("[All Proposals] ERROR: no game world"); return end
        local propmod_controller = world.propmod_controller
        if not propmod_controller then print("[All Proposals] ERROR: no propmod_controller"); return end

        print("[All Proposals] restore_normal_proposals: setting batch_size -> " .. tostring(original_batch_size))
        propmod_controller.proposals_per_batch = original_batch_size
        print("[All Proposals] restore_normal_proposals: batch_size set OK")

        print("[All Proposals] restore_normal_proposals: triggering reroll...")
        propmod_controller:reroll_proposals()
        print("[All Proposals] restore_normal_proposals: reroll done")
    end)
    if not ok then print("[All Proposals] restore_normal_proposals ERROR: " .. tostring(err)) end

    all_proposals_active = false
    print("[All Proposals] restore_normal_proposals: end")
end

-- Console commands (exposed as globals for the game console)
function show_proposals()
    print("[All Proposals] show_proposals: begin")
    show_all_proposals()
    if _ap_status then
        pcall(function()
            _ap_status.text = all_proposals_active and "Showing all proposals" or "Normal mode"
        end)
    end
    print("[All Proposals] show_proposals: end")
end

function hide_proposals()
    print("[All Proposals] hide_proposals: begin")
    restore_normal_proposals()
    if _ap_status then
        pcall(function() _ap_status.text = "Normal mode" end)
    end
    print("[All Proposals] hide_proposals: end")
end

function m_ap_panel()
    if not _ap_panel then print("[All Proposals] m_ap_panel: panel not built yet"); return end
    _ap_panel_visible = not _ap_panel_visible
    pcall(function() _ap_panel.visible = _ap_panel_visible end)
    print("[All Proposals] m_ap_panel: " .. (_ap_panel_visible and "shown" or "hidden"))
end

-- =========================================================================
-- Panel (standalone CanvasLayer at /root)
-- =========================================================================

local function destroy_ap_panel()
    if _ap_panel then pcall(function() _ap_panel.queue_free() end) end
    _ap_panel = nil; _ap_panel_visible = false; _ap_panel_close = nil
    _ap_status = nil; _ap_btn_show = nil; _ap_btn_hide = nil
end

local function build_ap_panel(world)
    destroy_ap_panel()
    local ok, err = pcall(function()
        local root = world.get_node("/root")
        if not root then print("[All Proposals] build_panel: /root not found"); return end

        _ap_panel = create_node("CanvasLayer", "")
        _ap_panel.layer = 100
        _ap_panel.visible = false

        local container = create_node("PanelContainer", "")
        _ap_panel.add_child(container)
        pcall(function()
            container.anchor_left = 1.0; container.anchor_top = 0.0
            container.anchor_right = 1.0; container.anchor_bottom = 0.0
        end)
        pcall(function()
            container.offset_left = -270; container.offset_top = 510
            container.offset_right = -10;  container.offset_bottom = 640
        end)
        pcall(function() container.self_modulate = Color(1, 1, 1, 0.92) end)

        local vbox = create_node("VBoxContainer", "")
        container.add_child(vbox)

        -- Header
        local header = create_node("HBoxContainer", "")
        vbox.add_child(header)
        local title = create_node("Label", "")
        title.text = "All Proposals"
        pcall(function() title.add_theme_font_size_override("font_size", 15) end)
        pcall(function() title.size_flags_horizontal = 3 end)
        header.add_child(title)

        _ap_panel_close = create_node("Button", "")
        _ap_panel_close.text = "X"
        _ap_panel_close.flat = true
        _ap_panel_close.toggle_mode = true
        pcall(function() _ap_panel_close.custom_minimum_size = Vector2(28, 28) end)
        header.add_child(_ap_panel_close)

        -- Status
        _ap_status = create_node("Label", "")
        _ap_status.text = all_proposals_active and "Showing all proposals" or "Normal mode"
        pcall(function() _ap_status.add_theme_font_size_override("font_size", 11) end)
        vbox.add_child(_ap_status)

        -- Buttons
        local row = create_node("HBoxContainer", "")
        vbox.add_child(row)

        local btn_show = create_node("Button", "")
        btn_show.text = "Show All"
        btn_show.toggle_mode = true
        pcall(function() btn_show.custom_minimum_size = Vector2(120, 28) end)
        row.add_child(btn_show)
        _ap_btn_show = btn_show

        local btn_hide = create_node("Button", "")
        btn_hide.text = "Restore"
        btn_hide.toggle_mode = true
        pcall(function() btn_hide.custom_minimum_size = Vector2(120, 28) end)
        row.add_child(btn_hide)
        _ap_btn_hide = btn_hide

        root.add_child(_ap_panel)
        print("[All Proposals] Panel built (standalone CanvasLayer at /root)")
    end)
    if not ok then print("[All Proposals] build_panel ERROR: " .. tostring(err)) end
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    print("[All Proposals] v1.3.0 loaded")
    print("[All Proposals] Console: m_show_proposals  m_hide_proposals  m_ap_panel")
end

function on_game_state_ready()
    print("[All Proposals] on_game_state_ready: begin")
    local world = ModApiV1.get_game_world()
    if not world then return end

    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if ok and dbg then
        pcall(function() dbg.enabled = true end)
        local cmds = {
            {"m_show_proposals", show_proposals},
            {"m_hide_proposals", hide_proposals},
            {"m_ap_panel",       m_ap_panel},
        }
        for _, cmd in ipairs(cmds) do
            pcall(function() dbg.register_cmd(cmd[1], cmd[2]) end)
        end
        print("[All Proposals] on_game_state_ready: registered " .. #cmds .. " console commands")
    else
        print("[All Proposals] on_game_state_ready: DebugLayer not found")
    end

    build_ap_panel(world)
end

function on_mod_reload()
    print("[All Proposals] Reloaded (F11)")
    destroy_ap_panel()
    local w = ModApiV1 and ModApiV1.get_game_world()
    if w then build_ap_panel(w) end
end

function on_tick(delta)
    -- Poll close button
    if _ap_panel_close then
        pcall(function()
            if _ap_panel_close.button_pressed then
                _ap_panel_close.button_pressed = false
                _ap_panel_visible = false
                _ap_panel.visible = false
            end
        end)
    end
    -- Poll action buttons
    pcall(function()
        if _ap_btn_show and _ap_btn_show.button_pressed then
            _ap_btn_show.button_pressed = false; show_proposals()
        end
        if _ap_btn_hide and _ap_btn_hide.button_pressed then
            _ap_btn_hide.button_pressed = false; hide_proposals()
        end
    end)
end

print("=== All Proposals Mod v1.3.0 Ready ===")
print("    Console: m_show_proposals / m_hide_proposals / m_ap_panel")
