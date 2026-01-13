## Continuous Release - GNU Toolchain

This is an automatically generated continuous release built with the GNU RISC-V toolchain.

### What's Included

- **LuaJIT Support Mod** (`luajit.elf`) - Required for running Lua-based mods
- **C++ Example Mods** - Template and example implementations

### Installation

1. Download `luajit.zip` and extract it
2. Place `luajit/entry.elf` in your game's `mods/` directory as `mods/luajit/entry.elf`
3. Download and install any additional mods you want to use

For detailed installation instructions, see the [main README](https://github.com/CJFWeatherhead/TNI-Mods#installing-mods).

### Recommended Build

**GNU builds are recommended** over Zig builds due to better error handling, especially for the LuaJIT support mod.

### Game Compatibility

- Match your release to your game branch (e.g., use `continuous-gnu-beta` for the beta branch)
- Main branch releases work with the stable game release

