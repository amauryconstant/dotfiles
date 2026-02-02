#!/usr/bin/env python3
"""
Update the Nerd Fonts glyphnames.json file from the official repository.
Usage: python update_glyphs.py [--force]
"""

import json
import sys
import urllib.request
import shutil
from pathlib import Path
from datetime import datetime

GITHUB_RAW_URL = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json"

def get_script_dir():
    """Get the directory containing this script."""
    return Path(__file__).parent

def get_references_dir():
    """Get the references directory."""
    return get_script_dir().parent / "references"

def get_glyphs_path():
    """Get the path to the local glyphnames.json file."""
    return get_references_dir() / "glyphnames.json"

def download_glyphs():
    """Download glyphnames.json from GitHub."""
    print(f"📥 Downloading glyphnames.json from GitHub...")
    print(f"   URL: {GITHUB_RAW_URL}")

    try:
        with urllib.request.urlopen(GITHUB_RAW_URL) as response:
            data = response.read().decode('utf-8')
            return json.loads(data)
    except urllib.error.URLError as e:
        print(f"❌ Error downloading file: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON: {e}")
        sys.exit(1)

def get_current_version():
    """Get version from current local file."""
    glyphs_path = get_glyphs_path()

    if not glyphs_path.exists():
        return None

    try:
        with open(glyphs_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return data.get('METADATA', {}).get('version')
    except (json.JSONDecodeError, OSError):
        return None

def backup_current_file():
    """Create a backup of the current file."""
    glyphs_path = get_glyphs_path()

    if not glyphs_path.exists():
        return None

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = glyphs_path.parent / f"glyphnames.json.backup_{timestamp}"

    shutil.copy2(glyphs_path, backup_path)
    print(f"💾 Backup created: {backup_path.name}")
    return backup_path

def save_new_file(data):
    """Save the new glyphnames.json file."""
    glyphs_path = get_glyphs_path()

    with open(glyphs_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"✅ Updated: {glyphs_path}")

def main():
    force = '--force' in sys.argv

    print("🔍 Checking for Nerd Fonts glyph updates...\n")

    # Get current version
    current_version = get_current_version()
    if current_version:
        print(f"📌 Current version: {current_version}")
    else:
        print("📌 No local file found")

    # Download new version
    new_data = download_glyphs()
    new_version = new_data.get('METADATA', {}).get('version', 'unknown')
    new_date = new_data.get('METADATA', {}).get('date', 'unknown')
    glyph_count = len([k for k in new_data.keys() if k != 'METADATA'])

    print(f"🆕 Remote version: {new_version}")
    print(f"📅 Release date: {new_date}")
    print(f"🎨 Total glyphs: {glyph_count:,}\n")

    # Check if update needed
    if current_version == new_version and not force:
        print("✨ Already up to date! Use --force to reinstall.")
        return

    if current_version and current_version != new_version:
        print(f"⬆️  Upgrade available: {current_version} → {new_version}\n")

    # Backup and update
    if current_version:
        backup_current_file()

    save_new_file(new_data)

    if current_version and current_version != new_version:
        print(f"\n🎉 Successfully upgraded from {current_version} to {new_version}!")
    else:
        print(f"\n🎉 Successfully installed version {new_version}!")

if __name__ == "__main__":
    main()
