# Tower Networking Inc. Modding Kit

This repository is a modding kit that can be used to create mods for the game [Tower Networking Inc](https://store.steampowered.com/app/2939600/Tower_Networking_Inc/). Modding support for the game is implemented with [Godot Sandbox](https://github.com/libriscv/godot-sandbox) using [libriscv](https://libriscv.no/).

Mods are created in C/C++, however this repository also contains the official LuaJIT support mod. Lua mods are preferred as they are easier to develop and are naturally source-available.

Note that modding for the game is still in early design/implementation stage.

## Mod Manager v3.0

This repository includes a modern WPF-based **[Mod Manager](ModManager-README.md)** that can download mods directly from GitHub releases and manage local installations.

### Features

- 🌐 **GitHub Integration**: Browse, download, and update mods from releases
- 📊 **Progress Bars**: Visual feedback during mod downloads
- 🎨 **Visual Distinctions**: Color-coded mods (Downloaded/Manual/Available)
- ⚙️ **Parameter Configuration**: Configure mod settings through the GUI
- 🚀 **One-Click Launch**: Start the game directly from the manager

### Quick Start

1. Double-click `ModManager.bat` to launch
2. Available mods from GitHub releases appear in gray
3. Click a mod and press **Download** to install
4. Installed mods show as blue (downloaded) or purple (manual)
5. Configure parameters and click **Save Changes**

### Mod Sources

| Source | Color | Behavior |
|--------|-------|----------|
| **Downloaded** | Blue | Installed from GitHub releases. Deleted when removed. |
| **Manual** | Purple | Manually installed. Moved to disabled folder when disabled. |
| **Available** | Gray | Not installed. Can be downloaded from GitHub. |

For full documentation, see:

- [ModManager-README.md](ModManager-README.md) - Complete mod manager guide
- [CONFIG-SYSTEM.md](CONFIG-SYSTEM.md) - Configuration system architecture

## Using Lua based mods

If you want to use a Lua based mods, you will need to manually add the `luajit` support mod first. This may be improved in the future.

You can find the mod in the github releases, or [click here](https://github.com/CJFWeatherhead/TNI-Mods/releases/early-0) for the latest stable release. Download the luajit file and place it in your mods folder. Refer to [Loading the mod](#loading-the-mod) for further instructions.

If you are using the `beta` branch of the game, you'll likely want to use the ["Continuous (gnu) - beta"](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/continuous-gnu-beta) release instead.

## Beta branch

There is a `beta` github branch which should work with the game's `beta` branch on steam.

Changes to the modding-kit go through the beta branch first.

## Automated Mod Releases

Each mod in the `/lua` directory has its own automated release workflow. When you push changes to a mod:

1. **Version is automatically incremented** (using semantic versioning)
2. **Last Updated date is set** to the current date
3. **Mod is packaged** into a versioned zip file
4. **GitHub release is created** with download links
5. **Documentation is updated** with the latest release links

For more details, see [.github/MOD-RELEASE-SYSTEM.md](.github/MOD-RELEASE-SYSTEM.md).

### Manual Releases

You can also trigger releases manually:
1. Go to the **Actions** tab
2. Select your mod's workflow (e.g., "Release money-cheat")
3. Click **Run workflow** and choose version bump type (major/minor/patch)

---

## Creating Lua Mods

### Mod Structure Standards

All Lua mods follow this structure:

```
lua/<mod-name>/
├── entry.lua          # Main mod file (REQUIRED)
├── metadata.yaml      # Mod metadata (REQUIRED)
├── README.md          # Mod documentation (REQUIRED)
└── ui-config.ps1      # Custom UI config (OPTIONAL, for complex configs)
```

#### Required Files

**entry.lua** - Main mod implementation

- Must be a single, self-contained Lua file

- Configuration options must be in a marked section:
  
  ```lua
  -- ===== MOD CONFIGURATION START =====
  -- This section is parsed and modified by ModManager
  -- Do not remove the configuration markers
  
  local config = {
      param1 = true,
      param2 = 2.0,
      param3 = "value"
  }
  
  -- ===== MOD CONFIGURATION END =====
  ```

**metadata.yaml** - Mod metadata

- Follow the schema in [mod-metadata-schema.yaml](mod-metadata-schema.yaml)
- Must include: Name, Description, Author, **Version**, Creation Date, Last Updated, Development Status, Game Version Supported, ID
- **Version** field uses semantic versioning (e.g., "1.0.0") and is auto-incremented by release workflows
- Parameters section defines configurable options (used by basic ModManager UI)

**README.md** - User documentation

- Describe what the mod does
- List features
- Explain installation and usage
- Include compatibility information
- Document any special configuration

#### Optional Files

**ui-config.ps1** - Custom configuration UI

- Only needed for complex mods with conditional parameters
- Defines UI elements in PowerShell (not in metadata.yaml)
- See [device-tweaker/ui-config.ps1](lua/device-tweaker/ui-config.ps1) for examples


### Configuration Best Practices

1. **Keep it simple**: Most mods should use the Parameters section in metadata.yaml
2. **Use marked sections**: Always use the `MOD CONFIGURATION START/END` markers in entry.lua
3. **Type-safe defaults**: Provide sensible defaults for all parameters
4. **Document parameters**: Add clear descriptions in metadata.yaml
5. **Use ui-config.ps1 only when needed**: For conditional/dynamic parameter visibility

---

## Loading the mod

Mods in the game will be loaded from the user's game directory in alphabetical order.

- Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc`

- Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc`

On the user's game directory, you'll observe directories like `saves/` and `logs/`. Place your mod in the `mods/` directory.

For example, to install the `tni-mod-template` mod, place `.zig/tni-mod-template` to `mods/` such that `mods/tni-mod-template/entry.elf` exists.

### Lua mods

If you'd like to use Lua instead, you can download the [pre-built luajit.elf mod](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/early-0/luajit.elf) from the releases section and place it as `mods/luajit.elf` (directly in the `mods/`) directory. This enables loading of `.lua` mods.

The engine will always first try to load the `luajit.elf` before all mods, so you do not need to worry about the naming.

---

## Building C/C++ mods

Check out the [librisc-v docs](https://libriscv.no/docs/host_langs/godot_integration/godot_docs/cmake#cmake-setup) for more information.

To clone and initialize the repository locally;

```sh
# Ensure you have `git` installed.
git clone https://github.com/CJFWeatherhead/TNI-Mods.git --branch main
git submodule update --init --recursive
```

### Windows

Make sure the following is installed:

1. [git](https://git-scm.com/install/windows) (version control system, used to clone the repo locally)
2. [CMake](https://cmake.org/download/) (generator for build systems)
3. [Ninja](https://ninja-build.org/) (build system)
4. [ZIG](https://ziglang.org/download/) (RISC-V cross-compilation)

Then in the root of this project, run the command:

```
zig.cmd
```

The built output (a .elf file) will be in the `.zig/<name-of-your-mod>/entry.elf` directory.

### Linux (and WSL2)

Make sure the following is installed:

1. `git` (version control system, used to clone the repo locally)
2. `CMake` (generator for build systems)
3. `Ninja` (build system)
4. `g++-riscv64-linux-gnu-14` (GNU RISC-V compiler)

```sh
# For Debian based systems like Ubuntu;
sudo apt install git cmake ninja-build g++-riscv64-linux-gnu-14
```

Then in the root of this project, run the command:

```sh
./build.sh
```
