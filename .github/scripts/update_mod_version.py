#!/usr/bin/env python3
"""
Update mod version and last modified date in metadata.yaml
Supports semantic versioning with auto-increment
"""
import sys
import yaml
from pathlib import Path
from datetime import datetime
import re


def load_yaml_preserving_order(filepath):
    """Load YAML file preserving order and comments"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    return content, yaml.safe_load(content)


def increment_version(version_str, bump_type='patch'):
    """
    Increment semantic version
    bump_type: 'major', 'minor', or 'patch' (default)
    """
    # Parse version (handle versions like "1.0.0" or just "1.0")
    match = re.match(r'(\d+)\.(\d+)(?:\.(\d+))?', version_str)
    if not match:
        # If no version or invalid format, start at 1.0.0
        return '1.0.0'
    
    major, minor, patch = match.groups()
    major = int(major)
    minor = int(minor)
    patch = int(patch) if patch else 0
    
    if bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
    elif bump_type == 'minor':
        minor += 1
        patch = 0
    else:  # patch
        patch += 1
    
    return f"{major}.{minor}.{patch}"


def update_metadata_yaml(filepath, bump_type='patch', new_version=None):
    """
    Update version and last modified date in metadata.yaml
    
    Args:
        filepath: Path to metadata.yaml
        bump_type: 'major', 'minor', or 'patch'
        new_version: Specific version to set (overrides bump_type)
    
    Returns:
        tuple: (old_version, new_version)
    """
    filepath = Path(filepath)
    
    if not filepath.exists():
        raise FileNotFoundError(f"metadata.yaml not found at {filepath}")
    
    # Load the file
    content, metadata = load_yaml_preserving_order(filepath)
    
    # Get current version or default to 0.1.0
    old_version = metadata.get('Version', '0.1.0')
    
    # Calculate new version
    if new_version:
        new_version_str = new_version
    else:
        new_version_str = increment_version(old_version, bump_type)
    
    # Get today's date
    today = datetime.now().strftime('%Y-%m-%d')
    
    # Update the content string preserving formatting
    # Update Version field (add if doesn't exist)
    version_pattern = re.compile(r'^Version:\s*(.+)$', re.MULTILINE)
    if version_pattern.search(content):
        content = version_pattern.sub(f'Version: {new_version_str}', content)
    else:
        # Add Version after Author line
        author_pattern = re.compile(r'(^Author:\s*.+$)', re.MULTILINE)
        content = author_pattern.sub(rf'\1\nVersion: {new_version_str}', content)
    
    # Update Last Updated field
    last_updated_pattern = re.compile(r'^Last Updated:\s*(.+)$', re.MULTILINE)
    if last_updated_pattern.search(content):
        content = last_updated_pattern.sub(f'Last Updated: {today}', content)
    else:
        # This should not happen if metadata follows schema, but handle it
        creation_pattern = re.compile(r'(^Creation Date:\s*.+$)', re.MULTILINE)
        content = creation_pattern.sub(rf'\1\nLast Updated: {today}', content)
    
    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Also update mod.jsonc if it exists in the same directory
    jsonc_path = filepath.parent / 'mod.jsonc'
    if jsonc_path.exists():
        update_mod_jsonc_version(jsonc_path, new_version_str)
    
    return old_version, new_version_str


def update_mod_jsonc_version(filepath, new_version):
    """
    Update the version field in a mod.jsonc file, preserving comments and formatting.
    """
    filepath = Path(filepath)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace the "version": "x.y.z" line, preserving surrounding whitespace/formatting
    version_pattern = re.compile(r'("version"\s*:\s*)"[^"]*"')
    if version_pattern.search(content):
        content = version_pattern.sub(rf'\1"{new_version}"', content)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  Also updated {filepath} -> {new_version}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python update_mod_version.py <metadata_yaml_path> [bump_type|version]")
        print("  bump_type: major, minor, or patch (default: patch)")
        print("  version: specific version like 2.1.0")
        sys.exit(1)
    
    metadata_path = sys.argv[1]
    
    # Determine if second arg is bump type or specific version
    if len(sys.argv) >= 3:
        arg = sys.argv[2]
        if arg in ['major', 'minor', 'patch']:
            bump_type = arg
            new_version = None
        else:
            bump_type = 'patch'
            new_version = arg
    else:
        bump_type = 'patch'
        new_version = None
    
    try:
        old_version, new_version = update_metadata_yaml(
            metadata_path, 
            bump_type=bump_type,
            new_version=new_version
        )
        
        print(f"Updated {metadata_path}")
        print(f"  Version: {old_version} -> {new_version}")
        print(f"  Last Updated: {datetime.now().strftime('%Y-%m-%d')}")
        
        # Output for GitHub Actions
        print(f"::set-output name=old_version::{old_version}")
        print(f"::set-output name=new_version::{new_version}")
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
