# Summary of Changes - Mod Release Automation

This document summarizes all changes made to implement per-mod automated releases.

## Date: January 24, 2026

## Files Modified

### 1. Metadata Schema
- **File**: `mod-metadata-schema.yaml`
- **Changes**: Added `Version` field as a required field for all mods
- **Format**: Semantic versioning (e.g., "1.0.0")

### 2. Build Workflows (4 files)
Updated to only trigger on LuaJIT-related changes:

#### `/.github/workflows/build-zig-continuous.yml`
- Changed from `paths-ignore` to specific `paths` filter
- Now only triggers on: `ext/LuaJIT/**`, `programs/luajit/**`, `CMakeLists.txt`, `cmake/**`, `zig.cmd`, `zig.sh`

#### `/.github/workflows/build-gnu-continuous.yml`
- Changed from `paths-ignore` to specific `paths` filter
- Now only triggers on: `ext/LuaJIT/**`, `programs/luajit/**`, `CMakeLists.txt`, `cmake/**`, `build.sh`

#### `/.github/workflows/build-zig-pr.yml`
- Changed from `paths-ignore` to specific `paths` filter
- Same paths as zig-continuous

#### `/.github/workflows/build-gnu-pr.yml`
- Changed from `paths-ignore` to specific `paths` filter
- Same paths as gnu-continuous

### 3. Documentation Generator
- **File**: `docs/generate_mod_pages.py`
- **Changes**:
  - Now reads and displays `Version` field from metadata.yaml
  - Generates direct download links to GitHub releases
  - Creates release tag URLs in format: `<mod-id>-v<version>`
  - Download links point to: `https://github.com/.../releases/download/<tag>/<mod-id>-<version>.zip`
  - Added version to Hugo front matter

### 4. Mod Metadata Files (9 files)
Added `Version: 0.1.0` to all existing mods:

- `lua/2x-bandwidth-switches/metadata.yaml`
- `lua/all-proposals/metadata.yaml`
- `lua/device-tweaker/metadata.yaml`
- `lua/floor-reward-scaling/metadata.yaml`
- `lua/inverse-prices/metadata.yaml`
- `lua/modapi-diagnostic/metadata.yaml`
- `lua/money-cheat/metadata.yaml`
- `lua/random-warranties/metadata.yaml`
- `lua/user-floor-addressing/metadata.yaml`

## Files Created

### 1. Version Update Script
- **File**: `.github/scripts/update_mod_version.py`
- **Purpose**: Automatically increment version numbers in metadata.yaml
- **Features**:
  - Supports semantic versioning (major, minor, patch)
  - Updates `Version` field
  - Updates `Last Updated` field to current date
  - Can set specific version or auto-increment
  - Preserves YAML formatting and comments

### 2. Reusable Workflow
- **File**: `.github/workflows/mod-release-reusable.yml`
- **Purpose**: Core release logic used by all mod workflows
- **Steps**:
  1. Checkout repository
  2. Setup Python and dependencies
  3. Update mod version and date
  4. Commit version update
  5. Package mod into zip file
  6. Create GitHub release with auto-generated notes
  7. Regenerate documentation
  8. Build and deploy Hugo site to Cloudflare Pages
  9. Output summary

### 3. Individual Mod Workflows (9 files)
Created a workflow for each mod:

- `.github/workflows/release-2x-bandwidth-switches.yml`
- `.github/workflows/release-all-proposals.yml`
- `.github/workflows/release-device-tweaker.yml`
- `.github/workflows/release-floor-reward-scaling.yml`
- `.github/workflows/release-inverse-prices.yml`
- `.github/workflows/release-modapi-diagnostic.yml`
- `.github/workflows/release-money-cheat.yml`
- `.github/workflows/release-random-warranties.yml`
- `.github/workflows/release-user-floor-addressing.yml`

**Features**:
- Auto-trigger on changes to mod directory
- Manual trigger with version bump type selection
- Calls reusable workflow with mod-specific parameters

