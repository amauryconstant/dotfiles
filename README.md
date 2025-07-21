# Sophisticated Chezmoi Dotfiles

This is a comprehensive chezmoi dotfiles repository that manages personal configuration files across systems with advanced AI assistant integration. The repository implements templating, encryption, automated maintenance, and AI-powered development workflows designed for Arch Linux environments.

## Features

### Core System Management
- **Advanced templating** with Go text/template and Sprig functions
- **Age encryption** for sensitive configuration files
- **Package management** with multiple installation strategies (pacman, yay, source)
- **Simplified configuration** with single work environment deployment
- **chezmoi_modify_manager** integration for complex configuration files
- **System-level services** with topgrade automation for maintenance

### AI Assistant Integration
- **Cline AI rules** for structured behavioral guidance (`~/.ai/rules/cline/`)
- **Continue AI extension** configuration for VS Code development
- **AI model management** with automated Ollama setup and model installation
- **Automated AI tool installation** and configuration
- **Git submodule architecture** for modular AI configuration management

### Development Environment
- **Multi-language support** (Go, Python, Rust via mise)
- **Enhanced CLI tools** (ripgrep, fd, fzf, bat, delta, etc.)
- **Consistent theming** with Solarized color scheme
- **Development containers** and tool automation
- **Git workflow enhancements** with advanced merging and diffing

## Installation

### Basic Installation
```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin
chezmoi init --apply https://gitlab.com/amoconst/dotfiles.git
reboot
```

### With AI Features
During initialization, you'll be prompted to enable AI tools and configurations. Answer `y` to include:
- AI assistant behavioral rules
- Continue AI extension configuration
- Ollama local LLM setup
- AI model management
- Development-focused AI tooling

## Architecture

### Git Submodule Structure
- **Main Repository**: Complete system configuration management
- **AI Submodule** (`external_dot_ai/`): AI assistant rules and configurations
  - Files deploy to `~/.ai/` directory
  - Inherits template variables from main repository
  - Managed through single `chezmoi apply` command

### Package Management
Sophisticated package installation with fallback chains:
- **Binary packages**: `pacman` → `yay_bin`
- **Source packages**: `pacman` → `yay_bin` → `yay_source`
- **Unified deployment**: Single comprehensive work environment configuration
- **AI tools integration**: Automated Ollama setup and model management

## Usage

### Daily Operations
```bash
chezmoi apply -v               # Apply all changes
chezmoi status                 # Check status
chezmoi diff                   # Preview changes
```

### AI Integration
```bash
# AI rules are automatically deployed to ~/.ai/rules/cline/
# Continue configuration is applied to ~/.ai/.continue.yaml
# AI models are managed through data files and automated scripts
```

### Development Workflow
```bash
topgrade                       # Update everything
mise install                   # Install development tools
chezmoi edit <file>            # Edit managed files
```

## Documentation

See `CLAUDE.md` for comprehensive documentation including:
- Architecture and structure details
- Template system usage
- Package management configuration
- AI assistant integration protocols
- Quality standards and validation procedures
- Emergency procedures and troubleshooting