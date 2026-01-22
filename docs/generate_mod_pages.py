#!/usr/bin/env python3
"""
Generate Hugo content pages for each mod from their metadata.yaml files
"""
import os
import yaml
from pathlib import Path
from datetime import datetime

# Paths - determine repository root dynamically
SCRIPT_DIR = Path(__file__).parent.resolve()
REPO_ROOT = SCRIPT_DIR.parent
LUA_DIR = REPO_ROOT / 'lua'
DOCS_CONTENT_DIR = SCRIPT_DIR / 'content' / 'mods'

def load_yaml(filepath):
    """Load YAML file"""
    try:
        with open(filepath, 'r') as f:
            return yaml.safe_load(f)
    except yaml.scanner.ScannerError as e:
        print(f"Error parsing YAML in {filepath}: {e}")
        # Return minimal metadata to allow continuing
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
    with open(filepath, 'r') as f:
        return f.read()

def generate_mod_page(mod_dir):
    """Generate a Hugo page for a mod"""
    mod_name = mod_dir.name
    
    # Skip special directories
    if mod_name.startswith('.') or mod_name == 'README.md':
        return
    
    metadata_file = mod_dir / 'metadata.yaml'
    readme_file = mod_dir / 'README.md'
    
    if not metadata_file.exists():
        print(f"Warning: No metadata.yaml found for {mod_name}")
        return
    
    # Load metadata
    metadata = load_yaml(metadata_file)
    
    # Load README content
    readme_content = load_markdown(readme_file)
    
    # Extract metadata fields with defaults
    today = datetime.now().strftime('%Y-%m-%d')
    title = metadata.get('Name', mod_name)
    description = metadata.get('Description', '')
    author = metadata.get('Author', 'Unknown')
    creation_date = metadata.get('Creation Date', today)
    last_updated = metadata.get('Last Updated', creation_date)
    status = metadata.get('Development Status', 'Unknown')
    game_version = metadata.get('Game Version Supported', 'Unknown')
    mod_id = metadata.get('ID', mod_name)
    website = metadata.get('Website', '')
    dependencies = metadata.get('Dependencies', [])
    notes = metadata.get('Notes', '')
    parameters = metadata.get('Parameters', [])
    
    # Generate Hugo front matter
    front_matter = f"""---
title: "{title}"
date: {last_updated}
draft: false
mod_id: "{mod_id}"
author: "{author}"
status: "{status}"
game_version: "{game_version}"
---

"""
    
    # Generate page content
    content = front_matter
    
    # Add header
    content += f"# {title}\n\n"
    
    # Add description
    if description:
        content += f"{description}\n\n"
    
    # Add metadata section
    content += "## Mod Information\n\n"
    content += f"- **Author**: {author}\n"
    content += f"- **Development Status**: {status}\n"
    content += f"- **Game Version**: {game_version}\n"
    content += f"- **Last Updated**: {last_updated}\n"
    
    if website:
        content += f"- **Website**: [{website}]({website})\n"
    
    if dependencies:
        content += f"- **Dependencies**: {', '.join(dependencies)}\n"
    
    content += "\n"
    
    # Add download section
    content += "## Download\n\n"
    content += f"**[Download {title}](https://github.com/CJFWeatherhead/TNI-Mods/tree/main/lua/{mod_id})**\n\n"
    content += "### Installation Instructions\n\n"
    content += "1. Download or clone this repository\n"
    content += f"2. Copy the `lua/{mod_id}/` folder to your game's mods directory:\n"
    content += "   - Windows: `%APPDATA%\\Godot\\app_userdata\\Tower Networking Inc\\mods\\`\n"
    content += "   - Linux: `~/.local/share/godot/app_userdata/Tower Networking Inc/mods/`\n"
    content += "3. Ensure you have [luajit.elf](https://github.com/CJFWeatherhead/TNI-Mods/releases) installed\n"
    content += "4. Enable and configure using [ModManagerGUI.ps1](/mods/tools/modmanager/)\n\n"
    
    # Add configuration section if parameters exist
    if parameters:
        content += "## Configuration Parameters\n\n"
        content += "This mod can be configured using the [Mod Manager](/mods/tools/modmanager/). Available parameters:\n\n"
        
        for param in parameters:
            param_name = param.get('Name', 'Unknown')
            param_label = param.get('Label', param_name)
            param_type = param.get('Type', 'unknown')
            param_default = param.get('Default', '')
            param_desc = param.get('Description', '')
            
            content += f"### {param_label}\n\n"
            content += f"- **Parameter Name**: `{param_name}`\n"
            content += f"- **Type**: {param_type}\n"
            content += f"- **Default**: `{param_default}`\n"
            
            if param_type in ['integer', 'number']:
                param_min = param.get('Min', '')
                param_max = param.get('Max', '')
                if param_min != '':
                    content += f"- **Min**: {param_min}\n"
                if param_max != '':
                    content += f"- **Max**: {param_max}\n"
            
            if param_type == 'select':
                options = param.get('Options', [])
                if options:
                    content += f"- **Options**: {', '.join(f'`{opt}`' for opt in options)}\n"
            
            if param_desc:
                content += f"\n{param_desc}\n"
            
            content += "\n"
    
    # Add README content if available
    if readme_content:
        content += "---\n\n"
        content += "## Detailed Documentation\n\n"
        content += readme_content
        content += "\n"
    
    # Add notes if available
    if notes:
        content += "\n---\n\n"
        content += f"## Additional Notes\n\n{notes}\n"
    
    # Add back to mods link
    content += "\n---\n\n"
    content += "[← Back to All Mods](/mods/)\n"
    
    # Write the Hugo page
    output_file = DOCS_CONTENT_DIR / f"{mod_id}.md"
    with open(output_file, 'w') as f:
        f.write(content)
    
    print(f"Generated page for: {title} ({mod_id})")

def main():
    """Main function"""
    print("Generating mod pages from metadata...")
    
    # Ensure output directory exists
    DOCS_CONTENT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Process each mod directory
    for item in LUA_DIR.iterdir():
        if item.is_dir():
            generate_mod_page(item)
    
    print("\nMod pages generated successfully!")

if __name__ == '__main__':
    main()
