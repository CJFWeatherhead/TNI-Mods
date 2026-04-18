# Money Cheat

Simple money cheat mod for Tower Networking Inc that adds configurable amounts of money via debug console command.

## Description

This mod provides a quick and easy way to add money to your balance during gameplay. Simply type `money` in the debug console (press `~`) to instantly receive a configurable amount of money. Perfect for testing, experimenting with game mechanics, or just having fun without financial constraints.

## Features

- **Debug Console Command**: Type `money` in the debug console to activate the cheat
- **Configurable Amount**: Set any amount from $100 to $10,000,000 (default: $10,000)
- **Console Feedback**: Confirmation messages when cheat is activated
- **In-Game Notifications**: Optional visual notifications (if supported)
- **Cooldown Protection**: 0.5-second cooldown prevents accidental double-activation
- **Debug Logging**: Optional detailed logging for troubleshooting

## Installation

1. Place the `money-cheat` folder in your `Mods/` directory
2. Load or reload the game (F11 to reload mods)
3. You should see "Money Cheat mod loaded!" in the console
4. Press `~` during gameplay to open the debug console, then type `money`

## Usage

### Activating the Cheat

During gameplay, press `~` to open the debug console, then type `money` and press Enter. You'll see a confirmation message in the console and receive the configured amount of money.

### Configuration

The mod can be configured through the Mod Manager UI or by editing the `entry.lua` file directly.

#### Available Settings

- **Money Amount** (default: 10000)
  
  - Amount of money to add when the money console command is run

- **Debug Logging** (default: true)
  
  - Enable detailed console messages
  - Shows confirmation when cheat is activated
  - Displays configuration on mod load

- **Show Notification** (default: true)
  
  - Attempts to show in-game notification when money is added
  - Falls back to console messages if not supported by game version

### Examples

**Small boost for tight situations:**

- Set Money Amount to $1,000

**Moderate funding (default):**

- Set Money Amount to $10,000

**Major financial injection:**

- Set Money Amount to $100,000

**Essentially unlimited funds:**

- Set Money Amount to $1,000,000+

## Technical Details

### Hooks Used

- `on_engine_load()`: Initialize mod and display configuration
- `on_mod_reload()`: Reload configuration when F11 is pressed

### How It Works

The mod registers a `money` command via `DebugLayer.register_cmd()`. When the command is run it uses the game's `modify_player_cash()` API to add money to the player's balance with the category set to INCOME.

### Configuration System

This mod uses the standardized `===== MOD CONFIGURATION START/END =====` marker system, making it compatible with automated Mod Manager tools. The `ui-config.ps1` file provides UI parameter definitions for graphical configuration interfaces.

## Compatibility

- **Game Version**: 0.10.0
- **Dependencies**: None
- **API Requirements**: ModApiV1, DebugLayer (activated automatically)

## Troubleshooting

### Cheat doesn't activate

1. Check that the mod is loaded (look for "Money Cheat mod loaded!" in console)
2. Press `~` to open the debug console — it should appear on screen
3. Type `money` and press Enter
4. Enable debug logging to see more detail if needed

### No confirmation message appears

1. Check that debug_logging is enabled in configuration
2. Verify the console is visible and not filtered
3. Look for error messages that might indicate API issues

### Money isn't being added

1. Verify the game world is active (you're in a game, not menu)
2. Check for error messages in console
3. Ensure the ModApiV1 is available (should show on mod load)

## Author

CJFWeatherhead

## Development Status

Active Development

## License

See LICENSE file in the root directory.

## Notes

This mod is intended for fun and experimentation. Using cheats may impact your gameplay experience and sense of achievement. Use responsibly!
