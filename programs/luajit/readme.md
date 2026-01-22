# LuaJIT Support Mod

This mod adds support for Lua-based mods in Tower Networking Inc using LuaJIT.

## Overview

The LuaJIT support mod enables loading and running Lua scripts as mods. It provides a bridge between the Lua scripting environment and the game's C++ modding API.

## Building from Source

> **Note**: Pre-built binaries are available in the [GitHub releases](https://github.com/CJFWeatherhead/TNI-Mods/releases). You only need to build from source if you're modifying the LuaJIT support mod itself.

### Build Requirements

- **Platform**: Must be built on Linux (or WSL on Windows)
- **Build System**: GNU toolchain (GCC)
- **Compiler**: `riscv64-linux-gnu-gcc-14`
- **Tools**: `make`

### Important Build Notes

**Use GCC, not Zig**: This mod must be built with GCC on Linux using `./build.sh`. Building with Zig causes Lua errors to trigger a Lua PANIC that cannot be handled properly.

**LuaJIT RISC-V Support**: LuaJIT doesn't officially support RISC-V64 yet. This mod uses a fork with RISC-V64 support from the [plctlab/LuaJIT repository](https://github.com/plctlab/LuaJIT/tree/v2.1-riscv64-pr).

### Building `libluajit.a` (GNU Toolchain)

```sh
# 1. Clean previous builds (if any)
rm -rf ./LuaJIT/

# 2. Clone the RISC-V fork of LuaJIT
git clone https://github.com/plctlab/LuaJIT.git -b v2.1-riscv64-pr

# 3. Build the library
cd ./LuaJIT/src
make CROSS=riscv64-linux-gnu- CC=gcc-14

# 4. The resulting libluajit.a can replace the existing version
```

### Building `zig-libluajit.a` (Zig Toolchain)

> **Warning**: This build method may have limitations with error handling. Prefer the GNU build for production use.

```sh
# 1. Clean previous builds (if any)
rm -rf ./LuaJIT/

# 2. Clone the RISC-V fork of LuaJIT
git clone https://github.com/plctlab/LuaJIT.git -b v2.1-riscv64-pr

# 3. Build with Zig
cd ./LuaJIT/src
make CC="zig cc" TARGET_FLAGS="-target riscv64-linux-musl"

# Note: This will error on libluajit.so (which is not needed)
# As long as libluajit.a is created, you can ignore the error

# 4. Rename and replace the library
mv libluajit.a zig-libluajit.a
```

## Usage

See the main [README](../../README.md) for instructions on installing and using Lua mods.

## Example Lua Mods

Check out the [2x Bandwidth Switches](../../lua/2x-bandwidth-switches/) example to see how to create Lua mods.
