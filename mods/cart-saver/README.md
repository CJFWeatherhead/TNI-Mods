# Cart Saver — Saved Shopping Lists

Setting up a new floor means ordering the same things every time: a server, a power cord,
a couple of ethernet runs, the peripherals. Typing that list into D-Market2 again and again
gets old fast.

Cart Saver lets you build the list once and order it later with one button.

## Features

- **Build lists in-game** by browsing merchants and their live stock
- **Order in one click** — orders go through the merchant's real order path, so stock checks,
  pricing, warranties and delivery all work exactly as if you had ordered by hand
- **Manage lists** — rename, delete, edit
- **Edit quantities** per line, or drop lines you do not need this time
- **Remembers cable colours**, and will happily order *several colours of the same cable from
  one list* — something the shop will not let you do normally
- **Per-list delivery floor**
- **Handles out-of-stock gracefully** — a short line is clamped to what is available, and each
  line is submitted separately so one bad item never loses the rest

## Installation

1. Install [luajit-support](https://github.com/CJFWeatherhead/TNI-Mods/releases) into your
   `mods/` folder first — Lua mods will not load without it.
2. Extract `cart-saver` into `mods/` so that `mods/cart-saver/entry.lua` exists.

Game data folder:

- Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc`
- Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc`

## Usage

1. Click **Saved Carts** in the bottom-left corner of the screen, or press `~` and type `carts`.
2. Press **New list**, then **Add item**. Pick a merchant, an item, a quantity, and a colour
   if it is a cable. Repeat for everything you want.
3. Give the list a name, choose a delivery floor, press **Save**.
4. Next time you are building a floor, open the panel and press **Order**.

Ordering needs one internal object that the sandbox will not let a mod create, so Cart Saver
borrows one from a D-Market2 listing row the first time you order. That happens by itself; it
only needs D-Market2 to have been opened at least once this session.

### Editing a list

Press **Edit** on any saved list to get a row per line:

| Control | What it does |
|---------|--------------|
| Quantity box | How many to order |
| Colour dropdown | Shown only for cables and anything else with a colour option |
| `X` | Remove the line (takes effect when you press **Save**) |
| **Add item** | Browse merchants and their stock, and add a line |
| **Add open cart** | Merge whatever is in D-Market2 right now into this list |

### Console commands

Press `~` to open the debug console.

| Command | What it does |
|---------|--------------|
| `carts` | Open / close the panel |
| `cart_code` | Print the backup code for all your lists |
| `cart_probe` | Diagnostics — **run this first if something looks wrong** |
| `cart_scan` | Dump the market UI nodes, for debugging cart importing |

Output appears in the console and in `logs/godot.log`.

## Where lists are stored

Mods are not allowed to write files in this game, so lists live in the **in-game clipboard
notepad**, wrapped in markers:

```
whatever notes you already had
[cartsaver]CS1~1|Floor kit~3~Mr Cable~Ethernet 500~4~Blue~15~0[/cartsaver]
```

Everything outside the markers is left untouched, and the block is rewritten in place rather
than appended to. Because it lives in the notepad, it is saved with your game.

Press **Code**, then **Copy**, to put a backup string on your system clipboard — paste it
anywhere you like with `Ctrl+V`. Pasting it back into the field and pressing **Import** restores
every list, which is also how you move lists to another save.

## Configuration

Configurable through ModManager, or by editing the config block at the top of `entry.lua`.

| Setting | Default | What it does |
|---------|---------|--------------|
| Show On-Screen Button | on | The bottom-left **Saved Carts** button. Turn off for console-only. |
| Saved Carts Button X Position | -1 (auto) | Pixels from the left edge. Auto places it just right of the mobile-OS button. |
| Store Lists In The Notepad | on | Persist lists in the clipboard notepad |
| Clamp Quantities To Stock | on | Order what is left rather than skipping a short line |
| Write Line Subtotals | on | Sets each line's subtotal to price × quantity. Turn off if you are ever charged wrongly. |
| Cable Colour Choices | `Original,Yellow,…` | Colours offered for cable lines |
| UI Poll Interval | 4 ticks | How often buttons are polled. Higher is cheaper, less responsive. |
| Enable Debug Logging | off | Extra console detail |

## Compatibility

- Game version: stable (`^0.10.7`), built against the 0.10.11 mod API
- Requires `luajit-support`
- No gameplay changes — it only places orders you ask it to place
- Works alongside `inverse-prices`, `money-cheat` and other economy mods, since orders go
  through the normal merchant path

## Known limitations

- **Add open cart** reads only the `CartItems` container. If the cart is empty it imports
  nothing rather than guessing; run `cart_scan` to see what it can find.
- **Listings are matched by title**, then by price, then by remembered position. If a merchant
  renames something the mod says so in the console.
- **Colours** come from the configured list; colours imported from a real cart are replayed
  exactly as the game recorded them.

## Notes for mod developers

This mod is shaped almost entirely by sandbox limits that are not obvious until you hit them.
All of these were confirmed from `logs/godot.log`:

| Limit | Consequence |
|-------|-------------|
| `ModFileSystem` refuses writes | No config or save files; storage is the in-game notepad |
| `get_script()` is banned, `create_node()` is engine-only | Game script classes cannot be instantiated; borrow an instance instead |
| A Lua function used as a `Callable` **fires once** | No signal connections at all — poll instead |
| A Lua error inside a Callable freezes the game | The bridge rethrows it as a C++ exception; unwinding it in the VM exhausts the sandbox budget (`Sandbox: Timeout`) |
| The Lua heap is ~1800 KB and OOM is fatal | Avoid `pcall(function() ... end)` in hot paths; use `pcall(shared_fn, args...)`. Retry paths count as hot paths. |
| Every `register_cmd` pins a coroutine forever | Register each console command once. Re-registering on a per-frame retry exhausts the heap in seconds. |
| Touching a freed object throws an uncatchable `bad_cast` | Deregister poll entries *before* freeing their nodes |
| `find_children` matches the engine class | Script class names like `V2CartItem` never match; use name patterns |
| Cart rows carry no data at all | They are plain code-built `HBoxContainer`s (`@HBoxContainer@6806`) whose only content is five labels: `Name`, `Variant`, `QtyContainer`, `UnitPrice`, `Subtotal`. Find them structurally under `CartItems` and parse the text. |
| `CartItems`' first child is `CartItemPreview` | It mirrors the store's current filtered selection and is the only node holding a real `DeviceCheckout`. Skip it when reading, borrow from it for the order-line template. |
| The OS clipboard needs `DisplayServer`, which is banned | Use `LineEdit.select_all()` + `menu_option(MENU_COPY)` instead |
| No `Dictionary` or `Vector2` across the bridge | `current_local_cart` is unreadable; `custom_minimum_size` cannot be set |
| The per-frame hook is `on_game_tick(delta)` | `on_tick`, `on_engine_load`, `on_mod_reload` and `on_day_start` are never called |
| A hot reload re-runs the file but fires no hook | Make setup idempotent and drive it from `on_game_tick` too, or the reloaded mod has no UI and no working commands. Remove the previous load's nodes from `BaseUI` by name first. |

## Troubleshooting

Run `cart_probe` in the `~` console. It reports merchant and floor counts, whether notepad
storage is available, whether an order-line template has been borrowed, and how many cart rows
it can currently see.
