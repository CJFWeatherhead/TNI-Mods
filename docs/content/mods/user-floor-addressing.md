---
title: "User Floor-Based Addressing"
date: 2026-05-31
draft: false
mod_id: "user-floor-addressing"
author: "CJFWeatherhead"
version: "0.1.12"
status: "Active Development"
game_version: "0.10.11+"
---

# User Floor-Based Addressing

This mod sets DHCP mode, DNS servers, and assigns network addresses based on floor number and user increment.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 0.1.12 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | 0.10.11+ |
| **Last Updated** | 2026-05-31 |

</div>

---

## Download

<div class="download-section">

**[Download user-floor-addressing-0.1.12.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/user-floor-addressing-v0.1.12/user-floor-addressing-0.1.12.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **User Floor-Based Addressing** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `user-floor-addressing/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Network Address Format** | string | `@f%d/usr%d` | Format string for network addresses. Two %d placeholders are replaced with floor number and user increment (e.g., "@f%d/usr%d" becomes "@f0/usr1") |
| **DHCP Mode** | select: disabled, boot_dhcp, periodic_dhcp | `boot_dhcp` | DHCP mode for users. boot_dhcp = DHCP on boot only, periodic_dhcp = periodic DHCP requests, disabled = manual only |
| **Floor DNS Server Format** | string | `@f%d/dns` | Format string for floor-specific DNS servers. %d is replaced with floor number (e.g., "@f%d/dns" becomes "@f0/dns") |
| **Fallback DNS Server 1** | string | `@srv/dns1` | First fallback DNS server if floor-specific DNS is unavailable |
| **Fallback DNS Server 2** | string | `@srv/dns2` | Second fallback DNS server |

---

## About This Mod

This mod sets DHCP mode, DNS servers, and assigns network addresses based on floor number and user increment.

## Features
- Sets DHCP mode (default: "boot_dhcp") for all users
- Assigns addresses like "@f{floor}/usr{increment}" (configurable format)
- Configures DNS servers with a floor-specific primary and two configurable fallbacks
- Tracks user count per floor for incremental addressing

## Limitations
- Hardware (MAC) address control is not supported -- the mod API does not expose
  any method to set or refresh hardware addresses.
- Phone and CCTV addressing is not supported -- these are fixture outlets managed
  by MultiplayerSpawner nodes and are not accessible via the Lua mod API.

---

<details>
<summary><strong>Full Documentation</strong></summary>

# User Floor-Based Addressing Mod

This mod automatically configures network settings for users when they spawn in the game.

## Features

- **DHCP Configuration**: Sets DHCP mode per configuration (`boot_dhcp` by default)
- **Floor-Based Addressing**: Assigns predictable network addresses based on floor number and user count
  - Format is configurable, default: `@f<floor>/usr<increment>`
  - Example: User #5 on floor 3 gets address `@f3/usr5`
  - Example: User #1 on floor 10 gets address `@f10/usr1`
- **Automatic DNS Setup**: Configures a floor-specific primary DNS plus two fallback DNS servers

## How It Works

The mod hooks into the `on_user_spawned` callback, triggered whenever a new user is created:

1. Retrieves the user's logic controller and network control module
2. Gets the floor number from the user's location
3. Maintains a counter of users per floor
4. Generates a predictable network address based on floor and user count
5. Sets DHCP mode (default: `boot_dhcp`)
6. Configures DNS servers: floor-specific primary, then two configurable fallbacks

## Limitations

**Hardware (MAC) Addresses**: The mod API does not expose any method to set or
refresh hardware addresses. Hardware addresses are assigned by the game engine
and cannot be controlled by mods.

**Phone / CCTV Devices**: Phones and CCTVs are fixture outlets
(`DeviceOutlet`/`PoweredDeviceOutlet`) instantiated by `MultiplayerSpawner`
nodes in the scene tree. They are not accessible via the Lua mod API — there
is no `on_fixture_spawned` callback and no API method to enumerate them.

## Installation

1. Copy the `user-floor-addressing` folder to your `mods/` directory
2. The mod will be automatically loaded when the game starts
3. Press F11 to reload the mod without restarting the game

## Technical Details

### DHCP Modes

The game supports three DHCP modes:

- `"disabled"` - DHCP disabled, manual configuration required
- `"boot_dhcp"` - Request DHCP address on boot
- `"periodic_dhcp"` - Periodically request DHCP updates

### DNS Configuration

DNS servers are set using a Godot Array. By default:

- Floor-specific: `@f<floor>/dns`
- Fallback 1: `@srv/dns1`
- Fallback 2: `@srv/dns2`

All three are configurable via format strings.

### Address Format

Addresses use a configurable `printf`-style format with two `%d` placeholders
(floor number, user increment). Default: `@f%d/usr%d`.

## Compatibility

- Tested with game version: 0.10.11+
- Compatible with other mods that don't modify user network settings
- Works alongside device modification mods and reward scaling mods (e.g. `floor-reward-scaling`)


</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

DHCP modes available: "disabled", "boot_dhcp", "periodic_dhcp". Uses on_user_spawned hook.


</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `user-floor-addressing` |
| Creation Date | 2026-01-01 |
| Last Updated | 2026-05-31 |
| Game Version | 0.10.11+ |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/user-floor-addressing](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/user-floor-addressing) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/user-floor-addressing-v0.1.12)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/user-floor-addressing-v0.1.12/user-floor-addressing-0.1.12.zip)

</details>

---

[Back to All Mods](/mods/)
