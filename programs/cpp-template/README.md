# TNI Mod Template - C++ Example

A comprehensive C++ template demonstrating common modding scenarios for Tower Networking Inc.

## What This Template Includes

This template provides working examples of:

- **Callback registration**: All available mod lifecycle callbacks
- **Game state access**: Reading scenario information and game world state
- **UI creation**: Creating and displaying dialog windows
- **Input handling**: Responding to keyboard input
- **Device interaction**: Hooking into device spawn events
- **Persistent state**: Maintaining variables across callbacks

## Features Demonstrated

### Lifecycle Callbacks

```cpp
on_mod_load()         // Called immediately after mod loads
on_engine_load()      // Called when all mods are loaded
on_game_state_ready() // Called when game is fully initialized
on_game_host_eod()    // Called at end of day (host only)
on_game_tick()        // Called every frame
on_player_input()     // Called on any player input
on_device_spawned()   // Called when a device is created
```

### UI Creation Example

The template shows how to create and display a dialog:

```cpp
AcceptDialog diag = sys_node_create(...);
diag.title() = "My Dialog";
diag.dialog_text() = "Hello from mod!";
// Connect signals and display
```

### Input Handling Example

Demonstrates keyboard input detection:

```cpp
if (event.get_class() == "InputEventKey") {
    InputEventKey* key = reinterpret_cast<InputEventKey*>(&event);
    if (key->is_pressed() && key->get_keycode() == 32) {
        // Handle spacebar press
    }
}
```

## Building

### Prerequisites

See the main [README](../../README.md#building-cc-mods) for complete build setup instructions.

**Quick reference**:
- **Windows**: Install Zig, CMake, Ninja → Run `zig.cmd`
- **Linux**: Install GCC RISC-V toolchain, CMake, Ninja → Run `./build.sh`

### Build Commands

**Windows**:
```cmd
cd /path/to/TNI-Mods
zig.cmd
```

**Linux/WSL**:
```sh
cd /path/to/TNI-Mods
./build.sh
```

### Build Output

- **Windows**: `.zig/tni-mod-template/entry.elf`
- **Linux**: `.build/tni-mod-template/entry.elf`

## Installation

1. Build the mod using the commands above
2. Copy the entire `tni-mod-template` directory to your game's `mods/` folder
3. Ensure the structure is: `mods/tni-mod-template/entry.elf`
4. Launch the game

**Game mod directories**:
- Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
- Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`

## Customization

Use this template as a starting point for your own mods:

1. **Copy the template**: Duplicate this directory with a new name
2. **Update CMakeLists.txt**: Change the project name
3. **Modify entry.cpp**: Implement your mod logic
4. **Build and test**: Iterate on your changes

### Tips for Development

- **Remove unused callbacks**: Only register the callbacks you need
- **Use `printf` for debugging**: Output appears in game logs
- **Check optionals**: Game API functions often return `std::optional`
- **Hot reload**: Requires game restart for C++ mods (unlike Lua)

## Common Patterns

### Accessing Game World

```cpp
std::optional<GameWorld> gw = api_v1.get_game_world();
if (gw) {
    String scenario = gw.value().scenario_name();
    // Use game world data
}
```

### Working with Devices

```cpp
static Variant on_device_spawned(DeviceUnit device) {
    fetch_mod_api();
    String name = device.product_name();
    int hw_class = device.device_hardware_class;
    // Modify device properties
    return Nil;
}
```

### Creating Callables

```cpp
Callable fn = Callable::Create<Variant(MyType)>([](MyType obj) -> Variant {
    // Your callback code
    return Nil;
}, Variant(obj));
```

## API Documentation

- **C++ API Reference**: [libriscv Godot C++ API](https://libriscv.no/docs/host_langs/godot_integration/godot_docs/cppapi)
- **C++ Examples**: [libriscv C++ Examples](https://libriscv.no/docs/host_langs/godot_integration/godot_docs/cppexamples/)
- **Main Repository**: [TNI-Mods on GitHub](https://github.com/CJFWeatherhead/TNI-Mods)

## Troubleshooting

**Build fails**:
- Verify all prerequisites are installed
- Check that submodules are initialized: `git submodule update --init --recursive`
- Ensure you're using the correct toolchain (Zig on Windows, GCC on Linux)

**Mod doesn't load**:
- Check file structure: `mods/tni-mod-template/entry.elf`
- Look for error messages in game logs
- Verify the `.elf` file was built for RISC-V64 architecture

**Crashes or unexpected behavior**:
- Check for null/optional values before dereferencing
- Review callback implementations for errors
- Add debug output with `printf` to trace execution

## Next Steps

- **Study the code**: Read through `entry.cpp` with the inline comments
- **Experiment**: Modify callbacks and see what happens
- **Check other examples**: Look at the [Lua example](../../lua/2x-bandwidth-switches/)
- **Read API docs**: Explore the full API capabilities
- **Build something cool**: Share your creation with the community!

## Contributing

Found a bug or have a suggestion? See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines on contributing to this project.
