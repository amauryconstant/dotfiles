# Nextcloud Configuration - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/Nextcloud/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Nextcloud desktop client config (mixed state/settings)
- **Tool**: chezmoi_modify_manager (separates settings from state)
- **File**: `modify_nextcloud.cfg.tmpl`
- **Pattern**: Filter state, set user-specific values, hide sensitive data

## chezmoi_modify_manager Reference

### Problem

Apps store both settings (user preferences) and state (window positions, cache) in one file. Traditional dotfiles treat these as single units, causing constant churn.

### Solution

chezmoi_modify_manager intelligently separates settings from state.

### Directive Reference

| Directive | Purpose | Example |
|-----------|---------|---------|
| `source auto` | Auto-find .src.ini | `source auto` |
| `ignore` | Filter specific keys | `ignore "General" "ColorSchemeHash"` |
| `ignore section` | Filter entire sections | `ignore section "Cache"` |
| `ignore regex` | Pattern-based filtering | `ignore regex "General" "clientVersion\|lastSync"` |
| `set` | Force specific values | `set "User" "Name" "{{ .fullname }}"` |
| `add:remove` | Remove from source on re-add | `add:remove "User" "Name"` |
| `add:hide` | Hide sensitive values | `add:hide "Accounts" "0\\password"` |
| `ignore_order` | Ignore list sort order | `ignore_order "Plugins" "LoadOrder"` |
| `self_update` | Enable auto-updates | `self_update enable` |

### Key Patterns

- Filter runtime state: `ignore section "Cache"`
- Use template vars: `set "User" "Name" "{{ .fullname }}"`
- Protect sensitive data: `add:hide "Auth" "token"`
- Dynamic values: `add:remove` for app-set values

### Quick Start

```bash
#!/usr/bin/env chezmoi_modify_manager
source auto  # Auto-find corresponding .src.ini

# Filter state
ignore section "Cache"
ignore section "DirSelect Dialog"

# Set user-specific values
set "User" "Name" "{{ .fullname }}"
set "User" "Email" "{{ .personalEmail }}"

# Hide sensitive data
add:hide "Auth" "token"
add:remove "User" "Name"
```

## Directive Reference

| Directive | Purpose | Example |
|-----------|---------|---------|
| `source auto` | Auto-find .src.ini | `source auto` |
| `ignore` | Filter specific keys | `ignore "General" "ColorSchemeHash"` |
| `ignore section` | Filter entire sections | `ignore section "Cache"` |
| `ignore regex` | Pattern-based filtering | `ignore regex "General" "clientVersion\|lastSync"` |
| `set` | Force specific values | `set "User" "Name" "{{ .fullname }}"` |
| `add:remove` | Remove from source on re-add | `add:remove "User" "Name"` |
| `add:hide` | Hide sensitive values | `add:hide "Accounts" "0\\password"` |
| `ignore_order` | Ignore list sort order | `ignore_order "Plugins" "LoadOrder"` |
| `self_update` | Enable auto-updates | `self_update enable` |

## Nextcloud Example

**File**: `modify_nextcloud.cfg.tmpl`

**Patterns used**:

### Filter Runtime State

```bash
# Ignore version tracking (changes on every update)
ignore regex "General" "clientVersion|desktopEnterpriseChannel|isVfsEnabled"

# Ignore ephemeral account state
ignore regex "Accounts" ".*version|.*journalPath|.*server.*|.*networkProxy.*"

# Ignore settings section (UI state)
ignore section "Settings"
```

### Set User-Specific Values

```bash
# Sync folder path (user-specific)
set "Accounts" "0\\Folders\\1\\localPath" "/home/{{ .firstname | lower }}/Synchronized/"
add:remove "Accounts" "0\\Folders\\1\\localPath"

# Username (template variable)
set "Accounts" "0\\dav_user" "{{ .firstname | lower }}"
add:remove "Accounts" "0\\dav_user"

# Display name
set "Accounts" "0\\displayName" "{{ .firstname }}"
add:remove "Accounts" "0\\displayName"

# Webflow user
set "Accounts" "0\\webflow_user" "{{ .firstname | lower }}"
add:remove "Accounts" "0\\webflow_user"
```

### Dynamic Server URL

```bash
# Transform server URL (www → nextcloud subdomain)
{{ $nextcloudServer := .privateServer | replace "www" "nextcloud" }}

set "Accounts" "0\\url" "{{ $nextcloudServer }}"
add:remove "Accounts" "0\\url"
```

## Template Integration

**Conditional logic**:
```bash
{{ if eq .chassisType "laptop" }}
set "Power" "SuspendOnLidClose" "true"
{{ else }}
set "Power" "SuspendOnLidClose" "false"
{{ end }}
```

**Variable transformation**:
```bash
{{ $server := .privateServer | replace "www" "nextcloud" }}
set "Server" "URL" "{{ $server }}"
```

**User-specific paths**:
```bash
set "Accounts" "0\\Folders\\1\\localPath" "/home/{{ .firstname | lower }}/Synchronized/"
```

## Common Mistakes

1. **Ignoring critical settings** (only ignore state)
   - ❌ `ignore section "Accounts"`
   - ✅ `ignore regex "Accounts" ".*version|.*journalPath"`

2. **Hardcoded values** (use template vars)
   - ❌ `set "User" "Name" "John"`
   - ✅ `set "User" "Name" "{{ .fullname }}"`

3. **Skipping testing** (`chezmoi cat` before apply)
   - Always preview: `chezmoi cat ~/.config/Nextcloud/nextcloud.cfg`

4. **Committing sensitive data** (use `add:hide`)
   - ✅ `add:hide "Accounts" "0\\password"`

5. **Assuming config structure** (test with actual files)
   - Nextcloud config structure varies by version

## Testing & Validation

**Preview output**:
```bash
chezmoi cat ~/.config/Nextcloud/nextcloud.cfg
```

**Validate template**:
```bash
chezmoi execute-template < private_dot_config/Nextcloud/modify_nextcloud.cfg.tmpl
```

**Test modify_manager syntax**:
```bash
chezmoi_modify_manager --help-syntax
```

**Dry-run**:
```bash
chezmoi apply --dry-run
```

## How It Works

1. **Source file**: `~/.config/Nextcloud/nextcloud.cfg.src.ini` (current state)
2. **Modify script**: `modify_nextcloud.cfg.tmpl` (directives)
3. **Processing**: chezmoi_modify_manager applies directives
4. **Output**: `~/.config/Nextcloud/nextcloud.cfg` (managed config)

**On re-add** (`chezmoi add`):
- `add:remove` keys removed from source
- `add:hide` keys hidden in source
- Filters applied to new state

## Integration Points

- **Template vars**: `.chezmoi.yaml.tmpl` (fullname, firstname, privateServer)
- **Nextcloud client**: Auto-detects config changes
- **Sync behavior**: Preserves user preferences, filters ephemeral state
