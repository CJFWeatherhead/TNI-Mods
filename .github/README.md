# GitHub Configuration

This directory contains GitHub Actions workflows and documentation for the automated mod release system.

## Documentation Guide

| Document | Purpose | Audience |
|----------|---------|----------|
| [MOD-RELEASE-SYSTEM.md](MOD-RELEASE-SYSTEM.md) | Complete guide to the release automation system | All contributors |
| [QUICK-REFERENCE.md](QUICK-REFERENCE.md) | Cheat sheet for common tasks and commands | Developers |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Visual diagrams of how the system works | Maintainers |
| [CHANGES-SUMMARY.md](CHANGES-SUMMARY.md) | Historical changelog of system implementation | Maintainers |

## Quick Start

**For mod developers**: Start with [MOD-RELEASE-SYSTEM.md](MOD-RELEASE-SYSTEM.md)

**For quick lookups**: See [QUICK-REFERENCE.md](QUICK-REFERENCE.md)

## Directory Structure

```
.github/
├── README.md                 # This file
├── MOD-RELEASE-SYSTEM.md     # Main documentation
├── QUICK-REFERENCE.md        # Quick command reference
├── ARCHITECTURE.md           # System diagrams
├── CHANGES-SUMMARY.md        # Implementation history
├── scripts/
│   └── update_mod_version.py # Version bump script
└── workflows/
    ├── mod-release-reusable.yml      # Shared release logic
    ├── release-<mod-name>.yml        # Per-mod release workflows
    ├── build-zig-*.yml               # LuaJIT build (Zig)
    ├── build-gnu-*.yml               # LuaJIT build (GNU)
    └── deploy-website.yml            # Manual docs deployment
```
