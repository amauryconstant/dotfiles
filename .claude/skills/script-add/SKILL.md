---
name: script-add
description: Guided script creation with proper patterns, validation, and structure. Use when creating new scripts, adding utilities, or when user wants to add functionality to dotfiles.
allowed-tools: Read, Write, Bash, Grep, Glob
---

# Script Add

Create scripts following repository patterns with automatic validation.

## When to Use

- User wants to create a new script
- User asks "how do I add a script?"
- User mentions creating utilities, functions, or tools
- User wants to add functionality to dotfiles

## Execution Steps

1. **Gather requirements**

   Prompt for:
   - Script name (without extension)
   - Purpose (1-2 sentences)
   - Category (or description for auto-detection)
   - CLI wrapper needed? (yes/no for system scripts)

2. **Detect category from keywords**

   | Category | Keywords |
   |----------|----------|
   | System | maintenance, package, update, health, monitor, backup |
   | Desktop | hyprland, waybar, theme, window, workspace, notification |
   | Menu | wofi, launcher, selector, chooser |
   | Terminal | cwd, session, terminal |
   | Media | wallpaper, screenshot, color, image |
   | Network | tailscale, vpn, network, ssh |
   | Git | branch, commit, repo |
   | Template | chezmoi, lifecycle, setup, install, configure |

   If ambiguous, prompt user to select.

3. **Read pattern reference**

   Based on category, read example:
   - System: `~/.local/share/chezmoi/private_dot_local/lib/scripts/system/executable_system-health.sh`
   - Desktop: `~/.local/share/chezmoi/private_dot_local/lib/scripts/desktop/executable_idle-toggle.sh`
   - Menu: `~/.local/share/chezmoi/private_dot_local/lib/scripts/user-interface/executable_menu-helpers.sh`
   - Template: `~/.local/share/chezmoi/.chezmoiscripts/run_once_after_002_setup_system_services.sh.tmpl`

4. **Generate script content**

   **Shebang selection**:
   - Use `#!/usr/bin/env bash` if: associative arrays, regex `=~`, `[[`, process substitution
   - Use `#!/usr/bin/env sh` if: POSIX only, simple utilities

   **UI pattern by category**:
   - System → gum-ui library (`ui_step`, `ui_success`, `ui_confirm`, `ui_choose`)
   - Desktop → notify-send (simple notifications)
   - Menu → menu-helpers.sh + gum
   - Template → log templates (`{{ includeTemplate "log_*" }}`)

   **Header template**:
   ```bash
   #!/usr/bin/env {sh|bash}

   # Script: {name}.sh
   # Purpose: {purpose}
   # Requirements: Arch Linux, {dependencies}
   ```

   **System script sourcing**:
   ```bash
   # Source UI library
   if [ -n "$UI_LIB" ] && [ -f "$UI_LIB" ]; then
       . "$UI_LIB"
   elif [ -f "$HOME/.local/lib/scripts/core/gum-ui.sh" ]; then
       . "$HOME/.local/lib/scripts/core/gum-ui.sh"
   else
       echo "Error: UI library not found" >&2
       exit 1
   fi
   ```

   **Error handling**:
   - Multi-step scripts → `set -euo pipefail`
   - Simple utilities → Manual checking
   - Desktop utilities → Manual (avoid unexpected exits)

5. **Write script to location**

   **Paths**:
   - System/Desktop/Menu: `~/.local/share/chezmoi/private_dot_local/lib/scripts/{category}/executable_{name}.sh`
   - Template: `~/.local/share/chezmoi/.chezmoiscripts/run_onchange_after_{name}.sh.tmpl`

   Set executable permissions:
   ```bash
   chmod +x /path/to/script
   ```

6. **Create CLI wrapper** (if requested for system scripts)

   Location: `~/.local/share/chezmoi/private_dot_local/bin/executable_{name}`

   Content:
   ```bash
   #!/usr/bin/env sh
   exec "$HOME/.local/lib/scripts/{category}/{name}.sh" "$@"
   ```

7. **Validate script**

   **Shellcheck**:
   ```bash
   shellcheck /path/to/script.sh
   ```

   **Template rendering** (if .tmpl):
   ```bash
   chezmoi execute-template < /path/to/script.sh.tmpl
   ```

   Report any issues with line numbers and remediation.

8. **Present results**
   ```
   ✅ Script created successfully

   Location: ~/.local/share/chezmoi/private_dot_local/lib/scripts/{category}/{name}.sh
   Wrapper: ~/.local/bin/{name} (if created)
   Pattern: {category}
   UI: {ui_pattern}

   Validation:
   ✅ Shellcheck passed
   ✅ Executable permissions set

   Next steps:
   1. Review: cat ~/.local/share/chezmoi/private_dot_local/lib/scripts/{category}/{name}.sh
   2. Test: {name} [args]
   3. Add to chezmoi: chezmoi add ~/.local/share/chezmoi/private_dot_local/lib/scripts/{category}/{name}.sh
   ```

## Pattern Reference

Read from existing scripts to match repository patterns (UI library usage, error handling, structure).
