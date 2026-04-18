# All Proposals Mod

## Description
This mod enhances the proposal system in the game by allowing players to view all available proposals at once. When activated, it temporarily increases the proposal batch size to display all eligible proposals, excluding only those with unmet dependencies or failed adhoc requirements.

## Features
- View all available proposals via debug console (`show_proposals` command)
- Automatically excludes proposals with unmet dependencies
- Shows detailed dependency information (what each blocked proposal requires)
- Checks adhoc requirements before displaying proposals
- Restore normal proposal display with `hide_proposals` command
- Provides organized, categorized logging of proposal status:
  - Available proposals
  - Blocked proposals with reasons
  - Already submitted proposals

## Installation
1. Place the `all-proposals` folder in your game's `lua` mods directory.
2. Ensure the mod is enabled in your mod configuration.
3. Restart the game or reload mods.

## Usage
- **Activate All Proposals**: Press `~` to open the debug console, then type `show_proposals`.
- **Restore Normal Mode**: Type `hide_proposals` in the debug console to return to the default proposal batch size and reroll proposals.

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