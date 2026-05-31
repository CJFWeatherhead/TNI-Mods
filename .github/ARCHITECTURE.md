# Mod Release System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TNI-Mods Repository                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  /lua/                           /.github/                         │
│  ├── 2x-bandwidth-switches/      ├── workflows/                    │
│  │   ├── entry.lua               │   ├── mod-release-reusable.yml │
│  │   ├── metadata.yaml           │   ├── release-2x-bandwidth...  │
│  │   └── README.md               │   ├── release-all-proposals... │
│  ├── money-cheat/                │   ├── release-device-tweaker..│
│  │   ├── entry.lua               │   └── ... (9 mod workflows)   │
│  │   ├── metadata.yaml           ├── scripts/                     │
│  │   └── README.md               │   └── update_mod_version.py   │
│  └── ... (9 mods total)          └── MOD-RELEASE-SYSTEM.md        │
│                                                                     │
│  /docs/                                                             │
│  ├── generate_mod_pages.py                                         │
│  ├── content/mods/                                                  │
│  └── hugo.toml                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Workflow Execution Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│ TRIGGER: Push to lua/money-cheat/**                                     │
└────────────────────────┬─────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ GitHub Actions: release-money-cheat.yml                                │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ on:                                                                 │ │
│ │   push:                                                             │ │
│ │     branches: [main]                                                │ │
│ │     paths: ['lua/money-cheat/**']                                   │ │
│ │   workflow_dispatch:                                                │ │
│ │     inputs: { bump_type: [patch, minor, major] }                    │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└────────────────────────┬─────────────────────────────────────────────────┘
                         │
                         │ Calls with:
                         │   mod_name: 'money-cheat'
                         │   bump_type: 'patch'
                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Reusable Workflow: mod-release-reusable.yml                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Step 1: Checkout Repository                                           │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ git clone + fetch full history                                 │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                         │                                               │
│  Step 2: Update Version                                                │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ python update_mod_version.py lua/money-cheat/metadata.yaml     │   │
│  │                                                                 │   │
│  │ Before:                      After:                             │   │
│  │ Version: 0.1.0               Version: 0.1.1                     │   │
│  │ Last Updated: 2026-01-20     Last Updated: 2026-01-24          │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                         │                                               │
│  Step 3: Commit Changes                                                │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ git commit -m "chore(money-cheat): bump version to 0.1.1"      │   │
│  │ git push                                                        │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                         │                                               │
│  Step 4: Package Mod                                                   │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ cd lua/money-cheat                                              │   │
│  │ zip -r money-cheat-0.1.1.zip .                                  │   │
│  │                                                                 │   │
│  │ Contents: entry.lua, metadata.yaml, README.md                   │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                         │                                               │
│  Step 5: Create GitHub Release                                         │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ Tag: money-cheat-v0.1.1                                         │   │
│  │ Title: "money-cheat v0.1.1"                                     │   │
│  │ Assets: money-cheat-0.1.1.zip                                   │   │
│  │ Notes: Auto-generated from metadata.yaml                        │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                         │                                               │
│  Step 6: Regenerate Documentation                                      │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ cd docs                                                         │   │
│  │ python3 generate_mod_pages.py                                   │   │
│  │                                                                 │   │
│  │ Reads: lua/*/metadata.yaml (all mods)                           │   │
│  │ Generates: content/mods/*.md (Hugo pages)                       │   │
│  │                                                                 │   │
│  │ Includes:                                                       │   │
│  │ - Version number                                                │   │
│  │ - Download link to GitHub release                               │   │
│  │ - Release tag URL                                               │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                         │                                               │
│  Step 7: Build Hugo Site                                               │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ hugo --minify                                                   │   │
│  │ Output: docs/public/                                            │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                         │                                               │
│  Step 8: Deploy to Cloudflare Pages                                    │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ Upload docs/public/ to Cloudflare                               │   │
│  │ URL: https://tower.networking.ink/                              │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                         │                                               │
│  Step 9: Summary                                                       │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ Output to GitHub Actions summary                                │   │
│  └────────────────────────────────────────────────────────────────┘   │
└────────────────────────┬─────────────────────────────────────────────────┘
                         │
                         ▼
                    ✅ COMPLETE
```

## Release Artifacts Generated

```
GitHub Release: money-cheat-v0.1.1
├── Tag: money-cheat-v0.1.1
├── Title: "money-cheat v0.1.1"
├── Release Notes:
│   ├── Mod description from metadata.yaml
│   ├── Installation instructions
│   └── Link to documentation
└── Assets:
    └── money-cheat-0.1.1.zip
        ├── entry.lua
        ├── metadata.yaml
        └── README.md

Documentation Page: https://tower.networking.ink/mods/money-cheat/
├── Mod Information (with version)
├── Download Section
│   ├── Direct link to money-cheat-0.1.1.zip
│   └── Link to all releases
├── Installation Instructions
├── Configuration Parameters
└── Detailed Documentation
```

## File Interactions

```
┌─────────────────────────────────────────────────────────────────┐
│                    update_mod_version.py                        │
│                                                                 │
│  Reads:  lua/<mod-name>/metadata.yaml                          │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ Version: 0.1.0          →  Parses                     │     │
│  │ Last Updated: 2026-01-20                              │     │
│  └───────────────────────────────────────────────────────┘     │
│                         │                                       │
│                         ▼                                       │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ Semantic Version Logic:                               │     │
│  │ - patch: 0.1.0 → 0.1.1                                │     │
│  │ - minor: 0.1.0 → 0.2.0                                │     │
│  │ - major: 0.1.0 → 1.0.0                                │     │
│  └───────────────────────────────────────────────────────┘     │
│                         │                                       │
│                         ▼                                       │
│  Writes: lua/<mod-name>/metadata.yaml (updated)                │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ Version: 0.1.1                                        │     │
│  │ Last Updated: 2026-01-24                              │     │
│  └───────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  generate_mod_pages.py                          │
│                                                                 │
│  For each mod in lua/*/                                         │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ 1. Read metadata.yaml                                 │     │
│  │ 2. Extract: Name, Version, Description, etc.          │     │
│  │ 3. Build download URLs:                               │     │
│  │    - Tag: <mod-id>-v<version>                         │     │
│  │    - Zip: <mod-id>-<version>.zip                      │     │
│  │ 4. Generate Hugo markdown file                        │     │
│  │ 5. Save to docs/content/mods/<mod-id>.md              │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
│  Output: docs/content/mods/money-cheat.md                       │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ ---                                                   │     │
│  │ title: "Money Cheat"                                  │     │
│  │ version: "0.1.1"                                      │     │
│  │ ---                                                   │     │
│  │                                                       │     │
│  │ ## Download                                           │     │
│  │ [📦 Download money-cheat-0.1.1.zip](...)              │     │
│  └───────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

