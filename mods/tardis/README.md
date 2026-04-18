# TARDIS - Time Controller

Control game time like a Time Lord! This mod provides debug console commands to manipulate game speed and skip time in Tower Networking Inc.

## Description

Just like the Doctor's famous time machine (Time And Relative Dimension In Space), this mod gives you control over the flow of time. Speed up boring moments, slow down critical situations, or skip straight to the end of the day.

The game already allows you to speed up time with coffee and slow it down with tea - this mod takes that concept and puts it in the debug console for easy access.

## Features

- **Speed Control**: Increase or decrease game speed via debug console commands
- **Day Skip**: Jump straight to 23:59 (end of day)
- **Visual Feedback**: On-screen notifications for all actions
- **Fully Configurable**: Adjust all parameters via Mod Manager
- **Cooldown Protection**: Prevents accidental rapid-fire key presses

## Installation

1. Place the `tardis` folder in your `Mods/` directory
2. Load or reload the game (F11 to reload mods)
3. You should see "TARDIS mod loaded!" in the console
4. Use debug console commands during gameplay (press `~` to open the console)

## Console Commands

Press `~` to open the debug console, then type a command:

| Command | Action |
|---------|--------|
| **speed_up** | Increase game speed by configured step |
| **speed_down** | Decrease game speed by configured step |
| **speed_reset** | Reset game speed to default |
| **day_skip** | Skip to end of day (23:59) |

## Configuration

All settings can be configured through the Mod Manager UI or by editing `entry.lua` directly.

### Speed Settings

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| **Speed Step** | 0.5 | 0.1 - 2.0 | Amount to change speed per keypress |
| **Min Speed** | 0.25 | 0.1 - 1.0 | Minimum speed multiplier |
| **Max Speed** | 10.0 | 2.0 - 50.0 | Maximum speed multiplier |
| **Default Speed** | 1.0 | 0.25 - 5.0 | Reference default speed |

### Time Skip Settings

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| **Skip To Time** | 23.99 | 0.0 - 23.99 | Hour to skip to (24h format) |

### Notification Settings

| Setting | Default | Description |
|---------|---------|-------------|
| **Show Notifications** | true | Display on-screen notifications |
| **Debug Logging** | false | Show detailed console output |

## Examples

### Quick Time Passing
Need to wait for something? Type `speed_up` a few times to speed up to 5x or 10x speed, then `speed_reset` to return to normal.

### End of Day Skip
Need to close out the day? Type `day_skip` to instantly jump to 23:59.

### Slow Motion Analysis
Want to carefully observe something? Type `speed_down` to slow down to 0.25x speed.

## Technical Details

- Uses `GameWorld.update_server_timescale()` for speed control
- Uses `DayCycleController.force_day_clock()` for time manipulation
- Speed changes persist until manually changed or game restart
- Console commands registered via `DebugLayer.register_cmd()` (activated automatically on game load)

## Compatibility

- **Game Version**: Beta
- **Dependencies**: None
- **Conflicts**: May interact unexpectedly with other mods that manipulate game time

## Troubleshooting

### Speed changes don't work
- Ensure the mod is properly loaded (check console for "TARDIS mod loaded!")
- Press `~` to open the debug console and try typing `speed_up`
- Check if another mod might be conflicting

### Day skip doesn't work
- The day skip relies on `DayCycleController` which may not be available in all game modes
- Check the console for error messages
- Try enabling debug logging to see more details

### Notifications don't appear
- Ensure "Show Notifications" is enabled in config
- Some game states may not support notifications

## Changelog

### v0.1.0 (2026-01-31)
- Initial release
- Speed up/down/reset via debug console commands (speed_up, speed_down, speed_reset)
- Day skip via debug console (day_skip)
- Configurable parameters
- In-game notifications

## Credits

- **Author**: CJFWeatherhead
- **Inspiration**: Doctor Who's TARDIS, and the in-game tea/coffee time mechanics
- **Thanks**: The TNI modding community

## License

This mod is released under the same license as the TNI-Mods repository.
