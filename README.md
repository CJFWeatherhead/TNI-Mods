# Tower Networking Inc. Modding Kit

This repository is a modding kit for creating mods for [Tower Networking Inc](https://store.steampowered.com/app/2939600/Tower_Networking_Inc/). Modding support is implemented using [Godot Sandbox](https://github.com/libriscv/godot-sandbox) with [libriscv](https://libriscv.no/).

## Language Support

Mods can be created in **C/C++** or **Lua** (via the LuaJIT support mod):

- **Lua mods** (recommended): Easier to develop, naturally source-available, and support hot-reloading
- **C/C++ mods**: Provide full control and performance for complex modifications

> **Note**: Modding for Tower Networking Inc is in active development. Feedback and suggestions are welcome to improve the modding experience!

## Using Lua Mods

To use Lua-based mods, you must first install the `luajit` support mod:

1. Download the latest LuaJIT support mod from the [GitHub releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)
2. Place the `luajit.elf` file directly in your game's `mods/` directory (not in a subdirectory)
3. The game will automatically load the LuaJIT support mod before all other mods

> **Beta Branch Users**: If you're using the `beta` branch of the game on Steam, download the release tagged with `continuous-gnu-beta` instead.

## Beta Branch

This repository includes a `beta` branch that corresponds to the game's `beta` branch on Steam.

- Changes to the modding kit are tested on the `beta` branch first
- Use the `beta` branch if you're developing mods for the beta version of the game

## Example Mods

Learn by example! The following examples demonstrate different modding approaches:

### 2x Bandwidth Switches (Lua)

**Location**: [`/lua/2x-bandwidth-switches/`](/lua/2x-bandwidth-switches/)

A simple Lua mod that doubles the bandwidth capacity of every switch when spawned. The store continues to display the original value, so players get a nice surprise!

**Key concepts demonstrated**:
- Using the `on_device_spawned` callback
- Accessing device properties
- Modifying game logic

### Template Mod (C/C++)

**Location**: [`/programs/tni-mod-template/`](/programs/tni-mod-template/)

A comprehensive C/C++ template demonstrating common modding scenarios including:
- Registering callbacks for game events
- Creating UI dialogs
- Handling player input
- Accessing game world state

### LuaJIT Support Mod (C/C++)

**Location**: [`/programs/luajit/`](/programs/luajit/)

The official LuaJIT support mod implementation. This is a more complex example showing advanced integration with the game engine.

---

## Installing Mods

Mods are loaded from the game's user directory in alphabetical order:

- **Windows**: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
- **Linux**: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`

### Installing C/C++ Mods

1. Build the mod (see [Building C/C++ Mods](#building-cc-mods))
2. Copy the entire mod directory from `.zig/<mod-name>/` to the game's `mods/` directory
3. Ensure the file structure is: `mods/<mod-name>/entry.elf`

**Example**: To install `tni-mod-template`:
```
mods/
└── tni-mod-template/
    └── entry.elf
```

### Installing Lua Mods

1. Ensure the LuaJIT support mod is installed (see [Using Lua Mods](#using-lua-mods))
2. Place your `.lua` mod file directly in the `mods/` directory

**Example**: To install `2x-bandwidth-switches.lua`:
```
mods/
├── luajit.elf          # Required for Lua support
└── 2x-bandwidth-switches.lua
```

> **Note**: The game engine loads `luajit.elf` first automatically, so naming is not critical.

---

## Building C/C++ Mods

For comprehensive documentation on building mods, see the [libriscv documentation](https://libriscv.no/docs/host_langs/godot_integration/godot_docs/cmake#cmake-setup).

### Initial Setup

Clone the repository and initialize submodules:

```sh
git clone https://github.com/CJFWeatherhead/TNI-Mods.git --branch main
cd TNI-Mods
git submodule update --init --recursive
```

### Windows Build Requirements

Install the following tools:

1. [Git](https://git-scm.com/install/windows) - Version control system
2. [CMake](https://cmake.org/download/) - Build system generator
3. [Ninja](https://ninja-build.org/) - Fast build system
4. [Zig](https://ziglang.org/download/) - RISC-V cross-compilation toolchain

**Build command**:
```cmd
zig.cmd
```

Built mods will be in `.zig/<mod-name>/entry.elf`

### Linux Build Requirements (including WSL2)

Install dependencies:

```sh
# Debian/Ubuntu
sudo apt install git cmake ninja-build g++-riscv64-linux-gnu-14
```

**Build command**:
```sh
./build.sh
```

Built mods will be in `.build/<mod-name>/entry.elf`

### Build Output

After building, mod binaries (`.elf` files) are placed in:
- **Windows/Zig**: `.zig/<mod-name>/`
- **Linux/GNU**: `.build/<mod-name>/`

See [Installing C/C++ Mods](#installing-cc-mods) for installation instructions.

---

## Resources

- **Game**: [Tower Networking Inc on Steam](https://store.steampowered.com/app/2939600/Tower_Networking_Inc/)
- **Godot Sandbox**: [GitHub Repository](https://github.com/libriscv/godot-sandbox)
- **libriscv Documentation**: [https://libriscv.no/](https://libriscv.no/)
- **C++ API Reference**: [Godot Sandbox C++ API](https://libriscv.no/docs/host_langs/godot_integration/godot_docs/cppapi)
- **C++ Examples**: [Godot Sandbox C++ Examples](https://libriscv.no/docs/host_langs/godot_integration/godot_docs/cppexamples/)

## Contributing

Contributions are welcome! When contributing:

1. Fork this repository
2. Create a feature branch
3. Follow the existing code style
4. Test your changes thoroughly
5. Submit a pull request with a clear description

For bug reports or feature requests, please open an issue on GitHub.

## License

This project is licensed under the BSD 3-Clause License. See [LICENSE](LICENSE) for details.
