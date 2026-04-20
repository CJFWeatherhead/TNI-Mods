-- Supa Mod Loader v4.0.0
-- Marker mod for ModManagerGUI + shared ModPanels UI framework.
--
-- ModPanels provides a shared, scrollable side-panel overlay at:
--     /root/ModPanels/Panel/Layout/Scroll/Content
--
-- Other mods add their own VBoxContainer sections as children of
-- that Content node.  Button signal callbacks dispatch within the
-- originating mod's sandbox so there are no cross-sandbox issues.
--
-- Toggle the panel with the  m_panels  console command (press ~).
--
-- IMPORTANT FOR MOD AUTHORS:
--   Every function passed to a Godot API (register_cmd, connect, etc.)
--   MUST be global (file-scope `function name()`, NOT `local function`).
--   The sandbox callable bridge holds references that Lua's GC cannot
--   trace; globals survive because _G pins them.
--
--   NEVER call display_notification() synchronously inside a command
--   handler.  It triggers re-entrant sandbox callbacks that cause
--   timeout cascades.  Use print() for feedback instead.
--
--   When connecting Lua functions to Godot signals (e.g. button.connect),
--   wrap them with Mod.callable_args_to_array(fn).  Raw Lua functions
--   crash the sandbox's callable bridge on signal dispatch.

local MOD_ID      = "supa-mod-loader"
local MOD_VERSION = "4.0.0"

print(string.format("[%s] v%s loaded — ModPanels framework", MOD_ID, MOD_VERSION))

if Mod then
    Mod.loader_version = MOD_VERSION
    Mod.installed_by   = "ModManagerGUI"
end

-- Panel state
local overlay_ref   = nil
local panel_showing = false

-- =========================================================================
-- Build the shared panel overlay
-- =========================================================================

local function build_overlay(world)
    -- Clean up previous overlay (F11 reload)
    pcall(function()
        local old = world.get_node("/root/ModPanels")
        if old then old.queue_free() end
    end)

    local root = world.get_node("/root")
    if not root then
        print("[" .. MOD_ID .. "] ERROR: /root not found")
        return false
    end

    -- CanvasLayer (renders on top of everything)
    overlay_ref = create_node("CanvasLayer", "")
    overlay_ref.name    = "ModPanels"
    overlay_ref.layer   = 100
    overlay_ref.visible = false

    -- PanelContainer (right-side strip)
    local panel = create_node("PanelContainer", "")
    panel.name = "Panel"
    overlay_ref.add_child(panel)
    pcall(function()
        panel.anchor_left = 1.0; panel.anchor_top    = 0.0
        panel.anchor_right = 1.0; panel.anchor_bottom = 1.0
    end)
    pcall(function()
        panel.offset_left = -280; panel.offset_top    = 10
        panel.offset_right = -10; panel.offset_bottom = -10
    end)
    pcall(function() panel.self_modulate = Color(1, 1, 1, 0.95) end)

    -- Main VBox
    local layout = create_node("VBoxContainer", "")
    layout.name = "Layout"
    panel.add_child(layout)

    -- Header row
    local header = create_node("HBoxContainer", "")
    header.name = "Header"
    layout.add_child(header)

    local title = create_node("Label", "")
    title.text = "Mod Panels"
    pcall(function() title.add_theme_font_size_override("font_size", 15) end)
    pcall(function() title.size_flags_horizontal = 3 end)
    header.add_child(title)

    local close_btn = create_node("Button", "")
    close_btn.text = "X"
    close_btn.flat = true
    pcall(function() close_btn.custom_minimum_size = Vector2(28, 28) end)
    header.add_child(close_btn)
    close_btn.connect("pressed", Mod.callable_args_to_array(_mp_close))

    -- Separator
    local sep = create_node("HSeparator", "")
    layout.add_child(sep)

    -- Scroll area
    local scroll = create_node("ScrollContainer", "")
    scroll.name = "Scroll"
    pcall(function() scroll.size_flags_vertical = 3 end)
    layout.add_child(scroll)

    -- Content VBox (other mods add children here)
    local content = create_node("VBoxContainer", "")
    content.name = "Content"
    pcall(function() content.size_flags_horizontal = 3 end)
    scroll.add_child(content)

    root.add_child(overlay_ref)
    print(string.format("[%s] Panel overlay created at /root/ModPanels", MOD_ID))
    return true
end

-- =========================================================================
-- Global command functions (MUST be global for GC safety)
-- =========================================================================

function _mp_close()
    if overlay_ref then
        overlay_ref.visible = false
        panel_showing = false
    end
end

function m_panels()
    if not overlay_ref then
        print("[" .. MOD_ID .. "] Panel overlay not available")
        return
    end
    panel_showing = not panel_showing
    overlay_ref.visible = panel_showing
    print("[" .. MOD_ID .. "] Panels " .. (panel_showing and "shown" or "hidden"))
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

function on_engine_load()
    print(string.format("[%s] v%s — ModPanels framework ready", MOD_ID, MOD_VERSION))
    if ModApiV1 and ModApiV1.sanity then ModApiV1.sanity() end
end

function on_game_state_ready()
    local world = ModApiV1.get_game_world()
    if not world then return end

    build_overlay(world)

    local ok, dbg = pcall(function() return world.get_node("/root/DebugLayer") end)
    if ok and dbg then
        pcall(function() dbg.enabled = true end)
        pcall(function() dbg.register_cmd("m_panels", m_panels) end)
        print(string.format("[%s] Registered: m_panels", MOD_ID))
    end
end

function on_mod_reload()
    print(string.format("[%s] Reloaded (F11)", MOD_ID))
    local world = ModApiV1 and ModApiV1.get_game_world()
    if world then build_overlay(world) end
end

function on_tick(delta) end
