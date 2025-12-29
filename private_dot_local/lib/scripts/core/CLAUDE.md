# Core Script Libraries - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/core/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Foundation libraries for all scripts
- **Files**: gum-ui.sh (572 lines), colors.sh.tmpl
- **Usage**: System scripts source `$UI_LIB` (see adoption note below)
- **Dependencies**: gum (optional - fallbacks provided), colors.yaml

## Gum UI Library - Primary Reference

**Purpose**: Standardized UI framework for system CLI tools
**Location**: `gum-ui.sh` (572 lines)
**Adopted by**: system/ scripts (7 files)
**Not used by**: desktop/ (use notify-send), menu/ (use menu-helpers.sh)

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

**Interactive Functions** (9):
- `ui_confirm` - Yes/No prompts
- `ui_choose` - Single selection menu
- `ui_choose_multi` - Multi-selection menu
- `ui_input` - Text input
- `ui_password` - Password input (hidden)
- `ui_filter` - Fuzzy search (requires gum)
- `ui_spin_verbose` - Verbose spinner (shows all output)
- `ui_spin_on_error` - Error-only spinner (shows stderr only)
- `ui_spin_silent` - Silent spinner (hides all output)

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

# Spinners (see dedicated section below)
ui_spin_verbose "Processing data" "long-running-command"
ui_spin_silent "Checking updates" "checkupdates"
```

### Spinner Variants with Output Control

**Three spinner types for different use cases**:

**ui_spin_verbose** - Shows all output:
- **Use for**: Long-running operations with verbose progress output (no user interaction)
- **Gum flag**: `--show-output`
- **Behavior**: Spinner + command output visible
- **Example**: `ui_spin_verbose "Processing data" "long-running-command"`
- **Note**: NOT for sudo/interactive prompts (use direct calls instead)

**ui_spin_on_error** - Shows output only on failure:
- **Use for**: Build commands, large operations, compilation
- **Gum flag**: `--show-stderr`
- **Behavior**: Silent on success, shows stderr on failure
- **Example**: `ui_spin_on_error "Building project" "make all"`

**ui_spin_silent** - Hides all output (background operations):
- **Use for**: Status checks, validation queries, background tasks
- **Gum flag**: *(none - default behavior)*
- **Behavior**: Spinner only, all output hidden
- **Example**: `ui_spin_silent "Checking updates" "checkupdates"`

**Key benefits**:
- ✅ Explicit function names indicate behavior (no guessing)
- ✅ Can't accidentally hide interactive prompts
- ✅ Gum handles I/O multiplexing (spinner + command output)
- ✅ String-based command pattern (consistent with existing usage)

**Usage pattern**:
```bash
# Interactive operations (sudo, package managers) - Direct call, NO spinner
ui_step "Installing packages..."
if paru -S --needed firefox; then
    ui_success "Packages installed"
fi

# Long-running with verbose output (no user interaction)
if ui_spin_verbose "Processing data" "long-running-command"; then
    ui_success "Processing complete"
fi

# Error diagnostics (show failures)
if ui_spin_on_error "Compiling project" "make -j4"; then
    ui_success "Build complete"
fi

# Background queries (hide output)
updates=$(ui_spin_silent "Checking updates" "checkupdates 2>/dev/null")
```

**Selection guidelines**:
- **Interactive operations** (sudo, package managers) → Direct call, NO spinner
- **Long-running with verbose output** (no interaction) → `ui_spin_verbose`
- **Query operations** → `ui_spin_silent`
- **Build operations** → `ui_spin_on_error`

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

**Source**: Theme system (`~/.config/themes/current/colors.sh`)

**Purpose**: Theme-aware color definitions for CLI tools

**Variables**: 24 semantic variables (ACCENT_*, BG_*, FG_*)

**Usage**:
```bash
# Colors loaded automatically by gum-ui.sh
. "$UI_LIB"
ui_success "Success!"  # Uses ACCENT_SUCCESS
ui_error "Error!"      # Uses ACCENT_ERROR

# Direct access (if needed)
. ~/.config/themes/current/colors.sh
echo "${ACCENT_SUCCESS}Success!${NC}"
```

**Semantic mappings**:
- Primary actions → `ACCENT_PRIMARY`
- Success states → `ACCENT_SUCCESS`
- Errors → `ACCENT_ERROR`
- Warnings → `ACCENT_WARNING`
- Secondary text → `FG_SECONDARY`
- Muted/disabled → `FG_MUTED`

**Theme switching**: New shells pick up active theme automatically

## Integration Points

- **System scripts**: Source `$UI_LIB` for consistent terminal UI
- **git-prune-branch**: Uses UI library for interactive CLI tool
- **Menu system**: Uses `menu-helpers.sh` (not gum-ui)
- **Desktop utilities**: Use `notify-send` (not gum-ui)
- **Template scripts**: Use `{{ includeTemplate "log_*" }}` (not gum-ui)
