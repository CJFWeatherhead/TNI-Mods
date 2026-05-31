# 2x Bandwidth Switches

A simple example mod that doubles the bandwidth capacity of all switches in the Tower Networking Inc game.

> **Note**: This functionality is also available in the [Device Tweaker](../device-tweaker/) mod which offers more comprehensive device customization. However, this mod remains available as a simple, feature-complete example - it was originally a template mod by [treefarmer741](https://github.com/treefarmer741) and makes an excellent starting point for new mod developers.

## Description

Switches in the game have a limited network bandwidth capacity. This mod increases that capacity by 2x, allowing switches to handle more network traffic without bottlenecks.

## Features

- Automatically doubles the installed network bandwidth (nbw) of all switch devices
- Works on all types of switches (device_hardware_class == 1)
- Modification applies when devices are spawned

## Installation

1. Place the `2x-bandwidth-switches` folder in your `lua/` directory
2. Load or reload the game
3. All newly spawned switches will have doubled bandwidth

## Usage

No additional configuration required. The mod activates automatically when devices are spawned.

## Compatibility

- Game Version: stable
- Dependencies: None

## Author

[treefarmer741](https://github.com/treefarmer741)

## Notes

This mod only affects switches and does not modify other device types.