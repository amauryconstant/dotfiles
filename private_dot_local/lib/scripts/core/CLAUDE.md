# Core Script Libraries - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/core/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Foundation libraries for all scripts
- **Files**: gum-ui.sh (572 lines), colors.sh.tmpl
- **Usage**: Source `$UI_LIB` in all scripts
- **Dependencies**: gum (optional - fallbacks provided), colors.yaml

## Gum UI Library - Primary Reference

**Purpose**: Standardized UI framework for all scripts
**Location**: `gum-ui.sh` (572 lines)
**Used in**: desktop/, system/, media/, user-interface/ scripts

**Dependencies**:
- `gum` (optional - provides fallbacks)
- `colors.sh` (oksolar theme)

### Function Categories

**Status Functions** (8):
- `ui_success` - ✅ Green checkmark
- `ui_error` - ❌ Red X
- `ui_warning` - ⚠️  Yellow triangle
- `ui_info` - ℹ️  Blue info
- `ui_step` - 📋 Step indicator
- `ui_status` - 📊 Status indicator
- `ui_action` - 🚀 Action indicator
- `ui_complete` - 🎉 Completion indicator

**Interactive Functions** (7):
- `ui_confirm` - Yes/No prompts
- `ui_choose` - Single selection menu
- `ui_choose_multi` - Multi-selection menu
- `ui_input` - Text input
- `ui_password` - Password input (hidden)
- `ui_filter` - Fuzzy search (requires gum)
- `ui_spin` - Spinner with command execution

**Layout Functions** (6):
- `ui_title` - Double border title
- `ui_subtitle` - Single border subtitle
- `ui_box` - Bordered content box
- `ui_separator` - Visual divider
- `ui_spacer` - Consistent spacing
- `ui_output` - Raw data display

**Data Display Functions** (3):
- `ui_table` - Formatted tables
- `ui_list` - Bulleted lists
- `ui_key_value` - Key-value pairs

### Universal Parameters

All rendering functions support:

| Param | Purpose | Example |
|-------|---------|---------|
| `--before N` | Blank lines before | `--before 2` |
| `--after N` | Blank lines after | `--after 1` |
| `--indent N` | Spaces before content | `--indent 4` |
| `--newline` / `--nl` | Single newline after | `--nl` |

### Usage Pattern

```bash
# Source in scripts
. "$UI_LIB"  # or: . ~/.local/lib/scripts/core/gum-ui.sh

# Universal parameters
ui_success "Operation complete" --before 1 --after 2 --indent 4
ui_box "Important message" "$UI_ERROR" --newline

# Interactive
if ui_confirm "Continue?"; then
    choice=$(ui_choose "Select" "Opt1" "Opt2" "Opt3")
fi

# Spinner
ui_spin "Processing" long_running_command
```

### Color Integration

**Source**: `colors.sh.tmpl`

**Loads from**: `.chezmoidata/colors.yaml` (oksolar)

**Color variables**:
- `UI_PRIMARY` - Primary accent
- `UI_SUCCESS` - Success green
- `UI_ERROR` - Error red
- `UI_WARNING` - Warning yellow
- `UI_CAUTION` - Caution orange
- `UI_SECONDARY` - Secondary blue
- `UI_SUBTLE` - Subtle gray

**Fallback**: Default values if `colors.sh` missing

### Graceful Degradation

**Gum availability**:
- Checks `gum` availability once
- Warns if missing (first call only)
- Falls back to plain text output
- Export `GUM_WARNING_SHOWN=1` to suppress warnings

**Behavior without gum**:
- All functions work (reduced visual fidelity)
- Text output instead of styled output
- `ui_filter` requires gum (no fallback)

### Example Usage

**Status output**:
```bash
ui_step "Installing packages"
# ... installation logic ...
ui_success "Packages installed"
```

**Interactive menu**:
```bash
options=("Option 1" "Option 2" "Option 3")
choice=$(ui_choose "Select option" "${options[@]}")
```

**Confirm dialog**:
```bash
if ui_confirm "Delete file?"; then
    rm "$file"
    ui_success "File deleted"
fi
```

**Data display**:
```bash
ui_table "Name|Status|Count" "Pkg1|Active|42" "Pkg2|Inactive|7"
ui_list "Item 1" "Item 2" "Item 3"
ui_key_value "Version" "1.2.3" "Author" "Name"
```

## Color Library

**File**: `colors.sh.tmpl`

**Source**: `.chezmoidata/colors.yaml`

**Purpose**: Oksolar color definitions for UI

**Usage**:
```bash
. "$HOME/.local/lib/scripts/core/colors.sh"
echo "${UI_SUCCESS}Success!${NC}"
```

**Template variables**:
```go
{{ .colors.oksolar.base0 }}
{{ .colors.oksolar.green }}
{{ .colors.oksolar.red }}
```

## Integration Points

- **All scripts**: Source `$UI_LIB` for consistent UI
- **CLI wrappers**: `~/.local/bin/executable_*` source UI library
- **Menu system**: `user-interface/` scripts use UI functions
- **System tools**: `system/` scripts use UI functions
- **Desktop utilities**: `desktop/` scripts use UI functions
