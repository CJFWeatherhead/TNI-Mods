-- Cart Saver Mod
-- Purpose: Build named shopping lists and order them from merchants in one click.
-- Author: CJFWeatherhead
-- Version: 3.5.0
--
-- ============================================================================
-- SANDBOX FACTS THIS MOD IS BUILT AROUND -- read before changing anything
-- ============================================================================
--
-- 1. WRITING FILES IS BLOCKED. ModFileSystem.open(..., WRITE) logs
--    "writing of files is not allowed!" and returns nothing. Lists are kept in the in-game
--    clipboard notepad between markers, and can be copied out as a code string. Note that
--    BaseUI.clipboard reports no notepad_text in this build, so the text widget inside the
--    clipboard subtree is located by class instead.
--
-- 2. get_script() IS BANNED ("Attempt to access restricted property setter get_script"), so
--    the DeviceCheckout class cannot be reached and create_node() only makes engine classes.
--    The only way to get an order line is to BORROW a live DeviceCheckout off a store listing
--    row and reuse it. This happens automatically the first time an order is placed.
--
-- 3. A Lua function given to Godot as a Callable FIRES ONCE. gd_callable_lua() leaves the
--    function on a coroutine stack at index 1, but lua_pcall() pops it and never pushes it
--    back. The second call hits nil, the error is rethrown as a C++ exception, and unwinding
--    it inside the VM exhausts the sandbox budget -- the game freezes with "Sandbox: Timeout".
--    => No signals anywhere. Buttons are toggle buttons polled from on_game_tick.
--    => Each Callable also costs a coroutine that is pinned in the registry forever, so
--       console commands re-register ONLY the command that was just used.
--
-- 4. THE LUA HEAP IS TINY (~1800 KB) and "Exception: Out of memory" is fatal and uncatchable.
--    Every pcall(function() ... end) allocates a closure, so the polling path uses shared
--    helper functions (_idx/_set/_call*) with pcall(fn, args...) and allocates nothing.
--
-- 5. TOUCHING A FREED OBJECT THROWS A C++ std::bad_cast THAT pcall CANNOT CATCH. Poll entries
--    are therefore removed BEFORE their nodes are freed, never probed afterwards.
--
-- 6. find_children's type argument matches the ENGINE class, so "V2CartItem" never matches.
--    Worse, the cart's rows are plain HBoxContainers built in code -- auto-named
--    "@HBoxContainer@6806", no script, and no listing or checkout references at all. Their only
--    content is five child labels: Name | Variant | QtyContainer | UnitPrice | Subtotal. Rows
--    are therefore found STRUCTURALLY inside the CartItems container and read by parsing text,
--    with the merchant recovered by matching the title against every merchant's listings.
--    CartItems' first child is named CartItemPreview but IS a real cart line -- it is the
--    scene's template row, reused for line 1 and duplicated for the rest. The only node holding
--    a DeviceCheckout is DeviceListingCartItem in the store area, used as the borrowed template.
--
-- 7. Dictionary and Vector2 do not cross the bridge, so current_local_cart is unreadable and
--    custom_minimum_size cannot be set (layout is anchors/offsets/size-flags only).
--
-- 8. The per-frame hook is on_game_tick(delta). on_engine_load / on_mod_reload / on_tick /
--    on_day_start are never called.

local MOD_VER  = "3.5.0"
local NOTE_BEG = "[cartsaver]"
local NOTE_END = "[/cartsaver]"

-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    -- Show the "Saved Carts" button in the bottom-left corner of the screen
    show_toggle_button = true,

    -- Keep lists in the in-game clipboard notepad so they survive restarts
    use_notepad_storage = true,

    -- Trim a line's quantity down to remaining stock instead of failing the line
    clamp_to_stock = true,

    -- Write our own subtotal (listing price x quantity) onto each order line
    set_subtotal = true,

    -- Colours offered for cable lines
    cable_colors = "Original,Yellow,Blue,Purple,Orange,Green,Red,Grey",

    -- Game ticks between UI polls. Higher is cheaper but less responsive.
    poll_every_n_ticks = 4,

    -- Distance in pixels from the left edge to the "Saved Carts" button.
    -- -1 means work it out automatically, sitting just right of the mobile-OS button.
    toggle_x = -1,

    -- Extra console output
    debug_logging = true
}

-- ===== MOD CONFIGURATION END =====

-- =========================================================================
-- Allocation-free access helpers (see sandbox fact 4)
-- =========================================================================

local function _idx(o, k) return o[k] end
local function _set(o, k, v) o[k] = v end
local function _len(a) return #a end
local function _c0(o, m) return o[m]() end
local function _c1(o, m, a) return o[m](a) end
local function _c2(o, m, a, b) return o[m](a, b) end
local function _c4(o, m, a, b, c, d) return o[m](a, b, c, d) end

local function get_prop(obj, prop)
    if obj == nil then return nil end
    local ok, v = pcall(_idx, obj, prop)
    if ok then return v end
    return nil
end

local function set_prop(obj, prop, value)
    if obj == nil then return false end
    return (pcall(_set, obj, prop, value))
end

local function call0(o, m) local ok, r = pcall(_c0, o, m) return ok and r or nil end
local function call1(o, m, a) local ok, r = pcall(_c1, o, m, a) return ok and r or nil end
local function call2(o, m, a, b) local ok, r = pcall(_c2, o, m, a, b) return ok and r or nil end

local dbg_layer = nil

local function log(msg)
    msg = tostring(msg)
    print("[cart-saver] " .. msg)
    if dbg_layer then pcall(_c1, dbg_layer, "print_console", "[carts] " .. msg) end
end

local function dlog(m) if config.debug_logging then log(m) end end

local function notify(msg)
    log(msg)
    local base = ModApiV1 and ModApiV1.get_base_ui()
    if base then pcall(_c2, base, "display_notification", tostring(msg), 0) end
end

