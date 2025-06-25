# Logging Fix Demonstration

This demonstrates the fix for the verbose logging issue where `chezmoi apply -v` was showing debug spam in the console.

## The Problem (Before Fix)

When running `chezmoi apply -v`, users would see polluted output like:
```bash
[2025-01-15 18:30:45] [DEBUG] [install_packages] [work] [before] Installing with pacman: fonts
[2025-01-15 18:30:45] [DEBUG] [install_packages] [work] [before] Command: sudo pacman -S --noconfirm
[2025-01-15 18:30:45] [INFO] [install_packages] [work] [before] ℹ Installing fonts
[2025-01-15 18:30:45] [DEBUG] [install_packages] [work] [before] Environment: USER=amaury
```

## The Solution (After Fix)

Now the system uses **separate log levels** for console and file output:

### Console Output: Always Clean
- `CONSOLE_LOG_LEVEL="INFO"` - Always clean, never shows debug
- `chezmoi apply` → Clean output
- `chezmoi apply -v` → Same clean output

### File Logging: Verbose Flag Controls Detail
- `FILE_LOG_LEVEL="INFO"` (standard) or `"DEBUG"` (with -v)
- `chezmoi apply` → Standard file logging
- `chezmoi apply -v` → Enhanced file logging with debug details

## Implementation Details

### Key Changes Made

1. **Separate Log Levels** (`.chezmoitemplates/chezmoi_logger_setup`)
```bash
# Console output - always clean
CONSOLE_LOG_LEVEL="INFO"

# File logging - enhanced with verbose flag
if [ "$CHEZMOI_VERBOSE" = "true" ]; then
    FILE_LOG_LEVEL="DEBUG"  # Enhanced file logging
else
    FILE_LOG_LEVEL="INFO"   # Standard file logging
fi
```

2. **Dual Log Level Checking** (`.chezmoitemplates/chezmoi_logger.sh`)
```bash
_dual_log() {
    console_level_numeric=$(get_log_level_numeric "${CONSOLE_LOG_LEVEL:-INFO}")
    file_level_numeric=$(get_log_level_numeric "${FILE_LOG_LEVEL:-INFO}")
    
    # Console: Check against console level (always INFO)
    if [ "$level_numeric" -ge "$console_level_numeric" ]; then
        # Show clean output in console
    fi
    
    # File: Check against file level (INFO or DEBUG based on -v)
    if [ "$level_numeric" -ge "$file_level_numeric" ]; then
        _log_to_file "$level" "$symbol" "$message" "$details"
    fi
}
```

## User Experience

### `chezmoi apply` (Standard)
**Console Output:**
```bash
⚙️ Setting up development environment for work
📦 Installing fonts (4 packages)
✅ Fonts installed
📦 Installing terminal tools (8 packages)
✅ Terminal tools installed
```

**File Logs:** (Standard detail level)
```bash
[2025-01-15 19:51:25] [INFO] [install_arch_packages] [work] [before] Package operation: install category=fonts
[2025-01-15 19:51:27] [INFO] [install_arch_packages] [work] [before] Successfully installed fonts with pacman
```

### `chezmoi apply -v` (Verbose)
**Console Output:** (Identical - stays clean!)
```bash
⚙️ Setting up development environment for work
📦 Installing fonts (4 packages)
✅ Fonts installed
📦 Installing terminal tools (8 packages)
✅ Terminal tools installed
```

**File Logs:** (Enhanced with debug details)
```bash
[2025-01-15 19:51:25] [INFO] [install_arch_packages] [work] [before] Package operation: install category=fonts
[2025-01-15 19:51:25] [DEBUG] [install_arch_packages] [work] [before] Debug: Installing with pacman: ttf-firacode-nerd otf-opendyslexic-nerd
[2025-01-15 19:51:25] [DEBUG] [install_arch_packages] [work] [before] Debug: Command details and environment info
[2025-01-15 19:51:27] [INFO] [install_arch_packages] [work] [before] Successfully installed fonts with pacman
```

## Benefits

1. **Always readable console** - No debug spam regardless of flags
2. **Enhanced debugging when needed** - Use `-v` for detailed file logs
3. **No workflow changes** - Keep using `chezmoi apply` as normal
4. **Minimal code changes** - Just separated console and file log levels
5. **Backward compatible** - All existing logging functions work the same

## Testing the Fix

To test this fix:

1. **Standard mode**: `chezmoi apply`
   - Console: Clean, readable output
   - File: Standard logging

2. **Verbose mode**: `chezmoi apply -v`
   - Console: Same clean output (no change!)
   - File: Enhanced logging with debug details

The key insight: **Decouple console verbosity from file verbosity**. Console always stays clean and human-readable, while the verbose flag only affects the detail level of file logs for debugging purposes.
