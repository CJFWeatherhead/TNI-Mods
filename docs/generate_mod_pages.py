#!/usr/bin/env python3
"""
Generate Hugo content pages for each mod from their metadata.yaml files.
Includes auto-generated index page and individual mod pages with improved UX.

Features:
- Auto-generated index page with sortable mod table
- Clean, accessible individual mod pages
- Collapsible sections for detailed information
- Download buttons with clear CTAs
- Responsive table layouts
"""
import os
import yaml
from pathlib import Path
from datetime import datetime

# Paths - determine repository root dynamically
SCRIPT_DIR = Path(__file__).parent.resolve()
REPO_ROOT = SCRIPT_DIR.parent
LUA_DIR = REPO_ROOT / 'mods'
DOCS_CONTENT_DIR = SCRIPT_DIR / 'content' / 'mods'

# GitHub repository
GITHUB_REPO = "CJFWeatherhead/TNI-Mods"

# Status display mapping
STATUS_INFO = {
    'Active Development': {'icon': '🟢', 'label': 'Active', 'priority': 1},
    'Maintenance only': {'icon': '🟡', 'label': 'Maintenance', 'priority': 2},
    'Discontinued': {'icon': '🔴', 'label': 'Discontinued', 'priority': 3},
    'Defunct': {'icon': '⚫', 'label': 'Defunct', 'priority': 4},
    'Unknown': {'icon': '⚪', 'label': 'Unknown', 'priority': 5}
}


def load_yaml(filepath):
    """Load YAML file with error handling"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except yaml.scanner.ScannerError as e:
        print(f"Error parsing YAML in {filepath}: {e}")
        today = datetime.now().strftime('%Y-%m-%d')
        return {
            'Name': filepath.parent.name,
            'ID': filepath.parent.name,
            'Description': 'Error loading description from metadata.yaml',
            'Author': 'Unknown',
            'Creation Date': today,
            'Last Updated': today,
            'Development Status': 'Unknown',
            'Game Version Supported': 'Unknown'
        }


def load_markdown(filepath):
    """Load markdown file"""
    if not filepath.exists():
        return ""
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()


def get_first_paragraph(description):
    """Extract the first paragraph/sentence for brief description"""
    if not description:
        return ""
    # Handle multi-line YAML descriptions
    lines = description.strip().split('\n')
    first_line = lines[0].strip()
    # Remove markdown headers if present
    if first_line.startswith('#'):
        first_line = lines[1].strip() if len(lines) > 1 else ""
    # Truncate if too long
    if len(first_line) > 150:
        first_line = first_line[:147] + "..."
    return first_line


def generate_index_page(mods):
    """Generate the _index.md page with mod listing table"""
    today = datetime.now().strftime('%Y-%m-%d')
    
    content = f"""---
title: "Available Mods"
date: {today}
draft: false
---

# Mods for Tower Networking Inc

Browse and download community-created mods. All mods are open-source Lua scripts that are easy to install and configure.

<div class="mod-quick-start">

## Quick Start

