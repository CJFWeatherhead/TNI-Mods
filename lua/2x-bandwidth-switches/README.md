# 2x Bandwidth Switches - Example Lua Mod

A simple example mod that demonstrates how to create Lua mods for Tower Networking Inc.

## What This Mod Does

This mod doubles the bandwidth capacity of every network switch when it's spawned in the game. The store continues to display the original bandwidth value, so players get a pleasant surprise when they use the device!

## Features Demonstrated

- **Callback Functions**: Shows how to use `on_engine_load`, `on_mod_reload`, and `on_device_spawned` callbacks
- **Device Inspection**: Demonstrates how to check device types using `device_hardware_class`
- **Property Modification**: Shows how to access and modify device properties
- **Logging**: Uses `print()` to output debugging information

## Installation

1. Install the LuaJIT support mod (see main [README](../../README.md#using-lua-mods))
2. Copy `entry.lua` to your game's `mods/` directory
3. Rename it if desired (e.g., `2x-bandwidth-switches.lua`)
4. Launch the game!

## How It Works

The mod uses the `on_device_spawned` callback to intercept every device creation:

```lua
function on_device_spawned(device)
    -- Check if the device is a switch (hardware class 1)
    if device.device_hardware_class == 1 then
        -- Double the bandwidth
        local current_bw = device.logic_controller.installed_nbw
        device.logic_controller.installed_nbw = current_bw * 2
    end
end
```

## Customization Ideas

Want to modify this mod? Here are some ideas:

- Change the multiplier (e.g., 3x or 5x instead of 2x)
- Apply the effect to different device types
- Add a random multiplier for variety
- Create a configuration file for different multiplier values

## Device Hardware Classes

Common device hardware classes you might want to target:

- `1` - Network switches
- Other classes depend on the game's implementation

Inspect devices in the `on_device_spawned` callback to discover more:
```lua
print("Device: " .. device.product_name .. ", Class: " .. device.device_hardware_class)
```

## Troubleshooting

**Mod not loading?**
- Ensure `luajit.elf` is in your `mods/` directory
- Check the game logs for error messages
- Verify the file is named correctly (must have `.lua` extension)

**Changes not applying?**
- Press F11 to reload the mod without restarting the game
- Check that you're modifying the correct property

## Learn More

- [Main Repository](https://github.com/CJFWeatherhead/TNI-Mods)
- [C++ Template Example](../../programs/tni-mod-template/)
- [LuaJIT Support Mod](../../programs/luajit/)
