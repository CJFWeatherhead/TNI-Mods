---
title: "Device Tweaker"
date: 2026-01-27
draft: false
mod_id: "device-tweaker"
author: "CJFWeatherhead"
version: "0.1.3"
status: "Active Development"
game_version: "beta"
---

# Device Tweaker

A comprehensive mod for tweaking device properties in Tower Networking Inc.

## Features
- **Bandwidth Multiplier**: Adjust network bandwidth capacity of devices
- **Warranty Modifications**: Set fixed or random warranty multipliers
- **Cost Adjustments**: Modify device purchase costs
- **Hardware Multipliers**: Scale CPU power, RAM, and storage
- **Network Addressing**: Auto-assign addresses based on floor and device type
- **DHCP Configuration**: Set DHCP mode (disabled, boot, or periodic)
- **Device Class Filtering**: Selectively apply modifications to specific device types

## Device Classes (20 types)
- Default (0) - def
- Network Switch (1) - swt
- Network Router (2) - rtr
- Network Tap (3) - tap
- Network Firewall (4) - fwr
- Media Line Simplex (5) - mls
- Media Line Duplex (6) - mld
- Compute Server (7) - srv
- Display Monitor (8) - mon
- Debugger (9) - dbg
- Load Tester (10) - ldt
- Power Expansion (11) - pwr
- Decentro Rigs (12) - dcr
- Surge Protector (13) - spr
- UPS (14) - ups
- Inert (15) - ine
- CCTV (16) - ccv
- Phone (17) - phn
- Printer (18) - prt
- Network Load Balancer (19) - nlb

## Configuration Tips
- Enable specific modifications using the enable toggles
- Set multipliers > 1.0 to increase values, < 1.0 to decrease
- Use random warranty mode for varied warranty periods per device
- Disable device classes you don't want to modify
- Network addressing format: @f{floor}/{abbrev}{increment}


## Mod Information

- **Author**: CJFWeatherhead
- **Version**: 0.1.3
- **Development Status**: Active Development
- **Game Version**: beta
- **Last Updated**: 2026-01-27
- **Website**: [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/device-tweaker](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/lua/device-tweaker)

## Download

### Latest Release: v0.1.3

**[Download device-tweaker-0.1.3.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/device-tweaker-v0.1.3/device-tweaker-0.1.3.zip)**

[View all releases on GitHub →](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/device-tweaker-v0.1.3)

### Installation Options

#### Option 1: Using Mod Manager (Recommended)

1. Download the [TNI Mod Manager](/mods/tools/modmanager/)
2. Run the Mod Manager application
3. Find **Device Tweaker** in the Available mods list
4. Click **Download** to automatically install
5. Configure parameters using the graphical interface

#### Option 2: Manual Installation

