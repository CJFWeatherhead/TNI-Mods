# All Proposals Mod

## Description
This mod enhances the proposal system in the game by allowing players to view all available proposals at once. When activated, it temporarily increases the proposal batch size to display all eligible proposals, excluding only those with unmet dependencies or failed adhoc requirements.

## Features
- View all available proposals with Shift+P
- Automatically excludes proposals with unmet dependencies
- Shows detailed dependency information (what each blocked proposal requires)
- Checks adhoc requirements before displaying proposals
- Restore normal proposal display with Shift+O
- Provides organized, categorized logging of proposal status:
  - Available proposals
  - Blocked proposals with reasons
  - Already submitted proposals

## Installation
1. Place the `all-proposals` folder in your game's `lua` mods directory.
2. Ensure the mod is enabled in your mod configuration.
3. Restart the game or reload mods.

## Usage
- **Activate All Proposals**: Press `Shift+P` to show all available proposals.
- **Restore Normal Mode**: Press `Shift+O` to return to the default proposal batch size and reroll proposals.

The mod will log detailed information about the proposal status in the console, organized into three sections:
- **AVAILABLE PROPOSALS**: Proposals that can be selected
- **BLOCKED PROPOSALS**: Proposals with unmet dependencies (shows what they require)
- **SUBMITTED PROPOSALS**: Proposals already completed

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
- Compatible with Tower Networking Inc game version beta
- Uses ModApiV1 for game integration
- No known conflicts with other mods

## Author
CJFWeatherhead

## Notes
- The mod safely stores and restores the original proposal batch size.
- Proposals are filtered to ensure only truly available ones are displayed.
- Detailed console output helps with debugging proposal availability.
- The mod emits UI update signals to try to refresh the Secretariat display automatically.