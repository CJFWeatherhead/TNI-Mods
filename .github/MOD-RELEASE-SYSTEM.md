# Mod Release Automation System

This document explains the automated release system for mods in the TNI-Mods repository.

## Overview

Each mod in the `/lua` directory now has its own individual GitHub Actions workflow that automatically:

1. **Increments the version number** in `metadata.yaml` (using semantic versioning)
2. **Updates the last modified date** to the current date
3. **Packages the mod** into a versioned zip file
4. **Creates a GitHub release** with the packaged mod
5. **Regenerates documentation** with download links to the latest release
6. **Deploys updated docs** to Cloudflare Pages

## Trigger Conditions

Workflows trigger automatically when:
- Changes are pushed to `main` or `beta` branches
- The changes affect files in the specific mod's directory (e.g., `lua/money-cheat/**`)

Workflows can also be triggered manually via the GitHub Actions UI with a choice of version bump type.

## Version Numbering

Mods use [Semantic Versioning](https://semver.org/):
- **MAJOR** (X.0.0): Breaking changes or complete rewrites
- **MINOR** (0.X.0): New features, backward compatible
- **PATCH** (0.0.X): Bug fixes, minor tweaks (default)

### Version Field in metadata.yaml

All mods must now include a `Version` field in their `metadata.yaml`:

```yaml
Name: My Awesome Mod
Description: Does cool things
Author: YourName
Version: 1.2.3
Creation Date: 2026-01-01
Last Updated: 2026-01-24
...
```

## Workflow Files

### Individual Mod Workflows

Each mod has its own workflow file in `.github/workflows/`:

- `release-2x-bandwidth-switches.yml`
- `release-all-proposals.yml`
- `release-device-tweaker.yml`
- `release-floor-reward-scaling.yml`
- `release-inverse-prices.yml`
- `release-modapi-diagnostic.yml`
- `release-money-cheat.yml`
- `release-random-warranties.yml`
- `release-user-floor-addressing.yml`

### Reusable Workflow

The core logic is in `.github/workflows/mod-release-reusable.yml`, which all mod workflows call.

## Manual Releases

You can manually trigger a release for any mod:

1. Go to **Actions** tab in GitHub
2. Select the mod's release workflow (e.g., "Release money-cheat")
3. Click **Run workflow**
4. Choose the version bump type:
   - `patch` - Bug fixes (0.0.X)
   - `minor` - New features (0.X.0)
   - `major` - Breaking changes (X.0.0)
5. Click **Run workflow**

## Build System Workflows

The existing build workflows (`build-zig-continuous.yml`, `build-gnu-continuous.yml`, etc.) have been updated to **only** trigger when LuaJIT-related files change:

- `ext/LuaJIT/**`
- `programs/luajit/**`
- `CMakeLists.txt`
- `cmake/**`
- Build scripts (`build.sh`, `zig.cmd`, etc.)

This prevents unnecessary builds when only mod files are updated.

## Release Artifacts

Each release includes:

1. **Zip File**: `<mod-name>-<version>.zip`
   - Contains all mod files (entry.lua, metadata.yaml, README.md, etc.)
   - Ready to extract directly into the game's mods folder

2. **Release Notes**: Auto-generated from metadata.yaml
   - Mod description
   - Installation instructions
   - Link to mod documentation page

## Documentation Updates

The `docs/generate_mod_pages.py` script has been enhanced to:

- Read the `Version` field from metadata.yaml
- Generate download links to the latest GitHub release
- Include version information in the mod page

Example output on the docs site:

```markdown
## Download

### Latest Release: v1.2.3

**[📦 Download money-cheat-1.2.3.zip](https://github.com/.../releases/download/money-cheat-v1.2.3/money-cheat-1.2.3.zip)**

[View all releases on GitHub →](https://github.com/.../releases/tag/money-cheat-v1.2.3)
```

## Version Update Script

The Python script `.github/scripts/update_mod_version.py` handles version increments:

```bash
# Increment patch version (0.0.X)
python update_mod_version.py lua/money-cheat/metadata.yaml patch

# Increment minor version (0.X.0)
python update_mod_version.py lua/money-cheat/metadata.yaml minor

# Increment major version (X.0.0)
python update_mod_version.py lua/money-cheat/metadata.yaml major

# Set specific version
python update_mod_version.py lua/money-cheat/metadata.yaml 2.5.1
```

## Adding a New Mod

To add a new mod to the release system:

1. **Create the mod directory** in `/lua/<mod-name>/`

2. **Add required files**:
   - `entry.lua` - Main mod code
   - `metadata.yaml` - Must include `Version: 0.1.0`
   - `README.md` - Documentation

3. **Create a workflow file** `.github/workflows/release-<mod-name>.yml`:

```yaml
name: Release <mod-name>

on:
  push:
    branches:
      - main
      - beta
    paths:
      - 'lua/<mod-name>/**'
  workflow_dispatch:
    inputs:
      bump_type:
        description: 'Version bump type'
        required: false
        default: 'patch'
        type: choice
        options:
          - patch
          - minor
          - major

jobs:
  release:
    uses: ./.github/workflows/mod-release-reusable.yml
    with:
      mod_name: '<mod-name>'
      bump_type: ${{ inputs.bump_type || 'patch' }}
    secrets:
      CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

4. **Push changes** - The first release will be created automatically!

## Secrets Required

The workflows require these GitHub repository secrets:

- `CLOUDFLARE_API_TOKEN` - For deploying docs to Cloudflare Pages
- `CLOUDFLARE_ACCOUNT_ID` - Your Cloudflare account ID
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

## Best Practices

### Commit Messages

When making changes to mods, use clear commit messages:

```
feat(money-cheat): add notification on money addition
fix(device-tweaker): correct bandwidth calculation
docs(random-warranties): update parameter descriptions
```

### Version Bumping

- **Patch** (default): Bug fixes, typos, minor tweaks
- **Minor**: New features, new parameters, enhancements
- **Major**: Breaking changes, complete rewrites, API changes

### Testing

Before pushing changes:

1. Test the mod locally
2. Update the README.md if needed
3. Consider if this warrants a minor or major version bump
4. Push and let automation handle the release

## Troubleshooting

### Workflow doesn't trigger

- Check that files were modified in `lua/<mod-name>/`
- Ensure you pushed to `main` or `beta` branch
- Verify the workflow file exists and has correct paths

### Version not incrementing

- Check `.github/scripts/update_mod_version.py` for errors
- Ensure `metadata.yaml` has proper YAML formatting
- Look at the workflow logs in GitHub Actions

### Release creation fails

- Verify `GITHUB_TOKEN` has proper permissions
- Check for existing release with same tag (shouldn't happen, but workflow handles it)
- Review the workflow logs for specific errors

## Future Improvements

Potential enhancements to consider:

- [ ] Automated testing before release
- [ ] Changelog generation from commits
- [ ] Release notifications (Discord, email, etc.)
- [ ] Automated compatibility checking
- [ ] Branch-based versioning (beta releases with `-beta.1` suffix)
- [ ] Rollback mechanism for failed releases

## Questions?

For issues or questions about the release system:

1. Check the workflow logs in GitHub Actions
2. Review this documentation
3. Open an issue in the repository
4. Check existing releases to see examples