1. Download the zip file above
2. Extract the `device-tweaker/` folder to your game's mods directory:
   - Windows: `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed in the mods directory
4. (Optional) Use [Mod Manager](/mods/tools/modmanager/) to configure parameters

## Configuration Parameters

This mod can be configured using the [Mod Manager](/mods/tools/modmanager/). Available parameters:

### Enable for Default Devices

- **Parameter Name**: `enable_default`
- **Type**: boolean
- **Default**: `True`

Apply modifications to default devices (class 0)

### Enable for Network Switches

- **Parameter Name**: `enable_network_switch`
- **Type**: boolean
- **Default**: `True`

Apply modifications to network switch devices (class 1)

### Enable for Network Routers

- **Parameter Name**: `enable_network_router`
- **Type**: boolean
- **Default**: `True`

Apply modifications to network router devices (class 2)

### Enable for Network Taps

- **Parameter Name**: `enable_network_tap`
- **Type**: boolean
- **Default**: `True`

Apply modifications to network tap devices (class 3)

### Enable for Network Firewalls

- **Parameter Name**: `enable_network_firewall`
- **Type**: boolean
- **Default**: `True`

Apply modifications to network firewall devices (class 4)

### Enable for Media Line Simplex

- **Parameter Name**: `enable_media_line_simplex`
- **Type**: boolean
- **Default**: `True`

Apply modifications to media line simplex devices (class 5)

### Enable for Media Line Duplex

- **Parameter Name**: `enable_media_line_duplex`
- **Type**: boolean
- **Default**: `True`

Apply modifications to media line duplex devices (class 6)

### Enable for Compute Servers

- **Parameter Name**: `enable_compute_server`
- **Type**: boolean
- **Default**: `True`

Apply modifications to compute server devices (class 7)

### Enable for Display Monitors

- **Parameter Name**: `enable_display_monitor`
- **Type**: boolean
- **Default**: `True`

Apply modifications to display monitor devices (class 8)

### Enable for Debuggers

- **Parameter Name**: `enable_debugger`
- **Type**: boolean
- **Default**: `True`

Apply modifications to debugger devices (class 9)

### Enable for Load Testers

- **Parameter Name**: `enable_load_tester`
- **Type**: boolean
- **Default**: `True`

Apply modifications to load tester devices (class 10)

### Enable for Power Expansion

- **Parameter Name**: `enable_power_expansion`
- **Type**: boolean
- **Default**: `True`

Apply modifications to power expansion devices (class 11)

### Enable for Decentro Rigs

- **Parameter Name**: `enable_decentro_rigs`
- **Type**: boolean
- **Default**: `True`

Apply modifications to decentro rig devices (class 12)

### Enable for Surge Protectors

- **Parameter Name**: `enable_surge_protector`
- **Type**: boolean
- **Default**: `True`

Apply modifications to surge protector devices (class 13)

### Enable for UPS Devices

- **Parameter Name**: `enable_ups`
- **Type**: boolean
- **Default**: `True`

Apply modifications to UPS devices (class 14)

### Enable for Inert Devices

- **Parameter Name**: `enable_inert`
- **Type**: boolean
- **Default**: `True`

Apply modifications to inert devices (class 15)

### Enable for CCTV

- **Parameter Name**: `enable_cctv`
- **Type**: boolean
- **Default**: `True`

Apply modifications to CCTV devices (class 16)

### Enable for Phones

- **Parameter Name**: `enable_phone`
- **Type**: boolean
- **Default**: `True`

Apply modifications to phone devices (class 17)

### Enable for Printers

- **Parameter Name**: `enable_printer`
- **Type**: boolean
- **Default**: `True`

Apply modifications to printer devices (class 18)

### Enable for Network Load Balancers

- **Parameter Name**: `enable_network_load_balancer`
- **Type**: boolean
- **Default**: `True`

Apply modifications to network load balancer devices (class 19)

### Enable Bandwidth Modification

- **Parameter Name**: `enable_bandwidth`
- **Type**: boolean
- **Default**: `False`

Enable bandwidth capacity modifications

### Bandwidth Multiplier

- **Parameter Name**: `bandwidth_multiplier`
- **Type**: number
- **Default**: `2.0`
- **Min**: 0.1
- **Max**: 100.0

Multiplier for device network bandwidth (e.g., 2.0 = double bandwidth)

### Enable Warranty Modification

- **Parameter Name**: `enable_warranty`
- **Type**: boolean
- **Default**: `False`

Enable warranty period modifications

### Warranty Mode

- **Parameter Name**: `warranty_mode`
- **Type**: select
- **Default**: `fixed`
- **Options**: `fixed`, `random`

Use a fixed multiplier or random range for warranties

### Fixed Warranty Multiplier

- **Parameter Name**: `warranty_multiplier_fixed`
- **Type**: number
- **Default**: `1.0`
- **Min**: 0.1
- **Max**: 100.0

Fixed multiplier for warranties (used when mode is 'fixed')

### Min Random Warranty Multiplier

- **Parameter Name**: `warranty_multiplier_min`
- **Type**: number
- **Default**: `2.0`
- **Min**: 0.1
- **Max**: 100.0

Minimum multiplier for random warranties (used when mode is 'random')

### Max Random Warranty Multiplier

- **Parameter Name**: `warranty_multiplier_max`
- **Type**: number
- **Default**: `25.0`
- **Min**: 0.1
- **Max**: 100.0

Maximum multiplier for random warranties (used when mode is 'random')

### Apply to Warranty Cycles

- **Parameter Name**: `warranty_apply_cycles`
- **Type**: boolean
- **Default**: `True`

Whether to also multiply warranty cycles (in addition to days)

### Apply to Remaining Warranty

- **Parameter Name**: `warranty_apply_remaining`
- **Type**: boolean
- **Default**: `True`

Whether to also apply multiplier to remaining warranty period

### Enable Cost Modification

- **Parameter Name**: `enable_cost`
- **Type**: boolean
- **Default**: `False`

Enable device cost modifications

### Cost Multiplier

- **Parameter Name**: `cost_multiplier`
- **Type**: number
- **Default**: `1.0`
- **Min**: 0.01
- **Max**: 100.0

Multiplier for device purchase costs (e.g., 0.5 = half price, 2.0 = double price)

### Enable CPU Modification

- **Parameter Name**: `enable_cpu`
- **Type**: boolean
- **Default**: `False`

Enable CPU power modifications

### CPU Power Multiplier

- **Parameter Name**: `cpu_multiplier`
- **Type**: number
- **Default**: `1.0`
- **Min**: 0.1
- **Max**: 100.0

Multiplier for device CPU power

### Enable Memory Modification

- **Parameter Name**: `enable_memory`
- **Type**: boolean
- **Default**: `False`

Enable RAM modifications

### Memory (RAM) Multiplier

- **Parameter Name**: `memory_multiplier`
- **Type**: number
- **Default**: `1.0`
- **Min**: 0.1
- **Max**: 100.0

Multiplier for device installed RAM

### Enable Storage Modification

- **Parameter Name**: `enable_storage`
- **Type**: boolean
- **Default**: `False`

Enable storage capacity modifications

### Storage Multiplier

- **Parameter Name**: `storage_multiplier`
- **Type**: number
- **Default**: `1.0`
- **Min**: 0.1
- **Max**: 100.0

Multiplier for device storage capacity

### Enable Auto Network Addressing

- **Parameter Name**: `enable_netaddr`
- **Type**: boolean
- **Default**: `False`

Automatically assign network addresses based on floor and device class.
Format: @f{floor}/{class}{increment}
Examples: @f4/srv1 (compute server on floor 4), @f2/swt1 (switch on floor 2), @f18/nlb2 (load balancer on floor 18)

Device class abbreviations (3 letters):
def=default, swt=switch, rtr=router, tap=tap, fwr=firewall, mls=media_simplex, mld=media_duplex,
srv=server, mon=monitor, dbg=debugger, ldt=load_tester, pwr=power_expansion, dcr=decentro_rigs,
spr=surge_protector, ups=ups, ine=inert, ccv=cctv, phn=phone, prt=printer, nlb=load_balancer


### DHCP Mode

- **Parameter Name**: `dhcp_mode`
- **Type**: select
- **Default**: `disabled`
- **Options**: `disabled`, `boot_dhcp`, `periodic_dhcp`

Set the DHCP mode for devices - disabled, boot_dhcp (runs once at boot), or periodic_dhcp (runs periodically)

---

## Detailed Documentation

# Device Tweaker Mod

A comprehensive mod for Tower Networking Inc that allows you to customize device properties including bandwidth, warranties, costs, and hardware specifications. This is an extension of the 2x Bandwidth mod and the Random Warranties mod.

## Features

### 🔧 Multiple Modification Types

- **Bandwidth**: Adjust network bandwidth capacity for switches, routers, and other network devices
- **Warranties**: Set fixed or random warranty multipliers for device reliability
- **Cost**: Modify device purchase prices (make them cheaper or more expensive)
- **Hardware**: Scale CPU power, RAM, and storage capacity independently (Not Supported by the games API currently)
- **Network Addressing**: Automatically assign descriptive network addresses based on floor and device type (Not supported by the games API)

### 🎯 Device Class Filtering

Selectively apply modifications to specific device types (all 20 classes from game API):

- **Default** (0) - def
- **Network Switch** (1) - swt
- **Network Router** (2) - rtr
- **Network Tap** (3) - tap
- **Network Firewall** (4) - fwr
- **Media Line Simplex** (5) - mls
- **Media Line Duplex** (6) - mld
- **Compute Server** (7) - srv
- **Display Monitor** (8) - mon
- **Debugger** (9) - dbg
- **Load Tester** (10) - ldt
- **Power Expansion** (11) - pwr
- **Decentro Rigs** (12) - dcr
- **Surge Protector** (13) - spr
- **UPS** (14) - ups
- **Inert** (15) - ine
- **CCTV** (16) - ccv
- **Phone** (17) - phn
- **Printer** (18) - prt
- **Network Load Balancer** (19) - nlb

### ⚙️ Flexible Configuration

- Enable/disable each modification type independently
- Fine-tune multipliers from 0.1x to 100x
- Choose between fixed or random warranty multipliers
- Configure warranty to affect days, cycles, and remaining periods

## Installation

1. Place this mod folder in your `lua/` directory
2. Load the game or reload mods (default: F11)
3. Configure the mod through the Mod Loader menu

## Configuration Parameters

### Device Class Filters

| Parameter                         | Default | Description                                                     |
| --------------------------------- | ------- | --------------------------------------------------------------- |
| Enable for Default Devices        | ✓       | Apply modifications to default devices (class 0)                |
| Enable for Network Switches       | ✓       | Apply modifications to network switch devices (class 1)         |
| Enable for Network Routers        | ✓       | Apply modifications to network router devices (class 2)         |
| Enable for Network Taps           | ✓       | Apply modifications to network tap devices (class 3)            |
| Enable for Network Firewalls      | ✓       | Apply modifications to network firewall devices (class 4)       |
| Enable for Media Line Simplex     | ✓       | Apply modifications to media line simplex devices (class 5)     |
| Enable for Media Line Duplex      | ✓       | Apply modifications to media line duplex devices (class 6)      |
| Enable for Compute Servers        | ✓       | Apply modifications to compute server devices (class 7)         |
| Enable for Display Monitors       | ✓       | Apply modifications to display monitor devices (class 8)        |
| Enable for Debuggers              | ✓       | Apply modifications to debugger devices (class 9)               |
| Enable for Load Testers           | ✓       | Apply modifications to load tester devices (class 10)           |
| Enable for Power Expansion        | ✓       | Apply modifications to power expansion devices (class 11)       |
| Enable for Decentro Rigs          | ✓       | Apply modifications to decentro rig devices (class 12)          |
| Enable for Surge Protectors       | ✓       | Apply modifications to surge protector devices (class 13)       |
| Enable for UPS Devices            | ✓       | Apply modifications to UPS devices (class 14)                   |
| Enable for Inert Devices          | ✓       | Apply modifications to inert devices (class 15)                 |
| Enable for CCTV                   | ✓       | Apply modifications to CCTV devices (class 16)                  |
| Enable for Phones                 | ✓       | Apply modifications to phone devices (class 17)                 |
| Enable for Printers               | ✓       | Apply modifications to printer devices (class 18)               |
| Enable for Network Load Balancers | ✓       | Apply modifications to network load balancer devices (class 19) |

### Bandwidth Settings

| Parameter                     | Default | Range     | Description                      |
| ----------------------------- | ------- | --------- | -------------------------------- |
| Enable Bandwidth Modification | ✗       | -         | Enable/disable bandwidth changes |
| Bandwidth Multiplier          | 2.0     | 0.1-100.0 | Bandwidth capacity multiplier    |

### Warranty Settings

| Parameter                    | Default | Range        | Description                        |
| ---------------------------- | ------- | ------------ | ---------------------------------- |
| Enable Warranty Modification | ✗       | -            | Enable/disable warranty changes    |
| Warranty Mode                | fixed   | fixed/random | Use fixed or random multipliers    |
| Fixed Warranty Multiplier    | 1.0     | 0.1-100.0    | Fixed warranty multiplier          |
| Min Random Multiplier        | 2.0     | 0.1-100.0    | Minimum random warranty multiplier |
| Max Random Multiplier        | 25.0    | 0.1-100.0    | Maximum random warranty multiplier |
| Apply to Warranty Cycles     | ✓       | -            | Also multiply warranty cycles      |
| Apply to Remaining Warranty  | ✓       | -            | Also multiply remaining warranty   |

### Cost Settings

| Parameter                | Default | Range      | Description                     |
| ------------------------ | ------- | ---------- | ------------------------------- |
| Enable Cost Modification | ✗       | -          | Enable/disable cost changes     |
| Cost Multiplier          | 1.0     | 0.01-100.0 | Device purchase cost multiplier |

### Hardware Settings (Currently Unsupported by API)

| Parameter                   | Default | Range     | Description                      |
| --------------------------- | ------- | --------- | -------------------------------- |
| Enable CPU Modification     | ✗       | -         | Enable/disable CPU power changes |
| CPU Power Multiplier        | 1.0     | 0.1-100.0 | CPU power multiplier             |
| Enable Memory Modification  | ✗       | -         | Enable/disable RAM changes       |
| Memory (RAM) Multiplier     | 1.0     | 0.1-100.0 | RAM capacity multiplier          |
| Enable Storage Modification | ✗       | -         | Enable/disable storage changes   |
| Storage Multiplier          | 1.0     | 0.1-100.0 | Storage capacity multiplier      |

### Network Addressing Settings (Currently Unsupported by API)

| Parameter                      | Default | Description                                                                     |
| ------------------------------ | ------- | ------------------------------------------------------------------------------- |
| Enable Auto Network Addressing | ✗       | Automatically assign network addresses in format `@f{floor}/{class}{increment}` |

**Address Format**: `@f{floor}/{abbrev}{increment}`

- **Abbreviations**: 
  - def (default), swt (switch), rtr (router), tap (tap), fwr (firewall)
  - mls (media line simplex), mld (media line duplex), srv (compute server)
  - mon (monitor), dbg (debugger), ldt (load tester), pwr (power expansion)
  - dcr (decentro rigs), spr (surge protector), ups (ups), ine (inert)
  - ccv (cctv), phn (phone), prt (printer), nlb (load balancer)
- **Examples**: `@f4/srv1`, `@f2/swt3`, `@f18/nlb2`
- **Increments**: Per floor and device class combination

## Technical Details

### Device Classes Reference

The mod uses the `device_hardware_class` property to identify device types based on the DeviceHardwareClass enum:

- `0` = Default (def)
- `1` = Network Switch (swt)
- `2` = Network Router (rtr)
- `3` = Network Tap (tap)
- `4` = Network Firewall (fwr)
- `5` = Media Line Simplex (mls)
- `6` = Media Line Duplex (mld)
- `7` = Compute Server (srv)
- `8` = Display Monitor (mon)
- `9` = Debugger (dbg)
- `10` = Load Tester (ldt)
- `11` = Power Expansion (pwr)
- `12` = Decentro Rigs (dcr)
- `13` = Surge Protector (spr)
- `14` = UPS (ups)
- `15` = Inert (ine)
- `16` = CCTV (ccv)
- `17` = Phone (phn)
- `18` = Printer (prt)
- `19` = Network Load Balancer (nlb)

### Modification Timing

All modifications are applied when devices spawn via the `on_device_spawned()` callback. This ensures that:

- Changes apply to newly purchased devices
- Modifications persist for the device's lifetime
- No performance impact on existing devices

### Logging

The mod logs all modifications to the console with details about:

- Device name and class
- Original and modified values
- Multipliers applied

Example log output:

```
[device-tweaker] Active modifications: Bandwidth x2.00, Warranty x5.50 (random), Cost x0.75, Auto Network Addressing
[device-tweaker] Enabled device classes: server, switch, router
[device-tweaker] SuperSwitch 3000 (switch): BW: 1000 -> 2000 (x2.00) | warranty days: 365 -> 2008 | cost: $5000 -> $3750 | netaddr: @f2/swt1
```

### Network Address Auto-Assignment

When enabled, devices receive network addresses automatically using this logic:

- **Format**: `@f{floor}/{class_abbrev}{increment}`
- **Counter**: Tracks increments per floor and device class combination
- **Reset**: Counters reset when mod is reloaded (F11)

Example progression on floor 4:

- First compute server: `@f4/srv1`
- Second compute server: `@f4/srv2`
- First network switch: `@f4/swt1`
- Third compute server: `@f4/srv3`
- First network load balancer: `@f4/nlb1`

## Compatibility

- **Game Version**: Beta
- **Dependencies**: None required (modloader config system is optional)
- **Conflicts**: Should be compatible with most other mods

## Credits

This mod combines and extends functionality from:

- `2x-bandwidth-switches` - Original bandwidth modification concept
- `random-warranties` - Random warranty system implementation

## Version History

### 1.0 (2026-01-18)

- Initial release
- Merged bandwidth and warranty modification features
- Added cost modification
- Added hardware multipliers (CPU, memory, storage)
- Implemented device class filtering
- Added comprehensive configuration system

## Support

For issues, questions, or suggestions, please refer to the main TNI-Mods repository.

## License

See the LICENSE file in the main repository.


---

## Additional Notes

This mod combines and extends functionality from 2x-bandwidth-switches and random-warranties mods.
All modifications are applied when devices spawn.


---

[← Back to All Mods](/mods/)
