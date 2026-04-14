# Lua Type Definitions

This directory contains Lua type annotation files for use with Lua Language Server (LuaLS) to provide IDE autocompletion and type checking when developing Lua mods.

## What's Inside

- **`globals.lua`**: Global type definitions for the mod API
- **`godot/`**: Type definitions for Godot engine classes
- **`godot-fill/`**: Additional Godot type definitions
- **`tni/`**: Type definitions for Tower Networking Inc game-specific classes
- **`create_node.lua`**: Node creation type definitions

## Using These Definitions

### With Lua Language Server

If you're using a Lua-aware IDE (like VS Code with Lua Language Server extension), these type definitions will automatically provide:

- **Autocompletion**: See available methods and properties
- **Type checking**: Catch errors before running your mod
- **Documentation**: View inline documentation for API functions

### Setup for VS Code

1. Install the [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) extension
2. Open your Lua mod directory
3. The type definitions in this directory will be automatically detected

### Example Usage

```lua
---@param device DeviceUnit
function on_device_spawned(device)
    -- IDE will show autocompletion for device properties
    local name = device.product_name
    local class = device.device_hardware_class
end
```

## Updating Type Definitions

These type definitions are generated from the game's API. If the game API changes:

1. The definitions may need to be regenerated
2. Check for updates in the main repository
3. Report any missing or incorrect types as issues

## Note

These files are for development assistance only and are not loaded by the game. They provide IDE support for a better development experience.