1. Download the **[Mod Manager](/mods/tools/modmanager/)** (recommended)
2. Browse mods below and click to install
3. Or manually download from [GitHub Releases](https://github.com/{GITHUB_REPO}/releases)

**Requirement:** All Lua mods need [luajit.elf](https://github.com/{GITHUB_REPO}/releases) in your mods folder.

</div>

---

## Available Mods

| Mod | Description | Version | Author | Status | Download |
|-----|-------------|---------|--------|--------|----------|
"""
    
    # Add each mod to the table
    for mod in mods:
        status_info = STATUS_INFO.get(mod['status'], STATUS_INFO['Unknown'])
        status_display = f"{status_info['icon']} {status_info['label']}"
        
        # Construct download URL
        release_tag = f"{mod['id']}-v{mod['version']}"
        download_url = f"https://github.com/{GITHUB_REPO}/releases/download/{release_tag}/{mod['id']}-{mod['version']}.zip"
        
        # Create table row
        content += f"| **[{mod['name']}](/mods/{mod['id']}/)** | {mod['description']} | `{mod['version']}` | {mod['author']} | {status_display} | <a href=\"{download_url}\" class=\"button inline\">Download</a> |\n"
    
    content += f"""
---

## Installation

<details>
<summary><strong>Option 1: Mod Manager (Recommended)</strong></summary>

The easiest way to manage mods:

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Run the application
3. Browse available mods and click **Download**
4. Configure settings through the GUI
5. Launch the game!

</details>

<details>
<summary><strong>Option 2: Manual Installation</strong></summary>

1. Download the mod zip from its page or [GitHub releases](https://github.com/{GITHUB_REPO}/releases)
2. Extract to your mods folder:
   - **Windows:** `%APPDATA%\\Godot\\app_userdata\\Tower Networking Inc\\mods\\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure `luajit.elf` is also in the mods folder
4. Launch the game

</details>

---

## Create Your Own Mods

Interested in modding? Check out the [GitHub repository](https://github.com/{GITHUB_REPO}) for development guides, templates, and API documentation.

---

*Last updated: {today} | {len(mods)} mods available*
"""
    
    output_file = DOCS_CONTENT_DIR / "_index.md"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Generated index page with {len(mods)} mods")


def generate_mod_page(mod_dir):
    """Generate an individual mod page with improved UX"""
    mod_name = mod_dir.name
    
    # Skip special directories
    if mod_name.startswith('.') or mod_name == 'README.md':
        return None
    
    metadata_file = mod_dir / 'metadata.yaml'
    readme_file = mod_dir / 'README.md'
    
    if not metadata_file.exists():
        print(f"Warning: No metadata.yaml found for {mod_name}")
        return None
    
    # Load data
    metadata = load_yaml(metadata_file)
    readme_content = load_markdown(readme_file)
    
    # Extract fields
    today = datetime.now().strftime('%Y-%m-%d')
    title = metadata.get('Name', mod_name)
    description = metadata.get('Description', '')
    author = metadata.get('Author', 'Unknown')
    version = metadata.get('Version', '0.1.0')
    creation_date = metadata.get('Creation Date', today)
    last_updated = metadata.get('Last Updated', creation_date)
    status = metadata.get('Development Status', 'Unknown')
    game_version = metadata.get('Game Version Supported', 'Unknown')
    mod_id = metadata.get('ID', mod_name)
    website = metadata.get('Website', '')
    dependencies = metadata.get('Dependencies', [])
    notes = metadata.get('Notes', '')
    parameters = metadata.get('Parameters', [])
    
    # URLs
    release_tag = f"{mod_id}-v{version}"
    release_url = f"https://github.com/{GITHUB_REPO}/releases/tag/{release_tag}"
    download_url = f"https://github.com/{GITHUB_REPO}/releases/download/{release_tag}/{mod_id}-{version}.zip"
    all_releases_url = f"https://github.com/{GITHUB_REPO}/releases"
    
    # Status info
    status_info = STATUS_INFO.get(status, STATUS_INFO['Unknown'])
    
    # Build page content
    content = f"""---
title: "{title}"
date: {last_updated}
draft: false
mod_id: "{mod_id}"
author: "{author}"
version: "{version}"
status: "{status}"
game_version: "{game_version}"
---

# {title}

{get_first_paragraph(description)}

<div class="mod-header-info">

| | |
|---|---|
| **Version** | {version} |
| **Author** | {author} |
| **Status** | {status_info['icon']} {status} |
| **Game Version** | {game_version} |
| **Last Updated** | {last_updated} |

</div>

---

## Download

<div class="download-section">

**[Download {mod_id}-{version}.zip]({download_url})** | [All Releases]({all_releases_url})

</div>

<details>
<summary><strong>Installation Instructions</strong></summary>

### Using Mod Manager (Recommended)

1. Download the [Mod Manager](/mods/tools/modmanager/)
2. Find **{title}** in the Available mods list
3. Click **Download** to install automatically
4. Configure parameters in the GUI

### Manual Installation

1. Download the zip file above
2. Extract the `{mod_id}/` folder to your mods directory:
   - **Windows:** `%APPDATA%\\Godot\\app_userdata\\Tower Networking Inc\\mods\\`
   - **Linux:** `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`
3. Ensure [luajit.elf]({all_releases_url}) is in the mods directory

</details>

"""
    
    # Configuration parameters section
    if parameters:
        content += """---

## Configuration

Configure these settings using the [Mod Manager](/mods/tools/modmanager/) or edit `entry.lua` directly.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
"""
        for param in parameters:
            param_name = param.get('Name', 'Unknown')
            param_label = param.get('Label', param_name)
            param_type = param.get('Type', 'unknown')
            param_default = param.get('Default', '')
            param_desc = param.get('Description', '')
            
            # Add range info for numeric types
            type_display = param_type
            if param_type in ['integer', 'number']:
                param_min = param.get('Min', '')
                param_max = param.get('Max', '')
                if param_min != '' and param_max != '':
                    type_display = f"{param_type} ({param_min}-{param_max})"
            elif param_type == 'select':
                options = param.get('Options', [])
                if options:
                    type_display = f"select: {', '.join(options)}"
            
            content += f"| **{param_label}** | {type_display} | `{param_default}` | {param_desc} |\n"
        
        content += "\n"
    
    # Full description (if multi-line)
    full_desc = description.strip()
    brief_desc = get_first_paragraph(description)
    if full_desc != brief_desc and len(full_desc) > len(brief_desc) + 20:
        content += f"""---

## About This Mod

{full_desc}

"""
    
    # README content (collapsible if long)
    if readme_content:
        # Check if README is substantial
        readme_lines = readme_content.strip().split('\n')
        if len(readme_lines) > 30:
            content += """---

<details>
<summary><strong>Full Documentation</strong></summary>

"""
            content += readme_content
            content += """

</details>

"""
        else:
            content += f"""---

## Documentation

{readme_content}

"""
    
    # Additional notes
    if notes:
        content += f"""---

<details>
<summary><strong>Additional Notes</strong></summary>

{notes}

</details>

"""
    
    # Metadata details (collapsible)
    content += f"""---

<details>
<summary><strong>Technical Details</strong></summary>

| Field | Value |
|-------|-------|
| Mod ID | `{mod_id}` |
| Creation Date | {creation_date} |
| Last Updated | {last_updated} |
| Game Version | {game_version} |
| Dependencies | {', '.join(dependencies) if dependencies else 'None'} |
"""
    if website:
        content += f"| Website | [{website}]({website}) |\n"
    
    content += f"""
**Release URLs:**
- [Latest Release]({release_url})
- [Direct Download]({download_url})

</details>

---

[Back to All Mods](/mods/)
"""
    
    # Write the file
    output_file = DOCS_CONTENT_DIR / f"{mod_id}.md"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Generated page: {title} ({mod_id})")
    
    return {
        'name': title,
        'id': mod_id,
        'description': get_first_paragraph(description),
        'author': author,
        'version': version,
        'status': status,
        'last_updated': last_updated,
        'game_version': game_version,
    }


def main():
    """Main function"""
    print("Generating mod pages from metadata...")
    print(f"Source: {LUA_DIR}")
    print(f"Output: {DOCS_CONTENT_DIR}")
    print()
    
    # Ensure output directory exists
    DOCS_CONTENT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Collect all mod info and generate individual pages
    mods = []
    for item in sorted(LUA_DIR.iterdir()):
        if item.is_dir():
            mod_info = generate_mod_page(item)
            if mod_info:
                mods.append(mod_info)
    
    print()
    
    # Sort mods by status priority, then name
    mods.sort(key=lambda m: (
        STATUS_INFO.get(m['status'], STATUS_INFO['Unknown'])['priority'],
        m['name'].lower()
    ))
    
    # Generate index page
    generate_index_page(mods)
    
    print(f"\nSuccess! Generated {len(mods)} mod pages + index")


if __name__ == '__main__':
    main()
