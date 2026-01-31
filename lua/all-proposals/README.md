# All Proposals Mod

## Description
This mod enhances the proposal system in the game by allowing players to view all available proposals at once. When activated, it temporarily increases the proposal batch size to display all eligible proposals, excluding only those with unmet dependencies or failed adhoc requirements.

## Features
- View all available proposals with Shift+P
- Automatically excludes proposals with unmet dependencies
- Checks adhoc requirements before displaying proposals
- Restore normal proposal display with Shift+O
- Provides detailed logging of proposal status

## Installation
1. Place the `all-proposals` folder in your game's `lua` mods directory.
2. Ensure the mod is enabled in your mod configuration.
3. Restart the game or reload mods.

## Usage
- **Activate All Proposals**: Press `Shift+P` to show all available proposals.
- **Restore Normal Mode**: Press `Shift+O` to return to the default proposal batch size and reroll proposals.

The mod will log detailed information about the proposal status in the console, including counts of total, available, blocked, and submitted proposals.

## Compatibility
- Compatible with Tower Networking Inc game version beta
- Uses ModApiV1 for game integration
- No known conflicts with other mods

## Author
Unknown

## Notes
- The mod safely stores and restores the original proposal batch size.
- Proposals are filtered to ensure only truly available ones are displayed.
- Detailed console output helps with debugging proposal availability.