# New Mod Submission

## Mod Information

**Mod Name**: <!-- e.g., "Double Bandwidth Switches" -->

**Mod ID (folder name)**: <!-- e.g., "2x-bandwidth-switches" -->

**Description**: 
<!-- Provide a brief description of what your mod does -->

## Required Files Checklist

Your mod folder (`lua/<mod-id>/`) must contain the following files:

- [ ] `entry.lua` - Main mod entry point
- [ ] `metadata.yaml` - Mod metadata (see schema below)
- [ ] `README.md` - Documentation for users

## Metadata Validation

I confirm that my `metadata.yaml` file:

- [ ] Contains all **required fields**:
  - [ ] `Name` - Pretty display name
  - [ ] `Description` - Markdown description
  - [ ] `Author` - Your name/handle
  - [ ] `Version` - Semantic version (e.g., "1.0.0")
  - [ ] `Creation Date` - YYYY-MM-DD format
  - [ ] `Last Updated` - YYYY-MM-DD format
  - [ ] `Development Status` - One of: "Active Development", "Maintenance only", "Discontinued", "Defunct"
  - [ ] `Game Version Supported` - e.g., "stable", "1.0.0", "1.0.0-1.2.0"
  - [ ] `ID` - Matches the folder name
- [ ] Is valid YAML syntax
- [ ] Follows the [mod-metadata-schema.yaml](https://github.com/CJFWeatherhead/TNI-Mods/blob/main/mod-metadata-schema.yaml)
- [ ] Has properly defined `Parameters` (if the mod is configurable)

## Mod Details

### What does this mod do?
<!-- Detailed explanation of the mod's functionality -->

### How is it used?
<!-- How do users interact with or configure the mod? -->

### Which callbacks/hooks does it use?
<!-- List the ModAPI callbacks your mod uses, e.g., on_device_spawned, on_day_changed -->
- 
- 

## Testing

- [ ] Tested with the latest game version
- [ ] Tested with ModManager
- [ ] Tested without other mods (to ensure no conflicts)
- [ ] Tested with other common mods (list which ones):
  - 

### Game Version Tested
<!-- e.g., stable, 1.0.0 -->

## License & Intellectual Property

> **Important**: All contributions to this repository are licensed under the [BSD 3-Clause License](https://github.com/CJFWeatherhead/TNI-Mods/blob/main/LICENSE).

- [ ] **I confirm that I have read and accept the BSD 3-Clause License terms**, including:
  - Redistribution of source code must retain copyright notice and license
  - Redistribution in binary form must reproduce the license in documentation
  - My name/the project name cannot be used to endorse derived products without permission

- [ ] **I confirm that I own the intellectual property** for this mod, OR I have explicit permission from the original creator to submit it to this repository

- [ ] **I understand** that by submitting this mod, I am granting permission for it to be:
  - Redistributed as part of this repository
  - Downloaded and used by others under the BSD 3-Clause License
  - Modified by maintainers if necessary for compatibility

### Attribution (if applicable)
<!-- If this mod is based on someone else's work, or you have permission to submit it, provide details -->

## Screenshots / Demo
<!-- Add screenshots or GIFs showing your mod in action (if applicable) -->

## Additional Notes
<!-- Any other information reviewers should know -->

---

## Reviewer Checklist (for maintainers)

- [ ] All required files present (`entry.lua`, `metadata.yaml`, `README.md`)
- [ ] `metadata.yaml` validates against schema
- [ ] Mod ID is unique and follows naming conventions
- [ ] Code quality is acceptable
- [ ] No malicious or inappropriate content
- [ ] License acknowledgment confirmed
- [ ] Tested and working