## Parallel Workflows

```
Multiple mods can release simultaneously without conflict:

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ Money Cheat      │  │ Device Tweaker   │  │ Random Warranties│
│ release workflow │  │ release workflow │  │ release workflow │
└────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                     │                     │
         │ Only touches:       │ Only touches:       │ Only touches:
         │ - lua/money-cheat/  │ - lua/device-      │ - lua/random-
         │                     │   tweaker/          │   warranties/
         ▼                     ▼                     ▼
    ✅ No conflicts - Each mod has isolated paths
    ✅ All can run in parallel
    ✅ All generate their own releases
    ✅ All update shared docs (Hugo regenerates all pages)
```

## Build Workflows (Updated)

```
┌─────────────────────────────────────────────────────────────────┐
│ Build Workflows: build-zig-continuous.yml, build-gnu-*.yml     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ BEFORE (old):                                                   │
│ ┌───────────────────────────────────────────────────────┐     │
│ │ on:                                                   │     │
│ │   push:                                               │     │
│ │     paths-ignore: ['lua/', '*.md']                    │     │
│ │                                                       │     │
│ │ Problem: Triggers on ANY non-lua, non-md change       │     │
│ └───────────────────────────────────────────────────────┘     │
│                                                                 │
│ AFTER (new):                                                    │
│ ┌───────────────────────────────────────────────────────┐     │
│ │ on:                                                   │     │
│ │   push:                                               │     │
│ │     paths:                                            │     │
│ │       - 'ext/LuaJIT/**'                               │     │
│ │       - 'programs/luajit/**'                          │     │
│ │       - 'CMakeLists.txt'                              │     │
│ │       - 'cmake/**'                                    │     │
│ │       - 'build.sh' / 'zig.cmd'                        │     │
│ │                                                       │     │
│ │ Benefit: Only triggers when LuaJIT code changes       │     │
│ └───────────────────────────────────────────────────────┘     │
│                                                                 │
│ Result: Fewer unnecessary builds, faster CI/CD                 │
└─────────────────────────────────────────────────────────────────┘
```

## Summary

**9 Mods** × **1 Workflow Each** = **9 Individual Workflows**
**+** **1 Reusable Workflow** (shared logic)
**+** **1 Version Script** (Python)
**+** **1 Updated Docs Generator** (Python)
**+** **4 Updated Build Workflows** (LuaJIT only)

= **Complete Automated Release System** ✅

Every mod push → Auto-versioned → Packaged → Released → Documented