local function arr_list(a, budget)
    local t = {}
    if a == nil then return t end
    local ok, n = pcall(_len, a)
    if not ok or type(n) ~= "number" then return t end
    if budget and n > budget then n = budget end
    for i = 0, n - 1 do
        local vok, v = pcall(_idx, a, i)
        if vok and v ~= nil then t[#t + 1] = v end
    end
    return t
end

local function trim(s)
    if type(s) ~= "string" then return "" end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local function split_commas(s)
    local out = {}
    for p in string.gmatch(tostring(s), "[^,]+") do
        p = trim(p)
        if p ~= "" then out[#out + 1] = p end
    end
    return out
end

-- =========================================================================
-- State
-- =========================================================================

local carts = {}
local spare_checkout = nil   -- borrowed DeviceCheckout, reused for every order line

-- =========================================================================
-- Encoding.  CS1~<count>|cart|cart...   cart = name~floor~(m~t~q~v~p~i)*
-- Anything that would break the format is percent-encoded, so a list can live
-- on one line of the in-game notepad.
-- =========================================================================

local function esc_char(c) return string.format("%%%02X", string.byte(c)) end
local function esc(s) return (string.gsub(tostring(s), "[%%~|%[%]\r\n\t]", esc_char)) end
local function unesc_hex(h) return string.char(tonumber(h, 16)) end
local function unesc(s) return (string.gsub(tostring(s), "%%(%x%x)", unesc_hex)) end

local function encode_carts()
    local parts = {}
    for _, cart in ipairs(carts) do
        local f = { esc(cart.name), tostring(cart.floor or 0) }
        for _, it in ipairs(cart.items) do
            f[#f + 1] = esc(it.merchant)
            f[#f + 1] = esc(it.title)
            f[#f + 1] = tostring(it.qty or 1)
            f[#f + 1] = esc(it.varsel or "")
            f[#f + 1] = tostring(it.price or 0)
            f[#f + 1] = tostring(it.idx or -1)
        end
        parts[#parts + 1] = table.concat(f, "~")
    end
    return "CS1~" .. #carts .. "|" .. table.concat(parts, "|")
end

-- Returns a list of carts, or nil plus a reason.
local function decode_carts(code)
    code = trim(code or "")
    if code == "" then return nil, "nothing to import" end
    local count = string.match(code, "^CS1~(%d+)|")
    if not count then return nil, "that does not look like a cart code (must start with CS1~)" end
    local body = string.sub(code, string.find(code, "|", 1, true) + 1)

    local out = {}
    for chunk in string.gmatch(body .. "|", "([^|]*)|") do
        if chunk ~= "" then
            local f = {}
            for piece in string.gmatch(chunk .. "~", "([^~]*)~") do f[#f + 1] = piece end
            if #f >= 2 then
                local cart = { name = unesc(f[1]), floor = tonumber(f[2]) or 0, items = {} }
                local i = 3
                while i + 5 <= #f do
                    cart.items[#cart.items + 1] = {
                        merchant = unesc(f[i]), title = unesc(f[i + 1]),
                        qty = tonumber(f[i + 2]) or 1, varsel = unesc(f[i + 3]),
                        price = tonumber(f[i + 4]) or 0, idx = tonumber(f[i + 5]) or -1,
                    }
                    i = i + 6
                end
                out[#out + 1] = cart
            end
        end
    end
    if #out ~= tonumber(count) then
        return out, string.format("warning: code says %s list(s) but %d decoded -- truncated paste?",
            count, #out)
    end
    return out, nil
end

-- =========================================================================
-- Persistence via the in-game clipboard notepad
-- =========================================================================

-- The notepad target is discovered once and cached as (node, property).
-- BaseUI.clipboard reports notepad_text as absent in this build, and clipboard_notes exposes
-- no readable text either, so the real text widget is hunted down inside the clipboard subtree.
local notepad_node, notepad_field = nil, nil
local notepad_searched = false

local function text_field_of(node)
    if node == nil then return nil end
    for _, f in ipairs({ "notepad_text", "text_content", "text" }) do
        if type(get_prop(node, f)) == "string" then return f end
    end
    return nil
end

local function search_text_widget(node, depth)
    if depth > 6 then return nil end
    local n = call0(node, "get_child_count")
    if type(n) ~= "number" then return nil end
    for i = 0, n - 1 do
        local c = call1(node, "get_child", i)
        if c then
            local cls = tostring(call0(c, "get_class") or "")
            if cls == "TextEdit" or cls == "LineEdit" then
                local f = text_field_of(c)
                if f then return c, f end
            end
            local r, rf = search_text_widget(c, depth + 1)
            if r then return r, rf end
        end
    end
    return nil
end

local function find_notepad()
    if notepad_searched then return notepad_node, notepad_field end
    notepad_searched = true

    local base = ModApiV1 and ModApiV1.get_base_ui()
    local clip = base and get_prop(base, "clipboard")

    for _, cand in ipairs({ clip, clip and get_prop(clip, "clipboard_notes") }) do
        local f = cand and text_field_of(cand)
        if f then notepad_node, notepad_field = cand, f return cand, f end
    end

    -- Fall back to the first editable text widget inside the clipboard UI.
    if clip then
        local n, f = search_text_widget(clip, 0)
        if n then notepad_node, notepad_field = n, f return n, f end
    end
    return nil
end

local function read_notepad_text()
    local node, field = find_notepad()
    if not node then return nil end
    local t = get_prop(node, field)
    if type(t) == "string" then return t, node, field end
    return nil
end

local function load_carts()
    if not config.use_notepad_storage then return end
    local text = read_notepad_text()
    if not text then dlog("notepad unavailable") return end
    local blob = string.match(text, "%[cartsaver%](.-)%[/cartsaver%]")
    if not blob then return end
    local decoded, err = decode_carts(blob)
    if err then log(err) end
    if decoded then
        carts = decoded
        log(string.format("loaded %d list(s) from the notepad", #carts))
    end
end

local function save_carts()
    if not config.use_notepad_storage then return false end
    local text, target, field = read_notepad_text()
    if not text then return false end
    local block = NOTE_BEG .. encode_carts() .. NOTE_END
    local updated
    if string.find(text, NOTE_BEG, 1, true) then
        updated = string.gsub(text, "%[cartsaver%].-%[/cartsaver%]", function() return block end, 1)
    else
        updated = (text ~= "" and (text .. "\n") or "") .. block
    end
    if set_prop(target, field, updated) then return true end
    log("could not write to the notepad")
    return false
end

-- =========================================================================
-- Game lookups
-- =========================================================================

local function get_world() return ModApiV1 and ModApiV1.get_game_world() end

local function get_scene_root()
    local world = get_world()
    if not world then return nil end
    local root = nil
    local tree = call0(world, "get_tree")
    if tree then root = call0(tree, "get_root") end
    if root then return root end
    return call1(world, "get_node", "/root")
end

local function get_merchants()
    local list = nil
    if ModApiV1 then list = call0(ModApiV1, "get_merchants") end
    if not list then
        local w = get_world()
        list = w and get_prop(w, "device_merchants")
    end
    return arr_list(list)
end

local function merchant_listings(m) return arr_list(get_prop(m, "listings")) end

local function find_merchant(name)
    for _, m in ipairs(get_merchants()) do
        if get_prop(m, "display_name") == name then return m end
    end
    return nil
end

local function find_listing(merchant, item)
    local listings = merchant_listings(merchant)
    local first, n = nil, 0
    for _, l in ipairs(listings) do
        if get_prop(l, "listing_title") == item.title then
            n = n + 1
            if not first then first = l end
            if get_prop(l, "price") == item.price then return l end
        end
    end
    if first then return first end
    if item.idx and item.idx >= 0 and listings[item.idx + 1] then
        return listings[item.idx + 1]
    end
    return nil
end

local function get_floors()
    local out = {}
    local world = get_world()
    if not world then return out end
    for _, loc in ipairs(arr_list(get_prop(world, "locations"))) do
        local idx = call1(world, "get_loc_index", loc)
        if type(idx) ~= "number" then idx = get_prop(loc, "slot_index") end
        if type(idx) == "number" then
            out[#out + 1] = {
                label = tostring(get_prop(loc, "display_name") or "Floor") ..
                        " (" .. tostring(get_prop(loc, "floor_num") or idx) .. ")",
                index = idx,
            }
        end
    end
    return out
end

-- =========================================================================
-- The open D-Market2 cart, and borrowing a checkout from it
-- =========================================================================

-- Cart rows are plain HBoxContainers built in code -- auto-named "@HBoxContainer@6806", no
-- script, no listing_ref, no checkout_item_ref. The only data they carry is the text of five
-- child labels:  Name | Variant | QtyContainer | UnitPrice | Subtotal.
-- So a row is identified STRUCTURALLY (does it have Name and Subtotal children?) and read by
-- parsing those labels. CartItems' first child is named CartItemPreview, but that is NOT a
-- preview to skip: it is the template row defined in the scene, reused as cart line 1, with
-- every further line a duplicate of it (hence the auto-names). It carries no refs and is
-- structurally identical to the rest, so it is read like any other row. A row is only ignored
-- when it is hidden or its Name label is blank, which is how the template looks when the cart
-- is empty. (The node that does hold a DeviceCheckout is DeviceListingCartItem, over in the
-- store listing area -- that one is only ever used as the borrowed order-line template.)
local CART_HOLDER_PATS = { "CartItems", "*CartItems*", "*CartList*", "*cart_items*" }

local function node_name(n) return tostring(call0(n, "get_name") or "") end

local function is_preview(n) return string.find(node_name(n), "Preview", 1, true) ~= nil end

local function child_named(node, name)
    if node == nil then return nil end
    local n = call0(node, "get_child_count")
    if type(n) ~= "number" then return nil end
    for i = 0, n - 1 do
        local c = call1(node, "get_child", i)
        if c and node_name(c) == name then return c end
    end
    return nil
end

local function text_of(node)
    local t = get_prop(node, "text")
    if type(t) == "string" then return trim(t) end
    return ""
end

local function first_number(s)
    return tonumber(string.match(tostring(s), "%-?%d+%.?%d*"))
end

local function is_cart_row(n)
    if child_named(n, "Name") == nil or child_named(n, "Subtotal") == nil then return false end
    if get_prop(n, "visible") == false then return false end
    return text_of(child_named(n, "Name")) ~= ""
end

-- Quantity lives somewhere inside QtyContainer, next to its +/- buttons.
local function qty_from_container(container)
    if container == nil then return nil end
    local n = call0(container, "get_child_count")
    if type(n) ~= "number" then return nil end
    for i = 0, n - 1 do
        local c = call1(container, "get_child", i)
        if c then
            local v = get_prop(c, "value")            -- SpinBox
            if type(v) == "number" then return math.floor(v + 0.5) end
            local t = get_prop(c, "text")             -- Label such as "5" or "x5"
            if type(t) == "string" then
                local num = string.match(t, "^%s*[xX]?%s*(%d+)") or string.match(t, "(%d+)%s*[xX]?%s*$")
                if num then return tonumber(num) end
            end
        end
    end
    return nil
end

local function find_market_app(root)
    for _, p in ipairs({ "*market*", "*Market*", "*DMarket*", "*Dmarket*", "*dmarket*" }) do
        local ok, found = pcall(_c4, root, "find_children", p, "", true, false)
        if ok then
            for _, n in ipairs(arr_list(found, 40)) do
                if get_prop(n, "chkoctl") ~= nil or get_prop(n, "lstctn") ~= nil then return n end
            end
        end
    end
    return nil
end

local function find_cart_holders(root)
    local out = {}
    for _, p in ipairs(CART_HOLDER_PATS) do
        local ok, found = pcall(_c4, root, "find_children", p, "", true, false)
        if ok then
            for _, n in ipairs(arr_list(found, 10)) do
                if not is_preview(n) then out[#out + 1] = n end
            end
        end
        if #out > 0 then return out end
    end
    return out
end

-- Never guesses: an empty cart reports empty rather than falling back to a global search.
local function find_cart_rows()
    local root = get_scene_root()
    if not root then return {} end
    local rows = {}
    for _, holder in ipairs(find_cart_holders(root)) do
        local n = call0(holder, "get_child_count")
        if type(n) == "number" then
            for i = 0, n - 1 do
                local c = call1(holder, "get_child", i)
                if c and is_cart_row(c) then rows[#rows + 1] = c end
            end
        end
        if #rows > 0 then
            dlog("cart rows under " .. node_name(holder) .. ": " .. #rows)
            return rows
        end
    end
    return rows
end

-- DeviceCheckout cannot be constructed (fact 2), so one live instance is borrowed and
-- reused for every order line. The bridge ref-counts objects handed to Lua, so it stays
-- alive after the player clears their cart.
-- The cart's own rows carry no objects, so the one reachable DeviceCheckout in the whole tree
-- belongs to the store's DeviceListingCartItem (the preview row). That is fine: only the object
-- is wanted, never its contents -- listing, quantity and varsel are overwritten per order line.
local function borrow_checkout()
    if spare_checkout ~= nil then return spare_checkout end
    local root = get_scene_root()
    if not root then return nil end
    for _, p in ipairs({ "*CartItem*", "*ListingCart*", "*Listing*", "*Checkout*" }) do
        local ok, found = pcall(_c4, root, "find_children", p, "", true, false)
        if ok then
            for _, n in ipairs(arr_list(found, 60)) do
                local c = get_prop(n, "checkout_item_ref") or get_prop(n, "device_checkout")
                if c ~= nil then
                    spare_checkout = c
                    log("order-line template borrowed from " .. node_name(n))
                    return c
                end
            end
        end
    end
    return nil
end

-- A cart row exposes no objects, so the listing has to be found back by its title. Price
-- breaks the tie when two merchants list the same name.
local function listing_by_title(title, price)
    local best_l, best_m, best_i
    for _, m in ipairs(get_merchants()) do
        local listings = merchant_listings(m)
        for i, l in ipairs(listings) do
            if get_prop(l, "listing_title") == title then
                if price and tonumber(get_prop(l, "price")) == price then return l, m, i - 1 end
                if not best_l then best_l, best_m, best_i = l, m, i - 1 end
            end
        end
    end
    return best_l, best_m, best_i
end

local BLANK_VARIANTS = { ["-"] = true, ["--"] = true, ["none"] = true, ["None"] = true,
                         ["N/A"] = true, ["n/a"] = true }

local function row_to_item(row)
    local title = text_of(child_named(row, "Name"))
    if title == "" then return nil end

    -- Rows sometimes prefix the count, e.g. "4x Ethernet 500".
    local prefix_qty, stripped = string.match(title, "^(%d+)%s*[xX]%s+(.+)$")
    if stripped then title = trim(stripped) end

    local unit = first_number(text_of(child_named(row, "UnitPrice")))
    local sub  = first_number(text_of(child_named(row, "Subtotal")))

    local qty = qty_from_container(child_named(row, "QtyContainer"))
    if not qty and prefix_qty then qty = tonumber(prefix_qty) end
    if not qty and unit and unit > 0 and sub then qty = math.floor(sub / unit + 0.5) end
    if not qty or qty < 1 then qty = 1 end

    local varsel = text_of(child_named(row, "Variant"))
    if BLANK_VARIANTS[varsel] then varsel = "" end

    local listing, merchant, idx = listing_by_title(title, unit)
    if not listing or not merchant then
        log("  cart line '" .. title .. "' matches no current listing")
        return nil
    end

    return {
        merchant = tostring(get_prop(merchant, "display_name") or ""),
        title = title, qty = qty, varsel = varsel,
        price = tonumber(get_prop(listing, "price")) or unit or 0,
        idx = idx or -1,
    }
end

local function scan_open_cart()
    local rows = find_cart_rows()
    if #rows == 0 then return {}, "no cart rows found -- is D-Market2 open with items in the cart?" end
    if spare_checkout == nil then borrow_checkout() end
    local items = {}
    for _, r in ipairs(rows) do
        local it = row_to_item(r)
        if it then items[#items + 1] = it end
    end
    if #items == 0 then return {}, "found cart rows but could not read them" end
    return items, nil
end

-- =========================================================================
-- Ordering. One line per submit_order call, because every line reuses the
-- same borrowed checkout object.
-- =========================================================================

local function order_cart(cart)
    if not cart or #cart.items == 0 then return false, "that list is empty" end
    local co = borrow_checkout()
    if co == nil then
        return false, "no order-line template yet -- open D-Market2 once so its listings exist, " ..
                      "then try again"
    end

    local floor = cart.floor or 0
    local placed, skipped, failed = 0, 0, 0
    local problems = {}

    for _, it in ipairs(cart.items) do
        local merchant = find_merchant(it.merchant)
        local listing = merchant and find_listing(merchant, it)
        if not merchant then
            failed = failed + 1
            problems[#problems + 1] = it.merchant .. ": merchant not found"
        elseif not listing then
            failed = failed + 1
            problems[#problems + 1] = it.title .. ": no longer listed"
        else
            local qty = it.qty or 1
            local stock = tonumber(get_prop(listing, "stock"))
            if get_prop(listing, "available") == false then
                skipped = skipped + 1
                problems[#problems + 1] = it.title .. ": not available"
            elseif stock and stock <= 0 then
                skipped = skipped + 1
                problems[#problems + 1] = it.title .. ": out of stock"
            else
                if stock and qty > stock then
                    problems[#problems + 1] = it.title .. ": only " .. stock .. " in stock"
                    if config.clamp_to_stock then qty = stock else qty = 0 skipped = skipped + 1 end
                end
                if qty > 0 then
                    set_prop(co, "listing", listing)
                    set_prop(co, "quantity", qty)
                    set_prop(co, "varsel", it.varsel or "")
                    if config.set_subtotal then
                        set_prop(co, "subtotal", (tonumber(get_prop(listing, "price")) or 0) * qty)
                    end
                    local batch = Array.create()
                    batch[0] = co
                    local ok, res = pcall(_c2, merchant, "submit_order", batch, floor)
                    if ok and res ~= false then
                        placed = placed + 1
                    else
                        failed = failed + 1
                        problems[#problems + 1] = it.title .. ": order rejected"
                    end
                end
            end
        end
    end

    for _, p in ipairs(problems) do log("  " .. p) end
    local msg = cart.name .. ": ordered " .. placed .. " line(s)"
    if skipped > 0 then msg = msg .. ", " .. skipped .. " skipped" end
    if failed > 0 then msg = msg .. ", " .. failed .. " failed" end
    return placed > 0, msg
end

-- =========================================================================
-- UI
-- =========================================================================

local ui = {
    built = false, root = nil, status = nil,
    views = {},        -- ONLY the three swappable view containers
    node = {},         -- named widget references
    fixed = {},        -- buttons that live for the whole session
    rows = {},         -- buttons inside rebuildable rows; cleared before their nodes are freed
    watches = {},
    edit_rows = {}, editing = nil, working = {}, add = {},
}

local VIEW_LIST, VIEW_EDIT, VIEW_ADD, VIEW_CODE = "list", "edit", "add", "code"

local function set_status(msg)
    if ui.status then set_prop(ui.status, "text", tostring(msg)) end
    log(msg)
end

local function mk(class_name, name, parent)
    local node = create_node(class_name, name)
    if node and parent then pcall(_c1, parent, "add_child", node) end
    return node
end

local function add_button(parent, text, action, into)
    local b = mk("Button", "btn", parent)
    if not b then return nil end
    set_prop(b, "text", text)
    set_prop(b, "toggle_mode", true)
    local list = into or ui.fixed
    list[#list + 1] = { node = b, action = action }
    return b
end

local function label(parent, text, expand)
    local l = mk("Label", "lbl", parent)
    if l then
        set_prop(l, "text", tostring(text))
        if expand then set_prop(l, "size_flags_horizontal", 3) end
    end
    return l
end

local function hbox(parent)
    local h = mk("HBoxContainer", "row", parent)
    if h then set_prop(h, "size_flags_horizontal", 3) end
    return h
end

-- Poll entries must be dropped BEFORE the nodes die (fact 5).
local function clear_rows(container)
    ui.rows = {}
    if not container then return end
    local n = call0(container, "get_child_count")
    if type(n) ~= "number" then return end
    for i = n - 1, 0, -1 do
        local child = call1(container, "get_child", i)
        if child then
            pcall(_c1, container, "remove_child", child)
            pcall(_c0, child, "queue_free")
        end
    end
end

local function show_view(name)
    for key, node in pairs(ui.views) do set_prop(node, "visible", key == name) end
end

local refresh_list, open_editor, open_add, rebuild_edit_rows

-- ---------- list view ----------

refresh_list = function()
    clear_rows(ui.node.list_box)
    if #carts == 0 then
        label(ui.node.list_box, "No lists yet. Press 'New list'.")
    else
        for _, cart in ipairs(carts) do
            local row = hbox(ui.node.list_box)
            local total = 0
            for _, it in ipairs(cart.items) do total = total + (it.price or 0) * (it.qty or 1) end
            label(row, cart.name .. "  -  " .. #cart.items .. " line(s), ~" .. total .. " cr", true)
            local this = cart
            add_button(row, "Order", function()
                local ok, msg = order_cart(this)
                notify(msg)
            end, ui.rows)
            add_button(row, "Edit", function() open_editor(this) end, ui.rows)
            add_button(row, "Del", function()
                for i, c in ipairs(carts) do if c == this then table.remove(carts, i) break end end
                save_carts()
                refresh_list()
                set_status("Deleted " .. this.name)
            end, ui.rows)
        end
    end
    show_view(VIEW_LIST)
end

-- ---------- edit view ----------

rebuild_edit_rows = function()
    clear_rows(ui.node.edit_box)
    ui.edit_rows = {}
    if #ui.working == 0 then
        label(ui.node.edit_box, "No lines yet. Press 'Add item'.")
        return
    end
    local colors = split_commas(config.cable_colors)
    for _, it in ipairs(ui.working) do
        local row = hbox(ui.node.edit_box)
        label(row, it.title .. "  [" .. it.merchant .. "]", true)

        local spin = mk("SpinBox", "qty", row)
        set_prop(spin, "min_value", 0)
        set_prop(spin, "max_value", 999)
        set_prop(spin, "step", 1)
        set_prop(spin, "value", it.qty or 1)

        local copt = nil
        if it.varsel and it.varsel ~= "" then
            copt = mk("OptionButton", "color", row)
            local sel, seen = 0, false
            for i, c in ipairs(colors) do
                call2(copt, "add_item", c, i - 1)
                if c == it.varsel then sel = i - 1 seen = true end
            end
            if not seen then call2(copt, "add_item", it.varsel, #colors) sel = #colors end
            set_prop(copt, "selected", sel)
        end

        local entry = { item = it, spin = spin, copt = copt, removed = false }
        ui.edit_rows[#ui.edit_rows + 1] = entry
        add_button(row, "X", function()
            entry.removed = true
            set_prop(row, "visible", false)
            set_status("Line removed -- press Save to keep it")
        end, ui.rows)
    end
end

local function collect_edit_items()
    local items = {}
    for _, e in ipairs(ui.edit_rows) do
        if not e.removed then
            local qty = e.item.qty or 1
            local v = get_prop(e.spin, "value")
            if type(v) == "number" then qty = math.floor(v + 0.5) end
            -- A zero-quantity line is kept, not silently dropped: dropping it here also lost
            -- lines every time this ran as a snapshot before switching views. Use X to remove.
            do
                local varsel = e.item.varsel or ""
                if e.copt then
                    local sel = get_prop(e.copt, "selected")
                    if type(sel) == "number" and sel >= 0 then
                        local t = call1(e.copt, "get_item_text", sel)
                        if type(t) == "string" and t ~= "" then varsel = t end
                    end
                end
                items[#items + 1] = {
                    merchant = e.item.merchant, title = e.item.title, qty = qty,
                    varsel = varsel, price = e.item.price, idx = e.item.idx,
                }
            end
        end
    end
    return items
end

local function fill_floor_options(selected)
    local opt = ui.node.floor_opt
    if not opt then return end
    call0(opt, "clear")
    call2(opt, "add_item", "Default (0)", 0)
    local chosen = 0
    for i, f in ipairs(get_floors()) do
        call2(opt, "add_item", f.label, f.index)
        if f.index == selected then chosen = i end
    end
    set_prop(opt, "selected", chosen)
end

open_editor = function(cart)
    ui.editing = cart
    ui.working = {}
    local name, floor = "List " .. (#carts + 1), 0
    if cart then
        name, floor = cart.name, cart.floor or 0
        for _, it in ipairs(cart.items) do
            ui.working[#ui.working + 1] = {
                merchant = it.merchant, title = it.title, qty = it.qty,
                varsel = it.varsel, price = it.price, idx = it.idx,
            }
        end
    end
    set_prop(ui.node.name_edit, "text", name)
    fill_floor_options(floor)
    rebuild_edit_rows()
    show_view(VIEW_EDIT)
end

-- ---------- add-item view ----------

local function add_fill_listings()
    local opt = ui.add.listing_opt
    if not opt then return end
    call0(opt, "clear")
    ui.add.listings = {}
    local m = ui.add.merchants and ui.add.merchants[(get_prop(ui.add.merchant_opt, "selected") or 0) + 1]
    if not m then return end
    for i, l in ipairs(merchant_listings(m.node)) do
        local title = tostring(get_prop(l, "listing_title") or "?")
        local price = tonumber(get_prop(l, "price")) or 0
        ui.add.listings[i] = {
            title = title, price = price, idx = i - 1,
            variant = tonumber(get_prop(l, "allowed_variant")) or 0,
        }
        call2(opt, "add_item",
            title .. "  " .. price .. "cr  (" .. (tonumber(get_prop(l, "stock")) or 0) .. ")", i - 1)
    end
    set_prop(opt, "selected", 0)
end

local function add_refresh_color()
    local e = ui.add.listings and ui.add.listings[(get_prop(ui.add.listing_opt, "selected") or 0) + 1]
    set_prop(ui.add.color_row, "visible", (e and e.variant == 1) and true or false)
end

open_add = function()
    ui.add.merchants = {}
    local opt = ui.add.merchant_opt
    call0(opt, "clear")
    for i, m in ipairs(get_merchants()) do
        local name = tostring(get_prop(m, "display_name") or ("Merchant " .. i))
        ui.add.merchants[i] = { node = m, name = name }
        call2(opt, "add_item", name, i - 1)
    end
    set_prop(opt, "selected", 0)
    add_fill_listings()
    add_refresh_color()
    show_view(VIEW_ADD)
end

-- ---------- construction ----------

local TOGGLE_W = 128
local TOGGLE_GAP = 10
local TOGGLE_FALLBACK_X = 150

-- The mobile-OS activator sits in the same bottom-left corner, so the toggle is parked just
-- to its right. Vector2 does not cross the bridge, so position/size are unreadable -- but the
-- individual anchor/offset floats do, and that is enough to find its right edge.
local function toggle_left_edge()
    if type(config.toggle_x) == "number" and config.toggle_x >= 0 then return config.toggle_x end

    local world = get_world()
    local cvl = world and get_prop(world, "mobile_os_cvl")
    local act = cvl and get_prop(cvl, "activator_control")
    if act ~= nil then
        local anchor_l = get_prop(act, "anchor_left")
        local right = get_prop(act, "offset_right")
        if anchor_l == 0 and type(right) == "number" and right > 0 then
            dlog("toggle placed right of the mobile-OS button (edge " .. right .. ")")
            return right + TOGGLE_GAP
        end
    end
    dlog("mobile-OS button not measurable; using fallback toggle_x")
    return TOGGLE_FALLBACK_X
end

-- A hot reload re-runs this file with fresh Lua state, but the nodes built by the previous load
-- are still parented to BaseUI. Nothing polls them any more, so they would sit there dead and
-- duplicated -- remove them before building again.
local function remove_stale_ui(base)
    local removed = 0
    for _, name in ipairs({ "CartSaverWindow", "CartSaverToggle" }) do
        local ok, found = pcall(_c4, base, "find_children", name, "", true, false)
        if ok then
            for _, n in ipairs(arr_list(found, 8)) do
                local parent = call0(n, "get_parent")
                if parent then pcall(_c1, parent, "remove_child", n) end
                pcall(_c0, n, "queue_free")
                removed = removed + 1
            end
        end
    end
    if removed > 0 then dlog("removed " .. removed .. " node(s) from a previous load") end
end

local function build_ui()
    if ui.built then return true end
    local base = ModApiV1 and ModApiV1.get_base_ui()
    if not base then return false end
    remove_stale_ui(base)
    local root = mk("PanelContainer", "CartSaverWindow", base)
    if not root then return false end
    ui.root = root
    set_prop(root, "anchor_left", 0.5)  set_prop(root, "anchor_top", 0.5)
    set_prop(root, "anchor_right", 0.5) set_prop(root, "anchor_bottom", 0.5)
    set_prop(root, "offset_left", -400) set_prop(root, "offset_top", -320)
    set_prop(root, "offset_right", 400) set_prop(root, "offset_bottom", 320)
    set_prop(root, "mouse_filter", 0)
    set_prop(root, "visible", false)

    local margin = mk("MarginContainer", "margin", root)
    for _, s in ipairs({ "margin_left", "margin_top", "margin_right", "margin_bottom" }) do
        call2(margin, "add_theme_constant_override", s, 12)
    end
    local outer = mk("VBoxContainer", "outer", margin)

    local title_row = hbox(outer)
    label(title_row, "Saved Carts v" .. MOD_VER, true)
    add_button(title_row, "Code", function()
        set_prop(ui.node.code_edit, "text", encode_carts())
        show_view(VIEW_CODE)
    end)
    add_button(title_row, "Close", function() set_prop(root, "visible", false) end)
    mk("HSeparator", "sep1", outer)

    -- list view
    local list_view = mk("VBoxContainer", "list_view", outer)
    set_prop(list_view, "size_flags_vertical", 3)
    ui.views[VIEW_LIST] = list_view
    local lt = hbox(list_view)
    add_button(lt, "New list", function() open_editor(nil) end)
    add_button(lt, "Reload", function() load_carts() refresh_list() set_status("Reloaded") end)
    local ls = mk("ScrollContainer", "list_scroll", list_view)
    set_prop(ls, "size_flags_vertical", 3) set_prop(ls, "size_flags_horizontal", 3)
    ui.node.list_box = mk("VBoxContainer", "list_box", ls)
    set_prop(ui.node.list_box, "size_flags_horizontal", 3)

    -- edit view
    local edit_view = mk("VBoxContainer", "edit_view", outer)
    set_prop(edit_view, "size_flags_vertical", 3)
    ui.views[VIEW_EDIT] = edit_view
    local nr = hbox(edit_view)
    label(nr, "Name")
    ui.node.name_edit = mk("LineEdit", "name", nr)
    set_prop(ui.node.name_edit, "size_flags_horizontal", 3)
    label(nr, "Floor")
    ui.node.floor_opt = mk("OptionButton", "floor", nr)
    local es = mk("ScrollContainer", "edit_scroll", edit_view)
    set_prop(es, "size_flags_vertical", 3) set_prop(es, "size_flags_horizontal", 3)
    ui.node.edit_box = mk("VBoxContainer", "edit_box", es)
    set_prop(ui.node.edit_box, "size_flags_horizontal", 3)
    local et = hbox(edit_view)
    add_button(et, "Add item", function() ui.working = collect_edit_items() open_add() end)
    add_button(et, "Add open cart", function()
        local scanned, err = scan_open_cart()
        if err then set_status(err) return end
        ui.working = collect_edit_items()
        for _, it in ipairs(scanned) do ui.working[#ui.working + 1] = it end
        rebuild_edit_rows()
        set_status("Added " .. #scanned .. " line(s) from the open cart")
    end)
    add_button(et, "Save", function()
        local name = trim(get_prop(ui.node.name_edit, "text") or "")
        if name == "" then name = "List " .. (#carts + 1) end
        local floor = call0(ui.node.floor_opt, "get_selected_id")
        if type(floor) ~= "number" then floor = 0 end
        local items = collect_edit_items()
        if ui.editing then
            ui.editing.name, ui.editing.floor, ui.editing.items = name, floor, items
        else
            carts[#carts + 1] = { name = name, floor = floor, items = items }
        end
        local stored = save_carts()
        refresh_list()
        set_status("Saved '" .. name .. "' (" .. #items .. " line(s))" ..
            (stored and "" or " -- NOT stored, use Code to keep a copy"))
    end)
    add_button(et, "Cancel", function() refresh_list() set_status("Cancelled") end)

    -- add-item view
    local add_view = mk("VBoxContainer", "add_view", outer)
    set_prop(add_view, "size_flags_vertical", 3)
    ui.views[VIEW_ADD] = add_view
    local mr = hbox(add_view)
    label(mr, "Merchant")
    ui.add.merchant_opt = mk("OptionButton", "merchant", mr)
    set_prop(ui.add.merchant_opt, "size_flags_horizontal", 3)
    local ir = hbox(add_view)
    label(ir, "Item")
    ui.add.listing_opt = mk("OptionButton", "listing", ir)
    set_prop(ui.add.listing_opt, "size_flags_horizontal", 3)
    local qr = hbox(add_view)
    label(qr, "Quantity")
    ui.add.qty = mk("SpinBox", "addqty", qr)
    set_prop(ui.add.qty, "min_value", 1) set_prop(ui.add.qty, "max_value", 999)
    set_prop(ui.add.qty, "step", 1) set_prop(ui.add.qty, "value", 1)
    ui.add.color_row = hbox(add_view)
    label(ui.add.color_row, "Colour")
    ui.add.color_opt = mk("OptionButton", "addcolor", ui.add.color_row)
    for i, c in ipairs(split_commas(config.cable_colors)) do
        call2(ui.add.color_opt, "add_item", c, i - 1)
    end
    set_prop(ui.add.color_opt, "selected", 0)
    ui.watches[#ui.watches + 1] = { node = ui.add.merchant_opt, last = 0,
        action = function() add_fill_listings() add_refresh_color() end }
    ui.watches[#ui.watches + 1] = { node = ui.add.listing_opt, last = 0, action = add_refresh_color }

    local at = hbox(add_view)
    add_button(at, "Add to list", function()
        local e = ui.add.listings and ui.add.listings[(get_prop(ui.add.listing_opt, "selected") or 0) + 1]
        if not e then set_status("Pick an item first") return end
        local m = ui.add.merchants[(get_prop(ui.add.merchant_opt, "selected") or 0) + 1]
        local varsel = ""
        if e.variant == 1 then
            local t = call1(ui.add.color_opt, "get_item_text", get_prop(ui.add.color_opt, "selected") or 0)
            if type(t) == "string" then varsel = t end
        end
        ui.working[#ui.working + 1] = {
            merchant = m and m.name or "", title = e.title,
            qty = math.floor((get_prop(ui.add.qty, "value") or 1) + 0.5),
            varsel = varsel, price = e.price, idx = e.idx,
        }
        rebuild_edit_rows()
        show_view(VIEW_EDIT)
        set_status("Added " .. e.title)
    end)
    add_button(at, "Back", function() rebuild_edit_rows() show_view(VIEW_EDIT) end)

    -- code view (manual backup / transfer)
    local code_view = mk("VBoxContainer", "code_view", outer)
    set_prop(code_view, "size_flags_vertical", 3)
    ui.views[VIEW_CODE] = code_view
    label(code_view, "Select the text and press Ctrl+C to back up your lists.")
    label(code_view, "Paste a code here and press Import to restore them.")
    ui.node.code_edit = mk("LineEdit", "code", code_view)
    set_prop(ui.node.code_edit, "size_flags_horizontal", 3)
    local ct = hbox(code_view)
    add_button(ct, "Import", function()
        local decoded, err = decode_carts(get_prop(ui.node.code_edit, "text") or "")
        if err then set_status(err) end
        if decoded and #decoded > 0 then
            carts = decoded
            save_carts()
            refresh_list()
            set_status("Imported " .. #carts .. " list(s)")
        elseif not err then
            set_status("nothing to import")
        end
    end)
    -- LineEdit.menu_option(MENU_COPY) puts the selection on the real OS clipboard, which is
    -- the only route to it: DisplayServer would need Engine.get_singleton(), and that is banned.
    add_button(ct, "Copy", function()
        local le = ui.node.code_edit
        set_prop(le, "text", encode_carts())
        call0(le, "grab_focus")
        call0(le, "select_all")
        call1(le, "menu_option", 1)
        set_status("Copied to the clipboard -- paste it anywhere with Ctrl+V")
    end)
    add_button(ct, "Done", function() refresh_list() end)

    mk("HSeparator", "sep2", outer)
    ui.status = label(outer, "Ready", true)

    if config.show_toggle_button then
        local t = mk("Button", "CartSaverToggle", base)
        set_prop(t, "text", "Saved Carts")
        set_prop(t, "toggle_mode", true)
        local left = toggle_left_edge()
        set_prop(t, "anchor_left", 0.0)  set_prop(t, "anchor_top", 1.0)
        set_prop(t, "anchor_right", 0.0) set_prop(t, "anchor_bottom", 1.0)
        set_prop(t, "offset_left", left) set_prop(t, "offset_top", -46)
        set_prop(t, "offset_right", left + TOGGLE_W) set_prop(t, "offset_bottom", -12)
        ui.fixed[#ui.fixed + 1] = { node = t, always = true, action = function()
            local vis = get_prop(ui.root, "visible")
            set_prop(ui.root, "visible", not vis)
            if not vis then refresh_list() end
        end }
    end

    ui.built = true
    refresh_list()
    return true
end

-- =========================================================================
-- Polling -- the entire input system (facts 3 and 4)
-- =========================================================================

-- Handles at most ONE press per poll and then stops. An action such as Delete rebuilds the
-- rows and frees their buttons, so carrying on through the rest of the list would touch a
-- freed node -- an uncatchable bad_cast that takes the game down (fact 5).
---@return boolean handled
local function poll_list(list, window_open)
    for i = 1, #list do
        local e = list[i]
        if e.always or window_open then
            if get_prop(e.node, "button_pressed") == true then
                set_prop(e.node, "button_pressed", false)
                local ok, err = pcall(e.action)
                if not ok then log("action failed: " .. tostring(err)) end
                return true
            end
        end
    end
    return false
end

local function poll_ui()
    local open = get_prop(ui.root, "visible") == true
    if poll_list(ui.fixed, open) then return end
    if not open then return end
    if poll_list(ui.rows, true) then return end
    for i = 1, #ui.watches do
        local w = ui.watches[i]
        local now = get_prop(w.node, "selected")
        if now ~= w.last then
            w.last = now
            pcall(w.action)
        end
    end
end

-- =========================================================================
-- Console commands. Only the command that just ran is re-registered, because
-- every registration pins another coroutine in the Lua registry (fact 3).
-- =========================================================================

local cmd_impls, pending_cmd = {}, nil

local function register_cmd(name)
    if not dbg_layer or not cmd_impls[name] then return end
    pcall(_c2, dbg_layer, "register_cmd", name, function()
        local ok, err = pcall(cmd_impls[name])
        if not ok then log(name .. " failed: " .. tostring(err)) end
        pending_cmd = name
        return nil
    end)
end

cmd_impls["carts"] = function()
    if not build_ui() then log("panel unavailable") return end
    local vis = get_prop(ui.root, "visible")
    set_prop(ui.root, "visible", not vis)
    if not vis then refresh_list() end
end

cmd_impls["cart_code"] = function() log(encode_carts()) end

-- Dumps what each candidate node actually looks like, so cart-row detection can be
-- corrected against reality rather than guessed at.
cmd_impls["cart_scan"] = function()
    local root = get_scene_root()
    if not root then log("no scene root") return end
    local app = find_market_app(root)
    log("-- scan --")
    log("market app: " .. tostring(app and call0(app, "get_name") or "not found") ..
        "  chkoctl: " .. tostring(app and get_prop(app, "chkoctl") ~= nil))

    local function describe(n, indent)
        local marks = ""
        for _, f in ipairs({ "checkout_item_ref", "device_checkout", "listing_ref", "listing",
                             "listing_merchant_ref", "quantity", "varsel" }) do
            local v = get_prop(n, f)
            if v ~= nil then
                marks = marks .. " " .. f
                if f == "quantity" or f == "varsel" then marks = marks .. "=" .. tostring(v) end
            end
        end
        log(indent .. node_name(n) .. " (" .. tostring(call0(n, "get_class")) .. ")" .. marks)
    end

    local holders = find_cart_holders(root)
    log("cart containers found: " .. #holders)
    local budget = 24
    for _, h in ipairs(holders) do
        local kids = call0(h, "get_child_count")
        log("  " .. node_name(h) .. " children=" .. tostring(kids))
        if type(kids) == "number" then
            for i = 0, kids - 1 do
                if budget <= 0 then log("    ...") break end
                local c = call1(h, "get_child", i)
                if c then
                    describe(c, "    ")
                    budget = budget - 1
                    -- one level down, in case the row sits inside a wrapper
                    local gk = call0(c, "get_child_count")
                    if type(gk) == "number" and gk > 0 and budget > 0 then
                        for j = 0, gk - 1 do
                            local g = call1(c, "get_child", j)
                            if g and budget > 0 then describe(g, "      ") budget = budget - 1 end
                        end
                    end
                end
            end
        end
    end

    local nnode, nfield = find_notepad()
    if nnode then
        log("notepad: " .. node_name(nnode) .. " (" .. tostring(call0(nnode, "get_class")) ..
            ") field=" .. tostring(nfield))
    else
        log("notepad: not found -- lists will not persist; use Code + Copy")
    end

    local rows = find_cart_rows()
    log("cart rows detected: " .. #rows)
    for _, r in ipairs(rows) do
        log("   name='" .. text_of(child_named(r, "Name")) ..
            "' variant='" .. text_of(child_named(r, "Variant")) ..
            "' unit='" .. text_of(child_named(r, "UnitPrice")) ..
            "' sub='" .. text_of(child_named(r, "Subtotal")) ..
            "' qty=" .. tostring(qty_from_container(child_named(r, "QtyContainer"))))
    end
end

cmd_impls["cart_probe"] = function()
    log("-- probe --")
    log("merchants: " .. #get_merchants() .. "  floors: " .. #get_floors() .. "  lists: " .. #carts)
    log("notepad storage: " .. tostring(read_notepad_text() ~= nil))
    log("order template: " .. tostring(spare_checkout ~= nil))
    local rows = find_cart_rows()
    log("open cart rows: " .. #rows)
    log("panel built: " .. tostring(ui.built))
end

-- =========================================================================
-- Lifecycle
-- =========================================================================

-- Setup is idempotent and driven from on_game_tick as well as on_game_state_ready, because a
-- hot reload re-runs this file WITHOUT firing any of the one-shot lifecycle hooks again.
-- Relying on on_game_state_ready alone leaves a reloaded mod with no panel, and no console
-- commands either -- the previous state's one-shot Callables are gone, so every command
-- returns null until something re-registers them.
local initialised = false

local function ensure_ready()
    if initialised then return true end
    local base = ModApiV1 and ModApiV1.get_base_ui()
    local world = get_world()
    if not base or not world then return false end

    local d = call1(world, "get_node", "/root/DebugLayer")
    if d then
        dbg_layer = d
        set_prop(d, "enabled", true)
        set_prop(d, "visible", true)
        for name in pairs(cmd_impls) do register_cmd(name) end
    end

    load_carts()
    if not build_ui() then return false end

    initialised = true
    log("v" .. MOD_VER .. " ready -- " .. #carts ..
        " list(s). Commands: carts, cart_code, cart_probe, cart_scan")
    return true
end

function on_game_state_ready() pcall(ensure_ready) end

local ticks = 0

function on_game_tick(delta)
    ticks = ticks + 1
    if ticks < (config.poll_every_n_ticks or 4) then return end
    ticks = 0
    if not initialised then pcall(ensure_ready) return end
    pcall(poll_ui)
    if pending_cmd then
        local n = pending_cmd
        pending_cmd = nil
        register_cmd(n)
    end
end
