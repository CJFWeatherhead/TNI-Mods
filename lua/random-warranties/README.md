# Random Device Warranties

This mod randomizes the warranty periods of all devices in The Tower Network Inc game.

## Description

Device warranties in the game have fixed periods. This mod introduces randomness by multiplying the base warranty days and cycles by a random factor between 2x and 25x for each spawned device.

## Features

- Randomizes warranty periods for all device types
- Multiplier ranges from 2x to 25x
- Affects both base warranty days and cycles
- Also modifies remaining warranty period if applicable
- Provides console logging of changes

## Installation

1. Place the `random-warranties` folder in your `lua/` directory
2. Load or reload the game
3. All newly spawned devices will have randomized warranties

## Usage

No additional configuration required. The mod activates automatically when devices are spawned.

## Compatibility

- Game Version: beta
- Dependencies: None

## Author

CJFWeatherhead

## Notes

Each device gets its own random multiplier, so warranties vary widely. Some devices may have very short warranties, others extremely long ones.