# Archives Directory

This directory stores previous configuration files that are no longer actively managed by chezmoi but may be useful for reference or restoration.

## Purpose

- **Preservation**: Keep old configurations for historical reference
- **Migration**: Store configs from previous desktop environments or tools during transitions
- **Recovery**: Easy restoration if needed
- **Learning**: Reference for future configurations

## Structure

The directory structure mirrors the original chezmoi layout. Files are organized by:

1. **Technology/Tool name** (e.g., `kde/`, `gnome/`, `i3/`)
2. **Original path** preserved from chezmoi source (e.g., `private_dot_config/`)

Example:
```
archives/
└── kde/
    └── private_dot_config/
        ├── modify_private_kdeglobals.tmpl
        ├── private_kdeglobals.src.ini
        ├── modify_private_kwinrc
        ├── private_kwinrc.src.ini
        └── color-schemes/
            ├── BreezeSolarizedDark.colors
            └── BreezeSolarizedLight.colors
```

## Ignored by Chezmoi

This directory is explicitly ignored via `.chezmoiignore`, meaning:
- ✅ Tracked in git for version control
- ✅ Available locally for reference
- ❌ Not processed by `chezmoi apply`
- ❌ Not deployed to target system

## Usage Guidelines

### Archiving Files

When archiving configurations:

1. Create a subdirectory named after the tool/technology (e.g., `kde/`, `sway/`)
2. Preserve the original chezmoi path structure
3. Move complete sets of related files together
4. Update this README with archive date and reason

### Restoring Files

To restore archived files:

1. Copy files from `archives/[tool]/` back to their original location
2. Remove the archived copies (optional)
3. Run `chezmoi apply` to deploy

## Archive Log

| Date | Technology | Reason | Files Archived |
|------|-----------|--------|----------------|
| 2025-10-09 | KDE Plasma | Migration to Hyprland | kdeglobals, kwinrc, color schemes |

## Notes

- Keep this directory organized and documented
- Remove truly obsolete files after extended periods (6+ months)
- Consider creating timestamped subdirectories for multiple migrations of the same tool
