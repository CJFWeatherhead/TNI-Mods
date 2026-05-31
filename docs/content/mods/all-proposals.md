---
title: "All Proposals"
date: 2026-05-31
draft: false
mod_id: "all-proposals"
author: "CJFWeatherhead"
version: "2.0.4"
status: "Active Development"
game_version: "stable"
---

# All Proposals

Shows all available proposals at once by overriding the game's proposal batch size.

<div class="mod-header-info">

| | |
|---|---|
| **Version** | 2.0.4 |
| **Author** | CJFWeatherhead |
| **Status** | 🟢 Active Development |
| **Game Version** | stable |
| **Last Updated** | 2026-05-31 |

</div>

---

## Download

<div class="download-section">

**[Download all-proposals-2.0.4.zip](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/all-proposals-v2.0.4/all-proposals-2.0.4.zip)** | [All Releases](https://github.com/CJFWeatherhead/TNI-Mods/releases)

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **All Proposals** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `all-proposals/` folder to your mods directory:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Tower Networking Inc\mods\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) is in the mods directory

</details>

---

## About This Mod

Shows all available proposals at once by overriding the game's proposal batch size.

## Keyboard Shortcuts
- **SHIFT+O**: Show all eligible proposals (increases batch size, triggers reroll)
- **SHIFT+U**: Restore normal proposal display (restores original batch size, triggers reroll)

## Logic
- Excludes proposals with unmet dependencies
- Excludes proposals that fail adhoc requirements
- Excludes already-submitted proposals
- Prints a summary: available / blocked / submitted counts

## Notes
- No panels, no console commands — keyboard shortcuts only
- Re-open the Secretariat screen if proposals don't refresh immediately

---

<details>
<summary><strong>Full Documentation</strong></summary>

# All Proposals Mod

## Description
This mod enhances the proposal system in the game by allowing players to view all available proposals at once. When activated, it temporarily increases the proposal batch size to display all eligible proposals, excluding only those with unmet dependencies or failed adhoc requirements.

## Features
- View all available proposals via debug console (`m_show_proposals` command)
- Automatically excludes proposals with unmet dependencies
- Shows detailed dependency information (what each blocked proposal requires)
- Checks adhoc requirements before displaying proposals
- Restore normal proposal display with `m_hide_proposals` command
- Provides organized, categorized logging of proposal status:
  - Available proposals
  - Blocked proposals with reasons
  - Already submitted proposals

## Installation
1. Place the `all-proposals` folder in your game's `lua` mods directory.
2. Ensure the mod is enabled in your mod configuration.
3. Restart the game or reload mods.

## Usage
- **Activate All Proposals**: Press `~` to open the debug console, then type `m_show_proposals`.
- **Restore Normal Mode**: Type `m_hide_proposals` in the debug console to return to the default proposal batch size and reroll proposals.

The mod will log detailed information about the proposal status in the console, organized into three sections:
- **AVAILABLE PROPOSALS**: Proposals that can be selected
- **BLOCKED PROPOSALS**: Proposals with unmet dependencies (shows what they require)
- **SUBMITTED PROPOSALS**: Proposals already completed

### Important: UI Refresh

The mod updates the proposal batch size and triggers a reroll, but **the Secretariat UI does not automatically refresh**. To see all proposals in the Secretariat app:

1. **Close and reopen the Secretariat app** - This is the most reliable method
2. Use the "Refresh RFP's" button in the Secretariat (costs credits)
3. Wait for the automatic 3-day refresh cycle

The proposals **are updated in the game's backend** - it's only the UI display that needs manual refreshing. The console output will show you all available proposals even if the Secretariat hasn't refreshed yet.

## Example Output
```
[All Proposals] ========================================
[All Proposals] Activating all available proposals...
[All Proposals] ========================================

[All Proposals] --- AVAILABLE PROPOSALS (27) ---
[All Proposals]   [OK] Reduce Expenses
[All Proposals]   [OK] Overvoltage Directive
...

[All Proposals] --- BLOCKED PROPOSALS (20) ---
[All Proposals]   [X] Advanced Research (requires: Basic Research)
[All Proposals]   [X] Phase Two (requires: Phase One)
...

[All Proposals] --- SUBMITTED PROPOSALS (0) ---

[All Proposals] ========================================
[All Proposals] SUMMARY
[All Proposals]   Total proposals: 47
[All Proposals]   Available: 27
[All Proposals]   Blocked: 20
[All Proposals]   Submitted: 0
[All Proposals] ========================================
```

## Compatibility
- Compatible with Tower Networking Inc game version stable
- Uses ModApiV1 for game integration
- No known conflicts with other mods

## Author
CJFWeatherhead

## Notes
- The mod safely stores and restores the original proposal batch size.
- Proposals are filtered to ensure only truly available ones are displayed.
- Detailed console output helps with debugging proposal availability.
- The mod emits UI update signals to try to refresh the Secretariat display automatically.

</details>

---

<details>
<summary><strong>Additional Notes</strong></summary>

- Uses ModApiV1 for game integration
- Safely checks proposal dependencies and adhoc requirements
- Provides detailed console logging (available / blocked / submitted counts)
- No known conflicts with other mods

</details>

---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `all-proposals` |
| Creation Date | 2026-01-01 |
| Last Updated | 2026-05-31 |
| Game Version | stable |
| Dependencies | None |
| Website | [https://github.com/CJFWeatherhead/TNI-Mods/tree/main/mods/all-proposals](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/mods/all-proposals) |

**Release URLs:**
- [Latest Release](https://github.com/CJFWeatherhead/TNI-Mods/releases/tag/all-proposals-v2.0.4)
- [Direct Download](https://github.com/CJFWeatherhead/TNI-Mods/releases/download/all-proposals-v2.0.4/all-proposals-2.0.4.zip)

</details>

---

[Back to All Mods](/mods/)
