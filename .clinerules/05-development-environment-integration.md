---
description: Development tools integration including VSCode, AI tools, and shell environment configuration
author: Repository Owner
version: 1.0
tags: ["development", "vscode", "ai-tools", "ollama", "shell"]
globs: [".chezmoidata/extensions.yaml", ".chezmoidata/ai.yaml", ".chezmoidata/globals.yaml"]
---

# Development Environment Integration

This repository manages a comprehensive development environment with VSCode extensions, AI tools, shell configuration, and development utilities. Understanding these integrations is essential for maintaining a consistent development experience.

## VSCode Extension Management

### **MUST** Understand Extension Configuration

Extensions are managed through `.chezmoidata/extensions.yaml`:
```yaml
extensions:
  code:
    - ginfuru.ginfuru-better-solarized-dark-theme
    - tamasfe.even-better-toml
    - ms-python.black-formatter
    - ms-python.debugpy
    - ms-python.python
    - redhat.vscode-yaml
    - vue.volar
    - dbaeumer.vscode-eslint
    - gitlab.gitlab-workflow
    - codezombiech.gitignore
    - foxundermoon.shell-format
    - golang.go
    - saoudrizwan.claude-dev
    - knisterpeter.vscode-github
    - esbenp.prettier-vscode
    - jock.svg
    - continue.continue
```

### Extension Installation Pattern
```bash
# In run_onchange_after_install_extensions.sh.tmpl
{{ range .extensions.code -}}
    echo "Installing extension: {{ . }}"
    code --install-extension {{ . }}
{{ end -}}
```

### **MUST** Follow Extension Categories

1. **Theme Extensions**: Color schemes and UI themes
2. **Language Support**: Python, Go, Vue, YAML, TOML
3. **Development Tools**: ESLint, Prettier, formatters
4. **AI Integration**: Claude Dev, Continue
5. **Git Integration**: GitLab workflow, GitHub integration
6. **Utility Extensions**: SVG viewer, gitignore generator

## AI Tools Integration

### **MUST** Understand AI Model Management

AI models are configured in `.chezmoidata/ai.yaml`:
```yaml
ai:
  models:
  - qwen2.5-coder:1.5b
  - nomic-embed-text:latest
```

### Ollama Integration Pattern
```bash
# Model installation script
{{ range .ai.models -}}
    echo "Installing {{.}}"
    ollama pull {{.}}
{{ end -}}
```

### **SHOULD** Understand AI Tool Ecosystem

1. **Ollama**: Local LLM hosting and management
2. **Continue**: VSCode AI coding assistant
3. **Claude Dev**: Advanced AI development assistant
4. **Model Selection**: Optimized for coding and embedding tasks

## Shell Environment Configuration

### **MUST** Understand Global Variables

Environment variables are managed in `.chezmoidata/globals.yaml`:
```yaml
globals:
  linux:
    # X Config Envs
    XDG_CACHE_HOME: HOME/.cache
    XDG_CONFIG_HOME: HOME/.config
    XDG_DATA_HOME: HOME/.local/share
    XDG_STATE_HOME: HOME/.local/state
```

### XDG Base Directory Specification
- **XDG_CONFIG_HOME**: User-specific configuration files
- **XDG_DATA_HOME**: User-specific data files
- **XDG_CACHE_HOME**: User-specific cache files
- **XDG_STATE_HOME**: User-specific state files

### Template Integration
```bash
# In shell configuration scripts
{{ range $key, $value := .globals.linux }}
export {{ $key }}="{{ $value | replace "HOME" "$HOME" }}"
{{ end }}
```

## Development Tools Stack

### **MUST** Understand Tool Categories

From `.chezmoidata/packages.yaml`:

#### Programming Languages
```yaml
languages:
  strategy: *_install_from_source
  list:
    - go
    - go-tools
    - python
    - rust
```

#### Package Managers
```yaml
package_managers:
  strategy: *_install_from_source
  list:
    - uv          # Fast Python package manager
    - cargo       # Rust package manager
    - mise        # Runtime version manager
```

#### Development Tools
```yaml
development_tools:
  list:
    - docker
    - docker-compose
    - code        # VSCode

development_clis:
  strategy: *_install_from_source
  list:
    - aws-cli-v2
    - git-delta   # Better git diffs
    - mergiraf    # Git merge tool
    - jujutsu     # Version control system
```

## Git Configuration Integration

### **MUST** Understand Git Tool Integration

Git is configured with enhanced tools:
- **Delta**: Syntax-highlighted diffs
- **Mergiraf**: Advanced merge conflict resolution
- **Git hooks**: Automated via chezmoi scripts

