# Lua Mods

This directory contains Lua-based mods and related resources for Tower Networking Inc.

## Contents

- **`2x-bandwidth-switches/`**: Example mod that doubles switch bandwidth capacity
- **`.lua-typing/`**: Type definitions for IDE autocompletion and type checking (development aid)

## Creating Lua Mods

Lua mods are easier to create and iterate on compared to C/C++ mods:

### Advantages
- ✅ No compilation required
- ✅ Hot-reload support (press F11 in-game)
- ✅ Simpler syntax and faster development
- ✅ Naturally source-available

### Requirements

1. **LuaJIT Support Mod**: Must be installed first
   - Download from [GitHub releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)
   - Place as `mods/luajit.elf` in your game directory

2. **Your Lua Mod**: Place `.lua` files directly in the `mods/` directory

## Quick Start

1. **Check the example**: See [`2x-bandwidth-switches/`](2x-bandwidth-switches/) for a complete working example

2. **Create your mod**: Start with this basic template:
   ```lua
   -- Called when all mods are loaded
   function on_engine_load()
       print("My mod loaded!")
       ModApiV1.sanity()  -- Verify API is working
   end

   -- Add more callback functions as needed
   ```

3. **Save as `.lua` file**: e.g., `my-mod.lua`

4. **Install and test**:
   - Copy to your game's `mods/` directory
   - Launch the game
   - Press F11 to reload after making changes

## Available Callbacks

Your Lua mod can implement any of these callback functions:

- `on_mod_load()` - Called when the mod loads
- `on_engine_load()` - Called when all mods are loaded
- `on_mod_reload()` - Called when F11 is pressed (hot reload)
- `on_game_state_ready()` - Called when the game is ready
- `on_game_tick(delta)` - Called every frame
- `on_player_input(event)` - Called on player input
- `on_device_spawned(device)` - Called when a device is created
- `on_game_host_eod()` - Called at end of day

## Type Definitions

For IDE support with autocompletion and type checking:

- Use the type definitions in [`.lua-typing/`](.lua-typing/)
- Install [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) for VS Code
- Type annotations will automatically provide hints

## Resources

- **Main README**: [Documentation root](../README.md)
- **Example Mod**: [2x Bandwidth Switches](2x-bandwidth-switches/)
- **C++ Template**: [For comparison](../programs/tni-mod-template/)
- **Contributing**: [Guidelines](../CONTRIBUTING.md)

## Tips

- **Use `print()`** for debugging - output appears in game logs
- **Press F11** to reload your mod without restarting the game
- **Check examples** - learn from working code
- **Test frequently** - rapid iteration is Lua's strength!

## Need Help?

- Review the [example mod](2x-bandwidth-switches/README.md)
- Check the [main documentation](../README.md)
- Open an issue on [GitHub](https://github.com/CJFWeatherhead/TNI-Mods/issues)