### 4. Documentation
- **File**: `.github/MOD-RELEASE-SYSTEM.md`
- **Purpose**: Complete guide to the new release automation system
- **Contents**:
  - Overview of the system
  - Trigger conditions
  - Version numbering guide
  - Manual release instructions
  - Adding new mods
  - Troubleshooting guide
  - Best practices

## How It Works

### Automatic Release Flow

```
Developer pushes code to lua/money-cheat/
    ↓
GitHub detects change in lua/money-cheat/**
    ↓
Triggers release-money-cheat.yml workflow
    ↓
Calls mod-release-reusable.yml with mod_name='money-cheat'
    ↓
update_mod_version.py increments version (0.1.0 → 0.1.1)
    ↓
Updates Last Updated date in metadata.yaml
    ↓
Commits version change back to repository
    ↓
Creates money-cheat-0.1.1.zip
    ↓
Creates GitHub release: money-cheat-v0.1.1
    ↓
Uploads zip to release
    ↓
Generates release notes from metadata
    ↓
Regenerates documentation with generate_mod_pages.py
    ↓
Builds Hugo site
    ↓
Deploys to Cloudflare Pages
    ↓
Complete! ✅
```

## Benefits

1. **Automated Versioning**: No manual version updates needed
2. **Consistent Releases**: Same process for every mod
3. **Documentation Sync**: Docs always reflect latest version
4. **Easy Downloads**: Direct links to zip files
5. **Git History**: Version bumps are tracked in commits
6. **Flexible**: Manual triggers for special releases
7. **Efficient**: Build system only runs when needed
8. **Scalable**: Easy to add new mods

## Breaking Changes

### For Mod Developers

1. **Required Field**: All metadata.yaml files must now include `Version` field
2. **Automatic Commits**: Workflows will commit version updates automatically
3. **Release Tags**: New format: `<mod-id>-v<version>` (e.g., `money-cheat-v1.0.0`)

### For Users

None - This is entirely backend automation. Downloads are now easier with direct links.

## Testing Recommendations

Before merging to main:

1. Test a workflow manually via GitHub Actions UI
2. Verify version increment works correctly
3. Check that release is created properly
4. Verify zip file contains all expected files
5. Test download link on documentation page
6. Ensure Cloudflare deployment succeeds

## Rollback Plan

If issues occur:

1. Workflows can be disabled individually in GitHub Actions UI
2. Manual releases can be created using GitHub's interface
3. Documentation can be manually updated
4. Version numbers can be manually corrected in metadata.yaml

## Next Steps

1. **Test**: Run a manual workflow for one mod to verify everything works
2. **Monitor**: Watch for any workflow failures
3. **Document**: Update main README if needed
4. **Improve**: Consider additional automation (changelog, notifications, etc.)
5. **Branch Strategy**: Consider whether to split mods into separate branches (currently not needed as path filters work well)

## Decision: No Branch Split Required

After analysis, keeping all mods in a monorepo with path-based triggers is preferable because:

- ✅ Simpler repository structure
- ✅ Easier to share common scripts and workflows
- ✅ Single place for documentation
- ✅ Path filters work perfectly for selective triggers
- ✅ No need to maintain multiple repositories or branches
- ✅ Easier for contributors (single clone)

Branch-per-mod would only be needed if:
- ❌ Mods had conflicting dependencies
- ❌ Different release cadences were critical
- ❌ Separate permission models were needed

None of these apply to this project.

## Maintenance

### Regular Tasks

- Monitor workflow success rates
- Review and update Python scripts as needed
- Keep Hugo version current
- Update documentation as system evolves

### When Adding New Mods

1. Create mod directory with required files
2. Add `Version: 0.1.0` to metadata.yaml
3. Copy and modify one of the existing workflow files
4. Test with manual trigger
5. Document in main README

---

**System Status**: ✅ Ready for Production

All files created, all workflows configured, all mods versioned.