### Git Configuration Template
```ini
# In private_dot_config/git/config.tmpl
[user]
    name = {{ .fullname }}
    email = {{ .personalEmail }}

[diff]
    pager = delta

[merge]
    tool = mergiraf
```

## Terminal Environment

### **MUST** Understand Terminal Tool Stack

#### Essential CLI Tools
```yaml
terminal_essentials:
  strategy: *_install_from_source
  list:
    - zoxide      # Smart directory jumping
    - fzf         # Fuzzy finder
    - tlrc        # Better man pages
    - fd          # Better find
    - ripgrep     # Better grep
    - broot       # Tree view with navigation
    - bat         # Better cat
    - eza         # Better ls
    - xh          # Better curl
    - jaq         # Better jq
    - rsync       # File synchronization
```

#### Utility Tools
```yaml
terminal_utils:
  strategy: *_install_from_source
  list:
    - fastfetch   # System information
    - usage       # Command usage statistics
    - nvitop      # GPU monitoring
    - btop        # System monitoring
```

## Color Scheme Integration

### **MUST** Understand Color System

Colors are centrally managed in `.chezmoidata/colors.yaml`:
```yaml
colors:
  oksolar:
    - base03: "002d38"
    - base02: "093946"
    - base01: "5b7279"
    # ... complete color palette
```

### Color Usage in Templates
```bash
# Example color integration
set "Appearance" "Theme" "{{ .colors.oksolar.base03 }}"
```

## Development Workflow Integration

### **MUST** Follow Development Patterns

#### Script Execution Order
1. **Package installation**: Core development tools
2. **Extension installation**: VSCode extensions
3. **AI model setup**: Ollama models
4. **Configuration application**: Git, shell, etc.

#### Template Variables for Development
```go
# User-specific development paths
{{ .firstname | lower }}     # Username for paths
{{ .workEmail }}            # Work-related configurations
{{ .personalEmail }}        # Personal development
{{ .privateServer }}        # Private infrastructure
```

## Integration Testing

### **SHOULD** Verify Development Environment

```bash
# Verify VSCode extensions
code --list-extensions

# Verify AI models
ollama list

# Verify development tools
which go python rust cargo uv mise

# Verify git configuration
git config --list
```

## Best Practices

### **MUST** Follow These Guidelines

1. ✅ **Keep extensions minimal** - Only install necessary extensions
2. ✅ **Use consistent color schemes** - Apply oksolar theme consistently
3. ✅ **Validate tool installations** - Check tool availability after installation
4. ✅ **Maintain version consistency** - Use specific versions where needed
5. ✅ **Document tool purposes** - Explain why each tool is included

### **SHOULD** Consider These Practices

1. ✅ **Group related tools** - Organize by function and purpose
2. ✅ **Use template variables** - Leverage user-specific configurations
3. ✅ **Test cross-platform compatibility** - Ensure tools work on target systems
4. ✅ **Monitor resource usage** - Consider impact of AI models and tools
5. ✅ **Keep configurations synchronized** - Maintain consistency across machines

### **NEVER** Do These Things

1. ❌ **Never install conflicting tools** - Check for tool conflicts
2. ❌ **Never hardcode user-specific paths** - Use template variables
3. ❌ **Never skip dependency checks** - Verify prerequisites
4. ❌ **Never ignore tool versions** - Consider version compatibility
5. ❌ **Never bypass package strategies** - Respect installation preferences

## Troubleshooting Common Issues

### Extension Installation Failures
```bash
# Check VSCode installation
which code

# Verify extension marketplace access
code --list-extensions

# Manual extension installation
code --install-extension <extension-id>
```

### AI Model Issues
```bash
# Check Ollama service
systemctl status ollama

# Verify model availability
ollama list

# Re-pull models
ollama pull <model-name>
```

### Tool Path Issues
```bash
# Check PATH configuration
echo $PATH

# Verify tool installations
which <tool-name>

# Check package manager installations
pacman -Qi <package-name>
yay -Qi <package-name>
```

## Verification Checklist

Before modifying development environment configurations:

<thinking>
1. Will this change affect other development tools?
2. Are the template variables properly used?
3. Have I considered cross-platform compatibility?
4. Will this work with the existing package management strategy?
5. Are there any dependency conflicts?
</thinking>

### Critical Questions
1. 🔍 **Does this integrate well with existing tools?**
2. 🔍 **Are template variables used correctly?**
3. 🔍 **Will this work across different machines?**
4. 🔍 **Have I tested the installation process?**

---

**REMEMBER**: The development environment is designed for consistency and productivity. Always consider the impact of changes on the overall development workflow.
