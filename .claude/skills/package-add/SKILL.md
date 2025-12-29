---
name: package-add
description: Add packages to packages.yaml with validation, module management, and conflict detection. Use when installing packages, managing dotfiles packages, or when user mentions adding software.
allowed-tools: Bash, Read, Write, Grep
---

# Package Add

Add packages to packages.yaml with validation and smart module management.

## When to Use

- User wants to install a package
- User asks "how do I add a package?"
- User mentions installing software, applications, or tools
- User wants to manage packages declaratively

## Execution Steps

1. **Gather package information**

   Prompt for:
   - Package name(s) (comma-separated for multiple)
   - Package type (auto-detect or ask):
     - Arch (pacman repositories)
     - AUR (paru repositories)
     - Flatpak (Flathub)

2. **Validate package existence**

   ```bash
   bash ~/.local/share/chezmoi/.claude/skills/package-add/scripts/package-add.sh validate \
     --type {arch|aur|flatpak} \
     --packages "pkg1,pkg2"
   ```

   Script returns JSON:
   ```json
   [
     {
       "name": "neovim",
       "type": "arch",
       "repo": "extra",
       "description": "Vim-fork focused on extensibility",
       "valid": true
     }
   ]
   ```

   If invalid, suggest similar packages (fuzzy search).

3. **Suggest module placement**

   Read packages.yaml and analyze:
   - Package category (based on description)
   - Existing module packages (find related)
   - Module conflicts

   **Categorization keywords**:
   - Development: git, compiler, editor, ide, debug, build, language
   - Productivity: office, note, calendar, email, document
   - Media: audio, video, image, photo, music, player
   - System: monitor, utility, backup, maintenance
   - Desktop: theme, icon, compositor, window
   - Network: browser, vpn, sync, cloud, ssh
   - Security: encrypt, password, auth, key

   **Confidence scoring**:
   - 90-100%: Perfect match (same category, related packages)
   - 70-89%: Good match (similar purpose, enabled module)
   - 50-69%: Acceptable match (broad category)
   - 0-49%: Poor match (suggest new module)

4. **Present module selection**

   ```
   Package: neovim
   Description: Vim-fork focused on extensibility and usability
   Type: Arch (extra)

   Recommended module: development (95% confidence)
   Reason: Text editor commonly used for development, similar to existing vim package

   Available modules:
   1. development (enabled) - Development tools and languages
   2. productivity (enabled) - Productivity applications
   3. [Create new module]

   Select module [1]: _
   ```

5. **Check for conflicts**

   - Duplicate in different module → Prompt resolution
   - Conflicting packages (e.g., vim + neovim) → Warn user
   - Module conflicts → Show and suggest fix

6. **Prompt for version constraint** (optional)

   ```
   Add version constraint? (y/N): _

   Options:
   - Exact: neovim==0.9.5
   - Minimum: neovim>=0.9.0
   - Maximum: neovim<1.0.0

   Constraint [none]: _
   ```

   **Recommendations**:
   - Rolling packages (-git suffix) → No constraint
   - Critical system packages → Minimum (>=)
   - Experimental packages → Exact (==)
   - Most packages → No constraint (rolling release)

7. **Update packages.yaml**

   ```bash
   bash ~/.local/share/chezmoi/.claude/skills/package-add/scripts/package-add.sh add \
     --package neovim \
     --module development \
     --constraint ">=0.9.0"
   ```

   Script:
   - Adds package to module's packages list
   - Preserves YAML formatting and comments
   - Sorts packages alphabetically

8. **Validate changes**

   ```bash
   package-manager validate
   ```

   Check for module conflicts, duplicate packages, invalid constraints.

9. **Offer sync**

   ```
   ✅ Package added successfully

   Changes:
   - Added neovim>=0.9.0 to module 'development'

   Validation: ✅ No conflicts detected

   Install now?
   1. Sync immediately (package-manager sync)
   2. Defer (add with chezmoi later)
   3. Review changes (chezmoi diff)

   Select [2]: _
   ```

10. **Execute sync** (if selected)

    ```bash
    package-manager sync --prune
    ```

    Monitor output and report results.

11. **Present results**

    ```
    ✅ Package added and synced

    Package: neovim>=0.9.0
    Module: development
    Status: Installed (v0.9.5-1)

    Next steps:
    1. Commit: chezmoi add .chezmoidata/packages.yaml
    2. Review: chezmoi diff
    3. Apply: chezmoi apply
    ```

## Module Creation

If creating new module:

```yaml
modules:
  custom_name:
    enabled: true
    description: "Custom module description"
    packages:
      - package_name
```

Prompt for:
- Name (lowercase, no spaces)
- Description (1-2 sentences)
- Enabled by default? (y/N)

## Batch Addition

For multiple packages:
- Validate all at once (batch AUR check)
- Suggest modules (can suggest same module for related)
- Single packages.yaml update
- Single validation run
- Single sync operation

## Helper Script Commands

```bash
# Validate packages
package-add.sh validate --type arch --packages "vim,neovim"

# Add package
package-add.sh add --package neovim --module development --constraint ">=0.9.0"

# Create module
package-add.sh create-module custom_tools "Custom development tools" true
```
