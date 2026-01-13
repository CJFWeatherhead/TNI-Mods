## Continuous Release - Zig Toolchain

This is an automatically generated continuous release built with the Zig cross-compilation toolchain.

### ⚠️ Known Issues

Zig builds have known issues with error handling, particularly for the LuaJIT support mod. Lua errors may cause a PANIC instead of being handled gracefully.

### Recommendation

**Use GNU builds instead** - Download the `continuous-gnu-*` releases for better stability and error handling.

### When to Use Zig Builds

- Testing cross-platform compatibility
- Developing on systems without GNU RISC-V toolchain
- Experimental features that require Zig-specific capabilities

### Installation

If you still want to use Zig builds:

1. Download the desired mod `.zip` file
2. Place `luajity.elf` in your game's `mods/` directory as `mods/luajit.elf`
3. Follow the [installation guide](https://github.com/CJFWeatherhead/TNI-Mods#installing-mods)

### Need Help?

See the [main README](https://github.com/CJFWeatherhead/TNI-Mods) or open an issue on GitHub.

