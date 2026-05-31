# Mod Configuration System

## Overview

Mods use a simple, embedded configuration system where all settings are stored directly in the `entry.lua` file within marked sections. This eliminates the need for separate configuration files and allows the Mod Manager to parse and update settings directly.

## Architecture

### Single-File Configuration

Each mod's configuration is embedded in its `entry.lua` file:

```lua
-- ===== MOD CONFIGURATION START =====
-- This section is parsed and modified by ModManager
-- Do not remove the configuration markers

local config = {
    enable_feature = true,
    multiplier = 2.0,
    mode = "automatic",
    debug_logging = false
}

-- ===== MOD CONFIGURATION END =====
```

### Mod Structure

Each configurable mod contains:

- `entry.lua` - Main mod logic **with embedded config section**
- `metadata.yaml` - Mod metadata including parameter definitions
- `README.md` - User documentation
- `ui-config.ps1` - (Optional) Custom UI configuration for complex parameter sets

### Accessing Configuration

Configuration values are accessed directly from the `config` table in your mod:

```lua
function on_engine_load()
    if config.enable_feature then
        print("Feature enabled with multiplier: " .. config.multiplier)
    end
end
```

## Mod Manager

The PowerShell `ModManagerGUI.ps1` script provides a UI to:

- View all installed mods
- Configure mod parameters by modifying `entry.lua` directly
- Reset mods to default configurations
- Support both simple and complex parameter UIs

### Usage

# GUI version
.\ModManagerGUI.ps1
```

The manager reads and writes the configuration section in each mod's `entry.lua` file located in `mods/<mod-name>/entry.lua`.

## Parameter Definition

Parameters are defined in `metadata.yaml` using the schema from [mod-metadata-schema.yaml](mod-metadata-schema.yaml):

```yaml
Parameters:
  - Name: enable_feature
    Label: Enable Feature
    Type: boolean
    Default: true
    Description: Whether to enable this feature

  - Name: multiplier
    Label: Multiplier Value
    Type: number
    Default: 2.0
    Min: 0.1
    Max: 10.0
    Step: 0.1
    Description: Scaling multiplier for the feature

  - Name: mode
    Label: Operation Mode
    Type: select
    Default: automatic
    Options: ["automatic", "manual", "disabled"]
    Description: How the feature operates
```

### Parameter Types

- **boolean**: true/false toggle
- **number**: Floating-point number (can include Min, Max, Step)
- **integer**: Whole number (can include Min, Max)
- **string**: Text input
- **select**: Dropdown with predefined Options

## Advanced Configuration with ui-config.ps1

For mods with complex, conditional parameter sets, create a `ui-config.ps1` file:

```powershell
param([hashtable]$CurrentConfig = @{})

$parameters = @()

# Always visible parameter
$parameters += @{
    Name        = "enable_feature"
    Label       = "Enable Feature"
    Type        = "boolean"
    Default     = $true
    Description = "Main feature toggle"
}

# Conditional parameter (only show if feature enabled)
if ($CurrentConfig.enable_feature) {
    $parameters += @{
        Name        = "multiplier"
        Label       = "Multiplier"
        Type        = "number"
        Default     = 2.0
        Min         = 0.1
        Max         = 10.0
        Description = "Feature strength multiplier"
    }
}

return $parameters
```

This allows parameters to appear/disappear based on other settings.

## Adding Configuration to a New Mod

1. **Add config section to entry.lua**:
   
   ```lua
   -- ===== MOD CONFIGURATION START =====
   -- This section is parsed and modified by ModManager
   -- Do not remove the configuration markers
   
   local config = {
       my_parameter = true,
       my_value = 1.0
   }
   
   -- ===== MOD CONFIGURATION END =====
   ```

2. **Define parameters in metadata.yaml**:
   
   ```yaml
   Parameters:
     - Name: my_parameter
       Label: My Parameter
       Type: boolean
       Default: true
       Description: What this parameter does
   ```

3. **Use the config in your mod**:
   
   ```lua
   function on_engine_load()
       if config.my_parameter then
           -- Use the setting
       end
   end
   ```

4. **(Optional) Create ui-config.ps1** for complex parameter sets

## Benefits

- **Simplicity**: Single file contains both code and configuration
- **No Dependencies**: No separate config files to manage
- **Direct Editing**: ModManager parses and updates entry.lua directly
- **Type Safety**: Lua-native types (boolean, number, string)
- **Flexibility**: Support both simple (metadata.yaml) and complex (ui-config.ps1) UIs
- **Version Control Friendly**: Configuration defaults are in the same file as the code

# 

## Best Practices

1. **Use descriptive parameter names**: `enable_bandwidth` not `eb`
2. **Provide sensible defaults**: Mod should work out-of-box
3. **Add comments**: Explain complex parameters
4. **Keep config section at the top**: After mod ID, before main logic
5. **Don't remove markers**: ModManager needs them to parse correctly
6. **Test your defaults**: Ensure config works without manual changes
