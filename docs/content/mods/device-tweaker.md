---
title: "Device Tweaker"
date: 2026-04-21
draft: false
mod_id: "device-tweaker"
author: "CJFWeatherhead"
version: "4.0.2"
status: "Active Development"
game_version: "beta"
---

# Device Tweaker

A comprehensive mod for tweaking device properties in Tower Networking Inc.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 4.0.2 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | beta |
| **Last Updated** | 2026-04-21 |

</div>

---

## Download

<div class="download-section">

**[Download device-tweaker-4.0.2.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/device-tweaker-v4.0.2/device-tweaker-4.0.2.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **Device Tweaker** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `device-tweaker/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Enable for Default Devices** | boolean | `True` | Apply modifications to default devices (class 0) |
| **Enable for Network Switches** | boolean | `True` | Apply modifications to network switch devices (class 1) |
| **Enable for Network Routers** | boolean | `True` | Apply modifications to network router devices (class 2) |
| **Enable for Network Taps** | boolean | `True` | Apply modifications to network tap devices (class 3) |
| **Enable for Network Firewalls** | boolean | `True` | Apply modifications to network firewall devices (class 4) |
| **Enable for Media Line Simplex** | boolean | `True` | Apply modifications to media line simplex devices (class 5) |
| **Enable for Media Line Duplex** | boolean | `True` | Apply modifications to media line duplex devices (class 6) |
| **Enable for Compute Servers** | boolean | `True` | Apply modifications to compute server devices (class 7) |
| **Enable for Display Monitors** | boolean | `True` | Apply modifications to display monitor devices (class 8) |
| **Enable for Debuggers** | boolean | `True` | Apply modifications to debugger devices (class 9) |
| **Enable for Load Testers** | boolean | `True` | Apply modifications to load tester devices (class 10) |
| **Enable for Power Expansion** | boolean | `True` | Apply modifications to power expansion devices (class 11) |
| **Enable for Decentro Rigs** | boolean | `True` | Apply modifications to decentro rig devices (class 12) |
| **Enable for Surge Protectors** | boolean | `True` | Apply modifications to surge protector devices (class 13) |
| **Enable for UPS Devices** | boolean | `True` | Apply modifications to UPS devices (class 14) |
| **Enable for Inert Devices** | boolean | `True` | Apply modifications to inert devices (class 15) |
| **Enable for CCTV** | boolean | `True` | Apply modifications to CCTV devices (class 16) |
| **Enable for Phones** | boolean | `True` | Apply modifications to phone devices (class 17) |
| **Enable for Printers** | boolean | `True` | Apply modifications to printer devices (class 18) |
| **Enable for Network Load Balancers** | boolean | `True` | Apply modifications to network load balancer devices (class 19) |
| **Enable for Network Storage** | boolean | `True` | Apply modifications to network storage devices (class 20) |
| **Enable Bandwidth Modification** | boolean | `True` | Enable bandwidth capacity modifications |
| **Bandwidth Mode** | select: fixed, random | `fixed` | Use a fixed multiplier or random range for bandwidth per device |
| **Bandwidth Multiplier** | number (0.1-100.0) | `2.0` | Fixed multiplier for device network bandwidth (used when mode is 'fixed') |
| **Min Random Bandwidth Multiplier** | number (0.1-100.0) | `1.5` | Lower bound for random bandwidth multiplier (used when mode is 'random') |
| **Max Random Bandwidth Multiplier** | number (0.1-100.0) | `4.0` | Upper bound for random bandwidth multiplier (used when mode is 'random') |
| **Enable Warranty Modification** | boolean | `True` | Enable warranty period modifications |
| **Warranty Mode** | select: fixed, random | `random` | fixed: apply a constant multiplier | random: apply a random multiplier per device |
| **Fixed Warranty Multiplier** | number (0.1-100.0) | `1.0` | Fixed multiplier for warranties (used when mode is 'fixed') |
| **Min Random Warranty Multiplier** | number (0.1-100.0) | `5.0` | Minimum multiplier for random warranties (used when mode is 'random') |
| **Max Random Warranty Multiplier** | number (0.1-1000.0) | `100.0` | Upper bound for random warranty multiplier (used when mode is 'random') |
| **Apply to Warranty Cycles** | boolean | `True` | Whether to also multiply warranty cycles (in addition to days) |
| **Apply to Remaining Warranty** | boolean | `True` | Whether to also apply multiplier to remaining warranty period |
| **Enable Cost Modification** | boolean | `False` | Enable device cost modifications |
| **Cost Multiplier** | number (0.01-100.0) | `1.0` | Multiplier for device purchase costs (e.g., 0.5 = half price, 2.0 = double price) |
| **Enable CPU Modification** | boolean | `False` | Enable CPU power modifications |
| **CPU Power Multiplier** | number (0.1-100.0) | `2.0` | Multiplier for device CPU power |
| **Enable Memory Modification** | boolean | `False` | Enable RAM modifications |
| **Memory Mode** | select: fixed, random | `fixed` | Use a fixed multiplier or random range for memory per device |
| **Memory (RAM) Multiplier** | number (0.1-100.0) | `4.0` | Fixed multiplier for device installed RAM (used when mode is 'fixed') |
| **Min Random Memory Multiplier** | number (0.1-100.0) | `2.0` | Lower bound for random memory multiplier (used when mode is 'random') |
| **Max Random Memory Multiplier** | number (0.1-100.0) | `8.0` | Upper bound for random memory multiplier (used when mode is 'random') |
| **Enable Storage Modification** | boolean | `False` | Enable storage capacity modifications |
| **Storage Mode** | select: fixed, random | `fixed` | Use a fixed multiplier or random range for storage per device |
| **Storage Multiplier** | number (0.1-100.0) | `8.0` | Fixed multiplier for device storage capacity (used when mode is 'fixed') |
| **Min Random Storage Multiplier** | number (0.1-100.0) | `4.0` | Lower bound for random storage multiplier (used when mode is 'random') |
| **Max Random Storage Multiplier** | number (0.1-1000.0) | `16.0` | Upper bound for random storage multiplier (used when mode is 'random') |

---

## About This Mod

A comprehensive mod for tweaking device properties in Tower Networking Inc.
Modifications are applied automatically when devices spawn — no keyboard input needed.

## Features
- **Bandwidth Multiplier**: Adjust network bandwidth capacity (installed_nbw)
- **Warranty Modifications**: Set fixed or random warranty multipliers
- **Cost Adjustments**: Modify device purchase prices
- **Hardware Multipliers**: Scale CPU (installed_cpu), RAM (installed_mem), and storage (installed_sto)
- **Device Class Filtering**: Selectively apply modifications to specific device types

## Device Classes (21 types)
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
- Network Storage (20) - nst

## Configuration Tips
- Enable specific modifications using the enable toggles
- Set multipliers > 1.0 to increase values, < 1.0 to decrease
- Use random warranty mode for varied warranty periods per device
- Disable device classes you don't want to modify
- Restock merchants with SHIFT+R (money-cheat mod)

## Notes
- No panels, no keyboard input — purely passive on_device_spawned hook
- Incompatible with 2x-bandwidth-switches and random-warranties (supersedes both)

---

<details>
<summary><strong>Full Documentation</strong></summary>

# Device Tweaker Mod

A comprehensive mod for Tower Networking Inc that allows you to customize device properties including bandwidth, warranties, costs, and hardware specifications. This is an extension of the 2x Bandwidth mod and the Random Warranties mod.

## Features

### 🔧 Multiple Modification Types

- **Bandwidth**: Adjust network bandwidth capacity (`installed_nbw`) for switches, routers, and other network devices
- **Warranties**: Set fixed or random warranty multipliers for device reliability
- **Cost**: Modify device purchase prices (`price`) — make them cheaper or more expensive
- **Hardware**: Scale CPU power (`installed_cpu`), RAM (`installed_mem`), and storage (`installed_sto`) independently

### 🎯 Device Class Filtering

Selectively apply modifications to specific device types (all 21 classes from game API v0.10.11):

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
- **Network Storage** (20) - nst

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

| Parameter                         | Default | Description                                                      |
| --------------------------------- | ------- | ---------------------------------------------------------------- |
| Enable for Default Devices        | ✓       | Apply modifications to default devices (class 0)                 |
| Enable for Network Switches       | ✓       | Apply modifications to network switch devices (class 1)          |
| Enable for Network Routers        | ✓       | Apply modifications to network router devices (class 2)          |
| Enable for Network Taps           | ✓       | Apply modifications to network tap devices (class 3)             |
| Enable for Network Firewalls      | ✓       | Apply modifications to network firewall devices (class 4)        |
| Enable for Media Line Simplex     | ✓       | Apply modifications to media line simplex devices (class 5)      |
| Enable for Media Line Duplex      | ✓       | Apply modifications to media line duplex devices (class 6)       |
| Enable for Compute Servers        | ✓       | Apply modifications to compute server devices (class 7)          |
| Enable for Display Monitors       | ✓       | Apply modifications to display monitor devices (class 8)         |
| Enable for Debuggers              | ✓       | Apply modifications to debugger devices (class 9)                |
| Enable for Load Testers           | ✓       | Apply modifications to load tester devices (class 10)            |
| Enable for Power Expansion        | ✓       | Apply modifications to power expansion devices (class 11)        |
| Enable for Decentro Rigs          | ✓       | Apply modifications to decentro rig devices (class 12)           |
| Enable for Surge Protectors       | ✓       | Apply modifications to surge protector devices (class 13)        |
| Enable for UPS Devices            | ✓       | Apply modifications to UPS devices (class 14)                    |
| Enable for Inert Devices          | ✓       | Apply modifications to inert devices (class 15)                  |
| Enable for CCTV                   | ✓       | Apply modifications to CCTV devices (class 16)                   |
| Enable for Phones                 | ✓       | Apply modifications to phone devices (class 17)                  |
| Enable for Printers               | ✓       | Apply modifications to printer devices (class 18)                |
| Enable for Network Load Balancers | ✓       | Apply modifications to network load balancer devices (class 19)  |
| Enable for Network Storage        | ✓       | Apply modifications to network storage devices (class 20)        |

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

### Hardware Settings

| Parameter                   | Default | Range     | Description                      |
| --------------------------- | ------- | --------- | -------------------------------- |
| Enable CPU Modification     | ✗       | -         | Enable/disable CPU power changes |
| CPU Power Multiplier        | 1.0     | 0.1-100.0 | CPU power multiplier             |
| Enable Memory Modification  | ✗       | -         | Enable/disable RAM changes       |
| Memory (RAM) Multiplier     | 1.0     | 0.1-100.0 | RAM capacity multiplier          |
| Enable Storage Modification | ✗       | -         | Enable/disable storage changes   |
| Storage Multiplier          | 1.0     | 0.1-100.0 | Storage capacity multiplier      |

## Technical Details

### API Property Mapping (game v0.10.11)

| Mod Feature | API Property | Object |
|-------------|-------------|--------|
| Bandwidth | `installed_nbw` | `LogicController` |
| CPU | `installed_cpu` | `LogicController` |
| Memory | `installed_mem` | `LogicController` |
| Storage | `installed_sto` | `LogicController` |
| Price | `price` | `DeviceUnit` |
| Warranty Days | `base_warranty_days` | `DeviceUnit` |
| Warranty Cycles | `base_warranty_cycles` | `DeviceUnit` |
| Warranty Remaining | `warranty_period_remaining` | `DeviceUnit` |
| Device Class | `device_hardware_class` | `DeviceUnit` |

### Device Classes Reference

The mod uses the `device_hardware_class` property to identify device types based on the `DeviceUnit.DeviceHardwareClass` enum:

| ID | Enum Name | Abbreviation |
|----|-----------|-------------|
| 0 | DEFAULT | def |
| 1 | NETWORK_SWITCH | swt |
| 2 | NETWORK_ROUTER | rtr |
| 3 | NETWORK_TAP | tap |
| 4 | NETWORK_FIREWALL | fwr |
| 5 | MEDIA_LINE_SIMPLEX | mls |
| 6 | MEDIA_LINE_DUPLEX | mld |
| 7 | COMPUTE_SERVER | srv |
| 8 | DISPLAY_MONITOR | mon |
| 9 | DEBUGGER | dbg |
| 10 | LOAD_TESTER | ldt |
| 11 | POWER_EXPANSION | pwr |
| 12 | DECENTRO_RIGS | dcr |
| 13 | SURGE_PROTECTOR | spr |
| 14 | UPS | ups |
| 15 | INERT | ine |
| 16 | CCTV | ccv |
| 17 | PHONE | phn |
| 18 | PRINTER | prt |
| 19 | NETWORK_LOAD_BALANCER | nlb |
| 20 | NETWORK_STORAGE | nst |

### Modification Timing

All modifications are applied when devices spawn via the `on_device_spawned()` callback. This ensures that:

- Changes apply to newly purchased devices
- Modifications persist for the device's lifetime
- No performance impact on existing devices

### Merchant Restock

Use the debug console (`~` key) and type `m_restock` to restock all merchants. The restock function uses `ModApiV1.get_merchants()` to retrieve merchants and calls `merchant.restock()` on each one.

### Logging

The mod logs all modifications to the console with details about:

- Device name and class
- Original and modified values
- Multipliers applied

Example log output:

```
[device-tweaker] Active modifications: Bandwidth x2.00, Warranty x5.50 (random), Cost x0.75
[device-tweaker] Enabled device classes: network_switch, network_router, compute_server
[device-tweaker] SuperSwitch 3000 (network_switch): BW: 1000 -> 2000 (x2.00) | warranty: 365 -> 2008 days (x5.50) | price: $5000 -> $3750
```

## Compatibility

- **Game Version**: 0.10.7+ (typed for 0.10.11)
- **Dependencies**: `luajit-support ~0.2.0`
- **Conflicts**: `random-warranties`, `2x-bandwidth-switches` (both are superseded by this mod)

## Credits

This mod combines and extends functionality from:

- `2x-bandwidth-switches` - Original bandwidth modification concept
- `random-warranties` - Random warranty system implementation

## Version History

### 3.0 (2026-04-20)

- Cleanroom rewrite against game API v0.10.11 typing
- Fixed CPU modification: `cpu_power` → `installed_cpu`
- Fixed Memory modification: `installed_ram` → `installed_mem`
- Fixed Storage modification: `installed_storage` → `installed_sto`
- Fixed Cost modification: `base_cost_dollars` → `price`
- Fixed merchant restock: `world.device_merchants` → `ModApiV1.get_merchants()`
- Added NETWORK_STORAGE (class 20) support
- Removed non-functional hotkey restock (replaced by debug console command)
- Updated all debug dump property names to match current API

### 2.2

- Added debug console command registration
- Added merchant restock functionality

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


</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

This mod supersedes 2x-bandwidth-switches and random-warranties.
All modifications are applied when devices spawn (on_device_spawned hook).
No input handling, no panels, no register_cmd.


</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `device-tweaker` |
| Creation Date | 2026-01-18 |
| Last Updated | 2026-04-21 |
| Game Version | beta |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/mods/device-tweaker](https://github.com/CJFWeatherhead/TNI-Mods/tree/beta/mods/device-tweaker) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/device-tweaker-v4.0.2)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/device-tweaker-v4.0.2/device-tweaker-4.0.2.zip)

</details>

---

[Back to All Mods](/mods/)
